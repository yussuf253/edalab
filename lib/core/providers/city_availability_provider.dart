import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../config/service_zones.dart';

enum CityAvailabilityStatus {
  /// Initial state — check hasn't run yet.
  unknown,

  /// A GPS check is currently in progress.
  checking,

  /// Device is inside an active service zone — app usable normally.
  available,

  /// Device was located but isn't inside any active zone.
  outOfZone,

  /// Location services are turned off on the device.
  locationServiceDisabled,

  /// Permission was denied (can still ask again).
  permissionDenied,

  /// Permission was permanently denied — user must go to device Settings.
  permissionDeniedForever,

  /// Something else went wrong (timeout, no GPS fix, etc).
  error,
}

/// Restricts the app to the cities eDalab currently operates in.
///
/// Uses the device's raw GPS position (not a manually-picked address) and
/// checks it against [kServiceZones]. This is intentionally a *client-side,
/// UX-level* gate for a phased rollout — it stops honest users from landing
/// in a city with no real service coverage, showing a friendly "coming soon"
/// screen instead of a broken/empty app. It is not a security boundary: a
/// determined user could spoof GPS. If that ever matters for you (fraud,
/// abuse), add a matching check server-side against delivery/pickup
/// addresses in the backend.
class CityAvailabilityProvider extends ChangeNotifier {
  CityAvailabilityStatus _status = CityAvailabilityStatus.unknown;
  CityZone? _matchedZone;
  CityZone? _nearestZone;

  CityAvailabilityStatus get status => _status;

  /// The active zone the user is currently inside, if any.
  CityZone? get matchedZone => _matchedZone;

  /// Closest known zone (active or upcoming) to the user's last checked
  /// position — used only for "coming soon" messaging, not for access.
  CityZone? get nearestZone => _nearestZone;

  /// Whether the app should currently be blocked behind the city gate.
  bool get isBlocking =>
      _status != CityAvailabilityStatus.unknown &&
      _status != CityAvailabilityStatus.checking &&
      _status != CityAvailabilityStatus.available;

  Future<void> checkAvailability() async {
    _status = CityAvailabilityStatus.checking;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _status = CityAvailabilityStatus.locationServiceDisabled;
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _status = CityAvailabilityStatus.permissionDeniedForever;
        notifyListeners();
        return;
      }
      if (permission == LocationPermission.denied) {
        _status = CityAvailabilityStatus.permissionDenied;
        notifyListeners();
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _status = CityAvailabilityStatus.error;
        notifyListeners();
        return;
      }

      _resolveZones(position.latitude, position.longitude);
      _status = _matchedZone != null
          ? CityAvailabilityStatus.available
          : CityAvailabilityStatus.outOfZone;
      notifyListeners();
    } catch (_) {
      _status = CityAvailabilityStatus.error;
      notifyListeners();
    }
  }

  void _resolveZones(double latitude, double longitude) {
    CityZone? matched;
    CityZone? nearest;
    double bestDistanceKm = double.infinity;

    for (final zone in kServiceZones) {
      final distanceKm = zone.distanceKmFrom(latitude, longitude);
      if (distanceKm < bestDistanceKm) {
        bestDistanceKm = distanceKm;
        nearest = zone;
      }
      if (zone.isActive && distanceKm <= zone.radiusKm) {
        matched = zone;
      }
    }

    _matchedZone = matched;
    _nearestZone = nearest;
  }
}
