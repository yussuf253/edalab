import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/cart_model.dart';
import '../../../core/models/grocery_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class GroceryDetailScreen extends StatefulWidget {
  final String productId;

  const GroceryDetailScreen({super.key, required this.productId});

  @override
  State<GroceryDetailScreen> createState() => _GroceryDetailScreenState();
}

class _GroceryDetailScreenState extends State<GroceryDetailScreen> {
  late GroceryModel _item;
  bool _isLoading = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _item = GroceryModel.sampleItems.firstWhere(
      (item) => item.id == widget.productId,
      orElse: () => GroceryModel.sampleItems.first,
    );
    _loadItem();
  }

  Future<void> _loadItem() async {
    try {
      final response = await ApiClient.get(
        '/catalog/products/${widget.productId}',
      );
      if (!mounted) return;
      setState(() {
        _item = GroceryModel.fromApi(
          Map<String, dynamic>.from(response as Map),
        );
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.entityOpened,
        properties: {
          'module': 'grocery',
          'entity_type': 'product',
          'entity_id': _item.id,
          'source': 'grocery_detail',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _addToCart() {
    AnalyticsService.instance.track(
      AnalyticsEvents.cartAdjustmentInitiated,
      properties: {
        'module': 'grocery',
        'source': 'grocery_detail',
        'action': 'add',
        'entity_type': 'product',
        'entity_id': _item.id,
        'quantity': _quantity,
      },
    );
    context.read<CartProvider>().addItem(
      CartItem(
        id: _item.id,
        name: _item.name,
        brand: _item.unit,
        price: _item.price,
        quantity: _quantity,
        moduleType: 'grocery',
        imageUrl: _item.imageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final cartItemCount = cartProvider.getModuleItemCount('grocery');
    final moduleTotal = cartProvider.getModuleSubtotal('grocery');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.t('grocery_detail.title')),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.viewCartTapped,
                    properties: {
                      'module': 'grocery',
                      'source': 'grocery_detail_appbar',
                      'cart_item_count': cartItemCount,
                    },
                  );
                  context.push('/grocery/cart');
                },
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$cartItemCount',
                        style: AppTextStyles.badge.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _isLoading
            ? const DetailContentShimmer(accentColor: AppColors.grocery)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: AppColors.groceryBg,
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: Icon(
                          _groceryCategoryIcon(
                            _item.categoryName ?? _item.categoryId,
                          ),
                          size: 74,
                          color: AppColors.grocery,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.groceryBg,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _item.categoryName ?? l10n.t('module.grocery'),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.grocery,
                                ),
                              ),
                            ),
                            if (_item.isOrganic)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.t('grocery_detail.organic'),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(_item.name, style: AppTextStyles.h2),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _item.rating.toStringAsFixed(1),
                              style: AppTextStyles.labelLarge,
                            ),
                            const Spacer(),
                            Text(
                              '\$${_item.price.toStringAsFixed(2)}',
                              style: AppTextStyles.price.copyWith(
                                color: AppColors.grocery,
                              ),
                            ),
                            Text(
                              ' / ${_item.unit}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _DetailStat(
                                  icon: Icons.local_shipping_outlined,
                                  label: l10n.t('grocery_detail.delivery'),
                                  value: '20-35 min',
                                ),
                              ),
                              Expanded(
                                child: _DetailStat(
                                  icon: Icons.inventory_2_outlined,
                                  label: l10n.t('grocery_detail.unit'),
                                  value: _item.unit,
                                ),
                              ),
                              Expanded(
                                child: _DetailStat(
                                  icon: Icons.eco_outlined,
                                  label: l10n.t('grocery_detail.quality'),
                                  value: _item.isOrganic
                                      ? l10n.t('grocery_detail.organic')
                                      : l10n.t('grocery_detail.fresh'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.t('grocery_detail.description'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _item.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.t('grocery_detail.quantity'),
                          style: AppTextStyles.labelLarge,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.extraLightGrey,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () {
                                        AnalyticsService.instance.track(
                                          AnalyticsEvents
                                              .cartAdjustmentInitiated,
                                          properties: {
                                            'module': 'grocery',
                                            'source': 'grocery_detail_quantity',
                                            'action': 'decrement_selection',
                                            'entity_type': 'product',
                                            'entity_id': _item.id,
                                          },
                                        );
                                        setState(() => _quantity--);
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  '$_quantity',
                                  style: AppTextStyles.labelLarge,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  AnalyticsService.instance.track(
                                    AnalyticsEvents.cartAdjustmentInitiated,
                                    properties: {
                                      'module': 'grocery',
                                      'source': 'grocery_detail_quantity',
                                      'action': 'increment_selection',
                                      'entity_type': 'product',
                                      'entity_id': _item.id,
                                    },
                                  );
                                  setState(() => _quantity++);
                                },
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomSheet: _isLoading || cartItemCount > 0
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('grocery_detail.total'),
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${(_item.price * _quantity).toStringAsFixed(2)}',
                            style: AppTextStyles.price,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AppButton(
                        text: l10n.t('grocery_detail.add_to_cart'),
                        icon: Icons.shopping_bag_outlined,
                        color: AppColors.grocery,
                        onPressed: _addToCart,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: !_isLoading && cartItemCount > 0
          ? SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: FloatingActionButton.extended(
                onPressed: () {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.viewCartTapped,
                    properties: {
                      'module': 'grocery',
                      'source': 'grocery_detail_fab',
                      'cart_item_count': cartItemCount,
                    },
                  );
                  context.push('/grocery/cart');
                },
                backgroundColor: AppColors.grocery,
                label: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$cartItemCount', style: AppTextStyles.badge),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.t('grocery_detail.view_cart'),
                      style: AppTextStyles.button,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '\$${moduleTotal.toStringAsFixed(2)}',
                      style: AppTextStyles.button,
                    ),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _DetailStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.grocery, size: 20),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.labelMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

IconData _groceryCategoryIcon(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('fruit') || normalized.contains('veg')) {
    return Icons.apple_rounded;
  }
  if (normalized.contains('dairy') || normalized.contains('egg')) {
    return Icons.egg_alt_rounded;
  }
  if (normalized.contains('meat') || normalized.contains('seafood')) {
    return Icons.set_meal_rounded;
  }
  if (normalized.contains('bakery') || normalized.contains('bread')) {
    return Icons.bakery_dining_rounded;
  }
  if (normalized.contains('beverage') || normalized.contains('drink')) {
    return Icons.local_drink_rounded;
  }
  if (normalized.contains('snack')) {
    return Icons.cookie_rounded;
  }
  return Icons.shopping_basket_rounded;
}
