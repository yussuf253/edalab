import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _WishItem('MacBook Pro M3', 'Apple', '\$1,999', 4.9),
      _WishItem('Sony WH-1000XM5', 'Sony', '\$348', 4.8),
      _WishItem('iPad Mini', 'Apple', '\$499', 4.7),
      _WishItem('Adidas Ultraboost', 'Adidas', '\$180', 4.6),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wishlist'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppSpacing.shadowSm,
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.extraLightGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: AppColors.lightGrey,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTextStyles.labelLarge),
                      const SizedBox(height: 4),
                      Text(item.brand, style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(item.price, style: AppTextStyles.priceSmall),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Add to Cart',
                              style: AppTextStyles.badge.copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WishItem {
  final String name;
  final String brand;
  final String price;
  final double rating;

  _WishItem(this.name, this.brand, this.price, this.rating);
}
