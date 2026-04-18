import 'package:flutter/material.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    final previous = _themeMode;
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    AnalyticsService.instance.track(
      AnalyticsEvents.themeChanged,
      properties: {'from': previous.name, 'to': _themeMode.name},
    );
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    final previous = _themeMode;
    _themeMode = mode;
    AnalyticsService.instance.track(
      AnalyticsEvents.themeChanged,
      properties: {'from': previous.name, 'to': _themeMode.name},
    );
    notifyListeners();
  }
}
