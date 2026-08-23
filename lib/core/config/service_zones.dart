import 'package:geolocator/geolocator.dart';

/// A city/town where eDalab operates or plans to operate.
///
/// Rollout strategy: launch one city at a time. Only zones with
/// [isActive] = true are usable — everyone else sees the "coming soon" gate
/// (see `CityNotAvailableScreen`).
///
/// To launch a new city: flip its `isActive` to `true` below. Nothing else
/// needs to change — the router gate, the coming-soon screen and the zone
/// check all read from this single list.
class CityZone {
  const CityZone({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.nameAr,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusKm,
    required this.isActive,
  });

  /// Stable identifier, e.g. 'ali_sabieh'. Safe to store/log/analytics.
  final String id;

  final String nameFr;
  final String nameEn;
  final String nameAr;

  /// Center point of the service zone (town center), in decimal degrees.
  final double centerLatitude;
  final double centerLongitude;

  /// How far from the center point (in km) the zone extends. Kept generous
  /// enough to absorb normal GPS drift and cover the town's immediate
  /// surroundings — this is a coarse circle, not a precise boundary.
  final double radiusKm;

  /// Whether eDalab is actually live in this city yet.
  final bool isActive;

  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return nameFr;
      case 'ar':
        return nameAr;
      default:
        return nameEn;
    }
  }

  /// Distance from [latitude]/[longitude] to this zone's center, in km.
  double distanceKmFrom(double latitude, double longitude) {
    return Geolocator.distanceBetween(
          latitude,
          longitude,
          centerLatitude,
          centerLongitude,
        ) /
        1000;
  }

  bool contains(double latitude, double longitude) {
    return distanceKmFrom(latitude, longitude) <= radiusKm;
  }
}

/// All known service zones, active and upcoming.
///
/// Coordinates are town centers (WGS84). Radii are coarse estimates based on
/// each town's built-up area — tighten or widen them once you have real
/// delivery/pickup data for that city.
const List<CityZone> kServiceZones = [
  CityZone(
    id: 'ali_sabieh',
    nameFr: 'Ali Sabieh',
    nameEn: 'Ali Sabieh',
    nameAr: 'علي صبيح',
    centerLatitude: 11.15583,
    centerLongitude: 42.71250,
    radiusKm: 5,
    isActive: true, // 🟢 live
  ),
  CityZone(
    id: 'djibouti_ville',
    nameFr: 'Djibouti-ville',
    nameEn: 'Djibouti City',
    nameAr: 'مدينة جيبوتي',
    centerLatitude: 11.59444,
    centerLongitude: 43.14806,
    radiusKm: 12,
    isActive: false,
  ),
  CityZone(
    id: 'arta',
    nameFr: 'Arta',
    nameEn: 'Arta',
    nameAr: 'أرتا',
    centerLatitude: 11.52361,
    centerLongitude: 42.84722,
    radiusKm: 4,
    isActive: false,
  ),
  CityZone(
    id: 'dikhil',
    nameFr: 'Dikhil',
    nameEn: 'Dikhil',
    nameAr: 'دخيل',
    centerLatitude: 11.10833,
    centerLongitude: 42.37111,
    radiusKm: 4,
    isActive: false,
  ),
  CityZone(
    id: 'tadjourah',
    nameFr: 'Tadjourah',
    nameEn: 'Tadjourah',
    nameAr: 'تاجورة',
    centerLatitude: 11.78300,
    centerLongitude: 42.88300,
    radiusKm: 4,
    isActive: false,
  ),
  CityZone(
    id: 'obock',
    nameFr: 'Obock',
    nameEn: 'Obock',
    nameAr: 'أبخ',
    centerLatitude: 11.96700,
    centerLongitude: 43.28300,
    radiusKm: 4,
    isActive: false,
  ),
];

List<CityZone> get kActiveServiceZones =>
    kServiceZones.where((z) => z.isActive).toList(growable: false);

List<CityZone> get kUpcomingServiceZones =>
    kServiceZones.where((z) => !z.isActive).toList(growable: false);
