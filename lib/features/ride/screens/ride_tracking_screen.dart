import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_shimmer.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideId;
  final Map<String, dynamic>? rideData;

  const RideTrackingScreen({super.key, required this.rideId, this.rideData});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  Map<String, dynamic>? _rideData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rideData = widget.rideData;
    _isLoading = widget.rideData == null;
    if (_isLoading) {
      _loadRide();
    }
  }

  Future<void> _loadRide() async {
    try {
      final response = await ApiClient.get('/rides/${widget.rideId}');
      if (!mounted) return;
      setState(() {
        _rideData = Map<String, dynamic>.from(response as Map);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _rideData;
    final pickup = ride?['pickup'] as String? ?? '123 Main Street';
    final destination =
        ride?['destination'] as String? ?? 'City Mall, Downtown';
    final eta = ride?['eta'] as String? ?? '5 min';
    final vehicle = ride?['vehicle'] as String? ?? 'Toyota Camry';
    final driverName = ride?['driverName'] as String? ?? 'Ahmed K.';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.46,
            width: double.infinity,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.extraLightGrey,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 80,
                              color: AppColors.ride.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Live Map',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 110,
                        left: 40,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 110,
                        right: 60,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 160,
                        left: MediaQuery.of(context).size.width * 0.4,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.ride,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.ride.withValues(alpha: 0.3),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 50,
                  left: 20,
                  child: GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/ride');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppSpacing.shadowMd,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ride,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ride.withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: AppColors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          eta,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: _isLoading
                    ? const AppShimmer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBlock(width: 40, height: 4, radius: 2),
                            SizedBox(height: 16),
                            ShimmerBlock(width: 180, height: 24, radius: 8),
                            SizedBox(height: 16),
                            ShimmerBlock(
                              width: double.infinity,
                              height: 82,
                              radius: 16,
                            ),
                            SizedBox(height: 14),
                            ShimmerBlock(
                              width: double.infinity,
                              height: 84,
                              radius: 16,
                            ),
                          ],
                        ),
                      )
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _error!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.lightGrey,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Your ride is arriving',
                                    style: AppTextStyles.h4,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (ride?['status'] as String? ?? 'on the way')
                                        .replaceAll('_', ' '),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.extraLightGrey,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.rideBg,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppColors.ride,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driverName,
                                          style: AppTextStyles.labelLarge,
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              color: AppColors.warning,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '4.9',
                                              style: AppTextStyles.labelSmall,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '$vehicle • ABC 1234',
                                                style: AppTextStyles.caption,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      color: AppColors.success,
                                      size: 12,
                                    ),
                                    Container(
                                      width: 2,
                                      height: 20,
                                      color: AppColors.lightGrey,
                                    ),
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.accent,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pickup,
                                        style: AppTextStyles.labelMedium,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        destination,
                                        style: AppTextStyles.labelMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.lightGrey,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.chat_rounded,
                                          color: AppColors.ride,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Message',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(color: AppColors.ride),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.ride,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Icons.call_rounded,
                                          color: AppColors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Call Driver',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(color: AppColors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
