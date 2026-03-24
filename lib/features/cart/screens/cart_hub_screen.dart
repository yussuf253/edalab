import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/providers.dart';

class CartHubScreen extends StatelessWidget {
  const CartHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    final sections = [
      _CartModule(
        key: 'shopping',
        title: 'Shopping',
        subtitle: 'Fashion, gadgets, and essentials',
        route: '/shopping/cart',
        accent: AppColors.shopping,
        icon: Icons.shopping_bag_rounded,
        count: cart.getModuleItemCount('shopping'),
        subtotal: cart.getModuleSubtotal('shopping'),
      ),
      _CartModule(
        key: 'food',
        title: 'Food',
        subtitle: 'Meals, drinks, and restaurant extras',
        route: '/food/cart',
        accent: AppColors.food,
        icon: Icons.restaurant_rounded,
        count: cart.getModuleItemCount('food'),
        subtotal: cart.getModuleSubtotal('food'),
      ),
      _CartModule(
        key: 'grocery',
        title: 'Grocery',
        subtitle: 'Fresh picks and pantry staples',
        route: '/grocery/cart',
        accent: AppColors.grocery,
        icon: Icons.local_grocery_store_rounded,
        count: cart.getModuleItemCount('grocery'),
        subtotal: cart.getModuleSubtotal('grocery'),
      ),
      _CartModule(
        key: 'pharmacy',
        title: 'Pharmacy',
        subtitle: 'Wellness, care, and refill items',
        route: '/pharmacy/cart',
        accent: AppColors.pharmacy,
        icon: Icons.medication_rounded,
        count: cart.getModuleItemCount('pharmacy'),
        subtotal: cart.getModuleSubtotal('pharmacy'),
      ),
    ];

    final activeSections = sections
        .where((section) => section.count > 0)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Cart'), centerTitle: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_checkout_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.itemCount} items waiting',
                            style: AppTextStyles.labelLarge,
                          ),
                          Text(
                            'Estimated subtotal \$${cart.subtotal.toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (activeSections.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.shopping_cart_outlined,
                          color: AppColors.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Your carts are empty', style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text(
                        'Add items from shopping, food, grocery, or pharmacy and they will show up here.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: () => context.go('/'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Browse Services'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Text('Active Module Carts', style: AppTextStyles.h4),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final section = activeSections[index];
                return _CartModuleTile(section: section);
              }, childCount: activeSections.length),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }
}

class _CartModuleTile extends StatelessWidget {
  const _CartModuleTile({required this.section});

  final _CartModule section;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(section.route),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: section.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(section.icon, color: section.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    section.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${section.count} items',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: section.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${section.subtotal.toStringAsFixed(2)}',
                  style: AppTextStyles.priceSmall.copyWith(
                    color: section.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CartModule {
  const _CartModule({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.accent,
    required this.icon,
    required this.count,
    required this.subtotal,
  });

  final String key;
  final String title;
  final String subtitle;
  final String route;
  final Color accent;
  final IconData icon;
  final int count;
  final double subtotal;
}
