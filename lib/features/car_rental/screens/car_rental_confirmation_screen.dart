import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import 'my_car_rentals_screen.dart';

class CarRentalConfirmationScreen extends StatelessWidget {
  const CarRentalConfirmationScreen({
    super.key,
    required this.carName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.confirmationNumber,
  });

  final String carName;
  final DateTime startDate;
  final DateTime endDate;
  final int totalPrice;
  final String confirmationNumber;

  String _formatDate(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('car_rental.booking_confirmed')),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.successLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 38,
                      ),
                    ),
                    Text(
                      l10n.t('car_rental.booking_confirmed'),
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      l10n.t('car_rental.booking_confirmation_subtitle'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
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
                          const Divider(height: 20),
                          _DetailRow(
                            label: l10n.t('car_rental.start_date'),
                            value: _formatDate(context, startDate),
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: l10n.t('car_rental.end_date'),
                            value: _formatDate(context, endDate),
                          ),
                          const Divider(height: 20),
                          _DetailRow(
                            label: l10n.t('car_rental.total'),
                            value: 'DJF $totalPrice',
                            emphasize: true,
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: l10n.t('car_rental.confirmation_number'),
                            value: confirmationNumber,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MyCarRentalsScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: Text(l10n.t('car_rental.my_bookings')),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    child: Text(l10n.t('payment_failure.back_home')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.grey),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: Text(
            value,
            softWrap: true,
            style:
                (emphasize
                        ? AppTextStyles.labelLarge
                        : AppTextStyles.bodyMedium)
                    .copyWith(
                      color: emphasize ? AppColors.primaryDark : AppColors.dark,
                      fontWeight: FontWeight.w700,
                    ),
          ),
        ),
      ],
    );
  }
}
