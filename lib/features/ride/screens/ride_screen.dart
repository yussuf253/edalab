import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class RideScreen extends StatelessWidget {
  const RideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map placeholder
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.extraLightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('Map View', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12, right: 12,
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppSpacing.shadowMd,
                      ),
                      child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Where to?
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
                        width: 12, height: 12,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.extraLightGrey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Current Location', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Column(
                      children: List.generate(3, (_) => Container(
                        width: 2, height: 6,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: AppColors.lightGrey,
                      )),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12, height: 12,
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/ride/book'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.extraLightGrey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Where to?', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGrey)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Quick Rides
            Text('Quick Rides', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickRide(Icons.home_rounded, 'Home', '123 Main St'),
                const SizedBox(width: 12),
                _QuickRide(Icons.work_rounded, 'Work', '456 Office Ave'),
              ],
            ),
            const SizedBox(height: 24),
            // Recent Places
            Text('Recent Places', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...[
              ('City Mall', '789 Shopping Blvd', Icons.shopping_bag_rounded),
              ('Central Park', '321 Green Lane', Icons.park_rounded),
              ('Airport', 'International Airport', Icons.flight_rounded),
              ('Train Station', 'Central Station', Icons.train_rounded),
            ].map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.rideBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(p.$3, color: AppColors.ride, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.$1, style: AppTextStyles.labelMedium),
                        Text(p.$2, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mediumGrey),
                ],
              ),
            )),
            const SizedBox(height: 24),
            // Promo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('First 3 Rides Free! 🎉', style: AppTextStyles.h4.copyWith(color: AppColors.white)),
                        const SizedBox(height: 4),
                        Text('New users get first 3 rides completely free', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                    child: Text('Claim', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickRide extends StatelessWidget {
  final IconData icon;
  final String name, address;
  const _QuickRide(this.icon, this.name, this.address);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.rideBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.ride, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelMedium),
                  Text(address, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
