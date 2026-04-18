import 'package:flutter/material.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../localization/app_localizations.dart';
import '../storage/app_preferences.dart';

class SupportedLanguage {
  const SupportedLanguage({
    required this.locale,
    required this.nativeName,
    required this.englishName,
  });

  final Locale locale;
  final String nativeName;
  final String englishName;
}

class LanguageProvider extends ChangeNotifier {
  static const supportedLanguages = [
    SupportedLanguage(
      locale: Locale('en'),
      nativeName: 'English',
      englishName: 'English',
    ),
    SupportedLanguage(
      locale: Locale('fr'),
      nativeName: 'Francais',
      englishName: 'French',
    ),
    SupportedLanguage(
      locale: Locale('ar'),
      nativeName: 'العربية',
      englishName: 'Arabic',
    ),
  ];

  Locale _locale = AppLocalizations.fallbackLocale;

  Locale get locale => _locale;

  SupportedLanguage get currentLanguage {
    return supportedLanguages.firstWhere(
      (item) => item.locale.languageCode == _locale.languageCode,
      orElse: () => supportedLanguages.first,
    );
  }

  Future<void> initialize() async {
    final savedCode = await AppPreferences.getLocaleCode();
    if (savedCode == null || savedCode.isEmpty) return;
    final next = _normalize(Locale(savedCode));
    if (next.languageCode == _locale.languageCode) return;
    _locale = next;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    final previousCode = _locale.languageCode;
    final next = _normalize(locale);
    if (next.languageCode == _locale.languageCode) return;
    _locale = next;
    notifyListeners();
    await AppPreferences.setLocaleCode(next.languageCode);
    AnalyticsService.instance.setGlobalProperties({
      'locale': next.languageCode,
    });
    AnalyticsService.instance.setUserProperties({'locale': next.languageCode});
    AnalyticsService.instance.track(
      AnalyticsEvents.languageChanged,
      properties: {'from': previousCode, 'to': next.languageCode},
    );
  }

  Locale _normalize(Locale locale) {
    return AppLocalizations.supportedLocales.firstWhere(
      (item) => item.languageCode == locale.languageCode,
      orElse: () => AppLocalizations.fallbackLocale,
    );
  }
}
