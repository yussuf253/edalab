import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../services/car_rental_service.dart';

// ─── Color palette for the rental module ──────────────────────────────────
// Using a dark teal/slate palette distinct from ride (AppColors.ride = green)
const _rentalPrimary = Color(0xFF1E3A5F); // deep navy
const _rentalAccent = Color(0xFF2DD4BF); // teal accent
const _rentalBg = Color(0xFFF0F9FF); // icy light blue tint
const _rentalSurface = Color(0xFF0F2744); // darker navy for cards

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  List<CarRentalCar> _cars = [];
  List<String> _types = [];
  String? _selectedType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final cars = await CarRentalService.fetchCars(type: _selectedType);
    if (!mounted) return;
    final types = [
      'All',
      ...{...cars.map((c) => c.type)},
    ];
    setState(() {
      _cars = cars;
      if (_types.isEmpty) _types = types;
      _isLoading = false;
    });
  }

  List<CarRentalCar> get _filtered {
    if (_selectedType == null || _selectedType == 'All') return _cars;
    return _cars.where((c) => c.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _rentalBg,
      body: CustomScrollView(
        slivers: [
          _RentalAppBar(),
          SliverToBoxAdapter(child: _buildTypeFilter()),
          SliverToBoxAdapter(child: _buildStats()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            sliver: _isLoading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: AppShimmer(
                          child: ShimmerBlock(
                            width: double.infinity,
                            height: 200,
                            radius: 20,
                          ),
                        ),
                      ),
                      childCount: 4,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final car = _filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CarCard(
                          car: car,
                          onTap: () =>
                              context.push('/car-rental/${car.id}', extra: car),
                        ),
                      );
                    }, childCount: _filtered.length),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    if (_types.isEmpty) return const SizedBox.shrink();
    final filters = ['All', ..._types.where((t) => t != 'All')];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = filters[index];
          final selected = type == 'All'
              ? (_selectedType == null || _selectedType == 'All')
              : _selectedType == type;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = type == 'All' ? null : type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? _rentalPrimary : AppColors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Text(
                type,
                style: AppTextStyles.labelMedium.copyWith(
                  color: selected ? _rentalAccent : AppColors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats() {
    final available = _filtered.where((c) => c.available).length;
    final minPrice = _filtered.isEmpty
        ? 0.0
        : _filtered.map((c) => c.pricePerDay).reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            '$available cars available',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
          const Spacer(),
          if (_filtered.isNotEmpty)
            Text(
              'From DJF ${minPrice.toStringAsFixed(0)}/day',
              style: AppTextStyles.labelMedium.copyWith(color: _rentalPrimary),
            ),
        ],
      ),
    );
  }
}

// ─── Sliver App Bar ────────────────────────────────────────────────────────

class _RentalAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _rentalPrimary,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => context.canPop() ? context.pop() : context.go('/ride'),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Navy gradient background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_rentalSurface, _rentalPrimary],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              right: -30,
              top: -20,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rentalAccent.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _rentalAccent.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _rentalAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.car_rental_rounded,
                          color: _rentalAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Car Rental',
                        style: AppTextStyles.h3.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Flexible daily rentals across Djibouti',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        title: Text(
          'Car Rental',
          style: AppTextStyles.h4.copyWith(color: Colors.white),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }
}

// ─── Car Card ─────────────────────────────────────────────────────────────

class _CarCard extends StatelessWidget {
  final CarRentalCar car;
  final VoidCallback onTap;

  const _CarCard({required this.car, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / placeholder
            _CarImageSection(car: car),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + badge row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(car.name, style: AppTextStyles.h4),
                            const SizedBox(height: 2),
                            Text(
                              '${car.year != null ? '${car.year} · ' : ''}${car.type}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.mediumGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (car.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _rentalAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            car.badge!,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _rentalPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Specs row
                  Row(
                    children: [
                      _SpecChip(
                        icon: Icons.people_rounded,
                        label: '${car.seats} seats',
                      ),
                      const SizedBox(width: 8),
                      _SpecChip(
                        icon: Icons.settings_rounded,
                        label: car.transmission,
                      ),
                      const SizedBox(width: 8),
                      _SpecChip(
                        icon: Icons.local_gas_station_rounded,
                        label: car.fuelType,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Price + CTA
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DJF ${car.pricePerDay.toStringAsFixed(0)}',
                            style: AppTextStyles.h3.copyWith(
                              color: _rentalPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '/ day',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_rentalPrimary, Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Book Now',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarImageSection extends StatelessWidget {
  final CarRentalCar car;

  const _CarImageSection({required this.car});

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

  Color get _typeColor {
    switch (car.type.toLowerCase()) {
      case 'suv':
        return const Color(0xFF7C3AED);
      case 'van':
        return const Color(0xFF065F46);
      case 'premium':
        return const Color(0xFFB45309);
      default:
        return _rentalPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (car.imageUrl != null && car.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Image.network(
          car.imageUrl!,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _typeColor.withValues(alpha: 0.08),
            _typeColor.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Center(
        child: Icon(_icon, size: 72, color: _typeColor.withValues(alpha: 0.35)),
      ),
    );
  }
}

class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SpecChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _rentalBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _rentalPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: _rentalPrimary),
          ),
        ],
      ),
    );
  }
}
