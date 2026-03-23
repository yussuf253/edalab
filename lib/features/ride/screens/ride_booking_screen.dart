import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/models/models.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});
  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  int _selectedVehicle = 0;

  IconData _getIconForCategory(String name) {
    if (name.toLowerCase().contains('xl')) return Icons.airport_shuttle_rounded;
    if (name.toLowerCase().contains('premium')) return Icons.local_taxi_rounded;
    return Icons.directions_car_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final categories = RideModel.sampleCategories;
    final routeDistance = 5.2;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose a Ride'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
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
                    Icon(Icons.route_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text('Route: $routeDistance km • 12 min', style: AppTextStyles.bodySmall),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route summary
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('123 Main Street', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.mediumGrey),
                      const SizedBox(width: 12),
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('City Mall', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Choose Vehicle', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final estPrice = cat.basePrice + (cat.pricePerMile * routeDistance);
                        final sel = _selectedVehicle == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedVehicle = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.rideBg : AppColors.extraLightGrey,
                              borderRadius: BorderRadius.circular(14),
                              border: sel ? Border.all(color: AppColors.ride, width: 2) : null,
                            ),
                            child: Row(
                              children: [
                                Icon(_getIconForCategory(cat.name), color: sel ? AppColors.ride : AppColors.grey, size: 32),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(cat.name, style: AppTextStyles.labelLarge),
                                      Text('${cat.timeToArrive} away • ${cat.capacity} seats', style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                Text('\$${estPrice.toStringAsFixed(2)}', style: AppTextStyles.priceSmall.copyWith(
                                  color: sel ? AppColors.ride : AppColors.dark,
                                )),
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
                        const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text('•••• 4242', style: AppTextStyles.labelMedium),
                        const Spacer(),
                        Text('Change', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SafeArea(
                    child: AppButton(
                      text: 'Confirm Ride • \$${(categories[_selectedVehicle].basePrice + categories[_selectedVehicle].pricePerMile * routeDistance).toStringAsFixed(2)}',
                      color: AppColors.ride,
                      onPressed: () async {
                        final estPrice = categories[_selectedVehicle].basePrice + categories[_selectedVehicle].pricePerMile * routeDistance;
                        final auth = context.read<AuthProvider>();
                        try {
                          await ApiClient.post('/orders', {
                            'userId': auth.user?.id ?? 'guest',
                            'moduleType': 'RIDE',
                            'subtotal': estPrice,
                            'tax': estPrice * 0.08,
                            'deliveryFee': 0,
                            'total': estPrice * 1.08,
                            'items': [{'vehicle': categories[_selectedVehicle].name, 'distance': routeDistance}],
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Ride confirmed! Driver is on the way 🚗'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          context.go('/ride/tracking/r1');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
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
}
