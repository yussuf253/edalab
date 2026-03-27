import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: Consumer2<ThemeProvider, NotificationProvider>(
        builder: (context, themeProvider, notificationProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // General
              Text('General', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingTile(
                Icons.language_rounded, 'Language', 'English',
                AppColors.primary, onTap: () {},
              ),
              _SettingTile(
                Icons.location_on_outlined, 'Location', 'New York, NY',
                AppColors.secondary, onTap: () {},
              ),
              _SettingToggle(
                Icons.dark_mode_outlined, 'Dark Mode', '',
                AppColors.dark, themeProvider.isDarkMode,
                (val) => themeProvider.toggleTheme(),
              ),
              const SizedBox(height: 20),

              // Notifications
              Text('Notifications', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingToggle(
                Icons.notifications_outlined,
                'Push Notifications',
                '',
                AppColors.warning,
                notificationProvider.preferences.pushEnabled,
                notificationProvider.setPushEnabled,
              ),
              _SettingToggle(
                Icons.email_outlined,
                'Email Notifications',
                '',
                AppColors.doctor,
                notificationProvider.preferences.emailEnabled,
                notificationProvider.setEmailEnabled,
              ),
              _SettingToggle(
                Icons.campaign_outlined,
                'Promotions',
                '',
                AppColors.food,
                notificationProvider.preferences.promotionsEnabled,
                notificationProvider.setPromotionsEnabled,
              ),
              _SettingToggle(
                Icons.location_on_outlined,
                'Location Alerts',
                '',
                AppColors.success,
                notificationProvider.preferences.locationAlertsEnabled,
                notificationProvider.setLocationAlertsEnabled,
              ),
              const SizedBox(height: 20),

              // Privacy
              Text('Privacy & Security', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingTile(Icons.lock_outlined, 'Change Password', '', AppColors.accent, onTap: () {}),
              _SettingToggle(Icons.fingerprint_rounded, 'Biometric Login', '', AppColors.primary, true, (_) {}),
              _SettingTile(Icons.shield_outlined, 'Two-Factor Auth', 'Enabled', AppColors.success, onTap: () {}),
              _SettingTile(Icons.history_rounded, 'Login Activity', '', AppColors.grey, onTap: () {}),
              const SizedBox(height: 20),

              // Data
              Text('Data & Storage', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingTile(Icons.download_rounded, 'Download History', '', AppColors.primary, onTap: () {}),
              _SettingTile(Icons.storage_rounded, 'Clear Cache', '23 MB', AppColors.food, onTap: () {}),
              const SizedBox(height: 20),

              // About
              Text('About', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              _SettingTile(Icons.info_outline_rounded, 'App Version', 'v1.0.0', AppColors.grey, onTap: () {}),
              _SettingTile(Icons.star_outline_rounded, 'Rate App', '', AppColors.warning, onTap: () {}),
              _SettingTile(Icons.share_outlined, 'Share App', '', AppColors.primary, onTap: () {}),
              const SizedBox(height: 20),

              // Danger zone
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
                          Text('Delete Account', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                          Text('This action cannot be undone', style: AppTextStyles.caption.copyWith(color: AppColors.error)),
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
