import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';

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
    final restaurant = _restaurant;
    final menu = _resolvedMenu(restaurant);

    final cartProvider = context.watch<CartProvider>();
    final foodCartItems = cartProvider.getModuleItems('food');
    final moduleTotal = cartProvider.getModuleSubtotal('food');
    final cartItemCount = cartProvider.getModuleItemCount('food');

    final categories = ['All', ...menu.map((category) => category.name)];
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleCategories = menu
        .where((category) {
          final matchesCategory =
              _selectedCategory == 'All' || category.name == _selectedCategory;
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
                child: CircleAvatar(
                  backgroundColor: AppColors.white,
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border_rounded,
                      size: 20,
                      color: AppColors.dark,
                    ),
                    onPressed: () {},
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(restaurant.name, style: AppTextStyles.h2),
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
                          restaurant.isOpen ? 'Open' : 'Closed',
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
                                ? ['Popular']
                                : restaurant.tags)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.foodBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  tag,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.food,
                                  ),
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
                        '${restaurant.reviewCount}+ reviews',
                        AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        Icons.schedule_rounded,
                        restaurant.deliveryTime,
                        'min delivery',
                        AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        Icons.delivery_dining_rounded,
                        restaurant.deliveryFee == 'Free'
                            ? 'Free'
                            : restaurant.deliveryFee,
                        'delivery',
                        AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
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
                        hintText: 'Search dishes, drinks, sides...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Categories', style: AppTextStyles.h3),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = category),
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
                        'No dishes match your search',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try another keyword or switch categories to keep exploring the menu.',
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
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: [
                        Text(entry.key, style: AppTextStyles.h3),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.value.length} items',
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
                    Text('View Cart', style: AppTextStyles.button),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  List<MenuCategory> _resolvedMenu(RestaurantModel restaurant) {
    if (restaurant.menu.isNotEmpty) {
      return restaurant.menu;
    }

    final cuisine = restaurant.cuisine.toLowerCase();
    if (cuisine.contains('pizza') || cuisine.contains('italian')) {
      return [
        MenuCategory('Signature Pizzas', [
          MenuItem(
            id: '${restaurant.id}_p1',
            name: 'Margherita Special',
            description: 'Fresh mozzarella, basil, and rich tomato sauce',
            price: 13.99,
            isPopular: true,
          ),
          MenuItem(
            id: '${restaurant.id}_p2',
            name: 'Pepperoni Royale',
            description: 'Loaded pepperoni with extra cheese and herbs',
            price: 15.99,
          ),
        ]),
        MenuCategory('Sides', [
          MenuItem(
            id: '${restaurant.id}_p3',
            name: 'Garlic Bread',
            description: 'Toasted bread with garlic butter and parmesan',
            price: 5.49,
          ),
          MenuItem(
            id: '${restaurant.id}_p4',
            name: 'Caesar Salad',
            description: 'Crisp romaine with parmesan and Caesar dressing',
            price: 6.99,
          ),
        ]),
      ];
    }

    if (cuisine.contains('sushi') || cuisine.contains('japanese')) {
      return [
        MenuCategory('Rolls', [
          MenuItem(
            id: '${restaurant.id}_s1',
            name: 'Salmon Avocado Roll',
            description: 'Fresh salmon, avocado, and seasoned rice',
            price: 14.49,
            isPopular: true,
          ),
          MenuItem(
            id: '${restaurant.id}_s2',
            name: 'Crunchy Shrimp Roll',
            description: 'Crispy shrimp with spicy mayo and cucumber',
            price: 15.99,
          ),
        ]),
        MenuCategory('Bowls', [
          MenuItem(
            id: '${restaurant.id}_s3',
            name: 'Teriyaki Chicken Bowl',
            description: 'Grilled chicken, steamed rice, and teriyaki glaze',
            price: 12.99,
          ),
          MenuItem(
            id: '${restaurant.id}_s4',
            name: 'Miso Soup',
            description: 'Traditional broth with tofu and seaweed',
            price: 4.49,
          ),
        ]),
      ];
    }

    if (cuisine.contains('mexican') || cuisine.contains('taco')) {
      return [
        MenuCategory('Tacos', [
          MenuItem(
            id: '${restaurant.id}_m1',
            name: 'Beef Street Tacos',
            description: 'Three tacos with salsa fresca and lime',
            price: 11.99,
            isPopular: true,
          ),
          MenuItem(
            id: '${restaurant.id}_m2',
            name: 'Chicken Fajita Wrap',
            description: 'Grilled chicken, peppers, onions, and chipotle sauce',
            price: 10.99,
          ),
        ]),
        MenuCategory('Sides', [
          MenuItem(
            id: '${restaurant.id}_m3',
            name: 'Loaded Nachos',
            description: 'Crispy chips with cheese, beans, and jalapenos',
            price: 8.49,
          ),
          MenuItem(
            id: '${restaurant.id}_m4',
            name: 'Churros',
            description: 'Warm cinnamon churros with chocolate dip',
            price: 5.99,
          ),
        ]),
      ];
    }

    if (cuisine.contains('chinese') || cuisine.contains('asian')) {
      return [
        MenuCategory('Mains', [
          MenuItem(
            id: '${restaurant.id}_c1',
            name: 'Kung Pao Chicken',
            description: 'Spicy chicken stir fry with peanuts and peppers',
            price: 13.49,
            isPopular: true,
          ),
          MenuItem(
            id: '${restaurant.id}_c2',
            name: 'Beef Chow Mein',
            description: 'Wok-fried noodles with beef and vegetables',
            price: 12.99,
          ),
        ]),
        MenuCategory('Rice & Sides', [
          MenuItem(
            id: '${restaurant.id}_c3',
            name: 'Vegetable Fried Rice',
            description: 'Fragrant rice with vegetables and egg',
            price: 9.49,
          ),
          MenuItem(
            id: '${restaurant.id}_c4',
            name: 'Spring Rolls',
            description: 'Crispy rolls served with sweet chili sauce',
            price: 5.99,
          ),
        ]),
      ];
    }

    if (cuisine.contains('indian') || cuisine.contains('curry')) {
      return [
        MenuCategory('Curries', [
          MenuItem(
            id: '${restaurant.id}_i1',
            name: 'Butter Chicken',
            description: 'Creamy tomato curry with tender chicken pieces',
            price: 14.99,
            isPopular: true,
          ),
          MenuItem(
            id: '${restaurant.id}_i2',
            name: 'Paneer Tikka Masala',
            description: 'Paneer cubes in a rich spiced masala sauce',
            price: 13.49,
          ),
        ]),
        MenuCategory('Sides', [
          MenuItem(
            id: '${restaurant.id}_i3',
            name: 'Garlic Naan',
            description: 'Soft naan bread with garlic butter',
            price: 3.99,
          ),
          MenuItem(
            id: '${restaurant.id}_i4',
            name: 'Mango Lassi',
            description: 'Refreshing yogurt drink with mango puree',
            price: 4.99,
          ),
        ]),
      ];
    }

    return [
      MenuCategory('Featured', [
        MenuItem(
          id: '${restaurant.id}_f1',
          name: 'Chef Special',
          description: 'A signature dish prepared fresh for every order',
          price: 12.99,
          isPopular: true,
        ),
        MenuItem(
          id: '${restaurant.id}_f2',
          name: 'House Favorite',
          description: 'One of the most loved meals on the menu',
          price: 10.99,
        ),
      ]),
      MenuCategory('Drinks', [
        MenuItem(
          id: '${restaurant.id}_f3',
          name: 'Fresh Juice',
          description: 'Freshly prepared and served chilled',
          price: 3.99,
        ),
      ]),
    ];
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _MenuItemCard({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
