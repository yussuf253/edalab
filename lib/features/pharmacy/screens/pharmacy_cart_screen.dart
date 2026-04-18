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

class PharmacyCartScreen extends StatefulWidget {
  const PharmacyCartScreen({super.key});

  @override
  State<PharmacyCartScreen> createState() => _PharmacyCartScreenState();
}

class _PharmacyCartScreenState extends State<PharmacyCartScreen> {
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
    final cartProvider = context.watch<CartProvider>();
    if (cartProvider.isHydrating) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('pharmacy_cart.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const ModuleCartShimmer(),
      );
    }

    final items = cartProvider.getModuleItems('pharmacy');
    final subtotal = cartProvider.getModuleSubtotal('pharmacy');
    final deliveryFee = items.isEmpty ? 0.0 : 2.99;
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('pharmacy_cart.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                AnalyticsService.instance.track(
                  AnalyticsEvents.cartAdjustmentInitiated,
                  properties: {
                    'module': 'pharmacy',
                    'source': 'pharmacy_cart',
                    'action': 'clear_module_cart',
                    'item_count': items.fold<int>(
                      0,
                      (sum, item) => sum + item.quantity,
                    ),
                  },
                );
                cartProvider.clearModuleCart('pharmacy');
              },
              child: Text(
                l10n.t('cart.clear'),
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: AppColors.lightGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('pharmacy_cart.empty_title'),
                    style: AppTextStyles.h3.copyWith(color: AppColors.grey),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: l10n.t('pharmacy_cart.browse'),
                    width: 200,
                    color: AppColors.pharmacy,
                    onPressed: () {
                      AnalyticsService.instance.track(
                        AnalyticsEvents.entityOpened,
                        properties: {
                          'module': 'pharmacy',
                          'entity_type': 'catalog',
                          'entity_id': 'pharmacy_home',
                          'source': 'pharmacy_cart_empty',
                        },
                      );
                      context.pop();
                    },
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ItemRow(
                        name: item.name,
                        desc: item.brand ?? l10n.t('pharmacy_cart.medicine'),
                        price: item.price,
                        qty: item.quantity,
                        onIncrement: () => cartProvider.updateQuantity(
                          item.id,
                          item.quantity + 1,
                        ),
                        onDecrement: () => cartProvider.updateQuantity(
                          item.id,
                          item.quantity - 1,
                        ),
                        onTrackIncrement: () {
                          AnalyticsService.instance.track(
                            AnalyticsEvents.cartAdjustmentInitiated,
                            properties: {
                              'module': 'pharmacy',
                              'source': 'pharmacy_cart',
                              'action': 'increment',
                              'entity_type': 'medicine',
                              'entity_id': item.id,
                            },
                          );
                        },
                        onTrackDecrement: () {
                          AnalyticsService.instance.track(
                            AnalyticsEvents.cartAdjustmentInitiated,
                            properties: {
                              'module': 'pharmacy',
                              'source': 'pharmacy_cart',
                              'action': 'decrement',
                              'entity_type': 'medicine',
                              'entity_id': item.id,
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
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
                        _SumRow(
                          l10n.t('cart.subtotal'),
                          '\$${subtotal.toStringAsFixed(2)}',
                        ),
                        _SumRow(
                          l10n.t('cart.delivery'),
                          '\$${deliveryFee.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 20),
                        _SumRow(
                          l10n.t('cart.total'),
                          '\$${total.toStringAsFixed(2)}',
                          bold: true,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          text: l10n.t(
                            'cart.continue_checkout',
                            params: {'amount': total.toStringAsFixed(2)},
                          ),
                          color: AppColors.pharmacy,
                          onPressed: () async {
                            AnalyticsService.instance.track(
                              AnalyticsEvents.checkoutEntryTapped,
                              properties: {
                                'module': 'pharmacy',
                                'source': 'pharmacy_cart',
                                'subtotal': subtotal,
                                'delivery': deliveryFee,
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
                                'moduleType': 'pharmacy',
                                'moduleName': l10n.t(
                                  'pharmacy_cart.module_name',
                                ),
                                'source': 'pharmacy_cart',
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final String name, desc;
  final double price;
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onTrackIncrement;
  final VoidCallback onTrackDecrement;

  const _ItemRow({
    required this.name,
    required this.desc,
    required this.price,
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
    required this.onTrackIncrement,
    required this.onTrackDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.pharmacyBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: AppColors.pharmacy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(desc, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: AppTextStyles.priceSmall.copyWith(
                    color: AppColors.pharmacy,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.extraLightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    onTrackDecrement();
                    onDecrement();
                  },
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(Icons.remove, size: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text('$qty', style: AppTextStyles.labelMedium),
                ),
                GestureDetector(
                  onTap: () {
                    onTrackIncrement();
                    onIncrement();
                  },
                  child: const SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(Icons.add, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SumRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? AppTextStyles.labelLarge
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          Text(
            value,
            style: bold
                ? AppTextStyles.priceSmall.copyWith(color: AppColors.pharmacy)
                : AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
