import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('settings.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer3<
        ThemeProvider,
        NotificationProvider,
        LanguageProvider
      >(
        builder: (
          context,
          themeProvider,
          notificationProvider,
          languageProvider,
          child,
        ) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(l10n.t('settings.general'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingTile(
                Icons.language_rounded,
                l10n.t('settings.language'),
                languageProvider.currentLanguage.nativeName,
                AppColors.primary,
                onTap: () => _showLanguagePicker(context, languageProvider),
              ),
              _SettingTile(
                Icons.location_on_outlined,
                l10n.t('settings.location'),
                'Djibouti City',
                AppColors.secondary,
                onTap: () {},
              ),
              _SettingToggle(
                Icons.dark_mode_outlined,
                l10n.t('settings.dark_mode'),
                '',
                AppColors.dark,
                themeProvider.isDarkMode,
                (val) => themeProvider.toggleTheme(),
              ),
              const SizedBox(height: 20),

              Text(l10n.t('settings.notifications'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingToggle(
                Icons.notifications_outlined,
                l10n.t('settings.push_notifications'),
                '',
                AppColors.warning,
                notificationProvider.preferences.pushEnabled,
                notificationProvider.setPushEnabled,
              ),
              _SettingToggle(
                Icons.email_outlined,
                l10n.t('settings.email_notifications'),
                '',
                AppColors.doctor,
                notificationProvider.preferences.emailEnabled,
                notificationProvider.setEmailEnabled,
              ),
              _SettingToggle(
                Icons.campaign_outlined,
                l10n.t('settings.promotions'),
                '',
                AppColors.food,
                notificationProvider.preferences.promotionsEnabled,
                notificationProvider.setPromotionsEnabled,
              ),
              _SettingToggle(
                Icons.location_on_outlined,
                l10n.t('settings.location_alerts'),
                '',
                AppColors.success,
                notificationProvider.preferences.locationAlertsEnabled,
                notificationProvider.setLocationAlertsEnabled,
              ),
              const SizedBox(height: 20),

              Text(l10n.t('settings.privacy_security'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingTile(
                Icons.lock_outlined,
                l10n.t('settings.change_password'),
                '',
                AppColors.accent,
                onTap: () {},
              ),
              _SettingToggle(
                Icons.fingerprint_rounded,
                l10n.t('settings.biometric_login'),
                '',
                AppColors.primary,
                true,
                (_) {},
              ),
              _SettingTile(
                Icons.shield_outlined,
                l10n.t('settings.two_factor_auth'),
                l10n.t('common.enabled'),
                AppColors.success,
                onTap: () {},
              ),
              _SettingTile(
                Icons.history_rounded,
                l10n.t('settings.login_activity'),
                '',
                AppColors.grey,
                onTap: () {},
              ),
              const SizedBox(height: 20),

              Text(l10n.t('settings.data_storage'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingTile(
                Icons.download_rounded,
                l10n.t('settings.download_history'),
                '',
                AppColors.primary,
                onTap: () {},
              ),
              _SettingTile(
                Icons.storage_rounded,
                l10n.t('settings.clear_cache'),
                '23 MB',
                AppColors.food,
                onTap: () {},
              ),
              const SizedBox(height: 20),

              Text(l10n.t('settings.about'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingTile(
                Icons.info_outline_rounded,
                l10n.t('settings.app_version'),
                'v1.0.0',
                AppColors.grey,
                onTap: () {},
              ),
              _SettingTile(
                Icons.star_outline_rounded,
                l10n.t('settings.rate_app'),
                '',
                AppColors.warning,
                onTap: () {},
              ),
              _SettingTile(
                Icons.share_outlined,
                l10n.t('settings.share_app'),
                '',
                AppColors.primary,
                onTap: () {},
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('settings.delete_account'),
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                          Text(
                            l10n.t('settings.delete_account_subtitle'),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.error),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    LanguageProvider languageProvider,
  ) {
    final l10n = context.l10n;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('settings.language'), style: AppTextStyles.h3),
                const SizedBox(height: 6),
                Text(
                  l10n.t('settings.choose_language'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 18),
                ...LanguageProvider.supportedLanguages.map((language) {
                  final isSelected =
                      language.locale.languageCode ==
                      languageProvider.locale.languageCode;
                  return GestureDetector(
                    onTap: () async {
                      await languageProvider.setLocale(language.locale);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.extraLightGrey,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  language.nativeName,
                                  style: AppTextStyles.labelLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  language.englishName,
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _SettingTile(this.icon, this.title, this.subtitle, this.color, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.labelMedium)),
            if (subtitle.isNotEmpty) Text(subtitle, style: AppTextStyles.caption),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.mediumGrey),
          ],
        ),
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingToggle(this.icon, this.title, this.subtitle, this.color, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: AppTextStyles.labelMedium)),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
