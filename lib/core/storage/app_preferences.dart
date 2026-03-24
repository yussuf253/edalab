import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static const _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const _currentUserIdKey = 'current_user_id';
  static const _authTokenKey = 'auth_token';
  static const _cartItemsKey = 'cart_items';
  static const _cartPromoCodeKey = 'cart_promo_code';
  static const _cartPromoDiscountKey = 'cart_promo_discount';

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
}
