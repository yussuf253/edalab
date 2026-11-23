import 'package:flutter/material.dart';

import '../../../core/widgets/module_screen_app_bar.dart';
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
import '../utils/home_service_category_image.dart';
import '../widgets/home_service_category_art.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeServicesScreen extends StatefulWidget {
  const HomeServicesScreen({super.key});

  @override
  State<HomeServicesScreen> createState() => _HomeServicesScreenState();
}

/// Loading placeholder for the category grid: 3 columns of image plates with
/// a label bar, matching the real tiles.
class _CategoryGridShimmer extends StatelessWidget {
  const _CategoryGridShimmer({required this.aspectRatio});

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const AppShimmer(
            child: Column(
              children: [
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 18,
                  ),
                ),
                SizedBox(height: 6),
                ShimmerBlock(width: 56, height: 10, radius: 6),
              ],
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

class _HomeServicesScreenState extends State<HomeServicesScreen> {
  static const String _handymanHeaderAsset =
      'assets/images/headers/header_handyman.png';
  final TextEditingController _searchController = TextEditingController();
  List<HomeServiceCategoryModel> _categories = const [];
  bool _isLoading = true;

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

  void _openHouseHelpCategory(BuildContext context) {
    AnalyticsService.instance.track(
      AnalyticsEvents.filterApplied,
      properties: {
        'module': 'home_services',
        'filter_type': 'category',
        'filter_value': 'house_help',
      },
    );
    context.push('/home-services/book/house-help-zone');
    return;
  }

  void _openCategory(BuildContext context, HomeServiceCategoryModel category) {
    final l10n = context.l10n;
    if (_isHouseHelpGroupCategory(category)) {
      _openHouseHelpCategory(context);
      return;
    }
    AnalyticsService.instance.track(
      AnalyticsEvents.filterApplied,
      properties: {
        'module': 'home_services',
        'filter_type': 'category',
        'filter_value': category.slug,
      },
    );
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
      final result = await ApiClient.get(
        '/catalog/home-service-categories',
        forceRefresh: true,
      );
      final categories = (result as List)
          .map(
            (item) => HomeServiceCategoryModel.fromApi(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'home_services',
          'entity_type': 'category',
          'result_count': _categories.length,
          'source': 'remote',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'home_services',
          'entity_type': 'category',
          'result_count': _categories.length,
          'source': 'fallback_empty',
        },
      );
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
    // Each tile is a square picture plus a label line under it.
    const categoryGridAspectRatio = 1.23;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModuleScreenAppBar(
          title: l10n.t('home_services.title'),
          search: AppSearchBar(
            hint: l10n.t('home_services.search_hint'),
            controller: _searchController,
            readOnly: true,
            onTap: () {
              AnalyticsService.instance.track(
                AnalyticsEvents.entityOpened,
                properties: {
                  'module': 'home_services',
                  'entity_type': 'category_browser',
                  'entity_id': 'all',
                  'source': 'home_services_search_bar',
                },
              );
              context.push('/home-services/category/all');
            },
          ),
        ),
        body: CustomScrollView(
          slivers: [
            // Module hero, matching grocery / pharmacy: 132-high rounded plate
            // with the handyman header artwork right-aligned behind the copy.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => _openHouseHelpCategory(context),
                  child: Container(
                    height: 132,
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.homeServicesBg,
                      image: const DecorationImage(
                        image: AssetImage(_handymanHeaderAsset),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.t('home_services.hero_title'),
                                style: AppTextStyles.h4,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.t('home_services.hero_subtitle'),
                                style: AppTextStyles.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 96),
                      ],
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
                      onPressed: () {
                        AnalyticsService.instance.track(
                          AnalyticsEvents.filterApplied,
                          properties: {
                            'module': 'home_services',
                            'filter_type': 'category',
                            'filter_value': 'all',
                            'source': 'popular_categories_see_all',
                          },
                        );
                        context.push('/home-services/category/all');
                      },
                      child: Text(l10n.t('home_services.see_all')),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              _CategoryGridShimmer(aspectRatio: categoryGridAspectRatio)
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 24) / 3;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _displayCategories
                            .map((category) {
                              final imagePath = homeServiceCategoryImage(
                                category.slug,
                                category.name,
                              );
                              return SizedBox(
                                width: cardWidth,
                                child: GestureDetector(
                                  onTap: () => _openCategory(context, category),
                                  child: Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: homeServiceCategoryPlateColor,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Square picture at full tile width:
                                        // the artwork fills the plate.
                                        // Square picture area; the shared art
                                        // widget clips the artwork's empty left
                                        // and bottom margins so the figure is
                                        // centred and the label sits close.
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: HomeServiceCategoryArt(
                                            imagePath: imagePath,
                                            fallbackIcon: category.icon,
                                            fallbackColor: category.color,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            6,
                                            0,
                                            6,
                                            8,
                                          ),
                                          child: Text(
                                            l10n.homeServiceCategoryName(
                                              category.slug,
                                              category.name,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.labelLarge
                                                .copyWith(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.15,
                                                  color: AppColors.dark,
                                                ),
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
                        icon: LucideIcons.shieldCheck,
                        title: l10n.t('home_services.verified_title'),
                        subtitle: l10n.t('home_services.verified_subtitle'),
                      ),
                      const SizedBox(height: 12),
                      _TrustRow(
                        icon: LucideIcons.clock,
                        title: l10n.t('home_services.scheduling_title'),
                        subtitle: l10n.t('home_services.scheduling_subtitle'),
                      ),
                      const SizedBox(height: 12),
                      _TrustRow(
                        icon: LucideIcons.banknote,
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
