import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/auth_gate.dart';

class HotelDetailScreen extends StatelessWidget {
  final String hotelId;
  const HotelDetailScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    final h = HotelModel.sampleHotels.firstWhere(
      (h) => h.id == hotelId,
      orElse: () => HotelModel.sampleHotels.first,
    );
    final type = h.amenities.isNotEmpty ? h.amenities.first : 'Hotel';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.hotel.withValues(alpha: 0.4),
                      AppColors.hotel.withValues(alpha: 0.15),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.hotel_rounded,
                    size: 64,
                    color: AppColors.hotel.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(h.name, style: AppTextStyles.h2)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.hotel,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(type, style: AppTextStyles.badge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppColors.hotel,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${h.city} • ${h.address}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip(
                        Icons.star_rounded,
                        '${h.rating}',
                        AppColors.warning,
                      ),
                      const SizedBox(width: 10),
                      if (h.amenities.contains('Free WiFi'))
                        _InfoChip(
                          Icons.wifi_rounded,
                          'Free WiFi',
                          AppColors.primary,
                        ),
                      if (h.amenities.contains('Pool')) ...[
                        const SizedBox(width: 10),
                        _InfoChip(
                          Icons.pool_rounded,
                          'Pool',
                          AppColors.secondary,
                        ),
                      ],
                      if (h.amenities.contains('Restaurant')) ...[
                        const SizedBox(width: 10),
                        _InfoChip(
                          Icons.restaurant_rounded,
                          'Restaurant',
                          AppColors.food,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('About', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    h.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Amenities', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: h.amenities
                        .map(
                          (a) =>
                              _Amenity(Icons.check_circle_outline_rounded, a),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text('Available Rooms', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _RoomCard(
                    'Standard Room',
                    '1 Bed • City View',
                    h.pricePerNight.toInt(),
                    true,
                  ),
                  _RoomCard(
                    'Premium Suite',
                    '1 King Bed • Balcony',
                    (h.pricePerNight * 1.5).toInt(),
                    true,
                  ),
                  _RoomCard(
                    'Royal Suite',
                    '2 Beds • Living Room',
                    (h.pricePerNight * 2.2).toInt(),
                    false,
                  ),
                  const SizedBox(height: 24),
                  Text('Reviews', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.hotelBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: AppColors.hotel,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('John D.', style: AppTextStyles.labelMedium),
                            const Spacer(),
                            ...List.generate(
                              5,
                              (_) => const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Amazing hotel with incredible views. The staff was exceptionally friendly and helpful. Will definitely come again!',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.dark,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Starting from', style: AppTextStyles.caption),
                  Row(
                    children: [
                      Text(
                        '\$${h.pricePerNight.toInt()}',
                        style: AppTextStyles.price.copyWith(
                          color: AppColors.hotel,
                        ),
                      ),
                      Text('/night', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: AppButton(
                  text: 'Book Now',
                  color: AppColors.hotel,
                  onPressed: () async {
                    final allowed = await requireLoggedIn(
                      context,
                      message: 'Please log in to book this hotel.',
                    );
                    if (!context.mounted || !allowed) return;
                    context.push('/hotel/book/${h.id}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Amenity extends StatelessWidget {
  final IconData icon;
  final String name;
  const _Amenity(this.icon, this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.extraLightGrey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.hotel),
          const SizedBox(width: 6),
          Text(
            name,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String name, desc;
  final int price;
  final bool available;
  const _RoomCard(this.name, this.desc, this.price, this.available);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.hotelBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bed_rounded,
              color: AppColors.hotel,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(desc, style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '\$$price',
                      style: AppTextStyles.priceSmall.copyWith(
                        color: AppColors.hotel,
                      ),
                    ),
                    Text('/night', style: AppTextStyles.caption),
                    const Spacer(),
                    Text(
                      available ? 'Available' : 'Sold Out',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: available ? AppColors.success : AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
