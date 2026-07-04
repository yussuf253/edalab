import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/providers.dart';
import '../services/car_rental_service.dart';

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
  String _pickupLocation = '';
  String _dropoffLocation = '';
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

    if (_pickupLocation.isEmpty || _dropoffLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('car_rental.error_locations'))),
      );
      return;
    }

    setState(() => _isBooking = true);
    try {
      final resp = await ApiClient.post('/car-rentals/bookings', {
        'userId': userId,
        'carId': car.id,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'pickupLocation': _pickupLocation.isEmpty
            ? 'Djibouti City'
            : _pickupLocation,
        'dropoffLocation': _dropoffLocation.isEmpty
            ? 'Djibouti City'
            : _dropoffLocation,
      });

      // Ensure widget still mounted before interacting with context
      if (!mounted) return;
      // Show success and navigate back or to a booking summary
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created successfully')),
      );
      Navigator.of(context).pop(resp);
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
      appBar: AppBar(title: Text(car?.name ?? 'Car')),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                child: Icon(Icons.directions_car_rounded, size: 64),
              ),
            ),
            const SizedBox(height: 12),
            Text(car?.name ?? 'Vehicle', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Text(
              car != null ? '${car.type} • ${car.seats} seats' : '',
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: 12),
            Text('Features', style: AppTextStyles.labelLarge),
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

            // Pickup and Drop-off locations
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
                    l10n.t('car_rental.pickup_dropoff_locations'),
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 12),
                  _LocationField(
                    label: l10n.t('car_rental.pickup_location'),
                    hint: l10n.t('car_rental.pickup_location_hint'),
                    value: _pickupLocation,
                    onChanged: (value) =>
                        setState(() => _pickupLocation = value),
                  ),
                  const SizedBox(height: 12),
                  _LocationField(
                    label: l10n.t('car_rental.dropoff_location'),
                    hint: l10n.t('car_rental.dropoff_location_hint'),
                    value: _dropoffLocation,
                    onChanged: (value) =>
                        setState(() => _dropoffLocation = value),
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
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
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
            const SizedBox(height: 16),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : () => _bookCar(l10n),
                    child: _isBooking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _totalDays > 0
                                ? '${l10n.t('car_rental.book_now')} • DJF$_totalPrice'
                                : l10n.t('car_rental.select_dates'),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _LocationField({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 6),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          style: AppTextStyles.bodyLarge,
        ),
      ],
    );
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
