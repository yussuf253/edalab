import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/network/api_client.dart';
import 'core/providers/providers.dart';
import 'core/providers/app_version_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_sync_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/app_version_service.dart';
import 'core/storage/app_preferences.dart';
import 'pro/core/providers/pro_auth_provider.dart';
import 'pro/core/services/pro_inbox_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSeenOnboarding = await AppPreferences.hasSeenOnboarding();
  final authProvider = AuthProvider();
  final cartProvider = CartProvider();
  final languageProvider = LanguageProvider();
  final notificationProvider = NotificationProvider();
  final userLocationProvider = UserLocationProvider();
  final moduleProvider = ModuleProvider();
  final proAuthProvider = ProAuthProvider();
  final appVersionProvider = AppVersionProvider();
  await languageProvider.initialize();
  await moduleProvider.hydrateFromStorage();
  await AnalyticsService.instance.initialize(
    localeCode: languageProvider.locale.languageCode,
    appVariant: 'user',
  );
  _bindAnalyticsStateSync(
    authProvider: authProvider,
    languageProvider: languageProvider,
  );

  final router = createAppRouter(hasSeenOnboarding: hasSeenOnboarding);
  AnalyticsService.instance.attachRouter(router);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: cartProvider),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(),
          update: (_, auth, wishlist) {
            final provider = wishlist ?? WishlistProvider();
            provider.syncAuth(auth.user?.id);
            return provider;
          },
        ),
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: userLocationProvider),
        ChangeNotifierProvider.value(value: moduleProvider),
        ChangeNotifierProvider.value(value: proAuthProvider),
        ChangeNotifierProvider.value(value: appVersionProvider),
        ChangeNotifierProxyProvider2<
          AuthProvider,
          CartProvider,
          NotificationProvider
        >(
          create: (_) => notificationProvider,
          update: (_, auth, cart, notifications) {
            final provider = notifications ?? notificationProvider;
            provider.syncSession(authProvider: auth, cartProvider: cart);
            PushNotificationService.bindProvider(provider);
            NotificationSyncService.instance.updateProvider(provider);
            ProInboxSyncService.instance.updateProviders(
              notificationProvider: provider,
              proAuthProvider: proAuthProvider,
            );
            final token = PushNotificationService.token;
            if (token != null && token.isNotEmpty) {
              provider.syncPushToken(token);
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: EdaLabApp(router: router),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      _bootstrapAppServices(
        authProvider: authProvider,
        cartProvider: cartProvider,
        languageProvider: languageProvider,
        notificationProvider: notificationProvider,
        moduleProvider: moduleProvider,
        proAuthProvider: proAuthProvider,
        appVersionProvider: appVersionProvider,
      ),
    );
  });
}

void _bindAnalyticsStateSync({
  required AuthProvider authProvider,
  required LanguageProvider languageProvider,
}) {
  String? lastSyncedUserId;
  int? lastAddressCount;
  bool? lastLoginState;
  String? lastLocaleCode;

  void syncAuth() {
    final user = authProvider.user;
    final userId = user?.id;
    final addressCount = user?.addresses.length ?? 0;
    final isLoggedIn = authProvider.isLoggedIn;

    if (userId == lastSyncedUserId &&
        addressCount == lastAddressCount &&
        isLoggedIn == lastLoginState) {
      return;
    }

    AnalyticsService.instance.setUserId(userId);
    AnalyticsService.instance.setUserProperties({
      'is_logged_in': isLoggedIn,
      'address_count': addressCount,
      'has_saved_address': addressCount > 0,
    });

    lastSyncedUserId = userId;
    lastAddressCount = addressCount;
    lastLoginState = isLoggedIn;
  }

  void syncLocale() {
    final localeCode = languageProvider.locale.languageCode;
    if (localeCode == lastLocaleCode) return;

    AnalyticsService.instance.setGlobalProperties({'locale': localeCode});
    AnalyticsService.instance.setUserProperties({'locale': localeCode});
    lastLocaleCode = localeCode;
  }

  authProvider.addListener(syncAuth);
  languageProvider.addListener(syncLocale);
  syncAuth();
  syncLocale();
}

Future<void> _bootstrapAppServices({
  required AuthProvider authProvider,
  required CartProvider cartProvider,
  required LanguageProvider languageProvider,
  required NotificationProvider notificationProvider,
  required ModuleProvider moduleProvider,
  required ProAuthProvider proAuthProvider,
  required AppVersionProvider appVersionProvider,
}) async {
  ApiClient.warmUpBackendInBackground();

  await Future.wait([
    authProvider.initialize(),
    cartProvider.initialize(),
    languageProvider.initialize(),
    notificationProvider.initialize(),
    moduleProvider.initialize(),
  ]);

  proAuthProvider.fetchProfile(authProvider.user?.id ?? '');

  await notificationProvider.syncSession(
    authProvider: authProvider,
    cartProvider: cartProvider,
  );

  PushNotificationService.bindProvider(notificationProvider);
  NotificationSyncService.instance.start(notificationProvider);
  ProInboxSyncService.instance.start(
    notificationProvider: notificationProvider,
    proAuthProvider: proAuthProvider,
  );

  unawaited(NotificationSyncService.instance.syncNow(showAlerts: false));
  unawaited(_initializePush(notificationProvider));

  // Initialize version checking service (call after brief delay to ensure context is available)
  Future.delayed(const Duration(milliseconds: 100), () {
    try {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        AppVersionService().initialize(context);
      }
    } catch (e) {
      print('Version service initialization error: $e');
    }
  });
}

Future<void> _initializePush(NotificationProvider notificationProvider) async {
  await PushNotificationService.initialize();
  await PushNotificationService.syncInitialMessage();

  final initialToken = PushNotificationService.token;
  if (initialToken != null && initialToken.isNotEmpty) {
    unawaited(notificationProvider.syncPushToken(initialToken));
  }
}
