import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class HotelOrderDetailScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? booking;

  const HotelOrderDetailScreen({
    super.key,
    required this.bookingId,
    this.booking,
  });

  @override
  State<HotelOrderDetailScreen> createState() => _HotelOrderDetailScreenState();
}

class _HotelOrderDetailScreenState extends State<HotelOrderDetailScreen> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _isLoading = widget.booking == null;
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiClient.get('/orders/$userId', forceRefresh: true);
      final orders = response is List ? response : const [];
      final match = orders.cast<dynamic>().firstWhere(
        (entry) => (entry as Map)['id']?.toString() == widget.bookingId,
        orElse: () => null,
      );
      if (!mounted) return;
      setState(() {
        if (match != null) {
          _booking = {
            ...?_booking,
            ...Map<String, dynamic>.from(match as Map),
          };
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _booking ?? const <String, dynamic>{};
    final items = (data['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final firstItem = items.isNotEmpty ? items.first : null;
    final metadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : <String, dynamic>{};

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/hotel');
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hotel Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/hotel');
            }
          },
        ),
      ),
      body: _isLoading
          ? const DetailContentShimmer(
              accentColor: AppColors.hotel,
              showHero: false,
            )
          : _booking == null
          ? const _MissingHotelState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HotelHero(
                    hotelName: data['moduleName']?.toString() ?? 'Hotel Booking',
                    roomName: firstItem?['name']?.toString() ?? 'Room',
                    status: _pretty(data['status']?.toString()),
                    total: ((data['total'] as num?)?.toDouble() ?? 0),
                  ),
                  const SizedBox(height: 16),
                  _TimelineCard(
                    checkIn:
                        metadata['checkInAt']?.toString() ??
                        metadata['checkIn']?.toString(),
                    checkOut:
                        metadata['checkOutAt']?.toString() ??
                        metadata['checkOut']?.toString(),
                    nights:
                        (firstItem?['quantity'] as num?)?.toInt() ??
                        (metadata['nights'] as num?)?.toInt() ??
                        1,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _HotelStatTile(
                          icon: Icons.people_alt_outlined,
                          label: 'Guests',
                          value:
                              metadata['guestCount']?.toString() ??
                              metadata['guests']?.toString() ??
                              '1',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HotelStatTile(
                          icon: Icons.schedule_outlined,
                          label: 'Booked',
                          value: _formatDate(data['createdAt']?.toString()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _HotelInfoCard(
                    title: 'Booking Summary',
                    rows: [
                      _HotelRowData(
                        'Stay',
                        '${data['moduleName']?.toString() ?? 'Hotel'} • ${firstItem?['name']?.toString() ?? 'Room'}',
                      ),
                      _HotelRowData(
                        'Subtotal',
                        '\$${((data['subtotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      ),
                      _HotelRowData(
                        'Taxes',
                        '\$${((data['tax'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      ),
                      _HotelRowData(
                        'Fees',
                        '\$${((data['deliveryFee'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      ),
                      _HotelRowData(
                        'Total',
                        '\$${((data['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

class _HotelHero extends StatelessWidget {
  final String hotelName;
  final String roomName;
  final String status;
  final double total;

  const _HotelHero({
    required this.hotelName,
    required this.roomName,
    required this.status,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.hotel, AppColors.hotel.withValues(alpha: 0.78)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: AppColors.white,
                  size: 28,
                ),
              ),
              const Spacer(),
              _HeroPill(label: status),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hotelName,
            style: AppTextStyles.h3.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 6),
          Text(
            roomName,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text(
            '\$${total.toStringAsFixed(2)} total stay',
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final String? checkIn;
  final String? checkOut;
  final int nights;

  const _TimelineCard({
    required this.checkIn,
    required this.checkOut,
    required this.nights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StayPoint(
                  title: 'Check-in',
                  value: _formatDate(checkIn),
                  alignEnd: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.hotel,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      color: AppColors.hotel.withValues(alpha: 0.28),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.hotel,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _StayPoint(
                  title: 'Check-out',
                  value: _formatDate(checkOut),
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.hotel.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$nights night${nights == 1 ? '' : 's'} reserved',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.hotel),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _StayPoint extends StatelessWidget {
  final String title;
  final String value;
  final bool alignEnd;

  const _StayPoint({
    required this.title,
    required this.value,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.labelLarge, textAlign: TextAlign.end),
      ],
    );
  }
}

class _HotelStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HotelStatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.hotel.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.hotel, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelInfoCard extends StatelessWidget {
  final String title;
  final List<_HotelRowData> rows;

  const _HotelInfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 14),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      row.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(row.value, style: AppTextStyles.labelMedium),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelRowData {
  final String label;
  final String value;
  const _HotelRowData(this.label, this.value);
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.white),
      ),
    );
  }
}

class _MissingHotelState extends StatelessWidget {
  const _MissingHotelState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: () => context.go('/hotel'),
        child: const Text('Back to Hotels'),
      ),
    );
  }
}

String _formatDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return raw;
  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${parsed.day.toString().padLeft(2, '0')} ${monthNames[parsed.month - 1]} ${parsed.year}';
}

String _pretty(String? raw) =>
    (raw == null || raw.isEmpty) ? 'Pending' : raw.replaceAll('_', ' ');
