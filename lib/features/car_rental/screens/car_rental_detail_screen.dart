import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../services/car_rental_service.dart';
import 'car_rental_confirmation_screen.dart';
import 'my_car_rentals_screen.dart';

class CarRentalDetailScreen extends StatefulWidget {
  const CarRentalDetailScreen({
    super.key,
    required this.carId,
    this.carData,
    this.carMap,
  });

  final String carId;
  final CarRentalCar? carData;
  final Map<String, dynamic>? carMap;

  @override
  State<CarRentalDetailScreen> createState() => _CarRentalDetailScreenState();
}

class _CarRentalDetailScreenState extends State<CarRentalDetailScreen> {
  final _pickupController = TextEditingController();
  final _notesController = TextEditingController();
  CarRentalCar? _car;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loadingCar = true;
  bool _checkingAvailability = false;
  bool _booking = false;
  bool? _isAvailable;
  String? _availabilityError;
  String? _loadError;
  int _availabilityRequest = 0;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _car =
        widget.carData ??
        (widget.carMap == null ? null : CarRentalCar.fromApi(widget.carMap!));
    if (_car != null) {
      _loadingCar = false;
    } else {
      _loadCar();
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCar() async {
    setState(() {
      _loadingCar = true;
      _loadError = null;
    });
    try {
      final car = await CarRentalService.fetchCar(widget.carId);
      if (!mounted) return;
      setState(() {
        _car = car;
        _loadingCar = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCar = false;
        _loadError = ApiClient.userFacingError(error);
      });
    }
  }

  int get _totalDays {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) return 0;
    final startDay = DateTime.utc(start.year, start.month, start.day);
    final endDay = DateTime.utc(end.year, end.month, end.day);
    final days = endDay.difference(startDay).inDays;
    return days > 0 ? days : 0;
  }

  int get _estimatedTotal {
    final subtotal = (_car?.pricePerDay ?? 0) * _totalDays;
    return subtotal + (subtotal * 0.08).round();
  }

  DateTime _dateAsUtc(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
    );
    if (picked == null || !mounted) return;
    _availabilityRequest++;
    setState(() {
      _startDate = picked;
      if (_endDate != null && !_endDate!.isAfter(picked)) _endDate = null;
      _isAvailable = null;
      _availabilityError = null;
    });
    await _checkAvailabilityIfReady();
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstEndDate =
        _startDate?.add(const Duration(days: 1)) ??
        today.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? firstEndDate,
      firstDate: firstEndDate,
      lastDate: DateTime(today.year + 2),
    );
    if (picked == null || !mounted) return;
    _availabilityRequest++;
    setState(() {
      _endDate = picked;
      _isAvailable = null;
      _availabilityError = null;
    });
    await _checkAvailabilityIfReady();
  }

  Future<void> _checkAvailabilityIfReady() async {
    final car = _car;
    final start = _startDate;
    final end = _endDate;
    if (car == null || start == null || end == null) return;
    final requestId = ++_availabilityRequest;
    setState(() {
      _checkingAvailability = true;
      _isAvailable = null;
      _availabilityError = null;
    });
    try {
      final available = await CarRentalService.checkAvailability(
        carId: car.id,
        startDate: _dateAsUtc(start),
        endDate: _dateAsUtc(end),
      );
      if (!mounted || requestId != _availabilityRequest) return;
      setState(() {
        _isAvailable = available;
        _checkingAvailability = false;
      });
    } catch (error) {
      if (!mounted || requestId != _availabilityRequest) return;
      setState(() {
        _isAvailable = false;
        _checkingAvailability = false;
        _availabilityError = ApiClient.userFacingError(error);
      });
    }
  }

  Future<void> _book() async {
    final car = _car;
    final start = _startDate;
    final end = _endDate;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      _showMessage(_l10n.t('car_rental.login_required'));
      return;
    }
    if (car == null || start == null || end == null || _totalDays == 0) {
      _showMessage(_l10n.t('car_rental.error_dates'));
      return;
    }
    if (_pickupController.text.trim().length < 4) {
      _showMessage(_l10n.t('car_rental.pickup_required'));
      return;
    }
    if (_isAvailable != true || _checkingAvailability) {
      _showMessage(
        _availabilityError ?? _l10n.t('car_rental.check_availability_first'),
      );
      return;
    }

    setState(() => _booking = true);
    try {
      final booking = await CarRentalService.createBooking(
        userId: userId,
        carId: car.id,
        startDate: _dateAsUtc(start),
        endDate: _dateAsUtc(end),
        pickupLocation: _pickupController.text.trim(),
        dropoffLocation: _pickupController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CarRentalConfirmationScreen(
            carName: car.name,
            startDate: start,
            endDate: end,
            totalPrice: booking.totalPrice ?? _estimatedTotal,
            confirmationNumber: booking.id,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        _l10n.t(
          'car_rental.error_booking',
          params: {'error': ApiClient.userFacingError(error)},
        ),
      );
      if (error.toString().contains('already booked')) {
        setState(() => _isAvailable = false);
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime? date) {
    if (date == null) return _l10n.t('car_rental.select_date');
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatMediumDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final car = _car;
    final l10n = _l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(car?.name ?? l10n.t('car_rental.title')),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.t('car_rental.my_bookings'),
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyCarRentalsScreen()),
            ),
          ),
        ],
      ),
      body: _loadingCar
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null || car == null
          ? _errorState()
          : _detailBody(car),
      bottomNavigationBar: car == null || _loadingCar || _loadError != null
          ? null
          : _bookingBar(car),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _loadError ?? _l10n.t('car_rental.load_error'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadCar,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_l10n.t('car_rental.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailBody(CarRentalCar car) {
    final l10n = _l10n;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Hero(
          tag: 'rental-car-${car.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _carImage(car),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.name, style: AppTextStyles.h3),
                  const SizedBox(height: 5),
                  Text(
                    '${car.year > 0 ? '${car.year} · ' : ''}${car.type}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'DJF ${car.pricePerDay}',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        if (car.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            car.description,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _spec(
              Icons.people_outline_rounded,
              '${car.seats} ${l10n.t('car_rental.seats')}',
            ),
            _spec(Icons.settings_outlined, car.transmission),
            _spec(Icons.local_gas_station_outlined, car.fuelType),
            _spec(Icons.speed_outlined, car.mileage),
          ],
        ),
        if (car.features.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(l10n.t('car_rental.features'), style: AppTextStyles.labelLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: car.features.map(_featureTile).toList(),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          l10n.t('car_rental.select_dates'),
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _dateButton(
                l10n.t('car_rental.start_date'),
                _formatDate(_startDate),
                Icons.calendar_today_outlined,
                _pickStartDate,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dateButton(
                l10n.t('car_rental.end_date'),
                _formatDate(_endDate),
                Icons.event_outlined,
                _pickEndDate,
              ),
            ),
          ],
        ),
        if (_checkingAvailability ||
            _isAvailable != null ||
            _availabilityError != null) ...[
          const SizedBox(height: 12),
          _availabilityStatus(),
        ],
        const SizedBox(height: 22),
        Text(
          l10n.t('car_rental.pickup_location'),
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _pickupController,
          onChanged: (_) => setState(() {}),
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: l10n.t('car_rental.pickup_location_hint'),
            prefixIcon: const Icon(Icons.location_on_outlined),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notesController,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.t('car_rental.notes_optional'),
            prefixIcon: const Icon(Icons.notes_outlined),
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        _priceBreakdown(car),
      ],
    );
  }

  Widget _carImage(CarRentalCar car) {
    final image = car.imageUrl;
    if (image == null || image.isEmpty) {
      return Container(
        height: 220,
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(
          Icons.directions_car_filled_outlined,
          size: 86,
          color: AppColors.primary,
        ),
      );
    }
    return Image.network(
      image,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: 220,
        color: AppColors.primarySurface,
        alignment: Alignment.center,
        child: const Icon(
          Icons.directions_car_filled_outlined,
          size: 86,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _spec(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _featureTile(String feature) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              feature,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateButton(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 17, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(title, style: AppTextStyles.caption)),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _availabilityStatus() {
    final String label;
    final Color color;
    final IconData icon;
    if (_checkingAvailability) {
      label = _l10n.t('car_rental.checking');
      color = AppColors.grey;
      icon = Icons.more_horiz_rounded;
    } else if (_availabilityError != null) {
      label = _l10n.t('car_rental.availability_error');
      color = AppColors.error;
      icon = Icons.error_outline_rounded;
    } else if (_isAvailable == true) {
      label = _l10n.t('car_rental.available');
      color = AppColors.primary;
      icon = Icons.check_circle_outline_rounded;
    } else {
      label = _l10n.t('car_rental.unavailable');
      color = AppColors.error;
      icon = Icons.cancel_outlined;
    }
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: color),
          ),
        ),
        if (_availabilityError != null)
          TextButton(
            onPressed: _checkAvailabilityIfReady,
            child: Text(_l10n.t('car_rental.retry')),
          ),
      ],
    );
  }

  Widget _priceBreakdown(CarRentalCar car) {
    final subtotal = car.pricePerDay * _totalDays;
    final tax = (subtotal * 0.08).round();
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
            _l10n.t('car_rental.price_breakdown'),
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            _totalDays > 0
                ? _l10n.t(
                    'car_rental.price_for_days',
                    params: {'count': '$_totalDays'},
                  )
                : _l10n.t('car_rental.price_select_dates'),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 12),
          _priceRow(_l10n.t('car_rental.daily_rate'), 'DJF ${car.pricePerDay}'),
          if (_totalDays > 0) ...[
            const SizedBox(height: 8),
            _priceRow(
              _l10n.t(
                'car_rental.rental_days',
                params: {'count': '$_totalDays'},
              ),
              'DJF $subtotal',
            ),
            const SizedBox(height: 8),
            _priceRow(_l10n.t('car_rental.tax'), 'DJF $tax'),
            const Divider(height: 20),
            _priceRow(
              _l10n.t('car_rental.total'),
              'DJF ${subtotal + tax}',
              bold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, String price, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: bold ? AppTextStyles.labelLarge : AppTextStyles.bodySmall,
          ),
        ),
        Text(
          price,
          style: (bold ? AppTextStyles.labelLarge : AppTextStyles.bodySmall)
              .copyWith(color: bold ? AppColors.primaryDark : AppColors.dark),
        ),
      ],
    );
  }

  Widget _bookingBar(CarRentalCar car) {
    final enabled =
        _isAvailable == true &&
        _totalDays > 0 &&
        _pickupController.text.trim().length >= 4 &&
        !_checkingAvailability &&
        !_booking;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.lightGrey.withValues(alpha: 0.65)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _l10n.t('car_rental.total'),
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    _totalDays > 0
                        ? 'DJF $_estimatedTotal'
                        : _l10n.t(
                            'car_rental.price_per_day',
                            params: {'price': '${car.pricePerDay}'},
                          ),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: enabled ? _book : null,
              icon: _booking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.event_available_outlined),
              label: Text(_l10n.t('car_rental.book_now')),
            ),
          ],
        ),
      ),
    );
  }
}
