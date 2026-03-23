import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/providers/providers.dart';

class GroceryCartScreen extends StatelessWidget {
  const GroceryCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.getModuleItems('grocery');
    final subtotal = cartProvider.getModuleSubtotal('grocery');
    final deliveryFee = items.isEmpty ? 0.0 : 3.99;
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Grocery Cart'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => cartProvider.clearModuleCart('grocery'),
              child: Text('Clear', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.lightGrey),
                  const SizedBox(height: 16),
                  Text('Your grocery cart is empty', style: AppTextStyles.h3.copyWith(color: AppColors.grey)),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Browse Groceries',
                    width: 200,
                    color: AppColors.grocery,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _ItemRow(
                        name: item.name,
                        qty: '${item.quantity} ${item.brand ?? ''}',
                        price: item.price * item.quantity,
                        quantity: item.quantity,
                        onIncrement: () => cartProvider.updateQuantity(item.id, item.quantity + 1),
                        onDecrement: () => cartProvider.updateQuantity(item.id, item.quantity - 1),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SumRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                        _SumRow('Delivery', '\$${deliveryFee.toStringAsFixed(2)}'),
                        const Divider(height: 20),
                        _SumRow('Total', '\$${total.toStringAsFixed(2)}', bold: true),
                        const SizedBox(height: 16),
                        AppButton(
                          text: 'Checkout • \$${total.toStringAsFixed(2)}', 
                          color: AppColors.grocery, 
                          onPressed: () {
                            context.push('/checkout');
                          },
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

class _ItemRow extends StatelessWidget {
  final String name, qty;
  final double price;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ItemRow({
    required this.name, 
    required this.qty, 
    required this.price,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppSpacing.shadowSm),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: AppColors.groceryBg, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.eco_rounded, color: AppColors.grocery),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(qty, style: AppTextStyles.caption),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.extraLightGrey, borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onDecrement,
                  child: const SizedBox(width: 28, height: 28, child: Icon(Icons.remove, size: 16)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text('$quantity', style: AppTextStyles.labelMedium),
                ),
                GestureDetector(
                  onTap: onIncrement,
                  child: const SizedBox(width: 28, height: 28, child: Icon(Icons.add, size: 16)),
                ),
              ],
            ),
          ),
          Text('\$${price.toStringAsFixed(2)}', style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _SumRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
          Text(value, style: bold ? AppTextStyles.priceSmall.copyWith(color: AppColors.grocery) : AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
