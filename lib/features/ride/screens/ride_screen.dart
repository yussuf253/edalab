import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class RideScreen extends StatefulWidget {
  const RideScreen({super.key});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  String _currentLocation = 'Current Location';
  String _destination = 'Where to?';

  final List<({String title, String address, IconData icon, double distance})> _savedPlaces = [
    (title: 'Home', address: '123 Main St', icon: Icons.home_rounded, distance: 4.2),
    (title: 'Work', address: '456 Office Ave', icon: Icons.work_rounded, distance: 6.8),
    (title: 'City Mall', address: '789 Shopping Blvd', icon: Icons.shopping_bag_rounded, distance: 5.2),
    (title: 'Central Park', address: '321 Green Lane', icon: Icons.park_rounded, distance: 3.7),
    (title: 'Airport', address: 'International Airport', icon: Icons.flight_rounded, distance: 9.5),
    (title: 'Train Station', address: 'Central Station', icon: Icons.train_rounded, distance: 7.1),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ride'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.extraLightGrey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text('Map View', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentLocation = 'Current Location');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pickup reset to current location.')),
                        );
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppSpacing.shadowMd,
                        ),
                        child: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
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
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectPlace(isPickup: true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.extraLightGrey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _currentLocation,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Column(
                      children: List.generate(
                        3,
                        (_) => Container(
                          width: 2,
                          height: 6,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          color: AppColors.lightGrey,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _selectPlace(isPickup: false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.extraLightGrey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _destination,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: _destination == 'Where to?' ? AppColors.mediumGrey : AppColors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Quick Rides', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickRide(
                  Icons.home_rounded,
                  'Home',
                  '123 Main St',
                  onTap: () => _openRideBooking('Home', '123 Main St', 4.2),
                ),
                const SizedBox(width: 12),
                _QuickRide(
                  Icons.work_rounded,
                  'Work',
                  '456 Office Ave',
                  onTap: () => _openRideBooking('Work', '456 Office Ave', 6.8),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent Places', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            ..._savedPlaces.skip(2).map(
              (p) => GestureDetector(
                onTap: () => _openRideBooking(p.title, p.address, p.distance),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.rideBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(p.icon, color: AppColors.ride, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.title, style: AppTextStyles.labelMedium),
                            Text(p.address, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.mediumGrey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'First 3 Rides Free! 🎉',
                          style: AppTextStyles.h4.copyWith(color: AppColors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'New users get first 3 rides completely free',
                          style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Offer saved to your account.')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(10)),
                      child: Text('Claim', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPlace({required bool isPickup}) async {
    final selected = await showModalBottomSheet<({String title, String address, double distance})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _PlacePickerSheet(
          isPickup: isPickup,
          places: _savedPlaces,
        );
      },
    );

    if (selected == null) return;

    if (isPickup) {
      setState(() => _currentLocation = selected.address);
      return;
    }

    setState(() => _destination = selected.address);
    _openRideBooking(selected.title, selected.address, selected.distance);
  }

  void _openRideBooking(String title, String address, double distance) {
    context.push(
      '/ride/book',
      extra: {
        'pickup': _currentLocation,
        'destinationTitle': title,
        'destination': address,
        'distance': distance,
      },
    );
  }
}

class _PlacePickerSheet extends StatefulWidget {
  final bool isPickup;
  final List<({String title, String address, IconData icon, double distance})> places;

  const _PlacePickerSheet({
    required this.isPickup,
    required this.places,
  });

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final showTypedDestination = !widget.isPickup && _searchController.text.trim().isNotEmpty;
    final filteredPlaces = widget.places.where((place) {
      if (query.isEmpty) return true;
      return place.title.toLowerCase().contains(query) ||
          place.address.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isPickup ? 'Select pickup' : 'Choose destination',
                style: AppTextStyles.h3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.isPickup ? 'Search pickup point...' : 'Search destination...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.extraLightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (showTypedDestination)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.rideBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_location_alt_rounded, color: AppColors.ride),
                  ),
                  title: Text(
                    _searchController.text.trim(),
                    style: AppTextStyles.labelMedium,
                  ),
                  subtitle: Text('Use typed destination', style: AppTextStyles.caption),
                  onTap: () => Navigator.of(context).pop((
                    title: _searchController.text.trim(),
                    address: _searchController.text.trim(),
                    distance: 5.0,
                  )),
                ),
              Expanded(
                child: ListView(
                  children: [
                    ...filteredPlaces.map(
                      (place) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.rideBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(place.icon, color: AppColors.ride),
                        ),
                        title: Text(place.title, style: AppTextStyles.labelMedium),
                        subtitle: Text(place.address, style: AppTextStyles.caption),
                        onTap: () => Navigator.of(context).pop((
                          title: place.title,
                          address: place.address,
                          distance: place.distance,
                        )),
                      ),
                    ),
                    if (filteredPlaces.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No saved places match your search.',
                          style: AppTextStyles.caption,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRide extends StatelessWidget {
  final IconData icon;
  final String name;
  final String address;
  final VoidCallback onTap;

  const _QuickRide(this.icon, this.name, this.address, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppSpacing.shadowSm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.rideBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppColors.ride, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.labelMedium),
                    Text(address, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
