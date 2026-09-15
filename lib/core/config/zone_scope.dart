/// Holds the service zone the device is currently in (e.g. `djibouti_ville`).
///
/// Written by `CityAvailabilityProvider` after every availability check and
/// read by screens that fetch per-location module data — the backend filters
/// restaurants, stores, pharmacies, hotels, laundry services and
/// professionals by this zone key when the `zone` query param is present.
///
/// Kept as a static holder because module data fetches go through static
/// `ApiClient` calls that have no BuildContext / Provider access.
class ZoneScope {
  ZoneScope._();

  static String? _currentZoneKey;

  /// Zone key of the matched active zone, or null when the device is outside
  /// every active zone (or the check hasn't run yet).
  static String? get currentZoneKey => _currentZoneKey;

  static void update(String? zoneKey) {
    final normalized = zoneKey?.trim() ?? '';
    _currentZoneKey = normalized.isEmpty ? null : normalized;
  }

  /// Appends the current zone as a query parameter to [path].
  ///
  /// Handles paths that already carry query params:
  /// ```dart
  /// ZoneScope.appendZone('/catalog/restaurants');
  /// // → '/catalog/restaurants?zone=djibouti_ville'  (or unchanged)
  /// ZoneScope.appendZone('/catalog/products?moduleType=pharmacy');
  /// // → '/catalog/products?moduleType=pharmacy&zone=djibouti_ville'
  /// ```
  static String appendZone(String path) {
    final zoneKey = _currentZoneKey;
    if (zoneKey == null || zoneKey.isEmpty) {
      return path;
    }
    final separator = path.contains('?') ? '&' : '?';
    return '$path${separator}zone=$zoneKey';
  }
}
