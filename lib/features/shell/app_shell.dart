import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/providers.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      path: '/',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'Messages',
      path: '/messages',
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      label: 'Cart',
      path: '/cart',
      isCenter: true,
    ),
    _NavItem(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Orders',
      path: '/orders',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      path: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final currentIndex = _currentIndexForPath(path);
    final cartCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 6),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.98),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 3, 10, 4),
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isActive = currentIndex == index;
                return Expanded(
                  child: _buildNavItem(item, isActive, cartCount: cartCount),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  int _currentIndexForPath(String path) {
    if (path == '/' || path.startsWith('/search')) {
      return 0;
    }

    for (var index = 1; index < _navItems.length; index++) {
      if (path == _navItems[index].path ||
          path.startsWith('${_navItems[index].path}/')) {
        return index;
      }
    }

    return 0;
  }

  Widget _buildNavItem(_NavItem item, bool isActive, {required int cartCount}) {
    final foreground = isActive ? AppColors.primary : AppColors.mediumGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(item.path),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 28,
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: isActive ? AppColors.primary : foreground,
                        size: 21,
                      ),
                    ),
                    if (item.path == '/cart' && cartCount > 0)
                      Positioned(
                        top: -4,
                        right: -5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.white,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            cartCount > 99 ? '99+' : '$cartCount',
                            style: AppTextStyles.badge.copyWith(fontSize: 8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isActive ? AppColors.primaryDark : AppColors.grey,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final bool isCenter;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    this.isCenter = false,
  });
}
