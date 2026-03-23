import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final coupons = [
      _Coupon('FIRST50', '50% Off', 'First order discount', 'Valid till Mar 30', AppColors.primary, true),
      _Coupon('SAVE20', '20% Off', 'On orders above \$50', 'Valid till Apr 5', AppColors.food, true),
      _Coupon('FRESH30', '30% Off', 'Fresh grocery items', 'Valid till Apr 10', AppColors.grocery, true),
      _Coupon('RIDE3', '3 Free Rides', 'New users only', 'Valid till Apr 15', AppColors.ride, false),
      _Coupon('CLEAN25', '25% Off', 'Laundry services', 'Valid till Apr 20', AppColors.laundry, true),
      _Coupon('HEALTH10', '\$10 Off', 'Doctor consultations', 'Valid till Apr 25', AppColors.doctor, false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Coupons & Rewards'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: CustomScrollView(
        slivers: [
          // Reward points card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('My Rewards', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Gold Member', style: AppTextStyles.badge.copyWith(fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('2,450', style: AppTextStyles.h1.copyWith(color: AppColors.white, fontSize: 40)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('points', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('550 pts to Platinum', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                            Text('3000 pts', style: AppTextStyles.caption.copyWith(color: Colors.white60)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 2450 / 3000,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation(AppColors.white),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Active coupons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Available Coupons', style: AppTextStyles.h4),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final c = coupons[index];
              return Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Row(
                  children: [
                    // Left color strip
                    Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        color: c.color,
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(c.discount, style: AppTextStyles.h4.copyWith(color: AppColors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(c.code, style: AppTextStyles.labelLarge),
                                const Spacer(),
                                if (c.active)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: c.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Copy', style: AppTextStyles.labelSmall.copyWith(color: c.color)),
                                  )
                                else
                                  Text('Used', style: AppTextStyles.caption.copyWith(color: AppColors.mediumGrey)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.desc, style: AppTextStyles.bodySmall),
                            const SizedBox(height: 4),
                            Text(c.validity, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: coupons.length),
          ),

          // Earn more points
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Earn More Points', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  ...[
                    ('Order Food', '+50 pts per order', Icons.restaurant_rounded, AppColors.food),
                    ('Book a Ride', '+30 pts per ride', Icons.directions_car_rounded, AppColors.ride),
                    ('Shop Online', '+100 pts per \$50 spent', Icons.shopping_bag_rounded, AppColors.shopping),
                    ('Refer a Friend', '+500 pts per referral', Icons.group_add_rounded, AppColors.primary),
                  ].map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: e.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(e.$3, color: e.$4, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.$1, style: AppTextStyles.labelMedium),
                              Text(e.$2, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mediumGrey),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Coupon {
  final String code, discount, desc, validity;
  final Color color;
  final bool active;
  _Coupon(this.code, this.discount, this.desc, this.validity, this.color, this.active);
}
