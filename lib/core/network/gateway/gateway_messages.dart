import 'package:flutter/foundation.dart';

import '../supabase_gateway.dart';
import 'gateway_router.dart';

/// `/messages/*` — the customer side of the conversation threads, ported
/// from `backend/src/routes/messages.routes.ts` with byte-compatible
/// response shapes.
///
/// Two PostgREST realities shape the implementation:
///   * `ProProfile` is owner-only under RLS, so "which pro is bound to this
///     entity" goes through the `resolve_bound_profile_user_ids` RPC.
///   * other people's `User` rows are invisible, so courier/driver names
///     come from the `counterparty_contact` RPC (RLS-safe by design).
void register() {
  GatewayRouter.get('/messages/user/:userId', _conversationsForUser);
  GatewayRouter.get('/messages/conversations/:conversationId', _conversationDetail);
  GatewayRouter.post('/messages/conversations/start', _startConversation);
  GatewayRouter.post(
    '/messages/conversations/:conversationId/messages',
    _sendMessage,
  );
  GatewayRouter.patch('/messages/conversations/:conversationId/read', _markRead);
}

// ── Shared helpers ──────────────────────────────────────────────────────────

const List<String> _moduleTypes = [
  'SHOPPING',
  'FOOD',
  'GROCERY',
  'PHARMACY',
  'DOCTOR',
  'HOTEL',
  'RIDE',
  'LAUNDRY',
  'HOME_SERVICES',
  'HOUSE_HELP',
  'HEALTH_SERVICES',
  'PARCEL',
];

const List<String> _entityTypes = [
  'DOCTOR',
  'HOME_SERVICE_PROVIDER',
  'RIDE',
  'DELIVERY',
  'SHOP',
];

const List<String> _senderRoles = ['USER', 'PROVIDER', 'DRIVER', 'SYSTEM'];

/// Mirrors `moduleName()` from `backend/src/utils/module-settings.ts` (the
/// backend read names from a constant map, not the `AppModule` row).
String _moduleName(String moduleType) {
  const names = <String, String>{
    'SHOPPING': 'Shopping',
    'FOOD': 'Food',
    'GROCERY': 'Grocery',
    'PHARMACY': 'Pharmacy',
    'DOCTOR': 'Doctor',
    'HOTEL': 'Hotel',
    'RIDE': 'Ride',
    'LAUNDRY': 'Laundry',
    'HOME_SERVICES': 'Home Services',
    'HOUSE_HELP': 'Home Services',
    'HEALTH_SERVICES': 'Health services',
    'PARCEL': 'Parcel Delivery',
  };
  return names[moduleType] ?? 'Service';
}

Map<String, dynamic>? _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

String? _nonEmpty(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

String _required(Map<String, dynamic>? body, String name) {
  final value = _nonEmpty(body?[name]);
  if (value == null) throw GatewayError('$name is required.');
  return value;
}

/// Backend `resolveViewer`: an empty actor is treated as the customer.
String _resolveViewer(Map<String, dynamic> conversation, String actorUserId) {
  if (actorUserId.isEmpty) return 'user';
  if (actorUserId == conversation['userId']) return 'user';
  if (actorUserId == conversation['participantUserId']) return 'participant';
  throw const GatewayError('Conversation access denied.', status: 403);
}

/// The signed-in customer's cuid — the `userId` a new conversation must be
/// written with (RLS `with check` enforces the same).
Future<String> _requireSelf(String claimedUserId) async {
  final self = await SupabaseGateway.currentCuid();
  if (self == null || self.isEmpty) {
    throw const GatewayError('Authentication required.', status: 401);
  }
  if (claimedUserId.isNotEmpty && claimedUserId != self) {
    throw const GatewayError('Conversation access denied.', status: 403);
  }
  return self;
}

/// Mirrors `isModuleEnabled`: a disabled module rejects with 403 before
/// anything is written.
Future<void> _requireModule(String moduleType) async {
  final rows = await SupabaseGateway.table('AppModule')
      .select('active')
      .eq('moduleType', moduleType)
      .limit(1);
  final active = rows.isNotEmpty ? rows.first['active'] == true : true;
  if (!active) {
    throw GatewayError(
      '${_moduleName(moduleType)} module is currently disabled.',
      status: 403,
    );
  }
}

/// `formatFullName` from the backend: two names, or 'Customer'.
String _fullName(Map<String, dynamic>? user) {
  if (user == null) return 'Customer';
  final joined = [
    _nonEmpty(user['firstName']) ?? '',
    _nonEmpty(user['lastName']) ?? '',
  ].join(' ').trim();
  return joined.isEmpty ? 'Customer' : joined;
}

/// RLS hides other people's `User` rows: name + phone for a legitimate
/// counterparty (courier, driver) come from the guarded RPC.
Future<Map<String, dynamic>?> _contactOf(String? userId) async {
  if (userId == null || userId.isEmpty) return null;
  try {
    final result = await SupabaseGateway.rpc(
      'counterparty_contact',
      params: {'p_user_id': userId},
    );
    return _asMap(result);
  } catch (error) {
    debugPrint('counterparty_contact skipped: $error');
    return null;
  }
}

/// `findBoundParticipantProfile` / `findBoundShopProfileByPharmacyBusiness`
/// through the SECURITY DEFINER RPC (ProProfile rows are owner-only).
Future<String?> _findBoundParticipant(
  String type,
  String bindingKey,
  String target,
) async {
  try {
    final result = await SupabaseGateway.rpc(
      'resolve_bound_profile_user_ids',
      params: {
        'p_type': type,
        'p_binding_key': bindingKey,
        'p_targets': <String>[target],
      },
    );
    final ids = (result as List?)
        ?.map((entry) => entry.toString())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (ids == null || ids.isEmpty) return null;
    return ids.first;
  } catch (error) {
    debugPrint('resolve_bound_profile_user_ids skipped: $error');
    return null;
  }
}

Future<Map<String, dynamic>?> _ownUserRow(String userId) async {
  try {
    final rows = await SupabaseGateway.table('User')
        .select('firstName,lastName,phone')
        .eq('id', userId)
        .limit(1);
    return rows.isEmpty ? null : _asMap(rows.first);
  } catch (_) {
    return null;
  }
}

// ── Serializers (mirror serializers.ts) ─────────────────────────────────────

/// The pro-facing subtitle (`proConversationSubtitle`) is derived from
/// metadata + entity type rather than stored.
String? _participantSubtitle(Map<String, dynamic> conversation) {
  final metadata = _asMap(conversation['metadata']) ?? const {};
  String moduleLabel() => _moduleName(
        (conversation['moduleType'] ?? '').toString(),
      );

  final entityId = (conversation['entityId'] ?? '').toString();
  final suffix = entityId.length >= 6
      ? entityId.substring(entityId.length - 6).toUpperCase()
      : entityId.toUpperCase();

  switch ((conversation['entityType'] ?? '').toString()) {
    case 'DELIVERY':
      return '${moduleLabel()} order #$suffix';
    case 'RIDE':
      final destination = _nonEmpty(metadata['destination']);
      return destination != null
          ? 'Ride to $destination'
          : 'Ride #$suffix';
    case 'DOCTOR':
      final specialty = _nonEmpty(metadata['specialty']);
      return specialty != null
          ? 'Consultation • $specialty'
          : 'Appointment #$suffix';
    case 'HOME_SERVICE_PROVIDER':
      final categorySlug = _nonEmpty(metadata['categorySlug']);
      if (categorySlug != null) {
        return categorySlug
            .replaceAll('-', ' ')
            .replaceAll('_', ' ')
            .split(' ')
            .where((part) => part.isNotEmpty)
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
      }
      return 'Service request #$suffix';
    case 'SHOP':
      final merchantName =
          _nonEmpty(metadata['merchantName']) ??
              (conversation['title']?.toString() ?? '');
      return '${moduleLabel()} • $merchantName';
    default:
      return (conversation['subtitle'] as String?) ?? moduleLabel();
  }
}

Map<String, dynamic> _serializeConversation(
  Map<String, dynamic> conversation, {
  required bool asParticipant,
}) {
  final metadata = _asMap(conversation['metadata']) ?? <String, dynamic>{};
  final storedSubtitle = conversation['subtitle']?.toString();

  String title = conversation['title']?.toString() ?? 'Conversation';
  String? subtitle = storedSubtitle;
  if (asParticipant) {
    final customerName = _nonEmpty(metadata['customerName']);
    if (customerName != null) title = customerName;
    subtitle = _participantSubtitle(conversation);
  }

  return <String, dynamic>{
    'id': conversation['id'],
    'userId': conversation['userId'],
    'participantUserId': conversation['participantUserId'],
    'moduleType': conversation['moduleType'],
    'entityType': conversation['entityType'],
    'entityId': conversation['entityId'],
    'title': title,
    'subtitle': subtitle,
    'avatarUrl': conversation['avatarUrl'],
    'accentColor': conversation['accentColor'],
    'status': conversation['status'],
    'unreadCount': asParticipant
        ? (conversation['participantUnreadCount'] ?? 0)
        : (conversation['userUnreadCount'] ?? 0),
    'lastMessage': conversation['lastMessage'],
    'lastMessageAt': conversation['lastMessageAt'],
    'metadata': metadata,
    'createdAt': conversation['createdAt'],
    'updatedAt': conversation['updatedAt'],
  };
}

Map<String, dynamic> _serializeMessage(Map<String, dynamic> message) {
  return <String, dynamic>{
    'id': message['id'],
    'conversationId': message['conversationId'],
    'senderUserId': message['senderUserId'],
    'senderRole': message['senderRole'],
    'senderLabel': message['senderLabel'],
    'body': message['body'],
    'metadata': _asMap(message['metadata']) ?? <String, dynamic>{},
    'readAt': message['readAt'],
    'createdAt': message['createdAt'],
  };
}

Future<Map<String, dynamic>?> _conversationById(String id) async {
  final rows = await SupabaseGateway.table('Conversation')
      .select('*')
      .eq('id', id)
      .limit(1);
  return rows.isEmpty ? null : _asMap(rows.first);
}

// ── GET /messages/user/:userId ──────────────────────────────────────────────

Future<dynamic> _conversationsForUser(GatewayRequest request) async {
  final userId = request.requireSegment(2, 'userId');
  await _requireSelf(userId);

  final rows = await SupabaseGateway.table('Conversation')
      .select('*')
      .eq('userId', userId)
      .order('lastMessageAt', ascending: false, nullsFirst: true)
      .order('updatedAt', ascending: false, nullsFirst: true);

  return rows
      .map((row) => _serializeConversation(
            _asMap(row) ?? const {},
            asParticipant: false,
          ))
      .toList();
}

// ── GET /messages/conversations/:conversationId ─────────────────────────────

Future<dynamic> _conversationDetail(GatewayRequest request) async {
  final conversationId = request.requireSegment(2, 'conversationId');
  final conversation = await _conversationById(conversationId);
  if (conversation == null) {
    throw const GatewayError('Conversation not found.', status: 404);
  }

  final actorUserId = request.optionalString('actorUserId') ?? '';
  final viewer = _resolveViewer(conversation, actorUserId);

  final messages = await SupabaseGateway.table('Message')
      .select('*')
      .eq('conversationId', conversationId)
      .order('createdAt', ascending: true, nullsFirst: false);

  return <String, dynamic>{
    ..._serializeConversation(conversation, asParticipant: viewer == 'participant'),
    'messages': messages
        .map((row) => _serializeMessage(_asMap(row) ?? const {}))
        .toList(),
  };
}

// ── POST /messages/conversations/start ──────────────────────────────────────

class _Participant {
  final int status;
  final String? reason;
  final String? participantUserId;
  final String? title;
  final Map<String, dynamic> metadata;

  const _Participant({
    this.status = 400,
    this.reason,
    this.participantUserId,
    this.title,
    this.metadata = const {},
  });

  bool get ok => reason == null;
}

/// `resolveConversationParticipant` — maps the entity to the pro inbox that
/// should receive the thread, plus the metadata both sides display.
Future<_Participant> _resolveParticipant({
  required String userId,
  required String entityType,
  required String entityId,
  required String moduleType,
  Map<String, dynamic> metadata = const {},
}) async {
  switch (entityType) {
    case 'SHOP':
      final user = await _ownUserRow(userId);
      final customer = <String, dynamic>{
        'customerName': _fullName(user),
        'customerPhone': user?['phone'],
      };

      if (moduleType == 'SHOPPING') {
        var rows = await SupabaseGateway.table('ShoppingStore')
            .select('id,slug,name')
            .eq('id', entityId)
            .limit(1);
        if (rows.isEmpty) {
          rows = await SupabaseGateway.table('ShoppingStore')
              .select('id,slug,name')
              .eq('slug', entityId)
              .limit(1);
        }
        if (rows.isEmpty) {
          return const _Participant(status: 404, reason: 'Store not found.');
        }
        final store = _asMap(rows.first)!;
        return _Participant(
          participantUserId: await _findBoundParticipant(
            'SHOP',
            'shoppingStoreIds',
            store['id'].toString(),
          ),
          title: store['name']?.toString(),
          metadata: {
            ...customer,
            'participantName': store['name'],
            'merchantName': store['name'],
            'merchantKind': 'store',
            'storeId': store['id'],
            'storeSlug': store['slug'],
          },
        );
      }

      if (moduleType == 'FOOD') {
        final rows = await SupabaseGateway.table('Restaurant')
            .select('id,name,cuisine')
            .eq('id', entityId)
            .limit(1);
        if (rows.isEmpty) {
          return const _Participant(status: 404, reason: 'Restaurant not found.');
        }
        final restaurant = _asMap(rows.first)!;
        return _Participant(
          participantUserId: await _findBoundParticipant(
            'SHOP',
            'restaurantIds',
            restaurant['id'].toString(),
          ),
          title: restaurant['name']?.toString(),
          metadata: {
            ...customer,
            'participantName': restaurant['name'],
            'merchantName': restaurant['name'],
            'merchantKind': 'restaurant',
            'restaurantId': restaurant['id'],
            'cuisine': restaurant['cuisine'],
          },
        );
      }

      if (moduleType == 'PHARMACY') {
        final businessName = entityId.trim();
        if (businessName.isEmpty) {
          return const _Participant(
            status: 404,
            reason: 'Pharmacy business not found.',
          );
        }
        return _Participant(
          participantUserId: await _findBoundParticipant(
            'SHOP',
            'pharmacyBusinesses',
            businessName,
          ),
          title: businessName,
          metadata: {
            ...customer,
            'participantName': businessName,
            'merchantName': businessName,
            'merchantKind': 'pharmacy',
            'pharmacyBusiness': businessName,
          },
        );
      }

      final merchantName = metadata['merchantName']?.toString() ?? 'Merchant';
      return _Participant(
        title: merchantName,
        metadata: {...customer, 'merchantName': merchantName},
      );

    case 'DOCTOR':
      final appointmentId = _nonEmpty(metadata['appointmentId']);
      final participant = await _findBoundParticipant(
        'DOCTOR',
        'doctorIds',
        entityId,
      );
      final user = await _ownUserRow(userId);

      Map<String, dynamic>? appointment;
      if (appointmentId != null && appointmentId.isNotEmpty) {
        final rows = await SupabaseGateway.table('Appointment')
            .select(
              'id,doctor:Doctor(id,name,specialty,contactPhone)',
            )
            .eq('id', appointmentId)
            .eq('userId', userId)
            .eq('doctorId', entityId)
            .limit(1);
        if (rows.isEmpty) {
          return const _Participant(
            status: 404,
            reason: 'Appointment not found for this user.',
          );
        }
        appointment = _asMap(rows.first);
      }

      final doctor = _asMap(appointment?['doctor']);
      final doctorName = doctor?['name']?.toString() ?? 'Doctor';
      return _Participant(
        participantUserId: participant,
        title: doctorName,
        metadata: {
          'customerName': _fullName(user),
          'customerPhone': user?['phone'],
          'participantName': doctorName,
          'participantPhone': doctor?['contactPhone'],
          'doctorId': entityId,
          'appointmentId': appointment?['id'] ?? appointmentId,
          'specialty':
              doctor?['specialty'] ?? metadata['specialty']?.toString(),
        },
      );

    case 'HOME_SERVICE_PROVIDER':
      final orderId = _nonEmpty(metadata['orderId']);
      final participant = await _findBoundParticipant(
        'PROVIDER',
        'providerIds',
        entityId,
      );
      final providerRows = await SupabaseGateway.table('HomeServiceProvider')
          .select('id,name,title,categoryId,contactPhone')
          .eq('id', entityId)
          .limit(1);
      if (providerRows.isEmpty) {
        return const _Participant(status: 404, reason: 'Provider not found.');
      }
      final provider = _asMap(providerRows.first)!;
      final user = await _ownUserRow(userId);

      String? orderOkId;
      if (orderId != null && orderId.isNotEmpty) {
        final orderRows = await SupabaseGateway.table('Order')
            .select('id')
            .eq('id', orderId)
            .eq('userId', userId)
            .inFilter('moduleType', ['HOME_SERVICES', 'HOUSE_HELP'])
            .limit(1);
        if (orderRows.isEmpty) {
          return const _Participant(
            status: 404,
            reason: 'Service request not found for this user.',
          );
        }
        orderOkId = orderRows.first['id']?.toString();
      }

      return _Participant(
        participantUserId: participant,
        title: provider['name']?.toString(),
        metadata: {
          'customerName': _fullName(user),
          'customerPhone': user?['phone'],
          'participantName': provider['name'],
          'participantPhone': provider['contactPhone'],
          'providerId': entityId,
          'orderId': orderOkId ?? orderId,
          'categorySlug': metadata['categorySlug']?.toString(),
          'providerTitle': provider['title'],
        },
      );

    case 'DELIVERY':
      final orderRows = await SupabaseGateway.table('Order')
          .select('id,userId,deliveryUserId')
          .eq('id', entityId)
          .limit(1);
      final order = orderRows.isEmpty ? null : _asMap(orderRows.first);
      if (order == null || order['userId'] != userId) {
        return const _Participant(
          status: 404,
          reason: 'Order not found for this user.',
        );
      }
      final deliveryUserId = order['deliveryUserId']?.toString();
      if (deliveryUserId == null || deliveryUserId.isEmpty) {
        return const _Participant(
          status: 409,
          reason:
              'Delivery chat becomes available once a courier has claimed the order.',
        );
      }
      final contact = await _contactOf(deliveryUserId);
      if (contact == null) {
        return const _Participant(
          status: 409,
          reason:
              'Delivery chat becomes available once a courier has claimed the order.',
        );
      }
      final user = await _ownUserRow(userId);
      return _Participant(
        participantUserId: deliveryUserId,
        title: _nonEmpty(contact['name']) ?? 'Courier',
        metadata: {
          'customerName': _fullName(user),
          'customerPhone': user?['phone'],
          'participantName': contact['name'],
          'participantPhone': contact['phone'],
          'orderId': order['id'],
        },
      );

    case 'RIDE':
      final rideRows = await SupabaseGateway.table('RideBooking')
          .select(
            'id,userId,driverUserId,driverName,driverPhone,'
            'pickupLabel,dropoffLabel,vehicleName',
          )
          .eq('id', entityId)
          .limit(1);
      final ride = rideRows.isEmpty ? null : _asMap(rideRows.first);
      if (ride == null || ride['userId'] != userId) {
        return const _Participant(
          status: 404,
          reason: 'Ride not found for this user.',
        );
      }
      final driverUserId = ride['driverUserId']?.toString();
      if (driverUserId == null || driverUserId.isEmpty) {
        return const _Participant(
          status: 409,
          reason:
              'Ride chat becomes available once a driver has accepted the trip.',
        );
      }
  final driverContact = await _contactOf(driverUserId);
      final driverName = _nonEmpty(ride['driverName']) ??
          _nonEmpty(driverContact?['name']) ??
          'Driver';
      final driverPhone =
          _nonEmpty(ride['driverPhone']) ?? _nonEmpty(driverContact?['phone']);
      final user = await _ownUserRow(userId);
      return _Participant(
        participantUserId: driverUserId,
        title: driverName,
        metadata: {
          'customerName': _fullName(user),
          'customerPhone': user?['phone'],
          'participantName': driverName,
          'participantPhone': driverPhone,
          'rideId': ride['id'],
          'pickup': ride['pickupLabel'],
          'destination': ride['dropoffLabel'],
          'vehicle': ride['vehicleName'],
        },
      );

    default:
      return const _Participant();
  }
}

/// `isDoctorConversationAllowed` — doctor chat only from an approved
/// appointment belonging to this customer and this doctor.
Future<void> _requireDoctorConversation({
  required String userId,
  required String entityId,
  Map<String, dynamic> metadata = const {},
}) async {
  final appointmentId = _nonEmpty(metadata['appointmentId']);
  if (appointmentId == null) {
    throw const GatewayError(
      'Doctor chat is only available from an appointment detail.',
      status: 403,
    );
  }
  final rows = await SupabaseGateway.table('Appointment')
      .select('id')
      .eq('id', appointmentId)
      .eq('userId', userId)
      .eq('doctorId', entityId)
      .eq('status', 'APPROVED')
      .limit(1);
  if (rows.isEmpty) {
    throw const GatewayError(
      'Doctor chat is only available for a valid appointment linked to this doctor.',
      status: 403,
    );
  }
}

({String senderRole, String senderLabel, String body}) _welcome(
  String entityType,
  String title,
) {
  switch (entityType) {
    case 'DOCTOR':
      return (
        senderRole: 'PROVIDER',
        senderLabel: title,
        body: 'Hello, how can I help you today?',
      );
    case 'HOME_SERVICE_PROVIDER':
      return (
        senderRole: 'PROVIDER',
        senderLabel: title,
        body: 'Hi! Tell us what you need at home and we will guide you.',
      );
    case 'SHOP':
      return (
        senderRole: 'PROVIDER',
        senderLabel: title,
        body:
            'Hello, thanks for reaching out. How can we help with your order or item today?',
      );
    case 'DELIVERY':
      return (
        senderRole: 'DRIVER',
        senderLabel: title,
        body: 'Hello, I am handling your delivery. Message me here for updates.',
      );
    case 'RIDE':
      return (
        senderRole: 'DRIVER',
        senderLabel: title,
        body: 'I am on the way. Message me here if you need anything.',
      );
    default:
      return (
        senderRole: 'SYSTEM',
        senderLabel: title,
        body: 'Hello, how can I help you today?',
      );
  }
}

({String senderRole, String senderLabel, String body}) _autoReply(
  String entityType,
  String title,
) {
  switch (entityType) {
    case 'DOCTOR':
      return (
        senderRole: 'PROVIDER',
        senderLabel: title,
        body: 'Thanks for your message. I will review it and reply shortly.',
      );
    case 'HOME_SERVICE_PROVIDER':
      return (
        senderRole: 'PROVIDER',
        senderLabel: title,
        body:
            'Thanks. We received your request and will confirm the service details soon.',
      );
    case 'SHOP':
      return (
        senderRole: 'PROVIDER',
        senderLabel: title,
        body: 'Thanks. We received your message and will help you shortly.',
      );
    case 'DELIVERY':
      return (
        senderRole: 'DRIVER',
        senderLabel: title,
        body: 'Thanks. I will keep you posted as your delivery moves forward.',
      );
    case 'RIDE':
      return (
        senderRole: 'DRIVER',
        senderLabel: title,
        body: 'Got it. I will keep you updated during the ride.',
      );
    default:
      return (
        senderRole: 'SYSTEM',
        senderLabel: title,
        body: 'Thanks for your message.',
      );
  }
}

Future<dynamic> _startConversation(GatewayRequest request) async {
  final userId = _required(request.body, 'userId');
  final moduleType = _required(request.body, 'moduleType');
  final entityType = _required(request.body, 'entityType');
  final entityId = _required(request.body, 'entityId');
  final title = _required(request.body, 'title');

  if (!_moduleTypes.contains(moduleType)) {
    throw const GatewayError('moduleType is invalid.');
  }
  if (!_entityTypes.contains(entityType)) {
    throw const GatewayError('entityType is invalid.');
  }

  final self = await _requireSelf(userId);
  await _requireModule(moduleType);

  final bodyMetadata = _asMap(request.body?['metadata']) ?? const {};
  if (entityType == 'DOCTOR') {
    await _requireDoctorConversation(
      userId: self,
      entityId: entityId,
      metadata: bodyMetadata,
    );
  }

  final participant = await _resolveParticipant(
    userId: self,
    entityType: entityType,
    entityId: entityId,
    moduleType: moduleType,
    metadata: bodyMetadata,
  );
  if (!participant.ok) {
    throw GatewayError(participant.reason!, status: participant.status);
  }

  final finalTitle = participant.title ?? title;
  final finalMetadata = <String, dynamic>{
    ...bodyMetadata,
    ...participant.metadata,
  };

  // Reuse the thread for the same (user, entity) pair — Prisma's
  // `userId_entityType_entityId` unique index.
  final existing = await SupabaseGateway.table('Conversation')
      .select('*')
      .eq('userId', self)
      .eq('entityType', entityType)
      .eq('entityId', entityId)
      .limit(1);

  if (existing.isNotEmpty) {
    final row = _asMap(existing.first)!;
    final updated = await SupabaseGateway.table('Conversation')
        .update({
          'participantUserId': participant.participantUserId,
          'title': finalTitle,
          'subtitle': _nonEmpty(request.body?['subtitle']) ??
              row['subtitle'],
          'avatarUrl': _nonEmpty(request.body?['avatarUrl']) ??
              row['avatarUrl'],
          'accentColor': _nonEmpty(request.body?['accentColor']) ??
              row['accentColor'],
          'metadata': finalMetadata,
        })
        .eq('id', row['id'].toString())
        .select('*')
        .limit(1);
    return _serializeConversation(
      _asMap(updated.first) ?? row,
      asParticipant: false,
    );
  }

  final welcome = _welcome(entityType, finalTitle);
  final now = DateTime.now().toUtc().toIso8601String();
  final created = await SupabaseGateway.table('Conversation')
      .insert({
        'userId': self,
        if (participant.participantUserId != null)
          'participantUserId': participant.participantUserId,
        'moduleType': moduleType,
        'entityType': entityType,
        'entityId': entityId,
        'title': finalTitle,
        'subtitle': _nonEmpty(request.body?['subtitle']),
        'avatarUrl': _nonEmpty(request.body?['avatarUrl']),
        'accentColor': _nonEmpty(request.body?['accentColor']),
        'metadata': finalMetadata,
        'lastMessage': welcome.body,
        'lastMessageAt': now,
        'userUnreadCount': 1,
        'participantUnreadCount': 0,
      })
      .select('*')
      .limit(1);

  final conversation = _asMap(created.first)!;
  await SupabaseGateway.table('Message').insert({
    'conversationId': conversation['id'],
    if (participant.participantUserId != null)
      'senderUserId': participant.participantUserId,
    'senderRole': welcome.senderRole,
    'senderLabel': welcome.senderLabel,
    'body': welcome.body,
  });

  return _serializeConversation(conversation, asParticipant: false);
}

// ── POST /messages/conversations/:conversationId/messages ───────────────────

Future<void> _notifyBestEffort({
  required Map<String, dynamic> conversation,
  required String recipientUserId,
  required String title,
  required String body,
  required String route,
  required String actorRole,
  required String dedupeKey,
}) async {
  try {
    await SupabaseGateway.createNotification(
      userId: recipientUserId,
      title: title,
      body: body,
      module: 'MESSAGES',
      type: 'SYSTEM',
      priority: 'HIGH',
      route: route,
      dedupeKey: dedupeKey,
      metadata: {
        'kind': 'message',
        'conversationId': conversation['id'],
        'actorRole': actorRole,
        'entityType': conversation['entityType'],
        'entityId': conversation['entityId'],
        'moduleType': conversation['moduleType'],
        'route': route,
      },
    );
  } catch (error) {
    // A failed push must not roll back the message the customer sent —
    // the backend isolated notification failures the same way.
    debugPrint('Message notification skipped: $error');
  }
}

String _participantNotificationTitle(Map<String, dynamic> conversation) {
  final metadata = _asMap(conversation['metadata']) ?? const {};
  return _nonEmpty(metadata['customerName']) ?? 'New customer message';
}

String _userNotificationTitle(Map<String, dynamic> conversation) {
  final metadata = _asMap(conversation['metadata']) ?? const {};
  return _nonEmpty(metadata['participantName']) ??
      (conversation['title']?.toString() ?? 'New message');
}

Future<dynamic> _sendMessage(GatewayRequest request) async {
  final conversationId = request.requireSegment(2, 'conversationId');
  final senderRole = _required(request.body, 'senderRole');
  final rawBody = _required(request.body, 'body');
  if (!_senderRoles.contains(senderRole)) {
    throw const GatewayError('senderRole is invalid.');
  }
  final messageBody = rawBody.trim();
  if (messageBody.isEmpty) {
    throw const GatewayError('body is required.');
  }
  if (messageBody.length > 1500) {
    throw const GatewayError('Message must be 1500 characters or fewer.');
  }

  final actorUserId = _nonEmpty(request.body?['actorUserId']) ?? '';

  final conversation = await _conversationById(conversationId);
  if (conversation == null) {
    throw const GatewayError('Conversation not found.', status: 404);
  }

  await _requireModule(conversation['moduleType']?.toString() ?? '');

  final viewer = _resolveViewer(conversation, actorUserId);
  if (senderRole == 'USER' && viewer != 'user') {
    throw const GatewayError(
      'Only the customer can send user messages.',
      status: 403,
    );
  }
  if (senderRole != 'USER' && viewer != 'participant') {
    throw const GatewayError(
      'Only the assigned pro can reply here.',
      status: 403,
    );
  }

  if (conversation['entityType']?.toString() == 'DOCTOR' &&
      senderRole == 'USER') {
    await _requireDoctorConversation(
      userId: conversation['userId']?.toString() ?? '',
      entityId: conversation['entityId']?.toString() ?? '',
      metadata: _asMap(conversation['metadata']) ?? const {},
    );
  }

  final senderUserId = actorUserId.isNotEmpty
      ? actorUserId
      : senderRole == 'USER'
          ? conversation['userId']?.toString()
          : conversation['participantUserId']?.toString();

  final sent = await SupabaseGateway.table('Message')
      .insert({
        'conversationId': conversationId,
        if (senderUserId != null && senderUserId.isNotEmpty)
          'senderUserId': senderUserId,
        'senderRole': senderRole,
        if (_nonEmpty(request.body?['senderLabel']) != null)
          'senderLabel': _nonEmpty(request.body?['senderLabel']),
        'body': messageBody,
        if (_asMap(request.body?['metadata']) != null)
          'metadata': _asMap(request.body?['metadata']),
      })
      .select('*')
      .limit(1);
  final userMessage = _asMap(sent.first)!;

  var userUnreadCount = (conversation['userUnreadCount'] as num?)?.toInt() ?? 0;
  var participantUnreadCount =
      (conversation['participantUnreadCount'] as num?)?.toInt() ?? 0;
  var lastMessage = userMessage['body']?.toString() ?? messageBody;
  var lastMessageAt = userMessage['createdAt']?.toString();

  final participantUserId = conversation['participantUserId']?.toString();

  if (senderRole == 'USER') {
    if (participantUserId != null && participantUserId.isNotEmpty) {
      participantUnreadCount += 1;
    } else {
      // No bound pro: the backend replied automatically so the thread is
      // never one-sided.
      final reply = _autoReply(
        conversation['entityType']?.toString() ?? '',
        conversation['title']?.toString() ?? '',
      );
      final autoReply = await SupabaseGateway.table('Message')
          .insert({
            'conversationId': conversationId,
            'senderRole': reply.senderRole,
            'senderLabel': reply.senderLabel,
            'body': reply.body,
          })
          .select('*')
          .limit(1);
      final replyRow = _asMap(autoReply.first)!;
      userUnreadCount += 1;
      lastMessage = replyRow['body']?.toString() ?? reply.body;
      lastMessageAt = replyRow['createdAt']?.toString();
    }
  } else {
    userUnreadCount += 1;
  }

  final updated = await SupabaseGateway.table('Conversation')
      .update({
        'lastMessage': lastMessage,
        'lastMessageAt': lastMessageAt,
        'userUnreadCount': userUnreadCount,
        'participantUnreadCount': participantUnreadCount,
      })
      .eq('id', conversationId)
      .select('*')
      .limit(1);
  final updatedConversation =
      _asMap(updated.isNotEmpty ? updated.first : conversation) ?? conversation;

  if (senderRole == 'USER' &&
      participantUserId != null &&
      participantUserId.isNotEmpty) {
    await _notifyBestEffort(
      conversation: conversation,
      recipientUserId: participantUserId,
      title: _participantNotificationTitle(conversation),
      body: messageBody,
      route: '/pro/messages/chat/$conversationId',
      actorRole: senderRole,
      dedupeKey: 'message:${userMessage['id']}:$participantUserId',
    );
  }
  if (senderRole != 'USER') {
    final ownerUserId = conversation['userId']?.toString() ?? '';
    if (ownerUserId.isNotEmpty) {
      await _notifyBestEffort(
        conversation: conversation,
        recipientUserId: ownerUserId,
        title: _userNotificationTitle(conversation),
        body: messageBody,
        route: '/messages/chat/$conversationId',
        actorRole: senderRole,
        dedupeKey: 'message:${userMessage['id']}:$ownerUserId',
      );
    }
  }

  return <String, dynamic>{
    'sent': _serializeMessage(userMessage),
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt,
    'unreadCount': viewer == 'participant'
        ? (updatedConversation['participantUnreadCount'] ?? 0)
        : (updatedConversation['userUnreadCount'] ?? 0),
  };
}

// ── PATCH /messages/conversations/:conversationId/read ──────────────────────

Future<dynamic> _markRead(GatewayRequest request) async {
  final conversationId = request.requireSegment(2, 'conversationId');
  final conversation = await _conversationById(conversationId);
  if (conversation == null) {
    throw const GatewayError('Conversation not found.', status: 404);
  }

  final actorUserId = _nonEmpty(request.body?['actorUserId']) ?? '';
  final viewer = _resolveViewer(conversation, actorUserId);

  var incomingQuery = SupabaseGateway.table('Message')
      .update({'readAt': DateTime.now().toUtc().toIso8601String()})
      .eq('conversationId', conversationId)
      .isFilter('readAt', null);
  incomingQuery = viewer == 'participant'
      ? incomingQuery.eq('senderRole', 'USER')
      : incomingQuery.neq('senderRole', 'USER');
  await incomingQuery;

  final updated = await SupabaseGateway.table('Conversation')
      .update(
        viewer == 'participant'
            ? {'participantUnreadCount': 0}
            : {'userUnreadCount': 0},
      )
      .eq('id', conversationId)
      .select('*')
      .limit(1);

  return _serializeConversation(
    _asMap(updated.isNotEmpty ? updated.first : conversation) ?? conversation,
    asParticipant: viewer == 'participant',
  );
}
