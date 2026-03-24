import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_shimmer.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  List<_PromoDeal> _specialOffers = const [];
  List<_PromoDeal> _flashSales = const [];
  List<_PromoDeal> _coupons = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.get('/promotions') as Map,
      );
      if (!mounted) return;
      setState(() {
        _specialOffers = _readDeals(response['specialOffers']);
        _flashSales = _readDeals(response['flashSales']);
        _coupons = _readDeals(response['coupons']);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _specialOffers = _fallbackSpecialOffers;
        _flashSales = _fallbackFlashSales;
        _coupons = _fallbackCoupons;
        _isLoading = false;
      });
    }
  }

  List<_PromoDeal> _readDeals(dynamic value) {
    if (value is! List) return const [];
    return value
        .map(
          (item) => _PromoDeal.fromApi(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $code'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specialOffers = _specialOffers.isEmpty
        ? _fallbackSpecialOffers
        : _specialOffers;
    final flashSales = _flashSales.isEmpty ? _fallbackFlashSales : _flashSales;
    final coupons = _coupons.isEmpty ? _fallbackCoupons : _coupons;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Promotions'), centerTitle: false),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sell_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Live offers, flash sales, and coupon codes are synced from the backend.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _SectionHeaderSliver(title: 'Special Offers'),
          if (_isLoading)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 136,
                child: AppShimmer(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 3,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => const ShimmerBlock(
                      width: 280,
                      height: 132,
                      radius: 20,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: specialOffers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _SpecialOfferCard(deal: specialOffers[index]),
                ),
              ),
            ),
          _SectionHeaderSliver(title: 'Flash Sales'),
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: AppShimmer(
                    child: ShimmerBlock(
                      width: double.infinity,
                      height: 82,
                      radius: 16,
                    ),
                  ),
                ),
                childCount: 3,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _DealCard(deal: flashSales[index]),
                ),
                childCount: flashSales.length,
              ),
            ),
          _SectionHeaderSliver(title: 'Coupon Codes'),
          if (_isLoading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: AppShimmer(
                    child: ShimmerBlock(
                      width: double.infinity,
                      height: 108,
                      radius: 16,
                    ),
                  ),
                ),
                childCount: 2,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: _CouponCard(
                    deal: coupons[index],
                    onCopy: coupons[index].code == null
                        ? null
                        : () => _copyCode(coupons[index].code!),
                  ),
                ),
                childCount: coupons.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SectionHeaderSliver extends StatelessWidget {
  final String title;
  const _SectionHeaderSliver({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
        child: Text(title, style: AppTextStyles.h4),
      ),
    );
  }
}

class _SpecialOfferCard extends StatelessWidget {
  final _PromoDeal deal;
  const _SpecialOfferCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: deal.color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(deal.discountLabel, style: AppTextStyles.badge),
          ),
          const Spacer(),
          Text(
            deal.title,
            style: AppTextStyles.h4.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 4),
          Text(
            deal.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final _PromoDeal deal;
  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: deal.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(deal.icon, color: deal.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal.title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(
                  deal.reason ?? deal.description,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            deal.discountLabel,
            style: AppTextStyles.labelSmall.copyWith(color: deal.color),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final _PromoDeal deal;
  final VoidCallback? onCopy;
  const _CouponCard({required this.deal, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: deal.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(deal.icon, color: deal.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deal.title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(
                  deal.code ?? deal.discountLabel,
                  style: AppTextStyles.h4.copyWith(color: deal.color),
                ),
                const SizedBox(height: 4),
                Text(
                  deal.reason ?? deal.description,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (onCopy != null)
            TextButton(onPressed: onCopy, child: const Text('Copy')),
        ],
      ),
    );
  }
}

class _PromoDeal {
  final String title;
  final String description;
  final String? code;
  final String? reason;
  final String discountLabel;
  final Color color;
  final IconData icon;

  const _PromoDeal({
    required this.title,
    required this.description,
    required this.code,
    required this.reason,
    required this.discountLabel,
    required this.color,
    required this.icon,
  });

  factory _PromoDeal.fromApi(Map<String, dynamic> json) {
    final moduleType = json['moduleType']?.toString().toUpperCase();
    final discountType = json['discountType']?.toString() ?? '';
    final discountValue = (json['discountValue'] as num?)?.toDouble();
    final metadata = Map<String, dynamic>.from(
      (json['metadata'] as Map?) ?? const {},
    );
    return _PromoDeal(
      title: json['title']?.toString() ?? 'Offer',
      description: json['description']?.toString() ?? '',
      code: json['code']?.toString(),
      reason: metadata['reason']?.toString(),
      discountLabel: _discountLabel(
        discountType,
        discountValue,
        json['code']?.toString(),
      ),
      color: _colorForModule(moduleType),
      icon: _iconForModule(moduleType),
    );
  }

  static String _discountLabel(String type, double? value, String? code) {
    if (code != null && code.isNotEmpty) return code;
    if (type == 'FREE_RIDES') return 'Free Ride';
    if (type == 'PERCENTAGE' && value != null) return '${value.toInt()}% Off';
    if (value != null) return value.toStringAsFixed(0);
    return 'Offer';
  }

  static Color _colorForModule(String? moduleType) {
    switch (moduleType) {
      case 'FOOD':
        return AppColors.food;
      case 'GROCERY':
        return AppColors.grocery;
      case 'PHARMACY':
        return AppColors.pharmacy;
      case 'DOCTOR':
        return AppColors.doctor;
      case 'HOTEL':
        return AppColors.hotel;
      case 'RIDE':
        return AppColors.ride;
      case 'LAUNDRY':
        return AppColors.laundry;
      default:
        return AppColors.primary;
    }
  }

  static IconData _iconForModule(String? moduleType) {
    switch (moduleType) {
      case 'FOOD':
        return Icons.restaurant_rounded;
      case 'GROCERY':
        return Icons.local_grocery_store_rounded;
      case 'PHARMACY':
        return Icons.medication_rounded;
      case 'DOCTOR':
        return Icons.medical_services_rounded;
      case 'HOTEL':
        return Icons.hotel_rounded;
      case 'RIDE':
        return Icons.directions_car_rounded;
      case 'LAUNDRY':
        return Icons.local_laundry_service_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }
}

const _fallbackSpecialOffers = [
  _PromoDeal(
    title: 'First 3 Rides Free',
    description: 'New user exclusive offer',
    code: null,
    reason: null,
    discountLabel: 'Free Ride',
    color: AppColors.ride,
    icon: Icons.directions_car_rounded,
  ),
  _PromoDeal(
    title: 'Laundry Weekend',
    description: '50% off on wash and fold orders',
    code: null,
    reason: null,
    discountLabel: '50% Off',
    color: AppColors.laundry,
    icon: Icons.local_laundry_service_rounded,
  ),
];

const _fallbackFlashSales = [
  _PromoDeal(
    title: 'Dinner Rush Flash Sale',
    description: 'Late-night meals and free delivery boosts after 7 PM.',
    code: null,
    reason: 'High evening demand',
    discountLabel: '20% Off',
    color: AppColors.food,
    icon: Icons.restaurant_rounded,
  ),
  _PromoDeal(
    title: 'Fresh Basket Countdown',
    description: 'Produce and pantry staples are discounted before noon.',
    code: null,
    reason: 'Morning produce push',
    discountLabel: '15% Off',
    color: AppColors.grocery,
    icon: Icons.local_grocery_store_rounded,
  ),
];

const _fallbackCoupons = [
  _PromoDeal(
    title: 'Weekend Escape Package',
    description: 'Use this when you are ready to confirm a stay booking.',
    code: 'STAY25',
    reason: 'City-stay promotion',
    discountLabel: 'STAY25',
    color: AppColors.hotel,
    icon: Icons.hotel_rounded,
  ),
  _PromoDeal(
    title: 'First Visit Consultation',
    description: 'Reduced fee for your first online consultation booking.',
    code: 'HEALTH10',
    reason: 'New patient offer',
    discountLabel: 'HEALTH10',
    color: AppColors.doctor,
    icon: Icons.medical_services_rounded,
  ),
];
