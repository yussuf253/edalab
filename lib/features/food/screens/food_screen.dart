import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/utils/money_format.dart';
import '../../../core/config/zone_scope.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/notification_bell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  List<RestaurantModel> _restaurants = const [];
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
      final response = await ApiClient.get(
        ZoneScope.appendZone('/catalog/restaurants'),
      );
      final items = (response as List)
          .map(
            (item) =>
                RestaurantModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _restaurants = items;
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
        _restaurants = const [];
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'food',
          'entity_type': 'restaurant',
          'result_count': 0,
          'source': 'error',
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
    final locationProvider = context.watch<UserLocationProvider>();
    final locationLabel =
        locationProvider.location?.subtitle ??
        locationProvider.location?.title ??
        l10n.t('ride.current_location');

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // Header: back · deliver-to · bell, then the search pill.
            SliverToBoxAdapter(
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.dark,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 2, 10, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  LucideIcons.arrowLeft,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.tile,
                                  foregroundColor: AppColors.dark,
                                  shape: const CircleBorder(),
                                ),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/');
                                  }
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.t('food.title'),
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.tile,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            LucideIcons.mapPin,
                                            size: 12,
                                            color: AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              locationLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.labelMedium
                                                  .copyWith(
                                                    fontSize: 11.5,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: AppColors.grey,
                                                  ),
                                            ),
                                          ),
                                          const Icon(
                                            LucideIcons.chevronDown,
                                            color: AppColors.mediumGrey,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    color: AppColors.dark,
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.tile,
                                      foregroundColor: AppColors.dark,
                                      shape: const CircleBorder(),
                                    ),
                                    icon: const Icon(
                                      LucideIcons.shoppingBag,
                                      size: 20,
                                    ),
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
                                            style: AppTextStyles.badge.copyWith(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const NotificationBell(
                                size: 38,
                                backgroundColor: AppColors.tile,
                                iconColor: AppColors.dark,
                                compact: true,
                                showBorder: false,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                          child: AppSearchBar(
                            hint: l10n.t('food.search_hint'),
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            suffix: _searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      LucideIcons.x,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  children: quickCategories
                      .map(
                        (category) => _FoodCategory(
                          icon: category.icon,
                          imagePath: category.imagePath,
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
                          borderRadius: BorderRadius.circular(999),
                          border: isSelected
                              ? null
                              : Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              sort == 'fastest'
                                  ? LucideIcons.bolt
                                  : sort == 'free_delivery'
                                  ? LucideIcons.scooter
                                  : CupertinoIcons.star_fill,
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
                padding: const EdgeInsets.only(top: 24, bottom: 4),
                child: SectionHeader(title: l10n.t('food.popular_nearby')),
              ),
            ),
            if (_isLoading) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverRestaurantListShimmer(itemCount: 4),
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
                          LucideIcons.searchX,
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final restaurant = restaurants[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RestaurantCard(
                        restaurant: restaurant,
                        l10n: l10n,
                        accentColor: _colorForCategory(restaurant.category),
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
                      ),
                    );
                  }, childCount: restaurants.length),
                ),
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
          icon: LucideIcons.utensilsCrossed,
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
            imagePath: _imageForCategory(entry.key),
            color: _colorForCategory(entry.key),
          ),
        )
        .toList();

    return [
      _FoodCategoryOption(
        id: 'all',
        label: l10n.t('common.all'),
        icon: LucideIcons.utensilsCrossed,
        color: AppColors.primary,
      ),
      ...dynamicOptions,
    ];
  }

  String? _imageForCategory(String label) {
    final normalized = _normalize(label);
    if (normalized.contains('pizza') || normalized.contains('italian')) {
      return 'assets/images/food/foodcategory_pizza.png';
    }
    if (normalized.contains('burger') || normalized.contains('fast food')) {
      return 'assets/images/food/foodcategory_fastfood.png';
    }
    if (normalized.contains('sandwich')) {
      return 'assets/images/food/foodcategory_sandwich.png';
    }
    if (normalized.contains('taco') || normalized.contains('mexican')) {
      return 'assets/images/food/foodcategory_tacos.png';
    }
    if (normalized.contains('hotdog') || normalized.contains('hot dog')) {
      return 'assets/images/food/foodcategory_hotdog.png';
    }
    if (normalized.contains('coffee') ||
        normalized.contains('cafe') ||
        normalized.contains('beverage') ||
        normalized.contains('drink')) {
      return 'assets/images/food/foodcategory_beverages.png';
    }
    if (normalized.contains('bakery') ||
        normalized.contains('dessert') ||
        normalized.contains('sweet')) {
      return 'assets/images/food/foodcategory_dessert.png';
    }
    if (normalized.contains('sushi') ||
        normalized.contains('asian') ||
        normalized.contains('chinese')) {
      return 'assets/images/food/foodcategory_chinese.png';
    }
    if (normalized.contains('seafood') || normalized.contains('fish')) {
      return 'assets/images/food/foodcategory_seafood.png';
    }
    return null;
  }

  IconData _iconForCategory(String label) {
    final normalized = _normalize(label);
    if (normalized.contains('burger') || normalized.contains('fast food')) {
      return LucideIcons.utensils;
    }
    if (normalized.contains('pizza') || normalized.contains('italian')) {
      return LucideIcons.pizza;
    }
    if (normalized.contains('taco') || normalized.contains('mexican')) {
      return LucideIcons.flame;
    }
    if (normalized.contains('coffee') || normalized.contains('cafe')) {
      return LucideIcons.coffee;
    }
    if (normalized.contains('bakery') || normalized.contains('dessert')) {
      return LucideIcons.cake;
    }
    if (normalized.contains('sushi') || normalized.contains('asian')) {
      return LucideIcons.utensils;
    }
    if (normalized.contains('bbq') || normalized.contains('grill')) {
      return LucideIcons.flame;
    }
    if (normalized.contains('healthy') || normalized.contains('salad')) {
      return LucideIcons.flower2;
    }
    if (normalized.contains('ice cream') || normalized.contains('frozen')) {
      return LucideIcons.iceCreamCone;
    }
    if (normalized.contains('indian')) {
      return LucideIcons.utensils;
    }
    return LucideIcons.utensilsCrossed;
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

class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard({
    required this.restaurant,
    required this.l10n,
    required this.accentColor,
    required this.onTap,
  });

  final RestaurantModel restaurant;
  final AppLocalizations l10n;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = restaurant.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final feeLabel = restaurant.deliveryFee == 'Free'
        ? l10n.t('food.free_delivery')
        : restaurant.deliveryFee;
    final highlights = <MenuItem>[
      for (final category in restaurant.menu) ...category.items,
    ].take(4).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // White surface; the category accent only shows as a hairline border
          // and in the copy, so cards differ without shouting.
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor.withValues(alpha: 0.14)),
          boxShadow: AppSpacing.shadowSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // One horizontal line: image, name, speciality, delivery time,
            // location and delivery price.
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 62,
                    height: 62,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: AppColors.tile),
                          if (hasImage)
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _imageFallback(),
                            )
                          else
                            _imageFallback(),
                          if (!restaurant.isOpen)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  l10n.t('food.closed'),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 9,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.star_fill,
                                    size: 10,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    restaurant.rating.toStringAsFixed(1),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          restaurant.cuisine,
                          style: AppTextStyles.caption.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Wraps instead of truncating so the delivery time is
                        // never cut off on narrow screens.
                        Wrap(
                          spacing: 10,
                          runSpacing: 3,
                          children: [
                            _RestaurantMetaLine(
                              icon: LucideIcons.clock,
                              label: restaurant.deliveryTime,
                            ),
                            _RestaurantMetaLine(
                              icon: LucideIcons.navigation,
                              label:
                                  '${restaurant.distance.toStringAsFixed(1)} km',
                              iconColor: AppColors.primary,
                            ),
                            _RestaurantMetaLine(
                              icon: LucideIcons.scooter,
                              label: feeLabel,
                              iconColor: AppColors.primary,
                              textColor: AppColors.primary,
                              bold: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (highlights.isNotEmpty) ...[
              Divider(height: 1, thickness: 1, color: AppColors.border),
              // Sizes to its content (rather than a fixed height) so large
              // text scales cannot overflow the card.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 10, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < highlights.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      _RestaurantItemTile(
                        item: highlights[i],
                        accentColor: accentColor,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Center(
      child: Icon(
        LucideIcons.utensilsCrossed,
        size: 22,
        color: accentColor.withValues(alpha: 0.55),
      ),
    );
  }
}

/// One small dish preview under a restaurant: image, name and price.
class _RestaurantItemTile extends StatelessWidget {
  const _RestaurantItemTile({required this.item, required this.accentColor});

  final MenuItem item;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 96,
              height: 58,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: AppColors.tile),
                  if (hasImage)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback(),
                    )
                  else
                    _fallback(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'DJF${money(item.price)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        LucideIcons.sandwich,
        size: 20,
        color: accentColor.withValues(alpha: 0.55),
      ),
    );
  }
}

class _RestaurantMetaLine extends StatelessWidget {
  const _RestaurantMetaLine({
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: iconColor ?? AppColors.mediumGrey),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: textColor,
              fontWeight: bold ? FontWeight.w700 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _FoodCategoryOption {
  final String id;
  final String label;
  final IconData icon;
  final String? imagePath;
  final Color color;

  const _FoodCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
    this.imagePath,
    required this.color,
  });
}

class _FoodCategory extends StatelessWidget {
  final IconData icon;
  final String? imagePath;
  final String name;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FoodCategory({
    required this.icon,
    this.imagePath,
    required this.name,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                // Only icon tiles get a filled plate. A picture must sit edge to
                // edge: a Container insets its child by the border width, so any
                // plate/border colour would show as a ring around the photo.
                color: hasImage
                    ? AppColors.white
                    : (isSelected ? AppColors.primary : AppColors.tile),
                borderRadius: BorderRadius.circular(18),
                border: hasImage
                    ? null
                    : Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
              ),
              child: hasImage
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(icon, color: color, size: 26),
                    )
                  : Icon(
                      icon,
                      color: isSelected ? AppColors.white : color,
                      size: 26,
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primaryDark : AppColors.dark,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
