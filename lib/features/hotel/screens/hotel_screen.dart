import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/models/models.dart';

class HotelScreen extends StatelessWidget {
  const HotelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hotels = HotelModel.sampleHotels;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hotels'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: const AppSearchBar(hint: 'Search hotels, locations...'),
            ),
          ),
          // Check in/out
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-in', style: AppTextStyles.caption),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.hotel),
                              const SizedBox(width: 6),
                              Text('Mar 25', style: AppTextStyles.labelLarge),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-out', style: AppTextStyles.caption),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.hotel),
                              const SizedBox(width: 6),
                              Text('Mar 28', style: AppTextStyles.labelLarge),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        Text('Guests', style: AppTextStyles.caption),
                        const SizedBox(height: 4),
                        Text('2', style: AppTextStyles.labelLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Popular Destinations
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Popular Destinations 🌍', style: AppTextStyles.h4),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                children: const [
                  _DestChip('🏖️', 'Beach'),
                  _DestChip('🏔️', 'Mountain'),
                  _DestChip('🌆', 'City'),
                  _DestChip('🏝️', 'Island'),
                  _DestChip('🏜️', 'Desert'),
                ],
              ),
            ),
          ),
          // Hotels list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text('Recommended Hotels', style: AppTextStyles.h4),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final h = hotels[index];
              final type = h.amenities.isNotEmpty ? h.amenities.first : 'Hotel';
              return GestureDetector(
                onTap: () => context.push('/hotel/detail/${h.id}'),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.hotel.withValues(alpha: 0.3), AppColors.hotel.withValues(alpha: 0.1)],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Stack(
                          children: [
                            Center(child: Icon(Icons.hotel_rounded, size: 48, color: AppColors.hotel.withValues(alpha: 0.4))),
                            Positioned(
                              top: 12, left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: AppColors.hotel, borderRadius: BorderRadius.circular(8)),
                                child: Text(type, style: AppTextStyles.badge),
                              ),
                            ),
                            Positioned(
                              top: 12, right: 12,
                              child: Container(
                                width: 36, height: 36,
                                decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.favorite_border_rounded, size: 18, color: AppColors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.name, style: AppTextStyles.labelLarge),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppColors.grey),
                                const SizedBox(width: 4),
                                Text('${h.city} • ${h.address}', style: AppTextStyles.caption),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                                const SizedBox(width: 4),
                                Text('${h.rating}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark)),
                                const Spacer(),
                                Text('\$${h.pricePerNight.toInt()}', style: AppTextStyles.priceSmall.copyWith(color: AppColors.hotel)),
                                Text('/night', style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: hotels.length),
          ),
        ],
      ),
    );
  }
}

class _DestChip extends StatelessWidget {
  final String emoji, name;
  const _DestChip(this.emoji, this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.hotelBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(name, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
