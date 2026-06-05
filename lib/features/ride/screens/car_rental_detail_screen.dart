import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/auth_gate.dart';
import '../../../../core/widgets/app_button.dart';
import '../services/car_rental_service.dart';

const _rentalPrimary = Color(0xFF1E3A5F);
const _rentalAccent = Color(0xFF2DD4BF);
const _rentalBg = Color(0xFFF0F9FF);

class CarRentalDetailScreen extends StatefulWidget {
  final String carId;
  final CarRentalCar? carData; // passed via GoRouter extra to skip fetch

  const CarRentalDetailScreen({super.key, required this.carId, this.carData});

  @override
  State<CarRentalDetailScreen> createState() => _CarRentalDetailScreenState();
}

class _CarRentalDetailScreenState extends State<CarRentalDetailScreen> {
  CarRentalCar? _car;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Booking state
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  final _pickupController = TextEditingController(text: 'Djibouti City Centre');
  bool _sameDropoff = true;
  final _dropoffController = TextEditingController();
  final _notesController = TextEditingController();

  int get _totalDays => _endDate.difference(_startDate).inDays.clamp(1, 365);

  double get _subtotal => (_car?.pricePerDay ?? 0) * _totalDays;
  double get _tax => _subtotal * 0.08;
  double get _total => _subtotal + _tax;

  @override
  void initState() {
    super.initState();
    if (widget.carData != null) {
      _car = widget.carData;
      _isLoading = false;
    } else {
      _fetchCar();
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchCar() async {
    try {
      final car = await CarRentalService.fetchCar(widget.carId);
      if (!mounted) return;
      setState(() {
        _car = car;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart
        ? DateTime.now()
        : _startDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(first) ? initial : first,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _rentalPrimary,
            secondary: _rentalAccent,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate.add(const Duration(days: 1)))) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final allowed = await requireLoggedIn(
      context,
      message: 'Please sign in to rent a car.',
    );
    if (!mounted || !allowed) return;

    final pickup = _pickupController.text.trim();
    if (pickup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a pickup location.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final booking = await CarRentalService.createBooking(
        userId: auth.user!.id,
        carId: widget.carId,
        startDate: _startDate,
        endDate: _endDate,
        pickupLocation: pickup,
        dropoffLocation: _sameDropoff ? pickup : _dropoffController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showConfirmationSheet(booking);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiClient.userFacingError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showConfirmationSheet(CarRentalBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmationSheet(
        booking: booking,
        car: _car!,
        onDone: () {
          Navigator.of(context).pop();
          context.go('/orders');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _rentalBg,
        body: const Center(
          child: CircularProgressIndicator(color: _rentalPrimary),
        ),
      );
    }

    if (_car == null) {
      return Scaffold(
        backgroundColor: _rentalBg,
        appBar: AppBar(backgroundColor: _rentalPrimary),
        body: const Center(child: Text('Car not found.')),
      );
    }

    final car = _car!;

    return Scaffold(
      backgroundColor: _rentalBg,
      body: CustomScrollView(
        slivers: [
          _DetailAppBar(car: car),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSpecsRow(car),
                  const SizedBox(height: 20),
                  _buildDescription(car),
                  const SizedBox(height: 20),
                  _buildFeatures(car),
                  const SizedBox(height: 24),
                  _buildBookingSection(),
                  const SizedBox(height: 24),
                  _buildPriceSummary(),
                  const SizedBox(height: 32),
                  AppButton(
                    text: 'Confirm Rental · DJF ${_total.toStringAsFixed(0)}',
                    color: _rentalPrimary,
                    isLoading: _isSubmitting,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsRow(CarRentalCar car) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          _SpecItem(Icons.people_rounded, '${car.seats} Seats'),
          _divider(),
          _SpecItem(Icons.settings_rounded, car.transmission),
          _divider(),
          _SpecItem(Icons.local_gas_station_rounded, car.fuelType),
          _divider(),
          _SpecItem(Icons.speed_rounded, car.mileage),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 32,
    color: AppColors.lightGrey,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  Widget _buildDescription(CarRentalCar car) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this car', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        Text(
          car.description,
          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
        ),
      ],
    );
  }

  Widget _buildFeatures(CarRentalCar car) {
    if (car.features.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Features', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: car.features
              .map(
                (f) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _rentalAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: _rentalPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: _rentalPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildBookingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Details', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          // Date pickers
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Pick-up Date',
                  date: _startDate,
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'Return Date',
                  date: _endDate,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Duration badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _rentalBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: _rentalPrimary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$_totalDays day${_totalDays == 1 ? '' : 's'} rental',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: _rentalPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Pickup location
          TextField(
            controller: _pickupController,
            decoration: _inputDecoration(
              'Pickup Location',
              Icons.location_on_outlined,
            ),
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          // Same dropoff toggle
          GestureDetector(
            onTap: () => setState(() => _sameDropoff = !_sameDropoff),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _sameDropoff ? _rentalPrimary : Colors.transparent,
                    border: Border.all(
                      color: _sameDropoff ? _rentalPrimary : AppColors.grey,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _sameDropoff
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Text('Return to same location', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (!_sameDropoff) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _dropoffController,
              decoration: _inputDecoration(
                'Dropoff Location',
                Icons.flag_outlined,
              ),
              style: AppTextStyles.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: _inputDecoration(
              'Special requests (optional)',
              Icons.notes_rounded,
            ),
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGrey),
      prefixIcon: Icon(icon, color: _rentalPrimary, size: 20),
      filled: true,
      fillColor: _rentalBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _rentalAccent),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Summary', style: AppTextStyles.h4),
          const SizedBox(height: 14),
          _PriceLine(
            label:
                'DJF ${_car!.pricePerDay.toStringAsFixed(0)} × $_totalDays days',
            value: 'DJF ${_subtotal.toStringAsFixed(0)}',
          ),
          _PriceLine(
            label: 'Taxes & fees (8%)',
            value: 'DJF ${_tax.toStringAsFixed(0)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _PriceLine(
            label: 'Total',
            value: 'DJF ${_total.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  final CarRentalCar car;

  const _DetailAppBar({required this.car});

  IconData get _icon {
    switch (car.type.toLowerCase()) {
      case 'suv':
        return Icons.airport_shuttle_rounded;
      case 'van':
        return Icons.directions_bus_filled_rounded;
      case 'premium':
        return Icons.local_taxi_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: _rentalPrimary,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: car.imageUrl != null && car.imageUrl!.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    car.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          _rentalPrimary.withValues(alpha: 0.85),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _buildHeaderContent(context, car),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  _placeholder(),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: _buildHeaderContent(context, car),
                  ),
                ],
              ),
        title: Text(
          car.name,
          style: AppTextStyles.h4.copyWith(color: Colors.white),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF0F2744), _rentalPrimary],
        ),
      ),
      child: Center(
        child: Icon(
          _icon,
          size: 100,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context, CarRentalCar car) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                car.name,
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
              Text(
                '${car.year != null ? '${car.year} · ' : ''}${car.type}',
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        if (car.badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _rentalAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              car.badge!,
              style: AppTextStyles.labelSmall.copyWith(color: _rentalPrimary),
            ),
          ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: _rentalPrimary),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _rentalBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}/${date.month}/${date.year}',
              style: AppTextStyles.labelLarge.copyWith(color: _rentalPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceLine({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style.copyWith(
              color: isTotal ? _rentalPrimary : AppColors.dark,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confirmation Bottom Sheet ──────────────────────────────────────────────

class _ConfirmationSheet extends StatelessWidget {
  final CarRentalBooking booking;
  final CarRentalCar car;
  final VoidCallback onDone;

  const _ConfirmationSheet({
    required this.booking,
    required this.car,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _rentalAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: _rentalAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text('Booking Confirmed!', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(
              '${car.name} · ${booking.totalDays} day${booking.totalDays == 1 ? '' : 's'}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
            const SizedBox(height: 20),
            _InfoRow(
              'Booking ID',
              '#${booking.id.substring(0, 8).toUpperCase()}',
            ),
            _InfoRow('Pickup', booking.pickupLocation ?? 'TBD'),
            _InfoRow(
              'Dates',
              '${booking.startDate.day}/${booking.startDate.month} → '
                  '${booking.endDate.day}/${booking.endDate.month}',
            ),
            _InfoRow(
              'Total',
              'DJF ${booking.total?.toStringAsFixed(0) ?? '0'}',
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'View My Orders',
              color: _rentalPrimary,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
