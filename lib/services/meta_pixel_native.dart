import 'dart:async';
import 'package:flutter/services.dart';

class MetaPixelNative {
  static const MethodChannel _channel = MethodChannel(
    'com.edalab.app/meta_pixel',
  );

  /// Sends a custom event to the native Facebook SDK.
  /// `event` – name of the event (e.g. "Purchase").
  /// `parameters` – optional map of key/value pairs.
  Future<void> track(String event, {Map<String, dynamic>? parameters}) async {
    try {
      await _channel.invokeMethod('trackEvent', {
        'event': event,
        'params': parameters ?? <String, dynamic>{},
      });
    } on PlatformException catch (e) {
      // In case native side is not available, log the error.
      print('MetaPixelNative error: ${e.message}');
    }
  }
}
