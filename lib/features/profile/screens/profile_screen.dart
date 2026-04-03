import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../pro/core/providers/pro_auth_provider.dart';
import '../../../pro/core/utils/pro_module_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final proAuthProvider = context.watch<ProAuthProvider>();
    final user = authProvider.user;
    final l10n = context.l10n;
    final currentProProfile = proAuthProvider.currentProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const NotificationBell(
                        size: 40,
                        backgroundColor: Color(0x33FFFFFF),
                        iconColor: AppColors.white,
                        useShadow: false,
                        compact: true,
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => context.push('/profile/settings'),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.settings_outlined, color: AppColors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
                    ),
                    child: user?.avatarUrl != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(21),
                            child: Image.network(user!.avatarUrl!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.person_rounded, color: AppColors.white, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.fullName ?? l10n.t('profile.guest'),
                    style: AppTextStyles.h2.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 4),
                  if (user != null)
                    Text(user.email, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Stat(user != null ? '12' : '0', l10n.t('profile.orders')),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _Stat(user != null ? '\$450' : '\$0', l10n.t('profile.spent')),
                      Container(width: 1, height: 30, color: Colors.white24),
                      _Stat(
                        user != null ? '${user.points}' : '0',
                        l10n.t('profile.rewards'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Menu items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t('profile.account'), style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _MenuItem(
                    Icons.person_outline_rounded,
                    l10n.t('profile.edit_profile'),
                    AppColors.primary,
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _MenuItem(
                    Icons.location_on_outlined,
                    l10n.t('profile.addresses'),
                    AppColors.secondary,
                    onTap: () => context.push('/profile/addresses'),
                  ),
                  _MenuItem(
                    Icons.credit_card_rounded,
                    l10n.t('profile.payment_methods'),
                    AppColors.food,
                    onTap: () => context.push('/profile/payment-methods'),
                  ),
                  const SizedBox(height: 20),

                  Text(l10n.t('profile.preferences'), style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _MenuItem(
                    Icons.notifications_outlined,
                    l10n.t('profile.notifications'),
                    AppColors.warning,
                    onTap: () => context.push('/notifications'),
                  ),
                  _MenuItem(
                    Icons.settings_outlined,
                    l10n.t('profile.settings'),
                    AppColors.dark,
                    onTap: () => context.push('/profile/settings'),
                  ),
                  const SizedBox(height: 20),

                  Text(l10n.t('profile.support'), style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _MenuItem(
                    Icons.help_outline_rounded,
                    l10n.t('profile.help_center'),
                    AppColors.success,
                    onTap: () => context.push('/profile/help'),
                  ),
                  _MenuItem(
                    Icons.chat_bubble_outline_rounded,
                    l10n.t('profile.contact_us'),
                    AppColors.doctor,
                  ),
                  _MenuItem(
                    Icons.privacy_tip_outlined,
                    l10n.t('profile.privacy_policy'),
                    AppColors.grey,
                  ),
                  const SizedBox(height: 20),

                  Text('Professional', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  _MenuItem(
                    currentProProfile != null
                        ? ProModuleHelper.getProfileIcon(currentProProfile.type)
                        : Icons.store_mall_directory_outlined,
                    currentProProfile != null
                        ? 'Open ${ProModuleHelper.getProfileName(currentProProfile.type)}'
                        : 'Join as a Professional',
                    currentProProfile != null
                        ? ProModuleHelper.getProfileColor(currentProProfile.type)
                        : AppColors.primary,
                    onTap: () {
                      if (user == null) {
                        context.go('/login');
                        return;
                      }

                      context.push(
                        currentProProfile != null
                            ? '/pro/dashboard'
                            : '/pro/signup',
                      );
                    },
                  ),
                  if (currentProProfile != null)
                    _MenuItem(
                      Icons.badge_outlined,
                      '${currentProProfile.activeModules.length} active business modules',
                      AppColors.secondary,
                      onTap: () => context.push('/pro/dashboard'),
                    ),
                  const SizedBox(height: 20),

                  // Logout
                  if (user != null)
                    GestureDetector(
                      onTap: () async {
                        await context.read<AuthProvider>().logout();
                        if (!context.mounted) return;
                        context.go('/login');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, color: AppColors.accent, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              l10n.t('profile.log_out'),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (user == null)
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              l10n.t('profile.log_in'),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  const SizedBox(height: 20),
                  Center(
                    child: Text('EdaLab v1.0.0', style: AppTextStyles.caption),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.white)),
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white60)),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _MenuItem(this.icon, this.title, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.labelMedium)),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mediumGrey),
          ],
        ),
      ),
    );
  }
}
