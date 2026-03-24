import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  List<Map<String, dynamic>> _coupons = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiClient.get('/users/$userId/coupons');
      if (!mounted) return;
      setState(() {
        _coupons = (response as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Coupons & Rewards'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Rewards',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user != null && user.points >= 3000
                                ? 'Platinum'
                                : 'Gold Member',
                            style: AppTextStyles.badge.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${user?.points ?? 0}',
                          style: AppTextStyles.h1.copyWith(
                            color: AppColors.white,
                            fontSize: 40,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'points',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ((user?.points ?? 0) / 3000)
                            .clamp(0, 1)
                            .toDouble(),
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.white,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Available Coupons', style: AppTextStyles.h4),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: AppShimmer(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ShimmerBlock(
                        width: double.infinity,
                        height: 104,
                        radius: 18,
                      ),
                      SizedBox(height: 12),
                      ShimmerBlock(
                        width: double.infinity,
                        height: 104,
                        radius: 18,
                      ),
                      SizedBox(height: 12),
                      ShimmerBlock(
                        width: double.infinity,
                        height: 104,
                        radius: 18,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_coupons.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'No assigned coupons yet.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final coupon = _coupons[index];
                final promotion = Map<String, dynamic>.from(
                  coupon['promotion'] as Map,
                );
                final color = _colorForModule(
                  promotion['moduleType']?.toString(),
                );
                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 86,
                        height: 104,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            promotion['code']?.toString() ??
                                _discountLabel(
                                  promotion['discountType']?.toString(),
                                  promotion['discountValue'],
                                ),
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.white,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      promotion['title']?.toString() ?? '',
                                      style: AppTextStyles.labelLarge,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      coupon['status']?.toString() ??
                                          'AVAILABLE',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                promotion['description']?.toString() ?? '',
                                style: AppTextStyles.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                promotion['moduleType']?.toString() ??
                                    'General',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: _coupons.length),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Earn More Points', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  ...[
                    (
                      'Order Food',
                      '+50 pts per order',
                      Icons.restaurant_rounded,
                      AppColors.food,
                    ),
                    (
                      'Book a Ride',
                      '+30 pts per ride',
                      Icons.directions_car_rounded,
                      AppColors.ride,
                    ),
                    (
                      'Shop Online',
                      '+100 pts per \$50 spent',
                      Icons.shopping_bag_rounded,
                      AppColors.shopping,
                    ),
                    (
                      'Refer a Friend',
                      '+500 pts per referral',
                      Icons.group_add_rounded,
                      AppColors.primary,
                    ),
                  ].map(
                    (entry) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: entry.$4.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(entry.$3, color: entry.$4, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.$1,
                                  style: AppTextStyles.labelMedium,
                                ),
                                Text(entry.$2, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForModule(String? moduleType) {
    switch (moduleType?.toUpperCase()) {
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

  String _discountLabel(String? type, dynamic value) {
    final numeric = (value as num?)?.toDouble();
    if (type == 'PERCENTAGE' && numeric != null) {
      return '${numeric.toInt()}% Off';
    }
    if (numeric != null) {
      return numeric.toStringAsFixed(0);
    }
    return 'Offer';
  }
}
