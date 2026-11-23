import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Base spacing unit = 4
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets screenPaddingAll = EdgeInsets.all(base);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(base);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(md);

  // Border Radius — one consistent scale for the whole product.
  static const double radiusXs = 6;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 18;
  static const double radiusXxl = 20;
  static const double radiusFull = 100;

  // Elevation — hairline borders carry the structure, shadows only lift a
  // surface off the canvas. The tint is warm-neutral, never pure black, so
  // cards on the green-tinted canvas don't read as dirty.
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0A0B1A14),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  // Icon sizes
  static const double iconXs = 16;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 28;
  static const double iconXl = 32;
}
