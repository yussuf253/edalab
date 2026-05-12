import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../features/ride/services/ride_route_service.dart';
import '../../../../features/ride/utils/ride_map_launcher.dart';
import '../../../../features/ride/widgets/ride_route_preview.dart';
import '../../../core/utils/pro_message_launcher.dart';
import '../../../core/widgets/swipeable_button.dart';

class RiderActiveTripScreen extends StatefulWidget {
  final String rideId;
  final String userId;

  const RiderActiveTripScreen({
    super.key,
    required this.rideId,
    required this.userId,
  });

  @override
  State<RiderActiveTripScreen> createState() => _RiderActiveTripScreenState();
}

class _RiderActiveTripScreenState extends State<RiderActiveTripScreen> {
  Map<String, dynamic>? _ride;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadRide();
  }

  Future<void> _loadRide() async {
    try {
      final response = await ApiClient.get('/rides/${widget.rideId}');
      if (!mounted) return;
      setState(() {
        _ride = Map<String, dynamic>.from(response as Map);
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  double _progressForStatus(String? rawStatus) {
    switch (rawStatus?.toUpperCase()) {
      case 'COMPLETED':
        return 1;
      case 'IN_PROGRESS':
        return 0.58;
      case 'DRIVER_ARRIVING':
        return 0.18;
      case 'ACCEPTED':
        return 0.08;
      default:
        return 0.12;
    }
  }

  String _actionLabel(String status) {
    switch (status) {
      case 'DRIVER_ARRIVING':
        return l10n.swipeToStartTrip;
      case 'IN_PROGRESS':
        return l10n.swipeToCompleteTrip;
      case 'COMPLETED':
        return l10n.tripCompleted;
      default:
        return l10n.swipeToArrive;
    }
  }

  String _nextStatus(String status) {
    switch (status) {
      case 'DRIVER_ARRIVING':
        return 'IN_PROGRESS';
      case 'IN_PROGRESS':
        return 'COMPLETED';
      case 'COMPLETED':
        return 'COMPLETED';
      default:
        return 'DRIVER_ARRIVING';
    }
  }

  Future<void> _advanceStatus() async {
    final ride = _ride;
    if (_isUpdating || ride == null) return;
    final currentStatus =
        ride['status']?.toString().toUpperCase() ?? 'ACCEPTED';
    final nextStatus = _nextStatus(currentStatus);
    if (nextStatus == currentStatus) return;

    setState(() => _isUpdating = true);
    try {
      await ApiClient.post('/pro/${widget.userId}/ride-status', {
        'rideId': widget.rideId,
        'status': nextStatus,
      });
      await _loadRide();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.rideStatusUpdated(_statusLabel(nextStatus)),
          ),
        ),
      );
      if (nextStatus == 'COMPLETED') {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotUpdateRide(error.toString()))));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return l10n.pending;
      case 'ACCEPTED':
        return l10n.approved;
      case 'DRIVER_ARRIVING':
        return l10n.upcoming;
      case 'IN_PROGRESS':
        return l10n.inProgress;
      case 'COMPLETED':
        return l10n.completedLabel;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final pickup = ride?['pickup']?.toString() ?? l10n.pickupLocationFallback;
    final destination = ride?['destination']?.toString() ?? l10n.dropoffLocationFallback;
    final driverName = ride?['driverName']?.toString() ?? l10n.assignedRiderFallback;
    final vehicle = ride?['vehicle']?.toString() ?? l10n.vehicleLabel;
    final status = ride?['status']?.toString().toUpperCase() ?? 'ACCEPTED';
    final passengerName = ride?['customerName']?.toString() ?? l10n.passengerLabel;
    final passengerPhone = ride?['customerPhone']?.toString() ?? '';
    final customerUserId = ride?['userId']?.toString() ?? '';
    final trackingData = ride?['trackingData'] is Map
        ? Map<String, dynamic>.from(ride!['trackingData'] as Map)
        : <String, dynamic>{};
    final eta =
        trackingData['durationLabel']?.toString() ??
        ride?['eta']?.toString() ??
        l10n.etaUnavailable;
    final fare = (ride?['total'] as num?)?.toDouble();
    final pickupPoint =
        rideMapPointFromJson(
          trackingData['pickup'],
          fallbackLabel: pickup,
          color: AppColors.success,
          icon: Icons.my_location_rounded,
        ) ??
        const RideMapPoint(
          label: 'Pickup',
          latitude: 11.5886,
          longitude: 43.1457,
          color: AppColors.success,
          icon: Icons.my_location_rounded,
        );
    final destinationPoint =
        rideMapPointFromJson(
          trackingData['destination'],
          fallbackLabel: destination,
          color: AppColors.accent,
          icon: Icons.location_on_rounded,
        ) ??
        estimateRideDestinationPoint(
          origin: pickupPoint,
          distanceKm:
              (trackingData['distance'] as num?)?.toDouble() ??
              (ride?['distanceKm'] as num?)?.toDouble() ??
              5.2,
          label: destination,
        );
    final driverPoint = interpolateRideMapPoint(
      from: pickupPoint,
      to: destinationPoint,
      progress: _progressForStatus(status),
      label: driverName,
    );
    final routeDetails = trackingData['routeDetails'] is Map
        ? RideRouteDetails.fromJson(
            Map<String, dynamic>.from(trackingData['routeDetails'] as Map),
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.46,
                width: double.infinity,
                child: RideRoutePreview(
                  title: 'Trip map',
                  pickup: pickupPoint,
                  destination: destinationPoint,
                  driver: _isLoading ? null : driverPoint,
                  badgeLabel: _isLoading ? null : eta,
                  routePolyline: routeDetails?.polylinePoints,
                  overlayStatusIcon: _isLoading
                      ? Icons.route_rounded
                      : _error != null
                      ? Icons.error_outline_rounded
                      : null,
                  overlayStatusMessage: _isLoading
                      ? l10n.loadingAssignedTrip
                      : _error,
                  actionLabel: l10n.openMapAction,
                  onActionTap: () => openRideRouteInMaps(
                    context,
                    pickupLabel: pickup,
                    destinationLabel: destination,
                    pickupPoint: pickupPoint,
                    destinationPoint: destinationPoint,
                  ),
                  height: MediaQuery.of(context).size.height * 0.46,
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrey,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        passengerName,
                                        style: AppTextStyles.h4,
                                      ),
                                    ),
                                    if (fare != null)
                                      Text(
                                        '\$${fare.toStringAsFixed(2)}',
                                        style: AppTextStyles.h4.copyWith(
                                          color: AppColors.ride,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.rideBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' '),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.ride,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.extraLightGrey,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.my_location_rounded,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              pickup,
                                              style: AppTextStyles.labelMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            color: AppColors.accent,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              destination,
                                              style: AppTextStyles.labelMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.extraLightGrey,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.rideBg,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.directions_car_rounded,
                                          color: AppColors.ride,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              vehicle,
                                              style: AppTextStyles.labelLarge,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              l10n.etaLabel(eta),
                                              style: AppTextStyles.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: passengerPhone.isEmpty
                                            ? null
                                            : () => launchPhoneCall(
                                                context,
                                                passengerPhone,
                                              ),
                                        icon: const Icon(Icons.call_outlined),
                                        label: Text(l10n.callPassengerAction),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: customerUserId.isEmpty
                                            ? null
                                            : () => openProConversation(
                                                context,
                                                customerUserId: customerUserId,
                                                participantUserId: widget.userId,
                                                moduleType: 'RIDE',
                                                entityType: 'RIDE',
                                                entityId: widget.rideId,
                                                title: passengerName,
                                                subtitle: l10n.rideInProgressSupport,
                                                accentColor: '#1D9070',
                                                metadata: {
                                                  'rideId': widget.rideId,
                                                  'passengerPhone': passengerPhone,
                                                  'destination': destination,
                                                },
                                              ),
                                        icon: const Icon(Icons.chat_bubble_outline),
                                        label: Text(l10n.messageAction),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                SwipeableButton(
                                  label: _isUpdating
                                      ? l10n.updating
                                      : _actionLabel(status),
                                  baseColor: AppColors.ride,
                                  onSwipe: _advanceStatus,
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppSpacing.shadowMd,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
