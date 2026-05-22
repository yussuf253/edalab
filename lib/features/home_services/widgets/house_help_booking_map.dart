import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/home_service_model.dart';

class HouseHelpBookingMap extends StatefulWidget {
  final double selectedLatitude;
  final double selectedLongitude;
  final List<HomeServiceProviderModel> providers;
  final String? selectedProviderId;
  final String userDisplayName;

  const HouseHelpBookingMap({
    super.key,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.providers,
    required this.userDisplayName,
    this.selectedProviderId,
  });

  @override
  State<HouseHelpBookingMap> createState() => _HouseHelpBookingMapState();
}

class _HouseHelpBookingMapState extends State<HouseHelpBookingMap> {
  GoogleMapController? _controller;
  String _lastMapFitSignature = '';
  static final Set<Factory<OneSequenceGestureRecognizer>> _gestureRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{
        Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
      };

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  LatLng? _providerZoneCenter(HomeServiceProviderModel provider) {
    final lat = _toDouble(provider.serviceZone['centerLatitude']);
    final lng = _toDouble(provider.serviceZone['centerLongitude']);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('user-address'),
        position: LatLng(widget.selectedLatitude, widget.selectedLongitude),
        zIndexInt: 3,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: widget.userDisplayName,
          snippet: 'Service location',
        ),
      ),
    };

    for (final provider in widget.providers) {
      final center = _providerZoneCenter(provider);
      if (center == null) continue;
      final isSelected = widget.selectedProviderId == provider.id;
      final distance = provider.distanceKm;
      markers.add(
        Marker(
          markerId: MarkerId('provider-zone-${provider.id}'),
          position: center,
          zIndexInt: isSelected ? 2 : 1,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: provider.name,
            snippet: distance == null
                ? provider.title
                : '${distance.toStringAsFixed(2)} km',
          ),
        ),
      );
    }
    return markers;
  }

  Set<Circle> _buildCircles() {
    return {
      Circle(
        circleId: const CircleId('user-search-area'),
        center: LatLng(widget.selectedLatitude, widget.selectedLongitude),
        radius: 1000,
        fillColor: AppColors.homeServices.withValues(alpha: 0.08),
        strokeColor: AppColors.homeServices.withValues(alpha: 0.40),
        strokeWidth: 2,
      ),
    };
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    if (controller == null) return;

    final points = <LatLng>[
      LatLng(widget.selectedLatitude, widget.selectedLongitude),
    ];
    for (final provider in widget.providers) {
      final center = _providerZoneCenter(provider);
      if (center != null) points.add(center);
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
          72,
        ),
      );
    } catch (_) {}
  }

  void _scheduleCameraFit() {
    final providersSignature = widget.providers
        .map((provider) => provider.id)
        .join('|');
    final signature =
        '${widget.selectedLatitude}|${widget.selectedLongitude}|${widget.selectedProviderId}|$providersSignature';
    if (signature == _lastMapFitSignature) return;
    _lastMapFitSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitCamera();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scheduleCameraFit();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 218,
        width: double.infinity,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.selectedLatitude,
                  widget.selectedLongitude,
                ),
                zoom: 15.2,
              ),
              gestureRecognizers: _gestureRecognizers,
              markers: _buildMarkers(),
              circles: _buildCircles(),
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
              liteModeEnabled: false,
              onMapCreated: (controller) {
                _controller = controller;
                _fitCamera();
              },
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _MapCircleButton(
                icon: Icons.my_location_rounded,
                onPressed: _fitCamera,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapCircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        icon: Icon(icon),
        color: AppColors.homeServices,
        onPressed: onPressed,
      ),
    );
  }
}
