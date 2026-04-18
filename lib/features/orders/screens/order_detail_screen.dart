import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic>? order;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.order,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = order ?? const <String, dynamic>{};
    final module = data['moduleType']?.toString().toUpperCase() ?? 'ORDER';
    final items = (data['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final firstItem = items.isNotEmpty ? items.first : null;
    final metadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_screenTitle(module, l10n)),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_moduleColor(module), _moduleColor(module).withValues(alpha: 0.78)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _moduleIcon(module),
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _title(data, firstItem, l10n),
                    style: AppTextStyles.h3.copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['moduleName']?.toString() ?? module,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _Card(
              title: l10n.t('order_detail.summary'),
              child: Column(
                children: [
                  _Row(
                    l10n.t('order_detail.status'),
                    _localizedStatusLabel(
                      l10n,
                      data['status']?.toString() ?? 'PENDING',
                    ),
                  ),
                  _Row(
                    l10n.t('order_detail.amount'),
                    _money((data['total'] as num?)?.toDouble() ?? 0),
                  ),
                  _Row(
                    l10n.t('order_detail.placed'),
                    _formatDate(data['createdAt']?.toString()),
                  ),
                  if (items.isNotEmpty)
                    _Row(
                      l10n.t('order_detail.items'),
                      '${items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0))}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              title: l10n.t('order_detail.details'),
              child: Column(
                children: _detailRows(module, metadata, firstItem, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _screenTitle(String module, AppLocalizations l10n) {
    switch (module) {
      case 'HOTEL':
        return l10n.t('order_detail.booking_details');
      case 'SHOPPING':
        return l10n.t('order_detail.order_details');
      case 'PHARMACY':
        return l10n.t('order_detail.pharmacy_order');
      default:
        return l10n.t('order_detail.order_details');
    }
  }

  IconData _moduleIcon(String module) {
    switch (module) {
      case 'SHOPPING':
        return Icons.shopping_bag_rounded;
      case 'HOTEL':
        return Icons.hotel_rounded;
      case 'PHARMACY':
        return Icons.local_pharmacy_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _moduleColor(String module) {
    switch (module) {
      case 'SHOPPING':
        return AppColors.shopping;
      case 'HOTEL':
        return AppColors.hotel;
      case 'PHARMACY':
        return AppColors.pharmacy;
      default:
        return AppColors.primary;
    }
  }

  String _title(
    Map<String, dynamic> data,
    Map<String, dynamic>? firstItem,
    AppLocalizations l10n,
  ) {
    return firstItem?['name']?.toString() ??
        data['moduleName']?.toString() ??
        l10n.t('orders.order');
  }

  List<Widget> _detailRows(
    String module,
    Map<String, dynamic> metadata,
    Map<String, dynamic>? firstItem,
    AppLocalizations l10n,
  ) {
    switch (module) {
      case 'HOTEL':
        return [
          _Row(
            l10n.t('order_detail.room'),
            firstItem?['name']?.toString() ?? l10n.t('order_detail.room'),
          ),
          _Row(
            l10n.t('order_detail.check_in'),
            _formatDate(
              metadata['checkInAt']?.toString() ?? metadata['checkIn']?.toString(),
            ),
          ),
          _Row(
            l10n.t('order_detail.check_out'),
            _formatDate(
              metadata['checkOutAt']?.toString() ?? metadata['checkOut']?.toString(),
            ),
          ),
          _Row(
            l10n.t('order_detail.guests'),
            metadata['guestCount']?.toString() ?? metadata['guests']?.toString() ?? '1',
          ),
        ];
      case 'SHOPPING':
      case 'PHARMACY':
        return [
          _Row(
            l10n.t('order_detail.product'),
            firstItem?['name']?.toString() ?? l10n.t('order_detail.item'),
          ),
          _Row(
            l10n.t('order_detail.brand'),
            firstItem?['brand']?.toString() ?? '-',
          ),
          _Row(
            l10n.t('order_detail.quantity'),
            firstItem?['quantity']?.toString() ?? '1',
          ),
          if ((firstItem?['size']?.toString() ?? '').isNotEmpty)
            _Row(l10n.t('order_detail.size'), firstItem!['size'].toString()),
          if ((firstItem?['color']?.toString() ?? '').isNotEmpty)
            _Row(l10n.t('order_detail.color'), firstItem!['color'].toString()),
        ];
      default:
        return [
          _Row(
            l10n.t('order_detail.item'),
            firstItem?['name']?.toString() ?? l10n.t('orders.order'),
          ),
        ];
    }
  }

  String _localizedStatusLabel(AppLocalizations l10n, String rawStatus) {
    switch (rawStatus.toUpperCase()) {
      case 'PENDING':
        return l10n.t('tracking.status_pending');
      case 'CONFIRMED':
      case 'SCHEDULED':
        return l10n.t('tracking.status_confirmed');
      case 'PROCESSING':
      case 'CLEANING':
      case 'PICKED_UP':
        return l10n.t('tracking.status_processing');
      case 'DISPATCHED':
      case 'OUT_FOR_DELIVERY':
        return l10n.t('tracking.status_dispatched');
      case 'IN_PROGRESS':
        return l10n.t('tracking.status_in_progress');
      case 'COMPLETED':
      case 'DELIVERED':
        return l10n.t('tracking.status_completed');
      case 'CANCELLED':
      case 'REFUNDED':
        return l10n.t('tracking.status_cancelled');
      default:
        return l10n.t('tracking.status_unknown');
    }
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy').format(parsed);
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

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

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.labelMedium)),
        ],
      ),
    );
  }
}
