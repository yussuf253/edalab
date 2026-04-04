import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class RideMapPoint {
  final String label;
  final double latitude;
  final double longitude;
  final Color color;
  final IconData icon;

  const RideMapPoint({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.icon,
  });
}

Map<String, dynamic> rideMapPointToJson(RideMapPoint point) {
  return {
    'label': point.label,
    'latitude': point.latitude,
    'longitude': point.longitude,
  };
}

RideMapPoint? rideMapPointFromJson(
  dynamic raw, {
  required String fallbackLabel,
  required Color color,
  required IconData icon,
}) {
  if (raw is! Map) return null;
  final data = Map<String, dynamic>.from(raw);
  final latitude = _readDouble(
    data['latitude'] ?? data['lat'] ?? data['pickupLatitude'],
  );
  final longitude = _readDouble(
    data['longitude'] ?? data['lng'] ?? data['pickupLongitude'],
  );
  if (latitude == null || longitude == null) return null;
  return RideMapPoint(
    label: data['label']?.toString() ?? fallbackLabel,
    latitude: latitude,
    longitude: longitude,
    color: color,
    icon: icon,
  );
}

RideMapPoint estimateRideDestinationPoint({
  required RideMapPoint origin,
  required double distanceKm,
  required String label,
  Color color = AppColors.accent,
  IconData icon = Icons.location_on_rounded,
  double bearingDegrees = 54,
}) {
  const earthRadiusKm = 6371.0;
  final angularDistance = distanceKm <= 0 ? 0.02 : distanceKm / earthRadiusKm;
  final bearing = bearingDegrees * math.pi / 180;
  final startLat = origin.latitude * math.pi / 180;
  final startLng = origin.longitude * math.pi / 180;

  final destinationLat = math.asin(
    math.sin(startLat) * math.cos(angularDistance) +
        math.cos(startLat) * math.sin(angularDistance) * math.cos(bearing),
  );
  final destinationLng =
      startLng +
      math.atan2(
        math.sin(bearing) * math.sin(angularDistance) * math.cos(startLat),
        math.cos(angularDistance) -
            math.sin(startLat) * math.sin(destinationLat),
      );

  return RideMapPoint(
    label: label,
    latitude: destinationLat * 180 / math.pi,
    longitude: destinationLng * 180 / math.pi,
    color: color,
    icon: icon,
  );
}

RideMapPoint interpolateRideMapPoint({
  required RideMapPoint from,
  required RideMapPoint to,
  required double progress,
  required String label,
  Color color = AppColors.ride,
  IconData icon = Icons.directions_car_rounded,
}) {
  final clampedProgress = progress.clamp(0.0, 1.0);
  return RideMapPoint(
    label: label,
    latitude: from.latitude + ((to.latitude - from.latitude) * clampedProgress),
    longitude:
        from.longitude + ((to.longitude - from.longitude) * clampedProgress),
    color: color,
    icon: icon,
  );
}

class RideRoutePreview extends StatefulWidget {
  final RideMapPoint? pickup;
  final RideMapPoint? destination;
  final RideMapPoint? driver;
  final String title;
  final String? badgeLabel;
  final String? emptyLabel;
  final VoidCallback? onActionTap;
  final IconData actionIcon;
  final String? actionLabel;
  final double height;
  final bool showMyLocation;
  final bool showTitleChip;
  final bool showLegend;
  final List<LatLng>? routePolyline;
  final IconData? overlayStatusIcon;
  final String? overlayStatusMessage;

  const RideRoutePreview({
    super.key,
    required this.title,
    this.pickup,
    this.destination,
    this.driver,
    this.badgeLabel,
    this.emptyLabel,
    this.onActionTap,
    this.actionIcon = Icons.open_in_new_rounded,
    this.actionLabel,
    this.height = 250,
    this.showMyLocation = false,
    this.showTitleChip = true,
    this.showLegend = true,
    this.routePolyline,
    this.overlayStatusIcon,
    this.overlayStatusMessage,
  });

  @override
  State<RideRoutePreview> createState() => _RideRoutePreviewState();
}

class _RideRoutePreviewState extends State<RideRoutePreview> {
  GoogleMapController? _mapController;
  final Completer<void> _mapReady = Completer<void>();

  @override
  void didUpdateWidget(covariant RideRoutePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pointsChanged(oldWidget, widget)) {
      unawaited(_fitBounds());
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    if (points.isEmpty) {
      return _EmptyRoutePreview(
        title: widget.title,
        emptyLabel: widget.emptyLabel,
        height: widget.height,
        onActionTap: widget.onActionTap,
        actionIcon: widget.actionIcon,
        actionLabel: widget.actionLabel,
      );
    }

    final markers = <Marker>{
      if (widget.pickup != null) _markerForPoint('pickup', widget.pickup!),
      if (widget.destination != null)
        _markerForPoint('destination', widget.destination!),
      if (widget.driver != null) _markerForPoint('driver', widget.driver!),
    };

    final polylines = <Polyline>{
      if (widget.pickup != null && widget.destination != null)
        Polyline(
          polylineId: const PolylineId('route'),
          points:
              widget.routePolyline != null && widget.routePolyline!.isNotEmpty
              ? widget.routePolyline!
              : [
                  LatLng(widget.pickup!.latitude, widget.pickup!.longitude),
                  LatLng(
                    (widget.pickup!.latitude + widget.destination!.latitude) /
                        2,
                    (widget.pickup!.longitude + widget.destination!.longitude) /
                        2,
                  ),
                  LatLng(
                    widget.destination!.latitude,
                    widget.destination!.longitude,
                  ),
                ],
          color: AppColors.ride,
          width: 6,
        ),
      if (widget.driver != null && widget.destination != null)
        Polyline(
          polylineId: const PolylineId('driver-to-destination'),
          points: [
            LatLng(widget.driver!.latitude, widget.driver!.longitude),
            LatLng(widget.destination!.latitude, widget.destination!.longitude),
          ],
          color: AppColors.warning,
          width: 4,
          patterns: [PatternItem.dot, PatternItem.gap(8)],
        ),
    };

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppSpacing.shadowMd,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _cameraForPoints(points),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: widget.showMyLocation,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              tiltGesturesEnabled: false,
              rotateGesturesEnabled: false,
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
              onMapCreated: (controller) {
                _mapController = controller;
                if (!_mapReady.isCompleted) {
                  _mapReady.complete();
                }
                unawaited(_fitBounds());
              },
            ),
          ),
          if (widget.showTitleChip)
            Positioned(
              top: 14,
              left: 14,
              child: _MapChip(
                icon: Icons.map_outlined,
                label: widget.title,
                backgroundColor: Colors.white.withValues(alpha: 0.94),
                foregroundColor: AppColors.ride,
              ),
            ),
          if (widget.badgeLabel != null && widget.badgeLabel!.trim().isNotEmpty)
            Positioned(
              top: 14,
              right: 14,
              child: _MapChip(
                icon: Icons.timer_rounded,
                label: widget.badgeLabel!,
                backgroundColor: AppColors.ride,
                foregroundColor: AppColors.white,
              ),
            ),
          if (widget.overlayStatusMessage != null &&
              widget.overlayStatusMessage!.trim().isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppSpacing.shadowMd,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.overlayStatusIcon ??
                              Icons.route_rounded,
                          size: 18,
                          color: AppColors.ride,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.overlayStatusMessage!,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              children: [
                if (widget.showLegend)
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.pickup != null)
                          _LegendPill(
                            color: widget.pickup!.color,
                            label: widget.pickup!.label,
                          ),
                        if (widget.destination != null)
                          _LegendPill(
                            color: widget.destination!.color,
                            label: widget.destination!.label,
                          ),
                        if (widget.driver != null)
                          _LegendPill(
                            color: widget.driver!.color,
                            label: widget.driver!.label,
                          ),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                if (widget.onActionTap != null) const SizedBox(width: 10),
                if (widget.onActionTap != null)
                  _ActionButton(
                    icon: widget.actionIcon,
                    label: widget.actionLabel,
                    onTap: widget.onActionTap!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<RideMapPoint> get _points {
    final points = <RideMapPoint>[];
    if (widget.pickup != null) points.add(widget.pickup!);
    if (widget.destination != null) points.add(widget.destination!);
    if (widget.driver != null) points.add(widget.driver!);
    return points;
  }

  bool _pointsChanged(RideRoutePreview oldWidget, RideRoutePreview newWidget) {
    bool same(RideMapPoint? a, RideMapPoint? b) {
      return a?.label == b?.label &&
          a?.latitude == b?.latitude &&
          a?.longitude == b?.longitude;
    }

    return !same(oldWidget.pickup, newWidget.pickup) ||
        !same(oldWidget.destination, newWidget.destination) ||
        !same(oldWidget.driver, newWidget.driver);
  }

  Marker _markerForPoint(String markerId, RideMapPoint point) {
    final hue = _hueForColor(point.color);
    return Marker(
      markerId: MarkerId(markerId),
      position: LatLng(point.latitude, point.longitude),
      infoWindow: InfoWindow(title: point.label),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
    );
  }

  CameraPosition _cameraForPoints(List<RideMapPoint> points) {
    if (points.length == 1) {
      return CameraPosition(
        target: LatLng(points.first.latitude, points.first.longitude),
        zoom: 16.4,
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final maxSpan = math.max(maxLat - minLat, maxLng - minLng);
    final zoom = maxSpan < 0.02
        ? 15.2
        : maxSpan < 0.05
        ? 14.1
        : maxSpan < 0.12
        ? 12.9
        : 11.3;
    return CameraPosition(target: center, zoom: zoom);
  }

  Future<void> _fitBounds() async {
    final points = _points;
    if (points.isEmpty) return;
    await _mapReady.future;
    if (!mounted || _mapController == null) return;
    if (points.length == 1) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_cameraForPoints(points)),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 64),
    );
  }

  double _hueForColor(Color color) {
    if (color == AppColors.success) return BitmapDescriptor.hueGreen;
    if (color == AppColors.accent) return BitmapDescriptor.hueRed;
    if (color == AppColors.warning) return BitmapDescriptor.hueYellow;
    return BitmapDescriptor.hueAzure;
  }
}

class _EmptyRoutePreview extends StatelessWidget {
  final String title;
  final String? emptyLabel;
  final VoidCallback? onActionTap;
  final IconData actionIcon;
  final String? actionLabel;
  final double height;

  const _EmptyRoutePreview({
    required this.title,
    required this.emptyLabel,
    required this.height,
    required this.onActionTap,
    required this.actionIcon,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5F7F0), Color(0xFFF7FCFA)],
        ),
        boxShadow: AppSpacing.shadowMd,
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                emptyLabel ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mediumGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _MapChip(
              icon: Icons.map_outlined,
              label: title,
              backgroundColor: Colors.white.withValues(alpha: 0.94),
              foregroundColor: AppColors.ride,
            ),
          ),
          if (onActionTap != null)
            Positioned(
              right: 14,
              bottom: 14,
              child: _ActionButton(
                icon: actionIcon,
                label: actionLabel,
                onTap: onActionTap!,
              ),
            ),
        ],
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _MapChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label == null ? 11 : 12,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.ride),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label!,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.ride),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
