import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final uri = Uri.parse('https://wa.me/$phoneNumber');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final faqs = [
      _FAQ(l10n.t('help.faq1_q'), l10n.t('help.faq1_a')),
      _FAQ(l10n.t('help.faq2_q'), l10n.t('help.faq2_a')),
      _FAQ(l10n.t('help.faq3_q'), l10n.t('help.faq3_a')),
      _FAQ(l10n.t('help.faq4_q'), l10n.t('help.faq4_a')),
      _FAQ(l10n.t('help.faq5_q'), l10n.t('help.faq5_a')),
      _FAQ(l10n.t('help.faq6_q'), l10n.t('help.faq6_a')),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('help.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
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
                  Text(
                    l10n.t('help.search_hint'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.mediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQs
            Text(l10n.t('help.faq'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...faqs.map(
              (f) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  title: Text(f.question, style: AppTextStyles.labelMedium),
                  children: [
                    Text(
                      f.answer,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.grey,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                  const Icon(
                    Icons.headset_mic_rounded,
                    color: AppColors.primary,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.t('help.still_need_help'), style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('help.support_available'),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _launchWhatsApp('25377442343'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.t('help.contact_support'),
                        style: AppTextStyles.badge.copyWith(fontSize: 13),
                      ),
                    ),
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

class _FAQ {
  final String question, answer;
  _FAQ(this.question, this.answer);
}
