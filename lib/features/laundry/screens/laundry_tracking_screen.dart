import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_shimmer.dart';

class LaundryTrackingScreen extends StatefulWidget {
  final String orderId;

  const LaundryTrackingScreen({super.key, required this.orderId});

  @override
  State<LaundryTrackingScreen> createState() => _LaundryTrackingScreenState();
}

class _LaundryTrackingScreenState extends State<LaundryTrackingScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
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
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ApiClient.userFacingError(error);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _normalizedStatus(String value) {
    switch (value.toUpperCase()) {
      case 'SCHEDULED':
        return 'CONFIRMED';
      case 'PICKED_UP':
      case 'CLEANING':
        return 'PROCESSING';
      case 'OUT_FOR_DELIVERY':
        return 'IN_PROGRESS';
      default:
        return value.toUpperCase();
    }
  }

  int _statusProgressIndex(String status) {
    switch (_normalizedStatus(status)) {
      case 'PENDING':
        return 0;
      case 'CONFIRMED':
        return 1;
      case 'PROCESSING':
        return 2;
      case 'DISPATCHED':
        return 3;
      case 'IN_PROGRESS':
        return 4;
      case 'COMPLETED':
        return 5;
      default:
        return 0;
    }
  }

  String _formatDateLabel(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy • HH:mm').format(parsed.toLocal());
  }

  String _itemSummary(Map<String, dynamic>? firstItem) {
    final l10n = context.l10n;
    final metadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : const <String, dynamic>{};
    final count = (metadata['itemCount'] as num?)?.toInt() ?? 0;
    if (count > 0) {
      return l10n.t(
        'orders.item_count',
        params: {'count': '$count', 'suffix': count > 1 ? 's' : ''},
      );
    }
    final quantity = (firstItem?['quantity'] as num?)?.toInt() ?? 1;
    return l10n.t(
      'orders.item_count',
      params: {'count': '$quantity', 'suffix': quantity > 1 ? 's' : ''},
    );
  }

  String _localizedStatusLabel(AppLocalizations l10n, String status) {
    switch (_normalizedStatus(status)) {
      case 'PENDING':
        return l10n.t('tracking.status_pending');
      case 'CONFIRMED':
        return l10n.t('tracking.status_confirmed');
      case 'PROCESSING':
        return l10n.t('tracking.status_processing');
      case 'DISPATCHED':
        return l10n.t('tracking.status_dispatched');
      case 'IN_PROGRESS':
        return l10n.t('tracking.status_in_progress');
      case 'COMPLETED':
        return l10n.t('tracking.status_completed');
      case 'CANCELLED':
        return l10n.t('tracking.status_cancelled');
      default:
        return l10n.t('tracking.status_unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = _order;
    final status = _normalizedStatus(
      order?['status']?.toString().toUpperCase() ?? 'PENDING',
    );
    final progressIndex = _statusProgressIndex(status);
    final items = (order?['items'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final firstItem = items.isNotEmpty ? items.first : null;
    final firstMetadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : const <String, dynamic>{};
    final pickupLabel =
        order?['deliveryLabel']?.toString() ??
        firstMetadata['deliveryLabel']?.toString() ??
        firstMetadata['scheduledDate']?.toString() ??
        firstMetadata['pickupAt']?.toString() ??
        order?['createdAt']?.toString() ??
        '-';
    final deliveryEta =
        order?['deliveryEta']?.toString() ??
        firstMetadata['deliveryEta']?.toString() ??
        '-';

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/laundry');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('tracking.order_tracking')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/laundry');
              }
            },
          ),
        ),
        body: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: AppShimmer(
                  child: Column(
                    children: [
                      ShimmerBlock(
                        width: double.infinity,
                        height: 180,
                        radius: 20,
                      ),
                      SizedBox(height: 16),
                      ShimmerBlock(
                        width: double.infinity,
                        height: 230,
                        radius: 16,
                      ),
                      SizedBox(height: 16),
                      ShimmerBlock(
                        width: double.infinity,
                        height: 180,
                        radius: 16,
                      ),
                    ],
                  ),
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _loadOrder(forceRefresh: true),
                        child: Text(l10n.t('tracking.retry')),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.laundry, AppColors.secondaryLight],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_laundry_service_rounded,
                            color: AppColors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.t('laundry_tracking.status'),
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _localizedStatusLabel(l10n, status),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Column(
                        children: [
                          _Step(
                            l10n.t('laundry_tracking.pickup_confirmed'),
                            '',
                            progressIndex >= 1,
                            progressIndex <= 1,
                          ),
                          _Step(
                            l10n.t('laundry_tracking.picked_up'),
                            '',
                            progressIndex >= 2,
                            progressIndex == 2,
                          ),
                          _Step(
                            l10n.t('laundry_tracking.cleaning'),
                            '',
                            progressIndex >= 3,
                            progressIndex == 3,
                          ),
                          _Step(
                            l10n.t('laundry_tracking.ready_for_delivery'),
                            '',
                            progressIndex >= 4,
                            progressIndex == 4,
                          ),
                          _Step(
                            l10n.t('laundry_tracking.delivered'),
                            '',
                            progressIndex >= 5,
                            progressIndex == 5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('laundry_tracking.order_details'),
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            l10n.t('laundry_tracking.order_number'),
                            widget.orderId,
                          ),
                          _DetailRow(
                            l10n.t('laundry_tracking.service'),
                            order?['moduleName']?.toString() ??
                                l10n.t('laundry_tracking.service_default'),
                          ),
                          _DetailRow(
                            l10n.t('laundry_tracking.items'),
                            _itemSummary(firstItem),
                          ),
                          _DetailRow(
                            l10n.t('laundry_tracking.pickup'),
                            _formatDateLabel(pickupLabel),
                          ),
                          _DetailRow(
                            l10n.t('tracking.delivery'),
                            _formatDateLabel(deliveryEta),
                          ),
                          const Divider(height: 20),
                          _DetailRow(
                            l10n.t('laundry_tracking.total'),
                            'DJF${((order?['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                            bold: true,
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

class _Step extends StatelessWidget {
  final String title;
  final String time;
  final bool isDone;
  final bool isActive;

  const _Step(this.title, this.time, this.isDone, this.isActive);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.success
                    : (isActive ? AppColors.laundry : AppColors.extraLightGrey),
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: AppColors.white, size: 16)
                  : isActive
                  ? const Icon(
                      Icons.local_laundry_service_rounded,
                      color: AppColors.white,
                      size: 14,
                    )
                  : null,
            ),
            if (title !=
                AppLocalizations.of(context).t('laundry_tracking.delivered'))
              Container(
                width: 2,
                height: 32,
                color: isDone ? AppColors.success : AppColors.extraLightGrey,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDone || isActive
                        ? AppColors.dark
                        : AppColors.mediumGrey,
                  ),
                ),
                if (time.isNotEmpty) Text(time, style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? AppTextStyles.labelLarge
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: bold
                  ? AppTextStyles.priceSmall.copyWith(color: AppColors.laundry)
                  : AppTextStyles.labelMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
