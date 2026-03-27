import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF039D55);
  static const Color primaryLight = Color(0xFF32BB79);
  static const Color primaryDark = Color(0xFF027A42);
  static const Color primarySurface = Color(0xFFE8FBF1);

  // Secondary Colors
  static const Color secondary = Color(0xFF04D472);
  static const Color secondaryLight = Color(0xFF52E59D);
  static const Color secondaryDark = Color(0xFF03B261);

  // Accent Colors
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF9E9E);
  static const Color accentDark = Color(0xFFCC4545);

  // Semantic Colors
  static const Color success = Color(0xFF2ED573);
  static const Color successLight = Color(0xFFE8FAF0);
  static const Color warning = Color(0xFFFFBE21);
  static const Color warningLight = Color(0xFFFFF8E7);
  static const Color error = Color(0xFFFF4757);
  static const Color errorLight = Color(0xFFFFEDEF);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFEBF5FB);

  // Neutral Colors
  static const Color dark = Color(0xFF1A1A2E);
  static const Color darkGrey = Color(0xFF2D2D44);
  static const Color grey = Color(0xFF6B7280);
  static const Color mediumGrey = Color(0xFF9CA3AF);
  static const Color lightGrey = Color(0xFFD1D5DB);
  static const Color extraLightGrey = Color(0xFFF2F6F3);
  static const Color background = Color(0xFFF7FBF8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  // Module Colors
  static const Color shopping = Color(0xFF199A60);
  static const Color shoppingBg = Color(0xFFEAF8F0);
  static const Color food = Color(0xFF3BAA5C);
  static const Color foodBg = Color(0xFFEDF8EF);
  static const Color grocery = Color(0xFF04D472);
  static const Color groceryBg = Color(0xFFEAFBF2);
  static const Color homeServices = Color(0xFF1A9A77);
  static const Color homeServicesBg = Color(0xFFEAF8F3);
  static const Color ride = Color(0xFF1D9070);
  static const Color rideBg = Color(0xFFE9F7F2);
  static const Color hotel = Color(0xFF2B9D73);
  static const Color hotelBg = Color(0xFFEAF8F2);
  static const Color doctor = Color(0xFF188E68);
  static const Color doctorBg = Color(0xFFE8F7F0);
  static const Color pharmacy = Color(0xFF03B261);
  static const Color pharmacyBg = Color(0xFFE9FBF3);
  static const Color laundry = Color(0xFF4A9C73);
  static const Color laundryBg = Color(0xFFEDF8F2);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF04D472)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF52E59D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFF9A76)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [dark, Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F0F1E);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF222240);
}
