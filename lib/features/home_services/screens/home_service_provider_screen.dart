import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
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

  bool _isHouseHelpProvider(HomeServiceProviderModel provider) {
    final slug = (provider.categorySlug ?? '').toLowerCase();
    final name = (provider.categoryName ?? '').toLowerCase();
    final title = provider.title.toLowerCase();
    final services = provider.services.join(' ').toLowerCase();
    return slug.contains('house-help') ||
        slug.contains('house_help') ||
        slug.contains('househelp') ||
        slug.contains('maid') ||
        name.contains('house help') ||
        name.contains('maid') ||
        title.contains('house help') ||
        title.contains('maid') ||
        services.contains('house help') ||
        services.contains('maid');
  }

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
      if (_provider != null) {
        AnalyticsService.instance.track(
          AnalyticsEvents.entityOpened,
          properties: {
            'module': 'home_services',
            'entity_type': 'provider',
            'entity_id': _provider!.id,
            'source': 'home_service_provider_screen',
          },
        );
      }
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
      final response = await ApiClient.get(
        '/orders/$userId',
        forceRefresh: true,
      );
      final orders = response is List ? response : const [];
      final hasBooked = orders.any((entry) {
        final order = Map<String, dynamic>.from(entry as Map);
        final moduleType = order['moduleType']?.toString().toUpperCase() ?? '';
        if (moduleType != 'HOME_SERVICES' && moduleType != 'HOUSE_HELP') {
          return false;
        }

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
    final l10n = context.l10n;
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
            onPressed: () {
              AnalyticsService.instance.track(
                AnalyticsEvents.wishlistToggled,
                properties: {
                  'module': 'home_services',
                  'entity_type': 'provider',
                  'entity_id': provider?.id ?? widget.providerId,
                  'source': 'home_service_provider_screen',
                  'state': 'unknown',
                },
              );
            },
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
                        colors: [
                          AppColors.homeServices,
                          AppColors.secondaryLight,
                        ],
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
                          child:
                              provider.imageUrl != null &&
                                  provider.imageUrl!.trim().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.network(
                                    provider.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Icon(
                                      provider.categoryIcon,
                                      color: AppColors.white,
                                      size: 42,
                                    ),
                                  ),
                                )
                              : Icon(
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
                          l10n.homeServiceProviderSubtitle(
                            categorySlug: provider.categorySlug,
                            categoryName: provider.categoryName,
                            fallbackTitle: provider.title,
                          ),
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
                              label: l10n.homeServiceCategoryName(
                                provider.categorySlug ?? '',
                                provider.categoryName ??
                                    l10n.t('home_provider.home_service'),
                              ),
                            ),
                            if (provider.isVerified)
                              _HeroPill(
                                label: l10n.t('home_provider.verified'),
                              ),
                            if (provider.responseTime != null)
                              _HeroPill(label: provider.responseTime!),
                            if (provider.isAvailable)
                              _HeroPill(
                                label: l10n.t('home_provider.available_today'),
                              ),
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
                        Text(
                          l10n.t('home_provider.about'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          provider.about ??
                              l10n.t('home_provider.no_description'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.t('home_provider.services'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.services
                              .map(
                                (service) => _Tag(
                                  label: l10n.homeServiceDynamicLabel(service),
                                  color: AppColors.homeServices,
                                ),
                              )
                              .toList(),
                        ),
                        if (provider.bookingModes.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n.t('home_provider.booking_options'),
                            style: AppTextStyles.h4,
                          ),
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
                          Text(
                            l10n.t('home_provider.highlights'),
                            style: AppTextStyles.h4,
                          ),
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
                        Text(
                          l10n.t('home_provider.availability'),
                          style: AppTextStyles.h4,
                        ),
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
                                label: l10n.t('home_provider.weekdays'),
                                value:
                                    provider.availability['weekdays']
                                        ?.toString() ??
                                    l10n.t('home_provider.not_set'),
                              ),
                              _AvailabilityRow(
                                label: l10n.t('home_provider.saturday'),
                                value:
                                    provider.availability['saturday']
                                        ?.toString() ??
                                    l10n.t('home_provider.not_set'),
                              ),
                              _AvailabilityRow(
                                label: l10n.t('home_provider.sunday'),
                                value:
                                    provider.availability['sunday']
                                        ?.toString() ??
                                    l10n.t('home_provider.not_set'),
                              ),
                            ],
                          ),
                        ),
                        if (provider.location != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n.t('home_provider.service_area'),
                            style: AppTextStyles.h4,
                          ),
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
                          Text(
                            l10n.t('home_provider.contact'),
                            style: AppTextStyles.h4,
                          ),
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
                                Text(
                                  l10n.t('home_provider.starting_from'),
                                  style: AppTextStyles.caption,
                                ),
                                Text(
                                  'DJF ${provider.startingPrice.toInt()}',
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
                                  text: l10n.t('home_provider.book_service'),
                                  color: AppColors.homeServices,
                                  onPressed: () {
                                    AnalyticsService.instance.track(
                                      AnalyticsEvents.checkoutEntryTapped,
                                      properties: {
                                        'module': 'home_services',
                                        'source':
                                            'provider_screen_book_service',
                                        'entity_type': 'provider',
                                        'entity_id': provider.id,
                                      },
                                    );
                                    context.push(
                                      '/home-services/book/${provider.id}',
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Builder(
                            builder: (context) {
                              final conversationModuleType =
                                  _isHouseHelpProvider(provider)
                                  ? 'HOUSE_HELP'
                                  : 'HOME_SERVICES';
                              return Expanded(
                                child: AppButton(
                                  text: l10n.t('home_provider.message'),
                                  isOutlined: true,
                                  color: AppColors.homeServices,
                                  onPressed: () {
                                    AnalyticsService.instance.track(
                                      AnalyticsEvents.entityOpened,
                                      properties: {
                                        'module': 'home_services',
                                        'entity_type': 'provider_chat',
                                        'entity_id': provider.id,
                                        'source': 'provider_screen',
                                      },
                                    );
                                    openConversation(
                                      context,
                                      moduleType: conversationModuleType,
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
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              text: l10n.t('home_provider.book_again'),
                              color: AppColors.homeServices,
                              onPressed: () {
                                AnalyticsService.instance.track(
                                  AnalyticsEvents.checkoutEntryTapped,
                                  properties: {
                                    'module': 'home_services',
                                    'source': 'provider_screen_book_again',
                                    'entity_type': 'provider',
                                    'entity_id': provider.id,
                                  },
                                );
                                context.push(
                                  '/home-services/book/${provider.id}',
                                );
                              },
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
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _StatItem('$rating', l10n.t('home_provider.rating')),
              ),
              Expanded(
                child: _StatItem(
                  '$reviewCount+',
                  l10n.t('home_provider.reviews'),
                ),
              ),
              Expanded(
                child: _StatItem(
                  'DJF ${price.toInt()}',
                  l10n.t('home_provider.starting'),
                ),
              ),
            ],
          ),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: AppTextStyles.labelLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
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
