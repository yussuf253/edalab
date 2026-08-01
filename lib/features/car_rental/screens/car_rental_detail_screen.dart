import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/providers.dart';
import '../services/car_rental_service.dart';
import 'car_rental_confirmation_screen.dart';

class CarRentalDetailScreen extends StatefulWidget {
  final String carId;
  final CarRentalCar? carData;
  final Map<String, dynamic>? carMap;

  const CarRentalDetailScreen({
    super.key,
    required this.carId,
    this.carData,
    this.carMap,
  });

  @override
  State<CarRentalDetailScreen> createState() => _CarRentalDetailScreenState();
}

class _CarRentalDetailScreenState extends State<CarRentalDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isBooking = false;
  bool _isCheckingAvailability = false;
  bool _isAvailable = true;
  CarRentalCar? _car;

  @override
  void initState() {
    super.initState();
    _initCar();
    if (_car == null) {
      _fetchCar();
    }
  }

  void _initCar() {
    if (widget.carData != null) {
      _car = widget.carData;
    } else if (widget.carMap != null) {
      _car = CarRentalCar.fromApi(widget.carMap!);
    }
  }

  Future<void> _fetchCar() async {
    try {
      final response = await ApiClient.get('/car-rentals/${widget.carId}');
      if (mounted && response is Map<String, dynamic>) {
        setState(() {
          _car = CarRentalCar.fromApi(response);
        });
      }
    } catch (_) {
      // Car fetch failed - will show error in UI
    }
  }

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    final diff = _endDate!.difference(_startDate!).inMilliseconds;
    final days = (diff / (1000 * 60 * 60 * 24)).ceil();
    return days < 1 ? 1 : days;
  }

  int get _totalPrice {
    final car = _car;
    if (car == null) return 0;
    final subtotal = _totalDays * car.pricePerDay;
    final tax = (subtotal * 0.08).toInt();
    return subtotal + tax;
  }

  Future<void> _pickStartDate(AppLocalizations l10n) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      if (_startDate != null && _endDate != null) {
        await _checkAvailability(l10n);
      }
    }
  }

  Future<void> _pickEndDate(AppLocalizations l10n) async {
    final now = DateTime.now();
    final initial =
        _endDate ??
        (_startDate != null
            ? _startDate!.add(const Duration(days: 1))
            : now.add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate ?? now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      if (_startDate != null && _endDate != null) {
        await _checkAvailability(l10n);
      }
    }
  }

  Future<void> _checkAvailability(AppLocalizations l10n) async {
    if (_startDate == null || _endDate == null) return;
    setState(() => _isCheckingAvailability = true);
    try {
      final response = await ApiClient.get(
        '/car-rentals/bookings/availability'
        '?carId=${_car?.id}'
        '&startDate=${_startDate!.toIso8601String()}'
        '&endDate=${_endDate!.toIso8601String()}',
      );
      if (mounted) {
        setState(() {
          _isAvailable = (response as Map)['available'] as bool? ?? true;
        });
        if (!_isAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.t('car_rental.unavailable')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.t('common.error'))));
      }
    } finally {
      if (mounted) setState(() => _isCheckingAvailability = false);
    }
  }

  Future<void> _bookCar(AppLocalizations l10n) async {
    final car = widget.carData;
    if (car == null) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('car_rental.login_required'))),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.t('car_rental.error_dates'))));
      return;
    }

    setState(() => _isBooking = true);
    try {
      final resp = await ApiClient.post('/car-rentals/bookings', {
        'userId': userId,
        'carId': car.id,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        // Self-drive rental: no per-trip route, so we default these rather
        // than making the renter fill in a ride-style pickup/dropoff pair.
        'pickupLocation': 'Djibouti City',
        'dropoffLocation': 'Djibouti City',
      });

      // Ensure widget still mounted before interacting with context
      if (!mounted) return;
      final respMap = resp is Map ? Map<String, dynamic>.from(resp) : const {};
      final confirmationNumber =
          (respMap['id'] ?? respMap['bookingId'] ?? respMap['_id'])
              ?.toString() ??
          '—';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CarRentalConfirmationScreen(
            carName: car.name,
            startDate: _startDate!,
            endDate: _endDate!,
            totalPrice: _totalPrice,
            confirmationNumber: confirmationNumber,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.t(
              'car_rental.error_booking',
              params: {'error': ApiClient.userFacingError(e)},
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final car = widget.carData;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(car?.name ?? l10n.t('car_rental.default_car_name')),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.extraLightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Iconsax.car, size: 64),
              ),
            ),
            const SizedBox(height: 12),
            Text(car?.name ?? l10n.t('car_rental.default_car_name'), style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              car != null ? '${car.type} • ${car.seats} seats' : '',
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: 12),
            Text(l10n.t('car_rental.features'), style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            if (car != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: car.features
                    .map((f) => Chip(label: Text(f)))
                    .toList(),
              ),
            const SizedBox(height: 12),

            // Rental is date-driven, not route-driven — no pickup/dropoff
            // address pair like a ride. Just a short heads-up instead.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.extraLightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Iconsax.information,
                    size: 20,
                    color: AppColors.mediumGrey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.t('car_rental.pickup_note'),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Date selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('car_rental.select_dates'),
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickStartDate(l10n),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.lightGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('car_rental.start_date'),
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _startDate == null
                                      ? l10n.t('common.select')
                                      : _formatDate(_startDate!),
                                  style: AppTextStyles.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickEndDate(l10n),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.lightGrey),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('car_rental.end_date'),
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _endDate == null
                                      ? l10n.t('common.select')
                                      : _formatDate(_endDate!),
                                  style: AppTextStyles.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isCheckingAvailability)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(l10n.t('common.checking')),
                        ],
                      ),
                    ),
                  if (!_isCheckingAvailability &&
                      _startDate != null &&
                      _endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            _isAvailable
                                ? Iconsax.tick_circle
                                : Iconsax.close_circle,
                            color: _isAvailable
                                ? AppColors.success
                                : AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAvailable
                                ? l10n.t('car_rental.available')
                                : l10n.t('car_rental.unavailable'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: _isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Price breakdown
            if (_totalDays > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('car_rental.price_breakdown'),
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    _PriceRow(
                      label: l10n.t('car_rental.daily_rate'),
                      value: 'DJF${car?.pricePerDay ?? 0}',
                    ),
                    _PriceRow(
                      label: '$_totalDays ${l10n.t('common.days')}',
                      value: 'DJF${_totalDays * (car?.pricePerDay ?? 0)}',
                    ),
                    const Divider(height: 16),
                    _PriceRow(
                      label: l10n.t('car_rental.subtotal'),
                      value: 'DJF${_totalDays * (car?.pricePerDay ?? 0)}',
                    ),
                    _PriceRow(
                      label: l10n.t('car_rental.tax'),
                      value:
                          'DJF${((_totalDays * (car?.pricePerDay ?? 0)) * 0.08).toInt()}',
                    ),
                    const Divider(height: 16),
                    _PriceRow(
                      label: l10n.t('car_rental.total'),
                      value: 'DJF$_totalPrice',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Book button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isBooking || !_isAvailable || _totalDays == 0)
                    ? null
                    : () => _bookCar(l10n),
                child: _isBooking
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.dark
                                : AppColors.white,
                          ),
                        ),
                      )
                    : Text(
                        _totalDays > 0
                            ? '${l10n.t('car_rental.book_now')} • DJF$_totalPrice'
                            : l10n.t('car_rental.select_dates'),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ignore: unused_element
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium,
          ),
          Text(
            value,
            style: (isBold ? AppTextStyles.h4 : AppTextStyles.labelMedium)
                .copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}
