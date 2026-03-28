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

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<GroceryModel> _items = GroceryModel.sampleItems;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final response = await ApiClient.get(
        '/catalog/products?moduleType=grocery',
      );
      final items = (response as List)
          .map(
            (item) =>
                GroceryModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items.isEmpty ? GroceryModel.sampleItems : items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final cartItemCount = cartProvider.getModuleItemCount('grocery');
    final moduleTotal = cartProvider.getModuleSubtotal('grocery');
    final query = _searchQuery.trim().toLowerCase();
    final filteredItems = _items.where((item) {
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          (item.categoryName ?? '').toLowerCase().contains(query);
    }).toList();

    final categoryMap = <String, GroceryCategory>{};
    for (final item in _items) {
      categoryMap[item.categoryId] ??= GroceryCategory(
        id: item.categoryId,
        name: item.categoryName ?? item.categoryId,
      );
    }
    final categories = categoryMap.isEmpty
        ? GroceryModel.sampleCategories
        : categoryMap.values.toList();

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
        title: Text(l10n.t('grocery.title')),
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
                onPressed: () => context.push('/grocery/cart'),
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
                hint: l10n.t('grocery.search_hint'),
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.grocery, AppColors.secondaryLight],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.t('grocery.hero_title'),
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.t('grocery.hero_subtitle'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.t('grocery.shop_now'),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.grocery,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(l10n.t('grocery.categories'), style: AppTextStyles.h4),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: AppShimmer(
                  child: SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _GroceryCategoryShimmer(),
                          _GroceryCategoryShimmer(),
                          _GroceryCategoryShimmer(),
                          _GroceryCategoryShimmer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: categories
                        .map(
                          (category) => _GroceryCategoryCard(
                            symbol: _groceryCategorySymbol(category.name),
                            name: category.name,
                            color: _groceryCategoryColor(category.name),
                            onTap: () =>
                                context.push('/grocery/category/${category.id}'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(l10n.t('grocery.popular_items'), style: AppTextStyles.h4),
            ),
          ),
          if (_isLoading)
            const SliverSectionGridShimmer(itemCount: 6)
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = filteredItems[index];
                  final itemIcon = _groceryCategoryIcon(
                    item.categoryName ?? item.categoryId,
                  );
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/grocery/product/${item.id}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.groceryBg,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  itemIcon,
                                  size: 36,
                                  color: AppColors.grocery.withValues(alpha: 0.55),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTextStyles.labelMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.isOrganic
                                        ? l10n.t('grocery.organic_pick')
                                        : l10n.t('grocery.fresh_daily'),
                                    style: AppTextStyles.caption,
                                  ),
                                  const Spacer(),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '\$${item.price.toStringAsFixed(2)}',
                                              style: AppTextStyles.priceSmall.copyWith(
                                                color: AppColors.grocery,
                                                fontSize: 13,
                                              ),
                                            ),
                                          Text(
                                              l10n.t(
                                                'grocery.per_unit',
                                                params: {'unit': item.unit},
                                              ),
                                              style: AppTextStyles.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                      _GroceryAddButton(
                                        onPressed: () {
                                          context.read<CartProvider>().addItem(
                                            CartItem(
                                              id: item.id,
                                              name: item.name,
                                              price: item.price,
                                              moduleType: 'grocery',
                                              brand: item.unit,
                                              imageUrl: item.imageUrl,
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
                }, childCount: filteredItems.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
      floatingActionButton: cartItemCount > 0
          ? SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/grocery/cart'),
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
                    Text(l10n.t('grocery.view_cart'), style: AppTextStyles.button),
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
      ),
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

String _groceryCategorySymbol(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('fruit')) return '🍎';
  if (normalized.contains('veg') || normalized.contains('salad')) return '🥬';
  if (normalized.contains('dairy')) return '🥛';
  if (normalized.contains('egg')) return '🥚';
  if (normalized.contains('meat')) return '🥩';
  if (normalized.contains('seafood')) return '🐟';
  if (normalized.contains('bakery') || normalized.contains('bread')) return '🥖';
  if (normalized.contains('beverage') || normalized.contains('drink')) return '🥤';
  if (normalized.contains('snack')) return '🍪';
  return '🧺';
}

Color _groceryCategoryColor(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('fruit')) return const Color(0xFFFF6B6B);
  if (normalized.contains('veg') || normalized.contains('salad')) {
    return const Color(0xFF2ED573);
  }
  if (normalized.contains('dairy') || normalized.contains('egg')) {
    return const Color(0xFFFFBE21);
  }
  if (normalized.contains('meat') || normalized.contains('seafood')) {
    return const Color(0xFF3498DB);
  }
  if (normalized.contains('bakery') || normalized.contains('bread')) {
    return const Color(0xFFFF8C42);
  }
  if (normalized.contains('beverage') || normalized.contains('drink')) {
    return const Color(0xFF6C63FF);
  }
  if (normalized.contains('snack')) return const Color(0xFF9B59B6);
  return AppColors.grocery;
}

class _GroceryCategoryShimmer extends StatelessWidget {
  const _GroceryCategoryShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 14),
      child: Column(
        children: [
          ShimmerBlock(width: 60, height: 60, radius: 18),
          SizedBox(height: 6),
          ShimmerBlock(width: 52, height: 12, radius: 10),
        ],
      ),
    );
  }
}

class _GroceryAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GroceryAddButton({required this.onPressed});

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
            color: AppColors.grocery,
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

class _GroceryCategoryCard extends StatelessWidget {
  final String symbol;
  final String name;
  final Color color;
  final VoidCallback onTap;

  const _GroceryCategoryCard({
    required this.symbol,
    required this.name,
    required this.color,
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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 68,
              child: Text(
                name,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
