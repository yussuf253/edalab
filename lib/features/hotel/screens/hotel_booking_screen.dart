import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/models/models.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/auth_gate.dart';

class HotelBookingScreen extends StatefulWidget {
  final String hotelId;
  const HotelBookingScreen({super.key, required this.hotelId});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  late HotelModel _hotel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _hotel = HotelModel.sampleHotels.firstWhere(
      (hotel) => hotel.id == widget.hotelId,
      orElse: () => HotelModel.sampleHotels.first,
    );
    _loadHotel();
  }

  Future<void> _loadHotel() async {
    try {
      final response = await ApiClient.get('/catalog/hotels/${widget.hotelId}');
      if (!mounted) return;
      setState(() {
        _hotel = HotelModel.fromApi(Map<String, dynamic>.from(response as Map));
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final h = _hotel;
    final defaultAddress = auth.user?.addresses
        .cast<AddressModel?>()
        .firstWhere(
          (address) => address?.isDefault == true,
          orElse: () => auth.user?.addresses.isNotEmpty == true
              ? auth.user!.addresses.first
              : null,
        );
    final checkIn = DateTime.now().add(const Duration(days: 1));
    final checkOut = checkIn.add(const Duration(days: 3));
    final nights = 3;
    final roomRate = h.pricePerNight * nights;
    final serviceFee = roomRate * 0.05;
    final tax = roomRate * 0.08;
    final total = roomRate + serviceFee + tax;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel mini
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
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
                        Text(h.name, style: AppTextStyles.labelLarge),
                        Text(
                          'Standard Room • City View',
                          style: AppTextStyles.caption,
                        ),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: SizedBox(
                              width: 120,
                              child: LinearProgressIndicator(minHeight: 3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Booking details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _Row('Check-in', DateFormat('MMM d, y').format(checkIn)),
                  _Row('Check-out', DateFormat('MMM d, y').format(checkOut)),
                  _Row('Nights', '$nights'),
                  _Row('Guests', '2 Adults'),
                  _Row('Room', 'Standard Room'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Guest Information', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                hintText: auth.user?.fullName ?? 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: InputDecoration(
                hintText: auth.user?.email ?? 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Text('Special Requests', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Any special requests...',
              ),
            ),
            const SizedBox(height: 20),
            if (defaultAddress != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved Address', style: AppTextStyles.h4),
                    const SizedBox(height: 8),
                    Text(
                      '${defaultAddress.label}: ${defaultAddress.address}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            if (defaultAddress != null) const SizedBox(height: 20),
            // Price breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.hotelBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _Row(
                    'Room Rate ($nights nights)',
                    '\$${roomRate.toStringAsFixed(2)}',
                  ),
                  _Row('Service Fee', '\$${serviceFee.toStringAsFixed(2)}'),
                  _Row('Tax', '\$${tax.toStringAsFixed(2)}'),
                  const Divider(height: 20),
                  _Row('Total', '\$${total.toStringAsFixed(2)}', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Confirm Booking • \$${total.toStringAsFixed(2)}',
              color: AppColors.hotel,
              onPressed: () async {
                final allowed = await requireLoggedIn(
                  context,
                  message: 'Please log in to confirm your hotel booking.',
                );
                if (!context.mounted || !allowed) return;

                try {
                  await ApiClient.post('/orders', {
                    'userId': auth.user!.id,
                    'moduleType': 'HOTEL',
                    'subtotal': roomRate,
                    'tax': tax,
                    'deliveryFee': serviceFee,
                    'total': total,
                    'items': [
                      {
                        'id': h.id,
                        'name': '${h.name} - Standard Room',
                        'price': roomRate,
                        'quantity': 1,
                        'total': roomRate,
                        'metadata': {
                          'hotelId': h.id,
                          'hotelName': h.name,
                          'nights': nights,
                          'checkIn': checkIn.toIso8601String(),
                          'checkOut': checkOut.toIso8601String(),
                          'guests': 2,
                        },
                      },
                    ],
                  });
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Hotel booked successfully! 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  context.go('/');
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

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
