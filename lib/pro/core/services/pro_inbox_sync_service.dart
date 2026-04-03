import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/models/app_notification_model.dart';
import '../../../core/providers/notification_provider.dart';
import '../providers/pro_auth_provider.dart';

class ProInboxSyncService with WidgetsBindingObserver {
  ProInboxSyncService._();

  static final ProInboxSyncService instance = ProInboxSyncService._();

  NotificationProvider? _notificationProvider;
  ProAuthProvider? _proAuthProvider;
  bool _started = false;
  Set<String> _seenNotificationIds = const <String>{};
  Timer? _refreshDebounce;

  void start({
    required NotificationProvider notificationProvider,
    required ProAuthProvider proAuthProvider,
  }) {
    _notificationProvider = notificationProvider;
    _proAuthProvider = proAuthProvider;
    _seenNotificationIds = notificationProvider.notifications
        .map((item) => item.id)
        .toSet();

    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    notificationProvider.addListener(_handleNotificationsChanged);
    proAuthProvider.addListener(_handleProStateChanged);
  }

  void updateProviders({
    required NotificationProvider notificationProvider,
    required ProAuthProvider proAuthProvider,
  }) {
    if (!identical(_notificationProvider, notificationProvider)) {
      _notificationProvider?.removeListener(_handleNotificationsChanged);
      _notificationProvider = notificationProvider;
      _seenNotificationIds = notificationProvider.notifications
          .map((item) => item.id)
          .toSet();
      if (_started) {
        notificationProvider.addListener(_handleNotificationsChanged);
      }
    }

    if (!identical(_proAuthProvider, proAuthProvider)) {
      _proAuthProvider?.removeListener(_handleProStateChanged);
      _proAuthProvider = proAuthProvider;
      if (_started) {
        proAuthProvider.addListener(_handleProStateChanged);
      }
    }
  }

  void stop() {
    _refreshDebounce?.cancel();
    _notificationProvider?.removeListener(_handleNotificationsChanged);
    _proAuthProvider?.removeListener(_handleProStateChanged);
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      _started = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleRefresh();
    }
  }

  void _handleNotificationsChanged() {
    final provider = _notificationProvider;
    if (provider == null) return;

    final notifications = provider.notifications;
    final currentIds = notifications.map((item) => item.id).toSet();
    final hasNewMessageNotification = notifications.any(
      (notification) =>
          !_seenNotificationIds.contains(notification.id) &&
          _isMessageNotification(notification),
    );
    _seenNotificationIds = currentIds;

    if (hasNewMessageNotification) {
      _scheduleRefresh();
    }
  }

  void _handleProStateChanged() {
    _scheduleRefresh();
  }

  bool _isMessageNotification(AppNotificationModel notification) {
    final kind = notification.metadata['kind']?.toString().trim().toLowerCase();
    final route = notification.route?.trim() ?? '';
    return notification.module == NotificationModule.messages ||
        kind == 'message' ||
        route.startsWith('/pro/messages/chat/') ||
        route.startsWith('/messages/chat/');
  }

  void _scheduleRefresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 350), () {
      final proAuth = _proAuthProvider;
      if (proAuth == null || !proAuth.supportsInbox) return;
      unawaited(proAuth.refreshInboxSummary(forceRefresh: true));
    });
  }
}
