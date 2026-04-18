import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/auth_gate.dart';

class FoodCartScreen extends StatefulWidget {
  const FoodCartScreen({super.key});

  @override
  State<FoodCartScreen> createState() => _FoodCartScreenState();
}

class _FoodCartScreenState extends State<FoodCartScreen> {
  double _tip = 2.0;
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartProvider>().refreshFromStorage();
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    if (cartProvider.isHydrating) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('food_cart.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: const ModuleCartShimmer(showHeaderCard: true),
      );
    }

    final items = cartProvider.getModuleItems('food');
    final subtotal = cartProvider.getModuleSubtotal('food');
    final restaurantName = items.isNotEmpty && items.first.brand != null
        ? items.first.brand!
        : 'Burger Palace';
    final restaurant = RestaurantModel.sampleRestaurants.firstWhere(
      (entry) => entry.name == restaurantName,
      orElse: () => RestaurantModel.sampleRestaurants.first,
    );
    final recommendedItems = restaurant.menu
        .expand((category) => category.items)
        .where(
          (menuItem) => !items.any((cartItem) => cartItem.id == menuItem.id),
        )
        .take(3)
        .toList();

    // Sample static fees
    final deliveryFee = items.isEmpty ? 0.0 : 2.99;
    final serviceFee = items.isEmpty ? 0.0 : 1.50;
    final tipAmount = items.isEmpty ? 0.0 : _tip;
    final total = subtotal + deliveryFee + serviceFee + tipAmount;
    final freeDeliveryGap = items.isEmpty
        ? 0.0
        : (25 - subtotal).clamp(0, 25).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('food_cart.title')),
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
                    'module': 'food',
                    'source': 'food_cart',
                    'action': 'clear_module_cart',
                    'item_count': items.fold<int>(
                      0,
                      (sum, item) => sum + item.quantity,
                    ),
                  },
                );
                cartProvider.clearModuleCart('food');
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
                  Icon(
                    Icons.fastfood_outlined,
                    size: 80,
                    color: AppColors.lightGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('food_cart.empty_title'),
                    style: AppTextStyles.h3.copyWith(color: AppColors.grey),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: l10n.t('food_cart.browse'),
                    width: 200,
                    color: AppColors.food,
                    onPressed: () {
                      AnalyticsService.instance.track(
                        AnalyticsEvents.entityOpened,
                        properties: {
                          'module': 'food',
                          'entity_type': 'catalog',
                          'entity_id': 'food_home',
                          'source': 'food_cart_empty',
                        },
                      );
                      context.go('/food');
                    },
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Restaurant name
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.foodBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.food,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurantName,
                              style: AppTextStyles.labelLarge,
                            ),
                            Text(
                              l10n.t('food_cart.eta'),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.foodBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.local_shipping_rounded,
                                color: AppColors.food,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    freeDeliveryGap > 0
                                        ? l10n.t(
                                            'food_cart.free_delivery_more',
                                            params: {
                                              'amount': freeDeliveryGap
                                                  .toStringAsFixed(2),
                                            },
                                          )
                                        : l10n.t(
                                            'food_cart.free_delivery_unlocked',
                                          ),
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.food,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: (subtotal / 25).clamp(0, 1),
                                      minHeight: 7,
                                      backgroundColor: AppColors.white,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            AppColors.food,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...items.map(
                        (item) => _CartRow(
                          name: item.name,
                          qty: item.quantity,
                          price: item.price,
                          brand: item.brand,
                          onIncrement: () {
                            AnalyticsService.instance.track(
                              AnalyticsEvents.cartAdjustmentInitiated,
                              properties: {
                                'module': 'food',
                                'source': 'food_cart',
                                'action': 'increment',
                                'entity_type': 'dish',
                                'entity_id': item.id,
                              },
                            );
                            cartProvider.updateQuantity(
                              item.id,
                              item.quantity + 1,
                            );
                          },
                          onDecrement: () {
                            AnalyticsService.instance.track(
                              AnalyticsEvents.cartAdjustmentInitiated,
                              properties: {
                                'module': 'food',
                                'source': 'food_cart',
                                'action': 'decrement',
                                'entity_type': 'dish',
                                'entity_id': item.id,
                              },
                            );
                            cartProvider.updateQuantity(
                              item.id,
                              item.quantity - 1,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Add instructions
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.note_alt_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.t('food_cart.instructions'),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _instructionsController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: l10n.t('food_cart.instructions_hint'),
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.mediumGrey,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.all(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tip
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('food_cart.delivery_tip'),
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [0.0, 1.0, 2.0, 5.0].map((t) {
                                final isSelected = t == _tip;
                                final label = t == 0.0
                                    ? l10n.t('food_cart.none')
                                    : '\$${t.toInt()}';
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final previous = _tip;
                                      setState(() => _tip = t);
                                      if (previous == t) return;
                                      AnalyticsService.instance.track(
                                        AnalyticsEvents.cartTipChanged,
                                        properties: {
                                          'module': 'food',
                                          'source': 'food_cart',
                                          'previous_tip': previous,
                                          'selected_tip': t,
                                        },
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.food
                                            : AppColors.extraLightGrey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: isSelected
                                                    ? AppColors.white
                                                    : AppColors.dark,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      if (recommendedItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.t(
                            'food_cart.add_more_from',
                            params: {'name': restaurantName},
                          ),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 10),
                        ...recommendedItems.map(
                          (menuItem) => _RecommendedFoodCard(
                            item: menuItem,
                            onAdd: () {
                              cartProvider.addItem(
                                CartItem(
                                  id: menuItem.id,
                                  name: menuItem.name,
                                  price: menuItem.price,
                                  quantity: 1,
                                  moduleType: 'food',
                                  brand: restaurantName,
                                ),
                              );
                              AnalyticsService.instance.track(
                                AnalyticsEvents.checkoutEntryTapped,
                                properties: {
                                  'module': 'food',
                                  'source': 'food_cart_recommended',
                                  'entity_type': 'dish',
                                  'entity_id': menuItem.id,
                                  'quantity': 1,
                                  'unit_price': menuItem.price,
                                  'line_total': menuItem.price,
                                  'restaurant_name': restaurantName,
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Summary
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
                        _SummLine(
                          l10n.t('cart.subtotal'),
                          '\$${subtotal.toStringAsFixed(2)}',
                        ),
                        _SummLine(
                          l10n.t('cart.delivery'),
                          '\$${deliveryFee.toStringAsFixed(2)}',
                        ),
                        _SummLine(
                          l10n.t('cart.tip'),
                          '\$${tipAmount.toStringAsFixed(2)}',
                        ),
                        _SummLine(
                          l10n.t('cart.service_fee'),
                          '\$${serviceFee.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 24),
                        _SummLine(
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
                          color: AppColors.food,
                          onPressed: () async {
                            AnalyticsService.instance.track(
                              AnalyticsEvents.checkoutEntryTapped,
                              properties: {
                                'module': 'food',
                                'source': 'food_cart',
                                'subtotal': subtotal,
                                'delivery_fee': deliveryFee,
                                'service_fee': serviceFee,
                                'tip': tipAmount,
                                'total': total,
                                'item_count': items.fold<int>(
                                  0,
                                  (sum, item) => sum + item.quantity,
                                ),
                                'has_instructions': _instructionsController.text
                                    .trim()
                                    .isNotEmpty,
                                'instructions_length': _instructionsController
                                    .text
                                    .trim()
                                    .length,
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
                                'moduleType': 'food',
                                'moduleName': restaurantName,
                                'instructions': _instructionsController.text
                                    .trim(),
                                'tip': _tip,
                                'source': 'food_cart',
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

class _CartRow extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String? brand;

  const _CartRow({
    required this.name,
    required this.qty,
    required this.price,
    required this.onIncrement,
    required this.onDecrement,
    this.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.extraLightGrey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.fastfood_rounded,
              color: AppColors.food.withValues(alpha: 0.3),
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
                if (brand != null) Text(brand!, style: AppTextStyles.caption),
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: AppTextStyles.priceSmall.copyWith(fontSize: 13),
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
                  onTap: onDecrement,
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
                  onTap: onIncrement,
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

class _RecommendedFoodCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onAdd;

  const _RecommendedFoodCard({required this.item, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.foodBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.food,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: AppTextStyles.priceSmall,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.food,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Add',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummLine extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SummLine(this.label, this.value, {this.bold = false});

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
            style: bold ? AppTextStyles.price : AppTextStyles.labelLarge,
          ),
        ],
      ),
    );
  }
}
