// ═══════════════════════════════════════════════════════════════════════════════
// INTEGRATION GUIDE — Car Rental Feature
// ═══════════════════════════════════════════════════════════════════════════════

// ─── 1. backend/src/routes/index.ts ─────────────────────────────────────────
// Add these two lines in the imports section and router.use() section:

/*
  // ADD to imports:
  import carRentalsRoutes from './car-rentals.routes';

  // ADD to route registrations (after ridesRoutes):
  router.use('/car-rentals', carRentalsRoutes);
*/

// ─── 2. Flutter GoRouter config ──────────────────────────────────────────────
// Add these routes wherever your ride routes are declared:

/*
  // In your GoRouter routes list:
  GoRoute(
    path: '/car-rental',
    builder: (context, state) => const CarRentalScreen(),
  ),
  GoRoute(
    path: '/car-rental/:carId',
    builder: (context, state) {
      final car = state.extra as CarRentalCar?;
      return CarRentalDetailScreen(
        carId: state.pathParameters['carId']!,
        carData: car,
      );
    },
  ),
*/

// ─── 3. Imports needed in router file ────────────────────────────────────────
/*
  import 'features/car_rental/screens/car_rental_screen.dart';
  import 'features/car_rental/screens/car_rental_detail_screen.dart';
  import 'features/car_rental/services/car_rental_service.dart';
*/

// ─── 4. Seed rental cars in the database ─────────────────────────────────────
// Run this one-time seed script (or add to your existing seed.ts):
// The car rental route uses Products with moduleType=RIDE and
// metadata.rentalCar=true, so no schema migration is needed yet.

/*
  import { PrismaClient, ModuleType } from '@prisma/client';
  const prisma = new PrismaClient();

  const cars = [
    {
      id: 'car-001',
      name: 'Toyota Yaris',
      type: 'Economy',
      seats: 5,
      pricePerDay: 6500,
      transmission: 'Automatic',
      fuelType: 'Petrol',
      year: 2022,
      badge: 'Best Value',
      features: ['AC', 'Bluetooth', 'USB Charging', 'Backup Camera'],
    },
    {
      id: 'car-002',
      name: 'Hyundai Tucson',
      type: 'SUV',
      seats: 5,
      pricePerDay: 12000,
      transmission: 'Automatic',
      fuelType: 'Diesel',
      year: 2023,
      badge: 'Popular',
      features: ['AC', 'Sunroof', 'Bluetooth', 'GPS', 'Leather Seats'],
    },
    {
      id: 'car-003',
      name: 'Toyota Hiace',
      type: 'Van',
      seats: 12,
      pricePerDay: 18000,
      transmission: 'Manual',
      fuelType: 'Diesel',
      year: 2021,
      badge: null,
      features: ['AC', 'Large Cargo Space', 'Multiple Seats'],
    },
    {
      id: 'car-004',
      name: 'Toyota Land Cruiser',
      type: 'SUV',
      seats: 7,
      pricePerDay: 25000,
      transmission: 'Automatic',
      fuelType: 'Diesel',
      year: 2022,
      badge: 'Premium',
      features: ['AC', '4WD', 'GPS', 'Leather Seats', 'Sunroof', 'Bluetooth'],
    },
  ];

  for (const car of cars) {
    await prisma.product.upsert({
      where: { id: car.id },
      create: {
        id: car.id,
        moduleType: ModuleType.RIDE,
        name: car.name,
        brand: car.type,
        description: `${car.year} ${car.name} – ${car.transmission}, ${car.fuelType}, ${car.seats} seats. Unlimited mileage included.`,
        price: car.pricePerDay,
        unit: 'per day',
        badge: car.badge ?? null,
        inStock: true,
        featuresJson: car.features,
        tagsJson: [car.type],
        metadata: {
          rentalCar: true,
          type: car.type,
          seats: car.seats,
          transmission: car.transmission,
          fuelType: car.fuelType,
          year: car.year,
          mileage: 'Unlimited',
        },
      },
      update: {},
    });
    console.log(`Seeded car: ${car.name}`);
  }

  await prisma.$disconnect();
*/

// ─── 5. Optional: Full CarRentalBooking Prisma model ────────────────────────
// For production, add this to schema.prisma for a proper bookings table
// instead of the current Order-based fallback.
// See the top of car-rentals.routes.ts for the full schema definition.

// ─── Summary of files delivered ─────────────────────────────────────────────
/*
  NEW files:
  ├── backend/src/routes/car-rentals.routes.ts
  ├── lib/features/car_rental/
  │   ├── services/car_rental_service.dart      (API + models)
  │   ├── screens/car_rental_screen.dart        (list screen)
  │   └── screens/car_rental_detail_screen.dart (detail + booking)

  MODIFIED files:
  └── lib/features/ride/screens/ride_screen.dart
      - Removed: _RideModeTabs, _RideModeTab, _RentalCarsSection, _RentalCarOption
      - Removed: _showRent state variable
      - Added:   _CarRentalBannerCard (navigates to /car-rental)
      - Fixed:   ride categories now always visible, not toggled by tab
*/
