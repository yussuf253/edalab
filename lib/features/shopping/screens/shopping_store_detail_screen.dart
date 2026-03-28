import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  ShoppingStoreModel _store = ShoppingStoreModel.sampleStores.first;
  List<ProductModel> _products = ProductModel.sampleProducts;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    try {
      final response = await ApiClient.get('/catalog/shopping-stores/${widget.storeId}')
          as Map;
      final data = Map<String, dynamic>.from(response);
      final products = (data['products'] as List? ?? const [])
          .map(
            (entry) => ProductModel.fromApi(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _store = ShoppingStoreModel.fromApi(data);
        _products = products.isEmpty ? ProductModel.sampleProducts : products;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _products = ProductModel.sampleProducts;
        _isLoading = false;
      });
    }
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
      final matchesCategory = _selectedCategory == 'All' ||
          _selectedCategory == allCategory ||
          product.category == _selectedCategory;
      final matchesSearch = normalizedQuery.isEmpty ||
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
                        onPressed: () => context.push('/shopping/cart'),
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
                  ? const DetailContentShimmer(
                      accentColor: AppColors.shopping,
                      showHero: false,
                    )
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
                                params: {'count': _store.productCount.toString()},
                              ),
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _StoreDetailChip(
                              icon: Icons.payments_outlined,
                              label:
                                  '\$${_store.minPrice.toStringAsFixed(0)}-\$${_store.maxPrice.toStringAsFixed(0)}',
                              color: AppColors.shopping,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AppSearchBar(
                          hint: l10n.t('store_detail.search_hint'),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                        ),
                      ],
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isSelected ? AppColors.white : AppColors.dark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverToBoxAdapter(
                child: InlineSectionGridShimmer(
                  itemCount: 6,
                  childAspectRatio: 0.62,
                ),
              ),
            )
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
                    onTap: () => context.push('/shopping/product/${product.id}'),
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
                                        wishlistProvider.toggleFavorite(product);
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
                                          '\$${product.price.toStringAsFixed(2)}',
                                          style: AppTextStyles.priceSmall,
                                        ),
                                      ),
                                      _StoreProductActionButton(
                                        onPressed: () {
                                          cartProvider.addItem(
                                            CartItem(
                                              id: product.id,
                                              name: product.name,
                                              brand: product.brand,
                                              price: product.price,
                                              moduleType: 'shopping',
                                              imageUrl: product.images.isNotEmpty
                                                  ? product.images.first
                                                  : null,
                                            ),
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
                onPressed: () => context.push('/shopping/cart'),
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
            child: Icon(
              Icons.add_rounded,
              color: AppColors.white,
              size: 18,
            ),
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
