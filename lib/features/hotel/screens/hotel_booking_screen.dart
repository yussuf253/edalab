import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/models/models.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

class HotelBookingScreen extends StatelessWidget {
  final String hotelId;
  const HotelBookingScreen({super.key, required this.hotelId});

  @override
  Widget build(BuildContext context) {
    final h = HotelModel.sampleHotels.firstWhere((h) => h.id == hotelId, orElse: () => HotelModel.sampleHotels.first);
    final nights = 3;
    final roomRate = h.pricePerNight * nights;
    final serviceFee = roomRate * 0.05;
    final tax = roomRate * 0.08;
    final total = roomRate + serviceFee + tax;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Summary'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel mini
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppColors.hotelBg, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.hotel_rounded, color: AppColors.hotel, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.name, style: AppTextStyles.labelLarge),
                        Text('Standard Room • City View', style: AppTextStyles.caption),
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
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _Row('Check-in', 'Mar 25, 2026'),
                  _Row('Check-out', 'Mar 28, 2026'),
                  _Row('Nights', '$nights'),
                  _Row('Guests', '2 Adults'),
                  _Row('Room', 'Standard Room'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Guest Information', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded))),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 12),
            TextFormField(decoration: const InputDecoration(hintText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 20),
            Text('Special Requests', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            TextFormField(maxLines: 3, decoration: const InputDecoration(hintText: 'Any special requests...')),
            const SizedBox(height: 20),
            // Price breakdown
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.hotelBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _Row('Room Rate ($nights nights)', '\$${roomRate.toStringAsFixed(2)}'),
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
                final auth = context.read<AuthProvider>();
                try {
                  await ApiClient.post('/orders', {
                    'userId': auth.user?.id ?? 'guest',
                    'moduleType': 'HOTEL',
                    'subtotal': roomRate,
                    'tax': tax,
                    'deliveryFee': serviceFee,
                    'total': total,
                    'items': [{'hotelId': h.id, 'name': h.name, 'nights': nights}],
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Hotel booked successfully! 🎉'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  context.go('/');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
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
          Text(label, style: bold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
          Text(value, style: bold ? AppTextStyles.priceSmall.copyWith(color: AppColors.hotel) : AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
