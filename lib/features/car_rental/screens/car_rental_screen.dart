import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../services/car_rental_service.dart';

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  late Future<List<CarRentalCar>> _carsFuture;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _carsFuture = CarRentalService.fetchCars();
  }

  List<CarRentalCar> _filterCars(List<CarRentalCar> cars) {
    if (_selectedType == null || _selectedType == 'All') {
      return cars;
    }
    return cars.where((c) => c.type == _selectedType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('car_rental.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<List<CarRentalCar>>(
        future: _carsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final cars = snapshot.data ?? [];
          if (cars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 64,
                    color: AppColors.extraLightGrey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.t('car_rental.no_cars'),
                    style: AppTextStyles.h4,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final types = ['All', ...cars.map((c) => c.type).toSet()];
          final filteredCars = _filterCars(cars);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final type in types)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: _selectedType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = selected ? type : null;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Cars list
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCars.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final car = filteredCars[index];
                    return _CarCard(
                      car: car,
                      onTap: () {
                        // Convert to Map for router compatibility
                        final Map<String, dynamic> carMap = {
                          'id': car.id,
                          'name': car.name,
                          'type': car.type,
                          'pricePerDay': car.pricePerDay,
                          'seats': car.seats,
                          'badge': car.badge,
                          'transmission': car.transmission,
                          'fuelType': car.fuelType,
                          'year': car.year,
                          'features': car.features,
                        };
                        context.push('/car-rental/${car.id}', extra: carMap);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car image placeholder
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.extraLightGrey,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 60,
                    color: AppColors.lightGrey,
                  ),
                  if (car.badge != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          car.badge!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Car details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    car.type,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 16,
                            color: AppColors.lightGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${car.seats} seats',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                      Text(
                        'DJF${car.pricePerDay}/day',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
