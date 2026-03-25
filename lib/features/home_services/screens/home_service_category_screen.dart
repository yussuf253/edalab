import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';

class HomeServiceCategoryScreen extends StatefulWidget {
  final String categorySlug;
  final String? categoryLabel;

  const HomeServiceCategoryScreen({
    super.key,
    required this.categorySlug,
    this.categoryLabel,
  });

  @override
  State<HomeServiceCategoryScreen> createState() =>
      _HomeServiceCategoryScreenState();
}

class _HomeServiceCategoryScreenState extends State<HomeServiceCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  HomeServiceCategoryModel? _category;
  List<HomeServiceProviderModel> _providers = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final categoriesResponse = await ApiClient.get(
        '/catalog/home-service-categories',
        forceRefresh: true,
      );
      final endpoint = widget.categorySlug == 'all'
          ? '/catalog/home-service-providers'
          : '/catalog/home-service-providers?category=${widget.categorySlug}';
      final response = await ApiClient.get(endpoint, forceRefresh: true);
      final categories = (categoriesResponse as List)
          .map(
            (item) => HomeServiceCategoryModel.fromApi(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final items = (response as List)
          .map(
            (item) => HomeServiceProviderModel.fromApi(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _category = widget.categorySlug == 'all'
            ? null
            : categories.cast<HomeServiceCategoryModel?>().firstWhere(
                (item) => item?.slug == widget.categorySlug,
                orElse: () => null,
              );
        _providers = items;
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
    final query = _searchController.text.trim().toLowerCase();
    final category = _category;
    final visibleProviders = _providers.where((provider) {
      if (query.isEmpty) return true;
      return provider.name.toLowerCase().contains(query) ||
          provider.title.toLowerCase().contains(query) ||
          provider.services.any(
            (service) => service.toLowerCase().contains(query),
          );
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryLabel ?? 'Professionals'),
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
                hint: 'Search professionals or services...',
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          if (category != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: category.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          category.icon,
                          color: category.color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.name, style: AppTextStyles.h4),
                            const SizedBox(height: 4),
                            Text(
                              category.description,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey,
                                height: 1.4,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                children: [
                  Text('Available Professionals', style: AppTextStyles.h3),
                  const Spacer(),
                  Text(
                    '${visibleProviders.length} found',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverSectionListShimmer(itemCount: 5)
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final provider = visibleProviders[index];
                return GestureDetector(
                  onTap: () =>
                      context.push('/home-services/provider/${provider.id}'),
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
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: provider.categoryColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            provider.categoryIcon,
                            color: provider.categoryColor,
                            size: 30,
                          ),
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
                                    ),
                                  ),
                                  if (provider.isVerified)
                                    const Icon(
                                      Icons.verified_rounded,
                                      size: 18,
                                      color: AppColors.success,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.title,
                                style: AppTextStyles.caption,
                              ),
                              if (provider.services.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  provider.services.take(2).join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: provider.bookingModes
                                    .take(2)
                                    .map(
                                      (mode) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.homeServicesBg,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          mode,
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.homeServices,
                                              ),
                                        ),
                                      ),
                                    )
                                    .toList(),
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
                                      color: provider.categoryColor,
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
              }, childCount: visibleProviders.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
