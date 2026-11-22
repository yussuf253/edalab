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
    final cartCount = context.watch<CartProvider>().itemCount;
    // The cart only holds items from the shopping/food/grocery/pharmacy
    // modules (see cart_hub_screen) — when every one of them is disabled,
    // the tab has nothing to show and disappears from the bar.
    final moduleProvider = context.watch<ModuleProvider>();
    final showCartTab =
        moduleProvider.isEnabled('shopping') ||
        moduleProvider.isEnabled('food') ||
        moduleProvider.isEnabled('grocery') ||
        moduleProvider.isEnabled('pharmacy');
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
      if (showCartTab)
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
    final currentIndex = _indexOfPath(path, navItems);

    return Scaffold(
      body: widgetChildWithSafeBackground(child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
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
      ),
    );
  }

  Widget widgetChildWithSafeBackground(Widget child) {
    return ColoredBox(color: AppColors.background, child: child);
  }

  /// Highlight index derived from the *actual* tab list, so hiding the cart
  /// tab doesn't shift every highlight after it (messages, profile).
  int _indexOfPath(String path, List<_NavItem> items) {
    if (path == '/' || path.startsWith('/search')) return 0;

    for (var index = 0; index < items.length; index++) {
      final navPath = items[index].path;
      if (path == navPath || path.startsWith('$navPath/')) {
        return index;
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
    final foreground = isActive ? AppColors.primary : AppColors.mediumGrey;
    final badge = item.path == '/cart' && cartCount > 0
        ? _CartBadge(count: cartCount)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primarySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ColorFiltered(
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
                    if (badge != null)
                      Positioned(top: -6, right: -9, child: badge),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: AppTextStyles.labelMedium.copyWith(
                  color: foreground,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 15),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white, width: 1.4),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.badge.copyWith(fontSize: 8),
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
