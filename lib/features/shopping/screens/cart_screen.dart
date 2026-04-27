import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/auth_gate.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('shopping_cart.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final cart = context.read<CartProvider>();
              final items = cart.getModuleItems('shopping');
              AnalyticsService.instance.track(
                AnalyticsEvents.cartAdjustmentInitiated,
                properties: {
                  'module': 'shopping',
                  'source': 'shopping_cart',
                  'action': 'clear_module_cart',
                  'item_count': items.fold<int>(
                    0,
                    (sum, item) => sum + item.quantity,
                  ),
                },
              );
              context.read<CartProvider>().clearModuleCart('shopping');
            },
            child: Text(
              l10n.t('cart.clear'),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isHydrating) {
            return const ModuleCartShimmer();
          }

          final items = cart.getModuleItems('shopping');

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: AppColors.lightGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('shopping_cart.empty_title'),
                    style: AppTextStyles.h3.copyWith(color: AppColors.grey),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: l10n.t('shopping_cart.start'),
                    width: 200,
                    onPressed: () {
                      AnalyticsService.instance.track(
                        AnalyticsEvents.entityOpened,
                        properties: {
                          'module': 'shopping',
                          'entity_type': 'catalog',
                          'entity_id': 'shopping_home',
                          'source': 'shopping_cart_empty',
                        },
                      );
                      context.pop();
                    },
                  ),
                ],
              ),
            );
          }

          final subtotal = cart.getModuleSubtotal('shopping');
          final shipping = subtotal > 50 ? 0.0 : 5.99;
          final tax = subtotal * 0.08;
          final total = subtotal + shipping + tax;

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.extraLightGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              color: AppColors.lightGrey,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTextStyles.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    item.brand,
                                    item.color,
                                    item.size,
                                  ].where((e) => e != null).join(' • '),
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'DJF${item.price}',
                                      style: AppTextStyles.priceSmall,
                                    ),
                                    const Spacer(),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.extraLightGrey,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.remove,
                                                size: 16,
                                              ),
                                              onPressed: () {
                                                AnalyticsService.instance.track(
                                                  AnalyticsEvents
                                                      .cartAdjustmentInitiated,
                                                  properties: {
                                                    'module': 'shopping',
                                                    'source': 'shopping_cart',
                                                    'action': 'decrement',
                                                    'entity_type': 'product',
                                                    'entity_id': item.id,
                                                  },
                                                );
                                                cart.decrementQuantity(item.id);
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: AppTextStyles.labelMedium,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.add,
                                                size: 16,
                                              ),
                                              onPressed: () {
                                                AnalyticsService.instance.track(
                                                  AnalyticsEvents
                                                      .cartAdjustmentInitiated,
                                                  properties: {
                                                    'module': 'shopping',
                                                    'source': 'shopping_cart',
                                                    'action': 'increment',
                                                    'entity_type': 'product',
                                                    'entity_id': item.id,
                                                  },
                                                );
                                                cart.incrementQuantity(item.id);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
              // Order summary
              Container(
                padding: const EdgeInsets.all(20),
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
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _summaryRow(
                        l10n.t('cart.subtotal'),
                        'DJF${subtotal.toStringAsFixed(2)}',
                      ),
                      _summaryRow(
                        l10n.t('cart.shipping'),
                        shipping == 0
                            ? l10n.t('shopping_cart.free_upper')
                            : 'DJF${shipping.toStringAsFixed(2)}',
                      ),
                      _summaryRow(
                        l10n.t('cart.tax'),
                        'DJF${tax.toStringAsFixed(2)}',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(),
                      ),
                      _summaryRow(
                        l10n.t('cart.total'),
                        'DJF${total.toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        text: l10n.t(
                          'cart.checkout_amount',
                          params: {'amount': total.toStringAsFixed(2)},
                        ),
                        onPressed: () async {
                          AnalyticsService.instance.track(
                            AnalyticsEvents.checkoutEntryTapped,
                            properties: {
                              'module': 'shopping',
                              'source': 'shopping_cart',
                              'subtotal': subtotal,
                              'shipping': shipping,
                              'tax': tax,
                              'total': total,
                              'item_count': items.fold<int>(
                                0,
                                (sum, item) => sum + item.quantity,
                              ),
                            },
                          );
                          final allowed = await requireLoggedIn(
                            context,
                            message: l10n.t('cart.login_required'),
                          );
                          if (!context.mounted || !allowed) return;
                          context.push(
                            '/checkout',
                            extra: {
                              'moduleType': 'shopping',
                              'moduleName': l10n.t('shopping_cart.module_name'),
                              'source': 'shopping_cart',
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal
                ? AppTextStyles.labelLarge
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          Text(
            value,
            style: isTotal ? AppTextStyles.price : AppTextStyles.labelLarge,
          ),
        ],
      ),
    );
  }
}
