import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils/money_format.dart';

class PaymentFailureScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentData;
  const PaymentFailureScreen({super.key, this.paymentData});
  @override
  State<PaymentFailureScreen> createState() => _PaymentFailureScreenState();
}

class _PaymentFailureScreenState extends State<PaymentFailureScreen> {
  bool _hasTrackedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasTrackedView) return;
      _hasTrackedView = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orderId = widget.paymentData?['orderId'] as String? ?? '';
    final amount = (widget.paymentData?['amount'] as num?)?.toDouble() ?? 0.0;
    final moduleName = widget.paymentData?['moduleName'] as String? ?? 'Order';
    // The backend may send a `status` (e.g., FAILED, PENDING) and a human‑readable
    // `message`. Prefer the explicit message; fall back to a generic error.
    final errorMessage =
        widget.paymentData?['message'] as String? ??
        l10n.t('payment_failure.default_error');
    final status = widget.paymentData?['status'] as String? ?? 'FAILED';

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
                // Failure animation placeholder
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.error,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 32),
                Text(l10n.t('payment_failure.title'), style: AppTextStyles.h2),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    l10n.t(
                      'payment_failure.subtitle',
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
                // Error message
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Show the status (e.g., FAILED, PENDING) as part of the error title
                      Text(
                        '${l10n.t('payment_failure.error_title')} ($status)',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.dark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Payment info
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(l10n.t('payment_failure.order_id'), '#$orderId'),
                      _InfoRow(l10n.t('payment_failure.module'), moduleName),
                      _InfoRow(
                        l10n.t('payment_failure.amount'),
                        'DJF ${money(amount)}',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                AppButton(
                  text: l10n.t('payment_failure.retry_payment'),
                  onPressed: () {
                    context.go('/cart');
                  },
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    context.go('/');
                  },
                  child: Text(
                    l10n.t('payment_failure.back_home'),
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
