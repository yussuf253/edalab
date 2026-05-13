import 'dart:async';
import 'dart:math';

import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/constants.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:amplitude_flutter/events/identify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../storage/app_preferences.dart';
import 'analytics_events.dart';

class AnalyticsService with WidgetsBindingObserver {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const String _apiKey = String.fromEnvironment(
    'AMPLITUDE_API_KEY',
    defaultValue: '',
  );
  static const String _serverZone = String.fromEnvironment(
    'AMPLITUDE_SERVER_ZONE',
    defaultValue: 'US',
  );
  static const int _maxBatchSize = 25;
  static const Duration _flushInterval = Duration(seconds: 15);
  static const Set<String> _sensitiveExactKeys = {
    'email',
    'phone',
    'phone_number',
    'mobile',
    'address',
    'street',
    'street_address',
    'address_line1',
    'address_line2',
    'zip',
    'zipcode',
    'postal_code',
    'postal',
    'lat',
    'lng',
    'latitude',
    'longitude',
    'coords',
    'coordinates',
    'note',
    'notes',
    'instruction',
    'instructions',
    'message',
    'comment',
    'avatar_url',
    'image_url',
  };
  static const List<String> _sensitiveKeyTokens = [
    'email',
    'phone',
    'mobile',
    'address',
    'street',
    'postal',
    'zipcode',
    'latitude',
    'longitude',
    'coord',
    'note',
    'instruction',
    'message',
    'comment',
    'avatar',
    'image',
    'prescription',
  ];
  static final RegExp _emailPattern = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );
  static final RegExp _phonePattern = RegExp(
    r'^\+?[\d\s().-]{8,}$',
    caseSensitive: false,
  );
  static final RegExp _urlPattern = RegExp(r'https?://', caseSensitive: false);
  static const Map<String, List<String>> _requiredEventProperties = {
    AnalyticsEvents.screenViewed: ['screen_name', 'module'],
    AnalyticsEvents.navigationTransition: ['from_screen', 'to_screen'],
    AnalyticsEvents.searchPerformed: ['module', 'query_length'],
    AnalyticsEvents.filterApplied: ['module', 'filter_type', 'filter_value'],
    AnalyticsEvents.sortApplied: ['module', 'sort_key'],
    AnalyticsEvents.entityOpened: ['module', 'entity_type', 'entity_id'],
    AnalyticsEvents.checkoutCompleted: ['module_type'],
    AnalyticsEvents.checkoutValidationFailed: ['reason'],
  };

  final Random _random = Random();
  final Map<String, Object?> _globalProperties = {};
  final Map<String, Object?> _userProperties = {};
  Amplitude? _amplitude;

  bool _initialized = false;
  bool _enabled = false;
  String? _deviceId;
  String? _userId;
  int _sessionId = DateTime.now().millisecondsSinceEpoch;

  GoRouter? _attachedRouter;
  VoidCallback? _routerListener;
  String _lastTrackedScreen = '';

  bool get isEnabled => _enabled;

  Future<void> initialize({
    required String localeCode,
    String appVariant = 'user',
  }) async {
    if (_initialized) {
      setGlobalProperties({'locale': localeCode, 'app_variant': appVariant});
      return;
    }

    _initialized = true;
    final normalizedApiKey = _apiKey.trim();
    if (normalizedApiKey.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'Amplitude disabled: define AMPLITUDE_API_KEY to enable analytics.',
        );
      }
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[Analytics] Initializing Amplitude (platform=$_platformName, key_length=${normalizedApiKey.length}, zone=$_resolvedServerZoneLabel)',
      );
    }

    _amplitude = Amplitude(
      Configuration(
        apiKey: normalizedApiKey,
        flushQueueSize: _maxBatchSize,
        flushIntervalMillis: _flushInterval.inMilliseconds,
        minIdLength: 1,
        serverZone: _resolvedServerZone,
        logLevel: kDebugMode ? LogLevel.warn : LogLevel.error,
      ),
    );
    final isBuilt = await _amplitude!.isBuilt;
    if (!isBuilt) {
      if (kDebugMode) {
        debugPrint('Amplitude disabled: SDK initialization failed.');
      }
      _amplitude = null;
      return;
    }
    if (kDebugMode) {
      debugPrint('[Analytics] Amplitude SDK initialized successfully.');
    }

    _enabled = true;
    WidgetsBinding.instance.addObserver(this);
    _deviceId = await _loadOrCreateDeviceId();
    _fireAndForget(_amplitude!.setDeviceId(_deviceId), 'setDeviceId');
    if (_userId != null) {
      _fireAndForget(_amplitude!.setUserId(_userId), 'setUserId');
    }
    _sessionId = DateTime.now().millisecondsSinceEpoch;

    _globalProperties
      ..clear()
      ..addAll({
        'locale': localeCode,
        'app_variant': appVariant,
        'platform': _platformName,
        'is_debug': kDebugMode,
        'event_schema_version': 1,
      });

    if (_userProperties.isNotEmpty) {
      final identify = Identify();
      _userProperties.forEach((key, value) {
        identify.set(key, value);
      });
      _fireAndForget(_amplitude!.identify(identify), 'identify.bootstrap');
    }

    track(AnalyticsEvents.appOpened, properties: {'cold_start': true});
    _fireAndForget(flush(), 'flush.bootstrap');
  }

  void attachRouter(GoRouter router) {
    if (!_enabled) return;
    if (identical(_attachedRouter, router)) return;

    _detachRouterListener();
    _attachedRouter = router;
    _routerListener = () => _trackCurrentRoute(force: false);
    router.routeInformationProvider.addListener(_routerListener!);
    _trackCurrentRoute(force: true);
  }

  void setUserId(String? userId) {
    final normalized = userId?.trim();
    final nextUserId = (normalized == null || normalized.isEmpty)
        ? null
        : normalized;

    if (_userId == nextUserId) return;
    _userId = nextUserId;
    final amplitude = _amplitude;
    if (_enabled && amplitude != null) {
      _fireAndForget(amplitude.setUserId(nextUserId), 'setUserId');
    }
  }

  void setUserProperties(
    Map<String, Object?> properties, {
    bool sendIdentify = true,
  }) {
    if (!_enabled) return;
    final sanitized = _sanitizeMap(properties);
    if (sanitized.isEmpty) return;

    _userProperties.addAll(sanitized);

    if (!sendIdentify) return;
    final amplitude = _amplitude;
    if (!_enabled || amplitude == null) return;

    final identify = Identify();
    sanitized.forEach((key, value) {
      identify.set(key, value);
    });
    _fireAndForget(amplitude.identify(identify), 'identify');
  }

  void setGlobalProperties(Map<String, Object?> properties) {
    if (!_enabled) return;
    final sanitized = _sanitizeMap(properties);
    if (sanitized.isEmpty) return;
    _globalProperties.addAll(sanitized);
  }

  void track(String eventName, {Map<String, Object?> properties = const {}}) {
    final amplitude = _amplitude;
    if (!_enabled || amplitude == null) return;
    final normalizedEvent = eventName.trim();
    if (normalizedEvent.isEmpty) return;

    if (!_isValidEventName(normalizedEvent)) {
      _logValidation('invalid_event_name', {'event_name': normalizedEvent});
    }

    final eventProperties = _sanitizeMap({..._globalProperties, ...properties});
    final missingProperties = _missingRequiredProperties(
      normalizedEvent,
      eventProperties,
    );
    if (missingProperties.isNotEmpty) {
      _logValidation('missing_required_properties', {
        'event_name': normalizedEvent,
        'missing': missingProperties,
      });
      eventProperties['validation_missing_props'] = missingProperties.join(',');
    }

    _fireAndForget(
      amplitude.track(
        BaseEvent(
          normalizedEvent,
          userId: _userId,
          deviceId: _deviceId,
          sessionId: _sessionId,
          eventProperties: _toDynamicMap(eventProperties),
        ),
      ),
      'track.$normalizedEvent',
    );
  }

  Future<void> flush() async {
    if (!_enabled) return;
    await _amplitude?.flush();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;

    if (state == AppLifecycleState.resumed) {
      _sessionId = DateTime.now().millisecondsSinceEpoch;
      track(AnalyticsEvents.appResumed);
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(flush());
    }
  }

  Future<String> _loadOrCreateDeviceId() async {
    final stored = await AppPreferences.getAnalyticsDeviceId();
    if (stored != null && stored.trim().isNotEmpty) {
      return stored;
    }

    final next =
        'dev_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1 << 30)}';
    await AppPreferences.setAnalyticsDeviceId(next);
    return next;
  }

  void _trackCurrentRoute({required bool force}) {
    final router = _attachedRouter;
    if (router == null) return;

    final routeInformation = router.routeInformationProvider.value;
    final uri = routeInformation.uri;
    final path = uri.path.isEmpty ? '/' : uri.path;

    if (path.startsWith('/pro')) return;

    final normalized = _normalizePath(path);
    if (!force && normalized == _lastTrackedScreen) return;

    final previous = _lastTrackedScreen;
    _lastTrackedScreen = normalized;
    final module = _moduleForPath(normalized);

    if (previous.isNotEmpty && previous != normalized) {
      track(
        AnalyticsEvents.navigationTransition,
        properties: {
          'from_screen': previous,
          'to_screen': normalized,
          'from_module': _moduleForPath(previous),
          'to_module': module,
          'query_param_count': uri.queryParameters.length,
          'has_query_params': uri.queryParameters.isNotEmpty,
        },
      );
    }

    track(
      AnalyticsEvents.screenViewed,
      properties: {
        'screen_name': normalized,
        'module': module,
        'path_depth': uri.pathSegments.length,
        'raw_path': path,
        'query_param_count': uri.queryParameters.length,
        'has_query_params': uri.queryParameters.isNotEmpty,
        'has_dynamic_segments': normalized.contains(':id'),
        if (previous.isNotEmpty) 'previous_screen': previous,
      },
    );
  }

  String _normalizePath(String rawPath) {
    if (rawPath.isEmpty || rawPath == '/') return '/';

    final segments = rawPath
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map((segment) => _looksLikeIdentifier(segment) ? ':id' : segment)
        .toList(growable: false);

    return '/${segments.join('/')}';
  }

  bool _looksLikeIdentifier(String segment) {
    if (segment.isEmpty) return false;

    if (RegExp(r'^\d{2,}$').hasMatch(segment)) return true;
    if (RegExp(
      r'^(ORD|RID|APT|BKG)-',
      caseSensitive: false,
    ).hasMatch(segment)) {
      return true;
    }
    if (RegExp(r'^[a-f0-9]{8,}$', caseSensitive: false).hasMatch(segment)) {
      return true;
    }
    if (segment.length >= 10 &&
        RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segment) &&
        RegExp(r'\d').hasMatch(segment)) {
      return true;
    }

    return false;
  }

  String _moduleForPath(String path) {
    if (path == '/') return 'home';
    final segments = path.split('/').where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? 'unknown' : segments.first;
  }

  bool _isValidEventName(String eventName) {
    return RegExp(r'^[a-z][a-z0-9_]{2,63}$').hasMatch(eventName);
  }

  List<String> _missingRequiredProperties(
    String eventName,
    Map<String, Object?> properties,
  ) {
    final required = _requiredEventProperties[eventName];
    if (required == null || required.isEmpty) return const [];
    return required
        .where((property) => !properties.containsKey(property))
        .toList(growable: false);
  }

  Map<String, Object?> _sanitizeMap(Map<String, Object?> values) {
    final sanitized = <String, Object?>{};

    values.forEach((key, value) {
      final normalizedKey = key.trim();
      if (normalizedKey.isEmpty) return;
      if (_isSensitiveKey(normalizedKey)) {
        _logValidation('pii_key_dropped', {'key': normalizedKey});
        return;
      }
      final normalized = _sanitizeValue(value);
      if (normalized == null) return;
      sanitized[normalizedKey] = normalized;
    });

    return sanitized;
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null) return null;

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;

      if (_emailPattern.hasMatch(trimmed)) {
        _logValidation('pii_value_dropped', {'type': 'email'});
        return null;
      }

      if (_looksLikePhone(trimmed)) {
        _logValidation('pii_value_dropped', {'type': 'phone'});
        return null;
      }

      if (_urlPattern.hasMatch(trimmed)) {
        _logValidation('pii_value_dropped', {'type': 'url'});
        return null;
      }

      if (trimmed.length <= 256) return trimmed;
      return '${trimmed.substring(0, 256)}...';
    }

    if (value is num || value is bool) return value;

    if (value is DateTime) return value.toIso8601String();

    if (value is Map) {
      final nested = <String, Object?>{};
      value.forEach((key, nestedValue) {
        final nestedKey = key.toString().trim();
        if (nestedKey.isEmpty) return;
        if (_isSensitiveKey(nestedKey)) {
          _logValidation('pii_key_dropped', {'key': nestedKey});
          return;
        }
        final normalizedNestedValue = _sanitizeValue(nestedValue);
        if (normalizedNestedValue == null) return;
        nested[nestedKey] = normalizedNestedValue;
      });
      return nested.isEmpty ? null : nested;
    }

    if (value is Iterable) {
      final normalized = value
          .map(_sanitizeValue)
          .where((item) => item != null)
          .cast<Object?>()
          .toList(growable: false);
      return normalized.isEmpty ? null : normalized;
    }

    return value.toString();
  }

  String get _platformName {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  void _detachRouterListener() {
    final router = _attachedRouter;
    final listener = _routerListener;

    if (router != null && listener != null) {
      router.routeInformationProvider.removeListener(listener);
    }

    _routerListener = null;
  }

  void _logValidation(String reason, Map<String, Object?> metadata) {
    if (kDebugMode) {
      debugPrint('[Analytics][Validation] $reason $metadata');
    }
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.trim().toLowerCase();
    if (_sensitiveExactKeys.contains(normalized)) return true;

    for (final token in _sensitiveKeyTokens) {
      if (normalized.contains(token)) return true;
    }

    return false;
  }

  bool _looksLikePhone(String value) {
    if (!_phonePattern.hasMatch(value)) return false;
    final digitCount = value.replaceAll(RegExp(r'\D'), '').length;
    return digitCount >= 8;
  }

  Map<String, dynamic> _toDynamicMap(Map<String, Object?> input) {
    return input.map((key, value) => MapEntry(key, value));
  }

  ServerZone get _resolvedServerZone {
    final normalized = _serverZone.trim().toUpperCase();
    return normalized == 'EU' ? ServerZone.eu : ServerZone.us;
  }

  String get _resolvedServerZoneLabel {
    return _resolvedServerZone == ServerZone.eu ? 'EU' : 'US';
  }

  void _fireAndForget(Future<void> task, String operation) {
    unawaited(
      task.catchError((Object error, StackTrace stackTrace) {
        if (kDebugMode) {
          debugPrint('[Analytics] $operation failed: $error');
        }
      }),
    );
  }
}
