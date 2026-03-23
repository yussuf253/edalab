import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42E8);
  static const Color primarySurface = Color(0xFFF0EFFF);

  // Secondary Colors
  static const Color secondary = Color(0xFF00D2FF);
  static const Color secondaryLight = Color(0xFF66E3FF);
  static const Color secondaryDark = Color(0xFF00A3CC);

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
  static const Color extraLightGrey = Color(0xFFF3F4F6);
  static const Color background = Color(0xFFF8F9FE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  // Module Colors
  static const Color shopping = Color(0xFFFF6B6B);
  static const Color shoppingBg = Color(0xFFFFF0F0);
  static const Color food = Color(0xFFFF8C42);
  static const Color foodBg = Color(0xFFFFF3EB);
  static const Color grocery = Color(0xFF2ED573);
  static const Color groceryBg = Color(0xFFE8FAF0);
  static const Color ride = Color(0xFF6C63FF);
  static const Color rideBg = Color(0xFFF0EFFF);
  static const Color hotel = Color(0xFF00D2FF);
  static const Color hotelBg = Color(0xFFE6FAFF);
  static const Color doctor = Color(0xFF3498DB);
  static const Color doctorBg = Color(0xFFEBF5FB);
  static const Color pharmacy = Color(0xFF00B894);
  static const Color pharmacyBg = Color(0xFFE6FFF9);
  static const Color laundry = Color(0xFF9B59B6);
  static const Color laundryBg = Color(0xFFF5EEFF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B83FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFF00F5A0)],
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
