import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'gateway/gateway_router.dart';
import 'gateway/gateway_admin.dart' as gateway_admin;
import 'gateway/gateway_catalog.dart' as gateway_catalog;
import 'gateway/gateway_media.dart' as gateway_media;
import 'gateway/gateway_messages.dart' as gateway_messages;
import 'gateway/gateway_misc.dart' as gateway_misc;
import 'gateway/gateway_notifications.dart' as gateway_notifications;
import 'gateway/gateway_orders.dart' as gateway_orders;
import 'gateway/gateway_payments.dart' as gateway_payments;
import 'gateway/gateway_pro.dart' as gateway_pro;
import 'gateway/gateway_users.dart' as gateway_users;

export 'gateway/gateway_router.dart' show GatewayUnrouted;

/// Translates the legacy REST paths (`/orders`, `/pro/:id/dashboard`, …) into
/// direct Supabase calls so the app no longer needs the Render backend.
///
/// Response shapes are kept byte-compatible with the Express handlers: the
/// same keys, same nesting, same error strings. That is what lets the ~400
/// existing `ApiClient` call sites keep working untouched while their
/// transport changes underneath them.
class SupabaseGateway {
  SupabaseGateway._();

  static bool _registered = false;

  /// True once the app is built with `--dart-define=SUPABASE_URL/ANON_KEY`.
  static bool get isActive => SupabaseService.isConfigured;

  static SupabaseClient get _client => Supabase.instance.client;

  static void _registerRoutes() {
    if (_registered) return;
    _registered = true;

    gateway_misc.register();
    gateway_notifications.register();
    gateway_users.register();
    gateway_catalog.register();
    gateway_orders.register();
    gateway_pro.register();
    gateway_messages.register();
    gateway_admin.register();
    gateway_media.register();
    gateway_payments.register();
  }

  /// Executes a legacy-API call against Supabase.
  ///
  /// Throws [GatewayUnrouted] when a path has not been migrated yet (the
  /// caller may fall back to the HTTP backend during the transition), and
  /// `Exception(message)` for real failures — identical to what the backend's
  /// `{"error": …}` bodies produced.
  static Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    void Function(String? banReason)? onBanned,
  }) async {
    if (!isActive) {
      throw const GatewayUnrouted('—', 'Supabase is not configured');
    }

    _registerRoutes();

    // The backend's `requireAuth` rejected suspended accounts on every
    // authenticated call with `{banned:true, banReason}`. Reproduce that here
    // (cached briefly so a hot read path does not query per request).
    await _enforceNotBanned();

    final uri = Uri.parse(path.startsWith('/') ? path : '/$path');
    final rawSegments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    final query = <String, String>{};
    query.addAll(uri.queryParameters);

    final params = <String, String>{};
    final handler = GatewayRouter.resolve(method, rawSegments, params);
    if (handler == null) {
      throw GatewayUnrouted(method, uri.path);
    }

    final request = GatewayRequest(
      method: method.toUpperCase(),
      path: uri.path,
      segments: rawSegments,
      query: query,
      body: body,
    );
    // Stash captured path params in the query map under their placeholder
    // names so handlers read `:userId` and `?userId=` the same way.
    query.addAll(params);

    try {
      return await handler(request);
    } on GatewayError catch (error) {
      if (error.banned) {
        onBanned?.call(error.banReason);
      }
      throw Exception(error.message);
    } on PostgrestException catch (error) {
      throw Exception(_friendlyMessage(error));
    }
  }

  static String? _cachedBanReason;
  static DateTime? _banCheckedAt;
  static const Duration _banCacheTtl = Duration(seconds: 30);

  static Future<void> _enforceNotBanned() async {
    final now = DateTime.now();
    if (_banCheckedAt != null && now.difference(_banCheckedAt!) < _banCacheTtl) {
      if (_cachedBanReason != null) _throwBanned(_cachedBanReason);
      return;
    }

    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      // Unauthenticated (public catalog reads) — nothing to enforce.
      _banCheckedAt = now;
      return;
    }

    // Pro accounts take precedence: a pro's profile setup also creates a
    // `User` row, and that one is never the account under moderation.
    final accounts = await table('ProAccount')
        .select('banned,banReason')
        .eq('auth_uid', uid)
        .limit(1);
    if (accounts.isNotEmpty) {
      final row = accounts.first;
      _cacheBan(row['banned'] == true ? row['banReason']?.toString() : null);
      if (_cachedBanReason != null) _throwBanned(_cachedBanReason);
      return;
    }

    final users = await table('User')
        .select('banned,banReason')
        .eq('auth_uid', uid)
        .limit(1);
    if (users.isNotEmpty) {
      final row = users.first;
      _cacheBan(row['banned'] == true ? row['banReason']?.toString() : null);
      if (_cachedBanReason != null) _throwBanned(_cachedBanReason);
      return;
    }

    _cacheBan(null);
  }

  static void _cacheBan(String? reason) {
    _cachedBanReason = reason;
    _banCheckedAt = DateTime.now();
  }

  static Never _throwBanned(String? reason) {
    throw GatewayError(
      'Your account has been suspended.',
      status: 403,
      banned: true,
      banReason: reason,
    );
  }

  /// Clears the cached ban state (call after login/logout or an admin action).
  static void invalidateBanCache() {
    _banCheckedAt = null;
    _cachedBanReason = null;
  }

  // ── Shared helpers used by the domain handlers ────────────────────────────

  // ── Notification fan-out ──────────────────────────────────────────────

  /// Writes a notification row through the guarded RPC.
  ///
  /// RLS only lets a session insert into its *own* inbox, so anything that
  /// reaches another user (a provider being told about an order) has to go
  /// through `create_notification`, which re-checks the caller's identity from
  /// the JWT and applies the backend's dedupe rule.
  static Future<Map<String, dynamic>?> createNotification({
    String? id,
    required String userId,
    required String title,
    required String body,
    String module = 'SYSTEM',
    String type = 'SYSTEM',
    String priority = 'HIGH',
    String? route,
    String? dedupeKey,
    Map<String, dynamic>? metadata,
    String? createdAt,
    String? readAt,
  }) async {
    final result = await rpc(
      'create_notification',
      params: <String, dynamic>{
        if (id != null && id.isNotEmpty) 'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'module': module,
        'type': type,
        'priority': priority,
        'route': ?route,
        'dedupe_key': ?dedupeKey,
        'metadata': ?metadata,
        'created_at': ?createdAt,
        'read_at': ?readAt,
      },
    );
    return result is Map ? Map<String, dynamic>.from(result) : null;
  }

  /// Fans an event out to every super-admin inbox. The inbox `User` row is
  /// created on demand and the dedupe key gets the backend's `admin:` prefix.
  static Future<void> notifyAdmins({
    required String title,
    required String body,
    String module = 'SYSTEM',
    String type = 'SYSTEM',
    String priority = 'HIGH',
    String? route,
    String? dedupeKey,
    Map<String, dynamic>? metadata,
  }) async {
    await rpc(
      'notify_admins',
      params: <String, dynamic>{
        'title': title,
        'body': body,
        'module': module,
        'type': type,
        'priority': priority,
        'route': ?route,
        'dedupe_key': ?dedupeKey,
        'metadata': ?metadata,
      },
    );
  }

  /// The configured Supabase client (for handlers that need Storage or
  /// Realtime rather than PostgREST).
  static SupabaseClient get client => _client;

  static SupabaseQueryBuilder table(String name) => _client.from(name);

  static Future<dynamic> rpc(String name, {Map<String, dynamic>? params}) =>
      _client.rpc(name, params: params);

  /// The signed-in user's `User.id` cuid, resolved from `auth.uid()` by RLS.
  ///
  /// Called through the `public` shim: PostgREST only exposes `public`, so a
  /// schema-qualified `app.current_user_id` would 404 with PGRST202.
  static Future<String?> currentCuid() async {
    final value = await _client.rpc('current_user_id');
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  /// The signed-in pro's `ProAccount.id`, or null for customer sessions.
  static Future<String?> currentProAccountId() async {
    final value = await _client.rpc('current_pro_account_id');
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? null : text;
  }

  /// The `ProProfile.userId` the signed-in pro account acts as.
  ///
  /// Super admins have no profile, so this falls back to the admin inbox user
  /// exactly like `resolveSuperAdminNotificationUserId` did on the backend.
  static Future<String?> currentProUserId() async {
    final accountId = await currentProAccountId();
    if (accountId == null) return null;

    final profiles = await table('ProProfile')
        .select('userId')
        .eq('accountId', accountId)
        .limit(1);
    if (profiles.isNotEmpty) {
      final userId = profiles.first['userId'];
      if (userId != null) return userId.toString();
    }

    // Super admins: no profile, so resolve the shared admin inbox.
    final accounts = await table('ProAccount')
        .select('email')
        .eq('id', accountId)
        .limit(1);
    if (accounts.isNotEmpty) {
      final email = (accounts.first['email'] ?? '').toString();
      if (email.isNotEmpty) {
        final inbox = await table('User')
            .select('id')
            .eq('email', email)
            .limit(1);
        if (inbox.isNotEmpty) {
          return inbox.first['id'].toString();
        }
      }
    }

    return null;
  }

  /// Resolves the effective city-zone key for a catalog request.
  ///
  /// Mirrors `resolveCityZoneKey`: an explicit `zone` param wins (`all` means
  /// no filter), otherwise a latitude/longitude pair is matched against the
  /// active service zones, and `null` means "everywhere".
  static Future<String?> resolveZoneKey({
    String? zone,
    double? latitude,
    double? longitude,
  }) async {
    final explicit = zone?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit.toLowerCase() == 'all' ? null : explicit;
    }

    if (latitude == null || longitude == null) return null;

    try {
      final rows = await table('ServiceZone')
          .select('zoneKey,centerLatitude,centerLongitude,radiusKm')
          .eq('active', true);
      for (final row in rows) {
        final distance = _haversine(
          latitude,
          longitude,
          (row['centerLatitude'] as num).toDouble(),
          (row['centerLongitude'] as num).toDouble(),
        );
        if (distance <= (row['radiusKm'] as num).toDouble()) {
          return row['zoneKey'].toString();
        }
      }
    } catch (_) {
      // Zone resolution is best-effort: fall through to "everywhere".
    }
    return null;
  }

  static double _haversine(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadiusKm = 6371.0;
    double toRadians(double value) => value * 3.141592653589793 / 180;

    final startLat = toRadians(startLatitude);
    final endLat = toRadians(endLatitude);
    final dLat = toRadians(endLatitude - startLatitude);
    final dLon = toRadians(endLongitude - startLongitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(startLat) *
            math.cos(endLat) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusKm *
        2 *
        math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Rewrites any stored storage reference into a directly fetchable URL for
  /// this Supabase project.
  ///
  /// Rows written by the backend hold either the Render proxy path
  /// (`/uploads/supabase/<bucket>/<path>`), the `supabase://bucket/path`
  /// shorthand, or an absolute `/storage/v1/object/...` link on another host.
  /// All three become `<project>/storage/v1/object/public/<bucket>/<path>`.
  static String normalizeStorageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    final proxyMatch = RegExp(
      r'^/uploads/supabase/([^/]+)/(.+)$',
    ).firstMatch(trimmed);
    if (proxyMatch != null) {
      return _publicObjectUri(proxyMatch.group(1)!, proxyMatch.group(2)!);
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) return trimmed;

    if (parsed.scheme == 'supabase') {
      return _publicObjectUri(parsed.host, parsed.path.replaceFirst('/', ''));
    }

    // Legacy Render proxy paths, either relative or absolute on any host
    // (`https://edalab.onrender.com/uploads/supabase/<bucket>/<path>`) —
    // rows written before the cutover still hold absolute Render links.
    final absoluteProxyMatch = RegExp(
      r'^/uploads/supabase/([^/]+)/(.+)$',
    ).firstMatch(parsed.path);
    if (absoluteProxyMatch != null) {
      return _publicObjectUri(
        absoluteProxyMatch.group(1)!,
        absoluteProxyMatch.group(2)!,
      );
    }

    // Any storage link — public, signed (its `?token=` is dropped, which is
    // safe because every bucket in this project is public), or on another
    // host — becomes a direct public object URL on this project.
    final storageMatch = RegExp(
      r'^/storage/v1/object/(?:(?:public|sign|authenticated)/)?([^/]+)/(.+)$',
    ).firstMatch(parsed.path);
    if (storageMatch != null) {
      return _publicObjectUri(storageMatch.group(1)!, storageMatch.group(2)!);
    }

    if (!parsed.hasScheme && trimmed.startsWith('/')) {
      return trimmed;
    }

    return trimmed;
  }

  static String _publicObjectUri(String bucket, String rawPath) {
    final segments = rawPath
        .split('/')
        .where((segment) => segment.trim().isNotEmpty)
        .map((segment) => Uri.encodeComponent(Uri.decodeComponent(segment)))
        .join('/');
    final projectUrl = SupabaseService.projectUrl.replaceAll(RegExp(r'/+$'), '');
    return '$projectUrl/storage/v1/object/public/'
        '${Uri.encodeComponent(Uri.decodeComponent(bucket))}/$segments';
  }

  static String _friendlyMessage(PostgrestException error) {
    switch (error.code) {
      case '42501':
        return 'You do not have permission to do that.';
      case 'PGRST116':
        return 'Record not found.';
      case '23505':
        return 'That already exists.';
      case '23503':
        return 'This record is still referenced elsewhere.';
      case '23514':
        return 'That value is not allowed.';
      default:
        break;
    }
    final message = error.message.trim();
    if (message.isEmpty) return 'Something went wrong. Please try again.';
    return message;
  }
}
