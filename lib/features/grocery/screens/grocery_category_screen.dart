import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class GroceryCategoryScreen extends StatelessWidget {
  final String categoryId;
  const GroceryCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final cat = GroceryModel.sampleCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => GroceryModel.sampleCategories.first,
    );
    final items = GroceryModel.sampleItems.where((i) => i.categoryId == categoryId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(cat.name),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: items.isEmpty 
        ? Center(child: Text('No items in this category yet.', style: AppTextStyles.bodyMedium))
        : GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
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
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.name, style: AppTextStyles.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const Spacer(),
                            Row(
                              children: [
                                Text('\$${i.price.toStringAsFixed(2)}', style: AppTextStyles.priceSmall.copyWith(color: AppColors.grocery, fontSize: 13)),
                                const Spacer(),
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
            },
          ),
    );
  }
}
