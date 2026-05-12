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
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ManagedModule> get modules => _accessService.modules;
  Set<String> get enabledModuleIds => _accessService.enabledModuleIds;

  bool isEnabled(String moduleIdOrType) =>
      _accessService.isEnabled(moduleIdOrType);

  Future<void> hydrateFromStorage() async {
    final raw = await AppPreferences.getModuleConfigJson();
    if (raw == null || raw.trim().isEmpty) {
      _accessService.applyModules(const []);
      notifyListeners();
      return;
    }

    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return;
      final modules = decoded
          .whereType<Map>()
          .map(
            (entry) => ManagedModule.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList();
      if (modules.isNotEmpty) {
        _accessService.applyModules(modules);
        notifyListeners();
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('Failed to hydrate module configuration from storage.');
      }
    }
  }

  Future<void> initialize() async {
    await hydrateFromStorage();
    await refreshFromServer();
  }

  Future<void> refreshFromServer() async {
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
