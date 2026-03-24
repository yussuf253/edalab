import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/providers/providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSeenOnboarding = await AppPreferences.hasSeenOnboarding();
  final authProvider = AuthProvider();
  authProvider.initialize();
  final cartProvider = CartProvider();
  cartProvider.initialize();
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: EdaLabApp(
        router: createAppRouter(hasSeenOnboarding: hasSeenOnboarding),
      ),
    ),
  );
}
