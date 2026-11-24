import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/money_format.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedColor = 0;
  int _selectedSize = 0;
  int _quantity = 1;
  int _imageIndex = 0;
  bool _isLoading = true;
  bool _hasTrackedView = false;

  ProductModel? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final product = await _fetchProduct();
    if (!mounted) return;
    setState(() {
      _product = product;
      _isLoading = false;
    });
    _trackProductViewed(source: product == null ? 'error' : 'remote');
  }

  /// Catalogue products (shopping, pharmacy, grocery) live in Supabase, while
  /// the AliExpress tab opens items that only the AliExpress proxy knows about,
  /// so fall back to it when the catalogue lookup misses.
  Future<ProductModel?> _fetchProduct() async {
    for (final path in <String>[
      '/catalog/products/${widget.productId}',
      '/aliexpress/products/${widget.productId}',
    ]) {
      try {
        final response = await ApiClient.get(path);
        if (response is Map) {
          return ProductModel.fromApi(Map<String, dynamic>.from(response));
        }
      } catch (_) {
        // Try the next source.
      }
    }
    return null;
  }

  void _trackProductViewed({required String source}) {
    if (_hasTrackedView) return;
    _hasTrackedView = true;
    AnalyticsService.instance.track(
      AnalyticsEvents.entityOpened,
      properties: {
        'module': 'shopping',
        'entity_type': 'product',
        'entity_id': _product?.id ?? widget.productId,
        'source': source,
        'price': _product?.price,
        'brand': _product?.brand,
        'in_stock': _product?.inStock,
      },
    );
  }

  // Pre-defined UI colors mapping for mock products
  final _colorMap = {
    'Black': Colors.black,
    'White': Colors.white,
    'Blue': AppColors.primary,
    'Red': AppColors.error,
    'Dark Blue': Colors.indigo,
    'Light Blue': Colors.lightBlue,
    'Silver': AppColors.mediumGrey,
    'Rose Gold': Colors.pink.shade200,
    'Gold/Green': Colors.amber,
    'Silver/Blue': Colors.blueGrey,
    'Black/Gray': Colors.black87,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final wishlistProvider = context.watch<WishlistProvider>();
    final product = _product;
    final isFavorite =
        product != null && wishlistProvider.isFavorite(product.id);
    final cartItems = cartProvider.getModuleItems('shopping');
    final existingCartItem = cartItems.cast<CartItem?>().firstWhere(
      (item) => item?.id == product?.id,
      orElse: () => null,
    );
    final isInCart = existingCartItem != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.t('product_detail.title')),
        actions: [
          if (product != null)
            IconButton(
              icon: Icon(
                isFavorite ? CupertinoIcons.heart_fill : LucideIcons.heart,
                color: isFavorite ? AppColors.accent : null,
              ),
              splashRadius: 24,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: const EdgeInsets.all(12),
              onPressed: () {
                wishlistProvider.toggleFavorite(product);
                AnalyticsService.instance.track(
                  AnalyticsEvents.wishlistToggled,
                  properties: {
                    'module': 'shopping',
                    'entity_type': 'product',
                    'entity_id': product.id,
                    'is_favorite': !isFavorite,
                    'source': 'product_detail',
                  },
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isFavorite
                          ? l10n.t('product_detail.removed_wishlist')
                          : l10n.t('product_detail.added_wishlist'),
                    ),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const _ProductDetailShimmer()
          : product == null
          ? _ProductUnavailable(onRetry: _loadProduct)
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product gallery — swipe between images, tap to zoom.
                  _ProductGallery(
                    images: product.images,
                    badge: product.badge,
                    index: _imageIndex,
                    onIndexChanged: (index) =>
                        setState(() => _imageIndex = index),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand + Name
                        Text(
                          product.brand,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(product.name, style: AppTextStyles.h2),
                        const SizedBox(height: 12),
                        // Rating + Reviews
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < product.rating.floor()
                                    ? CupertinoIcons.star_fill
                                    : CupertinoIcons.star_lefthalf_fill,
                                size: 18,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.rating.toString(),
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.t(
                                'product_detail.reviews',
                                params: {
                                  'count': product.reviewCount.toString(),
                                },
                              ),
                              style: AppTextStyles.caption,
                            ),
                            const Spacer(),
                            if (product.inStock)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n.t('product_detail.in_stock'),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'DJF${product.price}',
                              style: AppTextStyles.price.copyWith(fontSize: 28),
                            ),
                            const SizedBox(width: 8),
                            if (product.originalPrice != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'DJF${product.originalPrice}',
                                  style: AppTextStyles.priceOld.copyWith(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${product.discountPercent.toInt()}%',
                                  style: AppTextStyles.badge,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Color selection
                        if (product.colors.isNotEmpty) ...[
                          Text(
                            l10n.t('product_detail.color'),
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(product.colors.length, (i) {
                              final colorName = product.colors[i];
                              final uicolor =
                                  _colorMap[colorName] ?? AppColors.primary;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedColor = i);
                                  AnalyticsService.instance.track(
                                    AnalyticsEvents.filterApplied,
                                    properties: {
                                      'module': 'shopping',
                                      'filter_type': 'color',
                                      'filter_value': colorName,
                                      'entity_id': product.id,
                                    },
                                  );
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: uicolor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedColor == i
                                          ? AppColors.primary
                                          : AppColors.lightGrey,
                                      width: _selectedColor == i ? 3 : 1,
                                    ),
                                    boxShadow: AppSpacing.shadowSm,
                                  ),
                                  child:
                                      _selectedColor == i &&
                                          (uicolor == Colors.white ||
                                              uicolor == AppColors.mediumGrey)
                                      ? const Icon(
                                          LucideIcons.check,
                                          color: AppColors.dark,
                                          size: 18,
                                        )
                                      : _selectedColor == i
                                      ? const Icon(
                                          LucideIcons.check,
                                          color: AppColors.white,
                                          size: 18,
                                        )
                                      : null,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Size selection
                        if (product.sizes.isNotEmpty) ...[
                          Text(
                            l10n.t('product_detail.size'),
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(product.sizes.length, (i) {
                              final isSelected = _selectedSize == i;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedSize = i);
                                  AnalyticsService.instance.track(
                                    AnalyticsEvents.filterApplied,
                                    properties: {
                                      'module': 'shopping',
                                      'filter_type': 'size',
                                      'filter_value': product.sizes[i],
                                      'entity_id': product.id,
                                    },
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.extraLightGrey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    product.sizes[i],
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: isSelected
                                          ? AppColors.white
                                          : AppColors.dark,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Quantity
                        Row(
                          children: [
                            Text(
                              l10n.t('product_detail.quantity'),
                              style: AppTextStyles.labelLarge,
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.extraLightGrey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.minus,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      if (_quantity > 1) {
                                        setState(() => _quantity--);
                                      }
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      style: AppTextStyles.labelLarge,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.plus,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _quantity++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          l10n.t('product_detail.description'),
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Features
                        if (product.features.isNotEmpty) ...[
                          Text(
                            l10n.t('product_detail.features'),
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 12),
                          ...product.features.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.checkCircle,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomSheet: product == null
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
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
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('product_detail.total_price'),
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'DJF${money(product.price * _quantity)}',
                            style: AppTextStyles.price,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      fit: FlexFit.loose,
                      child: AppButton(
                        text: isInCart
                            ? l10n.t('product_detail.view_cart')
                            : l10n.t('product_detail.add_to_cart'),
                        icon: isInCart
                            ? LucideIcons.arrowRight
                            : LucideIcons.shoppingBag,
                        width: 220,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        onPressed: () {
                          if (isInCart) {
                            AnalyticsService.instance.track(
                              AnalyticsEvents.viewCartTapped,
                              properties: {
                                'module': 'shopping',
                                'source': 'product_detail',
                                'entity_id': product.id,
                                'cart_item_count': cartProvider
                                    .getModuleItemCount('shopping'),
                              },
                            );
                            context.push('/shopping/cart');
                            return;
                          }

                          final cartItem = CartItem(
                            id: product.id,
                            name: product.name,
                            brand: product.brand.trim().isNotEmpty
                                ? product.brand
                                : product.shopName,
                            price: product.price,
                            quantity: _quantity,
                            moduleType: 'shopping',
                            imageUrl: product.images.isNotEmpty
                                ? product.images.first
                                : null,
                            description: product.description,
                            shopId: product.shopId,
                            shopName: product.shopName,
                            color: product.colors.isNotEmpty
                                ? product.colors[_selectedColor]
                                : null,
                            size: product.sizes.isNotEmpty
                                ? product.sizes[_selectedSize]
                                : null,
                          );

                          cartProvider.addItem(cartItem);
                          AnalyticsService.instance.track(
                            AnalyticsEvents.checkoutEntryTapped,
                            properties: {
                              'module': 'shopping',
                              'source': 'product_detail',
                              'entity_type': 'product',
                              'entity_id': product.id,
                              'quantity': _quantity,
                              'unit_price': product.price,
                              'line_total': product.price * _quantity,
                              'selected_color': product.colors.isNotEmpty
                                  ? product.colors[_selectedColor]
                                  : null,
                              'selected_size': product.sizes.isNotEmpty
                                  ? product.sizes[_selectedSize]
                                  : null,
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ProductUnavailable extends StatelessWidget {
  final VoidCallback onRetry;
  const _ProductUnavailable({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.extraLightGrey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                LucideIcons.shoppingBag,
                color: AppColors.grey,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.t('product_detail.unavailable_title'),
              style: AppTextStyles.h4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('product_detail.unavailable_subtitle'),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppButton(
              text: l10n.t('product_detail.retry'),
              icon: LucideIcons.refreshCw,
              width: 180,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailShimmer extends StatelessWidget {
  const _ProductDetailShimmer();

  @override
  Widget build(BuildContext context) {
    // Scrollable so the placeholder never overflows short viewports while the
    // real content is still loading.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 320,
            width: double.infinity,
            color: AppColors.extraLightGrey,
            child: const Center(
              child: AppShimmer(
                child: ShimmerBlock(width: 100, height: 100, radius: 28),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBlock(width: 84, height: 12, radius: 10),
                  SizedBox(height: 8),
                  ShimmerBlock(width: 220, height: 28),
                  SizedBox(height: 14),
                  Row(
                    children: [
                      ShimmerBlock(width: 116, height: 18, radius: 10),
                      Spacer(),
                      ShimmerBlock(width: 78, height: 24, radius: 8),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerBlock(width: 96, height: 30),
                      SizedBox(width: 8),
                      ShimmerBlock(width: 62, height: 18, radius: 10),
                      SizedBox(width: 8),
                      ShimmerBlock(width: 46, height: 22, radius: 8),
                    ],
                  ),
                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 20),
                  ShimmerBlock(width: 68, height: 18, radius: 10),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerBlock(width: 36, height: 36, radius: 999),
                      SizedBox(width: 12),
                      ShimmerBlock(width: 36, height: 36, radius: 999),
                      SizedBox(width: 12),
                      ShimmerBlock(width: 36, height: 36, radius: 999),
                    ],
                  ),
                  SizedBox(height: 20),
                  ShimmerBlock(width: 56, height: 18, radius: 10),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ShimmerBlock(width: 56, height: 44, radius: 12),
                      ShimmerBlock(width: 64, height: 44, radius: 12),
                      ShimmerBlock(width: 60, height: 44, radius: 12),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      ShimmerBlock(width: 74, height: 18, radius: 10),
                      Spacer(),
                      ShimmerBlock(width: 122, height: 44, radius: 12),
                    ],
                  ),
                  SizedBox(height: 24),
                  ShimmerBlock(width: 102, height: 20),
                  SizedBox(height: 10),
                  ShimmerBlock(width: double.infinity, height: 14, radius: 10),
                  SizedBox(height: 8),
                  ShimmerBlock(width: double.infinity, height: 14, radius: 10),
                  SizedBox(height: 8),
                  ShimmerBlock(width: 220, height: 14, radius: 10),
                  SizedBox(height: 24),
                  ShimmerBlock(width: 82, height: 20),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerBlock(width: 20, height: 20, radius: 999),
                      SizedBox(width: 10),
                      Expanded(
                        child: ShimmerBlock(
                          width: double.infinity,
                          height: 14,
                          radius: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ShimmerBlock(width: 20, height: 20, radius: 999),
                      SizedBox(width: 10),
                      Expanded(
                        child: ShimmerBlock(
                          width: double.infinity,
                          height: 14,
                          radius: 10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      ShimmerBlock(width: 20, height: 20, radius: 999),
                      SizedBox(width: 10),
                      Expanded(
                        child: ShimmerBlock(width: 180, height: 14, radius: 10),
                      ),
                    ],
                  ),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero area of the product page: paged images, badge, dots, tap to open the
/// full-screen pinch-to-zoom viewer.
class _ProductGallery extends StatelessWidget {
  final List<String> images;
  final String? badge;
  final int index;
  final ValueChanged<int> onIndexChanged;

  const _ProductGallery({
    required this.images,
    required this.badge,
    required this.index,
    required this.onIndexChanged,
  });

  void _openViewer(BuildContext context, int startIndex) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            _ProductImageViewer(images: images, initialIndex: startIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = images.isNotEmpty;
    final current = index.clamp(0, hasImages ? images.length - 1 : 0);

    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        children: [
          if (hasImages)
            PageView.builder(
              itemCount: images.length,
              onPageChanged: onIndexChanged,
              itemBuilder: (context, pageIndex) => GestureDetector(
                onTap: () => _openViewer(context, pageIndex),
                child: Container(
                  color: AppColors.extraLightGrey,
                  child: Image.network(
                    images[pageIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(
                        LucideIcons.shoppingBag,
                        size: 100,
                        color: AppColors.shopping.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Icon(
                LucideIcons.shoppingBag,
                size: 100,
                color: AppColors.shopping.withValues(alpha: 0.3),
              ),
            ),
          if (badge != null)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          if (hasImages && images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length.clamp(1, 5),
                  (dotIndex) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotIndex == current
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.5),
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

/// Full-screen image viewer: swipe between images, pinch or double-tap to zoom.
class _ProductImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _ProductImageViewer({required this.images, required this.initialIndex});

  @override
  State<_ProductImageViewer> createState() => _ProductImageViewerState();
}

class _ProductImageViewerState extends State<_ProductImageViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;
  /// Shared across pages so paging can be locked while any image is zoomed.
  final ValueNotifier<bool> _zoomed = ValueNotifier(false);

  @override
  void dispose() {
    _controller.dispose();
    _zoomed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _zoomed,
              builder: (context, zoomed, _) => PageView.builder(
                controller: _controller,
                // While an image is zoomed in, paging is locked so one-finger
                // drags pan the zoomed image instead of flipping pages.
                physics: zoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.images.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (context, pageIndex) =>
                    _ZoomableImage(url: widget.images[pageIndex], zoomed: _zoomed),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                icon: const Icon(LucideIcons.x, color: AppColors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.images.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.images.length}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pinch-to-zoom image that only takes over dragging once it is zoomed in, so
/// horizontal swipes still page between images at normal scale.
class _ZoomableImage extends StatefulWidget {
  final String url;
  final ValueNotifier<bool> zoomed;

  const _ZoomableImage({required this.url, required this.zoomed});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
      widget.zoomed.value = zoomed;
    }
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transform,
      minScale: 1,
      maxScale: 4,
      panEnabled: _zoomed,
      child: Center(
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(
            LucideIcons.shoppingBag,
            size: 64,
            color: AppColors.grey,
          ),
        ),
      ),
    );
  }
}
