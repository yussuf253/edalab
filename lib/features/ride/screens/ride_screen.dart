import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
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
import '../../../core/widgets/app_shimmer.dart';
import '../widgets/ride_route_preview.dart';
import '../../car_rental/services/car_rental_service.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  static const _fallbackPickup = _RidePlace(
    title: 'Current Location',
    address: 'Place Menelik, Djibouti',
    icon: Icons.my_location_rounded,
    distance: 0,
    latitude: 11.5886,
    longitude: 43.1457,
  );

  _RidePlace? _pickupPlace;
  _RidePlace? _destinationPlace;
  List<RideCategory> _rideCategories = RideModel.sampleCategories;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  bool _isResolvingPickup = true;
  int _activeTab = 0; // 0 = Ride, 1 = Rent

  @override
  void initState() {
    super.initState();
    _loadRideCategories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationAccess(showFailureSnackBar: false);
    });
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
      setState(() {
        _rideCategories = items.isEmpty ? RideModel.sampleCategories : items;
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'ride',
          'entity_type': 'ride_category',
          'result_count': _rideCategories.length,
          'source': 'remote',
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
          'result_count': _rideCategories.length,
          'source': 'fallback_sample',
        },
      );
    }
  }

  String _rideCategoryName(RideCategory category, AppLocalizations l10n) {
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

  String _rideEtaLabel(String value, AppLocalizations l10n) {
    final match = RegExp(r'^(\d+)\s*min$').firstMatch(value.trim());
    if (match == null) return value;
    return l10n.t('ride.eta_minutes', params: {'count': match.group(1)!});
  }

  Future<void> _requestLocationAccess({bool showFailureSnackBar = true}) async {
    try {
      final locationProvider = context.read<UserLocationProvider>();
      final hasLocation = await locationProvider.ensureCurrentLocation(
        requestPermission: false,
      );
      if (!mounted) return;

      if (!hasLocation || locationProvider.location == null) {
        setState(() {
          _hasLocationPermission = locationProvider.hasPermission;
          _isResolvingPickup = false;
          _pickupPlace ??= _defaultPickupPlace();
        });
        if (showFailureSnackBar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.t('common.current_location_unavailable'),
              ),
            ),
          );
        }
        return;
      }

      final resolvedLocation = locationProvider.location!;
      setState(() {
        _pickupPlace = _RidePlace(
          title: resolvedLocation.title,
          address: resolvedLocation.subtitle,
          icon: Icons.my_location_rounded,
          distance: 0,
          latitude: resolvedLocation.latitude,
          longitude: resolvedLocation.longitude,
        );
        _hasLocationPermission = true;
        _isResolvingPickup = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = false;
          _isResolvingPickup = false;
        });
      }
      if (!mounted) return;
      if (showFailureSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('ride.saved_location_pickup_manual')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final savedPlaces = _savedPlaces(context);
    final pickupPlace = _pickupPlace;
    final destinationPlace = _destinationPlace;
    final currentLocationLabel = pickupPlace == null
        ? l10n.t('ride.locating_pickup')
        : pickupPlace.title == 'Current Location'
        ? l10n.t('ride.current_location')
        : pickupPlace.address;
    final destinationLabel =
        destinationPlace?.address ?? l10n.t('ride.where_to');
    final pickupPoint =
        pickupPlace?.latitude != null && pickupPlace?.longitude != null
        ? RideMapPoint(
            label: l10n.t('ride.current_location'),
            latitude: pickupPlace!.latitude!,
            longitude: pickupPlace.longitude!,
            color: AppColors.success,
            icon: Icons.my_location_rounded,
          )
        : null;
    final destinationPoint =
        destinationPlace?.latitude != null &&
            destinationPlace?.longitude != null
        ? RideMapPoint(
            label: destinationPlace!.title,
            latitude: destinationPlace.latitude!,
            longitude: destinationPlace.longitude!,
            color: AppColors.accent,
            icon: Icons.location_on_rounded,
          )
        : null;
    final homeQuickRide = _findPlace(
      savedPlaces,
      l10n.t('ride.home'),
      fallback: savedPlaces.isNotEmpty ? savedPlaces.first : _fallbackPickup,
    );
    final workQuickRide = _findPlace(
      savedPlaces,
      l10n.t('ride.work'),
      fallback: savedPlaces.length > 1 ? savedPlaces[1] : _fallbackPickup,
    );

    if (_activeTab == 1) {
      // Short-circuit: when the Rent tab is active, render only the RentContent
      return PopScope(
        canPop: context.canPop(),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !context.canPop()) {
            context.go('/');
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(l10n.t('ride.title')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Mode tabs (Ride / Rent) ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? AppColors.primary
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppSpacing.shadowSm,
                          ),
                          child: Center(
                            child: Text(
                              l10n.t('ride.mode_ride'),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _activeTab == 0
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? AppColors.primary
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppSpacing.shadowSm,
                          ),
                          child: Center(
                            child: Text(
                              l10n.t('ride.mode_rent'),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _activeTab == 1
                                    ? Colors.white
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rent-only content
                const RentContent(),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('ride.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Mode tabs (Ride / Rent) ─────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _activeTab == 0
                              ? AppColors.primary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppSpacing.shadowSm,
                        ),
                        child: Center(
                          child: Text(
                            l10n.t('ride.mode_ride'),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: _activeTab == 0
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _activeTab == 1
                              ? AppColors.primary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppSpacing.shadowSm,
                        ),
                        child: Center(
                          child: Text(
                            l10n.t('ride.mode_rent'),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: _activeTab == 1
                                  ? Colors.white
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Map preview (ride) - Rent handled above by short-circuit
              RideRoutePreview(
                title: l10n.t('ride.map_view'),
                pickup: pickupPoint,
                destination: destinationPoint,
                showMyLocation: _hasLocationPermission,
                showTitleChip: false,
                showLegend: false,
                emptyLabel: _isResolvingPickup
                    ? 'Finding your current location...'
                    : l10n.t('ride.choose_destination'),
                actionIcon: Icons.my_location_rounded,
                onActionTap: _requestLocationAccess,
              ),
              // ── Route input card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectPlace(isPickup: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.extraLightGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                currentLocationLabel,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Column(
                        children: List.generate(
                          3,
                          (_) => Container(
                            width: 2,
                            height: 6,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _selectPlace(isPickup: false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.extraLightGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                destinationLabel,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: destinationPlace == null
                                      ? AppColors.mediumGrey
                                      : AppColors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Available rides ──────────────────────────────────────────
              Text(l10n.t('ride.available_rides'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              if (_isLoading)
                const AppShimmer(
                  child: SizedBox(
                    height: 118,
                    child: Row(
                      children: [
                        Expanded(
                          child: ShimmerBlock(
                            width: double.infinity,
                            height: 118,
                            radius: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ShimmerBlock(
                            width: double.infinity,
                            height: 118,
                            radius: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _rideCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final ride = _rideCategories[index];
                      return Container(
                        width: 196,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppSpacing.shadowSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.rideBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _iconForRideCategory(ride.name),
                                    color: AppColors.ride,
                                    size: 22,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'DJF${ride.basePrice.toStringAsFixed(0)}+',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.ride,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _rideCategoryName(ride, l10n),
                                    style: AppTextStyles.labelLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.t(
                                      'ride.seats_eta',
                                      params: {
                                        'count': '${ride.capacity}',
                                        'eta': _rideEtaLabel(
                                          ride.timeToArrive,
                                          l10n,
                                        ),
                                      },
                                    ),
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // Note: 'Rent a Car' content moved into the Rent tab's RentContent widget

              // ── Quick rides ──────────────────────────────────────────────
              Text(l10n.t('ride.quick_rides'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _QuickRide(
                          homeQuickRide.icon,
                          homeQuickRide.title,
                          homeQuickRide.address,
                          onTap: () => _openRideBooking(
                            homeQuickRide,
                            source: 'quick_home',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _QuickRide(
                          workQuickRide.icon,
                          workQuickRide.title,
                          workQuickRide.address,
                          onTap: () => _openRideBooking(
                            workQuickRide,
                            source: 'quick_work',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Recent places ────────────────────────────────────────────
              Text(l10n.t('ride.recent_places'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              ...savedPlaces
                  .skip(2)
                  .map(
                    (place) => GestureDetector(
                      onTap: () =>
                          _openRideBooking(place, source: 'recent_place'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.rideBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                place.icon,
                                color: AppColors.ride,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.title,
                                    style: AppTextStyles.labelMedium,
                                  ),
                                  Text(
                                    place.address,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.mediumGrey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 24),

              // ── Promo banner ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;
                    final textBlock = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('ride.promo_title'),
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.t('ride.promo_subtitle'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    );
                    final action = GestureDetector(
                      onTap: () {
                        AnalyticsService.instance.track(
                          AnalyticsEvents.entityOpened,
                          properties: {
                            'module': 'ride',
                            'entity_type': 'promo_offer',
                            'entity_id': 'ride_promo_claim',
                            'source': 'ride_screen',
                          },
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.t('ride.offer_saved'))),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.t('ride.claim'),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          textBlock,
                          const SizedBox(height: 12),
                          action,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: textBlock),
                        const SizedBox(width: 12),
                        action,
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForRideCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('xl')) return Icons.airport_shuttle_rounded;
    if (lower.contains('premium')) return Icons.local_taxi_rounded;
    return Icons.directions_car_rounded;
  }

  Future<void> _selectPlace({required bool isPickup}) async {
    AnalyticsService.instance.track(
      AnalyticsEvents.entityOpened,
      properties: {
        'module': 'ride',
        'entity_type': 'place_picker',
        'entity_id': isPickup ? 'pickup' : 'destination',
        'source': 'ride_screen',
      },
    );
    final places = isPickup ? _pickupPlaces(context) : _savedPlaces(context);
    final selected = await showModalBottomSheet<_RidePlace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PlacePickerSheet(
          isPickup: isPickup,
          places: places,
          origin: _pickupPlace ?? _defaultPickupPlace(),
        );
      },
    );

    if (selected == null) return;

    if (isPickup) {
      setState(() => _pickupPlace = selected);
      AnalyticsService.instance.track(
        AnalyticsEvents.filterApplied,
        properties: {
          'module': 'ride',
          'filter_type': 'pickup_place',
          'filter_value': selected.title,
        },
      );
      return;
    }

    setState(() => _destinationPlace = selected);
    AnalyticsService.instance.track(
      AnalyticsEvents.filterApplied,
      properties: {
        'module': 'ride',
        'filter_type': 'destination_place',
        'filter_value': selected.title,
      },
    );
    _openRideBooking(selected, source: 'destination_picker');
  }

  void _openRideBooking(_RidePlace destination, {required String source}) {
    final pickup = _pickupPlace ?? _defaultPickupPlace();
    AnalyticsService.instance.track(
      AnalyticsEvents.checkoutEntryTapped,
      properties: {
        'module': 'ride',
        'source': source,
        'entry_type': 'ride_booking',
        'has_pickup_point': pickup.latitude != null && pickup.longitude != null,
        'has_destination_point':
            destination.latitude != null && destination.longitude != null,
      },
    );
    context.push(
      '/ride/book',
      extra: {
        'pickup': pickup.address,
        'pickupTitle': pickup.title,
        'pickupAddressId': pickup.addressId,
        'pickupPoint': pickup.latitude != null && pickup.longitude != null
            ? {
                'label': pickup.title,
                'latitude': pickup.latitude,
                'longitude': pickup.longitude,
              }
            : null,
        'destinationTitle': destination.title,
        'destination': destination.address,
        'dropoffAddressId': destination.addressId,
        'destinationPoint':
            destination.latitude != null && destination.longitude != null
            ? {
                'label': destination.title,
                'latitude': destination.latitude,
                'longitude': destination.longitude,
              }
            : null,
        'distance': destination.distance,
      },
    );
  }

  _RidePlace _defaultPickupPlace() {
    final addresses = context.read<AuthProvider>().user?.addresses ?? const [];
    _RidePlace? preferred;
    for (final address in addresses) {
      if (address.isDefault &&
          address.latitude != null &&
          address.longitude != null) {
        preferred = _RidePlace(
          title: address.label,
          address: address.address,
          icon: _iconForLabel(address.label),
          distance: 0,
          latitude: address.latitude,
          longitude: address.longitude,
          addressId: address.id,
        );
        break;
      }
    }
    preferred ??= addresses
        .where(
          (address) => address.latitude != null && address.longitude != null,
        )
        .map(
          (address) => _RidePlace(
            title: address.label,
            address: address.address,
            icon: _iconForLabel(address.label),
            distance: 0,
            latitude: address.latitude,
            longitude: address.longitude,
            addressId: address.id,
          ),
        )
        .cast<_RidePlace?>()
        .firstWhere((address) => address != null, orElse: () => null);
    if (preferred == null) return _fallbackPickup;
    return preferred;
  }

  List<_RidePlace> _savedPlaces(BuildContext context) {
    final addresses = context.read<AuthProvider>().user?.addresses ?? const [];
    final userPlaces = addresses
        .where(
          (address) => address.latitude != null && address.longitude != null,
        )
        .map(
          (address) => _RidePlace(
            title: address.label,
            address: address.address,
            icon: _iconForLabel(address.label),
            distance: address.isDefault ? 2.1 : 3.8,
            latitude: address.latitude,
            longitude: address.longitude,
            addressId: address.id,
          ),
        )
        .toList();
    final fallbackPlaces = [
      _RidePlace(
        title: context.l10n.t('ride.home'),
        address: '123 Main St',
        icon: Icons.home_rounded,
        distance: 4.2,
        latitude: 11.5824,
        longitude: 43.1488,
      ),
      _RidePlace(
        title: context.l10n.t('ride.work'),
        address: '456 Office Ave',
        icon: Icons.work_rounded,
        distance: 6.8,
        latitude: 11.5485,
        longitude: 43.1529,
      ),
      _RidePlace(
        title: context.l10n.t('ride.city_mall'),
        address: '789 Shopping Blvd',
        icon: Icons.shopping_bag_rounded,
        distance: 5.2,
        latitude: 11.5316,
        longitude: 43.1434,
      ),
      _RidePlace(
        title: context.l10n.t('ride.central_park'),
        address: '321 Green Lane',
        icon: Icons.park_rounded,
        distance: 3.7,
        latitude: 11.5776,
        longitude: 43.1514,
      ),
      _RidePlace(
        title: context.l10n.t('ride.airport'),
        address: 'International Airport',
        icon: Icons.flight_rounded,
        distance: 9.5,
        latitude: 11.5475,
        longitude: 43.1596,
      ),
      _RidePlace(
        title: context.l10n.t('ride.train_station'),
        address: 'Central Station',
        icon: Icons.train_rounded,
        distance: 7.1,
        latitude: 11.5958,
        longitude: 43.1374,
      ),
    ];

    final seen = <String>{};
    return [
      ...userPlaces,
      ...fallbackPlaces,
    ].where((place) => seen.add(place.address.toLowerCase())).toList();
  }

  List<_RidePlace> _pickupPlaces(BuildContext context) {
    final addresses = context.read<AuthProvider>().user?.addresses ?? const [];
    final currentPickup = _pickupPlace ?? _defaultPickupPlace();
    final userPlaces = addresses
        .where(
          (address) => address.latitude != null && address.longitude != null,
        )
        .map(
          (address) => _RidePlace(
            title: address.label,
            address: address.address,
            icon: _iconForLabel(address.label),
            distance: address.isDefault ? 2.1 : 3.8,
            latitude: address.latitude,
            longitude: address.longitude,
            addressId: address.id,
          ),
        )
        .toList();

    final seen = <String>{};
    return [
      currentPickup,
      ...userPlaces,
    ].where((place) => seen.add(place.address.toLowerCase())).toList();
  }

  _RidePlace _findPlace(
    List<_RidePlace> places,
    String title, {
    required _RidePlace fallback,
  }) {
    for (final place in places) {
      if (place.title.toLowerCase() == title.toLowerCase()) {
        return place;
      }
    }
    return fallback;
  }

  IconData _iconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('home')) return Icons.home_rounded;
    if (lower.contains('work') || lower.contains('office')) {
      return Icons.work_rounded;
    }
    if (lower.contains('airport')) return Icons.flight_rounded;
    if (lower.contains('station')) return Icons.train_rounded;
    return Icons.place_rounded;
  }
}

// (Car rental banner removed — Rent tab now displays `RentContent` only.)

// ─── Place picker sheet ──────────────────────────────────────────────────────

class _PlacePickerSheet extends StatefulWidget {
  final bool isPickup;
  final List<_RidePlace> places;
  final _RidePlace origin;

  const _PlacePickerSheet({
    required this.isPickup,
    required this.places,
    required this.origin,
  });

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;
  bool _isSearching = false;
  bool _isLoadingPopular = false;
  List<_RidePlace> _remotePlaces = const [];
  List<_RidePlace> _popularPlaces = const [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (!widget.isPickup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_loadPopularDjiboutiPlaces());
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    final query = value.trim();
    if (widget.isPickup) return;
    if (query.length < 2) {
      if (query.isEmpty) {
        setState(() {
          _remotePlaces = const [];
          _isSearching = false;
        });
        unawaited(_loadPopularDjiboutiPlaces());
      } else {
        setState(() {
          _remotePlaces = const [];
          _isSearching = false;
        });
      }
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_searchDjiboutiPlaces(query));
    });
  }

  Future<List<_RidePlace>> _fetchDjiboutiPlaces(
    String query, {
    int limit = 12,
  }) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': '$query, Djibouti',
      'format': 'jsonv2',
      'countrycodes': 'dj',
      'addressdetails': '1',
      'limit': '$limit',
      'viewbox': '42.98,11.72,43.25,11.45',
      'bounded': '1',
    });
    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'eDalab/1.0 (Ride destination search)',
        'Accept-Language': 'en',
      },
    );
    if (response.statusCode != 200) return const [];

    final rawItems = jsonDecode(response.body);
    if (rawItems is! List) return const [];

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(_ridePlaceFromNominatim)
        .whereType<_RidePlace>()
        .toList();
  }

  Future<void> _loadPopularDjiboutiPlaces() async {
    if (_isLoadingPopular) return;
    setState(() => _isLoadingPopular = true);
    try {
      final popularQueries = <String>[
        'Place Menelik',
        'Djibouti-Ambouli International Airport',
        'Port of Djibouti',
        'Bawadi Mall',
        'Kempinski Palace',
      ];
      final collected = <_RidePlace>[];
      for (final query in popularQueries) {
        final results = await _fetchDjiboutiPlaces(query, limit: 3);
        collected.addAll(results);
      }
      if (!mounted || _searchController.text.trim().isNotEmpty) return;
      final seen = <String>{};
      setState(() {
        _popularPlaces = collected
            .where((place) => seen.add(place.address.toLowerCase()))
            .toList();
        _isLoadingPopular = false;
      });
    } catch (_) {
      if (!mounted || _searchController.text.trim().isNotEmpty) return;
      setState(() {
        _popularPlaces = const [];
        _isLoadingPopular = false;
      });
    }
  }

  Future<void> _searchDjiboutiPlaces(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 2) return;
    setState(() => _isSearching = true);
    try {
      final activeQuery = _searchController.text.trim();
      if (!mounted ||
          (activeQuery.isNotEmpty && activeQuery != normalizedQuery)) {
        return;
      }
      final places = await _fetchDjiboutiPlaces(normalizedQuery);
      final seen = <String>{};
      setState(() {
        _remotePlaces = places
            .where((place) => seen.add(place.address.toLowerCase()))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      final activeQuery = _searchController.text.trim();
      if (!mounted ||
          (activeQuery.isNotEmpty && activeQuery != normalizedQuery)) {
        return;
      }
      setState(() {
        _remotePlaces = const [];
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = _searchController.text.trim().toLowerCase();
    final filteredLocalPlaces = widget.places.where((place) {
      if (query.isEmpty) return true;
      return place.title.toLowerCase().contains(query) ||
          place.address.toLowerCase().contains(query);
    }).toList();
    final filteredPlaces = widget.isPickup
        ? filteredLocalPlaces
        : query.isEmpty
        ? _mergedPlaces(const <_RidePlace>[], _popularPlaces)
        : (_remotePlaces.isNotEmpty ? _remotePlaces : filteredLocalPlaces);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isPickup
                    ? l10n.t('ride.select_pickup')
                    : l10n.t('ride.choose_destination'),
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: widget.isPickup
                      ? l10n.t('ride.search_pickup')
                      : l10n.t('ride.search_destination'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.extraLightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!widget.isPickup &&
                  query.isEmpty &&
                  (_isLoadingPopular || _popularPlaces.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _isLoadingPopular
                        ? l10n.t('ride.loading_popular_places')
                        : l10n.t('ride.popular_places'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ),
              if (!widget.isPickup &&
                  query.isNotEmpty &&
                  (_isSearching || _remotePlaces.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _isSearching
                        ? l10n.t('ride.searching_places')
                        : l10n.t('ride.search_results_places'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ),
              Expanded(
                child: !widget.isPickup && query.isEmpty && _isLoadingPopular
                    ? _PlacePickerStatus(
                        icon: Icons.travel_explore_rounded,
                        message: l10n.t('ride.loading_popular_places'),
                      )
                    : filteredPlaces.isEmpty
                    ? _PlacePickerStatus(
                        icon: query.isEmpty
                            ? (widget.isPickup
                                  ? Icons.my_location_rounded
                                  : Icons.location_city_rounded)
                            : Icons.search_off_rounded,
                        message: widget.isPickup
                            ? l10n.t('ride.no_pickup_places')
                            : query.isEmpty
                            ? l10n.t('ride.no_popular_places')
                            : query.isNotEmpty || _remotePlaces.isNotEmpty
                            ? l10n.t('ride.no_search_match')
                            : l10n.t('ride.no_saved_places'),
                      )
                    : ListView(
                        children: [
                          ...filteredPlaces.map(
                            (place) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.rideBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(place.icon, color: AppColors.ride),
                              ),
                              title: Text(
                                place.title,
                                style: AppTextStyles.labelMedium,
                              ),
                              subtitle: Text(
                                place.address,
                                style: AppTextStyles.caption,
                              ),
                              onTap: () => Navigator.of(context).pop(place),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

List<_RidePlace> _mergedPlaces(
  List<_RidePlace> primary,
  List<_RidePlace> secondary,
) {
  final seen = <String>{};
  return [
    ...primary,
    ...secondary,
  ].where((place) => seen.add(place.address.toLowerCase())).toList();
}

_RidePlace? _ridePlaceFromNominatim(Map<String, dynamic> data) {
  final latitude = double.tryParse(data['lat']?.toString() ?? '');
  final longitude = double.tryParse(data['lon']?.toString() ?? '');
  if (latitude == null || longitude == null) return null;

  final name = (data['name']?.toString().trim().isNotEmpty ?? false)
      ? data['name'].toString().trim()
      : ((data['display_name']?.toString().split(',').isNotEmpty ?? false)
            ? data['display_name'].toString().split(',').first.trim()
            : '');
  final displayName = data['display_name']?.toString().trim() ?? '';
  if (displayName.isEmpty) return null;

  return _RidePlace(
    title: name.isNotEmpty ? name : 'Destination',
    address: displayName,
    icon: _iconForPlaceCategory(
      data['type']?.toString(),
      data['class']?.toString(),
    ),
    distance: 5.0,
    latitude: latitude,
    longitude: longitude,
  );
}

IconData _iconForPlaceCategory(String? type, String? category) {
  final merged = '${type ?? ''} ${category ?? ''}'.toLowerCase();
  if (merged.contains('airport') || merged.contains('aerodrome')) {
    return Icons.flight_rounded;
  }
  if (merged.contains('hotel') || merged.contains('accommodation')) {
    return Icons.hotel_rounded;
  }
  if (merged.contains('restaurant') || merged.contains('cafe')) {
    return Icons.restaurant_rounded;
  }
  if (merged.contains('hospital') || merged.contains('clinic')) {
    return Icons.local_hospital_rounded;
  }
  if (merged.contains('school') || merged.contains('university')) {
    return Icons.school_rounded;
  }
  if (merged.contains('shop') || merged.contains('mall')) {
    return Icons.shopping_bag_rounded;
  }
  return Icons.place_rounded;
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _QuickRide extends StatelessWidget {
  final IconData icon;
  final String name;
  final String address;
  final VoidCallback onTap;

  const _QuickRide(this.icon, this.name, this.address, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.rideBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.ride),
            ),
            const SizedBox(height: 16),
            Text(name, style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text(
              address,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacePickerStatus extends StatelessWidget {
  final IconData icon;
  final String message;

  const _PlacePickerStatus({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.rideBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.ride, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.mediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RidePlace {
  final String title;
  final String address;
  final IconData icon;
  final double distance;
  final double? latitude;
  final double? longitude;
  final String? addressId;

  const _RidePlace({
    required this.title,
    required this.address,
    required this.icon,
    required this.distance,
    this.latitude,
    this.longitude,
    this.addressId,
  });
}

// RentContent: displays a simple list of rental cars fetched from the backend.
class RentContent extends StatefulWidget {
  const RentContent({super.key});

  @override
  State<RentContent> createState() => _RentContentState();
}

class _RentContentState extends State<RentContent> {
  bool _loading = true;
  List<dynamic> _cars = [];

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final cars = await CarRentalService.fetchCars();
      if (!mounted) return;
      setState(() {
        _cars = cars;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('No cars available', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _cars.map((c) {
        // CarRentalService returns CarRentalCar objects; ensure we can read id/name/price
        final id = c is Map ? (c['id']?.toString() ?? '') : (c.id ?? '');
        final name = c is Map ? (c['name']?.toString() ?? '') : (c.name ?? '');
        final price = c is Map
            ? (c['price']?.toString() ?? c['pricePerDay']?.toString() ?? '')
            : '${c.pricePerDay ?? ''}';

        return GestureDetector(
          onTap: () => context.push('/car-rental/$id'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppSpacing.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 48,
                  color: AppColors.extraLightGrey,
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: AppColors.mediumGrey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 6),
                      Text('DJF $price / day', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.mediumGrey,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
