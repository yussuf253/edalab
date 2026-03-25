import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home Services'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppSearchBar(
                hint: 'Search cleaning, plumbing, beauty...',
                controller: _searchController,
                readOnly: true,
                onTap: () => context.push('/home-services/category/all'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.homeServices, Color(0xFF27B5A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trusted help, right at home',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Book cleaning, repairs, beauty, and technical support with verified professionals.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.handyman_rounded,
                            color: AppColors.white,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BannerChip(
                          label: '${_categories.length} service types',
                        ),
                        _BannerChip(label: '${_providers.length} active pros'),
                        const _BannerChip(label: 'Same-day slots'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: _BannerStat(
                            value: '15m',
                            label: 'Avg response',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BannerStat(
                            value: _availableNow.length.toString(),
                            label: 'Available now',
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: _BannerStat(value: '4.8', label: 'Avg rating'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Text('Popular Categories', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        context.push('/home-services/category/all'),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverSectionGridShimmer(itemCount: 6, childAspectRatio: 0.95)
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = _categories[index];
                  return GestureDetector(
                    onTap: () => context.push(
                      '/home-services/category/${category.slug}',
                      extra: {'label': category.name},
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              category.icon,
                              color: category.color,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.grey,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${category.providerCount} available',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: category.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: _categories.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Text('Available Right Now', style: AppTextStyles.h3),
                  const Spacer(),
                  Text(
                    'Fastest response',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
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
                  Text('Top Professionals', style: AppTextStyles.h3),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        context.push('/home-services/category/all'),
                    child: const Text('See All'),
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
                      'Why people use Home Services',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 14),
                    const _TrustRow(
                      icon: Icons.verified_user_rounded,
                      title: 'Verified professionals',
                      subtitle:
                          'Trusted providers with clear reviews and profile details.',
                    ),
                    const SizedBox(height: 12),
                    const _TrustRow(
                      icon: Icons.schedule_rounded,
                      title: 'Easy scheduling',
                      subtitle: 'Choose the time slot that fits your day.',
                    ),
                    const SizedBox(height: 12),
                    const _TrustRow(
                      icon: Icons.payments_rounded,
                      title: 'Clear starting prices',
                      subtitle:
                          'Know the base fee before you confirm your booking.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  final String label;
  const _BannerChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String value;
  final String label;

  const _BannerStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.h4.copyWith(color: AppColors.white)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
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
                            'Open',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.title,
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
                      Text('/start', style: AppTextStyles.caption),
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
