import 'dart:ui' show Color;

/// The grey the category illustrations are exported on. Tiles and headers use
/// it as their plate so the artwork blends in with no visible square.
const Color homeServiceCategoryPlateColor = Color(0xFFEFF0F4);

/// Category art from the handyman illustration set, matched on slug/name.
String? homeServiceCategoryImage(String slug, String name) {
  final value = '$slug $name'.toLowerCase();
  // Specific trades are matched before the broad "house"/"clean" rule so a
  // category such as "house-carpentry" still gets its carpenter artwork. The
  // generic handyman category uses that same artwork (hammer and saw).
  if (value.contains('carpent') ||
      value.contains('carpain') ||
      value.contains('handyman') ||
      value.contains('handy man') ||
      value.contains('handy-man') ||
      value.contains('general repair')) {
    return 'assets/images/service/categories/handy_carpainter.png';
  }
  if (value.contains('plumb')) {
    return 'assets/images/service/categories/handy_plumber.png';
  }
  if (value.contains('elec')) {
    return 'assets/images/service/categories/handy_elec.png';
  }
  if (value.contains('paint')) {
    return 'assets/images/service/categories/handy_painter.png';
  }
  if (value.contains('garden') || value.contains('landscap')) {
    return 'assets/images/service/categories/handy_gardener.png';
  }
  if (value.contains('mov') || value.contains('pack')) {
    return 'assets/images/service/categories/handy_mover.png';
  }
  if (value.contains('salon') ||
      value.contains('beauty') ||
      value.contains('hair')) {
    return 'assets/images/service/categories/handy_salon.png';
  }
  if (value.contains('sanit') || value.contains('disinfect')) {
    return 'assets/images/service/categories/handy_sanitize.png';
  }
  if (value.contains('clean') || value.contains('house')) {
    return 'assets/images/service/categories/handy_cleaner.png';
  }
  return null;
}
