import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../features/ride/services/ride_route_service.dart';
import '../../../../features/ride/widgets/ride_route_preview.dart';
import '../../../../../core/constants/app_colors.dart';

class ProviderJobLocationMap extends StatefulWidget {
  final LatLng serviceLocation;
  final String customerName;
  final double? distanceKmHint;

  const ProviderJobLocationMap({
    super.key,
    required this.serviceLocation,
    required this.customerName,
    this.distanceKmHint,
  });

  @override
  State<ProviderJobLocationMap> createState() => _ProviderJobLocationMapState();
}

class _ProviderJobLocationMapState extends State<ProviderJobLocationMap> {
  GoogleMapController? _controller;
  LatLng? _providerLocation;
  List<LatLng> _routePolyline = const [];
  bool _loadingRoute = false;

  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
      };

  @override
  void initState() {
    super.initState();
    _bootstrapMap();
  }

  @override
  void didUpdateWidget(covariant ProviderJobLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moved =
        oldWidget.serviceLocation.latitude != widget.serviceLocation.latitude ||
        oldWidget.serviceLocation.longitude != widget.serviceLocation.longitude;
    if (moved) {
      _loadRoutePolyline();
      _fitCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _bootstrapMap() async {
    await _resolveProviderLocation();
    await _loadRoutePolyline();
    _fitCamera();
  }

  Future<void> _resolveProviderLocation() async {
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        final fallback = await Geolocator.getLastKnownPosition();
        if (fallback == null || !mounted) return;
        setState(() {
          _providerLocation = LatLng(fallback.latitude, fallback.longitude);
        });
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null || !mounted) return;
      setState(() {
        _providerLocation = LatLng(position!.latitude, position.longitude);
      });
    } catch (_) {}
  }

  Future<void> _loadRoutePolyline() async {
    final providerPoint = _providerLocation;
    if (providerPoint == null) {
      if (mounted && _routePolyline.isNotEmpty) {
        setState(() => _routePolyline = const []);
      }
      return;
    }

    if (mounted) setState(() => _loadingRoute = true);
    final route = await RideRouteService.computeRoute(
      origin: RideMapPoint(
        label: 'Provider',
        latitude: providerPoint.latitude,
        longitude: providerPoint.longitude,
        color: AppColors.homeServices,
        icon: Icons.person_pin_circle_rounded,
      ),
      destination: RideMapPoint(
        label: widget.customerName,
        latitude: widget.serviceLocation.latitude,
        longitude: widget.serviceLocation.longitude,
        color: AppColors.accent,
        icon: Icons.location_on_rounded,
      ),
    );
    if (!mounted) return;
    setState(() {
      _routePolyline = route?.polylinePoints ?? const [];
      _loadingRoute = false;
    });
  }

  double? _distanceKm() {
    final providerPoint = _providerLocation;
    if (providerPoint == null) return widget.distanceKmHint;
    return _haversineDistanceKm(providerPoint, widget.serviceLocation);
  }

  double _haversineDistanceKm(LatLng start, LatLng end) {
    const earthRadiusKm = 6371.0;
    final latDelta = _toRadians(end.latitude - start.latitude);
    final lngDelta = _toRadians(end.longitude - start.longitude);
    final startLat = _toRadians(start.latitude);
    final endLat = _toRadians(end.latitude);

    final a =
        math.sin(latDelta / 2) * math.sin(latDelta / 2) +
        math.cos(startLat) *
            math.cos(endLat) *
            math.sin(lngDelta / 2) *
            math.sin(lngDelta / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double value) => value * (math.pi / 180);

  Set<Marker> _markers() {
    return <Marker>{
      Marker(
        markerId: const MarkerId('customer-service-location'),
        position: widget.serviceLocation,
        infoWindow: InfoWindow(
          title: widget.customerName,
          snippet: 'Service location',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      if (_providerLocation != null)
        Marker(
          markerId: const MarkerId('provider-current-location'),
          position: _providerLocation!,
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Current provider location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
    };
  }

  Set<Polyline> _polylines() {
    final providerPoint = _providerLocation;
    if (providerPoint == null) return const <Polyline>{};

    final points = _routePolyline.isNotEmpty
        ? _routePolyline
        : <LatLng>[providerPoint, widget.serviceLocation];

    return <Polyline>{
      Polyline(
        polylineId: const PolylineId('provider-to-customer'),
        points: points,
        color: AppColors.homeServices,
        width: 6,
      ),
    };
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    if (controller == null) return;
    final points = <LatLng>[widget.serviceLocation];
    if (_providerLocation != null) {
      points.add(_providerLocation!);
    }

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15.2),
        ),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          70,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final distance = _distanceKm();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.serviceLocation,
                zoom: 15.2,
              ),
              gestureRecognizers: _gestureRecognizers,
              markers: _markers(),
              polylines: _polylines(),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              onMapCreated: (controller) {
                _controller = controller;
                _fitCamera();
              },
            ),
            if (distance != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      color: AppColors.homeServices,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: IconButton(
                  icon: const Icon(Icons.my_location_rounded),
                  color: AppColors.homeServices,
                  onPressed: _fitCamera,
                ),
              ),
            ),
            if (_providerLocation == null || _loadingRoute)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _providerLocation == null
                        ? 'Provider location unavailable'
                        : 'Updating route...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
