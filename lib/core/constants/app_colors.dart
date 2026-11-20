import 'package:flutter/material.dart';

/// EdaLab colour system.
///
/// One brand accent (green) carries every action, active state and price
/// emphasis; everything else is a neutral ink / hairline / soft-surface tone.
/// Module accents stay inside a green-teal family so screens read as one
/// product instead of a patchwork of module themes.
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = Color(0xFF00A651);
  static const Color primaryLight = Color(0xFF28B76C);
  static const Color primaryDark = Color(0xFF007A3B);
  static const Color primarySurface = Color(0xFFE7F6EE);

  // Secondary Colors
  static const Color secondary = Color(0xFF0E8F5A);
  static const Color secondaryLight = Color(0xFF22B573);
  static const Color secondaryDark = Color(0xFF0A6E45);

  // Accent Colors
  static const Color accent = Color(0xFFE4573D);
  static const Color accentLight = Color(0xFFF08A74);
  static const Color accentDark = Color(0xFFC23F28);

  // Semantic Colors
  static const Color success = Color(0xFF0F9D58);
  static const Color successLight = Color(0xFFE7F6EE);
  static const Color warning = Color(0xFFE8A317);
  static const Color warningLight = Color(0xFFFDF5E4);
  static const Color error = Color(0xFFD92D20);
  static const Color errorLight = Color(0xFFFEEDEB);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEAF1FE);

  // Neutral Colors
  static const Color dark = Color(0xFF0F1A14);
  static const Color darkGrey = Color(0xFF24302A);
  static const Color grey = Color(0xFF6B7772);
  static const Color mediumGrey = Color(0xFF93A09A);
  static const Color lightGrey = Color(0xFFE4E9E6);
  static const Color extraLightGrey = Color(0xFFF2F5F3);
  static const Color background = Color(0xFFF7F8F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// Hairline border used on white cards, pills and inputs.
  static const Color border = Color(0xFFE9EDEA);

  /// Soft filled surface used for service tiles, search pills and chips.
  static const Color tile = Color(0xFFF3F6F4);

  // Module Colors — one green-teal family, differentiated by hue only.
  static const Color shopping = Color(0xFF0F8A4F);
  static const Color shoppingBg = Color(0xFFE9F6EF);
  static const Color food = Color(0xFF12A05A);
  static const Color foodBg = Color(0xFFE8F7EE);
  static const Color grocery = Color(0xFF0C8B4A);
  static const Color groceryBg = Color(0xFFE8F6EC);
  static const Color homeServices = Color(0xFF0B7A62);
  static const Color homeServicesBg = Color(0xFFE6F4F0);
  static const Color ride = Color(0xFF157A4A);
  static const Color rideBg = Color(0xFFE9F5EE);
  static const Color hotel = Color(0xFF0E7C6E);
  static const Color hotelBg = Color(0xFFE6F4F2);
  static const Color doctor = Color(0xFF0D7F5F);
  static const Color doctorBg = Color(0xFFE7F5F0);
  static const Color pharmacy = Color(0xFF0E9159);
  static const Color pharmacyBg = Color(0xFFE7F7EE);
  static const Color laundry = Color(0xFF146E7A);
  static const Color laundryBg = Color(0xFFE5F2F5);

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
    colors: [accent, Color(0xFFF08A74)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [dark, Color(0xFF1C2A22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0C110E);
  static const Color darkSurface = Color(0xFF141A16);
  static const Color darkCard = Color(0xFF1A211C);
}
