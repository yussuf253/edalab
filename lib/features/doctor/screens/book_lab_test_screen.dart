import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/lab_test_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/auth_gate.dart';
import '../../../core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BookLabTestScreen extends StatefulWidget {
  final LabTestModel test;
  const BookLabTestScreen({super.key, required this.test});

  @override
  State<BookLabTestScreen> createState() => _BookLabTestScreenState();
}

class _BookLabTestScreenState extends State<BookLabTestScreen> {
  static const List<String> _times = [
    '07:00',
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '14:00',
    '15:00',
    '16:00',
  ];

  final TextEditingController _notesController = TextEditingController();
  late final List<DateTime> _dates;
  int _selectedDate = 0;
  int _selectedTime = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day + index),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    final l10n = context.l10n;
    final allowed = await requireLoggedIn(
      context,
      message: l10n.t('lab_booking.login_required'),
    );
    if (!mounted || !allowed) return;

    final auth = context.read<AuthProvider>();
    final test = widget.test;
    final date = _dates[_selectedDate];
    final timeSlot = _times[_selectedTime];
    final scheduledDate = DateFormat('yyyy-MM-dd').format(date);
    final scheduledLabel = DateFormat('EEE, MMM d, yyyy').format(date);
    final notes = _notesController.text.trim();

    setState(() => _isSubmitting = true);
    AnalyticsService.instance.track(
      AnalyticsEvents.checkoutPlaceOrderTapped,
      properties: {
        'module_type': 'health_services',
        'test_id': test.id,
        'test_name': test.name,
        'amount': test.price,
        'time_slot': timeSlot,
      },
    );

    try {
      final order = await ApiClient.post('/orders', {
        'userId': auth.user!.id,
        'moduleType': 'HEALTH_SERVICES',
        'subtotal': test.price,
        'tax': 0,
        'deliveryFee': 0,
        'total': test.price,
        if (notes.isNotEmpty) 'notes': notes,
        'items': [
          {
            'id': test.id,
            'name': test.name,
            'price': test.price,
            'quantity': 1,
            'total': test.price,
            'metadata': {
              'testId': test.id,
              'testName': test.name,
              'categoryId': test.categoryId,
              'sampleType': test.sampleType,
              'preparationInstructions': test.preparationInstructions,
              'scheduledDate': scheduledDate,
              'scheduledLabel': scheduledLabel,
              'timeSlot': timeSlot,
              'homeCollection': true,
              if (notes.isNotEmpty) 'patientNotes': notes,
            },
          },
        ],
      });
      if (!mounted) return;
      AnalyticsService.instance.track(
        AnalyticsEvents.checkoutCompleted,
        properties: {
          'module_type': 'health_services',
          'order_id': order is Map ? order['id']?.toString() : null,
          'test_id': test.id,
          'amount': test.price,
          'item_count': 1,
        },
      );
      context.push(
        '/checkout/success',
        extra: {
          'orderId': order is Map ? order['id'] : null,
          'amount': test.price,
          'payment': l10n.t('home_service_booking.pay_on_confirmation'),
          'delivery': '$scheduledLabel • $timeSlot',
          'moduleName': test.name,
          'itemCount': 1,
          'trackingRoute': '/orders',
        },
      );
    } catch (error) {
      AnalyticsService.instance.track(
        AnalyticsEvents.checkoutValidationFailed,
        properties: {
          'module_type': 'health_services',
          'reason': 'lab_booking_submission_failed',
          'error': error.toString(),
        },
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.t('lab_booking.failed', params: {'error': '$error'}),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final test = widget.test;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('lab_booking.title')),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      LucideIcons.flaskConical,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(test.name, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 2),
                        Text(
                          l10n.t('lab_booking.home_collection'),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.t('doctor_booking.select_date'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final selected = _selectedDate == index;
                  final date = _dates[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: selected
                            ? null
                            : Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE', localeTag).format(date),
                            style: AppTextStyles.caption.copyWith(
                              color: selected ? Colors.white70 : AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d').format(date),
                            style: AppTextStyles.h4.copyWith(
                              color: selected
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
            const SizedBox(height: 24),
            Text(l10n.t('doctor_booking.select_time'), style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_times.length, (index) {
                final selected = _selectedTime == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: selected
                          ? null
                          : Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _times[index],
                      style: AppTextStyles.labelMedium.copyWith(
                        color: selected ? AppColors.white : AppColors.dark,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.t('doctor_booking.notes_optional'),
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.t('lab_booking.notes_hint'),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _SummaryRow(l10n.t('doctor_booking.provider'), test.name),
                  _SummaryRow(
                    l10n.t('doctor_booking.date'),
                    DateFormat(
                      'EEE, MMM d, yyyy',
                    ).format(_dates[_selectedDate]),
                  ),
                  _SummaryRow(
                    l10n.t('doctor_booking.time'),
                    _times[_selectedTime],
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    l10n.t('doctor_booking.fee'),
                    'DJF ${test.price.toStringAsFixed(0)}',
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.white,
          child: AppButton(
            text: l10n.t('lab_booking.confirm'),
            icon: LucideIcons.calendarCheck,
            color: AppColors.primary,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _confirmBooking,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: bold
                  ? AppTextStyles.labelLarge
                  : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
            ),
          ),
          Text(
            value,
            style: bold
                ? AppTextStyles.priceSmall.copyWith(color: AppColors.primary)
                : AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
