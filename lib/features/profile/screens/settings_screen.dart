import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
          icon: const Icon(LucideIcons.chevronLeft, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer3<ThemeProvider, NotificationProvider, LanguageProvider>(
        builder:
            (
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
                    LucideIcons.languages,
                    l10n.t('settings.language'),
                    languageProvider.currentLanguage.nativeName,
                    AppColors.primary,
                    onTap: () => _showLanguagePicker(context, languageProvider),
                  ),
                  _SettingTile(
                    LucideIcons.mapPin,
                    l10n.t('settings.location'),
                    'Djibouti City',
                    AppColors.secondary,
                    onTap: () {},
                  ),
                  _SettingToggle(
                    LucideIcons.moon,
                    l10n.t('settings.dark_mode'),
                    '',
                    AppColors.dark,
                    themeProvider.isDarkMode,
                    (val) => themeProvider.toggleTheme(),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    l10n.t('settings.notifications'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 12),
                  _SettingToggle(
                    LucideIcons.bell,
                    l10n.t('settings.push_notifications'),
                    '',
                    AppColors.warning,
                    notificationProvider.preferences.pushEnabled,
                    notificationProvider.setPushEnabled,
                  ),
                  _SettingToggle(
                    LucideIcons.mail,
                    l10n.t('settings.email_notifications'),
                    '',
                    AppColors.doctor,
                    notificationProvider.preferences.emailEnabled,
                    notificationProvider.setEmailEnabled,
                  ),
                  _SettingToggle(
                    LucideIcons.megaphone,
                    l10n.t('settings.promotions'),
                    '',
                    AppColors.food,
                    notificationProvider.preferences.promotionsEnabled,
                    notificationProvider.setPromotionsEnabled,
                  ),
                  _SettingToggle(
                    LucideIcons.mapPin,
                    l10n.t('settings.location_alerts'),
                    '',
                    AppColors.success,
                    notificationProvider.preferences.locationAlertsEnabled,
                    notificationProvider.setLocationAlertsEnabled,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    l10n.t('settings.privacy_security'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 12),
                  _SettingTile(
                    LucideIcons.lock,
                    l10n.t('settings.change_password'),
                    '',
                    AppColors.accent,
                    onTap: () {},
                  ),
                  _SettingToggle(
                    LucideIcons.fingerprint,
                    l10n.t('settings.biometric_login'),
                    '',
                    AppColors.primary,
                    true,
                    (_) {},
                  ),
                  _SettingTile(
                    LucideIcons.shield,
                    l10n.t('settings.two_factor_auth'),
                    l10n.t('common.enabled'),
                    AppColors.success,
                    onTap: () {},
                  ),
                  _SettingTile(
                    LucideIcons.history,
                    l10n.t('settings.login_activity'),
                    '',
                    AppColors.grey,
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),

                  Text(
                    l10n.t('settings.data_storage'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 12),
                  _SettingTile(
                    LucideIcons.download,
                    l10n.t('settings.download_history'),
                    '',
                    AppColors.primary,
                    onTap: () {},
                  ),
                  _SettingTile(
                    LucideIcons.database,
                    l10n.t('settings.clear_cache'),
                    '23 MB',
                    AppColors.food,
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),

                  Text(l10n.t('settings.about'), style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _SettingTile(
                    LucideIcons.info,
                    l10n.t('settings.app_version'),
                    'v1.5.0',
                    AppColors.grey,
                    onTap: () {},
                  ),
                  _SettingTile(
                    CupertinoIcons.star_fill,
                    l10n.t('settings.rate_app'),
                    '',
                    AppColors.warning,
                    onTap: () {},
                  ),
                  _SettingTile(
                    LucideIcons.share,
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
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            LucideIcons.trash2,
                            color: AppColors.error,
                            size: 22,
                          ),
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
                        const Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: AppColors.error,
                        ),
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
                              : AppColors.border,
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
                              LucideIcons.checkCircle,
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
  const _SettingTile(
    this.icon,
    this.title,
    this.subtitle,
    this.color, {
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.labelMedium)),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: AppTextStyles.caption),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: AppColors.mediumGrey,
            ),
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
  const _SettingToggle(
    this.icon,
    this.title,
    this.subtitle,
    this.color,
    this.value,
    this.onChanged,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
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
