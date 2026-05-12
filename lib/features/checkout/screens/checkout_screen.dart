import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/auth_gate.dart';
import '../../../core/widgets/app_button.dart';
import '../../../payment/payment_service.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic>? checkoutData;
  const CheckoutScreen({super.key, this.checkoutData});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPayment = 0;
  int _selectedAddress = 0;
  int _selectedDeliveryOption = 0;
  final TextEditingController _promoController = TextEditingController();
  bool _hasTrackedCheckoutView = false;
  bool _isPlacingOrder = false;

  static const _deliveryOptions = [
    ('checkout.standard', 'checkout.standard_eta', 0.0),
    ('checkout.express', 'checkout.express_eta', 9.99),
    ('checkout.same_day', 'checkout.same_day_eta', 14.99),
  ];

  String _moduleLabel(BuildContext context, String? moduleType) {
    final l10n = context.l10n;
    switch (moduleType) {
      case 'food':
        return l10n.t('checkout.food_order');
      case 'shopping':
        return l10n.t('checkout.shopping_order');
      case 'pharmacy':
        return l10n.t('checkout.pharmacy_order');
      case 'grocery':
        return l10n.t('checkout.grocery_order');
      default:
        return l10n.t('module.orders');
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackCheckoutViewed());
  }

  void _trackCheckoutViewed() {
    if (_hasTrackedCheckoutView || !mounted) return;

    final cartProvider = context.read<CartProvider>();
    final moduleType = (widget.checkoutData?['moduleType'] as String?)
        ?.toLowerCase();
    final moduleItems = moduleType == null
        ? cartProvider.items
        : cartProvider.getModuleItems(moduleType);
    final subtotal = moduleType == null
        ? cartProvider.subtotal
        : cartProvider.getModuleSubtotal(moduleType);

    AnalyticsService.instance.track(
      AnalyticsEvents.checkoutViewed,
      properties: {
        'module_type': moduleType ?? 'mixed',
        'line_count': moduleItems.length,
        'item_count': moduleItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ),
        'subtotal': subtotal,
        'source': widget.checkoutData?['source']?.toString() ?? 'direct',
      },
    );

    _hasTrackedCheckoutView = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();

    final addresses = authProvider.user?.addresses ?? [];
    final rawModuleType = widget.checkoutData?['moduleType'] as String?;
    final moduleType = rawModuleType?.toLowerCase();
    final moduleItems = moduleType == null
        ? cartProvider.items
        : cartProvider.getModuleItems(moduleType);
    final moduleName = widget.checkoutData?['moduleName'] as String?;
    final instructions = widget.checkoutData?['instructions'] as String?;
    final tip = (widget.checkoutData?['tip'] as num?)?.toDouble() ?? 0.0;

    final subtotal = moduleType == null
        ? cartProvider.subtotal
        : cartProvider.getModuleSubtotal(moduleType);
    final shipping = moduleItems.isEmpty
        ? 0.0
        : _deliveryOptions[_selectedDeliveryOption].$3;
    final tax = subtotal * 0.08;
    final discount = cartProvider.discount > subtotal
        ? subtotal
        : cartProvider.discount;
    final total = subtotal + shipping + tax + tip - discount;
    final paymentMethods = [
      (
        'Credit Card',
        '•••• 4242',
        Icons.credit_card_rounded,
        AppColors.primary,
      ),
      (
        'WaafiPay',
        'EVC Plus / mobile wallet',
        Icons.account_balance_wallet_rounded,
        AppColors.food,
      ),
      (
        'Apple Pay',
        'john.doe@apple.com',
        Icons.phone_iphone_rounded,
        AppColors.dark,
      ),
      (
        'PayPal',
        'john.doe@paypal.com',
        Icons.account_balance_wallet_rounded,
        AppColors.secondary,
      ),
      (
        'Cash on Delivery',
        'checkout.pay_when_delivered',
        Icons.attach_money_rounded,
        AppColors.success,
      ),
    ];
    final paymentName = paymentMethods[_selectedPayment].$1;
    final isWaafiPay = paymentName == 'WaafiPay';
    final moduleLabel = moduleName ?? _moduleLabel(context, moduleType);
    final selectedDeliveryLabel = l10n.t(
      _deliveryOptions[_selectedDeliveryOption].$1,
    );
    final selectedDeliveryEta = l10n.t(
      _deliveryOptions[_selectedDeliveryOption].$2,
    );
    final selectedAddress = addresses.isNotEmpty
        ? addresses[_selectedAddress]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('checkout.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (moduleType != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: moduleType == 'food'
                            ? AppColors.foodBg
                            : AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        moduleType == 'food'
                            ? Icons.restaurant_rounded
                            : Icons.shopping_bag_rounded,
                        color: moduleType == 'food'
                            ? AppColors.food
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moduleName ?? l10n.t('checkout.order_review'),
                            style: AppTextStyles.labelLarge,
                          ),
                          Text(
                            l10n.t(
                              'checkout.items_prepared',
                              params: {
                                'count':
                                    '${moduleItems.fold<int>(0, (sum, item) => sum + item.quantity)}',
                              },
                            ),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (moduleItems.isNotEmpty) ...[
              Text(l10n.t('checkout.items_in_order'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Column(
                  children: moduleItems
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: moduleType == 'food'
                                      ? AppColors.foodBg
                                      : AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  moduleType == 'food'
                                      ? Icons.restaurant_menu_rounded
                                      : Icons.shopping_bag_rounded,
                                  color: moduleType == 'food'
                                      ? AppColors.food
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTextStyles.labelMedium,
                                    ),
                                    Text(
                                      l10n.t(
                                        'checkout.qty_brand',
                                        params: {
                                          'qty': '${item.quantity}',
                                          'brand': item.brand == null
                                              ? ''
                                              : ' • ${item.brand}',
                                        },
                                      ),
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'DJF ${item.total.toStringAsFixed(2)}',
                                style: AppTextStyles.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Delivery Address
            Text(l10n.t('checkout.delivery_address'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            if (addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.grey,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.t('checkout.no_addresses'),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    AppButton(
                      text: l10n.t('checkout.add'),
                      width: 80,
                      isSmall: true,
                      onPressed: () => context.push('/profile/addresses'),
                    ),
                  ],
                ),
              )
            else
              ...addresses.asMap().entries.map((e) {
                final i = e.key;
                final a = e.value;
                final sel = _selectedAddress == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAddress = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: sel
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primarySurface
                                : AppColors.extraLightGrey,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            a.label == 'Home'
                                ? Icons.home_rounded
                                : Icons.work_rounded,
                            color: sel ? AppColors.primary : AppColors.grey,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.label, style: AppTextStyles.labelLarge),
                              Text(
                                [
                                  if ((a.city ?? '').isNotEmpty) a.city!,
                                  if ((a.quartier ?? '').isNotEmpty)
                                    a.quartier!,
                                ].join(', '),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        if (sel)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),

            // Delivery Time
            Text(l10n.t('checkout.delivery_option'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Row(
              children: _deliveryOptions.asMap().entries.map((entry) {
                final i = entry.key;
                final option = entry.value;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == _deliveryOptions.length - 1 ? 0 : 10,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDeliveryOption = i),
                      child: _TimeChip(
                        l10n.t(option.$1),
                        l10n.t(option.$2),
                        option.$3 == 0
                            ? l10n.t('checkout.free')
                            : 'DJF ${option.$3.toStringAsFixed(2)}',
                        _selectedDeliveryOption == i,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            if (instructions != null && instructions.isNotEmpty) ...[
              Text(l10n.t('checkout.order_notes'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Text(instructions, style: AppTextStyles.bodyMedium),
              ),
              const SizedBox(height: 20),
            ],

            // Payment method
            Text(l10n.t('checkout.payment_method'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ...paymentMethods.asMap().entries.map((e) {
              final i = e.key;
              final p = e.value;
              final sel = _selectedPayment == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedPayment = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: sel ? Border.all(color: p.$4, width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: p.$4.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(p.$3, color: p.$4, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.$1, style: AppTextStyles.labelMedium),
                            Text(
                              p.$2.startsWith('checkout.')
                                  ? l10n.t(p.$2)
                                  : p.$2,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? p.$4 : AppColors.lightGrey,
                            width: 2,
                          ),
                          color: sel ? p.$4 : Colors.transparent,
                        ),
                        child: sel
                            ? const Icon(
                                Icons.check,
                                color: AppColors.white,
                                size: 14,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // Promo code
            Text(l10n.t('checkout.promo_code'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: l10n.t('checkout.promo_hint'),
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final code = _promoController.text.trim();
                      if (code.isNotEmpty) {
                        try {
                          cartProvider.applyPromo(code);
                          final appliedCode = cartProvider.promoCode;
                          if (appliedCode != null) {
                            context
                                .read<NotificationProvider>()
                                .addNotification(
                                  NotificationService.promotion(
                                    title: l10n.t(
                                      'checkout.promo_applied_title',
                                    ),
                                    body: l10n.t(
                                      'checkout.promo_applied_body',
                                      params: {'code': appliedCode},
                                    ),
                                    promoCode: appliedCode,
                                    route: '/checkout',
                                  ),
                                );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.t('checkout.promo_code_applied'),
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.t('checkout.apply'),
                        style: AppTextStyles.badge.copyWith(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SumRow(
                    l10n.t('checkout.subtotal'),
                    'DJF ${subtotal.toStringAsFixed(2)}',
                  ),
                  _SumRow(
                    l10n.t('checkout.delivery'),
                    shipping <= 0.0
                        ? l10n.t('checkout.free')
                        : 'DJF ${shipping.toStringAsFixed(2)}',
                  ),
                  _SumRow(
                    l10n.t('checkout.tax'),
                    'DJF ${tax.toStringAsFixed(2)}',
                  ),
                  if (tip > 0)
                    _SumRow(
                      l10n.t('checkout.tip'),
                      'DJF ${tip.toStringAsFixed(2)}',
                    ),
                  if (discount > 0)
                    _SumRow(
                      l10n.t('checkout.discount'),
                      '-DJF ${discount.toStringAsFixed(2)}',
                      isDiscount: true,
                    ),
                  if (cartProvider.promoCode != null)
                    _SumRow(
                      'Promo (${cartProvider.promoCode})',
                      l10n.t('checkout.promo_applied'),
                      isDiscount: true,
                    ),
                  const Divider(height: 20),
                  _SumRow(
                    l10n.t('checkout.total'),
                    'DJF ${total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            AppButton(
              isLoading: _isPlacingOrder,
              text: l10n.t(
                'checkout.place_order',
                params: {
                  'module': _moduleLabel(context, moduleType),
                  'amount': total.toStringAsFixed(2),
                },
              ),
              onPressed: () async {
                AnalyticsService.instance.track(
                  AnalyticsEvents.checkoutPlaceOrderTapped,
                  properties: {
                    'module_type': moduleType ?? 'mixed',
                    'line_count': moduleItems.length,
                    'item_count': moduleItems.fold<int>(
                      0,
                      (sum, item) => sum + item.quantity,
                    ),
                    'subtotal': subtotal,
                    'shipping': shipping,
                    'tax': tax,
                    'tip': tip,
                    'discount': discount,
                    'total': total,
                    'payment_label': paymentName,
                    'delivery_label':
                        _deliveryOptions[_selectedDeliveryOption].$1,
                  },
                );
                final allowed = await requireLoggedIn(
                  context,
                  message: l10n.t('checkout.login_required'),
                );
                if (!context.mounted || !allowed) return;
                if (moduleItems.isEmpty) {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.checkoutValidationFailed,
                    properties: {
                      'reason': 'empty_cart',
                      'module_type': moduleType ?? 'mixed',
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.t('checkout.cart_empty')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else if (addresses.isEmpty) {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.checkoutValidationFailed,
                    properties: {
                      'reason': 'missing_address',
                      'module_type': moduleType ?? 'mixed',
                    },
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.t('checkout.add_address_first')),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } else {
                  setState(() => _isPlacingOrder = true);
                  final modules = moduleType == null
                      ? cartProvider.items.map((e) => e.moduleType).toSet()
                      : {moduleType};
                  String? primaryOrderId;
                  try {
                    for (var m in modules) {
                      final createdOrderId = await cartProvider.submitModuleOrder(
                        authProvider.user!.id,
                        m,
                        orderMetadata: {
                          'address': selectedAddress == null
                              ? null
                              : '${selectedAddress.address}${selectedAddress.city != null ? ', ${selectedAddress.city}' : ''}',
                          'addressLabel': selectedAddress?.label,
                          'deliveryLabel': selectedDeliveryLabel,
                          'deliveryEta': selectedDeliveryEta,
                          'paymentLabel': paymentName,
                        },
                      );
                      if (moduleType == null) {
                        primaryOrderId ??= createdOrderId;
                      } else if (m == moduleType) {
                        primaryOrderId = createdOrderId;
                      }
                    }
                    if (moduleType == null) {
                      cartProvider.clearCart();
                    }
                    if (!context.mounted) return;
                    final orderId =
                        primaryOrderId ??
                        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                    WaafiPaymentResult? waafiResult;
                    if (isWaafiPay) {
                      waafiResult = await context
                          .read<PaymentProvider>()
                          .initiateWaafiPayment(
                            orderId: orderId,
                            userId: authProvider.user!.id,
                            amount: total,
                            description: '$moduleLabel order $orderId',
                          );
                      if (!context.mounted) return;
                      if (!waafiResult.success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              waafiResult.message ??
                                  'Could not start WaafiPay payment.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      final paymentUrl = waafiResult.paymentUrl;
                      if (paymentUrl != null && paymentUrl.isNotEmpty) {
                        await launchUrl(
                          Uri.parse(paymentUrl),
                          mode: LaunchMode.externalApplication,
                        );
                        if (!context.mounted) return;
                      }
                    }
                    AnalyticsService.instance.track(
                      AnalyticsEvents.checkoutCompleted,
                      properties: {
                        'order_id': orderId,
                        'module_type': moduleType ?? 'mixed',
                        'line_count': moduleItems.length,
                        'item_count': moduleItems.fold<int>(
                          0,
                          (sum, item) => sum + item.quantity,
                        ),
                        'subtotal': subtotal,
                        'shipping': shipping,
                        'tax': tax,
                        'tip': tip,
                        'discount': discount,
                        'total': total,
                        'payment_label': paymentName,
                        'delivery_label':
                            _deliveryOptions[_selectedDeliveryOption].$1,
                      },
                    );
                    if (!context.mounted) return;
                    context.push(
                      '/checkout/success',
                      extra: {
                        'orderId': orderId,
                        'amount': total,
                        'payment': paymentName,
                        'delivery': selectedDeliveryLabel,
                        'moduleName': moduleLabel,
                        'address': selectedAddress == null
                            ? null
                            : '${selectedAddress.address}${selectedAddress.city != null ? ', ${selectedAddress.city}' : ''}',
                        'itemCount': moduleItems.fold<int>(
                          0,
                          (sum, item) => sum + item.quantity,
                        ),
                        'trackingRoute': _trackingRouteForModule(
                          moduleType,
                          orderId,
                        ),
                        'trackingExtra': {
                          'id': orderId,
                          'moduleType': moduleType?.toUpperCase(),
                          'moduleName': moduleLabel,
                          'status': 'PENDING',
                          'subtotal': subtotal,
                          'tax': tax,
                          'deliveryFee': shipping,
                          'discount': discount,
                          'total': total,
                          'createdAt': DateTime.now().toIso8601String(),
                          'paymentLabel': paymentName,
                          if (waafiResult?.referenceId != null)
                            'paymentReference': waafiResult!.referenceId,
                          'deliveryLabel':
                              _deliveryOptions[_selectedDeliveryOption].$1,
                          'deliveryEta':
                              _deliveryOptions[_selectedDeliveryOption].$2,
                          'address': selectedAddress == null
                              ? null
                              : '${selectedAddress.address}${selectedAddress.city != null ? ', ${selectedAddress.city}' : ''}',
                          'items': moduleItems
                              .map(
                                (item) => {
                                  'id': item.id,
                                  'name': item.name,
                                  'brand': item.brand,
                                  'price': item.price,
                                  'quantity': item.quantity,
                                  'total': item.total,
                                  'color': item.color,
                                  'size': item.size,
                                },
                              )
                              .toList(),
                        },
                      },
                    );
                  } finally {
                    if (context.mounted) {
                      setState(() => _isPlacingOrder = false);
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _trackingRouteForModule(String? moduleType, String orderId) {
    switch (moduleType?.toLowerCase()) {
      case 'food':
        return '/food/tracking/$orderId';
      case 'shopping':
        return '/shopping/order/$orderId';
      case 'hotel':
        return '/hotel/order/$orderId';
      case 'pharmacy':
        return '/pharmacy/order/$orderId';
      case 'laundry':
        return '/laundry/tracking/$orderId';
      default:
        return '/orders';
    }
  }
}

class _TimeChip extends StatelessWidget {
  final String label, time, price;
  final bool selected;
  const _TimeChip(this.label, this.time, this.price, this.selected);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: selected ? null : Border.all(color: AppColors.lightGrey),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.white : AppColors.dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white60 : AppColors.grey,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final bool isDiscount;
  const _SumRow(
    this.label,
    this.value, {
    this.bold = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? AppTextStyles.labelLarge
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          Text(
            value,
            style: bold
                ? AppTextStyles.price
                : isDiscount
                ? AppTextStyles.labelMedium.copyWith(color: AppColors.success)
                : AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
