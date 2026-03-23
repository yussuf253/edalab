import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? orderData;
  const OrderSuccessScreen({super.key, this.orderData});

  @override
  Widget build(BuildContext context) {
    final rawOrderId = orderData?['orderId'] as String? ?? 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final orderId = rawOrderId.startsWith('#') ? rawOrderId : '#$rawOrderId';
    final amount = (orderData?['amount'] as num?)?.toDouble() ?? 87.19;
    final payment = orderData?['payment'] as String? ?? 'Credit Card';
    final delivery = orderData?['delivery'] as String? ?? 'Standard';
    final moduleName = orderData?['moduleName'] as String? ?? 'Order';
    final itemCount = orderData?['itemCount'] as int? ?? 0;
    final address = orderData?['address'] as String?;
    final trackingRoute = orderData?['trackingRoute'] as String? ?? '/orders';

    return Scaffold(
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
              Text('Order Placed! 🎉', style: AppTextStyles.h2),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Your $moduleName is confirmed and already moving through the next step. We will keep you updated along the way.',
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
                    _InfoRow('Order ID', orderId),
                    _InfoRow('Module', moduleName),
                    _InfoRow('Items', itemCount > 0 ? '$itemCount item${itemCount == 1 ? '' : 's'}' : 'Ready'),
                    _InfoRow('Amount', '\$${amount.toStringAsFixed(2)}'),
                    _InfoRow('Payment', payment),
                    _InfoRow('Delivery', delivery),
                    if (address != null && address.isNotEmpty) _InfoRow('Address', address),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                text: 'Track Order',
                onPressed: () => context.go(trackingRoute),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text('Back to Home', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
              ),
            ],
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
