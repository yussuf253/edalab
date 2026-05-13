import '../models/app_notification_model.dart';

class NotificationService {
  NotificationService._();

  static AppNotificationModel orderPlaced({
    required String title,
    required String body,
    required NotificationModule module,
    required String route,
    String? orderId,
    String? dedupeKey,
    NotificationPriority priority = NotificationPriority.high,
    Map<String, dynamic> metadata = const {},
  }) {
    return _build(
      title: title,
      body: body,
      module: module,
      route: route,
      priority: priority,
      dedupeKey: dedupeKey ?? 'order:$orderId:$route',
      metadata: {
        ...?orderId == null ? null : {'orderId': orderId},
        ...metadata,
      },
    );
  }

  static AppNotificationModel rideConfirmed({
    required String title,
    required String body,
    required String route,
    String? rideId,
    Map<String, dynamic> metadata = const {},
  }) {
    return _build(
      title: title,
      body: body,
      module: NotificationModule.ride,
      route: route,
      priority: NotificationPriority.high,
      dedupeKey: 'ride:$rideId:$route',
      metadata: {
        ...?rideId == null ? null : {'rideId': rideId},
        ...metadata,
      },
    );
  }

  static AppNotificationModel appointmentBooked({
    required String title,
    required String body,
    required String route,
    String? appointmentId,
    Map<String, dynamic> metadata = const {},
  }) {
    return _build(
      title: title,
      body: body,
      module: NotificationModule.doctor,
      route: route,
      priority: NotificationPriority.high,
      dedupeKey: 'appointment:$appointmentId:$route',
      metadata: {
        ...?appointmentId == null ? null : {'appointmentId': appointmentId},
        ...metadata,
      },
    );
  }

  static AppNotificationModel promotion({
    required String title,
    required String body,
    String route = '/promotions',
    String? promoCode,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    return _build(
      title: title,
      body: body,
      module: NotificationModule.promotions,
      route: route,
      priority: priority,
      dedupeKey: 'promo:${promoCode ?? title}',
      metadata: {
        ...?promoCode == null ? null : {'promoCode': promoCode},
      },
    );
  }

  static AppNotificationModel reminder({
    required String title,
    required String body,
    required NotificationModule module,
    String? route,
    String? dedupeKey,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic> metadata = const {},
  }) {
    return _build(
      title: title,
      body: body,
      module: module,
      route: route,
      priority: priority,
      dedupeKey: dedupeKey,
      metadata: metadata,
    );
  }

  static AppNotificationModel account({
    required String title,
    required String body,
    String route = '/profile/settings',
    String? dedupeKey,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    return _build(
      title: title,
      body: body,
      module: NotificationModule.account,
      route: route,
      priority: priority,
      dedupeKey: dedupeKey,
    );
  }

  static AppNotificationModel _build({
    required String title,
    required String body,
    required NotificationModule module,
    NotificationPriority priority = NotificationPriority.normal,
    String? route,
    String? dedupeKey,
    Map<String, dynamic> metadata = const {},
  }) {
    return AppNotificationModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      module: module,
      createdAt: DateTime.now(),
      priority: priority,
      route: route,
      dedupeKey: dedupeKey,
      metadata: metadata,
    );
  }
}
