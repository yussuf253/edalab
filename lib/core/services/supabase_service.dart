import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Direct Supabase connection (PostgREST + GoTrue + Storage + Realtime).
///
/// The Render backend is deleted, so this is the app's only transport and the
/// project URL + publishable key are baked in as defaults: every build is a
/// direct-Supabase build without needing `--dart-define`. Builds can still
/// override them (e.g. against a staging project):
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://staging.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=<anon/publishable key>
/// ```
///
/// The publishable key is public by design: it can only do what Row Level
/// Security policies allow. Never ship the service-role key in the app.
class SupabaseService {
  SupabaseService._();

  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tykmxdwewzarkoqnemko.supabase.co',
  );
  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_eXDNZQOOp0ey4sibsBj0ng_6sL9N-Lj',
  );

  static bool _initialized = false;

  /// True once Supabase was configured via --dart-define and initialized.
  static bool get isConfigured => _initialized;

  /// The project URL (empty until configured).
  static String get projectUrl => _url;

  static SupabaseClient? get client =>
      _initialized ? Supabase.instance.client : null;

  static GoTrueClient? get auth => client?.auth;

  /// The signed-in Supabase Auth user (customer accounts), or null.
  static User? get currentUser => auth?.currentUser;

  static String? get currentUserId => currentUser?.id;

  static Future<void> initialize() async {
    if (_initialized) return;

    if (_url.isEmpty || _anonKey.isEmpty) {
      // Unreachable with the baked-in defaults; kept as a guard so an empty
      // override fails loudly instead of silently reviving the dead backend.
      debugPrint(
        'SupabaseService: SUPABASE_URL/SUPABASE_ANON_KEY are empty — '
        'direct mode unavailable.',
      );
      return;
    }

    await Supabase.initialize(
      url: _url,
      publishableKey: _anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _initialized = true;
    debugPrint('SupabaseService: initialized for $_url');
  }

  /// Signs in with email/password via Supabase Auth, then loads the profile from
  /// PostgREST. Throws on bad credentials; returns null if no matching profile
  /// row is found for the auth user.
  static Future<Map<String, dynamic>?> signInAndLoadProfile(
    String email,
    String password,
  ) async {
    final c = client;
    if (c == null) {
      throw StateError('Supabase is not configured.');
    }
    await c.auth.signInWithPassword(email: email.trim(), password: password);
    return fetchUserProfile();
  }

  /// Registers a new customer via Supabase Auth. Email verification is required
  /// before a session exists, so this returns true when the signup succeeded and
  /// the user must now confirm their email (mirrors the backend contract).
  static Future<void> signUp(String name, String email, String phone, String password) async {
    final c = client;
    if (c == null) {
      throw StateError('Supabase is not configured.');
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty ? parts.first : '';
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    await c.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'firstName': first, 'lastName': last, 'phone': phone.trim()},
    );
  }

  /// Fetches the signed-in user's profile straight from PostgREST and returns a
  /// map shaped exactly like the old `GET /users/:id` payload (camelCase, a
  /// computed `name`, and nested `addresses`), so the rest of the app can consume
  /// it unchanged. Relies on the `User`/`Address` RLS policies (owner-only).
  static Future<Map<String, dynamic>?> fetchUserProfile() async {
    final c = client;
    final uid = currentUserId;
    if (c == null || uid == null) return null;

    var userRow = await c
        .from('User')
        .select('id,email,firstName,lastName,phone,avatarUrl,banned,banReason')
        .eq('auth_uid', uid)
        .maybeSingle();

    if (userRow == null) {
      // New signup with no profile row yet (registered via GoTrue directly,
      // no backend). The `user_self_insert` RLS policy only allows creating
      // one's own row with id = auth uid. `passwordHash` is legacy backend
      // state and unused in direct mode — an empty placeholder satisfies NOT NULL.
      final meta = currentUser?.userMetadata ?? const <String, dynamic>{};
      try {
        await c.from('User').insert({
          'id': uid,
          'auth_uid': uid,
          'email': currentUser?.email ?? '',
          'firstName': (meta['firstName'] as String? ?? '').trim(),
          'lastName': (meta['lastName'] as String? ?? '').trim(),
          'phone': (meta['phone'] as String? ?? '').trim(),
          'passwordHash': '',
        });
      } catch (_) {
        return null; // RLS rejected (e.g. row already exists) — no profile.
      }
      userRow = await c
          .from('User')
          .select('id,email,firstName,lastName,phone,avatarUrl,banned,banReason')
          .eq('auth_uid', uid)
          .maybeSingle();
      if (userRow == null) return null;
    }

    final rawRows = await c
        .from('Address')
        .select('id,label,line1,line2,city,postalCode,latitude,longitude,isDefault')
        .eq('userId', userRow['id'] as String);

    final sorted = List<Map<String, dynamic>>.from(
      (rawRows as List).map((a) => Map<String, dynamic>.from(a as Map)),
    )..sort((a, b) {
        final da = a['isDefault'] == true ? 0 : 1;
        final db = b['isDefault'] == true ? 0 : 1;
        return da.compareTo(db);
      });

    final addresses = sorted.map((m) {
      return <String, dynamic>{
        'id': m['id'],
        'label': m['label'],
        'address': m['line1'],
        'quartier': m['line2'],
        'city': m['city'],
        'zipCode': m['postalCode'],
        'latitude': m['latitude'],
        'longitude': m['longitude'],
        'isDefault': m['isDefault'] ?? false,
      };
    }).toList();

    final firstName = (userRow['firstName'] as String? ?? '').trim();
    final lastName = (userRow['lastName'] as String? ?? '').trim();

    return <String, dynamic>{
      'id': userRow['id'],
      'email': userRow['email'] ?? '',
      'name': [firstName, lastName].where((p) => p.isNotEmpty).join(' ').trim(),
      'phone': userRow['phone'] ?? '',
      'avatarUrl': userRow['avatarUrl'],
      'banned': userRow['banned'] ?? false,
      'banReason': userRow['banReason'],
      'address': sorted.isNotEmpty ? sorted.first['line1'] : null,
      'addresses': addresses,
    };
  }
}
