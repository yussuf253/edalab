import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      _FAQ('How do I place an order?', 'Simply browse through the available services, select the items or service you want, add them to your cart, and proceed to checkout. You can pay using any of our available payment methods.'),
      _FAQ('How can I track my order?', 'You can track your order in real-time from the Orders tab. Tap on any active order to see its current status, estimated delivery time, and rider information.'),
      _FAQ('What payment methods are accepted?', 'We accept Credit/Debit cards, Apple Pay, Google Pay, PayPal, and Cash on Delivery. You can manage your payment methods from your Profile settings.'),
      _FAQ('How do I cancel an order?', 'You can cancel an order within 5 minutes of placing it. Go to Orders tab, select the order, and tap "Cancel Order". After 5 minutes, contact support for assistance.'),
      _FAQ('How do refunds work?', 'Refunds are processed within 5-7 business days after cancellation approval. The amount will be credited back to your original payment method.'),
      _FAQ('How do I earn and use reward points?', 'Earn points with every order across all services. Points can be redeemed for discounts on future orders. Check the Rewards section in your profile for details.'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Help Center'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search help
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppColors.mediumGrey),
                  const SizedBox(width: 10),
                  Text('Search for help...', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGrey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick help
            Text('Quick Help', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Row(
              children: [
                _HelpCard(Icons.chat_bubble_rounded, 'Live Chat', AppColors.primary),
                const SizedBox(width: 12),
                _HelpCard(Icons.email_rounded, 'Email Us', AppColors.secondary),
                const SizedBox(width: 12),
                _HelpCard(Icons.phone_rounded, 'Call Us', AppColors.success),
              ],
            ),
            const SizedBox(height: 24),

            // FAQs
            Text('Frequently Asked Questions', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...faqs.map((f) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: Text(f.question, style: AppTextStyles.labelMedium),
                children: [
                  Text(f.answer, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey, height: 1.6)),
                ],
              ),
            )),
            const SizedBox(height: 20),

            // Contact info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(height: 12),
                  Text('Still need help?', style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text('Our support team is available 24/7', style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                    child: Text('Contact Support', style: AppTextStyles.badge.copyWith(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HelpCard(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _FAQ {
  final String question, answer;
  _FAQ(this.question, this.answer);
}
