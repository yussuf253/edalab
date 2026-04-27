import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../localization/app_localizations.dart';
import '../models/app_notification_model.dart';
import '../repositories/notification_repository.dart';
import '../services/notification_service.dart';
import '../storage/app_preferences.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationRepository? repository})
    : _repository = repository ?? const NotificationRepository();

  final List<AppNotificationModel> _notifications = [];
  final NotificationRepository _repository;
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _isLoading = true;
  bool _isSyncing = false;
  String _scope = 'guest';
  String? _currentUserId;
  String? _lastSessionSignature;

  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get currentUserId => _currentUserId;
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
    final sessionSignature = [
      nextScope,
      'cart:${cartProvider.itemCount}',
      'promo:${cartProvider.promoCode ?? ''}',
      'addresses:${authProvider.user?.addresses.length ?? 0}',
    ].join('|');

    if (_lastSessionSignature == sessionSignature) {
      return;
    }

    _lastSessionSignature = sessionSignature;
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

  Future<void> syncProSession({required String? userId}) async {
    final nextScope = userId == null ? 'pro_guest' : 'pro_$userId';
    final sessionSignature = 'pro|$nextScope';

    if (_lastSessionSignature == sessionSignature) {
      return;
    }

    _lastSessionSignature = sessionSignature;
    _currentUserId = userId;

    if (_scope != nextScope) {
      await _loadScope(nextScope);
    }

    if (userId != null) {
      await refreshFromServer(userId);
    }
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
    _notifications[index] = _notifications[index].copyWith(
      readAt: DateTime.now(),
    );
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
        raw == null || raw.isEmpty
            ? await _defaultInbox()
            : AppNotificationModel.decodeList(raw),
      );
    _deduplicateInMemory();
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _isLoading = false;
    await _persist();
    notifyListeners();
  }

  Future<List<AppNotificationModel>> refreshFromServer(String userId) async {
    if (_isSyncing) return const [];
    _isSyncing = true;
    notifyListeners();
    try {
      final remoteItems = await _repository.fetchForUser(userId);
      if (remoteItems.isNotEmpty) {
        final addedItems = _mergeNotifications(remoteItems);
        await _persist();
        return addedItems;
      }
      return const [];
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncPushToken(String token) async {
    final userId = _currentUserId;
    if (userId == null || token.isEmpty) return;
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
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
    final l10n = await _l10n();

    final user = authProvider.user;
    final cartItems = cartProvider.itemCount;
    final hasAddress = (user?.addresses ?? const []).isNotEmpty;

    if (_notifications.isEmpty) {
      await addNotification(
        NotificationService.reminder(
          title: l10n.t('notifications.seed_activity_title'),
          body: l10n.t('notifications.seed_activity_body'),
          module: NotificationModule.system,
          route: '/notifications',
          dedupeKey: 'system:inbox:intro',
        ),
      );
    }

    if (user != null && !hasAddress) {
      await addNotification(
        NotificationService.account(
          title: l10n.t('notifications.seed_add_address_title'),
          body: l10n.t('notifications.seed_add_address_body'),
          route: '/profile/addresses',
          dedupeKey: 'account:missing_address:${user.id}',
        ),
      );
    }

    if (user != null && cartItems > 0) {
      await addNotification(
        NotificationService.reminder(
          title: l10n.t(
            'notifications.seed_cart_waiting_title',
            params: {'count': '$cartItems'},
          ),
          body: l10n.t('notifications.seed_cart_waiting_body'),
          module: NotificationModule.orders,
          route: '/cart',
          dedupeKey: 'cart:active:${user.id}:$cartItems',
        ),
      );
    }

    final promoCode = cartProvider.promoCode;
    if (_preferences.promotionsEnabled &&
        promoCode != null &&
        promoCode.isNotEmpty) {
      await addNotification(
        NotificationService.promotion(
          title: l10n.t(
            'notifications.seed_promo_active_title',
            params: {'code': promoCode},
          ),
          body: l10n.t('notifications.seed_promo_active_body'),
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
    final dedupeKey = notification.dedupeKey?.trim();
    if (allowDuplicate || dedupeKey == null || dedupeKey.isEmpty) {
      return true;
    }
    return !_notifications.any((item) => item.dedupeKey?.trim() == dedupeKey);
  }

  List<AppNotificationModel> _mergeNotifications(
    List<AppNotificationModel> remoteItems,
  ) {
    final existingIds = _notifications.map((item) => item.id).toSet();
    final existingDedupeKeys = _notifications
        .map((item) => item.dedupeKey?.trim())
        .whereType<String>()
        .where((key) => key.isNotEmpty)
        .toSet();
    final mergedById = {for (final item in _notifications) item.id: item};
    final mergedByDedupe = {
      for (final item in _notifications)
        if (item.dedupeKey?.trim().isNotEmpty == true)
          item.dedupeKey!.trim(): item.id,
    };

    final added = <AppNotificationModel>[];
    for (final remote in remoteItems) {
      final existingId = mergedById[remote.id]?.id;
      final remoteDedupeKey = remote.dedupeKey?.trim();
      final existingDedupeId =
          remoteDedupeKey == null || remoteDedupeKey.isEmpty
          ? null
          : mergedByDedupe[remoteDedupeKey];

      if (existingId != null) {
        mergedById[remote.id] = _prefer(remote, mergedById[remote.id]!);
        continue;
      }

      if (existingDedupeId != null) {
        final local = mergedById[existingDedupeId];
        if (local != null) {
          mergedById.remove(existingDedupeId);
          mergedById[remote.id] = _prefer(remote, local);
          if (remoteDedupeKey != null && remoteDedupeKey.isNotEmpty) {
            mergedByDedupe[remoteDedupeKey] = remote.id;
          }
          continue;
        }
      }

      mergedById[remote.id] = remote;
      if (!existingIds.contains(remote.id) &&
          (remoteDedupeKey == null ||
              !existingDedupeKeys.contains(remoteDedupeKey))) {
        added.add(remote);
      }
      if (remoteDedupeKey != null && remoteDedupeKey.isNotEmpty) {
        mergedByDedupe[remoteDedupeKey] = remote.id;
      }
    }

    _notifications
      ..clear()
      ..addAll(mergedById.values);
    _deduplicateInMemory();
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return added;
  }

  void _deduplicateInMemory() {
    if (_notifications.length <= 1) return;

    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final seenIds = <String>{};
    final seenDedupe = <String>{};
    final unique = <AppNotificationModel>[];

    for (final item in _notifications) {
      final id = item.id.trim();
      if (id.isNotEmpty && seenIds.contains(id)) {
        continue;
      }
      final dedupe = item.dedupeKey?.trim() ?? '';
      if (dedupe.isNotEmpty && seenDedupe.contains(dedupe)) {
        continue;
      }

      unique.add(item);
      if (id.isNotEmpty) {
        seenIds.add(id);
      }
      if (dedupe.isNotEmpty) {
        seenDedupe.add(dedupe);
      }
    }

    _notifications
      ..clear()
      ..addAll(unique);
  }

  AppNotificationModel _prefer(
    AppNotificationModel remote,
    AppNotificationModel local,
  ) {
    return remote.copyWith(
      readAt: remote.readAt ?? local.readAt,
      metadata: {...local.metadata, ...remote.metadata},
      dedupeKey: remote.dedupeKey ?? local.dedupeKey,
      route: remote.route ?? local.route,
    );
  }

  Future<List<AppNotificationModel>> _defaultInbox() async {
    final l10n = await _l10n();
    return [
      NotificationService.reminder(
        title: l10n.t('notifications.seed_welcome_title'),
        body: l10n.t('notifications.seed_welcome_body'),
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
    await AppPreferences.setNotificationsPreferencesJson(_preferences.encode());
  }

  Future<AppLocalizations> _l10n() async {
    final localeCode = await AppPreferences.getLocaleCode();
    return AppLocalizations(
      Locale(localeCode ?? AppLocalizations.fallbackLocale.languageCode),
    );
  }
}
