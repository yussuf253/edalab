import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/utils/message_launcher.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../services/ride_route_service.dart';
import '../utils/ride_map_launcher.dart';
import '../widgets/ride_route_preview.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic>? rideData;

  const RideTrackingScreen({super.key, required this.rideId, this.rideData});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  Map<String, dynamic>? _rideData;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _rideData = widget.rideData;
    _isLoading = widget.rideData == null;
    _loadRide(forceRefresh: _isLoading);
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadRide(forceRefresh: true);
    });
  }

  Future<void> _loadRide({bool forceRefresh = true}) async {
    try {
      final response = await ApiClient.get(
        '/rides/${widget.rideId}',
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _rideData = Map<String, dynamic>.from(response as Map);
        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.userFacingError(error);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _openDriverChat() async {
    final ride = _rideData;
    final driverAssigned =
        (ride?['driverUserId'] as String?)?.isNotEmpty == true;
    if (ride == null || !driverAssigned) {
      showContactUnavailableSnackBar(context);
      return;
    }

    final pickup = ride['pickup'] as String? ?? context.l10n.t('ride.pickup');
    final destination =
        ride['destination'] as String? ?? context.l10n.t('ride.destination');
    final vehicle =
        ride['vehicle'] as String? ?? context.l10n.t('ride.assigned_vehicle');
    final driverName =
        ride['driverName'] as String? ?? context.l10n.t('ride.assigned_driver');

    await openConversation(
      context,
      moduleType: 'RIDE',
      entityType: 'RIDE',
      entityId: widget.rideId,
      title: driverName,
      subtitle: vehicle,
      accentColor: '#1D9070',
      metadata: {
        'rideId': widget.rideId,
        'vehicle': vehicle,
        'pickup': pickup,
        'destination': destination,
        'driverPhone': ride['driverPhone']?.toString(),
      },
    );
  }

  Future<void> _callDriver() async {
    await launchPhoneCall(context, _rideData?['driverPhone']?.toString());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ride = _rideData;
    final pickup = ride?['pickup'] as String? ?? '123 Main Street';
    final destination =
        ride?['destination'] as String? ?? 'City Mall, Downtown';
    final vehicle = ride?['vehicle'] as String? ?? 'Toyota Camry';
    final driverName =
        ride?['driverName'] as String? ??
        l10n.t('ride.driver_assignment_pending');
    final driverAssigned =
        (ride?['driverUserId'] as String?)?.isNotEmpty == true;
    final driverPhone = ride?['driverPhone'] as String?;
    final trackingData = ride?['trackingData'] is Map
        ? Map<String, dynamic>.from(ride!['trackingData'] as Map)
        : <String, dynamic>{};
    final eta =
        trackingData['durationLabel']?.toString() ??
        ride?['eta'] as String? ??
        '5 min';
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
    final driverPoint = driverAssigned
        ? rideMapPointFromJson(
                trackingData['driver'],
                fallbackLabel: driverName,
                color: AppColors.ride,
                icon: Icons.directions_car_rounded,
              ) ??
              interpolateRideMapPoint(
                from: pickupPoint,
                to: destinationPoint,
                progress: _progressForStatus(ride?['status']?.toString()),
                label: driverName,
              )
        : null;
    final routeDetails = trackingData['routeDetails'] is Map
        ? RideRouteDetails.fromJson(
            Map<String, dynamic>.from(trackingData['routeDetails'] as Map),
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.46,
            width: double.infinity,
            child: Stack(
              children: [
                RideRoutePreview(
                  title: l10n.t('tracking.live_map'),
                  pickup: pickupPoint,
                  destination: destinationPoint,
                  driver: driverPoint,
                  badgeLabel: eta,
                  routePolyline: routeDetails?.polylinePoints,
                  actionLabel: l10n.t('ride.open_map'),
                  onActionTap: () => openRideRouteInMaps(
                    context,
                    pickupLabel: pickup,
                    destinationLabel: destination,
                    pickupPoint: pickupPoint,
                    destinationPoint: destinationPoint,
                  ),
                  height: MediaQuery.of(context).size.height * 0.46,
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/ride');
                      }
                    },
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
                    ? const AppShimmer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBlock(width: 40, height: 4, radius: 2),
                            SizedBox(height: 16),
                            ShimmerBlock(width: 180, height: 24, radius: 8),
                            SizedBox(height: 16),
                            ShimmerBlock(
                              width: double.infinity,
                              height: 82,
                              radius: 16,
                            ),
                            SizedBox(height: 14),
                            ShimmerBlock(
                              width: double.infinity,
                              height: 84,
                              radius: 16,
                            ),
                          ],
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _error!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
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
                                    l10n.t('ride_tracking.arriving'),
                                    style: AppTextStyles.h4,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (ride?['status'] as String? ?? 'on the way')
                                        .replaceAll('_', ' '),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.extraLightGrey,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.rideBg,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.ride,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driverName,
                                          style: AppTextStyles.labelLarge,
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: AppColors.warning,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              driverAssigned
                                                  ? '4.9'
                                                  : 'Pending',
                                              style: AppTextStyles.labelSmall,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                driverAssigned
                                                    ? '$vehicle • ${l10n.t('ride.assigned_driver')}'
                                                    : '$vehicle • ${l10n.t('ride.waiting_for_rider')}',
                                                style: AppTextStyles.caption,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      color: AppColors.success,
                                      size: 12,
                                    ),
                                    Container(
                                      width: 2,
                                      height: 20,
                                      color: AppColors.lightGrey,
                                    ),
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.accent,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pickup,
                                        style: AppTextStyles.labelMedium,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        destination,
                                        style: AppTextStyles.labelMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: driverAssigned
                                        ? _openDriverChat
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: driverAssigned
                                            ? AppColors.white
                                            : AppColors.extraLightGrey,
                                        border: Border.all(
                                          color: AppColors.lightGrey,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.chat_rounded,
                                            color: AppColors.ride,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            l10n.t('profile.contact_us'),
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                                  color: AppColors.ride,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        driverPhone != null &&
                                            driverPhone.isNotEmpty
                                        ? _callDriver
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            driverPhone != null &&
                                                driverPhone.isNotEmpty
                                            ? AppColors.ride
                                            : AppColors.lightGrey,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.call_rounded,
                                            color:
                                                driverPhone != null &&
                                                    driverPhone.isNotEmpty
                                                ? AppColors.white
                                                : AppColors.mediumGrey,
                                            size: 20,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            l10n.t(
                                              'doctor_booking.contact_directly',
                                            ),
                                            style: AppTextStyles.labelMedium
                                                .copyWith(
                                                  color:
                                                      driverPhone != null &&
                                                          driverPhone.isNotEmpty
                                                      ? AppColors.white
                                                      : AppColors.mediumGrey,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _progressForStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'requested':
        return 0.14;
      case 'accepted':
        return 0.28;
      case 'arriving':
        return 0.46;
      case 'in_progress':
        return 0.7;
      case 'completed':
        return 1;
      default:
        return 0.22;
    }
  }
}
