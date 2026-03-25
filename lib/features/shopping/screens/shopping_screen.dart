import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
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
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  List<ShoppingStoreModel> _stores = ShoppingStoreModel.sampleStores;

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
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stores = ShoppingStoreModel.sampleStores;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().getModuleItemCount(
      'shopping',
    );
    final categories = [
      'All',
      ...{
        for (final store in _stores) ...store.categories,
      },
    ];
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final stores = _stores.where((store) {
      final matchesCategory = _selectedCategory == 'All' ||
          store.categories.contains(_selectedCategory);
      final matchesSearch = normalizedQuery.isEmpty ||
          store.name.toLowerCase().contains(normalizedQuery) ||
          store.tagline.toLowerCase().contains(normalizedQuery) ||
          store.categories.any(
            (category) => category.toLowerCase().contains(normalizedQuery),
          );
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shopping'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => context.push('/shopping/wishlist'),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => context.push('/shopping/cart'),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: AppSearchBar(
              hint: 'Search stores, brands, categories...',
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SizedBox(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.shopping, Color(0xFFFFA6A6)],
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
                          'Explore shops first',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          'Open a store to browse all of its products',
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
          Expanded(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: InlineSectionListShimmer(itemCount: 4),
                  )
                : stores.isEmpty
                ? Center(
                    child: Text(
                      'No shops found.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: stores.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final store = stores[index];
                      return _ShoppingStoreCard(store: store);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShoppingStoreCard extends StatelessWidget {
  final ShoppingStoreModel store;

  const _ShoppingStoreCard({required this.store});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shopping/store/${store.id}'),
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
                        Text(store.name, style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text(
                          store.tagline,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey,
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
                        '\$${store.minPrice.toStringAsFixed(0)} - \$${store.maxPrice.toStringAsFixed(0)}',
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

IconData _storeIcon(List<String> categories) {
  final joined = categories.join(' ').toLowerCase();
  if (joined.contains('shoe')) return Icons.shopping_bag_rounded;
  if (joined.contains('electronic')) return Icons.headphones_rounded;
  if (joined.contains('clothing')) return Icons.checkroom_rounded;
  if (joined.contains('home')) return Icons.chair_rounded;
  if (joined.contains('accessor')) return Icons.watch_rounded;
  return Icons.storefront_rounded;
}
