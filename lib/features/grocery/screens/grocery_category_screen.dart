import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class GroceryCategoryScreen extends StatelessWidget {
  final String categoryId;
  const GroceryCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Category'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<dynamic>(
        future: ApiClient.get(
          '/catalog/products?moduleType=grocery&categoryId=$categoryId',
        ),
        builder: (context, snapshot) {
          final items = snapshot.hasData
              ? ((snapshot.data as List)
                    .map(
                      (item) => GroceryModel.fromApi(
                        Map<String, dynamic>.from(item as Map),
                      ),
                    )
                    .toList())
              : GroceryModel.sampleItems
                    .where((item) => item.categoryId == categoryId)
                    .toList();

          final title = items.isNotEmpty
              ? (items.first.categoryName ?? items.first.categoryId)
              : GroceryModel.sampleCategories
                    .firstWhere(
                      (category) => category.id == categoryId,
                      orElse: () => GroceryModel.sampleCategories.first,
                    )
                    .name;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(child: ShimmerBlock(width: 140, height: 24)),
                  SizedBox(height: 20),
                  Expanded(
                    child: InlineSectionGridShimmer(
                      itemCount: 6,
                      childAspectRatio: 0.72,
                    ),
                  ),
                ],
              ),
            );
          }

          if (items.isEmpty) {
            return Center(
              child: Text(
                'No items in this category yet.',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(title, style: AppTextStyles.h3),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
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
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.eco_rounded,
                                  size: 36,
                                  color: AppColors.grocery.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: AppTextStyles.labelMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        '\$${item.price.toStringAsFixed(2)}',
                                        style: AppTextStyles.priceSmall
                                            .copyWith(
                                              color: AppColors.grocery,
                                              fontSize: 13,
                                            ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          context.read<CartProvider>().addItem(
                                            CartItem(
                                              id: item.id,
                                              name: item.name,
                                              price: item.price,
                                              moduleType: 'grocery',
                                              brand: item.unit,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${item.name} added!',
                                              ),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: AppColors.grocery,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: AppColors.white,
                                            size: 18,
                                          ),
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
              ),
            ],
          );
        },
      ),
    );
  }
}
