import 'package:url_launcher/url_launcher.dart';

/// Utility class for handling app store URLs and opening them
class AppStoreUtil {
  /// Open app in Google Play Store
  static Future<void> openPlayStore(String packageName) async {
    final url = 'https://play.google.com/store/apps/details?id=$packageName';
    await _launchUrl(url);
  }

  /// Open app in Apple App Store
  static Future<void> openAppStore(String appId) async {
    final url = 'https://apps.apple.com/app/id$appId';
    await _launchUrl(url);
  }

  /// Open a custom store URL
  static Future<void> openCustomUrl(String url) async {
    await _launchUrl(url);
  }

  /// Internal method to launch URLs
  static Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      print('Error launching URL: $e');
      rethrow;
    }
  }

  /// Get Play Store package name for the app
  /// This should be configured based on your app's package name
  static String getPlayStorePackageName() {
    // Configure this based on your app's package name
    // Example: 'com.example.edalab'
    return 'com.edalab'; // Replace with your actual package name
  }

  /// Get App Store app ID for the app
  /// This should be configured based on your app's App Store ID
  static String getAppStoreId() {
    // Configure this based on your app's App Store ID
    // Example: '1234567890'
    return ''; // Replace with your actual App Store ID
  }
}
