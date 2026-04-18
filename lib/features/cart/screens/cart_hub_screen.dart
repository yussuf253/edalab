import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class CartHubScreen extends StatefulWidget {
  const CartHubScreen({super.key});

  @override
  State<CartHubScreen> createState() => _CartHubScreenState();
}

class _CartHubScreenState extends State<CartHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartProvider>().refreshFromStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = context.watch<CartProvider>();
    final moduleProvider = context.watch<ModuleProvider>();

    final sections = [
      _CartModule(
        key: 'shopping',
        title: l10n.t('module.shopping'),
        subtitle: l10n.t('cart.shopping_subtitle'),
        route: '/shopping/cart',
        accent: AppColors.shopping,
        icon: Icons.shopping_bag_rounded,
        count: cart.getModuleItemCount('shopping'),
        subtotal: cart.getModuleSubtotal('shopping'),
      ),
      _CartModule(
        key: 'food',
        title: l10n.t('module.food'),
        subtitle: l10n.t('cart.food_subtitle'),
        route: '/food/cart',
        accent: AppColors.food,
        icon: Icons.restaurant_rounded,
        count: cart.getModuleItemCount('food'),
        subtotal: cart.getModuleSubtotal('food'),
      ),
      _CartModule(
        key: 'grocery',
        title: l10n.t('module.grocery'),
        subtitle: l10n.t('cart.grocery_subtitle'),
        route: '/grocery/cart',
        accent: AppColors.grocery,
        icon: Icons.local_grocery_store_rounded,
        count: cart.getModuleItemCount('grocery'),
        subtotal: cart.getModuleSubtotal('grocery'),
      ),
      _CartModule(
        key: 'pharmacy',
        title: l10n.t('module.pharmacy'),
        subtitle: l10n.t('cart.pharmacy_subtitle'),
        route: '/pharmacy/cart',
        accent: AppColors.pharmacy,
        icon: Icons.medication_rounded,
        count: cart.getModuleItemCount('pharmacy'),
        subtotal: cart.getModuleSubtotal('pharmacy'),
      ),
    ];

    final visibleSections = sections
        .where((section) => moduleProvider.isEnabled(section.key))
        .toList();

    final activeSections = visibleSections
        .where((section) => section.count > 0)
        .toList();
    final visibleItemCount = activeSections.fold<int>(
      0,
      (sum, section) => sum + section.count,
    );
    final visibleSubtotal = activeSections.fold<double>(
      0,
      (sum, section) => sum + section.subtotal,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.t('cart.title')), centerTitle: false),
      body: cart.isHydrating
          ? const CartHubShimmer()
          : CustomScrollView(
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
                                  l10n.t(
                                    'cart.items_waiting',
                                    params: {'count': '$visibleItemCount'},
                                  ),
                                  style: AppTextStyles.labelLarge,
                                ),
                                Text(
                                  l10n.t(
                                    'cart.estimated_subtotal',
                                    params: {
                                      'amount': visibleSubtotal.toStringAsFixed(
                                        2,
                                      ),
                                    },
                                  ),
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
                            Text(
                              l10n.t('cart.empty_title'),
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.t('cart.empty_subtitle'),
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
                              child: Text(l10n.t('cart.browse_services')),
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
                      child: Text(
                        l10n.t('cart.active_modules'),
                        style: AppTextStyles.h4,
                      ),
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
    final l10n = context.l10n;
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
                  l10n.t(
                    'cart.items_count',
                    params: {
                      'count': '${section.count}',
                      'suffix': section.count == 1 ? '' : 's',
                    },
                  ),
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
