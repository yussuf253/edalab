import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _recentSearches = ['Burger', 'Dr. Sarah', 'Nike Shoes', 'Hotel Downtown', 'Paracetamol'];
  final _trending = ['Pizza', 'Eye Doctor', 'Beach Resort', 'Vitamins', 'Fresh Fruits', 'Laundry Service'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search anything...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGrey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.mic_rounded, color: AppColors.primary), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Searches', style: AppTextStyles.h4),
                Text('Clear', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            ..._recentSearches.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 20, color: AppColors.mediumGrey),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s, style: AppTextStyles.bodyMedium)),
                  const Icon(Icons.north_west_rounded, size: 16, color: AppColors.mediumGrey),
                ],
              ),
            )),
            const SizedBox(height: 24),
            // Trending
            Text('Trending Now 🔥', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _trending.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: Text(t, style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark)),
              )).toList(),
            ),
            const SizedBox(height: 24),
            // Quick services
            Text('Quick Access', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...[
              ('Order Food', Icons.restaurant_rounded, AppColors.food, '/food'),
              ('Book a Ride', Icons.directions_car_rounded, AppColors.ride, '/ride'),
              ('Find a Doctor', Icons.medical_services_rounded, AppColors.doctor, '/doctor'),
              ('Shop Online', Icons.shopping_bag_rounded, AppColors.shopping, '/shopping'),
            ].map((s) => GestureDetector(
              onTap: () => context.push(s.$4),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppSpacing.shadowSm),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(color: s.$3.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(s.$2, color: s.$3, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(s.$1, style: AppTextStyles.labelMedium)),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mediumGrey),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
