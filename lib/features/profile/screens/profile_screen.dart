import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/module_screen_app_bar.dart';
import '../../../core/widgets/notification_bell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _orderCount = 0;
  double _totalSpent = 0;
  bool _statsLoaded = false;
  String? _loadedForUserId;

  @override
  void initState() {
    super.initState();
    _loadSpendStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSpendStats();
  }

  /// Computes order count and total spent from the same order-history
  /// endpoints the orders screen uses, so the header reflects real activity
  /// instead of placeholder values.
  Future<void> _loadSpendStats() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || _loadedForUserId == userId) return;
    _loadedForUserId = userId;

    int count = 0;
    double spent = 0;

    Future<void> accumulate(dynamic data) async {
      if (data is! List) return;
      count += data.length;
      for (final entry in data) {
        if (entry is! Map) continue;
        final total = entry['total'] ?? entry['fee'] ?? entry['estimatedFare'];
        if (total is num) spent += total.toDouble();
      }
    }

    try {
      final results = await Future.wait([
        ApiClient.get('/orders/$userId'),
        ApiClient.get('/appointments/$userId'),
        ApiClient.get('/rides/user/$userId'),
      ]);
      for (final data in results) {
        await accumulate(data);
      }
    } catch (_) {
      // Leave stats at zero on failure; they will retry on next mount.
      _loadedForUserId = null;
    }

    if (!mounted) return;
    setState(() {
      _orderCount = count;
      _totalSpent = spent;
      _statsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final user = authProvider.user;
    final l10n = context.l10n;
    final avatarUrl = user?.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ModuleScreenAppBar(
        title: l10n.t('profile.account'),
        showBack: false,
      ),
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const NotificationBell(
                          size: 40,
                          backgroundColor: AppColors.tile,
                          iconColor: AppColors.dark,
                          useShadow: false,
                          compact: true,
                          showBorder: false,
                        ),
                        // const SizedBox(width: 10),
                        // Settings quick access is intentionally disabled for now.
                        // GestureDetector(
                        //   onTap: () => context.push('/profile/settings'),
                        //   child: Container(
                        //     width: 40, height: 40,
                        //     decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
                        //     child: const Icon(LucideIcons.settings, color: AppColors.white, size: 22),
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          width: 1.5,
                        ),
                      ),
                      child: hasAvatar
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      LucideIcons.user,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                              ),
                            )
                          : const Icon(
                              LucideIcons.user,
                              color: AppColors.primary,
                              size: 32,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? l10n.t('profile.guest'),
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 4),
                    if (user != null)
                      Text(
                        user.email,
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tile,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _Stat(
                            _statsLoaded || user == null ? '$_orderCount' : '—',
                            l10n.t('profile.orders'),
                            valueColor: AppColors.dark,
                            labelColor: AppColors.grey,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppColors.border,
                          ),
                          _Stat(
                            _statsLoaded || user == null
                                ? 'DJF${_totalSpent.toInt()}'
                                : '—',
                            l10n.t('profile.spent'),
                            valueColor: AppColors.dark,
                            labelColor: AppColors.grey,
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: AppColors.border,
                          ),
                          _Stat(
                            user != null ? '${user.points}' : '0',
                            l10n.t('profile.rewards'),
                            valueColor: AppColors.dark,
                            labelColor: AppColors.grey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Menu items
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.t('profile.account'),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  _MenuItem(
                    LucideIcons.user,
                    l10n.t('profile.edit_profile'),
                    AppColors.primary,
                    onTap: () => context.push('/profile/edit'),
                  ),
                  _MenuItem(
                    LucideIcons.mapPin,
                    l10n.t('profile.addresses'),
                    AppColors.secondary,
                    onTap: () => context.push('/profile/addresses'),
                  ),
                  const SizedBox(height: 20),

                  SectionHeader(
                    title: l10n.t('profile.preferences'),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  _MenuItem(
                    LucideIcons.bell,
                    l10n.t('profile.notifications'),
                    AppColors.warning,
                    onTap: () => context.push('/notifications'),
                  ),
                  _LanguageMenuItem(
                    icon: LucideIcons.languages,
                    title: l10n.t('settings.language'),
                    value: languageProvider.currentLanguage.nativeName,
                    color: AppColors.success,
                    onTap: () => _showLanguagePicker(context, languageProvider),
                  ),
                  // Settings row intentionally disabled for now.
                  // _MenuItem(
                  //   LucideIcons.settings,
                  //   l10n.t('profile.settings'),
                  //   AppColors.dark,
                  //   onTap: () => context.push('/profile/settings'),
                  // ),
                  const SizedBox(height: 20),

                  SectionHeader(
                    title: l10n.t('profile.support'),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  _MenuItem(
                    LucideIcons.circleHelp,
                    l10n.t('profile.help_center'),
                    AppColors.success,
                    onTap: () => context.push('/profile/help'),
                  ),
                  const SizedBox(height: 20),

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
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.logOut,
                              color: AppColors.accent,
                              size: 22,
                            ),
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
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.logIn,
                              color: AppColors.primary,
                              size: 22,
                            ),
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
                    child: Text(
                      l10n.t(
                        'profile.app_version_label',
                        params: {'version': '1.8.0'},
                      ),
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    LanguageProvider languageProvider,
  ) async {
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
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
                        borderRadius: BorderRadius.circular(18),
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

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final Color labelColor;

  const _Stat(
    this.value,
    this.label, {
    this.valueColor = AppColors.white,
    this.labelColor = Colors.white60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: valueColor)),
        Text(label, style: AppTextStyles.caption.copyWith(color: labelColor)),
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.labelMedium)),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.mediumGrey,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _LanguageMenuItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.labelMedium)),
            Text(value, style: AppTextStyles.caption),
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
