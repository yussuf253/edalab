import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class FoodDishDetailScreen extends StatefulWidget {
  final String itemId;
  final MenuItem? item;
  final String? restaurantName;
  final String? categoryName;

  const FoodDishDetailScreen({
    super.key,
    required this.itemId,
    this.item,
    this.restaurantName,
    this.categoryName,
  });

  @override
  State<FoodDishDetailScreen> createState() => _FoodDishDetailScreenState();
}

class _FoodDishDetailScreenState extends State<FoodDishDetailScreen> {
  int _quantity = 1;
  MenuItem? _item;
  String _restaurantName = 'Restaurant';
  String _categoryName = 'Menu';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _restaurantName = widget.restaurantName ?? _restaurantName;
    _categoryName = widget.categoryName ?? _categoryName;
    _hydrateDish();
  }

  Future<void> _hydrateDish() async {
    if (_item != null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    final localMatch = _findDishInRestaurants(
      RestaurantModel.sampleRestaurants,
    );
    if (localMatch != null) {
      if (!mounted) return;
      setState(() {
        _item = localMatch.item;
        _restaurantName = localMatch.restaurantName;
        _categoryName = localMatch.categoryName;
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiClient.get('/catalog/restaurants');
      final restaurants = (response as List)
          .map(
            (item) =>
                RestaurantModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      final remoteMatch = _findDishInRestaurants(restaurants);
      if (!mounted) return;
      setState(() {
        _item = remoteMatch?.item;
        _restaurantName = remoteMatch?.restaurantName ?? _restaurantName;
        _categoryName = remoteMatch?.categoryName ?? _categoryName;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  _DishLookupResult? _findDishInRestaurants(List<RestaurantModel> restaurants) {
    for (final restaurant in restaurants) {
      for (final category in restaurant.menu) {
        for (final item in category.items) {
          if (item.id == widget.itemId) {
            return _DishLookupResult(
              item: item,
              restaurantName: restaurant.name,
              categoryName: category.name,
            );
          }
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final item = _item;
    final existingItems = cartProvider.getModuleItems('food');
    final existing = existingItems.cast<CartItem?>().firstWhere(
      (cartItem) => cartItem?.id == widget.itemId,
      orElse: () => null,
    );
    final quantity = existing?.quantity ?? _quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.t('food_detail.title')),
      ),
      body: _isLoading
          ? const SingleChildScrollView(
              child: DetailContentShimmer(accentColor: AppColors.food),
            )
          : item == null
          ? _DishNotFoundState(itemId: widget.itemId)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 280,
                    width: double.infinity,
                    color: AppColors.extraLightGrey,
                    child: Center(
                      child: Icon(
                        Icons.fastfood_rounded,
                        size: 90,
                        color: AppColors.food.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _categoryName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.food,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(item.name, style: AppTextStyles.h2),
                        const SizedBox(height: 6),
                        Text(
                          _restaurantName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: AppTextStyles.price.copyWith(fontSize: 28),
                            ),
                            if (item.isPopular) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.foodBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.t('food_detail.popular_choice'),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.food,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(l10n.t('food_detail.description'), style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        if ((item.customizations ?? const []).isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n.t('food_detail.customizations'),
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (item.customizations ?? const [])
                                .map(
                                  (option) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.lightGrey,
                                      ),
                                    ),
                                    child: Text(
                                      option,
                                      style: AppTextStyles.labelSmall,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Text(l10n.t('food_detail.quantity'), style: AppTextStyles.h4),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.lightGrey),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: quantity > 1
                                        ? () {
                                            if (existing != null) {
                                              cartProvider.updateQuantity(
                                                item.id,
                                                quantity - 1,
                                              );
                                            } else {
                                              setState(() => _quantity -= 1);
                                            }
                                          }
                                        : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (existing != null) {
                                        cartProvider.updateQuantity(
                                          item.id,
                                          quantity + 1,
                                        );
                                      } else {
                                        setState(() => _quantity += 1);
                                      }
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: AppColors.white),
        child: SafeArea(
          child: AppButton(
            text: item == null
                ? l10n.t('food_detail.back_to_menu')
                : existing == null
                ? l10n.t(
                    'food_detail.add_to_cart',
                    params: {
                      'amount': (item.price * quantity).toStringAsFixed(2),
                    },
                  )
                : l10n.t(
                    'food_detail.view_cart',
                    params: {
                      'amount': cartProvider
                          .getModuleSubtotal('food')
                          .toStringAsFixed(2),
                    },
                  ),
            color: AppColors.food,
            onPressed: () {
              if (item == null) {
                context.pop();
              } else if (existing == null) {
                cartProvider.addItem(
                  CartItem(
                    id: item.id,
                    name: item.name,
                    price: item.price,
                    quantity: quantity,
                    moduleType: 'food',
                    brand: _restaurantName,
                  ),
                );
                context.pop();
              } else {
                context.push('/food/cart');
              }
            },
          ),
        ),
      ),
    );
  }
}

class _DishLookupResult {
  final MenuItem item;
  final String restaurantName;
  final String categoryName;

  const _DishLookupResult({
    required this.item,
    required this.restaurantName,
    required this.categoryName,
  });
}

class _DishNotFoundState extends StatelessWidget {
  final String itemId;

  const _DishNotFoundState({required this.itemId});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood_outlined,
              size: 56,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 12),
            Text(l10n.t('food_detail.not_found_title'), style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              l10n.t(
                'food_detail.not_found_subtitle',
                params: {'itemId': itemId},
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
