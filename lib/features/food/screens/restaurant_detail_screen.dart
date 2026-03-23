import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final String restaurantId;
  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final restaurant = RestaurantModel.sampleRestaurants.firstWhere(
      (r) => r.id == restaurantId,
      orElse: () => RestaurantModel.sampleRestaurants.first,
    );

    // Flatten all menu items
    final allItems = restaurant.menu.expand((c) => c.items).toList();
    
    final cartProvider = context.watch<CartProvider>();
    final moduleTotal = cartProvider.getModuleSubtotal('food');
    final cartItemCount = cartProvider.getModuleItemCount('food');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Restaurant Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: AppColors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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
                    icon: const Icon(Icons.favorite_border_rounded, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  backgroundColor: AppColors.white,
                  child: IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.food.withValues(alpha: 0.4), AppColors.food.withValues(alpha: 0.15)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.restaurant_rounded, size: 64, color: AppColors.food.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),

          // Restaurant Info
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
                      Expanded(child: Text(restaurant.name, style: AppTextStyles.h2)),
                      if (restaurant.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Open', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Closed', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(restaurant.cuisine, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
                  const SizedBox(height: 16),
                  // Stats row
                  Row(
                    children: [
                      _StatChip(Icons.star_rounded, '${restaurant.rating}', '${restaurant.reviewCount}+ reviews', AppColors.warning),
                      const SizedBox(width: 10),
                      _StatChip(Icons.schedule_rounded, '${restaurant.deliveryTime}', 'min delivery', AppColors.primary),
                      const SizedBox(width: 10),
                      _StatChip(
                        Icons.delivery_dining_rounded, 
                        restaurant.deliveryFee == 'Free' ? 'Free' : restaurant.deliveryFee, 
                        'delivery', 
                        AppColors.success
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Info row
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text('123 Delivery St, City', style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Menu Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text('Menu', style: AppTextStyles.h3),
            ),
          ),

          // Menu Items
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = allItems[index];
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
                                Expanded(child: Text(item.name, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                if (item.isPopular) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.food.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('Popular', style: AppTextStyles.labelSmall.copyWith(color: AppColors.food, fontSize: 9)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(item.description, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Text('\$${item.price.toStringAsFixed(2)}', style: AppTextStyles.priceSmall),
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
                            child: Icon(Icons.fastfood_rounded, color: AppColors.food.withValues(alpha: 0.3)),
                          ),
                          Positioned(
                            bottom: -8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  // Add to food cart
                                  final cartItem = CartItem(
                                    id: item.id,
                                    name: item.name,
                                    price: item.price,
                                    quantity: 1,
                                    moduleType: 'food',
                                    brand: restaurant.name,
                                  );
                                  context.read<CartProvider>().addItem(cartItem);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item.name} added to cart!'), backgroundColor: AppColors.success),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.food),
                                    boxShadow: AppSpacing.shadowSm,
                                  ),
                                  child: Text('ADD', style: AppTextStyles.labelSmall.copyWith(color: AppColors.food)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: allItems.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      // Floating cart button
      floatingActionButton: cartItemCount > 0 
        ? Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: FloatingActionButton.extended(
              onPressed: () => context.push('/food/cart'),
              backgroundColor: AppColors.food,
              label: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$cartItemCount', style: AppTextStyles.badge),
                  ),
                  const SizedBox(width: 12),
                  Text('View Cart', style: AppTextStyles.button),
                  const SizedBox(width: 12),
                  Text('\$${moduleTotal.toStringAsFixed(2)}', style: AppTextStyles.button),
                ],
              ),
            ),
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                Text(value, style: AppTextStyles.labelLarge.copyWith(color: color)),
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
