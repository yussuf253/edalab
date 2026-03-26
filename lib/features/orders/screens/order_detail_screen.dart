import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

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
        title: Text(_screenTitle(module)),
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
                    _title(data, firstItem),
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
              title: 'Summary',
              child: Column(
                children: [
                  _Row('Status', _pretty(data['status']?.toString() ?? 'Pending')),
                  _Row('Amount', _money((data['total'] as num?)?.toDouble() ?? 0)),
                  _Row('Placed', _formatDate(data['createdAt']?.toString())),
                  if (items.isNotEmpty)
                    _Row(
                      'Items',
                      '${items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0))}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              title: 'Details',
              child: Column(
                children: _detailRows(module, metadata, firstItem),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _screenTitle(String module) {
    switch (module) {
      case 'HOTEL':
        return 'Booking Details';
      case 'SHOPPING':
        return 'Order Details';
      case 'PHARMACY':
        return 'Pharmacy Order';
      default:
        return 'Order Details';
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

  String _title(Map<String, dynamic> data, Map<String, dynamic>? firstItem) {
    return firstItem?['name']?.toString() ??
        data['moduleName']?.toString() ??
        'Order';
  }

  List<Widget> _detailRows(
    String module,
    Map<String, dynamic> metadata,
    Map<String, dynamic>? firstItem,
  ) {
    switch (module) {
      case 'HOTEL':
        return [
          _Row('Room', firstItem?['name']?.toString() ?? 'Room'),
          _Row('Check-in', _formatDate(metadata['checkInAt']?.toString() ?? metadata['checkIn']?.toString())),
          _Row('Check-out', _formatDate(metadata['checkOutAt']?.toString() ?? metadata['checkOut']?.toString())),
          _Row('Guests', metadata['guestCount']?.toString() ?? metadata['guests']?.toString() ?? '1'),
        ];
      case 'SHOPPING':
      case 'PHARMACY':
        return [
          _Row('Product', firstItem?['name']?.toString() ?? 'Item'),
          _Row('Brand', firstItem?['brand']?.toString() ?? '-'),
          _Row('Quantity', firstItem?['quantity']?.toString() ?? '1'),
          if ((firstItem?['size']?.toString() ?? '').isNotEmpty)
            _Row('Size', firstItem!['size'].toString()),
          if ((firstItem?['color']?.toString() ?? '').isNotEmpty)
            _Row('Color', firstItem!['color'].toString()),
        ];
      default:
        return [
          _Row('Item', firstItem?['name']?.toString() ?? 'Order'),
        ];
    }
  }

  String _pretty(String value) => value.replaceAll('_', ' ');

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
