import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/app_preferences.dart';
import '../models/pro_account.dart';
import '../models/pro_profile.dart';
import '../utils/pro_module_helper.dart';

class ProAuthProvider extends ChangeNotifier {
  ProAccount? _currentAccount;
  ProProfile? _currentProfile;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _emailVerificationRequired = false;
  String? _pendingVerificationEmail;
  int _unreadInboxCount = 0;

  ProAccount? get currentAccount => _currentAccount;
  ProProfile? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentAccount != null;
  bool get isBanned => _currentAccount?.isBanned == true;
  String? get banReason => _currentAccount?.banReason;
  bool get isSuperAdmin {
    final email = _currentAccount?.email.toLowerCase().trim() ?? '';
    const configuredEmail = String.fromEnvironment(
      'SUPER_ADMIN_EMAIL',
      defaultValue: 'admin@edalab.com',
    );
    return email == configuredEmail.toLowerCase() ||
        email.startsWith('admin@') ||
        email.contains('+admin@');
  }

  bool get emailVerificationRequired => _emailVerificationRequired;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  int get unreadInboxCount => _unreadInboxCount;
  bool get hasUnreadInbox => _unreadInboxCount > 0;
  bool get supportsInbox =>
      _currentProfile != null && _supportsInbox(_currentProfile!.type);

  bool _isConnectionError(Object error) {
    return ApiClient.isConnectionError(error);
  }

  bool _isMissingProSessionError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('requires a pro account session') ||
        message.contains('pro account session');
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

  ProProfile _profileFromApi(Map<String, dynamic> json) {
    final profile = ProProfile.fromJson(json);
    return profile.copyWith(
      activeModules: ProModuleHelper.sanitizeModules(
        profile.type,
        profile.activeModules,
      ),
    );
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    // Set up banned callback to handle banned users during API calls
    ApiClient.setBannedCallback(_handleBanned);

    try {
      await ApiClient.configureSessionScope(ApiSessionScope.pro);
      await _restoreLocalSession();
      final token = await AppPreferences.getProAuthToken();

      if (token == null || token.isEmpty) {
        await _clearLocalSession(clearToken: false);
      } else {
        try {
          await refreshSession();
        } catch (error) {
          // Don't clear session for banned users - they should stay logged in but blocked
          if (!_isConnectionError(error) && !_isBannedError(error)) {
            await _clearLocalSession(clearToken: true);
            rethrow;
          }
        }
      }
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  bool _isBannedError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('account has been suspended') ||
        message.contains('banned');
  }

  Future<void> refreshSession() async {
    final response = Map<String, dynamic>.from(
      await ApiClient.get('/pro-auth/me', forceRefresh: true) as Map,
    );

    // Check if account is banned - keep session but mark as banned
    if (response['banned'] == true) {
      final reason =
          response['banReason'] as String? ??
          'Your account has been suspended.';
      _currentAccount = response['account'] is Map
          ? ProAccount.fromJson(Map<String, dynamic>.from(response['account']))
          : _currentAccount?.copyWith(isBanned: true, banReason: reason);
      _currentProfile = null;
      await _persistLocalSession();
      return;
    }

    await _applySessionResponse(response);
  }

  void _handleBanned(String? banReason) {
    final reason = banReason ?? 'Your account has been suspended.';
    if (_currentAccount != null) {
      _currentAccount = _currentAccount!.copyWith(
        isBanned: true,
        banReason: reason,
      );
    }
    _currentProfile = null;
    _persistLocalSession();
    notifyListeners();
  }

  Future<void> registerAccount({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/pro-auth/register', {
              'fullName': fullName.trim(),
              'email': email.trim(),
              'phone': phone.trim(),
              'password': password,
            })
            as Map,
      );
      if (response['requiresEmailVerification'] == true) {
        _emailVerificationRequired = true;
        _pendingVerificationEmail = response['email']?.toString();
        await _clearLocalSession(clearToken: true);
        return;
      }
      _emailVerificationRequired = false;
      _pendingVerificationEmail = null;
      await _applySessionResponse(response);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/pro-auth/login', {
              'email': email.trim(),
              'password': password,
            })
            as Map,
      );

      // Check if account is banned
      if (response['banned'] == true) {
        _emailVerificationRequired = false;
        _pendingVerificationEmail = null;
        _currentAccount = null;
        _currentProfile = null;
        await _clearLocalSession(clearToken: true);
        throw Exception(
          response['banReason'] as String? ??
              'Your account has been suspended.',
        );
      }

      _emailVerificationRequired = false;
      _pendingVerificationEmail = null;
      await _applySessionResponse(response);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeProfile({
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
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/pro-auth/profile', {
              'type': _typeToApi(type),
              'activeModules': normalizedModules.map(_moduleToApi).toList(),
              'businessName': businessName.trim(),
            })
            as Map,
      );
      await _applySessionResponse(response);
      await refreshInboxSummary();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile(String unusedUserId) async {
    if (unusedUserId.isEmpty && _currentProfile == null) {
      return;
    }
    try {
      await refreshSession();
    } catch (error) {
      if (_isConnectionError(error)) {
        return;
      }
      if (_isMissingProSessionError(error)) {
        await _clearLocalSession(clearToken: true);
        notifyListeners();
        return;
      }
      await _clearLocalSession(clearToken: true);
      notifyListeners();
    }
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
      await _persistLocalSession();
      notifyListeners();
    } catch (error) {
      if (_isConnectionError(error)) {
        await _persistLocalSession();
        return;
      }
      _currentProfile = previous;
      notifyListeners();
      rethrow;
    }
  }

  // After signup the set of active modules is immutable. The `activeModules`
  // argument is retained for backward compatibility but is ignored – the
  // provider will always persist the modules that are already stored in the
  // current profile.
  Future<void> updateProfileSettings({
    required String businessName,
    required List<ProModule> activeModules,
  }) async {
    final profile = _currentProfile;
    if (profile == null) {
      throw Exception('No active pro profile found.');
    }

    final normalizedName = businessName.trim();
    if (normalizedName.length < 2) {
      throw Exception('Business name must be at least 2 characters.');
    }

    // Use the modules from the existing profile to prevent changes.
    final List<ProModule> modulesToPersist = profile.activeModules;
    final normalizedModules = ProModuleHelper.sanitizeModules(
      profile.type,
      modulesToPersist,
    );

    final response = Map<String, dynamic>.from(
      await ApiClient.post('/pro', {
            'userId': profile.userId,
            'type': _typeToApi(profile.type),
            'activeModules': normalizedModules.map(_moduleToApi).toList(),
            'businessName': normalizedName,
            'avatarUrl': profile.avatarUrl ?? '',
            'isOnline': profile.isOnline,
            'isVerified': profile.isVerified,
          })
          as Map,
    );

    _currentProfile = _profileFromApi(response);
    await _persistLocalSession();
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearLocalSession(clearToken: true);
    notifyListeners();
  }

  Future<void> _applySessionResponse(Map<String, dynamic> response) async {
    final token = response['token'] as String?;
    if (token != null && token.isNotEmpty) {
      await ApiClient.setToken(token);
    }

    final rawAccount = response['account'];
    final rawProfile = response['profile'];

    _currentAccount = rawAccount is Map
        ? ProAccount.fromJson(Map<String, dynamic>.from(rawAccount))
        : null;
    _currentProfile = rawProfile is Map
        ? _profileFromApi(Map<String, dynamic>.from(rawProfile))
        : null;

    await _persistLocalSession();
  }

  Future<void> _persistLocalSession() async {
    if (_currentAccount != null) {
      await AppPreferences.setProAccountJson(
        jsonEncode(_currentAccount!.toJson()),
      );
    } else {
      await AppPreferences.clearProAccountJson();
    }

    if (_currentProfile != null) {
      await AppPreferences.setProProfileJson(
        jsonEncode(_currentProfile!.toJson()),
      );
    } else {
      await AppPreferences.clearProProfileJson();
    }
  }

  Future<void> _restoreLocalSession() async {
    final rawAccount = await AppPreferences.getProAccountJson();
    if (rawAccount != null && rawAccount.isNotEmpty) {
      _currentAccount = ProAccount.fromJson(
        Map<String, dynamic>.from(jsonDecode(rawAccount) as Map),
      );
    }

    final rawProfile = await AppPreferences.getProProfileJson();
    if (rawProfile != null && rawProfile.isNotEmpty) {
      final cachedProfile = ProProfile.fromJson(
        Map<String, dynamic>.from(jsonDecode(rawProfile) as Map),
      );
      _currentProfile = cachedProfile.copyWith(
        activeModules: ProModuleHelper.sanitizeModules(
          cachedProfile.type,
          cachedProfile.activeModules,
        ),
      );
    }
  }

  Future<void> _clearLocalSession({required bool clearToken}) async {
    _currentAccount = null;
    _currentProfile = null;
    _emailVerificationRequired = false;
    _pendingVerificationEmail = null;
    _unreadInboxCount = 0;
    await AppPreferences.clearProAccountJson();
    await AppPreferences.clearProProfileJson();
    if (clearToken) {
      await ApiClient.setToken(null);
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
      case ProModule.ecologicalCleaning:
        return 'ECOLOGICAL_CLEANING';
    }
  }
}
