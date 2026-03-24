import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_search_bar.dart';

class HotelScreen extends StatefulWidget {
  const HotelScreen({super.key});

  @override
  State<HotelScreen> createState() => _HotelScreenState();
}

class _HotelScreenState extends State<HotelScreen> {
  final TextEditingController _searchController = TextEditingController();
  DateTime _checkInDate = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 4));
  int _guestCount = 2;
  String _searchQuery = '';
  List<HotelModel> _hotels = HotelModel.sampleHotels;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    try {
      final response = await ApiClient.get('/catalog/hotels');
      final items = (response as List)
          .map(
            (item) =>
                HotelModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _hotels = items.isEmpty ? HotelModel.sampleHotels : items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotels = _filteredHotels();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hotels'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppSearchBar(
                hint: 'Search hotels, locations...',
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
                suffix: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.mediumGrey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: _BookingField(
                      label: 'Check-in',
                      value: _formatDate(_checkInDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: _selectCheckInDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BookingField(
                      label: 'Check-out',
                      value: _formatDate(_checkOutDate),
                      icon: Icons.calendar_today_rounded,
                      onTap: _selectCheckOutDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BookingField(
                      label: 'Guests',
                      value: '$_guestCount',
                      icon: Icons.person_outline_rounded,
                      onTap: _selectGuests,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Popular Destinations 🌍', style: AppTextStyles.h4),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                children: [
                  _DestChip(
                    '🏖️',
                    'Beach',
                    onTap: () => _applyDestination('Beach'),
                  ),
                  _DestChip(
                    '🏔️',
                    'Mountain',
                    onTap: () => _applyDestination('Mountain'),
                  ),
                  _DestChip(
                    '🌆',
                    'City',
                    onTap: () => _applyDestination('City'),
                  ),
                  _DestChip(
                    '🏝️',
                    'Island',
                    onTap: () => _applyDestination('Island'),
                  ),
                  _DestChip(
                    '🏜️',
                    'Desert',
                    onTap: () => _applyDestination('Desert'),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Text('Recommended Hotels', style: AppTextStyles.h4),
                  const Spacer(),
                  Text('${hotels.length} found', style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (hotels.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.hotel_rounded,
                        size: 44,
                        color: AppColors.mediumGrey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hotels match your search',
                        style: AppTextStyles.h4,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try another hotel name or destination.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final h = hotels[index];
                final type = h.amenities.isNotEmpty
                    ? h.amenities.first
                    : 'Hotel';
                return GestureDetector(
                  onTap: () => context.push('/hotel/detail/${h.id}'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.hotel.withValues(alpha: 0.3),
                                AppColors.hotel.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.hotel_rounded,
                                  size: 48,
                                  color: AppColors.hotel.withValues(alpha: 0.4),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.hotel,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(type, style: AppTextStyles.badge),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.favorite_border_rounded,
                                    size: 18,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h.name, style: AppTextStyles.labelLarge),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${h.city} • ${h.address}',
                                      style: AppTextStyles.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${h.rating}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${h.reviewsCount})',
                                    style: AppTextStyles.caption,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\$${h.pricePerNight.toInt()}',
                                    style: AppTextStyles.priceSmall.copyWith(
                                      color: AppColors.hotel,
                                    ),
                                  ),
                                  Text('/night', style: AppTextStyles.caption),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: hotels.length),
            ),
        ],
      ),
    );
  }

  List<HotelModel> _filteredHotels() {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      return _hotels;
    }

    return _hotels.where((hotel) {
      return hotel.name.toLowerCase().contains(query) ||
          hotel.city.toLowerCase().contains(query) ||
          hotel.address.toLowerCase().contains(query) ||
          hotel.amenities.any(
            (amenity) => amenity.toLowerCase().contains(query),
          );
    }).toList();
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}';
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
                    Text('Select Guests', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Guests',
                            style: AppTextStyles.labelLarge,
                          ),
                        ),
                        _GuestButton(
                          icon: Icons.remove_rounded,
                          onTap: tempGuests > 1
                              ? () => setModalState(() => tempGuests--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('$tempGuests', style: AppTextStyles.h4),
                        ),
                        _GuestButton(
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
                          'Apply',
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

  void _applyDestination(String destination) {
    final mappedQuery = switch (destination) {
      'Beach' => 'miami',
      'Mountain' => 'aspen',
      'City' => 'new york',
      'Island' => 'beach',
      'Desert' => 'resort',
      _ => destination.toLowerCase(),
    };

    _searchController.text = mappedQuery;
    setState(() => _searchQuery = mappedQuery);
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

class _GuestButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _GuestButton({required this.icon, required this.onTap});

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

class _DestChip extends StatelessWidget {
  final String emoji;
  final String name;
  final VoidCallback onTap;

  const _DestChip(this.emoji, this.name, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.hotelBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(name, style: AppTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }
}
