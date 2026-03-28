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
import '../../../core/widgets/app_shimmer.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  late RestaurantModel _restaurant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _restaurant = RestaurantModel.sampleRestaurants.firstWhere(
      (r) => r.id == widget.restaurantId,
      orElse: () => RestaurantModel.sampleRestaurants.first,
    );
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    try {
      final response = await ApiClient.get(
        '/catalog/restaurants/${widget.restaurantId}',
      );
      if (!mounted) return;
      setState(() {
        _restaurant = RestaurantModel.fromApi(
          Map<String, dynamic>.from(response as Map),
        );
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
    final restaurant = _restaurant;
    final menu = _resolvedMenu(restaurant);

    final cartProvider = context.watch<CartProvider>();
    final foodCartItems = cartProvider.getModuleItems('food');
    final moduleTotal = cartProvider.getModuleSubtotal('food');
    final cartItemCount = cartProvider.getModuleItemCount('food');
    final allCategory = l10n.t('common.all');

    final categories = [allCategory, ...menu.map((category) => category.name)];
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleCategories = menu
        .where((category) {
          final matchesCategory =
              _selectedCategory == 'All' ||
              _selectedCategory == allCategory ||
              category.name == _selectedCategory;
          final matchesSearch =
              normalizedQuery.isEmpty ||
              category.items.any(
                (item) =>
                    item.name.toLowerCase().contains(normalizedQuery) ||
                    item.description.toLowerCase().contains(normalizedQuery),
              );
          return matchesCategory && matchesSearch;
        })
        .map((category) {
          final items = category.items.where((item) {
            if (normalizedQuery.isEmpty) {
              return true;
            }
            return item.name.toLowerCase().contains(normalizedQuery) ||
                item.description.toLowerCase().contains(normalizedQuery);
          }).toList();
          return MapEntry(category.name, items);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList();

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
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 22,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  backgroundColor: AppColors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 20,
                      color: AppColors.dark,
                    ),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.food.withValues(alpha: 0.45),
                      AppColors.food.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: 45,
                      right: -20,
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
                        Icons.restaurant_rounded,
                        size: 72,
                        color: AppColors.food.withValues(alpha: 0.35),
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
                      accentColor: AppColors.food,
                      showHero: false,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                style: AppTextStyles.h2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: restaurant.isOpen
                                    ? AppColors.successLight
                                    : AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                restaurant.isOpen
                                    ? l10n.t('restaurant_detail.open')
                                    : l10n.t('restaurant_detail.closed'),
                                style: AppTextStyles.labelSmall.copyWith(
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
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              (restaurant.tags.isEmpty
                                      ? [l10n.t('restaurant_detail.popular')]
                                      : restaurant.tags)
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
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
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatChip(
                              Icons.star_rounded,
                              '${restaurant.rating}',
                              l10n.t(
                                'restaurant_detail.reviews',
                                params: {
                                  'count': restaurant.reviewCount.toString(),
                                },
                              ),
                              AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            _StatChip(
                              Icons.schedule_rounded,
                              restaurant.deliveryTime,
                              l10n.t('restaurant_detail.min_delivery'),
                              AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _StatChip(
                              Icons.delivery_dining_rounded,
                              restaurant.deliveryFee == 'Free'
                                  ? 'Free'
                                  : restaurant.deliveryFee,
                              l10n.t('restaurant_detail.delivery'),
                              AppColors.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              icon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.grey,
                              ),
                              hintText: l10n.t('restaurant_detail.search_hint'),
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.t('restaurant_detail.categories'), style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = _selectedCategory == category;
                              return GestureDetector(
                                onTap: () => setState(
                                  () => _selectedCategory = category,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.food
                                        : AppColors.background,
                                    borderRadius: BorderRadius.circular(999),
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
                        if (menu.isNotEmpty) const SizedBox(height: 10),
                      ],
                    ),
            ),
          ),
          if (visibleCategories.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 44,
                        color: AppColors.mediumGrey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        menu.isEmpty
                            ? l10n.t('restaurant_detail.menu_coming_soon')
                            : l10n.t('restaurant_detail.no_match'),
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        menu.isEmpty
                            ? l10n.t(
                                'restaurant_detail.menu_coming_soon_subtitle',
                              )
                            : l10n.t('restaurant_detail.no_match_subtitle'),
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
            ...visibleCategories.expand(
              (entry) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      entry.key == visibleCategories.first.key ? 28 : 22,
                      20,
                      12,
                    ),
                    child: Row(
                      children: [
                        Text(entry.key, style: AppTextStyles.h3),
                        const SizedBox(width: 8),
                        Text(
                          l10n.t(
                            'restaurant_detail.items_count',
                            params: {'count': entry.value.length.toString()},
                          ),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = entry.value[index];
                    final itemQuantity = _getItemQuantity(
                      foodCartItems,
                      item.id,
                    );
                    return _MenuItemCard(
                      item: item,
                      quantity: itemQuantity,
                      onTap: () => context.push(
                        '/food/dish/${item.id}',
                        extra: {
                          'restaurantName': restaurant.name,
                          'categoryName': entry.key,
                          'item': item,
                        },
                      ),
                      onAdd: () => _addItem(context, item, restaurant.name),
                      onIncrement: () => context
                          .read<CartProvider>()
                          .updateQuantity(item.id, itemQuantity + 1),
                      onDecrement: () => context
                          .read<CartProvider>()
                          .updateQuantity(item.id, itemQuantity - 1),
                    );
                  }, childCount: entry.value.length),
                ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: cartItemCount > 0
          ? SizedBox(
              width: MediaQuery.of(context).size.width - 40,
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/food/cart'),
                backgroundColor: AppColors.food,
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
                      l10n.t('restaurant_detail.view_cart'),
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

  int _getItemQuantity(List<CartItem> cartItems, String itemId) {
    final match = cartItems.cast<CartItem?>().firstWhere(
      (item) => item?.id == itemId,
      orElse: () => null,
    );
    return match?.quantity ?? 0;
  }

  void _addItem(BuildContext context, MenuItem item, String restaurantName) {
    final cartItem = CartItem(
      id: item.id,
      name: item.name,
      price: item.price,
      quantity: 1,
      moduleType: 'food',
      brand: restaurantName,
    );
    context.read<CartProvider>().addItem(cartItem);
  }

  List<MenuCategory> _resolvedMenu(RestaurantModel restaurant) {
    return restaurant.menu;
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MenuItemCard({
    required this.item,
    required this.quantity,
    required this.onTap,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.food.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Popular',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.food,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: AppTextStyles.priceSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.extraLightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fastfood_rounded,
                    color: AppColors.food.withValues(alpha: 0.3),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: quantity == 0
                        ? GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.food),
                                boxShadow: AppSpacing.shadowSm,
                              ),
                              child: Text(
                                'ADD',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.food,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.food),
                              boxShadow: AppSpacing.shadowSm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: onDecrement,
                                  child: const Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: AppColors.food,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '$quantity',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.food,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: onIncrement,
                                  child: const Icon(
                                    Icons.add,
                                    size: 16,
                                    color: AppColors.food,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: AppTextStyles.labelLarge.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
