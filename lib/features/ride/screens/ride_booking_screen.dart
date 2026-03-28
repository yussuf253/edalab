import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/models/models.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/auth_gate.dart';

class RideBookingScreen extends StatefulWidget {
  final Map<String, dynamic>? bookingData;
  const RideBookingScreen({super.key, this.bookingData});
  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  int _selectedVehicle = 0;
  int _selectedPayment = 0;
  bool _isSubmitting = false;
  List<RideCategory> _categories = RideModel.sampleCategories;
  bool _isLoading = true;

  final _payments = const ['•••• 4242', 'Apple Pay', 'Cash'];

  @override
  void initState() {
    super.initState();
    _loadRideCategories();
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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconForCategory(String name) {
    if (name.toLowerCase().contains('xl')) return Icons.airport_shuttle_rounded;
    if (name.toLowerCase().contains('premium')) return Icons.local_taxi_rounded;
    return Icons.directions_car_rounded;
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
    final routeDistance =
        (widget.bookingData?['distance'] as num?)?.toDouble() ?? 5.2;
    final estimatedRidePrice =
        selectedCategory.basePrice +
        (selectedCategory.pricePerMile * routeDistance);

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
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.extraLightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.route_rounded,
                      size: 48,
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t(
                        'ride_booking.route_summary',
                        params: {'distance': routeDistance.toStringAsFixed(1)},
                      ),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
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
                  const SizedBox(height: 16),
                  Text(l10n.t('ride_booking.choose_vehicle'), style: AppTextStyles.h4),
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
                                onTap: () =>
                                    setState(() => _selectedVehicle = index),
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
                                              cat.name,
                                              style: AppTextStyles.labelLarge,
                                            ),
                                            Text(
                                              l10n.t(
                                                'ride_booking.arrival_seats',
                                                params: {
                                                  'eta': cat.timeToArrive,
                                                  'count': '${cat.capacity}',
                                                },
                                              ),
                                              style: AppTextStyles.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '\$${estPrice.toStringAsFixed(2)}',
                                        style: AppTextStyles.priceSmall
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
                  // Payment method
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.extraLightGrey,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.credit_card_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _payments[_selectedPayment],
                          style: AppTextStyles.labelMedium,
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _selectPayment,
                          child: Text(
                            l10n.t('ride_booking.change'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SafeArea(
                    child: AppButton(
                      text: l10n.t(
                        'ride_booking.confirm',
                        params: {
                          'amount': estimatedRidePrice.toStringAsFixed(2),
                        },
                      ),
                      color: AppColors.ride,
                      isLoading: _isSubmitting,
                      onPressed: () async {
                        if (_isSubmitting || _isLoading || categories.isEmpty) {
                          return;
                        }
                        final allowed = await requireLoggedIn(
                          context,
                          message: l10n.t('ride_booking.login_required'),
                        );
                        if (!context.mounted || !allowed) return;
                        final auth = context.read<AuthProvider>();
                        setState(() => _isSubmitting = true);
                        try {
                          final ride = await _createRideBooking(
                            userId: auth.user!.id,
                            selectedCategory: selectedCategory,
                            routeDistance: routeDistance,
                            pickup: pickup,
                            destination: destination,
                            estimatedRidePrice: estimatedRidePrice,
                          );
                          if (!context.mounted) return;
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
                          context.go(
                            '/ride/tracking/${ride['id']}',
                            extra: ride,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.t(
                                  'ride_booking.failed',
                                  params: {'error': '$e'},
                                ),
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
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

  Future<void> _selectPayment() async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('checkout.payment_method'), style: AppTextStyles.h3),
                const SizedBox(height: 16),
                ..._payments.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value, style: AppTextStyles.labelMedium),
                    trailing: _selectedPayment == entry.key
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(entry.key),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedPayment = selected);
    }
  }

  Future<Map<String, dynamic>> _createRideBooking({
    required String userId,
    required RideCategory selectedCategory,
    required double routeDistance,
    required String pickup,
    required String destination,
    required double estimatedRidePrice,
  }) async {
    final tax = estimatedRidePrice * 0.08;
    final total = estimatedRidePrice + tax;
    final response = await ApiClient.post('/rides', {
      'userId': userId,
      'rideCategoryId': selectedCategory.id,
      'pickupLabel': pickup,
      'dropoffLabel': destination,
      'distanceKm': routeDistance,
      'estimatedFare': estimatedRidePrice,
      'tax': tax,
      'total': total,
      'etaLabel': selectedCategory.timeToArrive,
      'vehicleName': selectedCategory.name,
      'trackingData': {
        'payment': _payments[_selectedPayment],
        'distance': routeDistance,
      },
    });
    return Map<String, dynamic>.from(response as Map);
  }
}
