import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/analytics/analytics_events.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/providers.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Root shell: a flat bottom navigation bar over one shared canvas.
///
/// The bar is docked edge to edge at the bottom of the screen — no inset,
/// rounded card or shadow — so it reads as part of the page. A hairline top
/// border separates it from content, and the active tab is marked by a soft
/// brand pill behind its icon and label. Icons come from the same Lucide set
/// as the rest of the app, so the nav can never drift back to a second
/// iconography.
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
        icon: LucideIcons.house,
        activeIcon: LucideIcons.house,
        label: l10n.t('home.services'),
        path: '/',
      ),
      _NavItem(
        icon: LucideIcons.receiptText,
        activeIcon: LucideIcons.receiptText,
        label: l10n.t('module.orders'),
        path: '/orders',
      ),
      if (showCartTab)
        _NavItem(
          icon: LucideIcons.shoppingBag,
          activeIcon: LucideIcons.shoppingBag,
          label: l10n.t('cart.title'),
          path: '/cart',
        ),
      _NavItem(
        icon: LucideIcons.messageCircle,
        activeIcon: LucideIcons.messageCircle,
        label: l10n.t('messages.title'),
        path: '/messages',
      ),
      _NavItem(
        icon: LucideIcons.userRound,
        activeIcon: LucideIcons.userRound,
        label: l10n.t('profile.account'),
        path: '/profile',
      ),
    ];
    final currentIndex = _indexOfPath(path, navItems);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 6),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
      ),
    );
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
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        // No ripple and no highlight: the pill under the tapped tab is the
        // only feedback, so a tap never flashes a second colour over the
        // icon and then fades it away.
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primarySurface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          // Selection is applied in the same frame on every tab: the old tab
          // drops its pill and returns to grey exactly when the new one takes
          // them, so nothing trails behind the tap.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 20,
                    color: foreground,
                  ),
                  if (badge != null)
                    Positioned(top: -6, right: -10, child: badge),
                ],
              ),
              const SizedBox(height: 2),
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
      constraints: const BoxConstraints(minWidth: 16),
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
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}
