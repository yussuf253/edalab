import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builds Google Maps marker icons from a real top-down car photo/illustration
/// (`assets/icons/car_marker.png`), tinted to the app's own colors at
/// render time — rather than a hand-drawn shape or an icon-font glyph, which
/// don't read clearly as "a car" at small marker sizes.
///
/// Source asset: a top-down car silhouette (MIT-licensed, from
/// SURYAKANTSHARMA/UberCarAnimation on GitHub — the same visual language
/// Uber-style ride apps use for their live map markers).
class RideMapIcons {
  RideMapIcons._();

  static const String _assetPath = 'assets/icons/car_marker.png';

  static final Map<String, BitmapDescriptor> _cache = {};
  static Future<ui.Image>? _sourceImageFuture;

  static Future<ui.Image> _loadSourceImage() {
    return _sourceImageFuture ??= () async {
      final data = await rootBundle.load(_assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final frame = await codec.getNextFrame();
      return frame.image;
    }();
  }

  /// [muted] renders a softer, lower-contrast version — used for ambient
  /// "nearby drivers" markers so they don't visually compete with the
  /// pickup/destination pins or the assigned-driver marker.
  static Future<BitmapDescriptor> car({
    required Color color,
    double logicalSize = 72,
    bool muted = false,
  }) async {
    final key = '${color.toString()}_${logicalSize}_$muted';
    final cached = _cache[key];
    if (cached != null) return cached;

    final source = await _loadSourceImage();
    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

    // Respect the source's natural proportions (taller than wide, like a
    // real car seen from above) instead of squashing it into a square.
    final aspect = source.width / source.height;
    final targetHeight = logicalSize * dpr;
    final targetWidth = targetHeight * aspect;
    final canvasSize = targetHeight + (dpr * 10); // room for the shadow

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasSize, canvasSize),
    );
    final srcRect = Rect.fromLTWH(
      0,
      0,
      source.width.toDouble(),
      source.height.toDouble(),
    );
    final dstRect = Rect.fromCenter(
      center: Offset(canvasSize / 2, canvasSize / 2),
      width: targetWidth,
      height: targetHeight,
    );

    if (!muted) {
      final shadowPaint = Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.black.withValues(alpha: 0.32),
          BlendMode.srcIn,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawImageRect(
        source,
        srcRect,
        dstRect.translate(0, dpr * 2),
        shadowPaint,
      );
    }

    final tintPaint = Paint()
      ..colorFilter = ColorFilter.mode(
        muted ? color.withValues(alpha: 0.65) : color,
        BlendMode.srcIn,
      )
      ..filterQuality = FilterQuality.high;
    canvas.drawImageRect(source, srcRect, dstRect, tintPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      canvasSize.toInt(),
      canvasSize.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    _cache[key] = descriptor;
    return descriptor;
  }
}

/// Initial great-circle bearing from (fromLat, fromLng) to (toLat, toLng),
/// in degrees, where 0 = north, 90 = east. Used to point a marker in its
/// direction of travel.
double bearingBetweenLatLng(
  double fromLat,
  double fromLng,
  double toLat,
  double toLng,
) {
  final lat1 = fromLat * math.pi / 180;
  final lat2 = toLat * math.pi / 180;
  final dLng = (toLng - fromLng) * math.pi / 180;

  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  final bearingDeg = math.atan2(y, x) * 180 / math.pi;
  return (bearingDeg + 360) % 360;
}
