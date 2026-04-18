import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/contact_launcher.dart';
import '../../../core/utils/message_launcher.dart';

class FoodOrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const FoodOrderTrackingScreen({super.key, required this.orderId});

  @override
  State<FoodOrderTrackingScreen> createState() =>
      _FoodOrderTrackingScreenState();
}

class _FoodOrderTrackingScreenState extends State<FoodOrderTrackingScreen> {
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

  bool _statusReached(String currentStatus, List<String> statuses) {
    return statuses.contains(currentStatus);
  }

  Future<void> _contactCourierByPhone(String? phone) async {
    await launchPhoneCall(context, phone);
  }

  Future<void> _openCourierChat(Map<String, dynamic>? deliveryAssignee) async {
    final l10n = context.l10n;
    final order = _order;
    final courierName = deliveryAssignee?['name']?.toString();
    final moduleName = (order?['moduleName']?.toString() ?? '').trim();
    if (order == null || courierName == null || courierName.isEmpty) {
      showContactUnavailableSnackBar(context);
      return;
    }

    await openConversation(
      context,
      moduleType: order['moduleType']?.toString() ?? 'FOOD',
      entityType: 'DELIVERY',
      entityId: widget.orderId,
      title: courierName,
      subtitle: moduleName.isNotEmpty
          ? moduleName
          : l10n.t('food_tracking.delivery_subtitle'),
      accentColor: '#FF6B35',
      metadata: {
        'orderId': widget.orderId,
        'deliveryUserId': deliveryAssignee?['userId']?.toString(),
        'deliveryPhone': deliveryAssignee?['phone']?.toString(),
        'moduleType': order['moduleType']?.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final order = _order;
    final displayOrderId = widget.orderId.startsWith('#')
        ? widget.orderId
        : '#${widget.orderId}';
    final status = order?['status']?.toString().toUpperCase() ?? 'PENDING';
    final eta =
        order?['deliveryEta']?.toString() ?? l10n.t('food_tracking.default_eta');
    final deliveryAssignee = order?['deliveryAssignee'] is Map
        ? Map<String, dynamic>.from(order!['deliveryAssignee'] as Map)
        : null;
    final courierPhone = deliveryAssignee?['phone']?.toString();
    final courierAssigned =
        deliveryAssignee?['name']?.toString().trim().isNotEmpty == true;
    final items = (order?['items'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/food');
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
                context.go('/food');
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
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
                          colors: [AppColors.food, AppColors.secondaryLight],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.delivery_dining_rounded,
                            color: AppColors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.t('food_tracking.estimated_delivery'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            eta,
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayOrderId,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.white,
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
                          _TimelineStep(
                            l10n.t('food_tracking.order_confirmed'),
                            '',
                            _statusReached(status, const [
                              'CONFIRMED',
                              'PROCESSING',
                              'DISPATCHED',
                              'IN_PROGRESS',
                              'COMPLETED',
                            ]),
                            status == 'CONFIRMED',
                          ),
                          _TimelineStep(
                            l10n.t('food_tracking.preparing'),
                            '',
                            _statusReached(status, const [
                              'PROCESSING',
                              'DISPATCHED',
                              'IN_PROGRESS',
                              'COMPLETED',
                            ]),
                            status == 'PROCESSING',
                          ),
                          _TimelineStep(
                            l10n.t('food_tracking.on_the_way'),
                            '',
                            _statusReached(status, const [
                              'DISPATCHED',
                              'IN_PROGRESS',
                              'COMPLETED',
                            ]),
                            status == 'DISPATCHED' || status == 'IN_PROGRESS',
                          ),
                          _TimelineStep(
                            l10n.t('food_tracking.delivered'),
                            '',
                            status == 'COMPLETED',
                            status == 'COMPLETED',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deliveryAssignee?['name']?.toString() ??
                                      l10n.t('food_tracking.courier_pending'),
                                  style: AppTextStyles.labelLarge,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      deliveryAssignee == null
                                          ? l10n.t(
                                              'food_tracking.waiting_assignment',
                                            )
                                          : '4.9 • ${l10n.t('food_tracking.rider')}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ContactActionIcon(
                                icon: Icons.chat_rounded,
                                iconColor: AppColors.food,
                                backgroundColor: AppColors.food.withValues(
                                  alpha: 0.12,
                                ),
                                enabled: courierAssigned,
                                onTap: () => _openCourierChat(deliveryAssignee),
                              ),
                              const SizedBox(width: 8),
                              _ContactActionIcon(
                                icon: Icons.phone_rounded,
                                iconColor: AppColors.success,
                                backgroundColor: AppColors.successLight,
                                enabled:
                                    courierPhone != null &&
                                    courierPhone.trim().isNotEmpty,
                                onTap: () =>
                                    _contactCourierByPhone(courierPhone),
                              ),
                            ],
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
                            l10n.t('food_tracking.order_details'),
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: 12),
                          ...items.map(
                            (item) => _OrderRow(
                              '${item['quantity']}x ${item['name']}',
                              '\$${((item['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                            ),
                          ),
                          const Divider(height: 20),
                          _OrderRow(
                            l10n.t('food_tracking.total'),
                            '\$${((order?['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
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

class _ContactActionIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final bool enabled;
  final VoidCallback onTap;

  const _ContactActionIcon({
    required this.icon,
    required this.iconColor,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String time;
  final bool isDone;
  final bool isActive;

  const _TimelineStep(this.title, this.time, this.isDone, this.isActive);

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
                    : (isActive ? AppColors.food : AppColors.extraLightGrey),
                shape: BoxShape.circle,
              ),
              child: isDone
                  ? const Icon(Icons.check, color: AppColors.white, size: 16)
                  : isActive
                  ? const Icon(
                      Icons.delivery_dining_rounded,
                      color: AppColors.white,
                      size: 16,
                    )
                  : null,
            ),
            if (title !=
                AppLocalizations.of(context).t('food_tracking.delivered'))
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

class _OrderRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _OrderRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
          ),
          Text(
            value,
            style: bold ? AppTextStyles.priceSmall : AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
