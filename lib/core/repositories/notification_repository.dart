import '../models/app_notification_model.dart';
import '../network/api_client.dart';

class NotificationRepository {
  const NotificationRepository();

  static final RegExp _localGeneratedIdPattern = RegExp(r'^\d+$');

  Future<List<AppNotificationModel>> fetchForUser(String userId) async {
    try {
      final response = await ApiClient.get(
        '/notifications/$userId',
        forceRefresh: true,
      );
      final items = response is List ? response : const [];
      return items
          .map(
            (item) => AppNotificationModel.fromApi(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> create({
    required String userId,
    required AppNotificationModel notification,
  }) async {
    try {
      await ApiClient.post(
        '/notifications',
        notification.toApiJson(userId: userId),
      );
    } catch (_) {}
  }

  Future<void> markRead(String notificationId) async {
    // Locally generated inbox items (e.g. welcome reminders) use numeric
    // microsecond IDs and do not exist in backend storage.
    if (_localGeneratedIdPattern.hasMatch(notificationId)) {
      return;
    }

    try {
      await ApiClient.patch('/notifications/$notificationId/read', {});
    } catch (_) {}
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    for (final id in ids) {
      await markRead(id);
    }
  }

  Future<void> registerPushToken({
    required String userId,
    required String token,
    String platform = 'unknown',
  }) async {
    try {
      await ApiClient.post('/notifications/device-tokens', {
        'userId': userId,
        'token': token,
        'platform': platform,
      });
    } catch (_) {}
  }
}
