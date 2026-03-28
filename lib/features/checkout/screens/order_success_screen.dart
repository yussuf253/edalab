import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? orderData;
  const OrderSuccessScreen({super.key, this.orderData});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rawOrderId = orderData?['orderId'] as String? ?? 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final orderId = rawOrderId.startsWith('#') ? rawOrderId : '#$rawOrderId';
    final amount = (orderData?['amount'] as num?)?.toDouble() ?? 87.19;
    final payment = orderData?['payment'] as String? ?? 'Credit Card';
    final delivery = orderData?['delivery'] as String? ?? 'Standard';
    final moduleName = orderData?['moduleName'] as String? ?? 'Order';
    final itemCount = orderData?['itemCount'] as int? ?? 0;
    final address = orderData?['address'] as String?;
    final trackingRoute = orderData?['trackingRoute'] as String? ?? '/orders';
    final trackingExtra = orderData?['trackingExtra'];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Success animation placeholder
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.success, Color(0xFF55EFC4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, color: AppColors.white, size: 60),
                ),
                const SizedBox(height: 32),
                Text(l10n.t('order_success.title'), style: AppTextStyles.h2),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l10n.t(
                      'order_success.subtitle',
                      params: {'moduleName': moduleName},
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                // Order info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(l10n.t('order_success.order_id'), orderId),
                      _InfoRow(l10n.t('order_success.module'), moduleName),
                      _InfoRow(
                        l10n.t('order_success.items'),
                        itemCount > 0
                            ? l10n.t(
                                'order_success.items_count',
                                params: {
                                  'count': '$itemCount',
                                  'suffix': itemCount == 1 ? '' : 's',
                                },
                              )
                            : l10n.t('common.ready'),
                      ),
                      _InfoRow(
                        l10n.t('order_success.amount'),
                        '\$${amount.toStringAsFixed(2)}',
                      ),
                      _InfoRow(l10n.t('order_success.payment'), payment),
                      _InfoRow(l10n.t('order_success.delivery'), delivery),
                      if (address != null && address.isNotEmpty)
                        _InfoRow(l10n.t('order_success.address'), address),
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(
                  text: l10n.t('order_success.track_order'),
                  onPressed: () => context.push(trackingRoute, extra: trackingExtra),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text(
                    l10n.t('order_success.back_home'),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
          Text(value, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
