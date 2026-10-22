import '../supabase_gateway.dart';
import 'gateway_router.dart';

/// `/notifications/*` — mirrors `notifications.routes.ts`.
///
/// Reads and writes go straight to the `Notification` table under RLS (the
/// owner policy scopes rows to `app.current_user_id()`), so the handlers only
/// reproduce the backend's response shapes and dedupe rule.
void register() {
  GatewayRouter.post('/notifications/device-tokens', _registerDeviceToken);
  GatewayRouter.get('/notifications/:userId', _listNotifications);
  GatewayRouter.post('/notifications', _createNotification);
  GatewayRouter.patch('/notifications/:id/read', _markRead);
}

const String _columns =
    'id,userId,type,module,priority,title,body,route,dedupeKey,metadata,'
    'data,readAt,createdAt';

const String _tokenColumns =
    'id,userId,token,audience,platform,lastSeenAt';

Map<String, dynamic> _serialize(Map<String, dynamic> row) {
  final metadata = row['metadata'] ?? row['data'];
  return <String, dynamic>{
    'id': row['id'],
    'userId': row['userId'],
    'type': row['type'],
    'module': row['module'],
    'priority': row['priority'],
    'title': row['title'],
    'body': row['body'],
    'route': row['route'],
    'dedupeKey': row['dedupeKey'],
    'metadata': metadata,
    'data': row['data'],
    'readAt': row['readAt'],
    'createdAt': row['createdAt'],
  };
}

Future<dynamic> _listNotifications(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  final rows = await SupabaseGateway.table('Notification')
      .select(_columns)
      .eq('userId', userId)
      .order('createdAt', ascending: false)
      .limit(100);

  return rows.map(_serialize).toList();
}

Map<String, dynamic>? _jsonMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

Future<dynamic> _createNotification(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};
  final userId = body['userId']?.toString().trim() ?? '';
  final title = body['title']?.toString().trim() ?? '';
  final text = body['body']?.toString().trim() ?? '';

  if (userId.isEmpty) throw const GatewayError('userId is required.');
  if (title.isEmpty) throw const GatewayError('title is required.');
  if (text.isEmpty) throw const GatewayError('body is required.');

  // RLS only permits inserting into the caller's own inbox, so this goes
  // through the RPC: it authorizes cross-inbox writes (providers, admin
  // inbox) from the JWT and reproduces the backend's dedupe behaviour.
  final row = await SupabaseGateway.createNotification(
    id: body['id']?.toString(),
    userId: userId,
    title: title,
    body: text,
    module: body['module']?.toString() ?? 'SYSTEM',
    type: body['type']?.toString() ?? 'SYSTEM',
    priority: body['priority']?.toString() ?? 'NORMAL',
    route: body['route']?.toString(),
    dedupeKey: body['dedupeKey']?.toString(),
    metadata: _jsonMap(body['metadata'] ?? body['data']),
    createdAt: body['createdAt']?.toString(),
    readAt: body['readAt']?.toString(),
  );

  if (row == null) {
    throw const GatewayError('Unable to save the notification.', status: 500);
  }
  return _serialize(row);
}

Future<dynamic> _markRead(GatewayRequest request) async {
  final id = request.requireSegment(1, 'notificationId');
  final readAt = DateTime.now().toUtc().toIso8601String();

  final updated = await SupabaseGateway.table('Notification')
      .update({'readAt': readAt})
      .eq('id', id)
      .select('id');

  final count = updated.length;
  return <String, dynamic>{
    'id': id,
    'readAt': count > 0 ? readAt : null,
    'updated': count > 0,
  };
}

Future<dynamic> _registerDeviceToken(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};
  final token = body['token']?.toString().trim() ?? '';
  if (token.isEmpty) throw const GatewayError('token is required.');

  final audience =
      body['audience']?.toString().trim().toUpperCase() == 'PRO'
          ? 'PRO'
          : 'USER';

  // Bind the token to the caller's own notification identity. For pros that
  // is their profile's user id (or the admin inbox for super admins), exactly
  // like the backend's `allowedUserId` check — so a token can never be bound
  // to somebody else's inbox.
  final allowedUserId = audience == 'PRO'
      ? await SupabaseGateway.currentProUserId()
      : await SupabaseGateway.currentCuid();

  if (allowedUserId == null) {
    throw const GatewayError(
      'No profile is linked to this account yet.',
      status: 403,
    );
  }

  final requestedUserId = body['userId']?.toString().trim();
  if (requestedUserId != null &&
      requestedUserId.isNotEmpty &&
      requestedUserId != allowedUserId) {
    throw const GatewayError(
      'Device tokens can only be registered for the authenticated user.',
      status: 403,
    );
  }

  final platform = body['platform']?.toString().trim().toUpperCase();
  final now = DateTime.now().toUtc().toIso8601String();

  // Tokens are keyed by (token, audience) so the user and pro apps can each
  // hold one FCM token per device without stealing each other's delivery.
  final existing = await SupabaseGateway.table('DeviceToken')
      .select('id')
      .eq('token', token)
      .eq('audience', audience)
      .limit(1);

  if (existing.isNotEmpty) {
    final updated = await SupabaseGateway.table('DeviceToken')
        .update({
          'userId': allowedUserId,
          if (platform != null && platform.isNotEmpty) 'platform': platform,
          'lastSeenAt': now,
        })
        .eq('id', existing.first['id'])
        .select(_tokenColumns)
        .maybeSingle();
    return updated ?? <String, dynamic>{};
  }

  final created = await SupabaseGateway.table('DeviceToken')
      .insert({
        'userId': allowedUserId,
        'token': token,
        'audience': audience,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
        'lastSeenAt': now,
      })
      .select(_tokenColumns)
      .single();
  return created;
}
