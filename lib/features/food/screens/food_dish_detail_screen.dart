import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/config/zone_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/money_format.dart';
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
  bool _hasTrackedDishView = false;

  // groupId -> selected optionIds within that group.
  final Map<String, Set<String>> _selectedOptions = {};
  bool _defaultsApplied = false;

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
      _trackDishViewed(source: 'route_extra');
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
      _trackDishViewed(source: 'local_sample_catalog');
      return;
    }

    try {
      final response = await ApiClient.get(ZoneScope.appendZone('/catalog/restaurants'));
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
      _trackDishViewed(
        source: remoteMatch == null ? 'remote_not_found' : 'remote_catalog',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _trackDishViewed({required String source}) {
    if (_hasTrackedDishView) return;
    final item = _item;
    if (item == null) return;
    _hasTrackedDishView = true;
    AnalyticsService.instance.track(
      AnalyticsEvents.entityOpened,
      properties: {
        'module': 'food',
        'entity_type': 'dish',
        'entity_id': item.id,
        'source': source,
        'restaurant_name': _restaurantName,
        'category': _categoryName,
        'price': item.price,
      },
    );
  }

  void _applyDefaultSelectionsIfNeeded(MenuItem item) {
    if (_defaultsApplied) return;
    _defaultsApplied = true;
    final needsDefaults = item.customizationGroups.any(
      (g) => g.required && g.options.isNotEmpty,
    );
    if (!needsDefaults) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        for (final group in item.customizationGroups) {
          if (group.required && group.options.isNotEmpty) {
            _selectedOptions.putIfAbsent(
              group.id,
              () => {group.options.first.id},
            );
          }
        }
      });
    });
  }

  void _toggleOption(CustomizationGroup group, CustomizationOption option) {
    setState(() {
      final current = _selectedOptions.putIfAbsent(group.id, () => {});
      if (group.multiSelect) {
        if (current.contains(option.id)) {
          current.remove(option.id);
        } else {
          if (group.maxSelections != null &&
              current.length >= group.maxSelections!) {
            return;
          }
          current.add(option.id);
        }
      } else {
        current
          ..clear()
          ..add(option.id);
      }
    });
  }

  double get _customizationsDelta {
    final item = _item;
    if (item == null) return 0;
    var total = 0.0;
    for (final group in item.customizationGroups) {
      final selected = _selectedOptions[group.id] ?? const {};
      for (final option in group.options) {
        if (selected.contains(option.id)) total += option.priceDelta;
      }
    }
    return total;
  }

  List<SelectedCustomization> get _selectedCustomizationsList {
    final item = _item;
    if (item == null) return const [];
    final result = <SelectedCustomization>[];
    for (final group in item.customizationGroups) {
      final selected = _selectedOptions[group.id] ?? const {};
      for (final option in group.options) {
        if (selected.contains(option.id)) {
          result.add(
            SelectedCustomization(
              groupId: group.id,
              groupName: group.name,
              optionId: option.id,
              optionName: option.name,
              priceDelta: option.priceDelta,
            ),
          );
        }
      }
    }
    return result;
  }

  bool get _requiredGroupsSatisfied {
    final item = _item;
    if (item == null) return true;
    for (final group in item.customizationGroups) {
      if (group.required && (_selectedOptions[group.id]?.isEmpty ?? true)) {
        return false;
      }
    }
    return true;
  }

  /// A stable signature for the current selection, used to give
  /// differently-customized cart lines of the same dish distinct IDs.
  String get _selectionSignature {
    final parts = _selectedCustomizationsList.map((s) => s.optionId).toList()
      ..sort();
    return parts.join('|');
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
    final wishlistProvider = context.watch<WishlistProvider>();
    final item = _item;
    if (item != null) {
      _applyDefaultSelectionsIfNeeded(item);
    }
    final existingItems = cartProvider.getModuleItems('food');
    final existing = existingItems.cast<CartItem?>().firstWhere(
      (cartItem) => cartItem?.id == widget.itemId,
      orElse: () => null,
    );
    final isFavorite = wishlistProvider.isFoodFavorite(widget.itemId);
    final quantity = existing?.quantity ?? _quantity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.t('food_detail.title')),
        actions: item == null
            ? null
            : [
                IconButton(
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.accent : null,
                  ),
                  splashRadius: 24,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  padding: const EdgeInsets.all(12),
                  onPressed: () async {
                    await wishlistProvider.toggleFoodFavorite(
                      itemId: widget.itemId,
                      title: item.name,
                      subtitle: _restaurantName,
                      price: item.price,
                      imageUrl: item.imageUrl,
                    );
                    if (!context.mounted) return;
                    AnalyticsService.instance.track(
                      AnalyticsEvents.wishlistToggled,
                      properties: {
                        'module': 'food',
                        'entity_type': 'dish',
                        'entity_id': item.id,
                        'is_favorite': !isFavorite,
                        'source': 'dish_detail',
                      },
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite
                              ? l10n.t('product_detail.removed_wishlist')
                              : l10n.t('product_detail.added_wishlist'),
                        ),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
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
                              'DJF${item.price.toStringAsFixed(2)}',
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
                        Text(
                          l10n.t('food_detail.description'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        for (final group in item.customizationGroups) ...[
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Text(group.name, style: AppTextStyles.h4),
                              if (group.required) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.food.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l10n.t('food_detail.required'),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.food,
                                    ),
                                  ),
                                ),
                              ] else if (group.multiSelect) ...[
                                const SizedBox(width: 8),
                                Text(
                                  l10n.t('food_detail.optional'),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...group.options.map((option) {
                            final isSelected = (_selectedOptions[group.id] ??
                                    const {})
                                .contains(option.id);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _toggleOption(group, option),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.food.withValues(alpha: 0.08)
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.food
                                          : AppColors.lightGrey,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        group.multiSelect
                                            ? (isSelected
                                                  ? Icons.check_box_rounded
                                                  : Icons
                                                        .check_box_outline_blank_rounded)
                                            : (isSelected
                                                  ? Icons
                                                        .radio_button_checked_rounded
                                                  : Icons
                                                        .radio_button_unchecked_rounded),
                                        size: 20,
                                        color: isSelected
                                            ? AppColors.food
                                            : AppColors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option.name,
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                      ),
                                      if (option.priceDelta > 0)
                                        Text(
                                          '+DJF${option.priceDelta.toStringAsFixed(0)}',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.food,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Text(
                              l10n.t('food_detail.quantity'),
                              style: AppTextStyles.h4,
                            ),
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
                                            AnalyticsService.instance.track(
                                              AnalyticsEvents
                                                  .cartAdjustmentInitiated,
                                              properties: {
                                                'module': 'food',
                                                'source': 'dish_detail',
                                                'action': 'decrement',
                                                'entity_type': 'dish',
                                                'entity_id': item.id,
                                              },
                                            );
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
                                      AnalyticsService.instance.track(
                                        AnalyticsEvents.cartAdjustmentInitiated,
                                        properties: {
                                          'module': 'food',
                                          'source': 'dish_detail',
                                          'action': 'increment',
                                          'entity_type': 'dish',
                                          'entity_id': item.id,
                                        },
                                      );
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
                : (item.customizationGroups.isEmpty && existing != null)
                ? l10n.t(
                    'food_detail.view_cart',
                    params: {
                      'amount': formatDjf(
                        cartProvider.getModuleSubtotal('food'),
                      ),
                    },
                  )
                : l10n.t(
                    'food_detail.add_to_cart',
                    params: {
                      'amount': formatDjf(
                        (item.price + _customizationsDelta) * quantity,
                      ),
                    },
                  ),
            color: AppColors.food,
            onPressed: () {
              if (item == null) {
                context.pop();
                return;
              }

              final hasCustomizations = item.customizationGroups.isNotEmpty;

              if (!hasCustomizations && existing != null) {
                AnalyticsService.instance.track(
                  AnalyticsEvents.viewCartTapped,
                  properties: {
                    'module': 'food',
                    'source': 'dish_detail',
                    'entity_id': item.id,
                    'cart_item_count': cartProvider.getModuleItemCount('food'),
                  },
                );
                context.push('/food/cart');
                return;
              }

              if (hasCustomizations && !_requiredGroupsSatisfied) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.t('food_detail.select_required')),
                  ),
                );
                return;
              }

              final unitPrice = item.price + _customizationsDelta;
              final selections = _selectedCustomizationsList;
              final cartLineId = hasCustomizations
                  ? '${item.id}::$_selectionSignature'
                  : item.id;

              cartProvider.addItem(
                CartItem(
                  id: cartLineId,
                  name: item.name,
                  price: unitPrice,
                  quantity: quantity,
                  moduleType: 'food',
                  brand: _restaurantName,
                  description: selections.isEmpty
                      ? null
                      : selections.map((s) => s.optionName).join(', '),
                ),
              );
              AnalyticsService.instance.track(
                AnalyticsEvents.checkoutEntryTapped,
                properties: {
                  'module': 'food',
                  'source': 'dish_detail',
                  'entity_type': 'dish',
                  'entity_id': item.id,
                  'quantity': quantity,
                  'unit_price': unitPrice,
                  'line_total': unitPrice * quantity,
                  'restaurant_name': _restaurantName,
                  'customizations': selections.map((s) => s.optionId).toList(),
                },
              );
              context.pop();
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
            Text(
              l10n.t('food_detail.not_found_title'),
              style: AppTextStyles.h3,
            ),
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
