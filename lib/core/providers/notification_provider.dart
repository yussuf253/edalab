import 'package:flutter/foundation.dart';

import '../models/app_notification_model.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_service.dart';
import '../storage/app_preferences.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    NotificationRepository? repository,
  }) : _repository = repository ?? const NotificationRepository();

  final List<AppNotificationModel> _notifications = [];
  final NotificationRepository _repository;
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _isLoading = true;
  bool _isSyncing = false;
  String _scope = 'guest';
  String? _currentUserId;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  NotificationPreferences get preferences => _preferences;
  List<AppNotificationModel> get notifications {
    final items = List<AppNotificationModel>.from(_notifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(items);
  }
  int get unreadCount => _notifications.where((item) => !item.isRead).length;
  bool get hasUnread => unreadCount > 0;

  Future<void> initialize() async {
    _preferences = NotificationPreferences.decode(
      await AppPreferences.getNotificationsPreferencesJson(),
    );
    await _loadScope('guest');
  }

  Future<void> syncSession({
    required AuthProvider authProvider,
    required CartProvider cartProvider,
  }) async {
    final nextUserId = authProvider.user?.id;
    final nextScope = nextUserId == null ? 'guest' : 'user_$nextUserId';
    _currentUserId = nextUserId;

    if (_scope != nextScope) {
      await _loadScope(nextScope);
    }

    if (nextUserId != null) {
      await refreshFromServer(nextUserId);
    }

    await _seedSmartNotifications(
      authProvider: authProvider,
      cartProvider: cartProvider,
    );
  }

  Future<void> addNotification(
    AppNotificationModel notification, {
    bool allowDuplicate = false,
    bool persistRemote = false,
  }) async {
    if (!_shouldAccept(notification, allowDuplicate: allowDuplicate)) {
      return;
    }

    _notifications.insert(0, notification);
    await _persist();
    final userId = _currentUserId;
    if (persistRemote && userId != null) {
      await _repository.create(userId: userId, notification: notification);
    }
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || _notifications[index].isRead) return;
    _notifications[index] = _notifications[index].copyWith(readAt: DateTime.now());
    await _persist();
    final remoteId = _notifications[index].id;
    if (remoteId.isNotEmpty) {
      await _repository.markRead(remoteId);
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    var changed = false;
    final ids = <String>[];
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].isRead) continue;
      _notifications[i] = _notifications[i].copyWith(readAt: DateTime.now());
      ids.add(_notifications[i].id);
      changed = true;
    }
    if (!changed) return;
    await _persist();
    await _repository.markAllRead(ids);
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> setPushEnabled(bool value) async {
    _preferences = _preferences.copyWith(pushEnabled: value);
    await _persistPreferences();
    notifyListeners();
  }

  Future<void> setEmailEnabled(bool value) async {
    _preferences = _preferences.copyWith(emailEnabled: value);
    await _persistPreferences();
    notifyListeners();
  }

  Future<void> setPromotionsEnabled(bool value) async {
    _preferences = _preferences.copyWith(promotionsEnabled: value);
    await _persistPreferences();
    notifyListeners();
  }

  Future<void> setLocationAlertsEnabled(bool value) async {
    _preferences = _preferences.copyWith(locationAlertsEnabled: value);
    await _persistPreferences();
    notifyListeners();
  }

  Future<void> _loadScope(String scope) async {
    _scope = scope;
    _isLoading = true;
    notifyListeners();
    final raw = await AppPreferences.getNotificationsJson(scope);
    _notifications
      ..clear()
      ..addAll(
        raw == null || raw.isEmpty ? _defaultInbox() : AppNotificationModel.decodeList(raw),
      );
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    await _persist();
    notifyListeners();
  }

  Future<void> refreshFromServer(String userId) async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();
    try {
      final remoteItems = await _repository.fetchForUser(userId);
      if (remoteItems.isNotEmpty) {
        _mergeNotifications(remoteItems);
        await _persist();
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncPushToken(String token) async {
    final userId = _currentUserId;
    if (userId == null || token.isEmpty) return;
    final platform = kIsWeb
        ? 'web'
        : defaultTargetPlatform.name.toLowerCase();
    await _repository.registerPushToken(
      userId: userId,
      token: token,
      platform: platform,
    );
  }

  Future<void> _seedSmartNotifications({
    required AuthProvider authProvider,
    required CartProvider cartProvider,
  }) async {
    if (!_preferences.pushEnabled) return;

    final user = authProvider.user;
    final cartItems = cartProvider.itemCount;
    final hasAddress = (user?.addresses ?? const []).isNotEmpty;

    if (_notifications.isEmpty) {
      await addNotification(
        NotificationService.reminder(
          title: 'Your activity updates live here',
          body: 'Orders, bookings, rides, promos, and account nudges will appear in one smart inbox.',
          module: NotificationModule.system,
          route: '/notifications',
          dedupeKey: 'system:inbox:intro',
        ),
      );
    }

    if (user != null && !hasAddress) {
      await addNotification(
        NotificationService.account(
          title: 'Add a saved address',
          body: 'Delivery, home services, and laundry will move faster once a default address is added.',
          route: '/profile/addresses',
          dedupeKey: 'account:missing_address:${user.id}',
        ),
      );
    }

    if (user != null && cartItems > 0) {
      await addNotification(
        NotificationService.reminder(
          title: 'You have $cartItems item${cartItems == 1 ? '' : 's'} waiting',
          body: 'Your cart is still active. Finish checkout when you are ready and we will keep the order updates here.',
          module: NotificationModule.orders,
          route: '/cart',
          dedupeKey: 'cart:active:${user.id}:$cartItems',
        ),
      );
    }

    final promoCode = cartProvider.promoCode;
    if (_preferences.promotionsEnabled && promoCode != null && promoCode.isNotEmpty) {
      await addNotification(
        NotificationService.promotion(
          title: 'Promo $promoCode is active',
          body: 'Your discount is already applied. Complete checkout before you lose the current basket state.',
          promoCode: promoCode,
          route: '/checkout',
        ),
      );
    }
  }

  bool _shouldAccept(
    AppNotificationModel notification, {
    required bool allowDuplicate,
  }) {
    if (!_preferences.pushEnabled) return false;
    if (!_preferences.promotionsEnabled &&
        notification.module == NotificationModule.promotions) {
      return false;
    }
    if (!_preferences.locationAlertsEnabled &&
        notification.module == NotificationModule.ride) {
      return false;
    }
    if (allowDuplicate || notification.dedupeKey == null) {
      return true;
    }
    return !_notifications.any(
      (item) => item.dedupeKey == notification.dedupeKey,
    );
  }

  void _mergeNotifications(List<AppNotificationModel> remoteItems) {
    final mergedById = {
      for (final item in _notifications) item.id: item,
    };
    final mergedByDedupe = {
      for (final item in _notifications)
        if (item.dedupeKey != null) item.dedupeKey!: item.id,
    };

    for (final remote in remoteItems) {
      final existingId = mergedById[remote.id]?.id;
      final existingDedupeId = remote.dedupeKey == null
          ? null
          : mergedByDedupe[remote.dedupeKey!];

      if (existingId != null) {
        mergedById[remote.id] = _prefer(remote, mergedById[remote.id]!);
        continue;
      }

      if (existingDedupeId != null) {
        final local = mergedById[existingDedupeId];
        if (local != null) {
          mergedById.remove(existingDedupeId);
          mergedById[remote.id] = _prefer(remote, local);
          mergedByDedupe[remote.dedupeKey!] = remote.id;
          continue;
        }
      }

      mergedById[remote.id] = remote;
      if (remote.dedupeKey != null) {
        mergedByDedupe[remote.dedupeKey!] = remote.id;
      }
    }

    _notifications
      ..clear()
      ..addAll(mergedById.values);
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  AppNotificationModel _prefer(
    AppNotificationModel remote,
    AppNotificationModel local,
  ) {
    return remote.copyWith(
      readAt: remote.readAt ?? local.readAt,
      metadata: {
        ...local.metadata,
        ...remote.metadata,
      },
      dedupeKey: remote.dedupeKey ?? local.dedupeKey,
      route: remote.route ?? local.route,
    );
  }

  List<AppNotificationModel> _defaultInbox() {
    return [
      NotificationService.reminder(
        title: 'Welcome to your smart inbox',
        body: 'We group updates by module so your orders, rides, care bookings, and offers stay easy to scan.',
        module: NotificationModule.system,
        route: '/notifications',
        dedupeKey: 'system:welcome',
      ),
    ];
  }

  Future<void> _persist() async {
    await AppPreferences.setNotificationsJson(
      _scope,
      AppNotificationModel.encodeList(_notifications),
    );
  }

  Future<void> _persistPreferences() async {
    await AppPreferences.setNotificationsPreferencesJson(
      _preferences.encode(),
    );
  }
}
