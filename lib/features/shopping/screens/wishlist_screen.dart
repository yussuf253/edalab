import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Map<String, dynamic>> _items = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final userId = context.read<AuthProvider>().user?.id;
    final localItems = context.read<WishlistProvider>().items;

    if (userId == null) {
      setState(() {
        _items = localItems
            .map(
              (item) => {
                'entityId': item.id,
                'title': item.name,
                'subtitle': item.brand,
                'price': item.price,
                'moduleType': 'SHOPPING',
              },
            )
            .toList();
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiClient.get('/users/$userId/wishlist');
      if (!mounted) return;
      setState(() {
        _items = (response as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(Map<String, dynamic> item) async {
    final userId = context.read<AuthProvider>().user?.id;
    setState(() {
      _items = _items
          .where((entry) => entry['entityId'] != item['entityId'])
          .toList();
    });

    if (userId != null) {
      try {
        await ApiClient.delete(
          '/users/$userId/wishlist/${item['entityId']}?moduleType=${item['moduleType']}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('wishlist.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const SimpleListShimmer(itemCount: 5, imageLeading: true)
          : _items.isEmpty
          ? Center(
              child: Text(
                l10n.t('wishlist.empty'),
                style: AppTextStyles.bodyMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _items[index];
                final moduleType = item['moduleType']?.toString() ?? 'SHOPPING';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.extraLightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_rounded,
                          color: AppColors.lightGrey,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title']?.toString() ?? '',
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['subtitle']?.toString() ?? moduleType,
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  item['price'] != null
                                      ? 'DJF${(item['price'] as num).toStringAsFixed(2)}'
                                      : l10n.t('wishlist.saved'),
                                  style: AppTextStyles.priceSmall,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    moduleType,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _removeItem(item),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.accent,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
