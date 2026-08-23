import 'dart:math' as math;

import 'package:flutter/material.dart' show Icons;

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../widgets/ride_route_preview.dart';

/// Supplies the small cluster of "nearby drivers" car markers shown on the
/// Ride landing map before a trip is booked — the same ambient-presence cue
/// Uber/Bolt/Careem give ("drivers are close by").
///
/// Tries a real backend endpoint first. If it's not available yet (404/
/// error), falls back to a believable simulated cluster around the given
/// point, gently drifting over time so the map still feels alive. This
/// mirrors how `interpolateRideMapPoint` already fills in for the driver's
/// live position when the backend doesn't provide one.
///
/// ⚠️ Backend contract this expects, once you wire it up for real:
/// `GET /rides/nearby-drivers?lat={lat}&lng={lng}&radiusKm={radiusKm}`
/// → `[{ "id": "...", "latitude": 11.58, "longitude": 43.14 }, ...]`
/// Once that endpoint exists and returns real data, this switches over
/// automatically — no other code needs to change.
class NearbyDriversService {
  NearbyDriversService._();

  static Future<List<RideMapPoint>> fetch({
    required double latitude,
    required double longitude,
    double radiusKm = 1.4,
    int simulatedCount = 5,
  }) async {
    final real = await _fetchFromBackend(latitude, longitude, radiusKm);
    if (real != null && real.isNotEmpty) return real;
    return _simulate(latitude, longitude, radiusKm, simulatedCount);
  }

  static Future<List<RideMapPoint>?> _fetchFromBackend(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    try {
      final resp = await ApiClient.get(
        '/rides/nearby-drivers?lat=$latitude&lng=$longitude&radiusKm=$radiusKm',
      );
      final list = resp is List
          ? resp
          : (resp is Map && resp['items'] is List)
          ? resp['items'] as List
          : null;
      if (list == null) return null;

      return list.whereType<Map>().map((raw) {
        final m = Map<String, dynamic>.from(raw);
        return RideMapPoint(
          label: m['label']?.toString() ?? 'Driver',
          latitude: (m['latitude'] as num).toDouble(),
          longitude: (m['longitude'] as num).toDouble(),
          color: AppColors.mediumGrey,
          icon: Icons.directions_car_filled_rounded,
        );
      }).toList();
    } catch (_) {
      // Endpoint doesn't exist yet, or the request failed — fall back below.
      return null;
    }
  }

  static List<RideMapPoint> _simulate(
    double centerLat,
    double centerLng,
    double radiusKm,
    int count,
  ) {
    // Seed by a coarse time bucket (changes every ~6s) so positions drift
    // gently over time instead of teleporting, without needing real state.
    final bucket = DateTime.now().millisecondsSinceEpoch ~/ 6000;
    final points = <RideMapPoint>[];

    for (var i = 0; i < count; i++) {
      final seed = bucket * 97 + i * 733;
      final angle = _pseudoRandom(seed) * 2 * math.pi;
      // Bias toward being close-in (sqrt distribution) so cars cluster
      // believably near the user rather than at a uniform ring.
      final distanceKm = math.sqrt(_pseudoRandom(seed + 17)) * radiusKm;

      final deltaLat = (distanceKm / 111.0) * math.cos(angle);
      final deltaLng =
          (distanceKm / (111.0 * math.cos(centerLat * math.pi / 180))) *
          math.sin(angle);

      points.add(
        RideMapPoint(
          label: 'Driver ${i + 1}',
          latitude: centerLat + deltaLat,
          longitude: centerLng + deltaLng,
          color: AppColors.mediumGrey,
          icon: Icons.directions_car_filled_rounded,
        ),
      );
    }
    return points;
  }

  /// Deterministic 0..1 pseudo-random value from an int seed (no external
  /// randomness dependency, easy to reason about).
  static double _pseudoRandom(int seed) {
    final x = math.sin(seed.toDouble()) * 43758.5453123;
    return x - x.floorToDouble();
  }
}
