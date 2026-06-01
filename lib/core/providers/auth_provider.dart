import 'package:flutter/material.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../localization/app_localizations.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../storage/app_preferences.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _emailVerificationRequired = false;
  String? _pendingVerificationEmail;

  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get emailVerificationRequired => _emailVerificationRequired;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  bool _isConnectionError(Object error) {
    return ApiClient.isConnectionError(error);
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  void _setOfflineSession(String userId) {
    _user = UserModel(
      id: userId,
      firstName: 'User',
      lastName: '',
      email: '',
      phone: '',
    );
    _isLoggedIn = true;
  }

  Future<void> _setUserFromResponse(Map<String, dynamic> response) async {
    _user = await _userFromResponse(response);
    _isLoggedIn = true;
    _syncAnalyticsIdentity();
  }

  void _syncAnalyticsIdentity() {
    final user = _user;
    AnalyticsService.instance.setUserId(_isLoggedIn ? user?.id : null);
    AnalyticsService.instance.setUserProperties({
      'is_logged_in': _isLoggedIn,
      'address_count': user?.addresses.length ?? 0,
      'has_saved_address': (user?.addresses.isNotEmpty ?? false),
    });
  }

  String _analyticsSafeError(Object error) {
    final message = ApiClient.userFacingError(error).trim();
    if (message.isEmpty) return 'unknown';
    return message.length > 120 ? '${message.substring(0, 120)}...' : message;
  }

  Future<void> _persistSession({required String userId, String? token}) async {
    await AppPreferences.setCurrentUserId(userId);
    if (token != null && token.isNotEmpty) {
      await ApiClient.setToken(token);
    }
  }

  Future<UserModel> _userFromResponse(Map<String, dynamic> response) async {
    final name = (response['name'] as String? ?? '').trim();
    final parts = name.isEmpty ? ['User'] : name.split(RegExp(r'\s+'));
    final rawAddresses = response['addresses'] as List<dynamic>? ?? const [];
    final l10n = await _storedL10n();

    return UserModel(
      id: response['id'] as String,
      firstName: parts.first,
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      email: response['email'] as String? ?? '',
      phone: response['phone'] as String? ?? '',
      avatarUrl: ApiClient.normalizePublicUrl(response['avatarUrl'] as String?),
      addresses: [
        ...rawAddresses.map((entry) {
          final address = Map<String, dynamic>.from(entry as Map);
          return AddressModel(
            id: address['id'] as String,
            label: address['label'] as String? ?? l10n.t('addresses.label'),
            address: address['address'] as String? ?? '',
            city: address['city'] as String?,
            quartier: _firstNonEmptyString([
              address['quartier'],
              address['district'],
              address['neighborhood'],
              address['neighbourhood'],
              address['suburb'],
              address['quarter'],
            ]),
            zipCode: address['zipCode'] as String?,
            latitude: (address['latitude'] as num?)?.toDouble(),
            longitude: (address['longitude'] as num?)?.toDouble(),
            isDefault: address['isDefault'] as bool? ?? false,
          );
        }),
        if (rawAddresses.isEmpty &&
            (response['address'] as String?)?.isNotEmpty == true)
          AddressModel(
            id: 'primary_address',
            label: l10n.t('addresses.default'),
            address: response['address'] as String,
            isDefault: true,
          ),
      ],
    );
  }

  Future<AppLocalizations> _storedL10n() async {
    final localeCode = await AppPreferences.getLocaleCode();
    return AppLocalizations(
      Locale(localeCode ?? AppLocalizations.fallbackLocale.languageCode),
    );
  }

  Future<bool> login(String email, String password) async {
    AnalyticsService.instance.track(
      AnalyticsEvents.authLoginAttempted,
      properties: {'auth_method': 'password'},
    );
    _isLoading = true;
    _errorMessage = null;
    _emailVerificationRequired = false;
    _pendingVerificationEmail = null;
    notifyListeners();

    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/auth/login', {
              'email': email.trim(),
              'password': password,
            })
            as Map,
      );

      final userResponse = Map<String, dynamic>.from(response['user'] as Map);
      await _setUserFromResponse(userResponse);
      await _persistSession(
        userId: _user!.id,
        token: response['token'] as String?,
      );
      AnalyticsService.instance.track(
        AnalyticsEvents.authLoginSucceeded,
        properties: {'auth_method': 'password'},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.authLoginFailed,
        properties: {
          'auth_method': 'password',
          'error': _analyticsSafeError(e),
        },
      );
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      _user = null;
      _isLoggedIn = false;
      _syncAnalyticsIdentity();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    AnalyticsService.instance.track(
      AnalyticsEvents.authRegisterAttempted,
      properties: {'auth_method': 'password'},
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/auth/register', {
              'name': name.trim(),
              'email': email.trim(),
              'phone': phone.trim(),
              'password': password,
            })
            as Map,
      );

      if (response['requiresEmailVerification'] == true) {
        _emailVerificationRequired = true;
        _pendingVerificationEmail = response['email']?.toString();
        _errorMessage =
            'Check your email to verify your account before signing in.';
        _isLoading = false;
        _user = null;
        _isLoggedIn = false;
        _syncAnalyticsIdentity();
        notifyListeners();
        return false;
      }

      final userResponse = Map<String, dynamic>.from(response['user'] as Map);
      await _setUserFromResponse(userResponse);
      await _persistSession(
        userId: _user!.id,
        token: response['token'] as String?,
      );
      AnalyticsService.instance.track(
        AnalyticsEvents.authRegisterSucceeded,
        properties: {'auth_method': 'password'},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.authRegisterFailed,
        properties: {
          'auth_method': 'password',
          'error': _analyticsSafeError(e),
        },
      );
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      _user = null;
      _isLoggedIn = false;
      _syncAnalyticsIdentity();
      notifyListeners();
      return false;
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    String? userId;
    try {
      await ApiClient.initialize();
      userId = await AppPreferences.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        _user = null;
        _isLoggedIn = false;
        _errorMessage = null;
        return;
      }

      final response = await ApiClient.get('/users/$userId');
      await _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      AnalyticsService.instance.track(
        AnalyticsEvents.authSessionRestored,
        properties: {'source': 'stored_session'},
      );
      _errorMessage = null;
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.authSessionRestoreFailed,
        properties: {'error': _analyticsSafeError(e)},
      );
      _errorMessage = ApiClient.userFacingError(e);
      if (userId != null && userId.isNotEmpty && _isConnectionError(e)) {
        _setOfflineSession(userId);
        _syncAnalyticsIdentity();
      } else {
        _user = null;
        _isLoggedIn = false;
        _syncAnalyticsIdentity();
        await AppPreferences.clearCurrentUserId();
        await ApiClient.setToken(null);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? avatarUrl,
  }) async {
    if (_user == null) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fullName = [
        firstName.trim(),
        lastName.trim(),
      ].where((part) => part.isNotEmpty).join(' ').trim();

      final response = await ApiClient.patch('/users/${_user!.id}', {
        'name': fullName,
        'email': email.trim(),
        'phone': phone.trim(),
        'avatarUrl': ApiClient.normalizePublicUrl(avatarUrl) ?? '',
      });

      await _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      AnalyticsService.instance.track(
        AnalyticsEvents.profileUpdated,
        properties: {'has_avatar': (avatarUrl?.trim().isNotEmpty ?? false)},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.profileUpdateFailed,
        properties: {'error': _analyticsSafeError(e)},
      );
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addAddress({
    required String label,
    required String address,
    String? city,
    String? quartier,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    if (_user == null) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post('/users/${_user!.id}/addresses', {
        'label': label.trim(),
        'address': address.trim(),
        'city': city?.trim() ?? '',
        'quartier': quartier?.trim() ?? '',
        'zipCode': '',
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      });

      await _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      AnalyticsService.instance.track(
        AnalyticsEvents.addressAdded,
        properties: {'is_default': isDefault},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.addressAddFailed,
        properties: {'error': _analyticsSafeError(e)},
      );
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAddress({
    required String addressId,
    required String label,
    required String address,
    String? city,
    String? quartier,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    if (_user == null) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response =
          await ApiClient.patch('/users/${_user!.id}/addresses/$addressId', {
            'label': label.trim(),
            'address': address.trim(),
            'city': city?.trim() ?? '',
            'quartier': quartier?.trim() ?? '',
            'zipCode': '',
            'latitude': latitude,
            'longitude': longitude,
            'isDefault': isDefault,
          });

      await _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      AnalyticsService.instance.track(
        AnalyticsEvents.addressUpdated,
        properties: {'is_default': isDefault},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.addressUpdateFailed,
        properties: {'error': _analyticsSafeError(e)},
      );
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    if (_user == null) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.patch(
        '/users/${_user!.id}/addresses/$addressId/default',
        {},
      );
      await _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      AnalyticsService.instance.track(
        AnalyticsEvents.addressDefaultSet,
        properties: {'address_id': addressId},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.addressDefaultSetFailed,
        properties: {'error': _analyticsSafeError(e)},
      );
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    if (_user == null) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.delete(
        '/users/${_user!.id}/addresses/$addressId',
      );
      if (response is Map) {
        await _setUserFromResponse(Map<String, dynamic>.from(response));
      }
      AnalyticsService.instance.track(
        AnalyticsEvents.addressDeleted,
        properties: {'address_id': addressId},
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.addressDeleteFailed,
        properties: {'error': _analyticsSafeError(e)},
      );
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    AnalyticsService.instance.track(AnalyticsEvents.authLoggedOut);
    _user = null;
    _isLoggedIn = false;
    _errorMessage = null;
    _syncAnalyticsIdentity();
    await AppPreferences.clearCurrentUserId();
    await ApiClient.setToken(null);
    notifyListeners();
  }
}
