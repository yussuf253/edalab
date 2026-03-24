import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_search_bar.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      _ServiceItem(
        'Food Delivery',
        '200+ restaurants',
        Icons.restaurant_rounded,
        AppColors.food,
        '/food',
      ),
      _ServiceItem(
        'Shopping',
        '500+ products',
        Icons.shopping_bag_rounded,
        AppColors.shopping,
        '/shopping',
      ),
      _ServiceItem(
        'Doctor',
        '100+ specialists',
        Icons.medical_services_rounded,
        AppColors.doctor,
        '/doctor',
      ),
      _ServiceItem(
        'Hotel',
        '50+ hotels',
        Icons.hotel_rounded,
        AppColors.hotel,
        '/hotel',
      ),
      _ServiceItem(
        'Ride',
        'Anywhere, anytime',
        Icons.directions_car_rounded,
        AppColors.ride,
        '/ride',
      ),
      _ServiceItem(
        'Pharmacy',
        '1000+ medicines',
        Icons.local_pharmacy_rounded,
        AppColors.pharmacy,
        '/pharmacy',
      ),
      _ServiceItem(
        'Grocery',
        'Fresh everyday',
        Icons.eco_rounded,
        AppColors.grocery,
        '/grocery',
      ),
      _ServiceItem(
        'Laundry',
        'Clean & fresh',
        Icons.local_laundry_service_rounded,
        AppColors.laundry,
        '/laundry',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Explore', style: AppTextStyles.h3),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: AppSearchBar(
                hint: 'Search services, products, doctors...',
                readOnly: true,
                onTap: () => context.push('/search'),
              ),
            ),
          ),
          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text('All Services', style: AppTextStyles.h4),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final s = services[index];
                return GestureDetector(
                  onTap: () => context.push(s.route),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(s.icon, color: s.color, size: 28),
                        ),
                        const SizedBox(height: 10),
                        Text(s.name, style: AppTextStyles.labelMedium),
                        const SizedBox(height: 2),
                        Text(s.desc, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                );
              }, childCount: services.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
            ),
          ),
          // Popular Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Quick Actions', style: AppTextStyles.h4),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ActionTile(
                    Icons.fastfood_rounded,
                    'Order Food',
                    'Hungry? Order from 200+ restaurants',
                    AppColors.food,
                    () => context.push('/food'),
                  ),
                  _ActionTile(
                    Icons.directions_car_rounded,
                    'Book a Ride',
                    'Get where you need to go',
                    AppColors.ride,
                    () => context.push('/ride'),
                  ),
                  _ActionTile(
                    Icons.medical_services_rounded,
                    'Consult Doctor',
                    'Talk to a specialist now',
                    AppColors.doctor,
                    () => context.push('/doctor'),
                  ),
                  _ActionTile(
                    Icons.local_laundry_service_rounded,
                    'Laundry Pickup',
                    'Schedule a pickup today',
                    AppColors.laundry,
                    () => context.push('/laundry'),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String name, desc, route;
  final IconData icon;
  final Color color;
  _ServiceItem(this.name, this.desc, this.icon, this.color, this.route);
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.onTap,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  Text(subtitle, style: AppTextStyles.caption),
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
  }
}
