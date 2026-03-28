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

class GroceryCategoryScreen extends StatelessWidget {
  final String categoryId;
  const GroceryCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final cartItemCount = cartProvider.getModuleItemCount('grocery');
    final moduleTotal = cartProvider.getModuleSubtotal('grocery');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('grocery_category.title')),
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
                l10n.t('grocery_category.empty'),
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
                                    color: AppColors.grocery.withValues(
                                      alpha: 0.55,
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '\$${item.price.toStringAsFixed(2)}',
                                                style: AppTextStyles.priceSmall
                                                    .copyWith(
                                                      color: AppColors.grocery,
                                                      fontSize: 13,
                                                    ),
                                              ),
                                              Text(
                                                l10n.t(
                                                  'grocery_category.per_unit',
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
                  },
                ),
              ),
            ],
          );
        },
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
                    Text(
                      l10n.t('grocery_category.view_cart'),
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
