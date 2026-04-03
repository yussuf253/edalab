import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/utils/message_launcher.dart';
import '../../../core/widgets/app_shimmer.dart';

class PharmacyOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic>? order;

  const PharmacyOrderDetailScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  State<PharmacyOrderDetailScreen> createState() =>
      _PharmacyOrderDetailScreenState();
}

class _PharmacyOrderDetailScreenState extends State<PharmacyOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _isLoading = widget.order == null;
    _loadOrder();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadOrder(forceRefresh: true);
    });
  }

  Future<void> _loadOrder({bool forceRefresh = true}) async {
    try {
      final response = await ApiClient.get(
        '/orders/detail/${widget.orderId}',
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _order = Map<String, dynamic>.from(response as Map);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openCourierChat(Map<String, dynamic>? courier) async {
    final order = _order;
    final courierName = courier?['name']?.toString();
    final moduleName = (order?['moduleName']?.toString() ?? '').trim();
    if (order == null || courierName == null || courierName.isEmpty) {
      showContactUnavailableSnackBar(context);
      return;
    }

    await openConversation(
      context,
      moduleType: order['moduleType']?.toString() ?? 'PHARMACY',
      entityType: 'DELIVERY',
      entityId: widget.orderId,
      title: courierName,
      subtitle: moduleName.isNotEmpty ? moduleName : 'Pharmacy delivery',
      accentColor: '#27AE60',
      metadata: {
        'orderId': widget.orderId,
        'deliveryUserId': courier?['userId']?.toString(),
        'deliveryPhone': courier?['phone']?.toString(),
        'moduleType': order['moduleType']?.toString(),
      },
    );
  }

  Future<void> _callCourier(String? phone) async {
    await launchPhoneCall(context, phone);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _order ?? const <String, dynamic>{};
    final items = (data['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final medicineCount = items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );
    final courier = data['deliveryAssignee'] is Map
        ? Map<String, dynamic>.from(data['deliveryAssignee'] as Map)
        : null;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/pharmacy');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('pharmacy_tracking.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/pharmacy');
              }
            },
          ),
        ),
        body: _isLoading
            ? const DetailContentShimmer(
                accentColor: AppColors.pharmacy,
                showHero: false,
              )
            : _order == null
            ? const _MissingPharmacyState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PharmacyHero(
                      title:
                          data['moduleName']?.toString() ??
                          l10n.t('pharmacy_tracking.default_title'),
                      status: _pretty(data['status']?.toString()),
                      medicineCount: medicineCount,
                      total: ((data['total'] as num?)?.toDouble() ?? 0),
                    ),
                    const SizedBox(height: 16),
                    _FulfillmentCard(
                      placedAt: _formatDate(data['createdAt']?.toString()),
                      delivery:
                          data['deliveryEta']?.toString() ??
                          data['deliveryLabel']?.toString() ??
                          l10n.t('pharmacy_tracking.preparing_medicines'),
                      payment:
                          data['paymentLabel']?.toString() ??
                          l10n.t('pharmacy_tracking.payment_confirmed'),
                    ),
                    if (courier != null) ...[
                      const SizedBox(height: 14),
                      _PharmacySection(
                        title: l10n.t('food_tracking.rider'),
                        child: _CourierRow(
                          name:
                              courier['name']?.toString() ?? 'Assigned courier',
                          phone: courier['phone']?.toString(),
                          onChatTap: () => _openCourierChat(courier),
                          onCallTap: () =>
                              _callCourier(courier['phone']?.toString()),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _PharmacySection(
                      title: l10n.t('pharmacy_tracking.medicines_title'),
                      child: Column(
                        children: items.isEmpty
                            ? const [_PharmacyEmpty()]
                            : items
                                  .map(
                                    (item) => _MedicineLine(
                                      name:
                                          item['name']?.toString() ??
                                          'Medicine',
                                      brand: item['brand']?.toString(),
                                      quantity:
                                          (item['quantity'] as num?)?.toInt() ??
                                          1,
                                      total:
                                          ((item['total'] as num?)
                                                      ?.toDouble() ??
                                                  (item['price'] as num?)
                                                      ?.toDouble() ??
                                                  0)
                                              .toStringAsFixed(2),
                                    ),
                                  )
                                  .toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF4),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.pharmacy.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
                              color: AppColors.pharmacy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('pharmacy_tracking.care_title'),
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: AppColors.pharmacy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.t('pharmacy_tracking.care_subtitle'),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.grey,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CourierRow extends StatelessWidget {
  final String name;
  final String? phone;
  final VoidCallback onChatTap;
  final VoidCallback onCallTap;

  const _CourierRow({
    required this.name,
    required this.phone,
    required this.onChatTap,
    required this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.pharmacy.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person_rounded, color: AppColors.pharmacy),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.labelLarge),
              const SizedBox(height: 4),
              Text(
                phone == null || phone!.isEmpty
                    ? 'Contact details pending'
                    : phone!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _PharmacyActionIcon(
          icon: Icons.chat_rounded,
          color: AppColors.pharmacy,
          backgroundColor: AppColors.pharmacy.withValues(alpha: 0.10),
          enabled: true,
          onTap: onChatTap,
        ),
        const SizedBox(width: 8),
        _PharmacyActionIcon(
          icon: Icons.phone_rounded,
          color: AppColors.success,
          backgroundColor: AppColors.successLight,
          enabled: phone != null && phone!.trim().isNotEmpty,
          onTap: onCallTap,
        ),
      ],
    );
  }
}

class _PharmacyActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool enabled;
  final VoidCallback onTap;

  const _PharmacyActionIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _PharmacyHero extends StatelessWidget {
  final String title;
  final String status;
  final int medicineCount;
  final double total;

  const _PharmacyHero({
    required this.title,
    required this.status,
    required this.medicineCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pharmacy,
            AppColors.pharmacy.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.white)),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).t(
              'pharmacy_tracking.medicine_items',
              params: {
                'count': '$medicineCount',
                'suffix': medicineCount == 1 ? '' : 's',
              },
            ),
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).t(
              'pharmacy_tracking.total',
              params: {'amount': total.toStringAsFixed(2)},
            ),
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _FulfillmentCard extends StatelessWidget {
  final String placedAt;
  final String delivery;
  final String payment;

  const _FulfillmentCard({
    required this.placedAt,
    required this.delivery,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        children: [
          _FulfillmentRow(
            icon: Icons.schedule_rounded,
            label: AppLocalizations.of(context).t('tracking.placed'),
            value: placedAt,
          ),
          const SizedBox(height: 12),
          _FulfillmentRow(
            icon: Icons.delivery_dining_rounded,
            label: AppLocalizations.of(context).t('tracking.delivery'),
            value: delivery,
          ),
          const SizedBox(height: 12),
          _FulfillmentRow(
            icon: Icons.payments_outlined,
            label: AppLocalizations.of(context).t('checkout.payment_method'),
            value: payment,
          ),
        ],
      ),
    );
  }
}

class _FulfillmentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FulfillmentRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.pharmacy.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.pharmacy, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 4),
              Text(value, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _PharmacySection extends StatelessWidget {
  final String title;
  final Widget child;

  const _PharmacySection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MedicineLine extends StatelessWidget {
  final String name;
  final String? brand;
  final int quantity;
  final String total;

  const _MedicineLine({
    required this.name,
    this.brand,
    required this.quantity,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.pharmacy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: AppColors.pharmacy,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelLarge),
                if (brand != null && brand!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    brand!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Qty $quantity',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('\$$total', style: AppTextStyles.labelLarge),
        ],
      ),
    );
  }
}

class _PharmacyEmpty extends StatelessWidget {
  const _PharmacyEmpty();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).t('tracking.no_items_title'),
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
    );
  }
}

class _MissingPharmacyState extends StatelessWidget {
  const _MissingPharmacyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: () => context.go('/pharmacy'),
        child: Text(AppLocalizations.of(context).t('module.pharmacy')),
      ),
    );
  }
}

String _formatDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return raw;
  return DateFormat('dd MMM yyyy • HH:mm').format(parsed);
}

String _pretty(String? raw) =>
    (raw == null || raw.isEmpty) ? 'Pending' : raw.replaceAll('_', ' ');
