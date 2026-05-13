import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserLocationData {
  const UserLocationData({
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.subtitle,
  });

  final double latitude;
  final double longitude;
  final String title;
  final String subtitle;
}

class UserLocationProvider extends ChangeNotifier {
  UserLocationData? _location;
  bool _isLoading = false;
  bool _hasPermission = false;
  bool _servicesEnabled = true;

  UserLocationData? get location => _location;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  bool get servicesEnabled => _servicesEnabled;

  Future<bool> ensureCurrentLocation({bool requestPermission = true}) async {
    if (_isLoading) {
      return _location != null;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final enabled = await Geolocator.isLocationServiceEnabled();
      _servicesEnabled = enabled;
      if (!enabled) {
        _hasPermission = false;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }

      final granted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      _hasPermission = granted;

      if (!granted) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final resolved = await _resolveAddress(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      _location = UserLocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        title: resolved?.title ?? 'Current Location',
        subtitle:
            resolved?.subtitle ??
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isLoading = false;
      notifyListeners();
      return _location != null;
    }
  }

  Future<_ResolvedAddress?> _resolveAddress({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'jsonv2',
        'zoom': '18',
        'addressdetails': '1',
      });

      final response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'eDalab/1.0 (Shared location reverse geocoding)',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return null;

      final map = Map<String, dynamic>.from(decoded);
      final address = map['address'];
      if (address is! Map) return null;

      final addressMap = Map<String, dynamic>.from(address);
      final area = _firstNonEmpty([
        addressMap['suburb'],
        addressMap['neighbourhood'],
        addressMap['road'],
        addressMap['quarter'],
      ]);
      final city = _firstNonEmpty([
        addressMap['city'],
        addressMap['town'],
        addressMap['village'],
        addressMap['municipality'],
        addressMap['state'],
      ]);

      final title = _firstNonEmpty([area, city]) ?? 'Current Location';
      final subtitle = _firstNonEmpty([
        [area, city].whereType<String>().join(', ').trim(),
        map['display_name'],
      ]);

      if (subtitle == null || subtitle.isEmpty) {
        return _ResolvedAddress(title: title, subtitle: title);
      }

      return _ResolvedAddress(title: title, subtitle: subtitle);
    } catch (_) {
      return null;
    }
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }
}

class _ResolvedAddress {
  const _ResolvedAddress({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
