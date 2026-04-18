import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/models/models.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/auth_gate.dart';

class LaundryOrderScreen extends StatefulWidget {
  const LaundryOrderScreen({super.key});
  @override
  State<LaundryOrderScreen> createState() => _LaundryOrderScreenState();
}

class _LaundryOrderScreenState extends State<LaundryOrderScreen> {
  int _selectedService = 0;
  int _selectedDate = 0;
  int _selectedTime = 2;
  final _items = {'Shirts': 3, 'Pants': 2, 'Dresses': 1, 'Jackets': 0};
  List<LaundryService> _services = LaundryModel.sampleServices;
  bool _isLoading = true;

  IconData _getIcon(String id) {
    if (id == 'l1') return Icons.local_laundry_service_rounded;
    if (id == 'l2') return Icons.dry_cleaning_rounded;
    if (id == 'l3') return Icons.iron_rounded;
    return Icons.auto_awesome_rounded;
  }

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final response = await ApiClient.get('/catalog/laundry-services');
      final items = (response as List)
          .map(
            (item) =>
                LaundryService.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _services = items.isEmpty ? LaundryModel.sampleServices : items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final services = _services;
    final selectedModel = services[_selectedService];
    final totalItems = _items.values.fold(0, (a, b) => a + b);
    final estTotal = selectedModel.price * totalItems; // Simplified estimate
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final pickupDates = List.generate(
      5,
      (index) => DateTime.now().add(Duration(days: index)),
    );
    final selectedPickupDate = pickupDates[_selectedDate];
    final selectedDayLabel = DateFormat(
      'EEE',
      localeTag,
    ).format(selectedPickupDate);
    final slots = [
      '08:00 - 10:00',
      '10:00 - 12:00',
      '14:00 - 16:00',
      '16:00 - 18:00',
    ];
    final slotStartHour =
        int.tryParse(slots[_selectedTime].split(':').first.trim()) ?? 8;
    final pickupAt = DateTime(
      selectedPickupDate.year,
      selectedPickupDate.month,
      selectedPickupDate.day,
      slotStartHour,
    );
    final etaAt = pickupAt.add(const Duration(days: 1, hours: 2));
    final defaultAddress = auth.user?.addresses
        .cast<AddressModel?>()
        .firstWhere(
          (address) => address?.isDefault == true,
          orElse: () => auth.user?.addresses.isNotEmpty == true
              ? auth.user!.addresses.first
              : null,
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('laundry_order.title')),
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
            // Service type
            Text(l10n.t('laundry_order.service_type'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            if (_isLoading)
              const AppShimmer(
                child: Row(
                  children: [
                    Expanded(
                      child: ShimmerBlock(
                        width: double.infinity,
                        height: 92,
                        radius: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ShimmerBlock(
                        width: double.infinity,
                        height: 92,
                        radius: 16,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ShimmerBlock(
                        width: double.infinity,
                        height: 92,
                        radius: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: List.generate(services.length, (index) {
                  final s = services[index];
                  if (index > 2) {
                    return const SizedBox.shrink();
                  }
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index < 2 ? 10 : 0),
                      child: _ServiceOption(
                        s.name,
                        _getIcon(s.id),
                        _selectedService == index,
                        () => setState(() => _selectedService = index),
                      ),
                    ),
                  );
                }),
              ),
            const SizedBox(height: 24),
            // Items
            Text(l10n.t('laundry_order.items'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ..._items.entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(e.key, style: AppTextStyles.labelMedium),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.extraLightGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                setState(() {
                                  if (_items[e.key]! > 0) {
                                    _items[e.key] = _items[e.key]! - 1;
                                  }
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${e.value}',
                              style: AppTextStyles.labelLarge,
                            ),
                          ),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                setState(
                                  () => _items[e.key] = _items[e.key]! + 1,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            // Pickup date
            Text(l10n.t('laundry_order.pickup_date'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pickupDates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final sel = _selectedDate == i;
                  final date = pickupDates[i];
                  final dayLabel = DateFormat('EEE', localeTag).format(date);
                  final dateLabel = DateFormat('d', localeTag).format(date);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.laundry : AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: sel
                            ? null
                            : Border.all(color: AppColors.lightGrey),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: sel ? Colors.white60 : AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel,
                            style: AppTextStyles.h4.copyWith(
                              color: sel ? AppColors.white : AppColors.dark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            // Time slot
            Text(l10n.t('laundry_order.time_slot'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(4, (i) {
                final sel = _selectedTime == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.laundry : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: sel
                          ? null
                          : Border.all(color: AppColors.lightGrey),
                    ),
                    child: Text(
                      slots[i],
                      style: AppTextStyles.labelMedium.copyWith(
                        color: sel ? AppColors.white : AppColors.dark,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Address
            Text(
              l10n.t('laundry_order.pickup_address'),
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.laundry,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('ride.home'),
                          style: AppTextStyles.labelMedium,
                        ),
                        Text(
                          defaultAddress?.address ??
                              '123 Main Street, Downtown',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.t('laundry_order.change'),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.laundry,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.laundryBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _Row(l10n.t('laundry_order.service'), selectedModel.name),
                  _Row(
                    l10n.t('laundry_order.items'),
                    l10n.t(
                      'laundry_order.items_count',
                      params: {'count': '$totalItems'},
                    ),
                  ),
                  _Row(
                    l10n.t('laundry_order.pickup'),
                    '$selectedDayLabel, ${DateFormat('MMM d', localeTag).format(selectedPickupDate)} • ${slots[_selectedTime]}',
                  ),
                  const Divider(height: 20),
                  _Row(
                    l10n.t('laundry_order.estimated_total'),
                    '\$${estTotal.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: l10n.t('laundry_order.schedule_pickup'),
              color: AppColors.laundry,
              onPressed: () async {
                final allowed = await requireLoggedIn(
                  context,
                  message: l10n.t('laundry_order.login_required'),
                );
                if (!context.mounted || !allowed) return;
                if (totalItems <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.t('laundry_order.items_required')),
                    ),
                  );
                  return;
                }
                final subtotal = selectedModel.price * totalItems;
                final tax = subtotal * 0.08;
                final total = subtotal + tax;
                AnalyticsService.instance.track(
                  AnalyticsEvents.checkoutPlaceOrderTapped,
                  properties: {
                    'module_type': 'laundry',
                    'service_id': selectedModel.id,
                    'service_name': selectedModel.name,
                    'item_count': totalItems,
                    'subtotal': subtotal,
                    'total': total,
                  },
                );
                try {
                  final pickupLabel =
                      '$selectedDayLabel, ${DateFormat('MMM d', localeTag).format(selectedPickupDate)} • ${slots[_selectedTime]}';
                  final order = await ApiClient.post('/orders', {
                    'userId': auth.user!.id,
                    'moduleType': 'LAUNDRY',
                    'subtotal': subtotal,
                    'tax': tax,
                    'deliveryFee': 0,
                    'total': total,
                    'items': [
                      {
                        'id': selectedModel.id,
                        'name': selectedModel.name,
                        'price': selectedModel.price,
                        'quantity': totalItems,
                        'total': subtotal,
                        'metadata': {
                          'serviceId': selectedModel.id,
                          'serviceName': selectedModel.name,
                          'serviceUnit': selectedModel.unit,
                          'itemCount': totalItems,
                          'timeSlot': slots[_selectedTime],
                          'pickupSlot': slots[_selectedTime],
                          'pickupDay': selectedDayLabel,
                          'pickupDate': DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedPickupDate),
                          'pickupAt': pickupAt.toIso8601String(),
                          'scheduledDate': DateFormat(
                            'MMM d, yyyy',
                            localeTag,
                          ).format(selectedPickupDate),
                          'deliveryLabel': pickupLabel,
                          'deliveryEta': DateFormat(
                            'MMM d, yyyy • HH:mm',
                            localeTag,
                          ).format(etaAt),
                          'address': defaultAddress?.address,
                          'addressId': defaultAddress?.id,
                          'items': _items,
                        },
                      },
                    ],
                  });
                  AnalyticsService.instance.track(
                    AnalyticsEvents.checkoutCompleted,
                    properties: {
                      'module_type': 'laundry',
                      'order_id': order is Map ? order['id']?.toString() : null,
                      'service_id': selectedModel.id,
                      'service_name': selectedModel.name,
                      'item_count': totalItems,
                      'subtotal': subtotal,
                      'tax': tax,
                      'total': total,
                    },
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.t('laundry_order.success')),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  final orderId = order is Map ? order['id']?.toString() : null;
                  if (orderId != null && orderId.isNotEmpty) {
                    context.go('/laundry/tracking/$orderId');
                  } else {
                    context.go('/orders');
                  }
                } catch (e) {
                  AnalyticsService.instance.track(
                    AnalyticsEvents.checkoutValidationFailed,
                    properties: {
                      'module_type': 'laundry',
                      'reason': 'order_submission_failed',
                      'error': e.toString(),
                    },
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.t(
                          'laundry_order.error',
                          params: {'error': ApiClient.userFacingError(e)},
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceOption extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ServiceOption(this.name, this.icon, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.laundry : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: selected ? null : Border.all(color: AppColors.lightGrey),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.white : AppColors.laundry,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: AppTextStyles.labelSmall.copyWith(
                color: selected ? AppColors.white : AppColors.dark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

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
