import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import 'my_car_rentals_screen.dart';

class CarRentalConfirmationScreen extends StatelessWidget {
  final String carName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalPrice;
  final String confirmationNumber;

  const CarRentalConfirmationScreen({
    super.key,
    required this.carName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.confirmationNumber,
  });

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.t('car_rental.booking_confirmed'),
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.t('car_rental.booking_confirmation_subtitle'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.mediumGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('car_rental.confirmation_details'),
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: l10n.t('car_rental.vehicle_details'),
                      value: carName,
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: l10n.t('car_rental.rental_period'),
                      value: '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: l10n.t('car_rental.total'),
                      value: 'DJF$totalPrice',
                    ),
                    const SizedBox(height: 10),
                    _DetailRow(
                      label: l10n.t('car_rental.confirmation_number'),
                      value: confirmationNumber,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MyCarRentalsScreen(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  child: Text(l10n.t('car_rental.my_bookings')),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: Text(l10n.t('payment_failure.back_home')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGrey),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
