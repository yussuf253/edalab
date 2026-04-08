import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';

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
  bool _isLoading = true;

  late ProductModel _product;

  @override
  void initState() {
    super.initState();
    _product = ProductModel.sampleProducts.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => ProductModel.sampleProducts.first,
    );
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final response = await ApiClient.get(
        '/catalog/products/${widget.productId}',
      );
      if (!mounted) return;
      setState(() {
        _product = ProductModel.fromApi(
          Map<String, dynamic>.from(response as Map),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // Pre-defined UI colors mapping for mock products
  final _colorMap = {
    'Black': Colors.black,
    'White': Colors.white,
    'Blue': AppColors.primary,
    'Red': AppColors.error,
    'Dark Blue': Colors.indigo,
    'Light Blue': Colors.lightBlue,
    'Silver': Colors.grey.shade400,
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
    final isFavorite = wishlistProvider.isFavorite(_product.id);
    final cartItems = cartProvider.getModuleItems('shopping');
    final existingCartItem = cartItems.cast<CartItem?>().firstWhere(
      (item) => item?.id == _product.id,
      orElse: () => null,
    );
    final isInCart = existingCartItem != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.t('product_detail.title')),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavorite ? AppColors.accent : null,
            ),
            splashRadius: 24,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            padding: const EdgeInsets.all(12),
            onPressed: () {
              wishlistProvider.toggleFavorite(_product);
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
      body: SingleChildScrollView(
        child: _isLoading
            ? const _ProductDetailShimmer()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    height: 320,
                    width: double.infinity,
                    color: AppColors.extraLightGrey,
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            size: 100,
                            color: AppColors.shopping.withValues(alpha: 0.3),
                          ),
                        ),
                        if (_product.badge != null)
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
                                _product.badge!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Brand + Name
                        Text(
                          _product.brand,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_product.name, style: AppTextStyles.h2),
                        const SizedBox(height: 12),
                        // Rating + Reviews
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < _product.rating.floor()
                                    ? Icons.star_rounded
                                    : Icons.star_half_rounded,
                                size: 18,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _product.rating.toString(),
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.t(
                                'product_detail.reviews',
                                params: {
                                  'count': _product.reviewCount.toString(),
                                },
                              ),
                              style: AppTextStyles.caption,
                            ),
                            const Spacer(),
                            if (_product.inStock)
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
                              '\$${_product.price}',
                              style: AppTextStyles.price.copyWith(fontSize: 28),
                            ),
                            const SizedBox(width: 8),
                            if (_product.originalPrice != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '\$${_product.originalPrice}',
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
                                  '-${_product.discountPercent.toInt()}%',
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
                        if (_product.colors.isNotEmpty) ...[
                          Text(
                            l10n.t('product_detail.color'),
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(_product.colors.length, (
                              i,
                            ) {
                              final colorName = _product.colors[i];
                              final uicolor =
                                  _colorMap[colorName] ?? AppColors.primary;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedColor = i),
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
                                              uicolor == Colors.grey.shade400)
                                      ? const Icon(
                                          Icons.check,
                                          color: AppColors.dark,
                                          size: 18,
                                        )
                                      : _selectedColor == i
                                      ? const Icon(
                                          Icons.check,
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
                        if (_product.sizes.isNotEmpty) ...[
                          Text(
                            l10n.t('product_detail.size'),
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(_product.sizes.length, (i) {
                              final isSelected = _selectedSize == i;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedSize = i),
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
                                    _product.sizes[i],
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
                                    icon: const Icon(Icons.remove, size: 18),
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
                                    icon: const Icon(Icons.add, size: 18),
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
                          _product.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Features
                        if (_product.features.isNotEmpty) ...[
                          Text(
                            l10n.t('product_detail.features'),
                            style: AppTextStyles.h4,
                          ),
                          const SizedBox(height: 12),
                          ..._product.features.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
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
      bottomSheet: Container(
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
                      '\$${(_product.price * _quantity).toStringAsFixed(2)}',
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
                      ? Icons.arrow_forward_rounded
                      : Icons.shopping_bag_outlined,
                  width: 220,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () {
                    if (isInCart) {
                      context.push('/shopping/cart');
                      return;
                    }

                    final cartItem = CartItem(
                      id: _product.id,
                      name: _product.name,
                      brand: _product.brand.trim().isNotEmpty
                          ? _product.brand
                          : _product.shopName,
                      price: _product.price,
                      quantity: _quantity,
                      moduleType: 'shopping',
                      imageUrl: _product.images.isNotEmpty
                          ? _product.images.first
                          : null,
                      description: _product.description,
                      shopId: _product.shopId,
                      shopName: _product.shopName,
                      color: _product.colors.isNotEmpty
                          ? _product.colors[_selectedColor]
                          : null,
                      size: _product.sizes.isNotEmpty
                          ? _product.sizes[_selectedSize]
                          : null,
                    );

                    cartProvider.addItem(cartItem);
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

class _ProductDetailShimmer extends StatelessWidget {
  const _ProductDetailShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
