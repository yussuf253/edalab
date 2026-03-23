import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/providers.dart';

class PharmacyScreen extends StatelessWidget {
  const PharmacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<CartProvider>().getModuleItemCount('pharmacy');
    final medicines = PharmacyModel.sampleItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pharmacy'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.shopping_bag_outlined), onPressed: () => context.push('/pharmacy/cart')),
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
              child: const AppSearchBar(hint: 'Search medicines, health products...'),
            ),
          ),
          // Upload prescription
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.pharmacy, Color(0xFF55EFC4)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Upload Prescription 📋', style: AppTextStyles.h4.copyWith(color: AppColors.white)),
                          const SizedBox(height: 4),
                          Text('Upload and get medicines delivered', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                            child: Text('Upload Now', style: AppTextStyles.labelMedium.copyWith(color: AppColors.pharmacy)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.camera_alt_rounded, color: AppColors.white, size: 36),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: const [
                  _CatIcon(Icons.medication_rounded, 'Medicines', AppColors.pharmacy),
                  _CatIcon(Icons.sanitizer_rounded, 'Wellness', AppColors.secondary),
                  _CatIcon(Icons.healing_rounded, 'First Aid', AppColors.accent),
                  _CatIcon(Icons.baby_changing_station_rounded, 'Baby Care', AppColors.food),
                  _CatIcon(Icons.face_retouching_natural_rounded, 'Skin Care', AppColors.laundry),
                  _CatIcon(Icons.fitness_center_rounded, 'Fitness', AppColors.primary),
                ],
              ),
            ),
          ),
          // Popular medicines
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text('Popular Medicines', style: AppTextStyles.h4),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final m = medicines[index];
              return GestureDetector(
                onTap: () => context.push('/pharmacy/medicine/${m.id}'),
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
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: AppColors.pharmacyBg, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.medication_rounded, color: AppColors.pharmacy, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(m.size, style: AppTextStyles.caption),
                            const SizedBox(height: 4),
                            Text(m.category, style: AppTextStyles.labelSmall.copyWith(color: AppColors.pharmacy)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('\$${m.price.toStringAsFixed(2)}', style: AppTextStyles.priceSmall.copyWith(color: AppColors.pharmacy)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              context.read<CartProvider>().addItem(CartItem(
                                id: m.id,
                                name: m.name,
                                price: m.price,
                                moduleType: 'pharmacy',
                                brand: m.category,
                              ));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${m.name} added to cart!'), backgroundColor: AppColors.success),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.pharmacy, borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Add', style: AppTextStyles.badge.copyWith(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: medicines.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _CatIcon extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;
  const _CatIcon(this.icon, this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(name, style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark)),
        ],
      ),
    );
  }
}
