import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/app_notification_model.dart';
import '../providers/notification_provider.dart';
import '../router/app_router.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushNotificationService {
  PushNotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static NotificationProvider? _provider;
  static bool _firebaseReady = false;
  static bool _localReady = false;
  static String? _token;

  static String? get token => _token;

  static Future<void> initialize() async {
    _firebaseReady = await _initializeFirebase();
    if (!_firebaseReady) {
      debugPrint('PushNotificationService: Firebase is not configured yet.');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermission();
    await _configureForegroundPresentation();
    await _captureToken();
    _listenForTokenRefresh();
    _listenForMessages();
  }

  static void bindProvider(NotificationProvider provider) {
    _provider = provider;
  }

  static Future<bool> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } catch (error) {
      debugPrint('PushNotificationService: Firebase init skipped: $error');
      return false;
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    if (_localReady) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        openAppRoute(payload);
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'edalab_high_priority',
      'EdaLab Updates',
      description: 'Important order, booking, and ride updates.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _localReady = true;
  }

  static Future<void> _requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  static Future<void> _configureForegroundPresentation() async {
    if (!Platform.isIOS && !Platform.isMacOS) return;
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _captureToken() async {
    try {
      _token = await FirebaseMessaging.instance.getToken();
      debugPrint('PushNotificationService: FCM token $_token');
    } catch (error) {
      debugPrint('PushNotificationService: token read failed: $error');
    }
  }

  static void _listenForTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _token = token;
      debugPrint('PushNotificationService: FCM token refreshed.');
      _provider?.syncPushToken(token);
    });
  }

  static void _listenForMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = _mapRemoteMessage(message);
      if (notification == null) return;

      await _provider?.addNotification(notification, allowDuplicate: false);
      await _showLocalNotification(notification);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      final notification = _mapRemoteMessage(message);
      if (notification == null) return;
      await _provider?.addNotification(notification, allowDuplicate: false);
      if (notification.route != null) {
        openAppRoute(notification.route!);
      }
    });
  }

  static Future<void> syncInitialMessage() async {
    if (!_firebaseReady) return;
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    final notification = initialMessage == null
        ? null
        : _mapRemoteMessage(initialMessage);
    if (notification == null) return;
    await _provider?.addNotification(notification, allowDuplicate: false);
    if (notification.route != null) {
      openAppRoute(notification.route!);
    }
  }

  static AppNotificationModel? _mapRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final title =
        message.notification?.title ??
        data['title']?.toString() ??
        'EdaLab update';
    final body =
        message.notification?.body ??
        data['body']?.toString() ??
        'You have a new update.';
    final route = data['route']?.toString();
    final module = _moduleFromRaw(data['module']?.toString());
    final priority = _priorityFromRaw(data['priority']?.toString());
    final dedupeKey = data['dedupeKey']?.toString() ?? message.messageId;

    return NotificationService.reminder(
      title: title,
      body: body,
      module: module,
      route: route,
      priority: priority,
      dedupeKey: dedupeKey,
      metadata: {
        'remoteMessageId': message.messageId,
        ...data,
      },
    );
  }

  static NotificationModule _moduleFromRaw(String? raw) {
    return NotificationModule.values.firstWhere(
      (module) => module.name.toLowerCase() == (raw ?? '').toLowerCase(),
      orElse: () => NotificationModule.system,
    );
  }

  static NotificationPriority _priorityFromRaw(String? raw) {
    return NotificationPriority.values.firstWhere(
      (priority) => priority.name.toLowerCase() == (raw ?? '').toLowerCase(),
      orElse: () => NotificationPriority.normal,
    );
  }

  static Future<void> _showLocalNotification(
    AppNotificationModel notification,
  ) async {
    if (!_localReady) return;

    final androidDetails = AndroidNotificationDetails(
      'edalab_high_priority',
      'EdaLab Updates',
      channelDescription: 'Important order, booking, and ride updates.',
      importance: Importance.max,
      priority: Priority.high,
      color: notification.color,
    );
    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: notification.route,
    );
  }

  static Future<void> showSyncedNotification(
    AppNotificationModel notification,
  ) async {
    await _showLocalNotification(notification);
  }
}
