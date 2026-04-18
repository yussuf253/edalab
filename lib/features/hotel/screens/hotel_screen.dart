import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';

class HotelScreen extends StatefulWidget {
  const HotelScreen({super.key});

  @override
  State<HotelScreen> createState() => _HotelScreenState();
}

class _HotelScreenState extends State<HotelScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<HotelModel> _hotels = [];
  bool _isLoading = true;
  Timer? _searchDebounce;
  String _lastTrackedSearch = '';

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    try {
      final response = await ApiClient.get('/catalog/hotels');
      final items = (response as List)
          .map(
            (item) =>
                HotelModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _hotels = items.isEmpty ? HotelModel.sampleHotels : items;
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'hotel',
          'entity_type': 'hotel',
          'result_count': _hotels.length,
          'source': 'remote',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'hotel',
          'entity_type': 'hotel',
          'result_count': _hotels.length,
          'source': 'fallback_sample',
        },
      );
    }
  }

  void _onSearchChanged(String value) {
    final nextQuery = value.trim();
    setState(() => _searchQuery = nextQuery);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      final normalizedQuery = nextQuery.toLowerCase();
      if (normalizedQuery == _lastTrackedSearch) return;
      _lastTrackedSearch = normalizedQuery;
      if (normalizedQuery.isNotEmpty && normalizedQuery.length < 2) return;

      AnalyticsService.instance.track(
        AnalyticsEvents.searchPerformed,
        properties: {
          'module': 'hotel',
          'query': normalizedQuery,
          'query_length': normalizedQuery.length,
          'result_count': _filteredHotels().length,
        },
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hotels = _filteredHotels();

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('hotel.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: AppSearchBar(
                  hint: l10n.t('hotel.search_hint'),
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  suffix: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.mediumGrey,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.t('hotel.popular_destinations'),
                  style: AppTextStyles.h4,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DestChip(
                      '🏖️',
                      l10n.t('hotel.beach'),
                      onTap: () => _applyDestination(
                        displayLabel: l10n.t('hotel.beach'),
                        mappedQuery: 'beach',
                      ),
                    ),
                    _DestChip(
                      '🏔️',
                      l10n.t('hotel.mountain'),
                      onTap: () => _applyDestination(
                        displayLabel: l10n.t('hotel.mountain'),
                        mappedQuery: 'mountain',
                      ),
                    ),
                    _DestChip(
                      '🌆',
                      l10n.t('hotel.city'),
                      onTap: () => _applyDestination(
                        displayLabel: l10n.t('hotel.city'),
                        mappedQuery: 'city',
                      ),
                    ),
                    _DestChip(
                      '🏝️',
                      l10n.t('hotel.island'),
                      onTap: () => _applyDestination(
                        displayLabel: l10n.t('hotel.island'),
                        mappedQuery: 'island',
                      ),
                    ),
                    _DestChip(
                      '🏜️',
                      l10n.t('hotel.desert'),
                      onTap: () => _applyDestination(
                        displayLabel: l10n.t('hotel.desert'),
                        mappedQuery: 'desert',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Text(l10n.t('hotel.recommended'), style: AppTextStyles.h4),
                    const Spacer(),
                    if (_isLoading)
                      const AppShimmer(
                        child: ShimmerBlock(width: 54, height: 14, radius: 10),
                      )
                    else
                      Text(
                        l10n.t(
                          'hotel.found_count',
                          params: {'count': '${hotels.length}'},
                        ),
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const _HotelListShimmer(itemCount: 4)
            else if (hotels.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.hotel_rounded,
                          size: 44,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.t('hotel.no_hotels'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.t('hotel.no_hotels_subtitle'),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final h = hotels[index];
                  final type = h.amenities.isNotEmpty
                      ? h.amenities.first
                      : 'Hotel';
                  return GestureDetector(
                    onTap: () {
                      AnalyticsService.instance.track(
                        AnalyticsEvents.entityOpened,
                        properties: {
                          'module': 'hotel',
                          'entity_type': 'hotel',
                          'entity_id': h.id,
                          'source': 'hotel_list',
                        },
                      );
                      context.push('/hotel/detail/${h.id}');
                    },
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
                                colors: [
                                  AppColors.hotel.withValues(alpha: 0.3),
                                  AppColors.hotel.withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.hotel_rounded,
                                    size: 48,
                                    color: AppColors.hotel.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.hotel,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      type,
                                      style: AppTextStyles.badge,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.favorite_border_rounded,
                                      size: 18,
                                      color: AppColors.grey,
                                    ),
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
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: AppColors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${h.city} • ${h.address}',
                                        style: AppTextStyles.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 16,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${h.rating}',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.dark,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${h.reviewsCount})',
                                      style: AppTextStyles.caption,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '\$${h.pricePerNight.toInt()}',
                                      style: AppTextStyles.priceSmall.copyWith(
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
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: hotels.length),
              ),
          ],
        ),
      ),
    );
  }

  List<HotelModel> _filteredHotels() {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      return _hotels;
    }

    return _hotels.where((hotel) {
      final destinationTerms = switch (query) {
        'beach' => ['beach', 'resort', 'pool', 'waterfront', 'seafront'],
        'mountain' => ['mountain', 'lodge', 'alpine', 'ski'],
        'city' => ['city', 'central', 'downtown', 'business'],
        'island' => ['island', 'resort', 'beachfront'],
        'desert' => ['desert', 'resort', 'oasis'],
        _ => <String>[],
      };

      final matchesDestination =
          destinationTerms.isNotEmpty &&
          destinationTerms.any(
            (term) =>
                hotel.name.toLowerCase().contains(term) ||
                hotel.city.toLowerCase().contains(term) ||
                hotel.address.toLowerCase().contains(term) ||
                hotel.amenities.any(
                  (amenity) => amenity.toLowerCase().contains(term),
                ) ||
                hotel.description.toLowerCase().contains(term),
          );

      return hotel.name.toLowerCase().contains(query) ||
          hotel.city.toLowerCase().contains(query) ||
          hotel.address.toLowerCase().contains(query) ||
          hotel.description.toLowerCase().contains(query) ||
          hotel.amenities.any(
            (amenity) => amenity.toLowerCase().contains(query),
          ) ||
          matchesDestination;
    }).toList();
  }

  void _applyDestination({
    required String displayLabel,
    required String mappedQuery,
  }) {
    _searchController.text = displayLabel;
    setState(() => _searchQuery = mappedQuery);
    AnalyticsService.instance.track(
      AnalyticsEvents.filterApplied,
      properties: {
        'module': 'hotel',
        'filter_type': 'destination',
        'filter_value': mappedQuery,
        'result_count': _filteredHotels().length,
      },
    );
  }
}

class _HotelListShimmer extends StatelessWidget {
  final int itemCount;

  const _HotelListShimmer({this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return const AppShimmer(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: _HotelCardShimmer(),
          ),
        );
      }, childCount: itemCount),
    );
  }
}

class _HotelCardShimmer extends StatelessWidget {
  const _HotelCardShimmer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFFF3F6FB),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
                Center(child: ShimmerBlock(width: 48, height: 48, radius: 16)),
                Positioned(
                  top: 12,
                  left: 12,
                  child: ShimmerBlock(width: 74, height: 28, radius: 8),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: ShimmerBlock(width: 36, height: 36, radius: 999),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: 170, height: 18),
                SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerBlock(width: 14, height: 14, radius: 999),
                    SizedBox(width: 6),
                    Expanded(
                      child: ShimmerBlock(
                        width: double.infinity,
                        height: 12,
                        radius: 10,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    ShimmerBlock(width: 72, height: 14, radius: 10),
                    SizedBox(width: 10),
                    ShimmerBlock(width: 58, height: 12, radius: 10),
                    Spacer(),
                    ShimmerBlock(width: 80, height: 16, radius: 10),
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

class _DestChip extends StatelessWidget {
  final String emoji;
  final String name;
  final VoidCallback onTap;

  const _DestChip(this.emoji, this.name, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
