import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/message_launcher.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class HomeServiceProviderScreen extends StatefulWidget {
  final String providerId;
  const HomeServiceProviderScreen({super.key, required this.providerId});

  @override
  State<HomeServiceProviderScreen> createState() =>
      _HomeServiceProviderScreenState();
}

class _HomeServiceProviderScreenState extends State<HomeServiceProviderScreen> {
  HomeServiceProviderModel? _provider;
  bool _isLoading = true;
  bool _hasBookedService = false;
  String? _bookingLookupUserId;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBookingAccess();
  }

  Future<void> _loadProvider() async {
    try {
      final response = await ApiClient.get(
        '/catalog/home-service-providers/${widget.providerId}',
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _provider = HomeServiceProviderModel.fromApi(
          Map<String, dynamic>.from(response as Map),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBookingAccess() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (_bookingLookupUserId == userId) return;
    _bookingLookupUserId = userId;

    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() => _hasBookedService = false);
      return;
    }

    try {
      final response = await ApiClient.get('/orders/$userId', forceRefresh: true);
      final orders = response is List ? response : const [];
      final hasBooked = orders.any((entry) {
        final order = Map<String, dynamic>.from(entry as Map);
        final moduleType = order['moduleType']?.toString().toUpperCase() ?? '';
        if (moduleType != 'HOME_SERVICES') return false;

        final status = order['status']?.toString().toUpperCase() ?? '';
        if (status == 'CANCELLED' || status == 'REFUNDED') return false;

        final items = (order['items'] as List? ?? const []);
        return items.any((item) {
          final orderItem = Map<String, dynamic>.from(item as Map);
          if (orderItem['id']?.toString() == widget.providerId) return true;

          final metadata = orderItem['metadata'];
          if (metadata is Map) {
            return metadata['providerId']?.toString() == widget.providerId;
          }
          return false;
        });
      });

      if (!mounted) return;
      setState(() => _hasBookedService = hasBooked);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasBookedService = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _isLoading || provider == null
            ? const DetailContentShimmer(
                accentColor: AppColors.homeServices,
                showHero: false,
              )
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.homeServices, Color(0xFF27B5A8)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            provider.categoryIcon,
                            color: AppColors.white,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.name,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _HeroPill(
                              label: provider.categoryName ?? 'Home Service',
                            ),
                            if (provider.isVerified)
                              const _HeroPill(label: 'Verified'),
                            if (provider.responseTime != null)
                              _HeroPill(label: provider.responseTime!),
                            if (provider.isAvailable)
                              const _HeroPill(label: 'Available today'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatRow(
                          rating: provider.rating,
                          reviewCount: provider.reviewCount,
                          experience: provider.yearsExperience,
                          price: provider.startingPrice,
                        ),
                        const SizedBox(height: 20),
                        Text('About', style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        Text(
                          provider.about ??
                              'No provider description available.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Services', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.services
                              .map(
                                (service) => _Tag(
                                  label: service,
                                  color: AppColors.homeServices,
                                ),
                              )
                              .toList(),
                        ),
                        if (provider.bookingModes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Booking Options', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: provider.bookingModes
                                .map(
                                  (mode) => _Tag(
                                    label: mode,
                                    color: AppColors.homeServices,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        if (provider.highlights.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Highlights', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          ...provider.highlights.map(
                            (highlight) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      highlight,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text('Availability', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppSpacing.shadowSm,
                          ),
                          child: Column(
                            children: [
                              _AvailabilityRow(
                                label: 'Weekdays',
                                value:
                                    provider.availability['weekdays']
                                        ?.toString() ??
                                    'Not set',
                              ),
                              _AvailabilityRow(
                                label: 'Saturday',
                                value:
                                    provider.availability['saturday']
                                        ?.toString() ??
                                    'Not set',
                              ),
                              _AvailabilityRow(
                                label: 'Sunday',
                                value:
                                    provider.availability['sunday']
                                        ?.toString() ??
                                    'Not set',
                              ),
                            ],
                          ),
                        ),
                        if (provider.location != null) ...[
                          const SizedBox(height: 20),
                          Text('Service Area', style: AppTextStyles.h4),
                          const SizedBox(height: 8),
                          Text(
                            provider.location!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                        if (provider.contactPhone != null &&
                            provider.contactPhone!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Contact', style: AppTextStyles.h4),
                          const SizedBox(height: 8),
                          Text(
                            provider.contactPhone!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 96),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomSheet: _isLoading || provider == null
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                16 + MediaQuery.of(context).padding.bottom,
              ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (!_hasBookedService) {
                        return Row(
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Starting From', style: AppTextStyles.caption),
                                Text(
                                  '\$${provider.startingPrice.toInt()}',
                                  style: AppTextStyles.price.copyWith(
                                    color: AppColors.homeServices,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                width: constraints.maxWidth,
                                child: AppButton(
                                  text: 'Book Service',
                                  color: AppColors.homeServices,
                                  onPressed: () => context.push(
                                    '/home-services/book/${provider.id}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Message',
                              isOutlined: true,
                              color: AppColors.homeServices,
                              onPressed: () => openConversation(
                                context,
                                moduleType: 'HOME_SERVICES',
                                entityType: 'HOME_SERVICE_PROVIDER',
                                entityId: provider.id,
                                title: provider.name,
                                subtitle: provider.title,
                                avatarUrl: provider.imageUrl,
                                accentColor: '#0F9D92',
                                metadata: {
                                  'providerId': provider.id,
                                  'categorySlug': provider.categorySlug,
                                  'serviceModes': provider.bookingModes,
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: 'Book Again',
                              color: AppColors.homeServices,
                              onPressed: () => context.push(
                                '/home-services/book/${provider.id}',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final String? experience;
  final double price;
  const _StatRow({
    required this.rating,
    required this.reviewCount,
    required this.experience,
    required this.price,
  });

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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('$rating', 'Rating'),
          _StatItem('$reviewCount+', 'Reviews'),
          _StatItem(experience ?? 'Fast', 'Experience'),
          _StatItem('\$${price.toInt()}', 'Starting'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.labelLarge),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  final String label;
  final String value;
  const _AvailabilityRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
