import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../modules/module_access_service.dart';
import '../network/api_client.dart';
import '../storage/app_preferences.dart';
import '../config/zone_scope.dart';

class ModuleProvider extends ChangeNotifier {
  ModuleProvider({ModuleAccessService? accessService})
    : _accessService = accessService ?? ModuleAccessService.instance;

  final ModuleAccessService _accessService;
  bool _isLoading = false;

  /// True once the persisted configuration has been loaded from storage.
  bool _hydrated = false;

  /// True while no real configuration is known yet (nothing usable in
  /// storage, no successful server sync). The enabled set is then empty —
  /// never the all-active defaults — so gating fails closed.
  bool _usingDefaults = false;

  /// True once a server sync has completed at least once this app run
  /// (success or failure). While it hasn't, UI may show its loading
  /// skeleton — the startup state, not a per-request spinner.
  bool _hasSyncedOnce = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;

  /// True when the module configuration can be trusted (storage loaded;
  /// server sync may still be in flight afterwards).
  bool get isReady => _hydrated;

  /// True when a real module configuration is known — restored from storage
  /// or fetched from the server. While false, [enabledModuleIds] is empty and
  /// [isEnabled] answers false, so no module is treated as active until the
  /// gating is actually known.
  bool get hasKnownConfig => _accessService.hasConfig;

  /// True while the enabled set is still unknown (no usable stored config and
  /// no successful sync yet).
  bool get isUsingDefaults => _usingDefaults;

  /// True after the first server sync of this run has settled.
  bool get hasSyncedOnce => _hasSyncedOnce;
  String? get errorMessage => _errorMessage;
  List<ManagedModule> get modules => _accessService.modules;

  /// The active module ids — the one set the home grid, the nav tabs and the
  /// module-scoped sections all read. Empty (not all-active) while the
  /// configuration is unknown, including during a slow or failed fetch.
  Set<String> get enabledModuleIds => _accessService.enabledModuleIds;

  bool isEnabled(String moduleIdOrType) =>
      _accessService.isEnabled(moduleIdOrType);

  Future<void> hydrateFromStorage() async {
    final raw = await AppPreferences.getModuleConfigJson();
    if (raw == null || raw.trim().isEmpty) {
      _usingDefaults = true;
      _accessService.resetToUnknown();
      _hydrated = true;
      notifyListeners();
      return;
    }

    var appliedStoredConfig = false;
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        final modules = decoded
            .whereType<Map>()
            .map(
              (entry) =>
                  ManagedModule.fromJson(Map<String, dynamic>.from(entry)),
            )
            .toList();
        if (modules.isNotEmpty) {
          _accessService.applyModules(modules);
          appliedStoredConfig = true;
        }
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Failed to hydrate module configuration from storage.');
      }
    }

    if (!appliedStoredConfig) {
      _accessService.resetToUnknown();
    }
    _usingDefaults = !appliedStoredConfig;
    _hydrated = true;
    notifyListeners();
  }

  Future<void> initialize() async {
    await hydrateFromStorage();
    await refreshFromServer();
  }

  /// In-flight guard so lifecycle/pull-to-refresh/timer triggers don't stack
  /// duplicate requests.
  Future<void>? _pendingRefresh;
  String? _pendingZoneKey;

  Future<void> refreshFromServer() {
    final requestedZoneKey = ZoneScope.currentZoneKey;
    final existing = _pendingRefresh;
    if (existing != null) {
      final inFlightZoneKey = _pendingZoneKey;
      if (inFlightZoneKey == requestedZoneKey) return existing;
      return existing.then((_) {
        if (ZoneScope.currentZoneKey != inFlightZoneKey) {
          return refreshFromServer();
        }
      });
    }

    _pendingZoneKey = requestedZoneKey;
    final task = _refreshFromServerInternal(zoneKey: requestedZoneKey)
        .whenComplete(() {
          _pendingRefresh = null;
          _pendingZoneKey = null;
        });
    _pendingRefresh = task;
    return task;
  }

  Future<void> _refreshFromServerInternal({required String? zoneKey}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        zoneKey == null
            ? '/modules'
            : '/modules?zone=${Uri.encodeQueryComponent(zoneKey)}',
        forceRefresh: true,
      );
      if (response is! List) {
        throw Exception('Invalid module configuration payload.');
      }

      final modules = response
          .whereType<Map>()
          .map(
            (entry) => ManagedModule.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList();
      if (modules.isEmpty) {
        // An empty payload carries no configuration — it must not be read as
        // "every module active". Keep the last known set (and its stored
        // copy) instead.
        _errorMessage = null;
        return;
      }
      _accessService.applyModules(modules);
      _usingDefaults = false;
      await AppPreferences.setModuleConfigJson(
        json.encode(modules.map((module) => module.toJson()).toList()),
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = ApiClient.userFacingError(error);
      // The last known configuration (restored from storage or from an
      // earlier successful sync) still stands: a timeout or a dropped
      // connection must never widen the active set. The next trigger (app
      // resume, poll, pull-to-refresh) retries.
    } finally {
      _hasSyncedOnce = true;
      _isLoading = false;
      notifyListeners();
    }
  }
}
