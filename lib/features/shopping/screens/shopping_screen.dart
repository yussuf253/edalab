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

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  List<ShoppingStoreModel> _stores = [];
  Timer? _searchDebounce;
  String _lastTrackedSearch = '';

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final response = await ApiClient.get('/catalog/shopping-stores');
      final stores = (response as List)
          .map(
            (entry) => ShoppingStoreModel.fromApi(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _stores = stores.isEmpty ? ShoppingStoreModel.sampleStores : stores;
        if (_selectedCategory != 'all' &&
            !_stores.any(
              (store) => store.categories.contains(_selectedCategory),
            )) {
          _selectedCategory = 'all';
        }
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'shopping',
          'entity_type': 'store',
          'result_count': _stores.length,
          'source': 'remote',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stores = ShoppingStoreModel.sampleStores;
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'shopping',
          'entity_type': 'store',
          'result_count': _stores.length,
          'source': 'fallback_sample',
        },
      );
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final normalizedQuery = value.trim().toLowerCase();
      if (normalizedQuery == _lastTrackedSearch) return;
      _lastTrackedSearch = normalizedQuery;
      if (normalizedQuery.isNotEmpty && normalizedQuery.length < 2) return;

      AnalyticsService.instance.track(
        AnalyticsEvents.searchPerformed,
        properties: {
          'module': 'shopping',
          'query': normalizedQuery,
          'query_length': normalizedQuery.length,
          'selected_category': _selectedCategory,
          'result_count': _visibleStoreCount(
            category: _selectedCategory,
            query: normalizedQuery,
          ),
        },
      );
    });
  }

  int _visibleStoreCount({required String category, required String query}) {
    return _stores.where((store) {
      final matchesCategory =
          category == 'all' || store.categories.contains(category);
      final matchesSearch =
          query.isEmpty ||
          store.name.toLowerCase().contains(query) ||
          store.tagline.toLowerCase().contains(query) ||
          store.categories.any((entry) => entry.toLowerCase().contains(query));
      return matchesCategory && matchesSearch;
    }).length;
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
      'shopping',
    );
    final categories = [
      'all',
      ...{for (final store in _stores) ...store.categories},
    ];
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final stores = _stores.where((store) {
      final matchesCategory =
          _selectedCategory == 'all' ||
          store.categories.contains(_selectedCategory);
      final matchesSearch =
          normalizedQuery.isEmpty ||
          store.name.toLowerCase().contains(normalizedQuery) ||
          store.tagline.toLowerCase().contains(normalizedQuery) ||
          store.categories.any(
            (category) => category.toLowerCase().contains(normalizedQuery),
          );
      return matchesCategory && matchesSearch;
    }).toList();

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
          title: Text(l10n.t('shopping.title')),
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
            IconButton(
              icon: const Icon(Icons.favorite_border_rounded),
              onPressed: () {
                AnalyticsService.instance.track(
                  AnalyticsEvents.entityOpened,
                  properties: {
                    'module': 'shopping',
                    'entity_type': 'wishlist',
                    'entity_id': 'shopping_wishlist',
                    'source': 'shopping_screen',
                  },
                );
                context.push('/shopping/wishlist');
              },
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined),
                  onPressed: () {
                    AnalyticsService.instance.track(
                      AnalyticsEvents.viewCartTapped,
                      properties: {
                        'module': 'shopping',
                        'source': 'shopping_screen',
                        'cart_item_count': cartItemCount,
                      },
                    );
                    context.push('/shopping/cart');
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
                  hint: l10n.t('shopping.search_hint'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.shopping, AppColors.secondaryLight],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.white,
                        size: 34,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('shopping.hero_title'),
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                            Text(
                              l10n.t('shopping.hero_subtitle'),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white70,
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
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: _isLoading
                    ? const _ShoppingFiltersShimmer()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = _selectedCategory == category;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedCategory = category);
                              AnalyticsService.instance.track(
                                AnalyticsEvents.filterApplied,
                                properties: {
                                  'module': 'shopping',
                                  'filter_type': 'category',
                                  'filter_value': category,
                                  'query': normalizedQuery,
                                  'result_count': _visibleStoreCount(
                                    category: category,
                                    query: normalizedQuery,
                                  ),
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
                              child: Text(
                                category == 'all'
                                    ? l10n.t('shopping.all')
                                    : category,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.dark,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: _ShoppingStoreListShimmer(itemCount: 4),
                ),
              )
            else if (stores.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    l10n.t('shopping.no_shops'),
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                sliver: SliverList.builder(
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    final store = stores[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == stores.length - 1 ? 0 : 14,
                      ),
                      child: _ShoppingStoreCard(
                        store: store,
                        onTap: () {
                          AnalyticsService.instance.track(
                            AnalyticsEvents.entityOpened,
                            properties: {
                              'module': 'shopping',
                              'entity_type': 'store',
                              'entity_id': store.id,
                              'position': index + 1,
                              'result_count': stores.length,
                              'selected_category': _selectedCategory,
                              'query': normalizedQuery,
                            },
                          );
                          context.push('/shopping/store/${store.id}');
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShoppingStoreCard extends StatelessWidget {
  final ShoppingStoreModel store;
  final VoidCallback onTap;

  const _ShoppingStoreCard({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = store.imageUrl.trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.shopping.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  if (hasImage)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          store.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  if (hasImage)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.08),
                              Colors.black.withValues(alpha: 0.28),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 18,
                    right: 18,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        _storeIcon(store.categories),
                        color: AppColors.shopping,
                        size: 38,
                      ),
                    ),
                  ),
                  if (store.badge != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(store.badge!, style: AppTextStyles.badge),
                      ),
                    ),
                  Positioned(
                    left: 18,
                    bottom: 18,
                    right: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: AppTextStyles.h3.copyWith(
                            color: hasImage ? AppColors.white : AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.tagline,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: hasImage
                                ? Colors.white.withValues(alpha: 0.86)
                                : AppColors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: store.categories
                        .take(3)
                        .map(
                          (category) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              category,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StoreStat(
                        icon: Icons.star_rounded,
                        value: store.rating.toStringAsFixed(1),
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      _StoreStat(
                        icon: Icons.inventory_2_outlined,
                        value: '${store.productCount} items',
                        color: AppColors.primary,
                      ),
                      const Spacer(),
                      Text(
                        'DJF${store.minPrice.toStringAsFixed(0)} - DJF${store.maxPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.shopping,
                        ),
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
  }
}

class _StoreStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StoreStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(value, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _ShoppingFiltersShimmer extends StatelessWidget {
  const _ShoppingFiltersShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final widths = [68.0, 94.0, 106.0, 88.0];
          return ShimmerBlock(width: widths[index], height: 36, radius: 999);
        },
      ),
    );
  }
}

class _ShoppingStoreListShimmer extends StatelessWidget {
  final int itemCount;

  const _ShoppingStoreListShimmer({this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(itemCount, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : 14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 150,
                    child: Stack(
                      children: const [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F4FA),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          child: ShimmerBlock(
                            width: 64,
                            height: 26,
                            radius: 999,
                          ),
                        ),
                        Positioned(
                          top: 18,
                          right: 18,
                          child: ShimmerBlock(
                            width: 72,
                            height: 72,
                            radius: 22,
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 110,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBlock(width: 140, height: 24),
                              SizedBox(height: 8),
                              ShimmerBlock(
                                width: double.infinity,
                                height: 12,
                                radius: 10,
                              ),
                              SizedBox(height: 6),
                              ShimmerBlock(width: 150, height: 12, radius: 10),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ShimmerBlock(width: 72, height: 28, radius: 999),
                            ShimmerBlock(width: 84, height: 28, radius: 999),
                            ShimmerBlock(width: 96, height: 28, radius: 999),
                          ],
                        ),
                        SizedBox(height: 14),
                        Row(
                          children: [
                            ShimmerBlock(width: 56, height: 14, radius: 10),
                            SizedBox(width: 12),
                            ShimmerBlock(width: 82, height: 14, radius: 10),
                            Spacer(),
                            ShimmerBlock(width: 86, height: 16, radius: 10),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

IconData _storeIcon(List<String> categories) {
  final joined = categories.join(' ').toLowerCase();
  if (joined.contains('shoe')) return Icons.shopping_bag_rounded;
  if (joined.contains('electronic')) return Icons.headphones_rounded;
  if (joined.contains('clothing')) return Icons.checkroom_rounded;
  if (joined.contains('home')) return Icons.chair_rounded;
  if (joined.contains('accessor')) return Icons.watch_rounded;
  return Icons.storefront_rounded;
}
