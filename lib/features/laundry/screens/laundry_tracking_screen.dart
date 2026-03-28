import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';

class LaundryTrackingScreen extends StatelessWidget {
  final String orderId;
  const LaundryTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/laundry');
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('tracking.order_tracking')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/laundry');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.laundry, AppColors.secondaryLight],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.local_laundry_service_rounded, color: AppColors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(l10n.t('laundry_tracking.status'), style: AppTextStyles.h3.copyWith(color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text(l10n.t('laundry_tracking.eta'), style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Timeline
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Column(
                children: [
                  _Step(l10n.t('laundry_tracking.pickup_confirmed'), '10:00 AM', true, true),
                  _Step(l10n.t('laundry_tracking.picked_up'), '10:30 AM', true, true),
                  _Step(l10n.t('laundry_tracking.cleaning'), '11:00 AM', true, false),
                  _Step(l10n.t('laundry_tracking.ready_for_delivery'), '', false, false),
                  _Step(l10n.t('laundry_tracking.delivered'), '', false, false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Order details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('laundry_tracking.order_details'), style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  _DetailRow(l10n.t('laundry_tracking.order_number'), '1234'),
                  _DetailRow(l10n.t('laundry_tracking.service'), 'Wash & Fold'),
                  _DetailRow(l10n.t('laundry_tracking.items'), '6 items (3 Shirts, 2 Pants, 1 Dress)'),
                  _DetailRow(l10n.t('laundry_tracking.pickup'), 'Tue, Mar 23, 10:30 AM'),
                  _DetailRow(l10n.t('tracking.delivery'), 'Wed, Mar 24, 6:00 PM'),
                  const Divider(height: 20),
                  _DetailRow(l10n.t('laundry_tracking.total'), '\$30.00', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Support
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: AppColors.laundryBg, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.headset_mic_rounded, color: AppColors.laundry),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.t('laundry_tracking.need_help'), style: AppTextStyles.labelMedium),
                        Text(l10n.t('laundry_tracking.support'), style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.laundry, borderRadius: BorderRadius.circular(10)),
                    child: Text(l10n.t('laundry_tracking.contact'), style: AppTextStyles.badge.copyWith(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String title, time;
  final bool isDone, isActive;
  const _Step(this.title, this.time, this.isDone, this.isActive);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: isDone ? AppColors.success : (isActive ? AppColors.laundry : AppColors.extraLightGrey),
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: AppColors.white, size: 16)
                  : isActive
                      ? const Icon(Icons.local_laundry_service_rounded, color: AppColors.white, size: 14)
                      : null,
            ),
            if (title != AppLocalizations.of(context).t('laundry_tracking.delivered'))
              Container(width: 2, height: 32, color: isDone ? AppColors.success : AppColors.extraLightGrey),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.labelMedium.copyWith(
                  color: isDone || isActive ? AppColors.dark : AppColors.mediumGrey,
                )),
                if (time.isNotEmpty) Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _DetailRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, style: bold ? AppTextStyles.priceSmall.copyWith(color: AppColors.laundry) : AppTextStyles.labelMedium, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
