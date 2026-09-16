import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/network/api_client.dart';
import 'core/providers/providers.dart';
import 'core/providers/app_version_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/module_sync_service.dart';
import 'core/services/notification_sync_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/app_version_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/realtime_service.dart';
import 'core/storage/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the persisted session token before any provider can issue requests,
  // mirroring the Pro app's bootstrap so both variants initialize identically.
  await ApiClient.initialize(scope: ApiSessionScope.user);
  final hasSeenOnboarding = await AppPreferences.hasSeenOnboarding();
  final hasSeenHomeOnboarding = await AppPreferences.hasSeenHomeOnboarding();
  final authProvider = AuthProvider();
  final cartProvider = CartProvider();
  final languageProvider = LanguageProvider();
  final notificationProvider = NotificationProvider();
  final userLocationProvider = UserLocationProvider();
  final moduleProvider = ModuleProvider();
  final appVersionProvider = AppVersionProvider();
  final cityAvailabilityProvider = CityAvailabilityProvider();
  final connectivityProvider = ConnectivityProvider();
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
  // Keeps module activation live: refreshes on app resume + periodic poll,
  // so admin toggles apply without an app restart.
  ModuleSyncService.instance.start(moduleProvider);

  final router = createAppRouter(
    authProvider: authProvider,
    cityAvailabilityProvider: cityAvailabilityProvider,
    hasSeenOnboarding: hasSeenOnboarding,
    hasSeenHomeOnboarding: hasSeenHomeOnboarding,
  );
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
        ChangeNotifierProvider.value(value: appVersionProvider),
        ChangeNotifierProvider.value(value: cityAvailabilityProvider),
        ChangeNotifierProvider.value(value: connectivityProvider),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
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
            final token = PushNotificationService.token;
            if (token != null && token.isNotEmpty) {
              provider.syncPushToken(token);
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AliExpressProvider()),
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
        appVersionProvider: appVersionProvider,
        cityAvailabilityProvider: cityAvailabilityProvider,
        connectivityProvider: connectivityProvider,
      ),
    );
    RealtimeService().connect();
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
  required AppVersionProvider appVersionProvider,
  required CityAvailabilityProvider cityAvailabilityProvider,
  required ConnectivityProvider connectivityProvider,
}) async {
  ApiClient.warmUpBackendInBackground();

  await Future.wait([
    authProvider.initialize(),
    cartProvider.initialize(),
    languageProvider.initialize(),
    notificationProvider.initialize(),
    moduleProvider.initialize(),
    cityAvailabilityProvider.checkAvailability(),
    connectivityProvider.initialize(),
  ]);

  // Bootstrapped after the module provider's first server sync so the
  // foreground/resume observers never race with startup.
  unawaited(ModuleSyncService.instance.refresh());

  // NOTE: banned-user redirection is handled declaratively by the router's
  // redirect guard (app_router.dart), which reacts to authProvider changes via
  // refreshListenable — no imperative navigation needed here.

  await notificationProvider.syncSession(
    authProvider: authProvider,
    cartProvider: cartProvider,
  );

  PushNotificationService.bindProvider(notificationProvider);
  NotificationSyncService.instance.start(notificationProvider);

  unawaited(NotificationSyncService.instance.syncNow(showAlerts: false));
  unawaited(_initializePush(notificationProvider));

  // Initialize version checking service (call after brief delay to ensure context is available)
  Future.delayed(const Duration(milliseconds: 100), () {
    try {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        AppVersionService().initialize(context);
        DeepLinkService().initialize(context);
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
