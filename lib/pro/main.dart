import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app.dart'; // pro/app.dart
import '../core/network/api_client.dart'; // ✅ User
import '../core/providers/language_provider.dart'; // ✅ User
import '../core/providers/notification_provider.dart'; // ✅ User
import '../core/providers/theme_provider.dart'; // ✅ User
import '../core/services/notification_sync_service.dart'; // ✅ User
import '../core/services/push_notification_service.dart'; // ✅ User
import '../core/storage/app_preferences.dart'; // ✅ User
import 'core/providers/pro_auth_provider.dart'; // ✅ Pro (spécifique Pro)
import 'core/router/pro_app_router.dart'; // ✅ Pro
import 'core/services/pro_inbox_sync_service.dart'; // ✅ Pro

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.initialize(scope: ApiSessionScope.pro);
  ApiClient.warmUpBackendInBackground();

  final hasSeenProOnboarding = await AppPreferences.hasSeenProOnboarding();
  final languageProvider = LanguageProvider();
  final notificationProvider = NotificationProvider();
  final proAuthProvider = ProAuthProvider();

  await Future.wait([
    languageProvider.initialize(),
    notificationProvider.initialize(),
    proAuthProvider.initialize(),
  ]);

  // Redirect banned pro users to the banned screen
  if (proAuthProvider.isBanned) {
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        final context = proNavigatorKey.currentContext;
        if (context != null && context.mounted) {
          context.go('/banned', extra: proAuthProvider.banReason);
        }
      } catch (e) {
        print('Banned redirect error: $e');
      }
    });
  }

  await notificationProvider.syncProSession(
    userId: proAuthProvider.currentProfile?.userId,
  );
  PushNotificationService.setRouteOpener(openProAppRoute);

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
        ChangeNotifierProvider.value(value: languageProvider),
        ChangeNotifierProvider.value(value: proAuthProvider),
        ChangeNotifierProxyProvider<ProAuthProvider, NotificationProvider>(
          create: (_) => notificationProvider,
          update: (_, proAuth, notifications) {
            final provider = notifications ?? notificationProvider;
            unawaited(
              provider.syncProSession(userId: proAuth.currentProfile?.userId),
            );
            PushNotificationService.bindProvider(provider);
            NotificationSyncService.instance.updateProvider(provider);
            ProInboxSyncService.instance.updateProviders(
              notificationProvider: provider,
              proAuthProvider: proAuth,
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
        router: createProAppRouter(
          proAuthProvider: proAuthProvider,
          hasSeenOnboarding: hasSeenProOnboarding,
        ),
      ),
    ),
  );

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
    await notificationProvider.syncPushToken(initialToken);
  }
}
