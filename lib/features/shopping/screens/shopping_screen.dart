import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/module_screen_app_bar.dart';
import '../../../core/utils/money_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  String _lastTrackedSearch = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // The tab is the AliExpress storefront, so its first page loads up front.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<AliExpressProvider>();
      if (provider.feedProducts.isEmpty && !provider.isLoadingFeed) {
        provider.loadFeed(refresh: true);
      }
    });
  }

  /// Pulls the next feed page as the storefront nears its end.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 600) return;
    context.read<AliExpressProvider>().loadMoreFeed();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final normalizedQuery = value.trim().toLowerCase();
      if (normalizedQuery == _lastTrackedSearch) return;
      _lastTrackedSearch = normalizedQuery;
      if (normalizedQuery.isNotEmpty && normalizedQuery.length < 2) return;

      final aliExpress = context.read<AliExpressProvider>();
      if (normalizedQuery.isEmpty) {
        // Clearing the field drops back to the browse feed.
        aliExpress.resetSearch();
      } else {
        aliExpress.searchProducts(normalizedQuery);
      }

      AnalyticsService.instance.track(
        AnalyticsEvents.searchPerformed,
        properties: {
          'module': 'shopping',
          'query': normalizedQuery,
          'query_length': normalizedQuery.length,
          'source': 'aliexpress',
          'result_count': aliExpress.searchResults.length,
        },
      );
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartItemCount = context.watch<CartProvider>().getModuleItemCount(
      'shopping',
    );
    final aliExpressProvider = context.watch<AliExpressProvider>();
    final normalizedQuery = _searchQuery.trim().toLowerCase();

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
          title: l10n.t('shopping.title'),
          search: AppSearchBar(
            hint: l10n.t('shopping.search_hint'),
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.heart),
              onPressed: () {
                AnalyticsService.instance.track(
                  AnalyticsEvents.entityOpened,
                  properties: {
                    'module': 'shopping',
                    'entity_type': 'wishlist',
                    'entity_id': 'shopping_wishlist',
                    'source': 'shopping_screen',
                  },
                );
                context.push('/shopping/wishlist');
              },
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.shoppingBag),
                  onPressed: () {
                    AnalyticsService.instance.track(
                      AnalyticsEvents.viewCartTapped,
                      properties: {
                        'module': 'shopping',
                        'source': 'shopping_screen',
                        'cart_item_count': cartItemCount,
                      },
                    );
                    context.push('/shopping/cart');
                  },
                ),
                if (cartItemCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$cartItemCount',
                          style: AppTextStyles.badge.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Hero banner
            if (normalizedQuery.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Container(
                    height: 112,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.shoppingBg,
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/headers/header_ecommerce.png',
                        ),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('shopping.hero_title'),
                                style: AppTextStyles.h4,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.t('shopping.hero_subtitle'),
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (normalizedQuery.isEmpty)
              _buildAliExpressFilters(aliExpressProvider),
            ..._buildAliExpressContent(context, aliExpressProvider, l10n),
          ],
        ),
      ),
    );
  }
}

Widget _buildAliExpressFilters(AliExpressProvider provider) {
  return SliverToBoxAdapter(
    child: SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        itemCount: AliExpressProvider.browseCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = AliExpressProvider.browseCategories[index];
          final isSelected = provider.selectedCategoryId == category.id;
          return GestureDetector(
            onTap: () {
              provider.selectCategory(category.id);
              AnalyticsService.instance.track(
                AnalyticsEvents.filterApplied,
                properties: {
                  'module': 'shopping',
                  'filter_type': 'aliexpress_category',
                  'filter_value': category.id ?? 'all',
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: isSelected ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                category.label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected ? AppColors.white : AppColors.dark,
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// AliExpress tab slivers: keyword results while searching, otherwise the
/// browsable feed grid that keeps appending pages as the user scrolls.
List<Widget> _buildAliExpressContent(
  BuildContext context,
  AliExpressProvider provider,
  AppLocalizations l10n,
) {
  if (provider.lastQuery.isNotEmpty) {
    if (provider.isSearching && provider.searchResults.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (provider.searchError != null && provider.searchResults.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _AliExpressMessage(
            icon: LucideIcons.circleAlert,
            title: provider.searchError!,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        sliver: SliverList.builder(
          itemCount: provider.searchResults.length,
          itemBuilder: (context, index) {
            final product = provider.searchResults[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == provider.searchResults.length - 1 ? 0 : 14,
              ),
              child: _AliExpressProductCard(
                product: product,
                onTap: () {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.entityOpened,
                    properties: {
                      'module': 'shopping',
                      'entity_type': 'aliexpress_product',
                      'entity_id': product.id,
                      'position': index + 1,
                      'source': 'aliexpress_search',
                    },
                  );
                  context.push('/shopping/product/${product.id}');
                },
              ),
            );
          },
        ),
      ),
    ];
  }

  if (provider.isLoadingFeed && provider.feedProducts.isEmpty) {
    return const [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    ];
  }
  if (provider.feedError != null && provider.feedProducts.isEmpty) {
    return [
      SliverFillRemaining(
        hasScrollBody: false,
        child: _AliExpressMessage(
          icon: LucideIcons.circleAlert,
          title: provider.feedError!,
          actionLabel: 'Try again',
          onAction: () => provider.loadFeed(refresh: true),
        ),
      ),
    ];
  }
  if (provider.feedProducts.isEmpty) {
    return const [
      SliverFillRemaining(
        hasScrollBody: false,
        child: _AliExpressMessage(
          icon: LucideIcons.shoppingBag,
          title: 'No AliExpress products right now',
          subtitle: 'Pick another category or try again in a moment.',
        ),
      ),
    ];
  }

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 292,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = provider.feedProducts[index];
          return _AliExpressGridCard(
            product: product,
            onTap: () {
              AnalyticsService.instance.track(
                AnalyticsEvents.entityOpened,
                properties: {
                  'module': 'shopping',
                  'entity_type': 'aliexpress_product',
                  'entity_id': product.id,
                  'position': index + 1,
                  'category_id': provider.selectedCategoryId,
                  'source': 'aliexpress_feed',
                },
              );
              context.push('/shopping/product/${product.id}');
            },
          );
        }, childCount: provider.feedProducts.length),
      ),
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Center(
          child: provider.isLoadingFeed
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : provider.hasMoreFeed
              ? const SizedBox.shrink()
              : Text(
                  'You have reached the end of the results',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                ),
        ),
      ),
    ),
  ];
}

/// Compact 2-column card for the browse feed.
class _AliExpressGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _AliExpressGridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.images.isNotEmpty && product.images.first.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppSpacing.shadowSm,
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image stepped down to 14 so it nests inside the 18pt card.
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  color: AppColors.extraLightGrey,
                  child: hasImage
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            LucideIcons.shoppingBag,
                            color: AppColors.lightGrey,
                            size: 36,
                          ),
                        )
                      : const Icon(
                          LucideIcons.shoppingBag,
                          color: AppColors.lightGrey,
                          size: 36,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'DJF${money(product.price)}',
                        style: AppTextStyles.priceSmall,
                      ),
                      const Spacer(),
                      if (product.rating > 0) ...[
                        const Icon(
                          CupertinoIcons.star_fill,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
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

/// Centred empty/error state used by the AliExpress tab.
class _AliExpressMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AliExpressMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.lightGrey),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.grey),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              AppButton(
                text: actionLabel!,
                icon: LucideIcons.refreshCw,
                width: 180,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AliExpressProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const _AliExpressProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        product.images.isNotEmpty && product.images.first.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            // Product image — inset and stepped down to 14 so it nests inside
            // the 18pt card instead of mirroring it.
            Padding(
              padding: const EdgeInsets.all(6),
              child: Container(
                width: 100,
                height: 100,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.extraLightGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: hasImage
                    ? Image.network(
                        product.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          LucideIcons.shoppingBag,
                          color: AppColors.lightGrey,
                          size: 36,
                        ),
                      )
                    : const Icon(
                        LucideIcons.shoppingBag,
                        color: AppColors.lightGrey,
                        size: 36,
                      ),
              ),
            ),
            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (product.rating > 0) ...[
                          const Icon(
                            CupertinoIcons.star_fill,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: AppTextStyles.labelSmall,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          'DJF${money(product.price)}',
                          style: AppTextStyles.priceSmall,
                        ),
                        const Spacer(),
                        if (product.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              product.badge!,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accent,
                                fontSize: 9,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
