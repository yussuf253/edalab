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
  /// Before this, [modules] only reflects hardcoded defaults — UI should not
  /// trust it (a fresh install would briefly show every module as enabled).
  bool _hydrated = false;

  /// True while [modules] only reflects the hardcoded defaults because no
  /// configuration has ever been persisted (fresh install). The defaults
  /// show every module as enabled, so UI should keep its loading skeleton
  /// up until the first server sync lands instead of flashing all modules.
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

  /// True while the enabled set is only the hardcoded defaults (nothing
  /// persisted yet — see [_usingDefaults]).
  bool get isUsingDefaults => _usingDefaults;

  /// True after the first server sync of this run has settled.
  bool get hasSyncedOnce => _hasSyncedOnce;
  String? get errorMessage => _errorMessage;
  List<ManagedModule> get modules => _accessService.modules;
  Set<String> get enabledModuleIds => _accessService.enabledModuleIds;

  bool isEnabled(String moduleIdOrType) =>
      _accessService.isEnabled(moduleIdOrType);

  Future<void> hydrateFromStorage() async {
    final raw = await AppPreferences.getModuleConfigJson();
    if (raw == null || raw.trim().isEmpty) {
      _usingDefaults = true;
      _accessService.applyModules(const []);
      _hydrated = true;
      notifyListeners();
      return;
    }

    var appliedStoredConfig = false;
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) {
        _hydrated = true;
        notifyListeners();
        return;
      }
      final modules = decoded
          .whereType<Map>()
          .map(
            (entry) => ManagedModule.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList();
      if (modules.isNotEmpty) {
        _accessService.applyModules(modules);
        appliedStoredConfig = true;
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Failed to hydrate module configuration from storage.');
      }
    } finally {
      _usingDefaults = !appliedStoredConfig;
      _hydrated = true;
      notifyListeners();
    }
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
      _accessService.applyModules(modules);
      _usingDefaults = modules.isEmpty;
      await AppPreferences.setModuleConfigJson(
        json.encode(modules.map((module) => module.toJson()).toList()),
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = ApiClient.userFacingError(error);
      // Persisted config still stands; the next trigger (app resume,
      // pull-to-refresh) will retry.
    } finally {
      _hasSyncedOnce = true;
      _isLoading = false;
      notifyListeners();
    }
  }
}
