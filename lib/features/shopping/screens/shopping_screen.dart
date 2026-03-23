import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  int _selectedCategory = 0;

  final _categories = [
    'All', 'Shoes', 'Electronics', 'Clothing', 'Home', 'Accessories',
  ];

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().getModuleItemCount('shopping');
    
    // Filter products by category
    final categoryFilter = _selectedCategory == 0 ? null : _categories[_selectedCategory];
    final products = ProductModel.sampleProducts.where((p) {
      if (categoryFilter == null) return true;
      return p.category == categoryFilter;
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
                      child: Text('$cartItemCount', style: AppTextStyles.badge.copyWith(fontSize: 10)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: AppSearchBar(
              hint: 'Search products, brands...',
            ),
          ),
          // Categories
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedCategory == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: AppColors.lightGrey),
                    ),
                    child: Text(
                      _categories[index],
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected ? AppColors.white : AppColors.dark,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Flash Sale Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.shopping, Color(0xFFFF9E9E)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.flash_on_rounded, color: AppColors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Flash Sale!',
                          style: AppTextStyles.h4.copyWith(color: AppColors.white),
                        ),
                        Text(
                          'Up to 70% off • Ends in 02:45:30',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Shop',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.shopping),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Products Grid
          Expanded(
            child: products.isEmpty 
              ? Center(child: Text("No products found.", style: AppTextStyles.bodyMedium))
              : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                final isFavorite = context.watch<WishlistProvider>().isFavorite(p.id);

                return GestureDetector(
                  onTap: () => context.push('/shopping/product/${p.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Expanded(
                          flex: 3,
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: AppColors.extraLightGrey,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.shopping_bag_rounded,
                                    size: 40,
                                    color: AppColors.shopping.withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                              if (p.badge != null)
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(p.badge!, style: AppTextStyles.badge),
                                  ),
                                ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<WishlistProvider>().toggleFavorite(p);
                                  },
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: AppSpacing.shadowSm,
                                    ),
                                    child: Icon(
                                      isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                      size: 16,
                                      color: isFavorite ? AppColors.accent : AppColors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Details
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: AppTextStyles.labelMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(p.brand, style: AppTextStyles.caption),
                                const Spacer(),
                                Row(
                                  children: [
                                    Text('\$${p.price}', style: AppTextStyles.priceSmall),
                                    const SizedBox(width: 4),
                                    if (p.originalPrice != null)
                                      Text('\$${p.originalPrice}', style: AppTextStyles.priceOld.copyWith(fontSize: 10)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                                    const SizedBox(width: 3),
                                    Text('${p.rating}', style: AppTextStyles.caption.copyWith(color: AppColors.dark)),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
