import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'core/providers/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        );
      },
    );
  }
}
