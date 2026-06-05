import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/car_rental_service.dart';

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  late Future<List<CarRentalCar>> _carsFuture;

  @override
  void initState() {
    super.initState();
    _carsFuture = CarRentalService.fetchCars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Car Rentals')),
      body: FutureBuilder<List<CarRentalCar>>(
        future: _carsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final cars = snapshot.data ?? [];
          if (cars.isEmpty) {
            return const Center(child: Text('No cars available'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cars.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final car = cars[index];
              return GestureDetector(
                onTap: () => context.push('/car-rental/${car.id}', extra: car),
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
                        width: 72,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.extraLightGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(car.name, style: AppTextStyles.labelLarge),
                            const SizedBox(height: 4),
                            Text(
                              '${car.type} • ${car.seats} seats',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'DJF${car.pricePerDay}',
                        style: AppTextStyles.labelMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
