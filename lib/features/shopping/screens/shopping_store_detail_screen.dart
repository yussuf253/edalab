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

class ShoppingStoreDetailScreen extends StatefulWidget {
  final String storeId;

  const ShoppingStoreDetailScreen({super.key, required this.storeId});

  @override
  State<ShoppingStoreDetailScreen> createState() =>
      _ShoppingStoreDetailScreenState();
}

class _ShoppingStoreDetailScreenState extends State<ShoppingStoreDetailScreen> {
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  ShoppingStoreModel _store = ShoppingStoreModel(
    id: '',
    name: '',
    tagline: '',
    imageUrl: '',
    rating: 0,
    reviewCount: 0,
    productCount: 0,
    minPrice: 0,
    maxPrice: 0,
  );
  List<ProductModel> _products = [];
  Timer? _searchDebounce;
  String _lastTrackedSearch = '';
  bool _hasTrackedStoreView = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    try {
      final response =
          await ApiClient.get('/catalog/shopping-stores/${widget.storeId}')
              as Map;
      final data = Map<String, dynamic>.from(response);
      final products = (data['products'] as List? ?? const [])
          .map(
            (entry) =>
                ProductModel.fromApi(Map<String, dynamic>.from(entry as Map)),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _store = ShoppingStoreModel.fromApi(data);
        _products = products.isEmpty ? ProductModel.sampleProducts : products;
        _isLoading = false;
      });
      _trackStoreViewed(source: 'remote');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _store = ShoppingStoreModel.sampleStores.first;
        _products = ProductModel.sampleProducts;
        _isLoading = false;
      });
      _trackStoreViewed(source: 'fallback_sample');
    }
  }

  void _trackStoreViewed({required String source}) {
    if (_hasTrackedStoreView) return;
    _hasTrackedStoreView = true;
    AnalyticsService.instance.track(
      AnalyticsEvents.entityOpened,
      properties: {
        'module': 'shopping',
        'entity_type': 'store',
        'entity_id': _store.id,
        'source': source,
        'category_count': _store.categories.length,
        'product_count': _products.length,
      },
    );
    AnalyticsService.instance.track(
      AnalyticsEvents.catalogResultsLoaded,
      properties: {
        'module': 'shopping',
        'entity_type': 'product',
        'parent_entity_type': 'store',
        'parent_entity_id': _store.id,
        'result_count': _products.length,
        'source': source,
      },
    );
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
          'entity_type': 'product',
          'context': 'store_detail',
          'parent_entity_id': _store.id,
          'query': normalizedQuery,
          'query_length': normalizedQuery.length,
          'selected_category': _selectedCategory,
          'result_count': _visibleProductCount(
            category: _selectedCategory,
            query: normalizedQuery,
          ),
        },
      );
    });
  }

  int _visibleProductCount({required String category, required String query}) {
    final allCategory = context.l10n.t('common.all');
    return _products.where((product) {
      final matchesCategory =
          category == 'All' ||
          category == allCategory ||
          product.category == category;
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).length;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final cartItemCount = cartProvider.getModuleItemCount('shopping');
    final moduleTotal = cartProvider.getModuleSubtotal('shopping');
    final allCategory = l10n.t('common.all');
    final categories = [allCategory, ..._store.categories];
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final products = _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'All' ||
          _selectedCategory == allCategory ||
          product.category == _selectedCategory;
      final matchesSearch =
          normalizedQuery.isEmpty ||
          product.name.toLowerCase().contains(normalizedQuery) ||
          product.brand.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: AppColors.white,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.dark,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.white,
                      child: IconButton(
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 20,
                          color: AppColors.dark,
                        ),
                        onPressed: () {
                          AnalyticsService.instance.track(
                            AnalyticsEvents.viewCartTapped,
                            properties: {
                              'module': 'shopping',
                              'source': 'store_detail',
                              'store_id': _store.id,
                              'cart_item_count': cartItemCount,
                            },
                          );
                          context.push('/shopping/cart');
                        },
                      ),
                    ),
                    if (cartItemCount > 0)
                      Positioned(
                        top: 8,
                        right: 0,
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
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.shopping.withValues(alpha: 0.45),
                      AppColors.primary.withValues(alpha: 0.16),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_store.imageUrl.trim().isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          _store.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    if (_store.imageUrl.trim().isNotEmpty)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (_store.imageUrl.trim().isEmpty) ...[
                      Positioned(
                        top: 44,
                        right: -10,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                    if (!_isLoading &&
                        _store.categories.isNotEmpty &&
                        _store.imageUrl.trim().isEmpty)
                      Center(
                        child: Icon(
                          _storeIcon(_store.categories),
                          size: 76,
                          color: AppColors.shopping.withValues(alpha: 0.35),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: _isLoading
                  ? const _ShoppingStoreDetailShimmer()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_store.name, style: AppTextStyles.h2),
                        const SizedBox(height: 6),
                        Text(
                          _store.tagline,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _store.highlights
                              .map(
                                (highlight) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    highlight,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _StoreDetailChip(
                              icon: Icons.star_rounded,
                              label: _store.rating.toStringAsFixed(1),
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            _StoreDetailChip(
                              icon: Icons.inventory_2_outlined,
                              label: l10n.t(
                                'store_detail.products',
                                params: {
                                  'count': _store.productCount.toString(),
                                },
                              ),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _StoreDetailChip(
                              icon: Icons.payments_outlined,
                              label:
                                  'DJF${_store.minPrice.toStringAsFixed(0)}-\$${_store.maxPrice.toStringAsFixed(0)}',
                              color: AppColors.shopping,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppSearchBar(
                          hint: l10n.t('store_detail.search_hint'),
                          onChanged: _onSearchChanged,
                        ),
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: _isLoading
                  ? const _ShoppingStoreCategoryShimmer()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                                'entity_type': 'product',
                                'context': 'store_detail',
                                'parent_entity_id': _store.id,
                                'filter_type': 'category',
                                'filter_value': category,
                                'query': normalizedQuery,
                                'result_count': _visibleProductCount(
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
                              category,
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
            const _StoreProductsGridShimmer()
          else if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l10n.t('store_detail.empty'),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  final isFavorite = wishlistProvider.isFavorite(product.id);
                  return GestureDetector(
                    onTap: () {
                      AnalyticsService.instance.track(
                        AnalyticsEvents.entityOpened,
                        properties: {
                          'module': 'shopping',
                          'entity_type': 'product',
                          'entity_id': product.id,
                          'source': 'store_detail_grid',
                          'parent_entity_id': _store.id,
                          'position': index + 1,
                          'result_count': products.length,
                        },
                      );
                      context.push('/shopping/product/${product.id}');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    color: AppColors.extraLightGrey,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _storeIcon([product.category]),
                                      size: 40,
                                      color: AppColors.shopping.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Material(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(999),
                                      onTap: () {
                                        wishlistProvider.toggleFavorite(
                                          product,
                                        );
                                        AnalyticsService.instance.track(
                                          AnalyticsEvents.wishlistToggled,
                                          properties: {
                                            'module': 'shopping',
                                            'entity_type': 'product',
                                            'entity_id': product.id,
                                            'is_favorite': !isFavorite,
                                            'source': 'store_detail_grid',
                                            'parent_entity_id': _store.id,
                                          },
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Icon(
                                          isFavorite
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          size: 18,
                                          color: isFavorite
                                              ? AppColors.accent
                                              : AppColors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 7, 10, 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: AppTextStyles.labelMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    product.brand,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'DJF${product.price.toStringAsFixed(2)}',
                                          style: AppTextStyles.priceSmall,
                                        ),
                                      ),
                                      _StoreProductActionButton(
                                        onPressed: () {
                                          cartProvider.addItem(
                                            CartItem(
                                              id: product.id,
                                              name: product.name,
                                              brand:
                                                  product.brand
                                                      .trim()
                                                      .isNotEmpty
                                                  ? product.brand
                                                  : _store.name,
                                              price: product.price,
                                              moduleType: 'shopping',
                                              imageUrl:
                                                  product.images.isNotEmpty
                                                  ? product.images.first
                                                  : null,
                                              description: product.description,
                                              shopId: product.shopId,
                                              shopName:
                                                  product.shopName ??
                                                  _store.name,
                                            ),
                                          );
                                          AnalyticsService.instance.track(
                                            AnalyticsEvents.checkoutEntryTapped,
                                            properties: {
                                              'module': 'shopping',
                                              'source': 'store_detail_grid',
                                              'entity_type': 'product',
                                              'entity_id': product.id,
                                              'quantity': 1,
                                              'unit_price': product.price,
                                              'line_total': product.price,
                                              'parent_entity_id': _store.id,
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: products.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.62,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: cartItemCount > 0
          ? SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: FloatingActionButton.extended(
                onPressed: () {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.viewCartTapped,
                    properties: {
                      'module': 'shopping',
                      'source': 'store_detail_fab',
                      'store_id': _store.id,
                      'cart_item_count': cartItemCount,
                      'cart_total': moduleTotal,
                    },
                  );
                  context.push('/shopping/cart');
                },
                backgroundColor: AppColors.shopping,
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
                      l10n.t('store_detail.view_cart'),
                      style: AppTextStyles.button,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'DJF${moduleTotal.toStringAsFixed(2)}',
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

class _ShoppingStoreDetailShimmer extends StatelessWidget {
  const _ShoppingStoreDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ShimmerBlock(width: 160, height: 28),
          SizedBox(height: 10),
          ShimmerBlock(width: 220, height: 14, radius: 10),
          SizedBox(height: 8),
          ShimmerBlock(width: 180, height: 14, radius: 10),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShimmerBlock(width: 88, height: 32, radius: 999),
              ShimmerBlock(width: 112, height: 32, radius: 999),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ShimmerBlock(
                  width: double.infinity,
                  height: 32,
                  radius: 999,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ShimmerBlock(
                  width: double.infinity,
                  height: 32,
                  radius: 999,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: ShimmerBlock(
                  width: double.infinity,
                  height: 32,
                  radius: 999,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ShimmerBlock(width: double.infinity, height: 56, radius: 16),
        ],
      ),
    );
  }
}

class _ShoppingStoreCategoryShimmer extends StatelessWidget {
  const _ShoppingStoreCategoryShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final widths = [72.0, 96.0, 86.0, 104.0];
          return ShimmerBlock(width: widths[index], height: 36, radius: 999);
        },
      ),
    );
  }
}

class _StoreProductsGridShimmer extends StatelessWidget {
  const _StoreProductsGridShimmer();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) =>
              const AppShimmer(child: _StoreProductCardShimmer()),
          childCount: 6,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.62,
        ),
      ),
    );
  }
}

class _StoreProductCardShimmer extends StatelessWidget {
  const _StoreProductCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.extraLightGrey,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: ShimmerBlock(width: 34, height: 34, radius: 999),
                ),
                Center(child: ShimmerBlock(width: 44, height: 44, radius: 14)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 7, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: double.infinity, height: 14, radius: 10),
                  SizedBox(height: 6),
                  ShimmerBlock(width: 72, height: 12, radius: 10),
                  Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ShimmerBlock(
                          width: double.infinity,
                          height: 16,
                          radius: 10,
                        ),
                      ),
                      SizedBox(width: 10),
                      ShimmerBlock(width: 34, height: 34, radius: 10),
                    ],
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

class _StoreDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StoreDetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _StoreProductActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StoreProductActionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.shopping,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.add_rounded, color: AppColors.white, size: 18),
          ),
        ),
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
