import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/auth_gate.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class HotelBookingScreen extends StatefulWidget {
  final String hotelId;

  const HotelBookingScreen({super.key, required this.hotelId});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _guestNameController;
  late final TextEditingController _guestEmailController;
  late final TextEditingController _guestPhoneController;
  late final TextEditingController _specialRequestsController;

  late HotelModel _hotel;
  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 4));
  int _guestCount = 2;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _guestNameController = TextEditingController(
      text: auth.user?.fullName ?? '',
    );
    _guestEmailController = TextEditingController(text: auth.user?.email ?? '');
    _guestPhoneController = TextEditingController(text: auth.user?.phone ?? '');
    _specialRequestsController = TextEditingController();
    _hotel = HotelModel(
      id: '',
      name: '',
      address: '',
      city: '',
      rating: 0,
      reviewsCount: 0,
      pricePerNight: 0,
      amenities: const [],
      description: '',
    );
    _loadHotel();
  }

  Future<void> _loadHotel() async {
    try {
      final response = await ApiClient.get('/catalog/hotels/${widget.hotelId}');
      final hotel = HotelModel.fromApi(
        Map<String, dynamic>.from(response as Map),
      );
      if (!mounted) return;
      setState(() {
        _hotel = hotel;
        _selectedRoomId = hotel.roomOptions
            .where((room) => room.available)
            .map((room) => room.id)
            .cast<String?>()
            .firstWhere((roomId) => roomId != null, orElse: () => null);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hotel = HotelModel.sampleHotels.firstWhere(
          (hotel) => hotel.id == widget.hotelId,
          orElse: () => HotelModel.sampleHotels.first,
        );
        _selectedRoomId = _hotel.roomOptions
            .where((room) => room.available)
            .map((room) => room.id)
            .cast<String?>()
            .firstWhere((roomId) => roomId != null, orElse: () => null);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestEmailController.dispose();
    _guestPhoneController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  HotelRoomOption? get _selectedRoom {
    if (_selectedRoomId == null) return null;
    for (final room in _hotel.roomOptions) {
      if (room.id == _selectedRoomId) {
        return room;
      }
    }
    return null;
  }

  int get _nights {
    final duration = _checkOutDate.difference(_checkInDate).inDays;
    return duration <= 0 ? 1 : duration;
  }

  Future<void> _selectCheckInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkInDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      _checkInDate = picked;
      if (!_checkOutDate.isAfter(_checkInDate)) {
        _checkOutDate = _checkInDate.add(const Duration(days: 1));
      }
    });
  }

  Future<void> _selectCheckOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _checkOutDate.isAfter(_checkInDate)
          ? _checkOutDate
          : _checkInDate.add(const Duration(days: 1)),
      firstDate: _checkInDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;
    setState(() => _checkOutDate = picked);
  }

  Future<void> _selectGuests() async {
    int tempGuests = _guestCount;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.t('hotel.select_guests'),
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.t('hotel.guests'),
                            style: AppTextStyles.labelLarge,
                          ),
                        ),
                        _GuestAdjustButton(
                          icon: Icons.remove_rounded,
                          onTap: tempGuests > 1
                              ? () => setModalState(() => tempGuests--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$tempGuests', style: AppTextStyles.h4),
                        ),
                        _GuestAdjustButton(
                          icon: Icons.add_rounded,
                          onTap: tempGuests < 10
                              ? () => setModalState(() => tempGuests++)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _guestCount = tempGuests);
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.hotel,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          context.l10n.t('hotel.apply'),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitBooking() async {
    final l10n = context.l10n;
    final auth = context.read<AuthProvider>();

    final allowed = await requireLoggedIn(
      context,
      message: l10n.t('hotel_booking.login_required'),
    );
    if (!mounted || !allowed) return;

    final room = _selectedRoom;
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available room.')),
      );
      return;
    }

    if (_guestCount > room.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This room supports up to ${room.capacity} guests.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final roomRate = room.pricePerNight * _nights;
    final serviceFee = roomRate * 0.05;
    final tax = roomRate * 0.08;
    final total = roomRate + serviceFee + tax;

    setState(() => _isSubmitting = true);

    try {
      final booking = Map<String, dynamic>.from(
        await ApiClient.post('/orders/hotel-bookings', {
              'userId': auth.user!.id,
              'hotelId': _hotel.id,
              'roomType': room.name,
              'guestName': _guestNameController.text.trim(),
              'guestEmail': _guestEmailController.text.trim(),
              'guestPhone': _guestPhoneController.text.trim().isEmpty
                  ? null
                  : _guestPhoneController.text.trim(),
              'specialRequests': _specialRequestsController.text.trim().isEmpty
                  ? null
                  : _specialRequestsController.text.trim(),
              'checkInAt': _checkInDate.toIso8601String(),
              'checkOutAt': _checkOutDate.toIso8601String(),
              'nights': _nights,
              'guestCount': _guestCount,
              'subtotal': roomRate,
              'serviceFee': serviceFee,
              'tax': tax,
              'total': total,
            })
            as Map,
      );

      if (!mounted) return;

      final normalizedItems = (booking['items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final trackingBooking = {
        ...booking,
        'hotelId': booking['hotelId'] ?? _hotel.id,
        'hotelName': booking['hotelName'] ?? _hotel.name,
        'moduleName': booking['moduleName'] ?? _hotel.name,
        'roomType': booking['roomType'] ?? room.name,
        'guestCount': booking['guestCount'] ?? _guestCount,
        'nights': booking['nights'] ?? _nights,
        'checkInAt': booking['checkInAt'] ?? _checkInDate.toIso8601String(),
        'checkOutAt': booking['checkOutAt'] ?? _checkOutDate.toIso8601String(),
        'serviceFee': booking['serviceFee'] ?? serviceFee,
        'deliveryFee':
            booking['deliveryFee'] ?? booking['serviceFee'] ?? serviceFee,
        'items': normalizedItems.isNotEmpty
            ? normalizedItems
                  .map(
                    (item) => {
                      ...item,
                      'name': item['name'] ?? room.name,
                      'quantity': item['quantity'] ?? _nights,
                      'price': item['price'] ?? roomRate,
                      'total': item['total'] ?? total,
                      'metadata': {
                        if (item['metadata'] is Map)
                          ...Map<String, dynamic>.from(item['metadata'] as Map),
                        'hotelId': _hotel.id,
                        'hotelName': _hotel.name,
                        'checkInAt': _checkInDate.toIso8601String(),
                        'checkOutAt': _checkOutDate.toIso8601String(),
                        'guestCount': _guestCount,
                        'nights': _nights,
                      },
                    },
                  )
                  .toList()
            : [
                {
                  'id': booking['id'],
                  'name': room.name,
                  'quantity': _nights,
                  'price': roomRate,
                  'total': total,
                  'metadata': {
                    'hotelId': _hotel.id,
                    'hotelName': _hotel.name,
                    'checkInAt': _checkInDate.toIso8601String(),
                    'checkOutAt': _checkOutDate.toIso8601String(),
                    'guestCount': _guestCount,
                    'nights': _nights,
                  },
                },
              ],
      };

      context.push(
        '/checkout/success',
        extra: {
          'orderId': booking['id'],
          'amount': total,
          'payment': l10n.t('hotel_booking.pay_at_hotel'),
          'delivery': l10n.t('hotel_booking.booking_confirmed'),
          'moduleName': _hotel.name,
          'itemCount': 1,
          'trackingRoute': '/hotel/order/${booking['id']}',
          'trackingExtra': trackingBooking,
        },
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      final routeMissing =
          message.contains('Route not found') ||
          message.contains('404') ||
          message.contains('Failed to post data: 404');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            routeMissing
                ? 'Hotel booking backend route is not live yet. Redeploy the backend with /orders/hotel-bookings enabled.'
                : l10n.t('hotel_booking.error', params: {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final room = _selectedRoom;
    final roomRate = (room?.pricePerNight ?? _hotel.pricePerNight) * _nights;
    final serviceFee = roomRate * 0.05;
    final tax = roomRate * 0.08;
    final total = roomRate + serviceFee + tax;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('hotel_booking.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const _HotelBookingShimmer()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.hotelBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.hotel_rounded,
                              color: AppColors.hotel,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hotel.name,
                                  style: AppTextStyles.labelLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_hotel.city} • ${_hotel.address}',
                                  style: AppTextStyles.caption,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _BookingField(
                            label: l10n.t('hotel_booking.check_in'),
                            value: DateFormat('MMM d, y').format(_checkInDate),
                            icon: Icons.calendar_today_rounded,
                            onTap: _selectCheckInDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BookingField(
                            label: l10n.t('hotel_booking.check_out'),
                            value: DateFormat('MMM d, y').format(_checkOutDate),
                            icon: Icons.calendar_today_rounded,
                            onTap: _selectCheckOutDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BookingField(
                            label: l10n.t('hotel_booking.guests'),
                            value: '$_guestCount',
                            icon: Icons.person_outline_rounded,
                            onTap: _selectGuests,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.t('hotel_detail.available_rooms'),
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 12),
                    ..._hotel.roomOptions.map(
                      (option) => _SelectableRoomCard(
                        option: option,
                        isSelected: option.id == _selectedRoomId,
                        onTap: option.available
                            ? () => setState(() => _selectedRoomId = option.id)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Column(
                        children: [
                          _HotelSummaryRow(
                            l10n.t('hotel_booking.nights'),
                            '$_nights',
                          ),
                          _HotelSummaryRow(
                            l10n.t('hotel_booking.guests'),
                            '$_guestCount',
                          ),
                          _HotelSummaryRow(
                            l10n.t('hotel_booking.room'),
                            room?.name ?? '-',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.t('hotel_booking.guest_info'),
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _guestNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: l10n.t('hotel_booking.full_name'),
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _guestEmailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: l10n.t('hotel_booking.email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) {
                          return 'Email is required.';
                        }
                        final emailRegex = RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        );
                        if (!emailRegex.hasMatch(email)) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _guestPhoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: l10n.t('hotel_booking.phone'),
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: (value) {
                        final phone = value?.trim() ?? '';
                        if (phone.isEmpty) {
                          return null;
                        }
                        if (phone.length < 6) {
                          return 'Enter a valid phone number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.t('hotel_booking.special_requests'),
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _specialRequestsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.t('hotel_booking.special_requests_hint'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.hotelBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _HotelSummaryRow(
                            l10n.t(
                              'hotel_booking.room_rate',
                              params: {'count': '$_nights'},
                            ),
                            '\$${roomRate.toStringAsFixed(2)}',
                          ),
                          _HotelSummaryRow(
                            l10n.t('hotel_booking.service_fee'),
                            '\$${serviceFee.toStringAsFixed(2)}',
                          ),
                          _HotelSummaryRow(
                            l10n.t('hotel_booking.tax'),
                            '\$${tax.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 20),
                          _HotelSummaryRow(
                            l10n.t('hotel_booking.total'),
                            '\$${total.toStringAsFixed(2)}',
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: l10n.t(
                        'hotel_booking.confirm',
                        params: {'amount': total.toStringAsFixed(2)},
                      ),
                      color: AppColors.hotel,
                      isLoading: _isSubmitting,
                      onPressed: _submitBooking,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BookingField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _BookingField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.hotel),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _GuestAdjustButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GuestAdjustButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.extraLightGrey : AppColors.hotelBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppColors.mediumGrey : AppColors.hotel,
        ),
      ),
    );
  }
}

class _SelectableRoomCard extends StatelessWidget {
  final HotelRoomOption option;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SelectableRoomCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.hotel : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.hotelBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bed_rounded,
                color: AppColors.hotel,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(option.description, style: AppTextStyles.caption),
                  const SizedBox(height: 6),
                  Text(
                    '${option.capacity} guests',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.hotel,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${option.pricePerNight.toStringAsFixed(0)}${l10n.t('hotel.per_night')}',
                    style: AppTextStyles.priceSmall.copyWith(
                      color: AppColors.hotel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              option.available
                  ? isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded
                  : Icons.block_rounded,
              color: option.available ? AppColors.hotel : AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _HotelSummaryRow(this.label, this.value, {this.bold = false});

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
          Text(
            value,
            style: bold
                ? AppTextStyles.priceSmall.copyWith(color: AppColors.hotel)
                : AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _HotelBookingShimmer extends StatelessWidget {
  const _HotelBookingShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerBlock(width: double.infinity, height: 88, radius: 16),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 74,
                    radius: 14,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 74,
                    radius: 14,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 74,
                    radius: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ShimmerBlock(width: 124, height: 20),
            SizedBox(height: 12),
            _BookingRoomCardShimmer(),
            SizedBox(height: 12),
            _BookingRoomCardShimmer(),
            SizedBox(height: 20),
            ShimmerBlock(width: double.infinity, height: 112, radius: 16),
            SizedBox(height: 20),
            ShimmerBlock(width: 140, height: 20),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 56, radius: 14),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 56, radius: 14),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 56, radius: 14),
            SizedBox(height: 20),
            ShimmerBlock(width: 138, height: 20),
            SizedBox(height: 12),
            ShimmerBlock(width: double.infinity, height: 96, radius: 14),
            SizedBox(height: 20),
            ShimmerBlock(width: double.infinity, height: 132, radius: 16),
            SizedBox(height: 24),
            ShimmerBlock(width: double.infinity, height: 54, radius: 16),
          ],
        ),
      ),
    );
  }
}

class _BookingRoomCardShimmer extends StatelessWidget {
  const _BookingRoomCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          ShimmerBlock(width: 70, height: 70, radius: 12),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBlock(width: 150, height: 18),
                SizedBox(height: 8),
                ShimmerBlock(width: 120, height: 12, radius: 10),
                SizedBox(height: 8),
                ShimmerBlock(width: 80, height: 12, radius: 10),
                SizedBox(height: 8),
                ShimmerBlock(width: 100, height: 16, radius: 10),
              ],
            ),
          ),
          SizedBox(width: 12),
          ShimmerBlock(width: 24, height: 24, radius: 999),
        ],
      ),
    );
  }
}
