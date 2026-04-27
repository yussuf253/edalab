import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_button.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  const OrderSuccessScreen({super.key, this.orderData});
  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  static const _shellRoutes = {
    '/',
    '/messages',
    '/cart',
    '/orders',
    '/profile',
  };

  bool _hasTrackedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasTrackedView) return;
      AnalyticsService.instance.track(
        AnalyticsEvents.orderSuccessViewed,
        properties: _analyticsProperties(),
      );
      _hasTrackedView = true;
    });
  }

  Map<String, Object?> _analyticsProperties() {
    final amount = (widget.orderData?['amount'] as num?)?.toDouble();
    return {
      'order_id': widget.orderData?['orderId']?.toString(),
      'module_name': widget.orderData?['moduleName']?.toString(),
      'item_count': (widget.orderData?['itemCount'] as int?) ?? 0,
      'amount': amount,
      'tracking_route':
          widget.orderData?['trackingRoute']?.toString() ?? '/orders',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rawOrderId =
        widget.orderData?['orderId'] as String? ??
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final orderId = rawOrderId.startsWith('#') ? rawOrderId : '#$rawOrderId';
    final amount = (widget.orderData?['amount'] as num?)?.toDouble() ?? 87.19;
    final payment = widget.orderData?['payment'] as String? ?? 'Credit Card';
    final delivery = widget.orderData?['delivery'] as String? ?? 'Standard';
    final moduleName = widget.orderData?['moduleName'] as String? ?? 'Order';
    final itemCount = widget.orderData?['itemCount'] as int? ?? 0;
    final address = widget.orderData?['address'] as String?;
    final trackingRoute =
        widget.orderData?['trackingRoute'] as String? ?? '/orders';
    final trackingExtra = widget.orderData?['trackingExtra'];

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
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.white,
                    size: 60,
                  ),
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                      height: 1.5,
                    ),
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
                        'DJF${amount.toStringAsFixed(2)}',
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
                  onPressed: () {
                    AnalyticsService.instance.track(
                      AnalyticsEvents.orderSuccessTrackTapped,
                      properties: _analyticsProperties(),
                    );
                    if (_shellRoutes.contains(trackingRoute)) {
                      context.go(trackingRoute);
                    } else {
                      context.push(trackingRoute, extra: trackingExtra);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    AnalyticsService.instance.track(
                      AnalyticsEvents.orderSuccessBackHomeTapped,
                      properties: _analyticsProperties(),
                    );
                    context.go('/');
                  },
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
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          Text(value, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
