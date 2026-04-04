import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const _currentUserIdKey = 'current_user_id';
  static const _authTokenKey = 'auth_token';
  static const _proAuthTokenKey = 'pro_auth_token';
  static const _cartItemsKey = 'cart_items';
  static const _cartPromoCodeKey = 'cart_promo_code';
  static const _cartPromoDiscountKey = 'cart_promo_discount';
  static const _notificationsPrefsKey = 'notifications_preferences';
  static const _localeCodeKey = 'locale_code';
  static const _proProfileJsonKey = 'pro_profile_json';
  static const _proAccountJsonKey = 'pro_account_json';
  static const _hasSeenProOnboardingKey = 'has_seen_pro_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, value);
  }

  static Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserIdKey);
  }

  static Future<void> setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
  }

  static Future<void> clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_authTokenKey);
  }

  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTokenKey, token);
  }

  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authTokenKey);
  }

  static Future<String?> getProAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proAuthTokenKey);
  }

  static Future<void> setProAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_proAuthTokenKey, token);
  }

  static Future<void> clearProAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_proAuthTokenKey);
  }

  static Future<String?> getCartItemsJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cartItemsKey);
  }

  static Future<void> setCartItemsJson(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartItemsKey, value);
  }

  static Future<void> clearCartItemsJson() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartItemsKey);
  }

  static Future<String?> getCartPromoCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cartPromoCodeKey);
  }

  static Future<void> setCartPromoCode(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null || value.isEmpty) {
      await prefs.remove(_cartPromoCodeKey);
      return;
    }
    await prefs.setString(_cartPromoCodeKey, value);
  }

  static Future<double> getCartPromoDiscount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_cartPromoDiscountKey) ?? 0;
  }

  static Future<void> setCartPromoDiscount(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_cartPromoDiscountKey, value);
  }

  static Future<void> clearCartState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartItemsKey);
    await prefs.remove(_cartPromoCodeKey);
    await prefs.remove(_cartPromoDiscountKey);
  }

  static Future<String?> getNotificationsJson(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('notifications_$scope');
  }

  static Future<void> setNotificationsJson(String scope, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications_$scope', value);
  }

  static Future<String?> getNotificationsPreferencesJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_notificationsPrefsKey);
  }

  static Future<void> setNotificationsPreferencesJson(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsPrefsKey, value);
  }

  static Future<String?> getLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeCodeKey);
  }

  static Future<void> setLocaleCode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeCodeKey, value);
  }

  static Future<String?> getProProfileJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proProfileJsonKey);
  }

  static Future<void> setProProfileJson(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_proProfileJsonKey, value);
  }

  static Future<void> clearProProfileJson() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_proProfileJsonKey);
  }

  static Future<String?> getProAccountJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_proAccountJsonKey);
  }

  static Future<void> setProAccountJson(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_proAccountJsonKey, value);
  }

  static Future<void> clearProAccountJson() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_proAccountJsonKey);
  }

  static Future<bool> hasSeenProOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenProOnboardingKey) ?? false;
  }

  static Future<void> setHasSeenProOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenProOnboardingKey, value);
  }
}
