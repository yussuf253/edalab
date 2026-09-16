import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../modules/module_access_service.dart';
import '../network/api_client.dart';
import '../storage/app_preferences.dart';

class ModuleProvider extends ChangeNotifier {
  ModuleProvider({ModuleAccessService? accessService})
    : _accessService = accessService ?? ModuleAccessService.instance;

  final ModuleAccessService _accessService;
  bool _isLoading = false;
  /// True once the persisted configuration has been loaded from storage.
  /// Before this, [modules] only reflects hardcoded defaults — UI should not
  /// trust it (a fresh install would briefly show every module as enabled).
  bool _hydrated = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  /// True when the module configuration can be trusted (storage loaded;
  /// server sync may still be in flight afterwards).
  bool get isReady => _hydrated;
  String? get errorMessage => _errorMessage;
  List<ManagedModule> get modules => _accessService.modules;
  Set<String> get enabledModuleIds => _accessService.enabledModuleIds;

  bool isEnabled(String moduleIdOrType) =>
      _accessService.isEnabled(moduleIdOrType);

  Future<void> hydrateFromStorage() async {
    final raw = await AppPreferences.getModuleConfigJson();
    if (raw == null || raw.trim().isEmpty) {
      _accessService.applyModules(const []);
      _hydrated = true;
      notifyListeners();
      return;
    }

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
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Failed to hydrate module configuration from storage.');
      }
    } finally {
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

  Future<void> refreshFromServer() {
    // Coalesce concurrent calls onto a single request.
    final existing = _pendingRefresh;
    if (existing != null) return existing;

    final task = _refreshFromServerInternal().whenComplete(() {
      _pendingRefresh = null;
    });
    _pendingRefresh = task;
    return task;
  }

  Future<void> _refreshFromServerInternal() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.get('/modules', forceRefresh: true);
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
      await AppPreferences.setModuleConfigJson(
        json.encode(modules.map((module) => module.toJson()).toList()),
      );
      _errorMessage = null;
    } catch (error) {
      _errorMessage = ApiClient.userFacingError(error);
      // Persisted config still stands; the next trigger (app resume,
      // pull-to-refresh) will retry.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
