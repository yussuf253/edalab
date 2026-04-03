import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/auth_gate.dart';

class HotelDetailScreen extends StatefulWidget {
  final String hotelId;
  const HotelDetailScreen({super.key, required this.hotelId});

  @override
  State<HotelDetailScreen> createState() => _HotelDetailScreenState();
}

class _HotelDetailScreenState extends State<HotelDetailScreen> {
  late HotelModel _hotel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _hotel = HotelModel(
      id: '',
      name: '',
      address: '',
      city: '',
      rating: 0,
      reviewsCount: 0,
      pricePerNight: 0,
      amenities: const [],
      description: '',
    );
    _loadHotel();
  }

  Future<void> _loadHotel() async {
    try {
      final response = await ApiClient.get('/catalog/hotels/${widget.hotelId}');
      if (!mounted) return;
      setState(() {
        _hotel = HotelModel.fromApi(Map<String, dynamic>.from(response as Map));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final h = _hotel;
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
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: AppColors.dark,
                  ),
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
              child: _isLoading
                  ? const _HotelDetailShimmer()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(h.name, style: AppTextStyles.h2),
                            ),
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
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoChip(
                              Icons.star_rounded,
                              '${h.rating}',
                              AppColors.warning,
                            ),
                            if (h.amenities.contains('Free WiFi'))
                              _InfoChip(
                                Icons.wifi_rounded,
                                'Free WiFi',
                                AppColors.primary,
                              ),
                            if (h.amenities.contains('Pool'))
                              _InfoChip(
                                Icons.pool_rounded,
                                'Pool',
                                AppColors.secondary,
                              ),
                            if (h.amenities.contains('Restaurant'))
                              _InfoChip(
                                Icons.restaurant_rounded,
                                'Restaurant',
                                AppColors.food,
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.t('hotel_detail.about'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          h.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.t('hotel_detail.amenities'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: h.amenities
                              .map(
                                (a) => _Amenity(
                                  Icons.check_circle_outline_rounded,
                                  a,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.t('hotel_detail.available_rooms'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 12),
                        ...h.roomOptions.map(
                          (room) => _RoomCard(
                            room.name,
                            room.description,
                            room.pricePerNight.toInt(),
                            room.available,
                            capacity: room.capacity,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.t('hotel_detail.reviews'),
                          style: AppTextStyles.h4,
                        ),
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
                                  Text(
                                    l10n.t('hotel_detail.reviewer_name'),
                                    style: AppTextStyles.labelMedium,
                                  ),
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
                                l10n.t('hotel_detail.review_text'),
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
      bottomSheet: _isLoading
          ? null
          : Container(
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
                        Text(
                          l10n.t('hotel_detail.starting_from'),
                          style: AppTextStyles.caption,
                        ),
                        Row(
                          children: [
                            Text(
                              '\$${h.pricePerNight.toInt()}',
                              style: AppTextStyles.price.copyWith(
                                color: AppColors.hotel,
                              ),
                            ),
                            Text(
                              l10n.t('hotel.per_night'),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: AppButton(
                        text: l10n.t('hotel_detail.book_now'),
                        color: AppColors.hotel,
                        onPressed: () async {
                          final allowed = await requireLoggedIn(
                            context,
                            message: l10n.t('hotel_detail.login_required'),
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

class _HotelDetailShimmer extends StatelessWidget {
  const _HotelDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Expanded(child: ShimmerBlock(width: double.infinity, height: 28)),
              SizedBox(width: 12),
              ShimmerBlock(width: 76, height: 30, radius: 8),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              ShimmerBlock(width: 16, height: 16, radius: 999),
              SizedBox(width: 6),
              Expanded(
                child: ShimmerBlock(
                  width: double.infinity,
                  height: 14,
                  radius: 10,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ShimmerBlock(width: 60, height: 32, radius: 8),
              ShimmerBlock(width: 88, height: 32, radius: 8),
              ShimmerBlock(width: 96, height: 32, radius: 8),
            ],
          ),
          SizedBox(height: 24),
          ShimmerBlock(width: 74, height: 20),
          SizedBox(height: 8),
          ShimmerBlock(width: double.infinity, height: 14, radius: 10),
          SizedBox(height: 8),
          ShimmerBlock(width: double.infinity, height: 14, radius: 10),
          SizedBox(height: 8),
          ShimmerBlock(width: 220, height: 14, radius: 10),
          SizedBox(height: 24),
          ShimmerBlock(width: 96, height: 20),
          SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ShimmerBlock(width: 118, height: 40, radius: 10),
              ShimmerBlock(width: 102, height: 40, radius: 10),
              ShimmerBlock(width: 126, height: 40, radius: 10),
            ],
          ),
          SizedBox(height: 24),
          ShimmerBlock(width: 124, height: 20),
          SizedBox(height: 12),
          _HotelRoomCardShimmer(),
          SizedBox(height: 12),
          _HotelRoomCardShimmer(),
          SizedBox(height: 12),
          _HotelRoomCardShimmer(),
          SizedBox(height: 24),
          ShimmerBlock(width: 70, height: 20),
          SizedBox(height: 12),
          ShimmerBlock(width: double.infinity, height: 116, radius: 14),
          SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _HotelRoomCardShimmer extends StatelessWidget {
  const _HotelRoomCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          ShimmerBlock(width: 70, height: 70, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: 150, height: 18),
                SizedBox(height: 8),
                ShimmerBlock(width: 120, height: 12, radius: 10),
                SizedBox(height: 10),
                ShimmerBlock(width: 84, height: 16, radius: 10),
              ],
            ),
          ),
          SizedBox(width: 12),
          ShimmerBlock(width: 70, height: 28, radius: 999),
        ],
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
  final int capacity;
  const _RoomCard(
    this.name,
    this.desc,
    this.price,
    this.available, {
    this.capacity = 2,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
                Text(
                  '$capacity guests',
                  style: AppTextStyles.caption.copyWith(color: AppColors.hotel),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '\$$price',
                      style: AppTextStyles.priceSmall.copyWith(
                        color: AppColors.hotel,
                      ),
                    ),
                    Text(
                      l10n.t('hotel.per_night'),
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    Text(
                      available
                          ? l10n.t('hotel_detail.available')
                          : l10n.t('hotel_detail.sold_out'),
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
