import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/providers.dart';
import '../services/car_rental_service.dart';

class MyCarRentalsScreen extends StatefulWidget {
  const MyCarRentalsScreen({super.key});

  @override
  State<MyCarRentalsScreen> createState() => _MyCarRentalsScreenState();
}

class _MyCarRentalsScreenState extends State<MyCarRentalsScreen> {
  List<CarRentalBooking>? _bookings; // null = couldn't load
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = context.read<AuthProvider>().user?.id;
    final bookings = userId == null
        ? <CarRentalBooking>[]
        : await CarRentalBookingsService.fetchUserBookings(userId);
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _loading = false;
    });
  }

  Future<void> _cancel(CarRentalBooking booking, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('car_rental.cancel_booking')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.t('car_rental.cancel_booking')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await CarRentalBookingsService.cancelBooking(booking.id);
    if (!mounted) return;
    if (ok) {
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('car_rental.error_booking', params: {'error': ''}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('car_rental.my_bookings')),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_bookings == null) {
      // Backend endpoint isn't reachable/wired up yet — be honest about it
      // rather than pretending there are no bookings.
      return ListView(
        children: [
          const SizedBox(height: 80),
          const Icon(Iconsax.cloud, size: 48, color: AppColors.mediumGrey),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.t('car_rental.error_booking', params: {'error': ''}),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGrey),
            ),
          ),
        ],
      );
    }

    if (_bookings!.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          const Icon(Iconsax.car, size: 48, color: AppColors.mediumGrey),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.t('car_rental.no_cars'),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGrey),
            ),
          ),
        ],
      );
    }

    final active = _bookings!.where((b) => !b.isPast && !b.isCancelled).toList();
    final past = _bookings!.where((b) => b.isPast || b.isCancelled).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (active.isNotEmpty) ...[
          Text(l10n.t('car_rental.active_bookings'), style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          for (final booking in active) ...[
            _BookingCard(booking: booking, l10n: l10n, onCancel: () => _cancel(booking, l10n)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
        ],
        if (past.isNotEmpty) ...[
          Text(l10n.t('car_rental.past_rentals'), style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          for (final booking in past) ...[
            _BookingCard(booking: booking, l10n: l10n, onCancel: null),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final CarRentalBooking booking;
  final AppLocalizations l10n;
  final VoidCallback? onCancel;

  const _BookingCard({required this.booking, required this.l10n, this.onCancel});

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.carName ?? l10n.t('car_rental.default_car_name'),
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGrey),
          ),
          if (booking.totalPrice != null) ...[
            const SizedBox(height: 6),
            Text('DJF${booking.totalPrice}', style: AppTextStyles.bodyMedium),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: Text(l10n.t('car_rental.cancel_booking')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
