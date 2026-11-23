import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/language_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/city_availability_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/city_gate/screens/city_not_available_screen.dart';
import 'features/city_gate/widgets/no_internet_alert.dart';

class EdaLabApp extends StatelessWidget {
  const EdaLabApp({required this.router, this.title = 'EdaLab', super.key});

  final GoRouter router;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp.router(
          title: title,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: languageProvider.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (context, child) {
            // Belt-and-suspenders city gate: this sits *above* every route,
            // shell, modal and nested navigator in the app, so it can't be
            // scoped to a single module the way a router-only redirect can.
            // The router redirect (app_router.dart) still runs too, so deep
            // links resolve to a sane place once the gate lifts.
            return Consumer2<CityAvailabilityProvider, ConnectivityProvider>(
              builder: (context, cityProvider, connectivityProvider, _) {
                final app = cityProvider.isBlocking
                    ? const Directionality(
                        textDirection: TextDirection.ltr,
                        child: CityNotAvailableScreen(),
                      )
                    : child ?? const SizedBox.shrink();

                // No internet is an alert, not a gate: the app stays usable
                // and a strip overlays the top of the screen. It floats above
                // the content instead of pushing it down (a Column here would
                // reflow every route and overflow fixed layouts), and it
                // clears itself as soon as the device reconnects.
                if (!connectivityProvider.isOffline) return app;

                return Stack(
                  children: [
                    Positioned.fill(child: app),
                    Positioned(top: 0, left: 0, right: 0, child: const NoInternetAlert()),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
