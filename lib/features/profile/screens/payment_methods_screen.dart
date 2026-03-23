import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _Card('Visa', '•••• •••• •••• 4242', '12/28', AppColors.primary, true),
      _Card('Mastercard', '•••• •••• •••• 8523', '06/27', AppColors.food, false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credit/Debit Cards
            Text('Cards', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...cards.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c.color, c.color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c.type, style: AppTextStyles.h4.copyWith(color: AppColors.white)),
                      if (c.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: Text('Default', style: AppTextStyles.badge.copyWith(fontSize: 9)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(c.number, style: AppTextStyles.h3.copyWith(color: AppColors.white, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EXPIRES', style: AppTextStyles.caption.copyWith(color: Colors.white60, fontSize: 9)),
                          Text(c.expiry, style: AppTextStyles.labelMedium.copyWith(color: AppColors.white)),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CARDHOLDER', style: AppTextStyles.caption.copyWith(color: Colors.white60, fontSize: 9)),
                          Text('JOHN DOE', style: AppTextStyles.labelMedium.copyWith(color: AppColors.white)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )),
            const SizedBox(height: 10),

            // Other payment methods
            Text('Other Methods', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...[
              ('Apple Pay', 'Connected', Icons.phone_iphone_rounded, AppColors.dark),
              ('Google Pay', 'Connected', Icons.g_mobiledata_rounded, AppColors.primary),
              ('PayPal', 'john.doe@paypal.com', Icons.account_balance_wallet_rounded, AppColors.secondary),
            ].map((p) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppSpacing.shadowSm),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: p.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(p.$3, color: p.$4, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.$1, style: AppTextStyles.labelMedium),
                        Text(p.$2, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.mediumGrey),
                ],
              ),
            )),

            const SizedBox(height: 20),
            // Add new card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text('Add New Card', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card {
  final String type, number, expiry;
  final Color color;
  final bool isDefault;
  _Card(this.type, this.number, this.expiry, this.color, this.isDefault);
}
