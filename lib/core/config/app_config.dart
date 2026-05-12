class AppConfig {
  static const String appName = 'eDalab';
  // Use the actual backend URL from Render
  static const String baseUrl = 'https://edalab.onrender.com';

  // Payment URLs for web view - these should point to our backend
  static String getPaymentSuccessUrl(String orderId) {
    return '$baseUrl/payment/success?orderId=$orderId';
  }

  static String getPaymentFailureUrl(String message) {
    return '$baseUrl/payment/failed?message=${Uri.encodeComponent(message)}';
  }
}
