import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';

class HomeServicesScreen extends StatefulWidget {
  const HomeServicesScreen({super.key});

  @override
  State<HomeServicesScreen> createState() => _HomeServicesScreenState();
}

class _HomeServicesScreenState extends State<HomeServicesScreen> {
  static const String _houseHelpBannerAsset =
      'assets/images/banners/home-service-banner.png';
  final TextEditingController _searchController = TextEditingController();
  List<HomeServiceCategoryModel> _categories = const [];
  List<HomeServiceProviderModel> _providers = const [];
  bool _isLoading = true;

  List<HomeServiceProviderModel> get _featuredProviders {
    final providers = [..._providers]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return providers.take(4).toList();
  }

  List<HomeServiceProviderModel> get _availableNow =>
      _providers.where((provider) => provider.isAvailable).take(3).toList();

  bool _isCleaningCategory(HomeServiceCategoryModel category) {
    final slug = category.slug.toLowerCase();
    final name = category.name.toLowerCase();
    return slug.contains('clean') || name.contains('clean');
  }

  bool _isHouseHelpCategory(HomeServiceCategoryModel category) {
    final slug = category.slug.toLowerCase();
    final name = category.name.toLowerCase();
    final description = category.description.toLowerCase();
    final matchesSlug =
        slug.contains('house-help') ||
        slug.contains('house_help') ||
        slug.contains('househelp') ||
        (slug.contains('house') && slug.contains('help')) ||
        slug.contains('maid') ||
        slug.contains('helper');
    final matchesText =
        name.contains('house help') ||
        name.contains('maid') ||
        name.contains('helper') ||
        description.contains('house help') ||
        description.contains('maid');
    return matchesSlug || matchesText;
  }

  bool _isHouseHelpGroupCategory(HomeServiceCategoryModel category) {
    return _isHouseHelpCategory(category) || _isCleaningCategory(category);
  }

  HomeServiceCategoryModel? get _houseHelpCategory {
    for (final category in _categories) {
      if (_isHouseHelpCategory(category)) return category;
    }
    for (final category in _categories) {
      if (_isCleaningCategory(category)) return category;
    }
    return null;
  }

  List<HomeServiceCategoryModel> get _displayCategories {
    final houseHelp = _houseHelpCategory;
    if (houseHelp == null) return _categories;
    return _categories
        .where((category) {
          if (category.id == houseHelp.id) return true;
          if (_isCleaningCategory(category)) return false;
          return true;
        })
        .toList(growable: false);
  }

  HomeServiceCategoryModel get _fallbackHouseHelpCategory =>
      const HomeServiceCategoryModel(
        id: 'house-help',
        name: 'House Help',
        slug: 'house-help',
        description: 'Daily chores, cleaning, and dependable in-home support.',
        iconKey: 'cleaning',
        colorHex: '#1A9A77',
        providerCount: 0,
      );

  HomeServiceCategoryModel get _houseHelpDisplayCategory =>
      _houseHelpCategory ?? _fallbackHouseHelpCategory;

  bool _isHouseHelpProvider(HomeServiceProviderModel provider) {
    final slug = (provider.categorySlug ?? '').toLowerCase();
    final categoryName = (provider.categoryName ?? '').toLowerCase();
    final title = provider.title.toLowerCase();
    final services = provider.services.join(' ').toLowerCase();
    return slug.contains('house-help') ||
        slug.contains('house_help') ||
        slug.contains('househelp') ||
        (slug.contains('house') && slug.contains('help')) ||
        slug.contains('maid') ||
        categoryName.contains('house help') ||
        categoryName.contains('maid') ||
        title.contains('house help') ||
        title.contains('maid') ||
        slug.contains('clean') ||
        categoryName.contains('clean') ||
        services.contains('house help') ||
        services.contains('maid') ||
        services.contains('clean');
  }

  HomeServiceProviderModel? get _preferredHouseHelpProvider {
    final candidates = _providers
        .where(_isHouseHelpProvider)
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    final ranked = [...candidates]
      ..sort((a, b) {
        final availabilityOrder = (b.isAvailable ? 1 : 0).compareTo(
          a.isAvailable ? 1 : 0,
        );
        if (availabilityOrder != 0) return availabilityOrder;
        final ratingOrder = b.rating.compareTo(a.rating);
        if (ratingOrder != 0) return ratingOrder;
        return b.reviewCount.compareTo(a.reviewCount);
      });
    return ranked.first;
  }

  void _openHouseHelpCategory(BuildContext context) {
    final l10n = context.l10n;
    final provider = _preferredHouseHelpProvider;
    if (provider != null) {
      context.push('/home-services/book/${provider.id}');
      return;
    }
    final category = _houseHelpCategory;
    if (category == null) {
      context.push(
        '/home-services/category/all',
        extra: {
          'label': l10n.homeServiceCategoryName(
            _fallbackHouseHelpCategory.slug,
            _fallbackHouseHelpCategory.name,
          ),
        },
      );
      return;
    }
    context.push(
      '/home-services/category/${category.slug}',
      extra: {
        'label': l10n.homeServiceCategoryName(category.slug, category.name),
      },
    );
  }

  void _openCategory(BuildContext context, HomeServiceCategoryModel category) {
    final l10n = context.l10n;
    if (_isHouseHelpGroupCategory(category)) {
      _openHouseHelpCategory(context);
      return;
    }
    context.push(
      '/home-services/category/${category.slug}',
      extra: {
        'label': l10n.homeServiceCategoryName(category.slug, category.name),
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/catalog/home-service-categories', forceRefresh: true),
        ApiClient.get('/catalog/home-service-providers', forceRefresh: true),
      ]);
      final categories = (results[0] as List)
          .map(
            (item) => HomeServiceCategoryModel.fromApi(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final providers = (results[1] as List)
          .map(
            (item) => HomeServiceProviderModel.fromApi(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _providers = providers;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.35);
    final categoryGridAspectRatio =
        (1.02 -
                (l10n.languageCode == 'en' ? 0.0 : 0.12) -
                ((textScale - 1.0) * 0.23))
            .clamp(0.82, 1.02);
    final houseHelpCategory = _houseHelpDisplayCategory;
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
          title: Text(l10n.t('home_services.title')),
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
                  hint: l10n.t('home_services.search_hint'),
                  controller: _searchController,
                  readOnly: true,
                  onTap: () => context.push('/home-services/category/all'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: GestureDetector(
                  onTap: () => _openHouseHelpCategory(context),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0D8067),
                          AppColors.homeServices,
                          Color(0xFF43BA92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                12,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.homeServiceCategoryName(
                                      houseHelpCategory.slug,
                                      houseHelpCategory.name,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.h3.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.t('home_services.house_help_subtitle'),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _HouseHelpTag(
                                        label: l10n.t(
                                          'home_services.house_help_tag_cleaning',
                                        ),
                                      ),
                                      _HouseHelpTag(
                                        label: l10n.t(
                                          'home_services.house_help_tag_dishes',
                                        ),
                                      ),
                                      _HouseHelpTag(
                                        label: l10n.t(
                                          'home_services.house_help_tag_laundry',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              l10n.t(
                                                'home_services.book_service',
                                              ),
                                              style: AppTextStyles.labelMedium
                                                  .copyWith(
                                                    color:
                                                        AppColors.homeServices,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: AppColors.homeServices,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  _houseHelpBannerAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _HouseHelpImageFallback(
                                        color: houseHelpCategory.color,
                                        label: l10n.t(
                                          'home_services.house_help_add_image',
                                        ),
                                      ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.26),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.t('home_services.popular_categories'),
                        style: AppTextStyles.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/home-services/category/all'),
                      child: Text(l10n.t('home_services.see_all')),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              SliverSectionGridShimmer(
                itemCount: 6,
                childAspectRatio: categoryGridAspectRatio,
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _displayCategories
                            .map((category) {
                              return SizedBox(
                                width: cardWidth,
                                child: GestureDetector(
                                  onTap: () => _openCategory(context, category),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: AppSpacing.shadowSm,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: category.color
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                category.icon,
                                                color: category.color,
                                                size: 22,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: category.color
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Icon(
                                                Icons.arrow_outward_rounded,
                                                size: 16,
                                                color: category.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.homeServiceCategoryName(
                                            category.slug,
                                            category.name,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.labelLarge
                                              .copyWith(
                                                fontWeight: FontWeight.w800,
                                                height: 1.3,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          category.description.isEmpty
                                              ? l10n.t(
                                                  'home_services.category_description_fallback',
                                                )
                                              : l10n.homeServiceCategoryDescription(
                                                  category.slug,
                                                  category.description,
                                                ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.grey,
                                                height: 1.35,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Text(
                      l10n.t('home_services.available_now'),
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverSectionListShimmer(itemCount: 3)
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final provider = _availableNow[index];
                  return _FeaturedProviderCard(
                    provider: provider,
                    onTap: () =>
                        context.push('/home-services/provider/${provider.id}'),
                    accentColor: provider.categoryColor,
                  );
                }, childCount: _availableNow.length),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.t('home_services.top_professionals'),
                        style: AppTextStyles.h3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.push('/home-services/category/all'),
                      child: Text(l10n.t('home_services.see_all')),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverSectionListShimmer(itemCount: 4)
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final provider = _featuredProviders[index];
                  return _FeaturedProviderCard(
                    provider: provider,
                    onTap: () =>
                        context.push('/home-services/provider/${provider.id}'),
                    accentColor: provider.categoryColor,
                  );
                }, childCount: _featuredProviders.length),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('home_services.why_people_use'),
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: 14),
                      _TrustRow(
                        icon: Icons.verified_user_rounded,
                        title: l10n.t('home_services.verified_title'),
                        subtitle: l10n.t('home_services.verified_subtitle'),
                      ),
                      const SizedBox(height: 12),
                      _TrustRow(
                        icon: Icons.schedule_rounded,
                        title: l10n.t('home_services.scheduling_title'),
                        subtitle: l10n.t('home_services.scheduling_subtitle'),
                      ),
                      const SizedBox(height: 12),
                      _TrustRow(
                        icon: Icons.payments_rounded,
                        title: l10n.t('home_services.pricing_title'),
                        subtitle: l10n.t('home_services.pricing_subtitle'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _HouseHelpTag extends StatelessWidget {
  final String label;

  const _HouseHelpTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _HouseHelpImageFallback extends StatelessWidget {
  final Color color;
  final String label;

  const _HouseHelpImageFallback({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.92),
            color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cleaning_services_rounded,
            color: AppColors.white,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedProviderCard extends StatelessWidget {
  final HomeServiceProviderModel provider;
  final VoidCallback onTap;
  final Color accentColor;

  const _FeaturedProviderCard({
    required this.provider,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(provider.categoryIcon, color: accentColor, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.name,
                          style: AppTextStyles.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (provider.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            context.l10n.t('home_services.open'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.homeServiceProviderSubtitle(
                      categorySlug: provider.categorySlug,
                      categoryName: provider.categoryName,
                      fallbackTitle: provider.title,
                    ),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text('${provider.rating}'),
                      Text(
                        ' (${provider.reviewCount})',
                        style: AppTextStyles.caption,
                      ),
                      const Spacer(),
                      Text(
                        '\$${provider.startingPrice.toInt()}',
                        style: AppTextStyles.priceSmall.copyWith(
                          color: accentColor,
                        ),
                      ),
                      Text(
                        context.l10n.t('home_services.per_start'),
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
  }
}

class _TrustRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _TrustRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.homeServicesBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.homeServices, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.grey,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
