import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../services/car_rental_service.dart';

class CarRentalDetailScreen extends StatefulWidget {
  final String carId;
  final CarRentalCar? carData;

  const CarRentalDetailScreen({super.key, required this.carId, this.carData});

  @override
  State<CarRentalDetailScreen> createState() => _CarRentalDetailScreenState();
}

class _CarRentalDetailScreenState extends State<CarRentalDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isBooking = false;

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    final diff = _endDate!.difference(_startDate!).inMilliseconds;
    final days = (diff / (1000 * 60 * 60 * 24)).ceil();
    return days < 1 ? 1 : days;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
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
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _bookCar() async {
    final car = widget.carData;
    if (car == null) return;
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in to book')));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
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
        'pickupLocation': '',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(e))));
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = widget.carData;
    final pricePerDay = car?.pricePerDay ?? 0;

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
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _startDate == null
                            ? 'Select start date'
                            : _startDate!.toLocal().toString().split(' ').first,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickEndDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _endDate == null
                            ? 'Select end date'
                            : _endDate!.toLocal().toString().split(' ').first,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Total days: $_totalDays', style: AppTextStyles.labelMedium),
            const SizedBox(height: 8),
            Text(
              'Total price: DJF${_totalDays * pricePerDay}',
              style: AppTextStyles.labelLarge,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _bookCar,
                    child: _isBooking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Book — DJF${_totalDays * pricePerDay}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
