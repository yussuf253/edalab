import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});
  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  int _selectedFilter = 0;
  final _filters = ['All', 'Pizza', 'Burger', 'Sushi', 'Chinese', 'Indian', 'Mexican'];

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().getModuleItemCount('food');
    final restaurants = RestaurantModel.sampleRestaurants;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Food Delivery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () => context.push('/food/cart'),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    child: Center(child: Text('$cartItemCount', style: AppTextStyles.badge.copyWith(fontSize: 10))),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search + Location
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 6),
                      Text('123 Main Street, NY', style: AppTextStyles.labelMedium),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AppSearchBar(hint: 'Search restaurants, dishes...'),
                ],
              ),
            ),
          ),

          // Food Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  _FoodCategory(icon: Icons.local_pizza_rounded, name: 'Pizza', color: AppColors.food),
                  _FoodCategory(icon: Icons.lunch_dining_rounded, name: 'Burger', color: AppColors.shopping),
                  _FoodCategory(icon: Icons.ramen_dining_rounded, name: 'Noodles', color: AppColors.primary),
                  _FoodCategory(icon: Icons.set_meal_rounded, name: 'Sushi', color: AppColors.secondary),
                  _FoodCategory(icon: Icons.cake_rounded, name: 'Dessert', color: AppColors.laundry),
                  _FoodCategory(icon: Icons.local_cafe_rounded, name: 'Coffee', color: AppColors.pharmacy),
                ],
              ),
            ),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilter == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.food : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: AppColors.lightGrey),
                      ),
                      child: Text(
                        _filters[index],
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

          // Promo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.food, Color(0xFFFFB347)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Free Delivery 🎉', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
                          const SizedBox(height: 4),
                          Text('On your first 3 orders', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Order Now', style: AppTextStyles.labelMedium.copyWith(color: AppColors.food)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Popular nearby
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Popular Nearby 🔥', style: AppTextStyles.h3),
            ),
          ),

          // Restaurant list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final r = restaurants[index];
                return GestureDetector(
                  onTap: () => context.push('/food/restaurant/${r.id}'),
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
                        // Image
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.food.withValues(alpha: 0.3), AppColors.food.withValues(alpha: 0.1)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.restaurant_rounded, color: AppColors.food.withValues(alpha: 0.5), size: 36),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: AppTextStyles.labelLarge),
                              const SizedBox(height: 4),
                              Text(r.cuisine, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                                  const SizedBox(width: 4),
                                  Text('${r.rating}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark)),
                                  Text(' (${r.reviewCount}+)', style: AppTextStyles.caption),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.schedule_rounded, size: 14, color: AppColors.mediumGrey),
                                  const SizedBox(width: 4),
                                  Text('${r.deliveryTime} min', style: AppTextStyles.caption),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.delivery_dining_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    r.deliveryFee == 'Free' ? 'Free delivery' : 'Delivery ${r.deliveryFee}',
                                    style: AppTextStyles.caption.copyWith(
                                      color: r.deliveryFee == 'Free' ? AppColors.success : AppColors.grey,
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
              },
              childCount: restaurants.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _FoodCategory extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;

  const _FoodCategory({required this.icon, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(name, style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark)),
        ],
      ),
    );
  }
}
