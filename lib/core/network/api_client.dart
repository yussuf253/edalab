import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/app_preferences.dart';

enum ApiSessionScope { user, pro }

class ApiClient {
  static const _defaultPort = '5050';
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://edalab.onrender.com/api',
  );
  static const String _configuredHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '127.0.0.1',
  );
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const int _maxGetRetries = 2;
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String connectionErrorMessage =
      'Unable to connect right now. Please check your internet connection and try again.';
  static final RegExp _legacyConnectionLeakPattern = RegExp(
    r'could not reach the api at|original error|confirm the hosted backend url|localhost:\d+|10\.0\.2\.2|onrender\.com',
    caseSensitive: false,
  );
  static final http.Client _httpClient = http.Client();
  static final Map<String, _CachedResponse> _getCache = {};
  static final Map<String, Future<dynamic>> _pendingGets = {};
  static const Duration _connectionLogCooldown = Duration(seconds: 3);
  static const Duration _warmUpCooldown = Duration(minutes: 2);
  static const Duration _warmUpTimeout = Duration(seconds: 8);
  static const int _warmUpAttempts = 2;
  static DateTime? _lastConnectionLogAt;
  static DateTime? _lastWarmUpAt;
  static Future<void>? _warmUpInFlight;
  static String? _token;
  static ApiSessionScope _sessionScope = ApiSessionScope.user;

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.endsWith('/')
          ? _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1)
          : _configuredBaseUrl;
    }
    if (kIsWeb) return 'http://localhost:$_defaultPort/api';
    if (Platform.isAndroid) {
      final host = _configuredHost == '127.0.0.1'
          ? '10.0.2.2'
          : _configuredHost;
      return 'http://$host:$_defaultPort/api';
    }
    return 'http://$_configuredHost:$_defaultPort/api';
  }

  static Future<void> initialize({
    ApiSessionScope scope = ApiSessionScope.user,
  }) async {
    _sessionScope = scope;
    _token = await _readPersistedToken();
  }

  static Future<void> warmUpBackend({bool force = false}) async {
    final now = DateTime.now();
    final isCoolingDown =
        !force &&
        _lastWarmUpAt != null &&
        now.difference(_lastWarmUpAt!) < _warmUpCooldown;
    if (isCoolingDown) return;

    final inFlight = _warmUpInFlight;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final warmUpFuture = _runWarmUpRequest();
    _warmUpInFlight = warmUpFuture;
    try {
      await warmUpFuture;
      _lastWarmUpAt = DateTime.now();
    } finally {
      _warmUpInFlight = null;
    }
  }

  static void warmUpBackendInBackground({bool force = false}) {
    unawaited(warmUpBackend(force: force));
  }

  static Future<void> _runWarmUpRequest() async {
    final uri = Uri.parse('$baseUrl/health');
    for (var attempt = 0; attempt < _warmUpAttempts; attempt++) {
      try {
        final response = await _httpClient.get(uri).timeout(_warmUpTimeout);
        if (response.statusCode == 200) {
          return;
        }
      } on TimeoutException {
        // Ignore and retry.
      } on SocketException {
        // Ignore and retry.
      } on http.ClientException {
        // Ignore and retry.
      }

      if (attempt < _warmUpAttempts - 1) {
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
  }

  static Future<void> configureSessionScope(ApiSessionScope scope) async {
    if (_sessionScope == scope) {
      _token = await _readPersistedToken();
      return;
    }

    _sessionScope = scope;
    _token = await _readPersistedToken();
    clearCache();
  }

  static Future<void> setToken(String? token) async {
    final previousToken = _token;
    _token = token;
    if (previousToken != token) {
      clearCache();
    }
    if (token == null || token.isEmpty) {
      await _clearPersistedToken();
      return;
    }
    await _writePersistedToken(token);
  }

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    final token = _token ?? await _readPersistedToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static Future<String?> _readPersistedToken() {
    switch (_sessionScope) {
      case ApiSessionScope.user:
        return AppPreferences.getAuthToken();
      case ApiSessionScope.pro:
        return AppPreferences.getProAuthToken();
    }
  }

  static Future<void> _writePersistedToken(String token) {
    switch (_sessionScope) {
      case ApiSessionScope.user:
        return AppPreferences.setAuthToken(token);
      case ApiSessionScope.pro:
        return AppPreferences.setProAuthToken(token);
    }
  }

  static Future<void> _clearPersistedToken() {
    switch (_sessionScope) {
      case ApiSessionScope.user:
        return AppPreferences.clearAuthToken();
      case ApiSessionScope.pro:
        return AppPreferences.clearProAuthToken();
    }
  }

  static Exception _connectionException(Object error) {
    if (kDebugMode) {
      final now = DateTime.now();
      final shouldLog =
          _lastConnectionLogAt == null ||
          now.difference(_lastConnectionLogAt!) >= _connectionLogCooldown;
      if (shouldLog) {
        debugPrint('Network request failed: $error');
        _lastConnectionLogAt = now;
      }
    }
    return const _ApiConnectionException(connectionErrorMessage);
  }

  static bool isConnectionError(Object error) =>
      error is _ApiConnectionException;

  static String userFacingError(Object error) {
    final rawMessage = error
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
    if (rawMessage.isEmpty) return genericErrorMessage;

    final messageLower = rawMessage.toLowerCase();
    final looksLikeConnectionFailure =
        messageLower.contains('socketexception') ||
        messageLower.contains('timeoutexception') ||
        messageLower.contains('failed host lookup') ||
        messageLower.contains('connection refused') ||
        messageLower.contains('network is unreachable') ||
        _legacyConnectionLeakPattern.hasMatch(rawMessage) ||
        rawMessage.contains(baseUrl);

    if (isConnectionError(error) || looksLikeConnectionFailure) {
      return connectionErrorMessage;
    }

    return rawMessage;
  }

  static String? normalizePublicUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return null;

    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) return trimmed;

    final apiUri = Uri.tryParse(baseUrl);
    final apiHost = apiUri?.host ?? '';
    final isRenderHost = parsed.host.endsWith('.onrender.com');
    final apiOrigin = apiUri == null
        ? null
        : Uri(
            scheme: apiUri.scheme,
            host: apiUri.host,
            port: apiUri.hasPort ? apiUri.port : null,
          ).toString().replaceFirst(RegExp(r'/$'), '');

    final storagePathMatch = RegExp(
      r'^/storage/v1/object/(?:public/)?([^/]+)/(.+)$',
    ).firstMatch(parsed.path);
    if (storagePathMatch != null && apiOrigin != null) {
      final bucket = Uri.decodeComponent(storagePathMatch.group(1)!);
      final rawObjectPath = storagePathMatch.group(2)!;
      final objectSegments = rawObjectPath
          .split('/')
          .where((segment) => segment.trim().isNotEmpty)
          .map((segment) => Uri.encodeComponent(Uri.decodeComponent(segment)))
          .join('/');
      if (objectSegments.isNotEmpty) {
        return '$apiOrigin/uploads/supabase/${Uri.encodeComponent(bucket)}/$objectSegments';
      }
    }

    if (parsed.scheme == 'supabase' && apiOrigin != null) {
      final bucket = parsed.host.trim();
      final objectSegments = parsed.pathSegments
          .where((segment) => segment.trim().isNotEmpty)
          .map((segment) => Uri.encodeComponent(Uri.decodeComponent(segment)))
          .join('/');
      if (bucket.isNotEmpty && objectSegments.isNotEmpty) {
        return '$apiOrigin/uploads/supabase/${Uri.encodeComponent(bucket)}/$objectSegments';
      }
    }

    if (!parsed.hasScheme) {
      if (trimmed.startsWith('/') && apiUri != null) {
        final origin = Uri(
          scheme: apiUri.scheme,
          host: apiUri.host,
          port: apiUri.hasPort ? apiUri.port : null,
        );
        return origin.resolveUri(Uri.parse(trimmed)).toString();
      }
      return trimmed;
    }

    if (parsed.scheme == 'http' &&
        (isRenderHost || (apiHost.isNotEmpty && parsed.host == apiHost))) {
      return parsed.replace(scheme: 'https').toString();
    }

    return trimmed;
  }

  static bool _looksLikeUrlKey(String? key) {
    if (key == null || key.trim().isEmpty) return false;
    final lower = key.toLowerCase();
    return lower.contains('url') ||
        lower.contains('uri') ||
        lower.contains('image') ||
        lower.contains('avatar') ||
        lower.contains('thumbnail');
  }

  static dynamic _normalizeResponseUrls(dynamic value, [String? key]) {
    if (value is Map) {
      final normalized = <String, dynamic>{};
      for (final entry in value.entries) {
        final entryKey = entry.key.toString();
        normalized[entryKey] = _normalizeResponseUrls(entry.value, entryKey);
      }
      return normalized;
    }

    if (value is List) {
      return value.map((item) => _normalizeResponseUrls(item, key)).toList();
    }

    if (value is String) {
      final trimmed = value.trim();
      final likelyPath = trimmed.startsWith('/uploads/');
      final likelySupabaseStorage = trimmed.contains('/storage/v1/object/');
      if (_looksLikeUrlKey(key) || likelyPath || likelySupabaseStorage) {
        return normalizePublicUrl(trimmed) ?? trimmed;
      }
    }

    return value;
  }

  static String _cacheKey(String endpoint) =>
      '$baseUrl|$endpoint|${_token ?? ''}';

  static bool _isRetryableGetStatus(int statusCode) =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;

  static Duration _getRetryBackoff(int attempt) {
    switch (attempt) {
      case 0:
        return const Duration(milliseconds: 700);
      case 1:
        return const Duration(seconds: 2);
      default:
        return const Duration(seconds: 3);
    }
  }

  static dynamic _decodeBody(String body) =>
      _normalizeResponseUrls(json.decode(body));

  static dynamic _cloneDecodedData(dynamic value) {
    if (value is Map || value is List) {
      return json.decode(json.encode(value));
    }
    return value;
  }

  static void clearCache() {
    _getCache.clear();
    _pendingGets.clear();
  }

  static void invalidateCache([String? endpointPrefix]) {
    if (endpointPrefix == null || endpointPrefix.isEmpty) {
      clearCache();
      return;
    }

    final matchingKeys = _getCache.keys
        .where(
          (key) =>
              key.contains('|$endpointPrefix|') ||
              key.contains('|$endpointPrefix?'),
        )
        .toList();
    for (final key in matchingKeys) {
      _getCache.remove(key);
    }
  }

  static Future<dynamic> get(
    String endpoint, {
    Duration cacheDuration = _defaultCacheDuration,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _cacheKey(endpoint);
    if (!forceRefresh) {
      final cached = _getCache[cacheKey];
      if (cached != null && !cached.isExpired(cacheDuration)) {
        return _decodeBody(cached.body);
      }

      final pending = _pendingGets[cacheKey];
      if (pending != null) {
        return pending.then(_cloneDecodedData);
      }
    }

    final future = _performGet(endpoint, cacheKey);
    _pendingGets[cacheKey] = future;

    try {
      return await future;
    } catch (error) {
      if (!forceRefresh && isConnectionError(error)) {
        final staleCached = _getCache[cacheKey];
        if (staleCached != null) {
          if (kDebugMode) {
            debugPrint('Serving stale cache for GET $endpoint after timeout.');
          }
          return _decodeBody(staleCached.body);
        }
      }
      rethrow;
    } finally {
      _pendingGets.remove(cacheKey);
    }
  }

  static Future<dynamic> _performGet(String endpoint, String cacheKey) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = await _headers();

    late http.Response response;
    for (var attempt = 0; attempt <= _maxGetRetries; attempt++) {
      try {
        response = await _httpClient
            .get(uri, headers: requestHeaders)
            .timeout(_requestTimeout);

        final shouldRetryStatus =
            _isRetryableGetStatus(response.statusCode) &&
            attempt < _maxGetRetries;
        if (!shouldRetryStatus) {
          break;
        }
      } on TimeoutException catch (error) {
        if (attempt >= _maxGetRetries) {
          throw _connectionException(error);
        }
      } on SocketException catch (error) {
        if (attempt >= _maxGetRetries) {
          throw _connectionException(error);
        }
      } on http.ClientException catch (error) {
        if (attempt >= _maxGetRetries) {
          throw _connectionException(error);
        }
      }

      await Future.delayed(_getRetryBackoff(attempt));
    }

    if (response.statusCode == 200) {
      _getCache[cacheKey] = _CachedResponse(
        body: response.body,
        cachedAt: DateTime.now(),
      );
      return _decodeBody(response.body);
    } else {
      final body = response.body.trim();
      if (body.isNotEmpty) {
        final errorDecoded = json.decode(body);
        throw Exception(
          errorDecoded['error'] ??
              'Failed to load data: ${response.statusCode}',
        );
      }
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  static Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    late http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
            body: json.encode(data),
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw _connectionException(error);
    } on SocketException catch (error) {
      throw _connectionException(error);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      clearCache();
      return _decodeBody(response.body);
    } else {
      final errorDecoded = json.decode(response.body);
      throw Exception(
        errorDecoded['error'] ?? 'Failed to post data: ${response.statusCode}',
      );
    }
  }

  static Future<dynamic> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    late http.Response response;
    try {
      response = await _httpClient
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
            body: json.encode(data),
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw _connectionException(error);
    } on SocketException catch (error) {
      throw _connectionException(error);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      clearCache();
      return _decodeBody(response.body);
    } else {
      final errorDecoded = json.decode(response.body);
      throw Exception(
        errorDecoded['error'] ?? 'Failed to patch data: ${response.statusCode}',
      );
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    late http.Response response;
    try {
      response = await _httpClient
          .delete(Uri.parse('$baseUrl$endpoint'), headers: await _headers())
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw _connectionException(error);
    } on SocketException catch (error) {
      throw _connectionException(error);
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      clearCache();
      if (response.body.isEmpty) {
        return null;
      }
      return _decodeBody(response.body);
    } else {
      final errorDecoded = json.decode(response.body);
      throw Exception(
        errorDecoded['error'] ??
            'Failed to delete data: ${response.statusCode}',
      );
    }
  }
}

class _ApiConnectionException implements Exception {
  final String message;

  const _ApiConnectionException(this.message);

  @override
  String toString() => 'Exception: $message';
}

class _CachedResponse {
  final String body;
  final DateTime cachedAt;

  const _CachedResponse({required this.body, required this.cachedAt});

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}
