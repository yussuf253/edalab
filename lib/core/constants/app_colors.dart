import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF00A651);
  static const Color primaryLight = Color(0xFF33C176);
  static const Color primaryDark = Color(0xFF007B3C);
  static const Color primarySurface = Color(0xFFE9F8F0);

  // Secondary Colors
  static const Color secondary = Color(0xFF12B76A);
  static const Color secondaryLight = Color(0xFF5AD79A);
  static const Color secondaryDark = Color(0xFF0E9455);

  // Accent Colors
  static const Color accent = Color(0xFFFF5A3D);
  static const Color accentLight = Color(0xFFFF8A73);
  static const Color accentDark = Color(0xFFD63F26);

  // Semantic Colors
  static const Color success = Color(0xFF12B76A);
  static const Color successLight = Color(0xFFE9F8F0);
  static const Color warning = Color(0xFFFFB020);
  static const Color warningLight = Color(0xFFFFF7E8);
  static const Color error = Color(0xFFF04438);
  static const Color errorLight = Color(0xFFFEECEB);
  static const Color info = Color(0xFF2E90FA);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Neutral Colors
  static const Color dark = Color(0xFF14161A);
  static const Color darkGrey = Color(0xFF2A2D34);
  static const Color grey = Color(0xFF667085);
  static const Color mediumGrey = Color(0xFF98A2B3);
  static const Color lightGrey = Color(0xFFE7EAEE);
  static const Color extraLightGrey = Color(0xFFF3F5F7);
  static const Color background = Color(0xFFF7F8FA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// Hairline border used on white cards, pills and inputs.
  static const Color border = Color(0xFFEDEFF3);

  /// Soft filled surface used for service tiles, search pills and chips.
  static const Color tile = Color(0xFFF4F5F7);

  // Module Colors
  static const Color shopping = Color(0xFF00A651);
  static const Color shoppingBg = Color(0xFFE9F8F0);
  static const Color food = Color(0xFF00A651);
  static const Color foodBg = Color(0xFFE9F8F0);
  static const Color grocery = Color(0xFF0FA95B);
  static const Color groceryBg = Color(0xFFE9F8F0);
  static const Color homeServices = Color(0xFF00976A);
  static const Color homeServicesBg = Color(0xFFE7F8F2);
  static const Color ride = Color(0xFF0C8F55);
  static const Color rideBg = Color(0xFFE8F7EF);
  static const Color hotel = Color(0xFF0E9E6B);
  static const Color hotelBg = Color(0xFFE8F8F2);
  static const Color doctor = Color(0xFF00936A);
  static const Color doctorBg = Color(0xFFE7F7F1);
  static const Color pharmacy = Color(0xFF00A651);
  static const Color pharmacyBg = Color(0xFFE9F8F0);
  static const Color laundry = Color(0xFF199C6C);
  static const Color laundryBg = Color(0xFFE9F8F2);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, Color(0xFFFF9A76)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [dark, Color(0xFF23262D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF171A1F);
  static const Color darkCard = Color(0xFF1F2229);
}
