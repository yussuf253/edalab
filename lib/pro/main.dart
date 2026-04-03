import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app.dart';
import '../core/providers/providers.dart';
import '../core/services/notification_sync_service.dart';
import '../core/services/push_notification_service.dart';
import '../core/storage/app_preferences.dart';
import 'core/providers/pro_auth_provider.dart';
import 'core/router/pro_app_router.dart';
import 'core/services/pro_inbox_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSeenProOnboarding = await AppPreferences.hasSeenProOnboarding();

  final authProvider = AuthProvider();
  final cartProvider = CartProvider();
  final languageProvider = LanguageProvider();
  final notificationProvider = NotificationProvider();
  final proAuthProvider = ProAuthProvider();

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
        ChangeNotifierProvider.value(value: proAuthProvider),
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
      child: EdaLabApp(
        title: 'EdaLab Pro',
        router: createProAppRouter(hasSeenOnboarding: hasSeenProOnboarding),
      ),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      _bootstrapProAppServices(
        authProvider: authProvider,
        cartProvider: cartProvider,
        languageProvider: languageProvider,
        notificationProvider: notificationProvider,
        proAuthProvider: proAuthProvider,
      ),
    );
  });
}

Future<void> _bootstrapProAppServices({
  required AuthProvider authProvider,
  required CartProvider cartProvider,
  required LanguageProvider languageProvider,
  required NotificationProvider notificationProvider,
  required ProAuthProvider proAuthProvider,
}) async {
  await Future.wait([
    authProvider.initialize(),
    cartProvider.initialize(),
    languageProvider.initialize(),
    notificationProvider.initialize(),
  ]);

  await proAuthProvider.fetchProfile(authProvider.user?.id ?? '');

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
}

Future<void> _initializePush(NotificationProvider notificationProvider) async {
  await PushNotificationService.initialize();
  await PushNotificationService.syncInitialMessage();

  final initialToken = PushNotificationService.token;
  if (initialToken != null && initialToken.isNotEmpty) {
    unawaited(notificationProvider.syncPushToken(initialToken));
  }
}
