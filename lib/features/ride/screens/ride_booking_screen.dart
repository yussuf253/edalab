import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../services/ride_route_service.dart';
import '../utils/ride_map_launcher.dart';
import '../widgets/ride_route_preview.dart';

class RideBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData;
  const RideBookingScreen({super.key, this.bookingData});
  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  int _selectedVehicle = 0;
  List<RideCategory> _categories = RideModel.sampleCategories;
  bool _isLoading = true;
  RideRouteDetails? _routeDetails;
  bool _isLoadingRoute = true;

  @override
  void initState() {
    super.initState();
    _loadRideCategories();
    _loadRouteDetails();
  }

  Future<void> _loadRideCategories() async {
    try {
      final response = await ApiClient.get('/catalog/ride-categories');
      final items = (response as List)
          .map(
            (item) =>
                RideCategory.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      final nextCategories = items.isEmpty ? RideModel.sampleCategories : items;
      setState(() {
        _categories = nextCategories;
        final maxIndex = nextCategories.isEmpty ? 0 : nextCategories.length - 1;
        if (_selectedVehicle > maxIndex) {
          _selectedVehicle = maxIndex;
        }
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'ride',
          'entity_type': 'ride_category',
          'result_count': _categories.length,
          'source': 'booking_screen_remote',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'ride',
          'entity_type': 'ride_category',
          'result_count': _categories.length,
          'source': 'booking_screen_fallback',
        },
      );
    }
  }

  IconData _getIconForCategory(String name) {
    if (name.toLowerCase().contains('xl')) return Icons.airport_shuttle_rounded;
    if (name.toLowerCase().contains('premium')) return Icons.local_taxi_rounded;
    return Icons.directions_car_rounded;
  }

  String _categoryDisplayName(RideCategory category, AppLocalizations l10n) {
    switch (category.id) {
      case 'r1':
        return l10n.t('ride.category_economy');
      case 'r2':
        return l10n.t('ride.category_premium');
      case 'r3':
        return l10n.t('ride.category_xl');
      default:
        return category.name;
    }
  }

  Future<void> _loadRouteDetails() async {
    final existing = widget.bookingData?['routeDetails'];
    if (existing is Map) {
      setState(() {
        _routeDetails = RideRouteDetails.fromJson(
          Map<String, dynamic>.from(existing),
        );
        _isLoadingRoute = false;
      });
      return;
    }

    final pickup =
        widget.bookingData?['pickup'] as String? ?? '123 Main Street';
    final destinationTitle =
        widget.bookingData?['destinationTitle'] as String? ?? 'City Mall';
    final fallbackDistance =
        (widget.bookingData?['distance'] as num?)?.toDouble() ?? 5.2;
    final pickupPoint =
        rideMapPointFromJson(
          widget.bookingData?['pickupPoint'],
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
          widget.bookingData?['destinationPoint'],
          fallbackLabel: destinationTitle,
          color: AppColors.accent,
          icon: Icons.location_on_rounded,
        ) ??
        estimateRideDestinationPoint(
          origin: pickupPoint,
          distanceKm: fallbackDistance,
          label: destinationTitle,
        );

    final routeDetails = await RideRouteService.computeRoute(
      origin: pickupPoint,
      destination: destinationPoint,
    );
    if (!mounted) return;
    setState(() {
      _routeDetails = routeDetails;
      _isLoadingRoute = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = _categories;
    final selectedVehicleIndex = _selectedVehicle >= categories.length
        ? 0
        : _selectedVehicle;
    final selectedCategory = categories[selectedVehicleIndex];
    final pickup =
        widget.bookingData?['pickup'] as String? ?? '123 Main Street';
    final destinationTitle =
        widget.bookingData?['destinationTitle'] as String? ?? 'City Mall';
    final destination =
        widget.bookingData?['destination'] as String? ?? 'City Mall, Downtown';
    final paymentMethod =
        widget.bookingData?['payment'] as String? ?? l10n.t('common.cash');
    final pickupPoint =
        rideMapPointFromJson(
          widget.bookingData?['pickupPoint'],
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
          widget.bookingData?['destinationPoint'],
          fallbackLabel: destinationTitle,
          color: AppColors.accent,
          icon: Icons.location_on_rounded,
        ) ??
        estimateRideDestinationPoint(
          origin: pickupPoint,
          distanceKm:
              _routeDetails?.distanceKm ??
              (widget.bookingData?['distance'] as num?)?.toDouble() ??
              5.2,
          label: destinationTitle,
        );
    final routeDistance =
        _routeDetails?.distanceKm ??
        (widget.bookingData?['distance'] as num?)?.toDouble() ??
        5.2;
    final routeDurationLabel = _routeDetails?.durationLabel;
    final routeDurationBadgeLabel =
        _isLoadingRoute || routeDurationLabel == null
        ? null
        : routeDurationLabel;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('ride_booking.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RideRoutePreview(
                title: l10n.t('tracking.live_map'),
                pickup: pickupPoint,
                destination: destinationPoint,
                showTitleChip: false,
                showLegend: false,
                badgeLabel: routeDurationBadgeLabel,
                routePolyline: _routeDetails?.polylinePoints,
                overlayStatusIcon: _isLoadingRoute
                    ? Icons.route_rounded
                    : routeDurationLabel == null
                    ? Icons.info_outline_rounded
                    : null,
                overlayStatusMessage: _isLoadingRoute
                    ? l10n.t('ride_booking.calculating_route_time')
                    : routeDurationLabel == null
                    ? l10n.t('ride_booking.route_estimate_unavailable')
                    : null,
                actionLabel: l10n.t('ride.open_map'),
                onActionTap: () {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.entityOpened,
                    properties: {
                      'module': 'ride',
                      'entity_type': 'external_map',
                      'entity_id': 'ride_route_map',
                      'source': 'ride_booking_screen',
                    },
                  );
                  openRideRouteInMaps(
                    context,
                    pickupLabel: pickup,
                    destinationLabel: destination,
                    pickupPoint: pickupPoint,
                    destinationPoint: destinationPoint,
                  );
                },
              ),
            ),
          ),
          // Vehicle selection
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route summary
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickup,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.mediumGrey,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          destinationTitle,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.extraLightGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isLoadingRoute
                          ? l10n.t('ride_booking.calculating_route')
                          : routeDurationLabel == null
                          ? l10n.t(
                              'ride_booking.route_estimate_unavailable_short',
                            )
                          : l10n.t(
                              'ride_booking.route_summary',
                              params: {
                                'distance': routeDistance.toStringAsFixed(1),
                                'duration': routeDurationLabel,
                              },
                            ),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('ride_booking.choose_vehicle'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _isLoading
                        ? const InlineSectionListShimmer(itemCount: 4)
                        : ListView.separated(
                            itemCount: categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final estPrice =
                                  cat.basePrice +
                                  (cat.pricePerMile * routeDistance);
                              final sel = _selectedVehicle == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedVehicle = index);
                                  AnalyticsService.instance.track(
                                    AnalyticsEvents.filterApplied,
                                    properties: {
                                      'module': 'ride',
                                      'filter_type': 'vehicle_category',
                                      'filter_value': cat.name,
                                      'entity_id': cat.id,
                                    },
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.rideBg
                                        : AppColors.extraLightGrey,
                                    borderRadius: BorderRadius.circular(14),
                                    border: sel
                                        ? Border.all(
                                            color: AppColors.ride,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getIconForCategory(cat.name),
                                        color: sel
                                            ? AppColors.ride
                                            : AppColors.grey,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _categoryDisplayName(cat, l10n),
                                              style: AppTextStyles.labelLarge,
                                            ),
                                            Text(
                                              _isLoadingRoute
                                                  ? l10n.t(
                                                      'ride_booking.calculating_route',
                                                    )
                                                  : routeDurationLabel == null
                                                  ? l10n.t(
                                                      'ride.seat_count',
                                                      params: {
                                                        'count':
                                                            '${cat.capacity}',
                                                      },
                                                    )
                                                  : l10n.t(
                                                      'ride_booking.arrival_seats',
                                                      params: {
                                                        'eta':
                                                            routeDurationLabel,
                                                        'count':
                                                            '${cat.capacity}',
                                                      },
                                                    ),
                                              style: AppTextStyles.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'DJF${estPrice.toStringAsFixed(2)}',
                                        style: AppTextStyles.labelLarge
                                            .copyWith(
                                              color: sel
                                                  ? AppColors.ride
                                                  : AppColors.dark,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 20),
                  SafeArea(
                    child: AppButton(
                      text: l10n.t('ride_booking.continue'),
                      color: AppColors.ride,
                      onPressed: () {
                        if (_isLoading ||
                            _isLoadingRoute ||
                            categories.isEmpty) {
                          return;
                        }
                        AnalyticsService.instance.track(
                          AnalyticsEvents.checkoutEntryTapped,
                          properties: {
                            'module': 'ride',
                            'source': 'ride_booking_screen',
                            'entry_type': 'ride_summary',
                            'ride_category_id': selectedCategory.id,
                            'ride_category_name': selectedCategory.name,
                            'route_distance_km': routeDistance,
                          },
                        );
                        context.push(
                          '/ride/summary',
                          extra: {
                            'selectedCategory': selectedCategory,
                            'payment': paymentMethod,
                            'pickup': pickup,
                            'destination': destination,
                            'pickupAddressId':
                                widget.bookingData?['pickupAddressId'],
                            'dropoffAddressId':
                                widget.bookingData?['dropoffAddressId'],
                            'pickupPoint': rideMapPointToJson(pickupPoint),
                            'destinationPoint': rideMapPointToJson(
                              destinationPoint,
                            ),
                            'routeDistance': routeDistance,
                            'routeDurationLabel':
                                routeDurationLabel ??
                                l10n.t('ride.eta_unavailable'),
                            'estimatedRidePrice':
                                selectedCategory.basePrice +
                                (selectedCategory.pricePerMile * routeDistance),
                            if (_routeDetails != null)
                              'routeDetails': _routeDetails!.toJson(),
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
