import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
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
    _booking = widget.booking == null
        ? null
        : _normalizeBooking(widget.booking!);
    _isLoading = widget.booking == null;
    _loadBooking();
  }

  Map<String, dynamic> _normalizeBooking(Map<String, dynamic> raw) {
    final normalized = Map<String, dynamic>.from(raw);
    final normalizedItems = (normalized['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (normalized['moduleName'] == null && normalized['hotelName'] != null) {
      normalized['moduleName'] = normalized['hotelName'];
    }
    if (normalized['deliveryFee'] == null && normalized['serviceFee'] != null) {
      normalized['deliveryFee'] = normalized['serviceFee'];
    }
    if (normalized['roomType'] == null && normalizedItems.isNotEmpty) {
      normalized['roomType'] = normalizedItems.first['name'];
    }
    if (normalizedItems.isEmpty &&
        (normalized['roomType'] != null || normalized['nights'] != null)) {
      normalized['items'] = [
        {
          'id': normalized['id'],
          'name': normalized['roomType']?.toString() ?? 'Room',
          'quantity': (normalized['nights'] as num?)?.toInt() ?? 1,
          'price': (normalized['subtotal'] as num?)?.toDouble() ?? 0,
          'total': (normalized['total'] as num?)?.toDouble() ?? 0,
          'metadata': {
            'hotelId': normalized['hotelId'],
            'hotelName':
                normalized['moduleName']?.toString() ??
                normalized['hotelName']?.toString(),
            'checkInAt': normalized['checkInAt'],
            'checkOutAt': normalized['checkOutAt'],
            'guestCount': normalized['guestCount'],
            'nights': normalized['nights'],
          },
        },
      ];
    } else {
      normalized['items'] = normalizedItems
          .map(
            (item) => {
              ...item,
              'metadata': {
                if (item['metadata'] is Map)
                  ...Map<String, dynamic>.from(item['metadata'] as Map),
                'hotelId': normalized['hotelId'],
                'hotelName':
                    normalized['moduleName']?.toString() ??
                    normalized['hotelName']?.toString(),
                'checkInAt':
                    (item['metadata'] is Map &&
                        Map<String, dynamic>.from(
                              item['metadata'] as Map,
                            )['checkInAt'] !=
                            null)
                    ? Map<String, dynamic>.from(
                        item['metadata'] as Map,
                      )['checkInAt']
                    : normalized['checkInAt'],
                'checkOutAt':
                    (item['metadata'] is Map &&
                        Map<String, dynamic>.from(
                              item['metadata'] as Map,
                            )['checkOutAt'] !=
                            null)
                    ? Map<String, dynamic>.from(
                        item['metadata'] as Map,
                      )['checkOutAt']
                    : normalized['checkOutAt'],
                'guestCount':
                    (item['metadata'] is Map &&
                        Map<String, dynamic>.from(
                              item['metadata'] as Map,
                            )['guestCount'] !=
                            null)
                    ? Map<String, dynamic>.from(
                        item['metadata'] as Map,
                      )['guestCount']
                    : normalized['guestCount'],
                'nights':
                    (item['metadata'] is Map &&
                        Map<String, dynamic>.from(
                              item['metadata'] as Map,
                            )['nights'] !=
                            null)
                    ? Map<String, dynamic>.from(
                        item['metadata'] as Map,
                      )['nights']
                    : normalized['nights'],
              },
            },
          )
          .toList();
    }

    return normalized;
  }

  void _applyBookingResponse(Map<String, dynamic> raw) {
    if (!mounted) return;
    setState(() {
      _booking = {...?_booking, ..._normalizeBooking(raw)};
      _isLoading = false;
    });
  }

  Future<void> _loadBooking() async {
    try {
      final response = await ApiClient.get(
        '/orders/hotel-bookings/${widget.bookingId}',
        forceRefresh: true,
      );
      _applyBookingResponse(Map<String, dynamic>.from(response as Map));
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = _booking ?? const <String, dynamic>{};
    final items = (data['items'] as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final firstItem = items.isNotEmpty ? items.first : null;
    final metadata = firstItem?['metadata'] is Map
        ? Map<String, dynamic>.from(firstItem!['metadata'] as Map)
        : <String, dynamic>{};
    final checkIn =
        metadata['checkInAt']?.toString() ??
        metadata['checkIn']?.toString() ??
        data['checkInAt']?.toString() ??
        data['checkIn']?.toString();
    final checkOut =
        metadata['checkOutAt']?.toString() ??
        metadata['checkOut']?.toString() ??
        data['checkOutAt']?.toString() ??
        data['checkOut']?.toString();
    final guestCount =
        metadata['guestCount']?.toString() ??
        metadata['guests']?.toString() ??
        data['guestCount']?.toString() ??
        '1';
    final nights =
        (firstItem?['quantity'] as num?)?.toInt() ??
        (metadata['nights'] as num?)?.toInt() ??
        (data['nights'] as num?)?.toInt() ??
        1;

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
          title: Text(l10n.t('hotel_tracking.title')),
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
                      hotelName:
                          data['moduleName']?.toString() ??
                          l10n.t('hotel_tracking.title'),
                      roomName: firstItem?['name']?.toString() ?? 'Room',
                      status: _pretty(data['status']?.toString()),
                      total: ((data['total'] as num?)?.toDouble() ?? 0),
                    ),
                    const SizedBox(height: 16),
                    _TimelineCard(
                      checkIn: checkIn,
                      checkOut: checkOut,
                      nights: nights,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _HotelStatTile(
                            icon: Icons.people_alt_outlined,
                            label: l10n.t('hotel_tracking.guests'),
                            value: guestCount,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HotelStatTile(
                            icon: Icons.schedule_outlined,
                            label: l10n.t('hotel_tracking.booked'),
                            value: _formatDate(data['createdAt']?.toString()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _HotelInfoCard(
                      title: l10n.t('hotel_tracking.summary'),
                      rows: [
                        _HotelRowData(
                          l10n.t('hotel_tracking.stay'),
                          '${data['moduleName']?.toString() ?? 'Hotel'} • ${firstItem?['name']?.toString() ?? 'Room'}',
                        ),
                        _HotelRowData(
                          l10n.t('hotel_tracking.subtotal'),
                          '\$${((data['subtotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                        ),
                        _HotelRowData(
                          l10n.t('hotel_tracking.taxes'),
                          '\$${((data['tax'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                        ),
                        _HotelRowData(
                          l10n.t('hotel_tracking.fees'),
                          '\$${((data['deliveryFee'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                        ),
                        _HotelRowData(
                          l10n.t('hotel_tracking.total'),
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
            AppLocalizations.of(context).t(
              'hotel_tracking.total_stay',
              params: {'amount': total.toStringAsFixed(2)},
            ),
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
                  title: AppLocalizations.of(
                    context,
                  ).t('hotel_tracking.check_in'),
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
                  title: AppLocalizations.of(
                    context,
                  ).t('hotel_tracking.check_out'),
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
              AppLocalizations.of(
                context,
              ).t('hotel_tracking.nights', params: {'count': '$nights'}),
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
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
        child: Text(AppLocalizations.of(context).t('hotel_tracking.back')),
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
