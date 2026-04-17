import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';
import '../storage/app_preferences.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

  void _setUserFromResponse(Map<String, dynamic> response) {
    _user = _userFromResponse(response);
    _isLoggedIn = true;
  }

  Future<void> _persistSession({required String userId, String? token}) async {
    await AppPreferences.setCurrentUserId(userId);
    if (token != null && token.isNotEmpty) {
      await ApiClient.setToken(token);
    }
  }

  UserModel _userFromResponse(Map<String, dynamic> response) {
    final name = (response['name'] as String? ?? '').trim();
    final parts = name.isEmpty ? ['User'] : name.split(RegExp(r'\s+'));
    final rawAddresses = response['addresses'] as List<dynamic>? ?? const [];

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
            label: address['label'] as String? ?? 'Address',
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
            label: 'Primary',
            address: response['address'] as String,
            isDefault: true,
          ),
      ],
    );
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
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
      _setUserFromResponse(userResponse);
      await _persistSession(
        userId: _user!.id,
        token: response['token'] as String?,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      _user = null;
      _isLoggedIn = false;
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

      final userResponse = Map<String, dynamic>.from(response['user'] as Map);
      _setUserFromResponse(userResponse);
      await _persistSession(
        userId: _user!.id,
        token: response['token'] as String?,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      _user = null;
      _isLoggedIn = false;
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
      _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      _errorMessage = null;
    } catch (e) {
      _errorMessage = ApiClient.userFacingError(e);
      if (userId != null && userId.isNotEmpty && _isConnectionError(e)) {
        _setOfflineSession(userId);
      } else {
        _user = null;
        _isLoggedIn = false;
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

      _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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

      _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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

      _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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
      _setUserFromResponse(Map<String, dynamic>.from(response as Map));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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
        _setUserFromResponse(Map<String, dynamic>.from(response));
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ApiClient.userFacingError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    _errorMessage = null;
    await AppPreferences.clearCurrentUserId();
    await ApiClient.setToken(null);
    notifyListeners();
  }
}
