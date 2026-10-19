import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../services/car_rental_service.dart';
import 'my_car_rentals_screen.dart';

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  final _searchController = TextEditingController();
  List<CarRentalCar> _cars = const [];
  bool _isLoading = true;
  String? _error;
  String? _selectedType;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cars = await CarRentalService.fetchCars();
      if (!mounted) return;
      setState(() {
        _cars = cars;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  List<String> get _types =>
      _cars.map((car) => car.type).toSet().toList()..sort();

  List<CarRentalCar> get _filteredCars {
    final search = _search.trim().toLowerCase();
    final cars = _cars.where((car) {
      final matchesType = _selectedType == null || car.type == _selectedType;
      final matchesSearch =
          search.isEmpty ||
          car.name.toLowerCase().contains(search) ||
          car.type.toLowerCase().contains(search) ||
          car.features.any((feature) => feature.toLowerCase().contains(search));
      return matchesType && matchesSearch;
    }).toList();
    cars.sort((left, right) => left.pricePerDay.compareTo(right.pricePerDay));
    return cars;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cars = _filteredCars;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('car_rental.title')),
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
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              sliver: SliverToBoxAdapter(child: _hero(l10n)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(child: _searchField(l10n)),
            ),
            if (_cars.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.only(top: 14),
                sliver: SliverToBoxAdapter(child: _typeFilters(l10n)),
              ),
            if (_isLoading)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                sliver: SliverList.builder(
                  itemCount: 3,
                  itemBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: _CarLoadingTile(),
                  ),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _errorState(l10n),
              )
            else if (_cars.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(l10n, hasFilter: false),
              )
            else if (cars.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _emptyState(l10n, hasFilter: true),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.t(
                            'car_rental.available_count',
                            params: {'count': '${cars.length}'},
                          ),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                      Text(
                        l10n.t('car_rental.lowest_price_first'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                sliver: SliverList.builder(
                  itemCount: cars.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CarCard(
                      car: cars[index],
                      onTap: () => context.push(
                        '/car-rental/${cars[index].id}',
                        extra: cars[index],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hero(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('car_rental.hero_title'),
                  style: AppTextStyles.h4.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.t('car_rental.hero_subtitle'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.directions_car_filled_outlined,
              color: AppColors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(AppLocalizations l10n) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _search = value),
      decoration: InputDecoration(
        hintText: l10n.t('car_rental.search_hint'),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _search.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.t('car_rental.clear_search'),
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
              ),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _typeFilters(AppLocalizations l10n) {
    final filters = [null, ..._types];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = filters[index];
          final selected = _selectedType == type;
          return ChoiceChip(
            label: Text(type ?? l10n.t('car_rental.all_types')),
            selected: selected,
            onSelected: (_) => setState(() => _selectedType = type),
            selectedColor: AppColors.primarySurface,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.lightGrey,
            ),
          );
        },
      ),
    );
  }

  Widget _errorState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: AppColors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.t('car_rental.load_error'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.t('car_rental.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(AppLocalizations l10n, {required bool hasFilter}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 52,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.t(
                hasFilter ? 'car_rental.no_matches' : 'car_rental.no_cars',
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge,
            ),
            if (hasFilter) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _search = '';
                    _selectedType = null;
                  });
                },
                child: Text(l10n.t('car_rental.clear_filters')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarCard extends StatelessWidget {
  const _CarCard({required this.car, required this.onTap});

  final CarRentalCar car;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'rental-car-${car.id}',
                  child: _CarImage(car: car, height: 190),
                ),
                if (car.badge != null && car.badge!.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        car.badge!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: car.available
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.t(
                        car.available
                            ? 'car_rental.available'
                            : 'car_rental.unavailable',
                      ),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: car.available
                            ? AppColors.primaryDark
                            : AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.name, style: AppTextStyles.h4),
                  const SizedBox(height: 4),
                  Text(
                    '${car.year > 0 ? '${car.year} · ' : ''}${car.type}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _CarSpec(
                        icon: Icons.people_outline_rounded,
                        text: l10n.t(
                          'car_rental.seat_count',
                          params: {'count': '${car.seats}'},
                        ),
                      ),
                      if (car.transmission.isNotEmpty)
                        _CarSpec(
                          icon: Icons.settings_outlined,
                          text: car.transmission,
                        ),
                      if (car.fuelType.isNotEmpty)
                        _CarSpec(
                          icon: Icons.local_gas_station_outlined,
                          text: car.fuelType,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'DJF ${car.pricePerDay} / ${l10n.t('common.day')}',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
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

class _CarImage extends StatelessWidget {
  const _CarImage({required this.car, required this.height});

  final CarRentalCar car;
  final double height;

  @override
  Widget build(BuildContext context) {
    final image = car.imageUrl;
    if (image == null || image.trim().isEmpty) return _placeholder();
    return Image.network(
      image,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: height,
      color: AppColors.primarySurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled_outlined,
        size: 76,
        color: AppColors.primary,
      ),
    );
  }
}

class _CarSpec extends StatelessWidget {
  const _CarSpec({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: 5),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(color: AppColors.grey),
        ),
      ],
    );
  }
}

class _CarLoadingTile extends StatelessWidget {
  const _CarLoadingTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
