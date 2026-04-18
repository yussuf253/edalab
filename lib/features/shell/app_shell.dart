import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/providers/providers.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = GoRouterState.of(context).uri.path;
    final currentIndex = _currentIndexForPath(path);
    final cartCount = context.watch<CartProvider>().itemCount;
    final navItems = [
      _NavItem(
        assetPath: AppAssets.navHome,
        label: l10n.t('home.services'),
        path: '/',
      ),
      _NavItem(
        assetPath: AppAssets.navOrders,
        label: l10n.t('module.orders'),
        path: '/orders',
      ),
      _NavItem(
        assetPath: AppAssets.navCart,
        label: l10n.t('cart.title'),
        path: '/cart',
      ),
      _NavItem(
        assetPath: AppAssets.navMessages,
        label: l10n.t('messages.title'),
        path: '/messages',
      ),
      _NavItem(
        assetPath: AppAssets.navProfile,
        label: l10n.t('profile.account'),
        path: '/profile',
      ),
    ];

    return Scaffold(
      body: widgetChildWithSafeBackground(child),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.98),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              return Expanded(
                child: _NavButton(
                  item: item,
                  isActive: currentIndex == index,
                  cartCount: cartCount,
                  onTap: () {
                    AnalyticsService.instance.track(
                      AnalyticsEvents.navigationTabTapped,
                      properties: {
                        'target_path': item.path,
                        'current_path': path,
                        'is_reselect': currentIndex == index,
                        'cart_count': cartCount,
                      },
                    );
                    context.go(item.path);
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget widgetChildWithSafeBackground(Widget child) {
    return ColoredBox(color: AppColors.background, child: child);
  }

  int _currentIndexForPath(String path) {
    if (path == '/' || path.startsWith('/search')) return 0;

    const navPaths = ['/orders', '/cart', '/messages', '/profile'];
    for (var index = 0; index < navPaths.length; index++) {
      final navPath = navPaths[index];
      if (path == navPath || path.startsWith('$navPath/')) {
        return index + 1;
      }
    }

    return 0;
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isActive,
    required this.cartCount,
    required this.onTap,
  });

  final _NavItem item;
  final bool isActive;
  final int cartCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? AppColors.primaryDark : AppColors.mediumGrey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          foreground,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          item.assetPath,
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (item.path == '/cart' && cartCount > 0)
                      Positioned(
                        top: -5,
                        right: 6,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            cartCount > 99 ? '99+' : '$cartCount',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.badge.copyWith(fontSize: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? AppColors.primaryDark : AppColors.grey,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 2,
                width: isActive ? 18 : 0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.assetPath,
    required this.label,
    required this.path,
  });

  final String assetPath;
  final String label;
  final String path;
}
