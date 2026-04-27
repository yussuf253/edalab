import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/ride_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/auth_gate.dart';
import '../../../core/widgets/app_button.dart';
import '../services/ride_route_service.dart';
import '../utils/ride_map_launcher.dart';
import '../widgets/ride_route_preview.dart';

class RideBookingSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;

  const RideBookingSummaryScreen({super.key, required this.bookingData});

  @override
  State<RideBookingSummaryScreen> createState() =>
      _RideBookingSummaryScreenState();
}

class _RideBookingSummaryScreenState extends State<RideBookingSummaryScreen> {
  bool _isSubmitting = false;

  Map<String, dynamic> get _data => widget.bookingData;

  String? _normalizedOptionalId(String key) {
    final raw = _data[key];
    if (raw == null) return null;
    final value = raw.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') {
      return null;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedCategory = _data['selectedCategory'] as RideCategory?;
    final payment = _data['payment']?.toString() ?? l10n.t('common.cash');
    final pickup = _data['pickup']?.toString() ?? l10n.t('ride.pickup');
    final destination =
        _data['destination']?.toString() ?? l10n.t('ride.destination');
    final pickupPoint =
        rideMapPointFromJson(
          _data['pickupPoint'],
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
          _data['destinationPoint'],
          fallbackLabel: destination,
          color: AppColors.accent,
          icon: Icons.location_on_rounded,
        ) ??
        estimateRideDestinationPoint(
          origin: pickupPoint,
          distanceKm: (_data['routeDistance'] as num?)?.toDouble() ?? 5.2,
          label: destination,
        );
    final routeDetails = _data['routeDetails'] is Map
        ? RideRouteDetails.fromJson(
            Map<String, dynamic>.from(_data['routeDetails'] as Map),
          )
        : null;
    final routeDistance =
        routeDetails?.distanceKm ??
        (_data['routeDistance'] as num?)?.toDouble() ??
        5.2;
    final routeDurationLabel =
        routeDetails?.durationLabel ??
        _data['routeDurationLabel']?.toString() ??
        l10n.t('ride.eta_unavailable');
    final estimatedFare =
        (_data['estimatedRidePrice'] as num?)?.toDouble() ??
        ((selectedCategory?.basePrice ?? 0) +
            ((selectedCategory?.pricePerMile ?? 0) * routeDistance));
    final tax = estimatedFare * 0.08;
    final total = estimatedFare + tax;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('ride_summary.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RideRoutePreview(
              title: l10n.t('tracking.live_map'),
              pickup: pickupPoint,
              destination: destinationPoint,
              badgeLabel: routeDurationLabel,
              showTitleChip: false,
              showLegend: false,
              routePolyline: routeDetails?.polylinePoints,
              actionLabel: l10n.t('ride.open_map'),
              onActionTap: () => openRideRouteInMaps(
                context,
                pickupLabel: pickup,
                destinationLabel: destination,
                pickupPoint: pickupPoint,
                destinationPoint: destinationPoint,
              ),
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('ride_summary.trip_details'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 14),
                  _SummaryLine(
                    icon: Icons.my_location_rounded,
                    label: l10n.t('ride.select_pickup'),
                    value: pickup,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  _SummaryLine(
                    icon: Icons.location_on_rounded,
                    label: l10n.t('ride.choose_destination'),
                    value: destination,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 12),
                  _SummaryLine(
                    icon: Icons.route_rounded,
                    label: l10n.t(
                      'ride_booking.route_summary',
                      params: {
                        'distance': routeDistance.toStringAsFixed(1),
                        'duration': routeDurationLabel,
                      },
                    ),
                    value: '',
                    color: AppColors.ride,
                    hideTrailing: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('ride_summary.ride_details'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 14),
                  _SummaryRow(
                    l10n.t('ride_summary.vehicle'),
                    selectedCategory?.name ?? l10n.t('module.ride'),
                  ),
                  _SummaryRow(
                    l10n.t('ride_summary.capacity'),
                    l10n.t(
                      'ride.seat_count',
                      params: {'count': '${selectedCategory?.capacity ?? 0}'},
                    ),
                  ),
                  _SummaryRow(l10n.t('ride_summary.payment_method'), payment),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SummaryCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('ride_summary.fare_breakdown'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 14),
                  _SummaryRow(
                    l10n.t('ride_summary.base_fare'),
                    'DJF ${estimatedFare.toStringAsFixed(2)}',
                  ),
                  _SummaryRow(
                    l10n.t('ride_summary.tax'),
                    'DJF ${tax.toStringAsFixed(2)}',
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    l10n.t('ride_summary.total'),
                    'DJF ${total.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SafeArea(
              top: false,
              child: AppButton(
                text: l10n.t(
                  'ride_booking.confirm',
                  params: {'amount': total.toStringAsFixed(2)},
                ),
                color: AppColors.ride,
                isLoading: _isSubmitting,
                onPressed: () {
                  if (_isSubmitting) return;
                  _submitBooking(total);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking(double total) async {
    final l10n = context.l10n;
    final auth = context.read<AuthProvider>();
    final allowed = await requireLoggedIn(
      context,
      message: l10n.t('ride_booking.login_required'),
    );
    if (!mounted || !allowed) return;

    final selectedCategory = _data['selectedCategory'] as RideCategory?;
    if (selectedCategory == null) {
      AnalyticsService.instance.track(
        AnalyticsEvents.checkoutValidationFailed,
        properties: {'module_type': 'ride', 'reason': 'missing_ride_category'},
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final estimatedFare =
          (_data['estimatedRidePrice'] as num?)?.toDouble() ?? total;
      final routeDistance = (_data['routeDistance'] as num?)?.toDouble() ?? 0;
      final routeDurationLabel =
          _data['routeDurationLabel']?.toString() ??
          l10n.t('ride.eta_unavailable');
      final pickup = _data['pickup']?.toString() ?? l10n.t('ride.pickup');
      final destination =
          _data['destination']?.toString() ?? l10n.t('ride.destination');
      final payment = _data['payment']?.toString() ?? l10n.t('common.cash');
      AnalyticsService.instance.track(
        AnalyticsEvents.checkoutPlaceOrderTapped,
        properties: {
          'module_type': 'ride',
          'ride_category_id': selectedCategory.id,
          'ride_category': selectedCategory.name,
          'payment': payment,
          'total': total,
        },
      );
      final routeDetails = _data['routeDetails'] is Map
          ? RideRouteDetails.fromJson(
              Map<String, dynamic>.from(_data['routeDetails'] as Map),
            )
          : null;
      final pickupPoint =
          rideMapPointFromJson(
            _data['pickupPoint'],
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
            _data['destinationPoint'],
            fallbackLabel: destination,
            color: AppColors.accent,
            icon: Icons.location_on_rounded,
          ) ??
          estimateRideDestinationPoint(
            origin: pickupPoint,
            distanceKm: routeDistance,
            label: destination,
          );

      final tax = estimatedFare * 0.08;
      final payload = <String, dynamic>{
        'userId': auth.user!.id,
        'rideCategoryId': selectedCategory.id,
        'pickupLabel': pickup,
        'dropoffLabel': destination,
        'distanceKm': routeDistance,
        'estimatedFare': estimatedFare,
        'tax': tax,
        'total': total,
        'etaLabel': routeDurationLabel,
        'vehicleName': selectedCategory.name,
        'trackingData': {
          'payment': payment,
          'distance': routeDistance,
          'durationLabel': routeDurationLabel,
          'pickup': rideMapPointToJson(pickupPoint),
          'destination': rideMapPointToJson(destinationPoint),
          if (routeDetails != null) 'routeDetails': routeDetails.toJson(),
        },
      };
      final pickupAddressId = _normalizedOptionalId('pickupAddressId');
      final dropoffAddressId = _normalizedOptionalId('dropoffAddressId');
      if (pickupAddressId != null) {
        payload['pickupAddressId'] = pickupAddressId;
      }
      if (dropoffAddressId != null) {
        payload['dropoffAddressId'] = dropoffAddressId;
      }

      final response = await ApiClient.post('/rides', payload);

      if (!mounted) return;
      final ride = Map<String, dynamic>.from(response as Map);
      AnalyticsService.instance.track(
        AnalyticsEvents.checkoutCompleted,
        properties: {
          'module_type': 'ride',
          'order_id': ride['id']?.toString(),
          'ride_category_id': selectedCategory.id,
          'ride_category': selectedCategory.name,
          'distance_km': routeDistance,
          'subtotal': estimatedFare,
          'tax': tax,
          'total': total,
        },
      );
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('ride_booking.success')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.go('/ride/tracking/${ride['id']}', extra: ride);
    } catch (e) {
      AnalyticsService.instance.track(
        AnalyticsEvents.checkoutValidationFailed,
        properties: {
          'module_type': 'ride',
          'reason': 'ride_submission_failed',
          'error': e.toString(),
        },
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t('ride_booking.failed', params: {'error': '$e'})),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final Widget child;

  const _SummaryCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _SummaryRow(this.label, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final style = isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style.copyWith(
              color: isTotal ? AppColors.ride : AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool hideTrailing;

  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.hideTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              if (!hideTrailing) ...[
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.labelMedium),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
