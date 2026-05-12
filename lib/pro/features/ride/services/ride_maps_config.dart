import 'package:flutter/services.dart';

class RideMapsConfig {
  static const MethodChannel _channel = MethodChannel(
    'com.edalab.app/maps_config',
  );

  static String? _cachedGoogleMapsApiKey;

  static Future<String?> googleMapsApiKey() async {
    if (_cachedGoogleMapsApiKey != null &&
        _cachedGoogleMapsApiKey!.trim().isNotEmpty) {
      return _cachedGoogleMapsApiKey;
    }

    try {
      final value = await _channel.invokeMethod<String>('getGoogleMapsApiKey');
      final normalized = value?.trim();
      if (normalized == null || normalized.isEmpty) {
        return null;
      }
      _cachedGoogleMapsApiKey = normalized;
      return normalized;
    } catch (_) {
      return null;
    }
  }
}
