import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart' as core;

/// The pro module used to keep a second, slightly different copy of the theme
/// (18px app-bar titles, 24px sheets, borderless inputs), which is exactly how
/// two screens end up looking like two apps. It now shares the single product
/// theme; the class stays so existing imports keep working.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => core.AppTheme.lightTheme;

  static ThemeData get darkTheme => core.AppTheme.darkTheme;
}
