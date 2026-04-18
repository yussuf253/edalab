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
  String? _selectedTimeSlot;
  Map<String, int> _itemCounts = <String, int>{};
  List<LaundryService> _services = LaundryModel.sampleServices;
  bool _isLoading = true;

  IconData _getIcon(LaundryService _) {
    return Icons.local_laundry_service_rounded;
  }

  List<LaundryServiceItemConfig> _bookableItemsFor(LaundryService service) {
    return service.bookingConfig.itemCatalog;
  }

  List<String> _pickupSlotsFor(LaundryService service) {
    return service.bookingConfig.pickupSlots;
  }

  void _syncServiceState({bool resetDate = false}) {
    if (_services.isEmpty) return;
    if (_selectedService < 0 || _selectedService >= _services.length) {
      _selectedService = 0;
    }
    if (resetDate) {
      _selectedDate = 0;
    }
    final service = _services[_selectedService];
    final items = _bookableItemsFor(service);
    final nextCounts = <String, int>{};
    for (final item in items) {
      nextCounts[item.id] = _itemCounts[item.id] ?? 0;
    }
    _itemCounts = nextCounts;

    final slots = _pickupSlotsFor(service);
    if (slots.isEmpty) {
      _selectedTimeSlot = null;
      return;
    }
    if (_selectedTimeSlot == null || !slots.contains(_selectedTimeSlot)) {
      _selectedTimeSlot = slots.length > 2 ? slots[2] : slots.first;
    }
  }

  int _slotStartHour(String slot) {
    final match = RegExp(r'^(\d{1,2})\s*:\s*(\d{2})').firstMatch(slot.trim());
    if (match == null) return 8;
    return int.tryParse(match.group(1) ?? '') ?? 8;
  }

  int _slotStartMinute(String slot) {
    final match = RegExp(r'^(\d{1,2})\s*:\s*(\d{2})').firstMatch(slot.trim());
    if (match == null) return 0;
    return int.tryParse(match.group(2) ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _syncServiceState();
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
        _syncServiceState(resetDate: true);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _itemLabel(String key, String fallbackLabel, AppLocalizations l10n) {
    if (fallbackLabel.trim().isNotEmpty &&
        !{'shirts', 'pants', 'dresses', 'jackets'}.contains(key)) {
      return fallbackLabel;
    }
    switch (key) {
      case 'shirts':
        return l10n.t('laundry_order.item_shirts');
      case 'pants':
        return l10n.t('laundry_order.item_pants');
      case 'dresses':
        return l10n.t('laundry_order.item_dresses');
      case 'jackets':
        return l10n.t('laundry_order.item_jackets');
      default:
        return fallbackLabel.trim().isNotEmpty ? fallbackLabel : key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = context.watch<AuthProvider>();
    final services = _services;
    final selectedIndex = _selectedService.clamp(0, services.length - 1);
    final selectedModel = services[selectedIndex];
    final itemOptions = _bookableItemsFor(selectedModel);
    final totalItems = itemOptions.fold<int>(
      0,
      (sum, item) => sum + (_itemCounts[item.id] ?? 0),
    );
    final estSubtotal = itemOptions.fold<double>(
      0,
      (sum, item) => sum + ((_itemCounts[item.id] ?? 0) * item.price),
    );
    final taxRatePercent = selectedModel.bookingConfig.taxRatePercent;
    final estDeliveryFee = selectedModel.bookingConfig.deliveryFee;
    final estTax = estSubtotal * (taxRatePercent / 100);
    final estTotal = estSubtotal + estTax + estDeliveryFee;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final minNoticeHours = selectedModel.bookingConfig.minNoticeHours;
    final maxAdvanceDays = selectedModel.bookingConfig.maxAdvanceDays;
    final firstEligibleMoment = DateTime.now().add(
      Duration(hours: minNoticeHours),
    );
    final firstEligibleDate = DateTime(
      firstEligibleMoment.year,
      firstEligibleMoment.month,
      firstEligibleMoment.day,
    );
    final pickupDates = List.generate(
      maxAdvanceDays,
      (index) => firstEligibleDate.add(Duration(days: index)),
    );
    final selectedDateIndex = _selectedDate.clamp(0, pickupDates.length - 1);
    final selectedPickupDate = pickupDates[selectedDateIndex];
    final selectedDayLabel = DateFormat(
      'EEE',
      localeTag,
    ).format(selectedPickupDate);
    final allSlots = _pickupSlotsFor(selectedModel);
    final availableSlots = selectedPickupDate == firstEligibleDate
        ? allSlots
              .where((slot) {
                final startTime = DateTime(
                  selectedPickupDate.year,
                  selectedPickupDate.month,
                  selectedPickupDate.day,
                  _slotStartHour(slot),
                  _slotStartMinute(slot),
                );
                return !startTime.isBefore(firstEligibleMoment);
              })
              .toList(growable: false)
        : allSlots;
    final slots = availableSlots.isNotEmpty ? availableSlots : allSlots;
    final selectedSlot =
        (_selectedTimeSlot != null && slots.contains(_selectedTimeSlot))
        ? _selectedTimeSlot!
        : (slots.isNotEmpty ? slots.first : '08:00 - 10:00');
    final slotStartHour = _slotStartHour(selectedSlot);
    final slotStartMinute = _slotStartMinute(selectedSlot);
    final pickupAt = DateTime(
      selectedPickupDate.year,
      selectedPickupDate.month,
      selectedPickupDate.day,
      slotStartHour,
      slotStartMinute,
    );
    final etaAt = pickupAt.add(
      Duration(hours: selectedModel.bookingConfig.turnaroundHours),
    );
    final defaultAddress = auth.user?.addresses
        .cast<AddressModel?>()
        .firstWhere(
          (address) => address?.isDefault == true,
          orElse: () => auth.user?.addresses.isNotEmpty == true
              ? auth.user!.addresses.first
              : null,
        );
    final addressLabel = (defaultAddress?.label.trim().isNotEmpty ?? false)
        ? defaultAddress!.label.trim()
        : l10n.t('laundry_order.pickup_address');
    final addressParts = <String>[
      defaultAddress?.address ?? '',
      defaultAddress?.quartier ?? '',
      defaultAddress?.city ?? '',
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
    final fullAddress = addressParts.isNotEmpty
        ? addressParts.join(', ')
        : l10n.t('laundry_order.address_placeholder');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('laundry_order.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const _LaundryOrderShimmer()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service type
                  Text(
                    l10n.t('laundry_order.service_type'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 98,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: services.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final s = services[index];
                        return SizedBox(
                          width: 130,
                          child: _ServiceOption(
                            s.name,
                            _getIcon(s),
                            selectedIndex == index,
                            () => setState(() {
                              _selectedService = index;
                              _syncServiceState(resetDate: true);
                            }),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Items
                  Text(l10n.t('laundry_order.items'), style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  ...itemOptions.map((item) {
                    final count = _itemCounts[item.id] ?? 0;
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
                          Text(
                            _itemLabel(item.id, item.label, l10n),
                            style: AppTextStyles.labelMedium,
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Text(
                              '\$${item.price.toStringAsFixed(2)}',
                              style: AppTextStyles.caption,
                            ),
                          ),
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
                                        if ((_itemCounts[item.id] ?? 0) > 0) {
                                          _itemCounts[item.id] =
                                              (_itemCounts[item.id] ?? 0) - 1;
                                        }
                                      });
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '$count',
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
                                      setState(() {
                                        _itemCounts[item.id] =
                                            (_itemCounts[item.id] ?? 0) + 1;
                                      });
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
                  Text(
                    l10n.t('laundry_order.pickup_date'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pickupDates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final sel = selectedDateIndex == i;
                        final date = pickupDates[i];
                        final dayLabel = DateFormat(
                          'EEE',
                          localeTag,
                        ).format(date);
                        final dateLabel = DateFormat(
                          'd',
                          localeTag,
                        ).format(date);
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
                                    color: sel
                                        ? Colors.white60
                                        : AppColors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateLabel,
                                  style: AppTextStyles.h4.copyWith(
                                    color: sel
                                        ? AppColors.white
                                        : AppColors.dark,
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
                  Text(
                    l10n.t('laundry_order.time_slot'),
                    style: AppTextStyles.h4,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: slots
                        .map((slot) {
                          final sel = selectedSlot == slot;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedTimeSlot = slot),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.laundry
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: sel
                                    ? null
                                    : Border.all(color: AppColors.lightGrey),
                              ),
                              child: Text(
                                slot,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: sel ? AppColors.white : AppColors.dark,
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
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
                                addressLabel,
                                style: AppTextStyles.labelMedium,
                              ),
                              Text(fullAddress, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await context.push('/profile/addresses');
                            if (!mounted) return;
                            setState(() {});
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.t('laundry_order.change'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.laundry,
                            ),
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
                        _Row(
                          l10n.t('laundry_order.service'),
                          selectedModel.name,
                        ),
                        _Row(
                          l10n.t('laundry_order.items'),
                          l10n.t(
                            'laundry_order.items_count',
                            params: {'count': '$totalItems'},
                          ),
                        ),
                        _Row(
                          l10n.t('laundry_order.pickup'),
                          '$selectedDayLabel, ${DateFormat('MMM d', localeTag).format(selectedPickupDate)} • $selectedSlot',
                        ),
                        _Row(
                          l10n.t('laundry_order.delivery_fee'),
                          '\$${estDeliveryFee.toStringAsFixed(2)}',
                        ),
                        _Row(
                          l10n.t(
                            'laundry_order.tax',
                            params: {'rate': taxRatePercent.toStringAsFixed(2)},
                          ),
                          '\$${estTax.toStringAsFixed(2)}',
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
                            content: Text(
                              l10n.t('laundry_order.items_required'),
                            ),
                          ),
                        );
                        return;
                      }
                      final subtotal = estSubtotal;
                      final deliveryFee = estDeliveryFee;
                      final tax = estTax;
                      final total = estTotal;
                      AnalyticsService.instance.track(
                        AnalyticsEvents.checkoutPlaceOrderTapped,
                        properties: {
                          'module_type': 'laundry',
                          'service_id': selectedModel.id,
                          'service_name': selectedModel.name,
                          'item_count': totalItems,
                          'subtotal': subtotal,
                          'tax_rate_percent': taxRatePercent,
                          'delivery_fee': deliveryFee,
                          'total': total,
                        },
                      );
                      try {
                        final pickupLabel =
                            '$selectedDayLabel, ${DateFormat('MMM d', localeTag).format(selectedPickupDate)} • $selectedSlot';
                        final order = await ApiClient.post('/orders', {
                          'userId': auth.user!.id,
                          'moduleType': 'LAUNDRY',
                          'subtotal': subtotal,
                          'tax': tax,
                          'deliveryFee': deliveryFee,
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
                                'timeSlot': selectedSlot,
                                'pickupSlot': selectedSlot,
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
                                'address': fullAddress,
                                'addressLabel': addressLabel,
                                'addressId': defaultAddress?.id,
                                'taxRatePercent': taxRatePercent,
                                'deliveryFee': deliveryFee,
                                'items': {
                                  for (final entry in itemOptions)
                                    entry.id: _itemCounts[entry.id] ?? 0,
                                },
                                'itemPricing': itemOptions
                                    .map(
                                      (entry) => {
                                        'id': entry.id,
                                        'label': entry.label,
                                        'price': entry.price,
                                      },
                                    )
                                    .toList(growable: false),
                              },
                            },
                          ],
                        });
                        AnalyticsService.instance.track(
                          AnalyticsEvents.checkoutCompleted,
                          properties: {
                            'module_type': 'laundry',
                            'order_id': order is Map
                                ? order['id']?.toString()
                                : null,
                            'service_id': selectedModel.id,
                            'service_name': selectedModel.name,
                            'item_count': totalItems,
                            'subtotal': subtotal,
                            'tax': tax,
                            'tax_rate_percent': taxRatePercent,
                            'delivery_fee': deliveryFee,
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
                        final orderId = order is Map
                            ? order['id']?.toString()
                            : null;
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

class _LaundryOrderShimmer extends StatelessWidget {
  const _LaundryOrderShimmer();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBlock(width: 140, height: 20, radius: 8),
            SizedBox(height: 12),
            Row(
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
            SizedBox(height: 24),
            ShimmerBlock(width: 90, height: 20, radius: 8),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 58, radius: 14),
            SizedBox(height: 10),
            ShimmerBlock(width: double.infinity, height: 58, radius: 14),
            SizedBox(height: 10),
            ShimmerBlock(width: double.infinity, height: 58, radius: 14),
            SizedBox(height: 20),
            ShimmerBlock(width: 120, height: 20, radius: 8),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 80, radius: 14),
            SizedBox(height: 20),
            ShimmerBlock(width: 90, height: 20, radius: 8),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 100, radius: 14),
            SizedBox(height: 24),
            ShimmerBlock(width: 130, height: 20, radius: 8),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 64, radius: 14),
            SizedBox(height: 24),
            ShimmerBlock(width: double.infinity, height: 50, radius: 14),
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
