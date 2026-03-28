import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class ShoppingOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? order;

  const ShoppingOrderDetailScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  State<ShoppingOrderDetailScreen> createState() =>
      _ShoppingOrderDetailScreenState();
}

class _ShoppingOrderDetailScreenState extends State<ShoppingOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _isLoading = widget.order == null;
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiClient.get('/orders/$userId', forceRefresh: true);
      final orders = response is List ? response : const [];
      final match = orders.cast<dynamic>().firstWhere(
        (entry) => (entry as Map)['id']?.toString() == widget.orderId,
        orElse: () => null,
      );
      if (!mounted) return;
      setState(() {
        if (match != null) {
          _order = {
            ...?_order,
            ...Map<String, dynamic>.from(match as Map),
          };
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _order ?? const <String, dynamic>{};
    final items = (data['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final firstItem = items.isNotEmpty ? items.first : null;
    final firstMetadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : <String, dynamic>{};
    final itemCount = items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
    final address =
        data['address']?.toString() ?? firstMetadata['address']?.toString();

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/shopping');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('shopping_tracking.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/shopping');
              }
            },
          ),
        ),
        body: _isLoading
            ? const DetailContentShimmer(
                accentColor: AppColors.shopping,
                showHero: false,
              )
            : _order == null
            ? const _MissingOrderState(moduleRoute: '/shopping')
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShoppingHero(
                      storeName: data['moduleName']?.toString() ?? l10n.t('shopping_tracking.default_title'),
                      status: _pretty(data['status']?.toString()),
                      itemCount: itemCount,
                      total: ((data['total'] as num?)?.toDouble() ?? 0),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.schedule_rounded,
                            label: l10n.t('tracking.placed'),
                            value: _formatDate(data['createdAt']?.toString()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoTile(
                            icon: Icons.local_shipping_outlined,
                            label: l10n.t('tracking.delivery'),
                            value:
                                data['deliveryEta']?.toString() ??
                                data['deliveryLabel']?.toString() ??
                                firstMetadata['deliveryEta']?.toString() ??
                                firstMetadata['deliveryLabel']?.toString() ??
                                l10n.t('checkout.standard'),
                          ),
                        ),
                      ],
                    ),
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: l10n.t('tracking.delivery_address'),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.shopping.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.shopping,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(address, style: AppTextStyles.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: l10n.t('tracking.order_items'),
                      child: Column(
                        children: items.isEmpty
                            ? [
                                _EmptyLine(
                                  title: l10n.t('tracking.no_items_title'),
                                  subtitle: l10n.t('tracking.shopping_empty_subtitle'),
                                ),
                              ]
                            : items
                                  .map(
                                    (item) => _ShoppingItemCard(
                                      name: item['name']?.toString() ?? 'Item',
                                      brand: item['brand']?.toString(),
                                      quantity:
                                          (item['quantity'] as num?)?.toInt() ?? 1,
                                      price:
                                          ((item['total'] as num?)?.toDouble() ??
                                                  (item['price'] as num?)?.toDouble() ??
                                                  0)
                                              .toStringAsFixed(2),
                                      variant: [
                                        if ((item['color']?.toString() ?? '').isNotEmpty)
                                          item['color'].toString(),
                                        if ((item['size']?.toString() ?? '').isNotEmpty)
                                          item['size'].toString(),
                                      ].join(' • '),
                                    ),
                                  )
                                  .toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ShoppingHero extends StatelessWidget {
  final String storeName;
  final String status;
  final int itemCount;
  final double total;

  const _ShoppingHero({
    required this.storeName,
    required this.status,
    required this.itemCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.shopping, AppColors.shopping.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              _StatusPill(
                label: status,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                textColor: AppColors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            storeName,
            style: AppTextStyles.h3.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).t(
              'shopping_tracking.ready_delivery',
              params: {
                'count': '$itemCount',
                'suffix': itemCount == 1 ? '' : 's',
              },
            ),
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context).t('tracking.total_paid'),
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: AppTextStyles.h4.copyWith(color: AppColors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.shopping.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.shopping, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  final String name;
  final String? brand;
  final int quantity;
  final String price;
  final String variant;

  const _ShoppingItemCard({
    required this.name,
    this.brand,
    required this.quantity,
    required this.price,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.shopping.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.shopping,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge),
                if (brand != null && brand!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    brand!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  [
                    'Qty $quantity',
                    if (variant.isNotEmpty) variant,
                  ].join(' • '),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('\$$price', style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: textColor),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyLine({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _MissingOrderState extends StatelessWidget {
  final String moduleRoute;

  const _MissingOrderState({required this.moduleRoute});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 42,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(l10n.t('shopping_tracking.missing_title'), style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(
              l10n.t('shopping_tracking.missing_subtitle'),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(moduleRoute),
              child: Text(l10n.t('shopping_tracking.back_to_shopping')),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return raw;
  return DateFormat('dd MMM yyyy • HH:mm').format(parsed);
}

String _pretty(String? raw) =>
    (raw == null || raw.isEmpty) ? 'Pending' : raw.replaceAll('_', ' ');
