import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class FoodOrderTrackingScreen extends StatelessWidget {
  final String orderId;
  const FoodOrderTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final displayOrderId = orderId.startsWith('#') ? orderId : '#$orderId';
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/food');
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/food');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Estimated Time
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.food, AppColors.secondaryLight],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.delivery_dining_rounded, color: AppColors.white, size: 48),
                  const SizedBox(height: 12),
                  Text('Estimated Delivery', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('15-20 minutes', style: AppTextStyles.h2.copyWith(color: AppColors.white)),
                  const SizedBox(height: 8),
                  Text(displayOrderId, style: AppTextStyles.labelMedium.copyWith(color: AppColors.white)),
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
                  _TimelineStep('Order Confirmed', '10:30 AM', true, true),
                  _TimelineStep('Preparing', '10:32 AM', true, true),
                  _TimelineStep('On the way', '10:45 AM', true, false),
                  _TimelineStep('Delivered', '', false, false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Rider info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ahmed K.', style: AppTextStyles.labelLarge),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text('4.9 • Your rider', style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.phone_rounded, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Order details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Details', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 12),
                  _OrderRow('1x Classic Cheese Burger', '\$12.99'),
                  _OrderRow('1x BBQ Bacon Burger', '\$15.99'),
                  const Divider(height: 20),
                  _OrderRow('Total', '\$32.48', bold: true),
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

class _TimelineStep extends StatelessWidget {
  final String title, time;
  final bool isDone, isActive;

  const _TimelineStep(this.title, this.time, this.isDone, this.isActive);

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
                color: isDone ? AppColors.success : (isActive ? AppColors.food : AppColors.extraLightGrey),
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: AppColors.white, size: 16)
                  : isActive
                      ? const Icon(Icons.delivery_dining_rounded, color: AppColors.white, size: 16)
                      : null,
            ),
            if (title != 'Delivered')
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

class _OrderRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _OrderRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium),
          Text(value, style: bold ? AppTextStyles.priceSmall : AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
