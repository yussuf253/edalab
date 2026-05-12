import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../services/ride_maps_config.dart';
import '../widgets/ride_route_preview.dart';

class RideRouteDetails {
  final double distanceKm;
  final int durationMinutes;
  final String durationLabel;
  final List<LatLng> polylinePoints;

  const RideRouteDetails({
    required this.distanceKm,
    required this.durationMinutes,
    required this.durationLabel,
    required this.polylinePoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'durationLabel': durationLabel,
      'polylinePoints': polylinePoints
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(),
    };
  }

  factory RideRouteDetails.fromJson(Map<String, dynamic> json) {
    final rawPolyline = json['polylinePoints'] as List?;
    return RideRouteDetails(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      durationLabel: json['durationLabel']?.toString() ?? '0 min',
      polylinePoints: rawPolyline == null
          ? const []
          : rawPolyline
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .map(
                  (item) => LatLng(
                    (item['latitude'] as num?)?.toDouble() ?? 0,
                    (item['longitude'] as num?)?.toDouble() ?? 0,
                  ),
                )
                .toList(),
    );
  }
}

class RideRouteService {
  static Future<RideRouteDetails?> computeRoute({
    required RideMapPoint origin,
    required RideMapPoint destination,
  }) async {
    final apiKey = await RideMapsConfig.googleMapsApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      final googleRoute = await _computeGoogleRoute(
        origin: origin,
        destination: destination,
        apiKey: apiKey,
      );
      if (googleRoute != null) {
        return googleRoute;
      }
    }

    return _computeOsrmRoute(origin: origin, destination: destination);
  }

  static Future<RideRouteDetails?> _computeGoogleRoute({
    required RideMapPoint origin,
    required RideMapPoint destination,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes'),
        headers: const {
          'Content-Type': 'application/json',
          'X-Goog-FieldMask':
              'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline',
        }..addAll({'X-Goog-Api-Key': apiKey}),
        body: jsonEncode({
          'origin': {
            'location': {
              'latLng': {
                'latitude': origin.latitude,
                'longitude': origin.longitude,
              },
            },
          },
          'destination': {
            'location': {
              'latLng': {
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              },
            },
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'computeAlternativeRoutes': false,
          'languageCode': 'en-US',
          'units': 'METRIC',
        }),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route = routes.first;
      if (route is! Map) return null;
      final routeMap = Map<String, dynamic>.from(route);

      final distanceMeters =
          (routeMap['distanceMeters'] as num?)?.toDouble() ?? 0;
      final duration = _parseDuration(routeMap['duration']?.toString() ?? '0s');
      final encodedPolyline =
          (routeMap['polyline'] as Map?)?['encodedPolyline']?.toString() ?? '';

      return RideRouteDetails(
        distanceKm: distanceMeters / 1000,
        durationMinutes: duration.inMinutes,
        durationLabel: _formatDuration(duration),
        polylinePoints: encodedPolyline.isEmpty
            ? [
                LatLng(origin.latitude, origin.longitude),
                LatLng(destination.latitude, destination.longitude),
              ]
            : _decodePolyline(encodedPolyline),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<RideRouteDetails?> _computeOsrmRoute({
    required RideMapPoint origin,
    required RideMapPoint destination,
  }) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=polyline&steps=false',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;
      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route = routes.first;
      if (route is! Map) return null;
      final routeMap = Map<String, dynamic>.from(route);
      final distanceMeters =
          (routeMap['distance'] as num?)?.toDouble() ?? 0;
      final durationSeconds =
          (routeMap['duration'] as num?)?.toDouble() ?? 0;
      final encodedPolyline = routeMap['geometry']?.toString() ?? '';
      final duration = Duration(seconds: durationSeconds.round());

      return RideRouteDetails(
        distanceKm: distanceMeters / 1000,
        durationMinutes: duration.inMinutes,
        durationLabel: _formatDuration(duration),
        polylinePoints: encodedPolyline.isEmpty
            ? [
                LatLng(origin.latitude, origin.longitude),
                LatLng(destination.latitude, destination.longitude),
              ]
            : _decodePolyline(encodedPolyline),
      );
    } catch (_) {
      return null;
    }
  }

  static Duration _parseDuration(String value) {
    final normalized = value.trim().replaceAll('s', '');
    final seconds = double.tryParse(normalized) ?? 0;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  static String _formatDuration(Duration duration) {
    if (duration.inMinutes <= 0) return '1 min';
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes == 0) {
        return '$hours hr';
      }
      return '$hours hr $minutes min';
    }
    return '${duration.inMinutes} min';
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += deltaLat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20 && index < encoded.length);
      final deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += deltaLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}
