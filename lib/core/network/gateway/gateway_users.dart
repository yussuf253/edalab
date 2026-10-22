import '../supabase_gateway.dart';
import 'gateway_router.dart';

/// `/users/*` — profile, addresses, payment methods, wishlist and coupons.
///
/// Every read/write runs under RLS, so a session can only ever touch its own
/// rows: `GET /users/:id` on somebody else's id returns 404 rather than
/// leaking their profile the way the unauthenticated backend route did.
void register() {
  GatewayRouter.get('/users/me', _getMe);
  GatewayRouter.get('/users/:userId', _getUser);
  GatewayRouter.patch('/users/:userId', _updateProfile);

  GatewayRouter.post('/users/:userId/addresses', _createAddress);
  GatewayRouter.patch(
    '/users/:userId/addresses/:addressId/default',
    _makeAddressDefault,
  );
  GatewayRouter.patch('/users/:userId/addresses/:addressId', _updateAddress);
  GatewayRouter.delete('/users/:userId/addresses/:addressId', _deleteAddress);

  GatewayRouter.get('/users/:userId/payment-methods', _listPaymentMethods);
  GatewayRouter.post('/users/:userId/payment-methods', _createPaymentMethod);
  GatewayRouter.patch(
    '/users/:userId/payment-methods/:paymentMethodId/default',
    _makePaymentMethodDefault,
  );
  GatewayRouter.delete(
    '/users/:userId/payment-methods/:paymentMethodId',
    _deletePaymentMethod,
  );

  GatewayRouter.get('/users/:userId/wishlist', _listWishlist);
  GatewayRouter.post('/users/:userId/wishlist', _upsertWishlistItem);
  GatewayRouter.delete('/users/:userId/wishlist/:entityId', _removeWishlistItem);

  GatewayRouter.get('/users/:userId/coupons', _listCoupons);
}

const String _userColumns =
    'id,email,"firstName","lastName",phone,avatarUrl,banned,banReason,'
    'createdAt,updatedAt';

const String _addressColumns =
    'id,userId,label,line1,line2,city,state,postalCode,latitude,longitude,'
    'isDefault,createdAt,updatedAt';

// ── Serializers (mirror utils/serializers.ts) ───────────────────────────────

Map<String, dynamic> _sanitizeAddress(Map<String, dynamic> address) =>
    <String, dynamic>{
      'quartier': address['line2'] ?? address['state'],
      'id': address['id'],
      'label': address['label'],
      'address': address['line1'],
      'city': address['city'],
      'zipCode': address['postalCode'],
      'latitude': address['latitude'],
      'longitude': address['longitude'],
      'isDefault': address['isDefault'],
    };

Map<String, dynamic> _sanitizeUser(
  Map<String, dynamic> user,
  List<Map<String, dynamic>> addresses,
) {
  final first = user['firstName']?.toString() ?? '';
  final last = user['lastName']?.toString() ?? '';
  final name = [first, last].where((part) => part.isNotEmpty).join(' ');

  Map<String, dynamic>? defaultAddress;
  for (final address in addresses) {
    if (address['isDefault'] == true) {
      defaultAddress = address;
      break;
    }
  }

  return <String, dynamic>{
    'id': user['id'],
    'email': user['email'],
    'name': name,
    'phone': user['phone'],
    'avatarUrl': user['avatarUrl'],
    'banned': user['banned'],
    'banReason': user['banReason'],
    'address': defaultAddress?['line1'],
    'createdAt': user['createdAt'],
    'updatedAt': user['updatedAt'],
    'addresses': addresses.map(_sanitizeAddress).toList(),
  };
}

Future<List<Map<String, dynamic>>> _loadAddresses(String userId) {
  return SupabaseGateway.table('Address')
      .select(_addressColumns)
      .eq('userId', userId)
      .order('isDefault', ascending: false)
      .order('updatedAt', ascending: false);
}

Future<Map<String, dynamic>> _loadUserOrThrow(String userId) async {
  final rows = await SupabaseGateway.table('User')
      .select(_userColumns)
      .eq('id', userId)
      .limit(1);
  if (rows.isEmpty) throw const GatewayError('User not found.', status: 404);

  final addresses = await _loadAddresses(userId);
  return _sanitizeUser(rows.first, addresses);
}

// Ownership is enforced by RLS, not by these handlers: rows written by other
// accounts are simply invisible, which turns a foreign id into the backend's
// 404 instead of exposing the other person's data.
List<String> _splitName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  final list = parts.toList();
  if (list.isEmpty) return const ['User', ''];
  return [list.first, list.skip(1).join(' ')];
}

// ── Profile ─────────────────────────────────────────────────────────────────

Future<dynamic> _getUser(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final user = await _loadUserOrThrow(userId);
  if (user['banned'] == true) throw _banned(user['banReason']?.toString());
  return user;
}

Future<dynamic> _getMe(GatewayRequest request) async {
  final userId = request.optionalString('userId');
  if (userId == null || userId.isEmpty) {
    throw const GatewayError('Unauthorized.', status: 401);
  }
  return _getUser(
    GatewayRequest(
      method: 'GET',
      path: request.path,
      segments: ['', userId],
      query: request.query,
    ),
  );
}

GatewayError _banned(String? reason) => GatewayError(
  'Your account has been suspended.',
  status: 403,
  banned: true,
  banReason: reason,
);

Future<dynamic> _updateProfile(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final body = request.body ?? const <String, dynamic>{};

  final email = body['email']?.toString().trim().toLowerCase() ?? '';
  final name = body['name']?.toString() ?? '';
  if (email.isEmpty) throw const GatewayError('A valid email is required.');
  if (name.trim().length < 2) {
    throw const GatewayError('Name must be at least 2 characters.');
  }

  final existing = await SupabaseGateway.table('User')
      .select('id')
      .eq('id', userId)
      .limit(1);
  if (existing.isEmpty) {
    throw const GatewayError('User not found.', status: 404);
  }

  final parts = _splitName(name);
  try {
    await SupabaseGateway.table('User')
        .update({
          'email': email,
          'firstName': parts[0],
          'lastName': parts[1],
          'phone': body['phone']?.toString().trim().isEmpty == true
              ? null
              : body['phone'],
          'avatarUrl': body['avatarUrl']?.toString().trim().isEmpty == true
              ? null
              : body['avatarUrl'],
        })
        .eq('id', userId);
  } catch (error) {
    if (error.toString().contains('23505')) {
      throw const GatewayError(
        'That email is already being used by another account.',
        status: 409,
      );
    }
    rethrow;
  }

  return _loadUserOrThrow(userId);
}

// ── Addresses ───────────────────────────────────────────────────────────────

Map<String, dynamic> _addressPayload(GatewayRequest request) {
  final body = request.body ?? const <String, dynamic>{};
  final label = body['label']?.toString().trim() ?? '';
  if (label.isEmpty) throw const GatewayError('A label is required.');
  return body;
}

Future<void> _clearDefault(String userId) async {
  await SupabaseGateway.table('Address')
      .update({'isDefault': false})
      .eq('userId', userId)
      .eq('isDefault', true);
}

Future<dynamic> _createAddress(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final body = _addressPayload(request);

  final existing = await SupabaseGateway.table('Address')
      .select('id')
      .eq('userId', userId);
  final wantDefault = body['isDefault'] == true || existing.isEmpty;

  final quartier = body['quartier']?.toString().trim();
  final city = body['city']?.toString().trim();
  final addressLine = body['address']?.toString().trim();

  final line1 = (addressLine != null && addressLine.isNotEmpty)
      ? addressLine
      : (quartier != null && quartier.isNotEmpty)
          ? quartier
          : (city != null && city.isNotEmpty)
              ? city
              : body['label'].toString().trim();

  if (wantDefault) await _clearDefault(userId);

  await SupabaseGateway.table('Address').insert({
    'userId': userId,
    'label': body['label'],
    'line1': line1,
    'line2': (quartier == null || quartier.isEmpty) ? null : quartier,
    'city': (city == null || city.isEmpty) ? null : city,
    'postalCode': body['zipCode']?.toString().trim().isEmpty == true
        ? null
        : body['zipCode'],
    'latitude': body['latitude'],
    'longitude': body['longitude'],
    'isDefault': wantDefault,
  });

  return _loadUserOrThrow(userId);
}

Future<Map<String, dynamic>> _loadAddressOrThrow(
  String userId,
  String addressId,
) async {
  final rows = await SupabaseGateway.table('Address')
      .select(_addressColumns)
      .eq('id', addressId)
      .eq('userId', userId)
      .limit(1);
  if (rows.isEmpty) {
    throw const GatewayError('Address not found.', status: 404);
  }
  return rows.first;
}

Future<dynamic> _updateAddress(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final addressId = request.requireSegment(3, 'addressId');
  final current = await _loadAddressOrThrow(userId, addressId);
  final body = request.body ?? const <String, dynamic>{};

  final hasAddress = body.containsKey('address');
  final hasLatitude = body.containsKey('latitude');
  final hasLongitude = body.containsKey('longitude');

  final nextCity = !body.containsKey('city')
      ? current['city']
      : body['city']?.toString().trim().isEmpty == true
          ? null
          : body['city']?.toString().trim();

  final nextQuartier = !body.containsKey('quartier')
      ? current['line2']
      : body['quartier']?.toString().trim().isEmpty == true
          ? null
          : body['quartier']?.toString().trim();

  final submittedLine = body['address']?.toString().trim();
  final nextLine1 = hasAddress
      ? ((submittedLine != null && submittedLine.isNotEmpty)
            ? submittedLine
            : (nextQuartier != null && nextQuartier.isNotEmpty)
                ? nextQuartier
                : (nextCity != null && nextCity.isNotEmpty)
                    ? nextCity
                    : current['label'])
      : ((current['line1']?.toString().isNotEmpty ?? false)
            ? current['line1']
            : (nextQuartier != null && nextQuartier.isNotEmpty)
                ? nextQuartier
                : (nextCity != null && nextCity.isNotEmpty)
                    ? nextCity
                    : current['label']);

  final makeDefault = body['isDefault'] == true;
  if (makeDefault) await _clearDefault(userId);

  await SupabaseGateway.table('Address')
      .update({
        'label': body['label'] ?? current['label'],
        'line1': nextLine1,
        'line2': nextQuartier,
        'city': nextCity,
        'postalCode': body['zipCode'] == null
            ? current['postalCode']
            : body['zipCode']?.toString().trim().isEmpty == true
                ? null
                : body['zipCode'],
        'latitude': hasLatitude ? body['latitude'] : current['latitude'],
        'longitude': hasLongitude ? body['longitude'] : current['longitude'],
        'isDefault': body['isDefault'] ?? current['isDefault'],
      })
      .eq('id', addressId)
      .eq('userId', userId);

  return _loadUserOrThrow(userId);
}

Future<dynamic> _makeAddressDefault(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final addressId = request.requireSegment(3, 'addressId');
  await _loadAddressOrThrow(userId, addressId);

  await _clearDefault(userId);
  await SupabaseGateway.table('Address')
      .update({'isDefault': true})
      .eq('id', addressId)
      .eq('userId', userId);

  return _loadUserOrThrow(userId);
}

Future<dynamic> _deleteAddress(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final addressId = request.requireSegment(3, 'addressId');
  final address = await _loadAddressOrThrow(userId, addressId);

  await SupabaseGateway.table('Address')
      .delete()
      .eq('id', addressId)
      .eq('userId', userId);

  if (address['isDefault'] == true) {
    final replacement = await SupabaseGateway.table('Address')
        .select('id')
        .eq('userId', userId)
        .order('updatedAt', ascending: false)
        .limit(1);
    if (replacement.isNotEmpty) {
      await SupabaseGateway.table('Address')
          .update({'isDefault': true})
          .eq('id', replacement.first['id']);
    }
  }

  return _loadUserOrThrow(userId);
}

// ── Payment methods ─────────────────────────────────────────────────────────

const String _methodColumns =
    'id,type,brand,last4,expiryMonth,expiryYear,isDefault';

Future<List<Map<String, dynamic>>> _loadPaymentMethods(String userId) {
  return SupabaseGateway.table('PaymentMethod')
      .select(_methodColumns)
      .eq('userId', userId)
      .order('isDefault', ascending: false)
      .order('updatedAt', ascending: false);
}

Future<dynamic> _listPaymentMethods(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  return _loadPaymentMethods(userId);
}

Future<dynamic> _createPaymentMethod(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final body = request.body ?? const <String, dynamic>{};

  final type = body['type']?.toString();
  if (type == null || type.isEmpty) throw const GatewayError('type is required.');

  if (body['isDefault'] == true) {
    await SupabaseGateway.table('PaymentMethod')
        .update({'isDefault': false})
        .eq('userId', userId)
        .eq('isDefault', true);
  }

  await SupabaseGateway.table('PaymentMethod').insert({
    'userId': userId,
    'type': type,
    'brand': body['brand']?.toString().trim().isEmpty == true
        ? null
        : body['brand'],
    'last4': body['last4']?.toString().trim().isEmpty == true
        ? null
        : body['last4'],
    'expiryMonth': body['expiryMonth'],
    'expiryYear': body['expiryYear'],
    'isDefault': body['isDefault'] ?? false,
  });

  return _loadPaymentMethods(userId);
}

Future<dynamic> _makePaymentMethodDefault(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final methodId = request.requireSegment(3, 'paymentMethodId');

  await SupabaseGateway.table('PaymentMethod')
      .update({'isDefault': false})
      .eq('userId', userId)
      .eq('isDefault', true);

  final updated = await SupabaseGateway.table('PaymentMethod')
      .update({'isDefault': true})
      .eq('id', methodId)
      .eq('userId', userId)
      .select('id');

  if (updated.isEmpty) {
    throw const GatewayError('Payment method not found.', status: 404);
  }
  return <String, dynamic>{'success': true};
}

Future<dynamic> _deletePaymentMethod(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final methodId = request.requireSegment(3, 'paymentMethodId');

  final deleted = await SupabaseGateway.table('PaymentMethod')
      .delete()
      .eq('id', methodId)
      .eq('userId', userId)
      .select('id');

  if (deleted.isEmpty) {
    throw const GatewayError('Payment method not found.', status: 404);
  }
  return null;
}

// ── Wishlist ────────────────────────────────────────────────────────────────

const String _wishlistColumns =
    'id,moduleType,entityId,title,subtitle,imageUrl,price';

Map<String, dynamic> _serializeWishlist(Map<String, dynamic> item) =>
    <String, dynamic>{
      'id': item['id'],
      'moduleType': item['moduleType'],
      'entityId': item['entityId'],
      'title': item['title'],
      'subtitle': item['subtitle'],
      'imageUrl': item['imageUrl'],
      'price': item['price'],
    };

Future<dynamic> _listWishlist(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final items = await SupabaseGateway.table('WishlistItem')
      .select(_wishlistColumns)
      .eq('userId', userId)
      .order('createdAt', ascending: false);
  return items.map(_serializeWishlist).toList();
}

Future<dynamic> _upsertWishlistItem(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final body = request.body ?? const <String, dynamic>{};

  final moduleType = body['moduleType']?.toString();
  final entityId = body['entityId']?.toString();
  final title = body['title']?.toString();
  if (moduleType == null || moduleType.isEmpty) {
    throw const GatewayError('moduleType is required.');
  }
  if (entityId == null || entityId.isEmpty) {
    throw const GatewayError('entityId is required.');
  }
  if (title == null || title.isEmpty) throw const GatewayError('title is required.');

  final item = await SupabaseGateway.table('WishlistItem')
      .upsert(
        {
          'userId': userId,
          'moduleType': moduleType,
          'entityId': entityId,
          'title': title,
          'subtitle': body['subtitle'],
          'imageUrl': body['imageUrl'],
          'price': body['price'],
        },
        onConflict: 'userId,moduleType,entityId',
      )
      .select(_wishlistColumns)
      .single();

  return _serializeWishlist(item);
}

Future<dynamic> _removeWishlistItem(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final entityId = request.requireSegment(3, 'entityId');
  final moduleType = request.optionalString('moduleType')?.toUpperCase();

  if (moduleType == null || moduleType.isEmpty) {
    throw const GatewayError('moduleType is required.');
  }

  await SupabaseGateway.table('WishlistItem')
      .delete()
      .eq('userId', userId)
      .eq('entityId', entityId)
      .eq('moduleType', moduleType);

  return null;
}

// ── Coupons ─────────────────────────────────────────────────────────────────

Future<dynamic> _listCoupons(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final coupons = await SupabaseGateway.table('UserCoupon')
      .select(
        'id,status,usedAt,expiresAt,'
        'promotion:Promotion(id,moduleType,title,description,code,'
        'discountType,discountValue,active,metadata)',
      )
      .eq('userId', userId)
      .order('createdAt', ascending: false);

  return coupons.map((coupon) {
    final rawPromotion = coupon['promotion'];
    final promotion = rawPromotion is Map
        ? Map<String, dynamic>.from(rawPromotion)
        : <String, dynamic>{};
    return <String, dynamic>{
      'id': coupon['id'],
      'status': coupon['status'],
      'usedAt': coupon['usedAt'],
      'expiresAt': coupon['expiresAt'],
      'promotion': <String, dynamic>{
        'id': promotion['id'],
        'moduleType': promotion['moduleType'],
        'title': promotion['title'],
        'description': promotion['description'],
        'code': promotion['code'],
        'discountType': promotion['discountType'],
        'discountValue': promotion['discountValue'],
        'active': promotion['active'],
        'metadata': promotion['metadata'],
      },
    };
  }).toList();
}
