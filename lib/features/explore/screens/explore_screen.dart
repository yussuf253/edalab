import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_search_bar.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final services = [
      _ServiceItem(
        l10n.t('explore.food_delivery'),
        l10n.t('explore.restaurants_count'),
        Icons.restaurant_rounded,
        AppColors.food,
        '/food',
      ),
      _ServiceItem(
        l10n.t('explore.shopping'),
        l10n.t('explore.products_count'),
        Icons.shopping_bag_rounded,
        AppColors.shopping,
        '/shopping',
      ),
      _ServiceItem(
        l10n.t('explore.doctor'),
        l10n.t('explore.specialists_count'),
        Icons.medical_services_rounded,
        AppColors.doctor,
        '/doctor',
      ),
      _ServiceItem(
        l10n.t('explore.hotel'),
        l10n.t('explore.hotels_count'),
        Icons.hotel_rounded,
        AppColors.hotel,
        '/hotel',
      ),
      _ServiceItem(
        l10n.t('explore.ride'),
        l10n.t('explore.anywhere_anytime'),
        Icons.directions_car_rounded,
        AppColors.ride,
        '/ride',
      ),
      _ServiceItem(
        l10n.t('explore.pharmacy'),
        l10n.t('explore.medicines_count'),
        Icons.local_pharmacy_rounded,
        AppColors.pharmacy,
        '/pharmacy',
      ),
      _ServiceItem(
        l10n.t('explore.grocery'),
        l10n.t('explore.fresh_everyday'),
        Icons.eco_rounded,
        AppColors.grocery,
        '/grocery',
      ),
      _ServiceItem(
        l10n.t('explore.laundry'),
        l10n.t('explore.clean_fresh'),
        Icons.local_laundry_service_rounded,
        AppColors.laundry,
        '/laundry',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('explore.title'), style: AppTextStyles.h3),
        centerTitle: false,
      ),
      body: CustomScrollView(
        slivers: [
          // Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: AppSearchBar(
                hint: l10n.t('explore.search_hint'),
                readOnly: true,
                onTap: () => context.push('/search'),
              ),
            ),
          ),
          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(l10n.t('explore.all_services'), style: AppTextStyles.h4),
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
              child: Text(l10n.t('explore.quick_actions'), style: AppTextStyles.h4),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _ActionTile(
                    Icons.fastfood_rounded,
                    l10n.t('explore.order_food'),
                    l10n.t('explore.order_food_subtitle'),
                    AppColors.food,
                    () => context.push('/food'),
                  ),
                  _ActionTile(
                    Icons.directions_car_rounded,
                    l10n.t('explore.book_ride'),
                    l10n.t('explore.book_ride_subtitle'),
                    AppColors.ride,
                    () => context.push('/ride'),
                  ),
                  _ActionTile(
                    Icons.medical_services_rounded,
                    l10n.t('explore.consult_doctor'),
                    l10n.t('explore.consult_doctor_subtitle'),
                    AppColors.doctor,
                    () => context.push('/doctor'),
                  ),
                  _ActionTile(
                    Icons.local_laundry_service_rounded,
                    l10n.t('explore.laundry_pickup'),
                    l10n.t('explore.laundry_pickup_subtitle'),
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
