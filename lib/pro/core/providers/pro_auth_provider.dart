import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_preferences.dart';
import '../models/pro_profile.dart';
import '../utils/pro_module_helper.dart';

class ProAuthProvider extends ChangeNotifier {
  ProProfile? _currentProfile;
  bool _isLoading = false;
  int _unreadInboxCount = 0;

  ProProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentProfile != null;
  int get unreadInboxCount => _unreadInboxCount;
  bool get hasUnreadInbox => _unreadInboxCount > 0;
  bool get supportsInbox =>
      _currentProfile != null && _supportsInbox(_currentProfile!.type);

  bool _isConnectionError(Object error) {
    return error.toString().contains('Could not reach the API at');
  }

  bool _isMissingProRoute(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('route not found') ||
        message.contains('cannot post /pro') ||
        message.contains('cannot get /pro');
  }

  Future<void> _persistLocalProfile(ProProfile profile) {
    return AppPreferences.setProProfileJson(jsonEncode(profile.toJson()));
  }

  bool _supportsInbox(ProProfileType type) {
    return {
      ProProfileType.shop,
      ProProfileType.provider,
      ProProfileType.doctor,
      ProProfileType.delivery,
      ProProfileType.rider,
    }.contains(type);
  }

  void updateUnreadInboxCount(int value) {
    final next = value < 0 ? 0 : value;
    if (_unreadInboxCount == next) return;
    _unreadInboxCount = next;
    notifyListeners();
  }

  Future<void> refreshInboxSummary({bool forceRefresh = true}) async {
    final profile = _currentProfile;
    if (profile == null || !_supportsInbox(profile.type)) {
      updateUnreadInboxCount(0);
      return;
    }

    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get(
              '/messages/pro/${profile.userId}/summary',
              forceRefresh: forceRefresh,
            )
            as Map,
      );
      updateUnreadInboxCount((response['unreadCount'] as num?)?.toInt() ?? 0);
    } catch (_) {}
  }

  ProProfile _profileFromApi(Map<String, dynamic> json) {
    final profile = ProProfile.fromJson(json);
    return profile.copyWith(
      activeModules: ProModuleHelper.sanitizeModules(
        profile.type,
        profile.activeModules,
      ),
    );
  }

  Map<String, dynamic> _profilePayload({
    required String userId,
    required ProProfileType type,
    required List<ProModule> modules,
    required String businessName,
    bool? isOnline,
  }) {
    final payload = <String, dynamic>{
      'userId': userId,
      'type': _typeToApi(type),
      'activeModules': modules.map(_moduleToApi).toList(),
      'businessName': businessName,
    };
    if (isOnline != null) {
      payload['isOnline'] = isOnline;
    }
    return payload;
  }

  Future<void> signUpAsPro({
    required String userId,
    required ProProfileType type,
    required List<ProModule> selectedModules,
    required String businessName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final normalizedModules = ProModuleHelper.sanitizeModules(
        type,
        selectedModules,
      );
      final payload = _profilePayload(
        userId: userId,
        type: type,
        modules: normalizedModules,
        businessName: businessName,
      );

      try {
        final response = Map<String, dynamic>.from(
          await ApiClient.post('/pro', payload) as Map,
        );
        _currentProfile = _profileFromApi(response);
        await refreshInboxSummary();
      } catch (error) {
        if (!_isConnectionError(error) && !_isMissingProRoute(error)) {
          rethrow;
        }

        _currentProfile = ProProfile(
          id: 'pro_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          type: type,
          activeModules: normalizedModules,
          businessName: businessName,
          isOnline: true,
        );
        updateUnreadInboxCount(0);
      }

      await _persistLocalProfile(_currentProfile!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (userId.isEmpty) {
        _currentProfile = null;
        updateUnreadInboxCount(0);
        return;
      }

      try {
        final response = Map<String, dynamic>.from(
          await ApiClient.get('/pro/$userId', forceRefresh: true) as Map,
        );
        _currentProfile = _profileFromApi(response);
        await _persistLocalProfile(_currentProfile!);
        await refreshInboxSummary();
        return;
      } catch (error) {
        final message = error.toString();
        if (message.contains('Pro profile not found')) {
          _currentProfile = null;
          updateUnreadInboxCount(0);
          await AppPreferences.clearProProfileJson();
          return;
        }

        if (!_isConnectionError(error) && !_isMissingProRoute(error)) {
          rethrow;
        }
      }

      final rawProfile = await AppPreferences.getProProfileJson();
      if (rawProfile == null || rawProfile.isEmpty) {
        _currentProfile = null;
        return;
      }

      final profile = ProProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(rawProfile) as Map),
      );
      _currentProfile = profile.userId == userId
          ? profile.copyWith(
              activeModules: ProModuleHelper.sanitizeModules(
                profile.type,
                profile.activeModules,
              ),
            )
          : null;
      await refreshInboxSummary(forceRefresh: false);
    } catch (_) {
      _currentProfile = null;
      updateUnreadInboxCount(0);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentProfile = null;
    _unreadInboxCount = 0;
    await AppPreferences.clearProProfileJson();
    notifyListeners();
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final profile = _currentProfile;
    if (profile == null) return;

    final previous = profile;
    _currentProfile = profile.copyWith(isOnline: isOnline);
    notifyListeners();

    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/pro/${profile.userId}/online-status', {
              'isOnline': isOnline,
            })
            as Map,
      );
      _currentProfile = _profileFromApi(response);
      await _persistLocalProfile(_currentProfile!);
      notifyListeners();
    } catch (error) {
      if (_isConnectionError(error)) {
        await _persistLocalProfile(_currentProfile!);
        return;
      }
      _currentProfile = previous;
      notifyListeners();
      rethrow;
    }
  }

  String _typeToApi(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return 'SHOP';
      case ProProfileType.provider:
        return 'PROVIDER';
      case ProProfileType.doctor:
        return 'DOCTOR';
      case ProProfileType.delivery:
        return 'DELIVERY';
      case ProProfileType.rider:
        return 'RIDER';
    }
  }

  String _moduleToApi(ProModule module) {
    switch (module) {
      case ProModule.shopping:
        return 'SHOPPING';
      case ProModule.food:
        return 'FOOD';
      case ProModule.pharmacy:
        return 'PHARMACY';
      case ProModule.services:
        return 'SERVICES';
      case ProModule.laundry:
        return 'LAUNDRY';
      case ProModule.doctor:
        return 'DOCTOR';
      case ProModule.shoppingDelivery:
        return 'SHOPPING_DELIVERY';
      case ProModule.foodDelivery:
        return 'FOOD_DELIVERY';
      case ProModule.pharmacyDelivery:
        return 'PHARMACY_DELIVERY';
      case ProModule.ride:
        return 'RIDE';
    }
  }
}
