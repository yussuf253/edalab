import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'top_rated';
  String _selectedCategoryFilter = 'all';
  String _searchQuery = '';
  List<RestaurantModel> _restaurants = RestaurantModel.sampleRestaurants;
  bool _isLoading = true;
  Timer? _searchDebounce;
  String _lastTrackedSearch = '';

  final _sorts = ['top_rated', 'fastest', 'free_delivery'];
  final _preferredCategoryOrder = const [
    'Burgers & Fast Food',
    'Pizza & Italian',
    'Tacos & Mexican',
    'Coffee & Cafe',
    'Bakery & Desserts',
    'Sushi & Asian',
    'BBQ, Grill & Kebab',
    'Middle Eastern',
    'Healthy & Salad',
    'Ice Cream & Frozen Treats',
    'Indian',
    'General Restaurants',
    'International & Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    try {
      final response = await ApiClient.get('/catalog/restaurants');
      final items = (response as List)
          .map(
            (item) =>
                RestaurantModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _restaurants = items.isEmpty
            ? RestaurantModel.sampleRestaurants
            : items;
        final categoryKeys = _restaurants
            .map((restaurant) => _categoryKey(restaurant.category))
            .toSet();
        if (_selectedCategoryFilter != 'all' &&
            !categoryKeys.contains(_selectedCategoryFilter)) {
          _selectedCategoryFilter = 'all';
        }
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'food',
          'entity_type': 'restaurant',
          'result_count': _restaurants.length,
          'source': 'remote',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _restaurants = RestaurantModel.sampleRestaurants;
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'food',
          'entity_type': 'restaurant',
          'result_count': _restaurants.length,
          'source': 'fallback_sample',
        },
      );
    }
  }

  void _onSearchChanged(String value) {
    final nextQuery = value.trim();
    setState(() => _searchQuery = nextQuery);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      final normalizedQuery = nextQuery.toLowerCase();
      if (normalizedQuery == _lastTrackedSearch) return;
      _lastTrackedSearch = normalizedQuery;
      if (normalizedQuery.isNotEmpty && normalizedQuery.length < 2) return;

      AnalyticsService.instance.track(
        AnalyticsEvents.searchPerformed,
        properties: {
          'module': 'food',
          'query': normalizedQuery,
          'query_length': normalizedQuery.length,
          'sort_key': _selectedSort,
          'result_count': _filteredRestaurants().length,
        },
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartItemCount = context.watch<CartProvider>().getModuleItemCount(
      'food',
    );
    final restaurants = _filteredRestaurants();
    final quickCategories = _buildFoodCategories(l10n);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('food.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () {
                    AnalyticsService.instance.track(
                      AnalyticsEvents.viewCartTapped,
                      properties: {
                        'module': 'food',
                        'source': 'food_screen',
                        'cart_item_count': cartItemCount,
                      },
                    );
                    context.push('/food/cart');
                  },
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
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: AppSearchBar(
                  hint: l10n.t('food.search_hint'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  suffix: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.mediumGrey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  children: quickCategories
                      .map(
                        (category) => _FoodCategory(
                          icon: category.icon,
                          name: category.label,
                          color: category.color,
                          isSelected: _selectedCategoryFilter == category.id,
                          onTap: () {
                            setState(
                              () => _selectedCategoryFilter = category.id,
                            );
                            AnalyticsService.instance.track(
                              AnalyticsEvents.filterApplied,
                              properties: {
                                'module': 'food',
                                'filter_type': 'quick_category',
                                'filter_value': category.label,
                                'result_count': _filteredRestaurants().length,
                              },
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  itemCount: _sorts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final sort = _sorts[index];
                    final isSelected = _selectedSort == sort;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSort = sort);
                        AnalyticsService.instance.track(
                          AnalyticsEvents.sortApplied,
                          properties: {
                            'module': 'food',
                            'sort_key': sort,
                            'query': _searchQuery.trim().toLowerCase(),
                            'result_count': _filteredRestaurants().length,
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sort == 'fastest'
                                  ? Icons.bolt_rounded
                                  : sort == 'free_delivery'
                                  ? Icons.delivery_dining_rounded
                                  : Icons.star_rounded,
                              size: 16,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _sortLabel(l10n, sort),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 4),
                child: Text(
                  l10n.t('food.popular_nearby'),
                  style: AppTextStyles.h3,
                ),
              ),
            ),
            if (_isLoading) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverSectionListShimmer(itemCount: 5),
            ] else if (restaurants.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 44,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.t('food.no_restaurants'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.t('food.no_restaurants_subtitle'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final restaurant = restaurants[index];
                  return GestureDetector(
                    onTap: () {
                      AnalyticsService.instance.track(
                        AnalyticsEvents.entityOpened,
                        properties: {
                          'module': 'food',
                          'entity_type': 'restaurant',
                          'entity_id': restaurant.id,
                          'position': index + 1,
                          'result_count': restaurants.length,
                          'sort_key': _selectedSort,
                          'query': _searchQuery.trim().toLowerCase(),
                        },
                      );
                      context.push('/food/restaurant/${restaurant.id}');
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.food.withValues(alpha: 0.3),
                                  AppColors.food.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child:
                                restaurant.imageUrl != null &&
                                    restaurant.imageUrl!.trim().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      restaurant.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.restaurant_rounded,
                                        color: AppColors.food.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 36,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.restaurant_rounded,
                                    color: AppColors.food.withValues(
                                      alpha: 0.5,
                                    ),
                                    size: 36,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        restaurant.name,
                                        style: AppTextStyles.labelLarge,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: restaurant.isOpen
                                            ? AppColors.successLight
                                            : AppColors.errorLight,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        restaurant.isOpen
                                            ? l10n.t('food.open')
                                            : l10n.t('food.closed'),
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              color: restaurant.isOpen
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  restaurant.cuisine,
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: restaurant.tags.take(2).map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.foodBg,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: AppTextStyles.labelSmall
                                            .copyWith(color: AppColors.food),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${restaurant.rating}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.dark,
                                      ),
                                    ),
                                    Text(
                                      ' (${restaurant.reviewCount}+)',
                                      style: AppTextStyles.caption,
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 14,
                                      color: AppColors.mediumGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${restaurant.deliveryTime} min',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.delivery_dining_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      restaurant.deliveryFee == 'Free'
                                          ? l10n.t('food.free_delivery')
                                          : l10n.t(
                                              'food.delivery_fee',
                                              params: {
                                                'fee': restaurant.deliveryFee,
                                              },
                                            ),
                                      style: AppTextStyles.caption.copyWith(
                                        color: restaurant.deliveryFee == 'Free'
                                            ? AppColors.success
                                            : AppColors.grey,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${restaurant.distance.toStringAsFixed(1)} km',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: restaurants.length),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  List<RestaurantModel> _filteredRestaurants() {
    final query = _normalize(_searchQuery);

    final filtered = _restaurants.where((restaurant) {
      final searchableCuisine = _normalize(restaurant.cuisine);
      final searchableName = _normalize(restaurant.name);
      final searchableTags = restaurant.tags.map(_normalize).toList();
      final categoryMatches =
          _selectedCategoryFilter == 'all' ||
          _categoryKey(restaurant.category) == _selectedCategoryFilter;

      final matchesQuery =
          query.isEmpty ||
          searchableName.contains(query) ||
          searchableCuisine.contains(query) ||
          searchableTags.any((tag) => tag.contains(query)) ||
          restaurant.menu.expand((category) => category.items).any((item) {
            return _normalize(item.name).contains(query) ||
                _normalize(item.description).contains(query);
          });
      return categoryMatches && matchesQuery;
    }).toList();

    if (_selectedSort == 'fastest') {
      filtered.sort(
        (a, b) => _deliveryMinutes(
          a.deliveryTime,
        ).compareTo(_deliveryMinutes(b.deliveryTime)),
      );
    } else if (_selectedSort == 'free_delivery') {
      filtered.sort((a, b) {
        final aFree = a.deliveryFee == 'Free' ? 0 : 1;
        final bFree = b.deliveryFee == 'Free' ? 0 : 1;
        return aFree.compareTo(bFree);
      });
    } else {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return filtered;
  }

  String _sortLabel(AppLocalizations l10n, String sort) {
    switch (sort) {
      case 'fastest':
        return l10n.t('food.sort_fastest');
      case 'free_delivery':
        return l10n.t('food.sort_free_delivery');
      case 'top_rated':
      default:
        return l10n.t('food.sort_top_rated');
    }
  }

  int _deliveryMinutes(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return int.tryParse(match?.group(0) ?? '') ?? 999;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', ' ')
        .replaceAll(',', ' ')
        .replaceAll('-', ' ')
        .replaceAll('burgers', 'burger')
        .replaceAll('pizzas', 'pizza')
        .replaceAll('tacos', 'taco')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _categoryKey(String value) => _normalize(value);

  List<_FoodCategoryOption> _buildFoodCategories(AppLocalizations l10n) {
    final counts = <String, int>{};
    for (final restaurant in _restaurants) {
      final label = restaurant.category.trim().isEmpty
          ? 'International & Other'
          : restaurant.category.trim();
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final entries = counts.entries.toList();
    if (entries.isEmpty) {
      return [
        _FoodCategoryOption(
          id: 'all',
          label: l10n.t('common.all'),
          icon: Icons.restaurant_rounded,
          color: AppColors.food,
        ),
      ];
    }

    final order = <String, int>{
      for (var i = 0; i < _preferredCategoryOrder.length; i += 1)
        _preferredCategoryOrder[i].toLowerCase(): i,
    };

    entries.sort((left, right) {
      final leftOrder = order[left.key.toLowerCase()] ?? 999;
      final rightOrder = order[right.key.toLowerCase()] ?? 999;
      if (leftOrder != rightOrder) return leftOrder.compareTo(rightOrder);
      return right.value.compareTo(left.value);
    });

    final dynamicOptions = entries
        .take(10)
        .map(
          (entry) => _FoodCategoryOption(
            id: _categoryKey(entry.key),
            label: entry.key,
            icon: _iconForCategory(entry.key),
            color: _colorForCategory(entry.key),
          ),
        )
        .toList();

    return [
      _FoodCategoryOption(
        id: 'all',
        label: l10n.t('common.all'),
        icon: Icons.restaurant_menu_rounded,
        color: AppColors.primary,
      ),
      ...dynamicOptions,
    ];
  }

  IconData _iconForCategory(String label) {
    final normalized = _normalize(label);
    if (normalized.contains('burger') || normalized.contains('fast food')) {
      return Icons.lunch_dining_rounded;
    }
    if (normalized.contains('pizza') || normalized.contains('italian')) {
      return Icons.local_pizza_rounded;
    }
    if (normalized.contains('taco') || normalized.contains('mexican')) {
      return Icons.local_fire_department_rounded;
    }
    if (normalized.contains('coffee') || normalized.contains('cafe')) {
      return Icons.coffee_rounded;
    }
    if (normalized.contains('bakery') || normalized.contains('dessert')) {
      return Icons.cake_rounded;
    }
    if (normalized.contains('sushi') || normalized.contains('asian')) {
      return Icons.set_meal_rounded;
    }
    if (normalized.contains('bbq') || normalized.contains('grill')) {
      return Icons.outdoor_grill_rounded;
    }
    if (normalized.contains('healthy') || normalized.contains('salad')) {
      return Icons.spa_rounded;
    }
    if (normalized.contains('ice cream') || normalized.contains('frozen')) {
      return Icons.icecream_rounded;
    }
    if (normalized.contains('indian')) {
      return Icons.dinner_dining_rounded;
    }
    return Icons.restaurant_rounded;
  }

  Color _colorForCategory(String label) {
    final normalized = _normalize(label);
    if (normalized.contains('burger') || normalized.contains('fast food')) {
      return AppColors.shopping;
    }
    if (normalized.contains('pizza') || normalized.contains('italian')) {
      return AppColors.food;
    }
    if (normalized.contains('taco') || normalized.contains('mexican')) {
      return AppColors.accent;
    }
    if (normalized.contains('coffee') || normalized.contains('cafe')) {
      return AppColors.secondary;
    }
    if (normalized.contains('bakery') || normalized.contains('dessert')) {
      return AppColors.warning;
    }
    if (normalized.contains('sushi') || normalized.contains('asian')) {
      return AppColors.primary;
    }
    if (normalized.contains('bbq') || normalized.contains('grill')) {
      return AppColors.error;
    }
    if (normalized.contains('healthy') || normalized.contains('salad')) {
      return AppColors.success;
    }
    if (normalized.contains('ice cream') || normalized.contains('frozen')) {
      return AppColors.pharmacy;
    }
    return AppColors.food;
  }
}

class _FoodCategoryOption {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const _FoodCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class _FoodCategory extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FoodCategory({
    required this.icon,
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.12),
                border: isSelected
                    ? Border.all(color: color.withValues(alpha: 0.55))
                    : null,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark),
            ),
          ],
        ),
      ),
    );
  }
}
