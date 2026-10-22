import 'dart:math' as math;

import '../supabase_gateway.dart';
import 'gateway_router.dart';

/// `/catalog/*` — the public browsing surface.
///
/// All of it is readable under the `*_public_read` RLS policies (anon and
/// authenticated alike), so these handlers only translate Prisma queries into
/// PostgREST and reproduce the legacy JSON shapes.
void register() {
  GatewayRouter.get('/catalog/products', _products);
  GatewayRouter.get('/catalog/products/:id', _productDetail);
  GatewayRouter.get('/catalog/categories', _categories);
  GatewayRouter.get('/catalog/pharmacies', _pharmacies);
  GatewayRouter.get('/catalog/shopping-stores', _shoppingStores);
  GatewayRouter.get('/catalog/shopping-stores/:id', _shoppingStoreDetail);
  GatewayRouter.get('/catalog/doctors', _doctors);
  GatewayRouter.get('/catalog/doctors/:id', _doctorDetail);
  GatewayRouter.get('/catalog/home-service-categories', _homeServiceCategories);
  GatewayRouter.get('/catalog/home-service-providers', _homeServiceProviders);
  GatewayRouter.get(
    '/catalog/home-service-providers/:id',
    _homeServiceProviderDetail,
  );
  GatewayRouter.get('/catalog/restaurants', _restaurants);
  GatewayRouter.get('/catalog/restaurants/:id', _restaurantDetail);
  GatewayRouter.get('/catalog/hotels', _hotels);
  GatewayRouter.get('/catalog/hotels/:id', _hotelDetail);
  GatewayRouter.get('/catalog/ride-categories', _rideCategories);
  GatewayRouter.get('/catalog/laundry-services', _laundryServices);
  GatewayRouter.get('/catalog/health-services/tests', _healthServiceTests);
  GatewayRouter.get(
    '/catalog/health-services/physiotherapy',
    _physiotherapyServices,
  );
}

// ── Shared helpers ──────────────────────────────────────────────────────────

/// Reads a numeric column the way the backend's `toNumber` did.
///
/// Prisma returns `Decimal` and JS collapses it to a plain number, so an
/// integral value crossed the wire as `700`, never `700.0`. PostgREST hands
/// Dart a double for `numeric`, so integral values are converted back to int
/// to keep the payloads byte-compatible with what the app was built against.
num? _num(dynamic value) {
  if (value == null) return null;
  final parsed = value is num ? value : num.tryParse(value.toString());
  if (parsed == null) return null;
  if (parsed is double) return _integral(parsed) ? parsed.toInt() : parsed;
  return parsed;
}

bool _integral(double value) =>
    value == value.roundToDouble() && value.abs() < 9007199254740992;

/// Rounds to [decimals] places then normalizes like `toNumber`, mirroring the
/// backend's `Number(x.toFixed(n))` for computed values (room prices,
/// distances, tax rates…).
num _fixed(int decimals, double value) {
  final rounded = double.parse(value.toStringAsFixed(decimals));
  return _integral(rounded) ? rounded.toInt() : rounded;
}

double _toDouble(dynamic value, {double orElse = 0}) =>
    _num(value)?.toDouble() ?? orElse;

List<String> _stringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .whereType<String>()
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}

/// Narrows an embedded PostgREST resource (always a `Map` at runtime) to the
/// typed map the serializers expect.
Map<String, dynamic>? _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

double? _finite(dynamic value) {
  if (value is num) return value.isFinite ? value.toDouble() : null;
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

bool _readBool(dynamic value) {
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  return normalized == '1' ||
      normalized == 'true' ||
      normalized == 'yes' ||
      normalized == 'y';
}

/// `cityZone` filtering: a listing matches when its zone list contains the
/// requested key, or when the list is empty (global listings stay visible in
/// every city) — exactly the backend's `cityZoneFilter` OR.
List<Map<String, dynamic>> _zoneFilter(
  List<Map<String, dynamic>> rows,
  String? zoneKey,
) {
  if (zoneKey == null || zoneKey.isEmpty) return rows;
  return rows.where((row) {
    final raw = row['cityZone'];
    if (raw is! List) return true;
    if (raw.isEmpty) return true;
    return raw.map((entry) => entry.toString()).contains(zoneKey);
  }).toList();
}

Future<String?> _zoneKey(GatewayRequest request) {
  return SupabaseGateway.resolveZoneKey(
    zone: request.optionalString('zone'),
    latitude: _finite(request.param('latitude')),
    longitude: _finite(request.param('longitude')),
  );
}

int _compareNullableAsc(num? left, num? right) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return left.compareTo(right);
}

// ── Product / medicine ──────────────────────────────────────────────────────

const String _productSelect =
    '*,category:ProductCategory(id,name),shop:ShoppingStore(name)';

Map<String, dynamic> _serializeProduct(
  Map<String, dynamic> product, {
  Map<String, dynamic>? category,
  Map<String, dynamic>? shop,
}) {
  final categoryName = category?['name'];
  return <String, dynamic>{
    'id': product['id'],
    'moduleType': product['moduleType'],
    'categoryId': product['categoryId'],
    'category': categoryName ?? product['categoryId'],
    'name': product['name'],
    'brand': product['brand'],
    'description': product['description'],
    'price': _num(product['price']),
    'originalPrice': _num(product['originalPrice']),
    'unit': product['unit'],
    'dosage': product['dosage'],
    'packageSize': product['packageSize'],
    'requiresPrescription': product['requiresPrescription'],
    'rating': _num(product['rating']),
    'reviewCount': product['reviewCount'],
    'images': _stringList(product['imageUrlsJson']),
    'colors': _stringList(product['colorsJson']),
    'sizes': _stringList(product['sizesJson']),
    'tags': _stringList(product['tagsJson']),
    'features': _stringList(product['featuresJson']),
    'badge': product['badge'],
    'inStock': product['inStock'],
    'isOrganic': product['isOrganic'],
    'metadata': product['metadata'],
    'shopId': product['shopId'],
    'shopName': shop?['name'] ?? product['brand'],
  };
}

Map<String, dynamic> _serializeMedicineAsProduct(
  Map<String, dynamic> medicine, {
  Map<String, dynamic>? pharmacy,
  Map<String, dynamic>? category,
}) {
  final pharmacyName = pharmacy?['name']?.toString() ?? '';
  final rawMetadata = medicine['metadata'];
  final metadata = <String, dynamic>{
    if (rawMetadata is Map) ...rawMetadata,
    'sourceBusiness': pharmacyName,
  };

  return <String, dynamic>{
    'id': medicine['id'],
    'moduleType': 'PHARMACY',
    'categoryId': medicine['categoryId'],
    'category': category?['name'] ?? medicine['categoryId'],
    'name': medicine['name'],
    'brand': pharmacyName,
    'description': medicine['description'],
    'price': _num(medicine['price']),
    'originalPrice': _num(medicine['originalPrice']),
    'unit': medicine['unit'],
    'dosage': medicine['dosage'],
    'packageSize': medicine['packageSize'],
    'requiresPrescription': medicine['requiresPrescription'],
    'rating': _num(medicine['rating']),
    'reviewCount': medicine['reviewCount'],
    'images': _stringList(medicine['imageUrlsJson']),
    'tags': _stringList(medicine['tagsJson']),
    'features': _stringList(medicine['featuresJson']),
    'badge': medicine['badge'],
    'inStock': medicine['inStock'],
    'isOrganic': false,
    'metadata': metadata,
    'shopId': medicine['pharmacyId'],
    'shopName': pharmacyName,
  };
}

Future<dynamic> _products(GatewayRequest request) async {
  final moduleType = request.optionalString('moduleType')?.toUpperCase();
  final categoryId = request.optionalString('categoryId');
  final zoneKey = await _zoneKey(request);

  // Pharmacy medicines live in their own table but are served through the
  // legacy product payload so PharmacyModel.fromApi keeps working.
  if (moduleType == 'PHARMACY') {
    var query = SupabaseGateway.table('Medicine').select(
      '*,pharmacy:Pharmacy(id,name,cityZone),category:ProductCategory(name)',
    );
    if (categoryId != null) query = query.eq('categoryId', categoryId);
    final medicines = await query.order('createdAt', ascending: false);

    final zoneFiltered = _zoneFilter(
      medicines.map((row) {
        final raw = row['pharmacy'];
        if (raw is! Map) return row;
        return <String, dynamic>{
          ...row,
          'cityZone': raw['cityZone'],
        };
      }).toList(),
      zoneKey,
    );

    return zoneFiltered.map((medicine) {
      final rawPharmacy = medicine['pharmacy'];
      final rawCategory = medicine['category'];
      return _serializeMedicineAsProduct(
        medicine,
        pharmacy: _asMap(rawPharmacy),
        category: _asMap(rawCategory),
      );
    }).toList();
  }

  var query = SupabaseGateway.table('Product').select(_productSelect);
  if (moduleType != null && moduleType.isNotEmpty) {
    query = query.eq('moduleType', moduleType);
  }
  if (categoryId != null) query = query.eq('categoryId', categoryId);
  final products = await query.order('createdAt', ascending: false);

  return _zoneFilter(products, zoneKey)
      .map((product) {
        final rawCategory = product['category'];
        final rawShop = product['shop'];
        return _serializeProduct(
          product,
          category: _asMap(rawCategory),
          shop: _asMap(rawShop),
        );
      })
      .toList();
}

Future<dynamic> _productDetail(GatewayRequest request) async {
  final productId = request.requireSegment(2, 'productId');

  final medicines = await SupabaseGateway.table('Medicine')
      .select('*,pharmacy:Pharmacy(id,name),category:ProductCategory(name)')
      .eq('id', productId)
      .limit(1);
  if (medicines.isNotEmpty) {
    final medicine = medicines.first;
    final rawPharmacy = medicine['pharmacy'];
    final rawCategory = medicine['category'];
    return _serializeMedicineAsProduct(
      medicine,
      pharmacy: _asMap(rawPharmacy),
      category: _asMap(rawCategory),
    );
  }

  final products = await SupabaseGateway.table('Product')
      .select(_productSelect)
      .eq('id', productId)
      .limit(1);
  if (products.isEmpty) {
    throw const GatewayError('Product not found.', status: 404);
  }

  final product = products.first;
  final rawCategory = product['category'];
  final rawShop = product['shop'];
  return _serializeProduct(
    product,
    category: _asMap(rawCategory),
    shop: _asMap(rawShop),
  );
}

Future<dynamic> _categories(GatewayRequest request) async {
  final moduleType = request.optionalString('moduleType')?.toUpperCase();

  var query = SupabaseGateway.table('ProductCategory').select('*');
  if (moduleType != null && moduleType.isNotEmpty) {
    query = query.eq('moduleType', moduleType);
  }
  final categories = await query
      .order('sortOrder', ascending: true)
      .order('name', ascending: true);

  return categories
      .map(
        (category) => <String, dynamic>{
          'id': category['id'],
          'name': category['name'],
          'slug': category['slug'],
          'sortOrder': category['sortOrder'],
          'active': category['active'],
        },
      )
      .toList();
}

// ── Pharmacies ──────────────────────────────────────────────────────────────

Future<dynamic> _pharmacies(GatewayRequest request) async {
  final latitude = _finite(request.param('latitude'));
  final longitude = _finite(request.param('longitude'));
  final nearOnly = _readBool(request.param('nearOnly'));
  final sortBy = request.optionalString('sort')?.trim().toLowerCase() ?? 'distance';
  final radiusRaw = _finite(request.param('radiusKm'));
  final radiusKm = radiusRaw != null && radiusRaw > 0
      ? math.min(radiusRaw, 25.0)
      : 5.0;
  final zoneKey = await _zoneKey(request);

  final pharmacies = await SupabaseGateway.table('Pharmacy').select(
    '*,medicines:Medicine(price,requiresPrescription)',
  );
  final ordered = _zoneFilter(pharmacies, zoneKey)
    ..sort((left, right) {
      final byRating = _toDouble(right['rating']).compareTo(_toDouble(left['rating']));
      if (byRating != 0) return byRating;
      return (right['reviewCount'] as num? ?? 0)
          .compareTo(left['reviewCount'] as num? ?? 0);
    });

  final directory = <Map<String, dynamic>>[];
  for (final pharmacy in ordered) {
    final rawMedicines = pharmacy['medicines'];
    final medicines = rawMedicines is List
        ? rawMedicines.whereType<Map>().toList()
        : const <Map>[];

    double? distanceKm;
    if (latitude != null &&
        longitude != null &&
        pharmacy['latitude'] != null &&
        pharmacy['longitude'] != null) {
      distanceKm = _haversine(
        (pharmacy['latitude'] as num).toDouble(),
        (pharmacy['longitude'] as num).toDouble(),
        latitude,
        longitude,
      );
    }

    final prices = medicines
        .map((medicine) => _num(medicine['price']))
        .whereType<num>()
        .toList();

    final entry = <String, dynamic>{
      'id': pharmacy['id'],
      'name': pharmacy['name'],
      'businessKey': _normalizeBusinessName(pharmacy['name'].toString()),
      'rating': _num(pharmacy['rating']) ?? 0,
      'reviewCount': pharmacy['reviewCount'],
      'productCount': medicines.length,
      'prescriptionCount':
          medicines.where((m) => m['requiresPrescription'] == true).length,
      'minPrice': prices.isEmpty
          ? null
          : _fixed(2, prices.reduce(math.min).toDouble()),
      'location': pharmacy['latitude'] == null || pharmacy['longitude'] == null
          ? null
          : <String, dynamic>{
              'latitude': pharmacy['latitude'],
              'longitude': pharmacy['longitude'],
              'address': pharmacy['address'],
            },
      'distanceKm': distanceKm == null ? null : _fixed(3, distanceKm),
    };

    if (nearOnly) {
      final distance = entry['distanceKm'];
      if (distance is! num || distance > radiusKm) continue;
    }
    directory.add(entry);
  }

  directory.sort((left, right) {
    if (sortBy == 'rating') {
      final byRating = _toDouble(right['rating']).compareTo(_toDouble(left['rating']));
      if (byRating != 0) return byRating;
      final byReviews = (right['reviewCount'] as num? ?? 0)
          .compareTo(left['reviewCount'] as num? ?? 0);
      if (byReviews != 0) return byReviews;
      return _compareNullableAsc(
        (left['distanceKm'] as num?)?.toDouble(),
        (right['distanceKm'] as num?)?.toDouble(),
      );
    }
    if (sortBy == 'reviews') {
      final byReviews = (right['reviewCount'] as num? ?? 0)
          .compareTo(left['reviewCount'] as num? ?? 0);
      if (byReviews != 0) return byReviews;
      final byRating = _toDouble(right['rating']).compareTo(_toDouble(left['rating']));
      if (byRating != 0) return byRating;
      return _compareNullableAsc(
        (left['distanceKm'] as num?)?.toDouble(),
        (right['distanceKm'] as num?)?.toDouble(),
      );
    }
    return _compareNullableAsc(
      (left['distanceKm'] as num?)?.toDouble(),
      (right['distanceKm'] as num?)?.toDouble(),
    );
  });

  return directory;
}

String _normalizeBusinessName(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll(RegExp("[’']"), "'")
    .replaceAll(RegExp(r'\s+'), ' ');

// ── Shopping stores ─────────────────────────────────────────────────────────

Map<String, dynamic> _serializeShoppingStore(
  Map<String, dynamic> store,
  List<Map<String, dynamic>> products,
) {
  final categories = <String>{
    for (final product in products)
      (product['category'] is Map
              ? (product['category'] as Map)['name']
              : product['categoryId'])
          ?.toString() ??
          '',
  }.where((entry) => entry.isNotEmpty).toList();

  return <String, dynamic>{
    'id': store['slug'],
    'name': store['name'],
    'tagline': store['tagline'] ?? 'Curated shopping picks for every style.',
    'imageUrl': store['imageUrl'] ?? '',
    'rating': _num(store['rating']) ?? 0,
    'reviewCount': store['reviewCount'],
    'productCount': products.length,
    'categories': categories,
    'badge': store['badge'],
    'minPrice': _num(store['minPrice']) ?? 0,
    'maxPrice': _num(store['maxPrice']) ?? 0,
    'highlights': _stringList(store['highlightsJson']),
  };
}

Future<List<Map<String, dynamic>>> _storeProducts(String storeId) {
  return SupabaseGateway.table('Product')
      .select(_productSelect)
      .eq('moduleType', 'SHOPPING')
      .eq('shopId', storeId)
      .order('rating', ascending: false)
      .order('reviewCount', ascending: false);
}

Future<dynamic> _shoppingStores(GatewayRequest request) async {
  final zoneKey = await _zoneKey(request);
  final stores = await SupabaseGateway.table('ShoppingStore')
      .select('*')
      .order('rating', ascending: false)
      .order('reviewCount', ascending: false);

  final result = <Map<String, dynamic>>[];
  for (final store in _zoneFilter(stores, zoneKey)) {
    final products = await _storeProducts(store['id'].toString());
    if (products.isEmpty) continue;
    result.add(_serializeShoppingStore(store, products));
  }
  return result;
}

Future<dynamic> _shoppingStoreDetail(GatewayRequest request) async {
  final storeId = request.requireSegment(2, 'storeId');
  final zoneKey = await _zoneKey(request);

  // The list payload exposes `slug` as the id, so detail lookups always use it.
  final stores = await SupabaseGateway.table('ShoppingStore')
      .select('*')
      .eq('slug', storeId)
      .limit(1);
  if (stores.isEmpty ||
      (zoneKey != null && _zoneFilter(stores, zoneKey).isEmpty)) {
    throw const GatewayError('Store not found.', status: 404);
  }

  final store = stores.first;
  final products = await _storeProducts(store['id'].toString());
  return <String, dynamic>{
    ..._serializeShoppingStore(store, products),
    'products': products
        .map(
          (product) => _serializeProduct(
            product,
            category: _asMap(product['category']),
            shop: _asMap(product['shop']),
          ),
        )
        .toList(),
  };
}

// ── Doctors ─────────────────────────────────────────────────────────────────

Map<String, dynamic> _serializeDoctor(
  Map<String, dynamic> doctor, {
  List<Map<String, dynamic>>? reviews,
}) =>
    <String, dynamic>{
      'id': doctor['id'],
      'name': doctor['name'],
      'specialty': doctor['specialty'],
      'providerType': doctor['providerType'],
      'rating': _num(doctor['rating']),
      'reviewCount': doctor['reviewCount'],
      'experience': doctor['experience'],
      'consultationFee': _num(doctor['consultationFee']),
      'isAvailable': doctor['isAvailable'],
      'isSignedUp': doctor['isSignedUp'],
      'imageUrl': doctor['imageUrl'],
      'about': doctor['about'],
      'location': doctor['location'],
      'contactPhone': doctor['contactPhone'],
      'contactWhatsApp': doctor['contactWhatsApp'],
      'languages': doctor['languagesJson'] ?? <dynamic>[],
      'services': doctor['servicesJson'] ?? <dynamic>[],
      'careModes': doctor['careModesJson'] ?? <dynamic>[],
      'workingHours': doctor['workingHoursJson'] ?? <String, dynamic>{},
      if (reviews != null)
        'reviews': reviews
            .map(
              (review) => <String, dynamic>{
                'id': review['id'],
                'name': review['reviewer'],
                'rating': review['rating'],
                'comment': review['comment'],
                'date': review['dateLabel'],
                'avatarUrl': review['avatarUrl'],
              },
            )
            .toList(),
    };

Future<dynamic> _doctors(GatewayRequest request) async {
  final zoneKey = await _zoneKey(request);
  final doctors = await SupabaseGateway.table('Doctor').select('*');
  final ordered = _zoneFilter(doctors, zoneKey)
    ..sort((left, right) {
      final byRating = _toDouble(right['rating']).compareTo(_toDouble(left['rating']));
      if (byRating != 0) return byRating;
      return (right['reviewCount'] as num? ?? 0)
          .compareTo(left['reviewCount'] as num? ?? 0);
    });
  return ordered.map((doctor) => _serializeDoctor(doctor)).toList();
}

Future<dynamic> _doctorDetail(GatewayRequest request) async {
  final doctorId = request.requireSegment(2, 'doctorId');
  final doctors = await SupabaseGateway.table('Doctor')
      .select('*')
      .eq('id', doctorId)
      .limit(1);
  if (doctors.isEmpty) {
    throw const GatewayError('Doctor not found.', status: 404);
  }

  final reviews = await SupabaseGateway.table('DoctorReview')
      .select('*')
      .eq('doctorId', doctorId)
      .order('createdAt', ascending: false);

  return _serializeDoctor(doctors.first, reviews: reviews);
}

// ── Home services ───────────────────────────────────────────────────────────

Map<String, dynamic> _serializeHomeServiceCategory(
  Map<String, dynamic> category, {
  int providerCount = 0,
}) =>
    <String, dynamic>{
      'id': category['id'],
      'name': category['name'],
      'slug': category['slug'],
      'description': category['description'],
      'iconKey': category['iconKey'],
      'colorHex': category['colorHex'],
      'providerCount': providerCount,
    };

Future<dynamic> _homeServiceCategories(GatewayRequest request) async {
  final categories = await SupabaseGateway.table('HomeServiceCategory')
      .select('*')
      .eq('active', true)
      .order('sortOrder', ascending: true);

  final providers = await SupabaseGateway.table('HomeServiceProvider')
      .select('id,categoryId')
      .eq('isAvailable', true);
  final countByCategory = <String, int>{};
  for (final provider in providers) {
    final key = provider['categoryId']?.toString();
    if (key == null) continue;
    countByCategory[key] = (countByCategory[key] ?? 0) + 1;
  }

  return categories
      .map(
        (category) => _serializeHomeServiceCategory(
          category,
          providerCount: countByCategory[category['id'].toString()] ?? 0,
        ),
      )
      .toList();
}

Map<String, dynamic> _serializeHomeServiceProvider(
  Map<String, dynamic> provider, {
  Map<String, dynamic>? category,
}) =>
    <String, dynamic>{
      'id': provider['id'],
      'categoryId': provider['categoryId'],
      'category': category == null
          ? null
          : <String, dynamic>{
              'id': category['id'],
              'name': category['name'],
              'slug': category['slug'],
              'iconKey': category['iconKey'],
              'colorHex': category['colorHex'],
            },
      'name': provider['name'],
      'title': provider['title'],
      'rating': _num(provider['rating']),
      'reviewCount': provider['reviewCount'],
      'yearsExperience': provider['yearsExperience'],
      'startingPrice': _num(provider['startingPrice']),
      'isAvailable': provider['isAvailable'],
      'isVerified': provider['isVerified'],
      'responseTime': provider['responseTime'],
      'imageUrl': provider['imageUrl'],
      'about': provider['about'],
      'location': provider['location'],
      'contactPhone': provider['contactPhone'],
      'services': _stringList(provider['servicesJson']),
      'highlights': _stringList(provider['highlightsJson']),
      'bookingModes': _stringList(provider['bookingModesJson']),
      'availability': provider['availabilityJson'] ?? <String, dynamic>{},
    };

Map<String, dynamic> _serviceZone(dynamic value) {
  const defaults = <String, dynamic>{
    'enabled': false,
    'centerLatitude': null,
    'centerLongitude': null,
    'radiusKm': 1.0,
  };
  final map = value is Map ? value : const <String, dynamic>{};
  final nestedRaw = map['serviceZone'];
  final nested = nestedRaw is Map ? nestedRaw : const <String, dynamic>{};

  final radius = _finite(nested['radiusKm'] ?? defaults['radiusKm']);
  return <String, dynamic>{
    'enabled': nested['enabled'] == null
        ? defaults['enabled']
        : _readBool(nested['enabled']),
    'centerLatitude': _finite(nested['centerLatitude']),
    'centerLongitude': _finite(nested['centerLongitude']),
    'radiusKm': radius != null && radius > 0 && radius <= 120 ? radius : 1.0,
  };
}

Future<dynamic> _homeServiceProviders(GatewayRequest request) async {
  final categorySlug = request.optionalString('category');
  final availableOnly = _readBool(request.param('availableOnly'));
  final nearOnly = _readBool(request.param('nearOnly'));
  final latitude = _finite(request.param('latitude'));
  final longitude = _finite(request.param('longitude'));
  final hasSearchLocation = latitude != null && longitude != null;
  final minRating = _finite(request.param('minRating'));
  final minReviewsRaw = _finite(request.param('minReviews'));
  final minReviews = minReviewsRaw != null ? math.max(0, minReviewsRaw) : null;
  final sortBy = request.optionalString('sort')?.trim().toLowerCase() ?? 'distance';
  final limitRaw = _finite(request.param('limit'));
  final limit = limitRaw?.round();
  final requestedRadiusRaw = _finite(request.param('radiusKm'));
  final requestedRadiusKm = nearOnly
      ? math.min(math.max(requestedRadiusRaw ?? 1, 0.1), 1.0)
      : (requestedRadiusRaw != null && requestedRadiusRaw > 0
            ? requestedRadiusRaw
            : null);
  final zoneKey = await _zoneKey(request);

  var query = SupabaseGateway.table('HomeServiceProvider')
      .select('*,category:HomeServiceCategory(id,name,slug,iconKey,colorHex)');
  if (availableOnly) query = query.eq('isAvailable', true);
  final rows = await query
      .order('rating', ascending: false)
      .order('reviewCount', ascending: false);

  // Backend filtered on `category.slug` through the relation; we embed the
  // category, so apply the same predicate over the embedded value.
  final candidates = categorySlug == null
      ? rows
      : rows.where((provider) {
          final category = _asMap(provider['category']);
          return category != null && category['slug'] == categorySlug;
        }).toList();

  final mapped = <Map<String, dynamic>>[];
  for (final provider in _zoneFilter(candidates, zoneKey)) {
    final rawCategory = provider['category'];
    final zone = _serviceZone(provider['availabilityJson']);

    double? distanceKm;
    if (latitude != null &&
        longitude != null &&
        zone['centerLatitude'] != null &&
        zone['centerLongitude'] != null) {
      distanceKm = _haversine(
        (zone['centerLatitude'] as num).toDouble(),
        (zone['centerLongitude'] as num).toDouble(),
        latitude,
        longitude,
      );
    }

    final withinProviderZone = distanceKm != null &&
        zone['enabled'] == true &&
        distanceKm <= (zone['radiusKm'] as num).toDouble();
    final withinRequestedRadius = distanceKm != null && requestedRadiusKm != null
        ? distanceKm <= requestedRadiusKm
        : null;
    final matchesNearbyScope = nearOnly &&
        hasSearchLocation &&
        withinProviderZone &&
        (withinRequestedRadius ?? false);

    final serialized = _serializeHomeServiceProvider(
      provider,
      category: _asMap(rawCategory),
    )
      ..['serviceZone'] = zone
      ..['distanceKm'] = distanceKm == null ? null : _fixed(3, distanceKm)
      ..['withinProviderZone'] = withinProviderZone
      ..['withinRequestedRadius'] = withinRequestedRadius
      ..['matchesNearbyScope'] = matchesNearbyScope;

    final rating = _num(serialized['rating']) ?? 0;
    final reviews = (serialized['reviewCount'] as num?) ?? 0;
    if (minRating != null && rating < minRating) continue;
    if (minReviews != null && reviews < minReviews) continue;
    if (nearOnly && !matchesNearbyScope) continue;

    mapped.add(serialized);
  }

  mapped.sort((left, right) {
    if (sortBy == 'rating') {
      final byRating =
          _toDouble(right['rating']).compareTo(_toDouble(left['rating']));
      if (byRating != 0) return byRating;
      final byReviews = ((right['reviewCount'] as num?) ?? 0)
          .compareTo((left['reviewCount'] as num?) ?? 0);
      if (byReviews != 0) return byReviews;
      return _compareNullableAsc(
        (left['distanceKm'] as num?)?.toDouble(),
        (right['distanceKm'] as num?)?.toDouble(),
      );
    }
    if (sortBy == 'reviews') {
      final byReviews = ((right['reviewCount'] as num?) ?? 0)
          .compareTo((left['reviewCount'] as num?) ?? 0);
      if (byReviews != 0) return byReviews;
      final byRating =
          _toDouble(right['rating']).compareTo(_toDouble(left['rating']));
      if (byRating != 0) return byRating;
      return _compareNullableAsc(
        (left['distanceKm'] as num?)?.toDouble(),
        (right['distanceKm'] as num?)?.toDouble(),
      );
    }
    final byDistance = _compareNullableAsc(
      (left['distanceKm'] as num?)?.toDouble(),
      (right['distanceKm'] as num?)?.toDouble(),
    );
    if (byDistance != 0) return byDistance;
    final byRating =
        _toDouble(right['rating']).compareTo(_toDouble(left['rating']));
    if (byRating != 0) return byRating;
    return ((right['reviewCount'] as num?) ?? 0)
        .compareTo((left['reviewCount'] as num?) ?? 0);
  });

  final limited = (limit != null && limit > 0)
      ? mapped.sublist(0, math.min(limit, mapped.length))
      : mapped;

  return limited.map((provider) {
    final copy = Map<String, dynamic>.from(provider);
    copy.remove('matchesNearbyScope');
    return copy;
  }).toList();
}

Future<dynamic> _homeServiceProviderDetail(GatewayRequest request) async {
  final providerId = request.requireSegment(2, 'providerId');
  final rows = await SupabaseGateway.table('HomeServiceProvider')
      .select('*,category:HomeServiceCategory(id,name,slug,iconKey,colorHex)')
      .eq('id', providerId)
      .limit(1);
  if (rows.isEmpty) {
    throw const GatewayError('Home service provider not found.', status: 404);
  }
  final rawCategory = rows.first['category'];
  return _serializeHomeServiceProvider(
    rows.first,
    category: _asMap(rawCategory),
  );
}

// ── Restaurants ─────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _serializeRestaurantMenu({
  List<Map<String, dynamic>> menuCategories = const [],
  required List<Map<String, dynamic>> menuItems,
}) {
  final hasCategories = menuCategories.isNotEmpty;
  final categories = hasCategories
      ? menuCategories
      : <Map<String, dynamic>>[
          {'id': 'menu', 'name': 'Menu', 'sortOrder': 9999},
        ];
  final knownIds = categories.map((c) => c['id'].toString()).toSet();

  Map<String, dynamic> serializeItem(Map<String, dynamic> item) =>
      <String, dynamic>{
        'id': item['id'],
        'name': item['name'],
        'description': item['description'],
        'price': _num(item['price']),
        'imageUrl': item['imageUrl'],
        'isPopular': item['isPopular'],
        'isAvailable': item['isAvailable'],
        'customizations': item['customizationsJson'] ?? <dynamic>[],
      };

  final menu = <Map<String, dynamic>>[];
  for (final category in categories) {
    final categoryId = category['id'].toString();
    final items = menuItems.where((item) {
      if (!hasCategories) return true;
      return item['categoryId']?.toString() == categoryId;
    }).map(serializeItem).toList();
    if (items.isNotEmpty) {
      menu.add({
        'name': category['name'],
        'sortOrder': category['sortOrder'] ?? 0,
        'items': items,
      });
    }
  }

  if (hasCategories) {
    final uncategorized = menuItems.where((item) {
      final id = item['categoryId']?.toString();
      return id == null || !knownIds.contains(id);
    }).map(serializeItem).toList();
    if (uncategorized.isNotEmpty) {
      menu.add({'name': 'Menu', 'sortOrder': 9999, 'items': uncategorized});
    }
  }

  menu.sort(
    (a, b) => (a['sortOrder'] as num? ?? 0).compareTo(b['sortOrder'] as num? ?? 0),
  );
  return menu
      .map(
        (entry) => <String, dynamic>{
          'name': entry['name'],
          'items': entry['items'],
        },
      )
      .toList();
}

const String _restaurantSelect =
    '*,menuCategories:RestaurantMenuCategory(id,name,sortOrder),'
    'menuItems:RestaurantMenuItem(id,categoryId,name,description,price,'
    'imageUrl,isPopular,isAvailable,customizationsJson)';

Map<String, dynamic> _serializeRestaurant(
  Map<String, dynamic> restaurant, {
  List<Map<String, dynamic>> menuCategories = const [],
  List<Map<String, dynamic>> menuItems = const [],
}) {
  final tags = _stringList(restaurant['tagsJson']);
  final sortedCategories = [...menuCategories]
    ..sort(
      (a, b) => (a['sortOrder'] as num? ?? 0).compareTo(b['sortOrder'] as num? ?? 0),
    );

  return <String, dynamic>{
    'id': restaurant['id'],
    'name': restaurant['name'],
    'cuisine': restaurant['cuisine'],
    'category': tags.isNotEmpty ? tags.first : 'International & Other',
    'rating': _num(restaurant['rating']),
    'reviewCount': restaurant['reviewCount'],
    'deliveryTime': restaurant['deliveryTime'],
    'deliveryFee': _num(restaurant['deliveryFee']),
    'imageUrl': restaurant['imageUrl'],
    'isOpen': restaurant['isOpen'],
    'distance': _num(restaurant['distanceKm']),
    'tags': tags,
    'menu': _serializeRestaurantMenu(
      menuCategories: sortedCategories,
      menuItems: menuItems,
    ),
  };
}

List<Map<String, dynamic>> _asMapList(dynamic value) => value is List
    ? value.whereType<Map<String, dynamic>>().toList()
    : const <Map<String, dynamic>>[];

Future<dynamic> _restaurants(GatewayRequest request) async {
  final zoneKey = await _zoneKey(request);
  final rows = await SupabaseGateway.table('Restaurant')
      .select(_restaurantSelect)
      .order('rating', ascending: false)
      .order('reviewCount', ascending: false);

  return _zoneFilter(rows, zoneKey)
      .map(
        (restaurant) => _serializeRestaurant(
          restaurant,
          menuCategories: _asMapList(restaurant['menuCategories']),
          menuItems: _asMapList(restaurant['menuItems']),
        ),
      )
      .toList();
}

Future<dynamic> _restaurantDetail(GatewayRequest request) async {
  final restaurantId = request.requireSegment(2, 'restaurantId');
  final rows = await SupabaseGateway.table('Restaurant')
      .select(_restaurantSelect)
      .eq('id', restaurantId)
      .limit(1);
  if (rows.isEmpty) {
    throw const GatewayError('Restaurant not found.', status: 404);
  }
  final restaurant = rows.first;
  return _serializeRestaurant(
    restaurant,
    menuCategories: _asMapList(restaurant['menuCategories']),
    menuItems: _asMapList(restaurant['menuItems']),
  );
}

// ── Hotels ──────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _hotelRoomOptions(dynamic basePriceRaw) {
  final basePrice = _num(basePriceRaw)?.toDouble() ?? 0;
  final normalized = basePrice > 0 ? basePrice : 120.0;

  num price(double multiplier) => _fixed(2, normalized * multiplier);

  return <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'standard-room',
      'name': 'Standard Room',
      'description': '1 Bed • City View',
      'pricePerNight': _fixed(2, normalized),
      'capacity': 2,
      'available': true,
    },
    <String, dynamic>{
      'id': 'premium-suite',
      'name': 'Premium Suite',
      'description': '1 King Bed • Balcony',
      'pricePerNight': price(1.45),
      'capacity': 2,
      'available': true,
    },
    <String, dynamic>{
      'id': 'family-suite',
      'name': 'Family Suite',
      'description': '2 Beds • Family Stay',
      'pricePerNight': price(1.8),
      'capacity': 4,
      'available': true,
    },
  ];
}

Map<String, dynamic> _serializeHotel(Map<String, dynamic> hotel) =>
    <String, dynamic>{
      'id': hotel['id'],
      'name': hotel['name'],
      'address': hotel['address'],
      'city': hotel['city'],
      'rating': _num(hotel['rating']),
      'reviewsCount': hotel['reviewsCount'],
      'pricePerNight': _num(hotel['pricePerNight']),
      'amenities': hotel['amenitiesJson'] ?? <dynamic>[],
      'description': hotel['description'],
      'imageUrls': hotel['imageUrlsJson'] ?? <dynamic>[],
      'roomOptions': _hotelRoomOptions(hotel['pricePerNight']),
    };

Future<dynamic> _hotels(GatewayRequest request) async {
  final zoneKey = await _zoneKey(request);
  final rows = await SupabaseGateway.table('Hotel').select('*');
  final ordered = _zoneFilter(rows, zoneKey)
    ..sort((left, right) {
      final byRating = _toDouble(right['rating']).compareTo(_toDouble(left['rating']));
      if (byRating != 0) return byRating;
      return (right['reviewsCount'] as num? ?? 0)
          .compareTo(left['reviewsCount'] as num? ?? 0);
    });
  return ordered.map(_serializeHotel).toList();
}

Future<dynamic> _hotelDetail(GatewayRequest request) async {
  final hotelId = request.requireSegment(2, 'hotelId');
  final rows = await SupabaseGateway.table('Hotel')
      .select('*')
      .eq('id', hotelId)
      .limit(1);
  if (rows.isEmpty) throw const GatewayError('Hotel not found.', status: 404);
  return _serializeHotel(rows.first);
}

// ── Ride categories ─────────────────────────────────────────────────────────

Future<dynamic> _rideCategories(GatewayRequest request) async {
  final rows = await SupabaseGateway.table('RideCategory')
      .select('*')
      .eq('active', true)
      .order('createdAt', ascending: false);

  return rows
      .map(
        (category) => <String, dynamic>{
          'id': category['id'],
          'name': category['name'],
          'description': category['description'],
          'capacity': category['capacity'],
          'basePrice': _num(category['basePrice']),
          'pricePerMile': _num(category['pricePerKm']),
          'timeToArrive': category['etaLabel'],
        },
      )
      .toList();
}

// ── Laundry services ────────────────────────────────────────────────────────

Map<String, dynamic> _defaultLaundryBookingConfig(double basePrice) {
  final washAndFoldBase =
      basePrice.isFinite && basePrice > 0 ? _num(basePrice) ?? 6000 : 6000;

  Map<String, dynamic> item(
    String id,
    String label,
    num price,
    String category, [
    String? spec,
  ]) =>
      <String, dynamic>{
        'id': id,
        'label': label,
        'price': price,
        'category': category,
        'spec': ?spec,
      };

  return <String, dynamic>{
    'itemCatalog': <Map<String, dynamic>>[
      item('shirts', 'Shirt', 700, 'unit'),
      item('t_shirt', 'T-Shirt', 500, 'unit'),
      item('polo', 'Polo', 500, 'unit'),
      item('trouser', 'Trouser', 800, 'unit'),
      item('blazer', 'Blazer', 1500, 'unit'),
      item('suit_2_pieces', 'Suit 2 pieces', 2000, 'unit'),
      item('suit_3_pieces', 'Suit 3 pieces', 2700, 'unit'),
      item('jacket', 'Jacket', 1500, 'unit'),
      item('dress', 'Dress', 1200, 'unit'),
      item(
        'wash_fold_10_20',
        'Wash & Fold 10-20 pieces',
        washAndFoldBase,
        'group',
        '10 to 20 pieces',
      ),
      item(
        'wash_fold_21_30',
        'Wash & Fold 21-30 pieces',
        12000,
        'group',
        '21 to 30 pieces',
      ),
      item(
        'wash_fold_31_40',
        'Wash & Fold 31-40 pieces',
        14500,
        'group',
        '31 to 40 pieces',
      ),
    ],
    'pickupSlots': <String>[
      '08:00 - 10:00',
      '10:00 - 12:00',
      '14:00 - 16:00',
      '16:00 - 18:00',
    ],
    'turnaroundHours': 26,
    'minNoticeHours': 0,
    'maxAdvanceDays': 5,
    'taxRatePercent': 8,
    'deliveryFee': 0,
  };
}

Map<String, dynamic> _normalizeLaundryBookingConfig(
  dynamic value,
  Map<String, dynamic> fallback,
) {
  final map = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  String normalizeId(String label, String? idValue) {
    String clean(String input) => input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fromId = clean(idValue ?? '');
    if (fromId.isNotEmpty) return fromId.substring(0, math.min(40, fromId.length));
    final fromLabel = clean(label);
    return fromLabel.substring(0, math.min(40, fromLabel.length));
  }

  final rawCatalog = map['itemCatalog'];
  final hasCatalog = rawCatalog is List;
  final catalog = <Map<String, dynamic>>[];
  if (rawCatalog is List) {
    for (final entry in rawCatalog.whereType<Map>()) {
      final label = entry['label']?.toString().trim() ?? '';
      final price = _num(entry['price']) ?? 0;
      final id = normalizeId(label, entry['id']?.toString());
      final rawCategory = entry['category']?.toString().trim().toLowerCase() ?? '';
      final inferred = (id.contains('wash_fold_') ||
              label.toLowerCase().contains('wash & fold'))
          ? 'group'
          : 'unit';
      final category =
          (rawCategory == 'group' || rawCategory == 'unit') ? rawCategory : inferred;
      final spec = entry['spec']?.toString().trim() ?? '';

      if (id.isEmpty ||
          label.isEmpty ||
          price <= 0 ||
          (category != 'unit' && category != 'group')) {
        continue;
      }
      catalog.add({
        'id': id.substring(0, math.min(40, id.length)),
        'label': label,
        'price': price,
        'category': category,
        'spec': category == 'group' && spec.isNotEmpty ? spec : null,
      });
      if (catalog.length >= 24) break;
    }
  }

  final rawSlots = map['pickupSlots'];
  final slots = <String>[];
  if (rawSlots is List) {
    for (final entry in rawSlots.whereType<String>()) {
      final trimmed = entry.trim();
      if (trimmed.isNotEmpty) slots.add(trimmed);
      if (slots.length >= 12) break;
    }
  }

  int? boundedInt(dynamic raw, int min, int max, int? fallbackValue) {
    final value = _finite(raw);
    if (value == null) return fallbackValue;
    if (value != value.roundToDouble()) return fallbackValue;
    if (value < min || value > max) return fallbackValue;
    return value.round();
  }

  final turnaround = boundedInt(
    map['turnaroundHours'],
    1,
    168,
    (fallback['turnaroundHours'] as num?)?.toInt(),
  );
  final minNotice = boundedInt(
    map['minNoticeHours'],
    0,
    72,
    (fallback['minNoticeHours'] as num?)?.toInt(),
  );
  final maxAdvance = boundedInt(
    map['maxAdvanceDays'],
    1,
    30,
    (fallback['maxAdvanceDays'] as num?)?.toInt(),
  );

  final taxRaw = _finite(map['taxRatePercent']);
  final tax = (taxRaw != null && taxRaw >= 0 && taxRaw <= 40)
      ? _fixed(2, taxRaw)
      : _num(fallback['taxRatePercent']) ?? 8;

  final deliveryRaw = _finite(map['deliveryFee']);
  final deliveryFee =
      (deliveryRaw != null && deliveryRaw >= 0 && deliveryRaw <= 100000)
      ? _fixed(2, deliveryRaw)
      : _num(fallback['deliveryFee']) ?? 0;

  return <String, dynamic>{
    'itemCatalog': hasCatalog ? catalog : fallback['itemCatalog'],
    'pickupSlots': slots.isNotEmpty ? slots : fallback['pickupSlots'],
    'turnaroundHours': turnaround ?? fallback['turnaroundHours'],
    'minNoticeHours': minNotice ?? fallback['minNoticeHours'],
    'maxAdvanceDays': maxAdvance ?? fallback['maxAdvanceDays'],
    'taxRatePercent': tax,
    'deliveryFee': deliveryFee,
  };
}

Future<dynamic> _laundryServices(GatewayRequest request) async {
  final zoneKey = await _zoneKey(request);
  final rows = await SupabaseGateway.table('LaundryService').select(
    'id,name,description,price,unit,iconUrl,bookingConfigJson,cityZone,'
    'createdAt,providerUser:User(firstName,lastName,ProProfile(businessName))',
  );

  final filtered = _zoneFilter(rows, zoneKey)
    ..sort(
      (a, b) => (b['createdAt'] ?? '').toString().compareTo((a['createdAt'] ?? '').toString()),
    );

  return filtered.map((service) {
    final price = _num(service['price']) ?? 0;
    final rawProvider = service['providerUser'];
    final provider = rawProvider is Map ? rawProvider : const <String, dynamic>{};
    final rawProfile = provider['proProfile'];
    final profile = rawProfile is Map ? rawProfile : null;

    final businessName = profile?['businessName']?.toString().trim() ?? '';
    final ownerName =
        '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
    final profileName = businessName.isNotEmpty
        ? businessName
        : (ownerName.isNotEmpty ? ownerName : null);

    final fallback = service['bookingConfigJson'] == null
        ? (_defaultLaundryBookingConfig(price.toDouble())
              ..['itemCatalog'] = <Map<String, dynamic>>[])
        : _defaultLaundryBookingConfig(price.toDouble());

    return <String, dynamic>{
      'id': service['id'],
      'name': service['name'],
      'profileName': profileName,
      'description': service['description'],
      'price': price,
      'unit': service['unit'],
      'iconUrl': service['iconUrl'],
      'bookingConfig': _normalizeLaundryBookingConfig(
        service['bookingConfigJson'],
        fallback,
      ),
    };
  }).toList();
}

// ── Geometry ────────────────────────────────────────────────────────────────

// ── Health services (lab tests + physiotherapy) ────────────────────────────

/// `GET /catalog/health-services/tests` — active lab tests ordered by
/// `sortOrder`, shaped exactly like the backend's response mapper.
Future<dynamic> _healthServiceTests(GatewayRequest request) async {
  final categoryId = request.optionalString('categoryId');
  var query = SupabaseGateway.table('LabTest').select(
    'id,categoryId,name,description,fullDescription,price,originalPrice,'
    'preparationInstructions,sampleType,durationLabel,imageUrl,active,'
    'sortOrder',
  ).eq('active', true);
  if (categoryId != null) {
    query = query.eq('categoryId', categoryId);
  }
  final rows = await query.order('sortOrder', ascending: true, nullsFirst: false);

  return rows.map((test) {
    return <String, dynamic>{
      'id': test['id'],
      'categoryId': test['categoryId'],
      'name': test['name'],
      'description': test['description'],
      'fullDescription': test['fullDescription'],
      'price': _num(test['price']),
      'originalPrice': _num(test['originalPrice']),
      'preparationInstructions': test['preparationInstructions'],
      'sampleType': test['sampleType'],
      'durationLabel': test['durationLabel'],
      'imageUrl': test['imageUrl'],
      'active': test['active'],
      'sortOrder': test['sortOrder'],
    };
  }).toList();
}

/// `GET /catalog/health-services/physiotherapy` — the backend re-labelled the
/// generic `LabTest` columns for this screen (`targetArea`, `sessionType`,
/// `therapistQualification`) and defaulted the category to `hsc-physiotherapy`.
Future<dynamic> _physiotherapyServices(GatewayRequest request) async {
  final categoryId =
      request.optionalString('categoryId') ?? 'hsc-physiotherapy';
  final rows = await SupabaseGateway.table('LabTest')
      .select(
        'id,categoryId,name,description,fullDescription,price,originalPrice,'
        'preparationInstructions,sampleType,durationLabel,imageUrl,active,'
        'sortOrder,category:HealthServiceCategory(id,name,iconKey,colorHex)',
      )
      .eq('active', true)
      .eq('categoryId', categoryId)
      .order('sortOrder', ascending: true, nullsFirst: false);

  return rows.map((service) {
    final category = service['category'] is Map
        ? Map<String, dynamic>.from(service['category'] as Map)
        : const <String, dynamic>{};
    return <String, dynamic>{
      'id': service['id'],
      'categoryId': service['categoryId'],
      'name': service['name'],
      'description': service['description'],
      'fullDescription': service['fullDescription'],
      'price': _num(service['price']),
      'originalPrice': _num(service['originalPrice']),
      'durationLabel': service['durationLabel'],
      'imageUrl': service['imageUrl'],
      'active': service['active'],
      'sortOrder': service['sortOrder'],
      'targetArea': service['preparationInstructions'],
      'sessionType': service['sampleType'],
      'therapistQualification': category['name'],
    };
  }).toList();
}

double _haversine(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  const earthRadiusKm = 6371.0;
  double toRadians(double value) => value * math.pi / 180;

  final startLat = toRadians(startLatitude);
  final endLat = toRadians(endLatitude);
  final dLat = toRadians(endLatitude - startLatitude);
  final dLon = toRadians(endLongitude - startLongitude);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(startLat) * math.cos(endLat) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
