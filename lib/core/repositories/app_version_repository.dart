import 'package:edalab/core/models/app_version_model.dart';
import 'package:edalab/core/network/api_client.dart';

/// Repository for managing app version checks from the database
class AppVersionRepository {
  /// Fetch the latest version info from the backend
  /// This includes current app version, latest version, and update requirements
  static Future<AppVersionModel> checkForUpdates() async {
    try {
      final response = await ApiClient.get(
        '/version/check',
        forceRefresh: true,
      );

      if (response is Map<String, dynamic>) {
        return AppVersionModel.fromJson(response);
      }
      throw Exception('Invalid version info format');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch version info by platform (android, ios)
  /// Optional: pass specific platform if needed
  static Future<AppVersionModel> checkForUpdatesByPlatform(
    String platform,
  ) async {
    try {
      final response = await ApiClient.get(
        '/version/check?platform=$platform',
        forceRefresh: true,
      );

      if (response is Map<String, dynamic>) {
        return AppVersionModel.fromJson(response);
      }
      throw Exception('Invalid version info format for $platform');
    } catch (e) {
      rethrow;
    }
  }

  /// Report user action (update skipped, updated, etc.)
  static Future<void> reportUpdateAction(
    String action,
    String currentVersion,
  ) async {
    try {
      await ApiClient.post('/version/report-action', {
        'action': action, // 'skipped', 'updated', 'forced_update', etc.
        'currentVersion': currentVersion,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log but don't throw - this is a non-critical operation
      print('Failed to report update action: $e');
    }
  }
}
