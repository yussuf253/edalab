import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../l10n/app_localizations.dart';

class ProPendingVerificationScreen extends StatelessWidget {
  const ProPendingVerificationScreen({
    super.key,
    required this.businessName,
    required this.profileType,
  });

  final String businessName;
  final String profileType;

  Future<void> _openWhatsApp() async {
    const whatsappNumber = '25377442343';
    final whatsappUrl = Uri.parse(
      'https://wa.me/$whatsappNumber?text=Hello%2C%20I%20need%20help%20with%20my%20pro%20account%20verification.',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback - try to open the WhatsApp app if available
        final whatsappApp = Uri.parse('https://www.whatsapp.com/');
        if (await canLaunchUrl(whatsappApp)) {
          await launchUrl(whatsappApp, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(ProDesignSystem.spacing20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: ProDesignSystem.spacing32),
                // Illustration or icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      ProDesignSystem.radiusLarge,
                    ),
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    size: 60,
                    color: Colors.amber.shade600,
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing32),

                // Title
                Text(
                  l10n.verificationPendingTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ProDesignSystem.spacing12),

                // Subtitle
                Text(
                  l10n.verificationPendingSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: ProDesignSystem.spacing32),

                // Info cards
                _VerificationInfoCard(
                  icon: Icons.business_outlined,
                  title: l10n.businessNameLabel,
                  subtitle: businessName,
                ),
                const SizedBox(height: ProDesignSystem.spacing12),

                _VerificationInfoCard(
                  icon: Icons.verified_user_outlined,
                  title: l10n.accountTypeLabel,
                  subtitle: profileType,
                ),
                const SizedBox(height: ProDesignSystem.spacing32),

                // Description
                Container(
                  padding: const EdgeInsets.all(ProDesignSystem.spacing16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(
                      ProDesignSystem.radiusSmall,
                    ),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.whatsHappening,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing8),
                      Text(
                        l10n.verificationDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing32),

                // WhatsApp button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(l10n.contactSupportWhatsApp),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: ProDesignSystem.spacing12,
                      ),
                      backgroundColor: Colors.green.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing16),

                // WhatsApp number display
                Text(
                  '+253 77 44 23 43',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: ProDesignSystem.spacing8),
                Text(
                  l10n.available247,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationInfoCard extends StatelessWidget {
  const _VerificationInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ProDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusSmall),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 24),
          const SizedBox(width: ProDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
