import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum ShopModuleBottomTab { orders, products }

class ShopModuleBottomNav extends StatelessWidget {
  final ShopModuleBottomTab activeTab;
  final VoidCallback onOrders;
  final VoidCallback onProducts;

  const ShopModuleBottomNav({
    super.key,
    required this.activeTab,
    required this.onOrders,
    required this.onProducts,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ShopModuleNavButton(
                icon: Icons.receipt_long_outlined,
                label: AppLocalizations.of(context)!.ordersLabel,
                onTap: onOrders,
                active: activeTab == ShopModuleBottomTab.orders,
              ),
            ),
            Expanded(
              child: _ShopModuleNavButton(
                icon: Icons.inventory_2_outlined,
                label: AppLocalizations.of(context)!.productsLabel,
                onTap: onProducts,
                active: activeTab == ShopModuleBottomTab.products,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopModuleNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ShopModuleNavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = Colors.grey.shade700;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? activeColor : inactiveColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
