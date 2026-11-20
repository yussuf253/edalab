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
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(4, 7, 4, 7),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 8),
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
                  isCenter:
                      navItems.length.isOdd && index == navItems.length ~/ 2,
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
    this.isCenter = false,
  });

  final _NavItem item;
  final bool isActive;
  final int cartCount;
  final VoidCallback onTap;
  final bool isCenter;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? AppColors.primary : AppColors.mediumGrey;
    final badge = item.path == '/cart' && cartCount > 0
        ? _CartBadge(count: cartCount, onGreen: isCenter)
        : null;

    // Middle tab of an odd bar becomes the raised green action button.
    if (isCenter) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x3300A651),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    AppColors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    item.assetPath,
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                ),
                if (badge != null) Positioned(top: 1, right: 1, child: badge),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 26,
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
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (badge != null)
                      Positioned(top: -4, right: 0, child: badge),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isActive ? AppColors.primary : AppColors.mediumGrey,
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
  const _CartBadge({required this.count, this.onGreen = false});

  final int count;
  final bool onGreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(
        color: onGreen ? AppColors.white : AppColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: AppTextStyles.badge.copyWith(
          fontSize: 8,
          color: onGreen ? AppColors.primary : AppColors.white,
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
