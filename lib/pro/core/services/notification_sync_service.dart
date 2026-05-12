import 'dart:async';

import 'package:flutter/widgets.dart';

import '../providers/notification_provider.dart';
import 'push_notification_service.dart';

class NotificationSyncService with WidgetsBindingObserver {
  NotificationSyncService._();

  static final NotificationSyncService instance = NotificationSyncService._();

  NotificationProvider? _provider;
  Timer? _timer;
  bool _started = false;

  void start(NotificationProvider provider) {
    _provider = provider;
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => _sync(showAlerts: true),
    );
  }

  void updateProvider(NotificationProvider provider) {
    _provider = provider;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      _started = false;
    }
  }

  Future<void> syncNow({bool showAlerts = false}) {
    return _sync(showAlerts: showAlerts);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sync(showAlerts: false);
    }
  }

  Future<void> _sync({required bool showAlerts}) async {
    final provider = _provider;
    final userId = provider?.currentUserId;
    if (provider == null || userId == null || userId.isEmpty) return;

    final added = await provider.refreshFromServer(userId);
    if (!showAlerts || added.isEmpty) return;

    for (final notification in added.take(3)) {
      await PushNotificationService.showSyncedNotification(notification);
    }
  }
}
