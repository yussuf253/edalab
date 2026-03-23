import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class GroceryScreen extends StatelessWidget {
  const GroceryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = GroceryModel.sampleCategories;
    final items = GroceryModel.sampleItems;
    final cartItemCount = context.watch<CartProvider>().getModuleItemCount('grocery');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Grocery'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.shopping_bag_outlined), onPressed: () => context.push('/grocery/cart')),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: const AppSearchBar(hint: 'Search groceries...'),
            ),
          ),
          // Promo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.grocery, Color(0xFF55EFC4)]),
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
                          Text('Fresh & Organic 🌿', style: AppTextStyles.h3.copyWith(color: AppColors.white)),
                          const SizedBox(height: 4),
                          Text('Get 40% off on fresh produce', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                      child: Text('Shop Now', style: AppTextStyles.labelMedium.copyWith(color: AppColors.grocery)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Categories', style: AppTextStyles.h4),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final c = categories[index];
                    return GestureDetector(
                      onTap: () => context.push('/grocery/category/${c.id}'),
                      child: Column(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.grocery.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Center(child: Icon(Icons.category_rounded, color: AppColors.grocery, size: 28)),
                          ),
                          const SizedBox(height: 6),
                          Text(c.name, style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Products
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text('Popular Items', style: AppTextStyles.h4),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final i = items[index];
                return Container(
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
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          ),
                          child: Center(child: Icon(Icons.eco_rounded, size: 36, color: AppColors.grocery.withValues(alpha: 0.4))),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name, style: AppTextStyles.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text(i.isOrganic ? 'Organic' : 'Standard', style: AppTextStyles.caption),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Text('\$${i.price.toStringAsFixed(2)}', style: AppTextStyles.priceSmall.copyWith(color: AppColors.grocery, fontSize: 13)),
                                        Text('/${i.unit}', style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      context.read<CartProvider>().addItem(CartItem(
                                        id: i.id,
                                        name: i.name,
                                        price: i.price,
                                        moduleType: 'grocery',
                                        brand: i.unit,
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${i.name} added!'), backgroundColor: AppColors.success),
                                      );
                                    },
                                    child: Container(
                                      width: 30, height: 30,
                                      decoration: BoxDecoration(color: AppColors.grocery, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.add, color: AppColors.white, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: items.length),
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
    );
  }
}
