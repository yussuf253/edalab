import { ModuleType, OrderStatus, Prisma } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { toNumber } from '../utils/serializers';

/**
 * Car Rental Module
 *
 * This module handles car rental catalog and bookings.
 * Cars are stored as Products with moduleType = RIDE and metadata.rentalCar = true.
 *
 * ─── PRISMA SCHEMA ADDITIONS ─────────────────────────────────────────────────
 *
 * Add this model to schema.prisma:
 *
 * model CarRentalBooking {
 *   id              String              @id @default(cuid())
 *   userId          String
 *   carId           String
 *   carName         String
 *   carType         String
 *   startDate       DateTime
 *   endDate         DateTime
 *   totalDays       Int
 *   pricePerDay     Decimal             @db.Decimal(10, 2)
 *   subtotal        Decimal             @db.Decimal(10, 2)
 *   tax             Decimal             @db.Decimal(10, 2)
 *   total           Decimal             @db.Decimal(10, 2)
 *   status          CarRentalStatus     @default(PENDING)
 *   pickupLocation  String?
 *   dropoffLocation String?
 *   notes           String?
 *   metadata        Json?
 *   createdAt       DateTime            @default(now())
 *   updatedAt       DateTime            @updatedAt
 *   user            User                @relation(fields: [userId], references: [id], onDelete: Cascade)
 *
 *   @@index([userId, createdAt])
 *   @@index([status])
 * }
 *
 * enum CarRentalStatus {
 *   PENDING
 *   CONFIRMED
 *   ACTIVE
 *   COMPLETED
 *   CANCELLED
 * }
 *
 * Also add to User model:
 *   carRentalBookings CarRentalBooking[]
 *
 * ─── SEED DATA (run once) ────────────────────────────────────────────────────
 *
 * const cars = [
 *   { id: 'car-001', name: 'Toyota Yaris', type: 'Economy', seats: 5,
 *     pricePerDay: 6500, transmission: 'Automatic', fuelType: 'Petrol',
 *     year: 2022, mileage: 'Unlimited', badge: 'Best Value',
 *     features: ['AC', 'Bluetooth', 'USB Charging', 'Backup Camera'],
 *     imageUrls: ['https://...'] },
 *   { id: 'car-002', name: 'Hyundai Tucson', type: 'SUV', seats: 5,
 *     pricePerDay: 12000, transmission: 'Automatic', fuelType: 'Diesel',
 *     year: 2023, mileage: 'Unlimited', badge: 'Popular',
 *     features: ['AC', 'Sunroof', 'Bluetooth', 'GPS', 'Leather Seats'],
 *     imageUrls: ['https://...'] },
 *   { id: 'car-003', name: 'Toyota Hiace', type: 'Van', seats: 12,
 *     pricePerDay: 18000, transmission: 'Manual', fuelType: 'Diesel',
 *     year: 2021, mileage: 'Unlimited', badge: null,
 *     features: ['AC', 'Large Cargo Space'],
 *     imageUrls: ['https://...'] },
 * ];
 *
 * for (const car of cars) {
 *   await prisma.product.upsert({
 *     where: { id: car.id },
 *     create: {
 *       id: car.id,
 *       moduleType: ModuleType.RIDE,
 *       name: car.name,
 *       brand: car.type,
 *       description: `${car.year} ${car.name} – ${car.transmission}, ${car.fuelType}, ${car.seats} seats`,
 *       price: car.pricePerDay,
 *       unit: 'per day',
 *       badge: car.badge,
 *       imageUrlsJson: car.imageUrls,
 *       featuresJson: car.features,
 *       tagsJson: [car.type],
 *       inStock: true,
 *       metadata: {
 *         rentalCar: true,
 *         type: car.type,
 *         seats: car.seats,
 *         transmission: car.transmission,
 *         fuelType: car.fuelType,
 *         year: car.year,
 *         mileage: car.mileage,
 *       },
 *     },
 *     update: {},
 *   });
 * }
 */

const router = Router();

// ─── Validation Schemas ────────────────────────────────────────────────────

const createCarRentalBookingSchema = z.object({
  userId: z.string().min(1),
  carId: z.string().min(1),
  startDate: z.string().datetime(),
  endDate: z.string().datetime(),
  pickupLocation: z.string().trim().min(1).max(200),
  dropoffLocation: z.string().trim().max(200).optional(),
  notes: z.string().trim().max(500).optional(),
});

// ─── Serializers ────────────────────────────────────────────────────────────

function serializeCarFromProduct(product: {
  id: string;
  name: string;
  brand: string | null;
  description: string;
  price: Prisma.Decimal;
  unit: string | null;
  badge: string | null;
  imageUrlsJson: Prisma.JsonValue;
  tagsJson: Prisma.JsonValue;
  featuresJson: Prisma.JsonValue;
  metadata: Prisma.JsonValue;
  inStock: boolean;
}) {
  const metadata =
    product.metadata && typeof product.metadata === 'object' && !Array.isArray(product.metadata)
      ? (product.metadata as Record<string, unknown>)
      : {};

  const readJsonArray = (value: Prisma.JsonValue): string[] => {
    if (!Array.isArray(value)) return [];
    return value.filter((v): v is string => typeof v === 'string');
  };

  const images = readJsonArray(product.imageUrlsJson);
  const features = readJsonArray(product.featuresJson);
  const tags = readJsonArray(product.tagsJson);

  return {
    id: product.id,
    name: product.name,
    type: (metadata.type?.toString() ?? product.brand ?? tags[0] ?? 'Standard'),
    description: product.description,
    pricePerDay: toNumber(product.price) ?? 0,
    unit: product.unit ?? 'per day',
    badge: product.badge,
    imageUrl: images[0] ?? null,
    imageUrls: images,
    features,
    seats: typeof metadata.seats === 'number' ? metadata.seats : 5,
    transmission: metadata.transmission?.toString() ?? 'Automatic',
    fuelType: metadata.fuelType?.toString() ?? 'Petrol',
    year: typeof metadata.year === 'number' ? metadata.year : null,
    mileage: metadata.mileage?.toString() ?? 'Unlimited',
    available: product.inStock,
    metadata,
  };
}

function serializeBooking(booking: {
  id: string;
  userId: string;
  carId: string;
  carName: string;
  carType: string;
  startDate: Date;
  endDate: Date;
  totalDays: number;
  pricePerDay: Prisma.Decimal;
  subtotal: Prisma.Decimal;
  tax: Prisma.Decimal;
  total: Prisma.Decimal;
  status: string;
  pickupLocation: string | null;
  dropoffLocation: string | null;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
}) {
  return {
    id: booking.id,
    userId: booking.userId,
    carId: booking.carId,
    carName: booking.carName,
    carType: booking.carType,
    startDate: booking.startDate,
    endDate: booking.endDate,
    totalDays: booking.totalDays,
    pricePerDay: toNumber(booking.pricePerDay),
    subtotal: toNumber(booking.subtotal),
    tax: toNumber(booking.tax),
    total: toNumber(booking.total),
    status: booking.status,
    pickupLocation: booking.pickupLocation,
    dropoffLocation: booking.dropoffLocation,
    notes: booking.notes,
    createdAt: booking.createdAt,
    updatedAt: booking.updatedAt,
  };
}

// ─── Routes ─────────────────────────────────────────────────────────────────

// GET /api/car-rentals — list all available rental cars
router.get(
  '/',
  asyncHandler(async (req, res) => {
    const typeFilter = req.query.type?.toString().trim();
    const minSeats = req.query.minSeats ? Number(req.query.minSeats) : undefined;

    const products = await prisma.product.findMany({
      where: {
        moduleType: ModuleType.RIDE,
        inStock: true,
        metadata: {
          path: ['rentalCar'],
          equals: true,
        },
        ...(typeFilter
          ? {
              metadata: {
                path: ['type'],
                equals: typeFilter,
              },
            }
          : {}),
      },
      orderBy: [{ price: 'asc' }],
    });

    let cars = products.map(serializeCarFromProduct);

    if (minSeats != null && !isNaN(minSeats)) {
      cars = cars.filter((car) => car.seats >= minSeats);
    }

    const types = Array.from(new Set(cars.map((car) => car.type)));

    // Return both `items` and `cars` for compatibility with frontends
    res.json({ items: cars, cars, types });
  }),
);

// GET /api/car-rentals/:carId — single car details
router.get(
  '/:carId',
  asyncHandler(async (req, res) => {
    const carId = getParam(req.params.carId, 'carId');

    const product = await prisma.product.findFirst({
      where: {
        id: carId,
        moduleType: ModuleType.RIDE,
        metadata: {
          path: ['rentalCar'],
          equals: true,
        },
      },
    });

    if (!product) {
      return res.status(404).json({ error: 'Car not found.' });
    }

    res.json(serializeCarFromProduct(product));
  }),
);

// POST /api/car-rentals/bookings — create a rental booking
// NOTE: Uses raw SQL until CarRentalBooking model is added to schema.
// After adding the model, swap to: prisma.carRentalBooking.create(...)
router.post(
  '/bookings',
  asyncHandler(async (req, res) => {
    const body = createCarRentalBookingSchema.parse(req.body);

    const car = await prisma.product.findFirst({
      where: {
        id: body.carId,
        moduleType: ModuleType.RIDE,
        inStock: true,
        metadata: {
          path: ['rentalCar'],
          equals: true,
        },
      },
    });

    if (!car) {
      return res.status(404).json({ error: 'Car not found or unavailable.' });
    }

    const startDate = new Date(body.startDate);
    const endDate = new Date(body.endDate);

    if (endDate <= startDate) {
      return res.status(400).json({ error: 'End date must be after start date.' });
    }

    const totalDays = Math.max(
      1,
      Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)),
    );
    const pricePerDay = toNumber(car.price) ?? 0;
    const subtotal = pricePerDay * totalDays;
    const tax = subtotal * 0.08;
    const total = subtotal + tax;

    const carMetadata =
      car.metadata && typeof car.metadata === 'object' && !Array.isArray(car.metadata)
        ? (car.metadata as Record<string, unknown>)
        : {};

    // Check availability: ensure no existing confirmed/active bookings overlap
    const overlapping = await prisma.carRentalBooking.findFirst({
      where: {
        carId: body.carId,
        status: { in: ['PENDING', 'CONFIRMED', 'ACTIVE'] },
        AND: [
          { startDate: { lte: endDate } },
          { endDate: { gte: startDate } },
        ],
      },
    });

    if (overlapping) {
      return res.status(409).json({ error: 'Car is already booked for the selected dates.' });
    }

    // Transactionally create CarRentalBooking and an Order record for accounting
    const result = await prisma.$transaction(async (tx) => {
      const booking = await tx.carRentalBooking.create({
        data: {
          userId: body.userId,
          carId: body.carId,
          carName: car.name,
          carType: carMetadata.type?.toString() ?? car.brand ?? 'Standard',
          startDate,
          endDate,
          totalDays,
          pricePerDay: new Prisma.Decimal(pricePerDay),
          subtotal: new Prisma.Decimal(subtotal),
          tax: new Prisma.Decimal(tax),
          total: new Prisma.Decimal(total),
          status: 'CONFIRMED',
          pickupLocation: body.pickupLocation,
          dropoffLocation: body.dropoffLocation ?? body.pickupLocation,
          notes: body.notes ?? null,
          metadata: {
            createdBy: 'api',
          } as Prisma.InputJsonValue,
        },
      });

      const order = await tx.order.create({
        data: {
          userId: body.userId,
          moduleType: ModuleType.RIDE,
          status: OrderStatus.CONFIRMED,
          subtotal: new Prisma.Decimal(subtotal),
          tax: new Prisma.Decimal(tax),
          deliveryFee: new Prisma.Decimal(0),
          discount: new Prisma.Decimal(0),
          total: new Prisma.Decimal(total),
          notes: body.notes ?? null,
          metadata: {
            rentalBooking: true,
            bookingId: booking.id,
            carId: body.carId,
            carName: car.name,
            carType: carMetadata.type?.toString() ?? car.brand ?? 'Standard',
            startDate: startDate.toISOString(),
            endDate: endDate.toISOString(),
            totalDays,
            pricePerDay,
            pickupLocation: body.pickupLocation,
            dropoffLocation: body.dropoffLocation ?? body.pickupLocation,
          } as Prisma.InputJsonValue,
          items: {
            create: [
              {
                productId: body.carId,
                name: car.name,
                brand: carMetadata.type?.toString() ?? car.brand ?? 'Car Rental',
                quantity: totalDays,
                unitPrice: new Prisma.Decimal(pricePerDay),
                lineTotal: new Prisma.Decimal(subtotal),
                metadata: {
                  bookingId: booking.id,
                  startDate: startDate.toISOString(),
                  endDate: endDate.toISOString(),
                  totalDays,
                  pickupLocation: body.pickupLocation,
                  dropoffLocation: body.dropoffLocation ?? body.pickupLocation,
                  rentalBooking: true,
                } as Prisma.InputJsonValue,
              },
            ],
          },
        },
        include: { items: true },
      });

      return { booking, order };
    });

    const booking = result.booking;

    res.status(201).json(serializeBooking({
      id: booking.id,
      userId: booking.userId,
      carId: booking.carId,
      carName: booking.carName,
      carType: booking.carType,
      startDate: booking.startDate,
      endDate: booking.endDate,
      totalDays: booking.totalDays,
      pricePerDay: booking.pricePerDay,
      subtotal: booking.subtotal,
      tax: booking.tax,
      total: booking.total,
      status: booking.status,
      pickupLocation: booking.pickupLocation ?? null,
      dropoffLocation: booking.dropoffLocation ?? null,
      notes: booking.notes ?? null,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
    }));
  }),
);

// Availability check endpoint
// GET /api/car-rentals/bookings/availability?carId=...&startDate=...&endDate=...
router.get(
  '/bookings/availability',
  asyncHandler(async (req, res) => {
    const carId = req.query.carId?.toString();
    const start = req.query.startDate?.toString();
    const end = req.query.endDate?.toString();

    if (!carId || !start || !end) {
      return res.status(400).json({ error: 'carId, startDate and endDate are required' });
    }

    const startDate = new Date(start);
    const endDate = new Date(end);

    if (endDate <= startDate) {
      return res.status(400).json({ error: 'End date must be after start date.' });
    }

    const overlapping = await prisma.carRentalBooking.findFirst({
      where: {
        carId,
        status: { in: ['PENDING', 'CONFIRMED', 'ACTIVE'] },
        AND: [
          { startDate: { lte: endDate } },
          { endDate: { gte: startDate } },
        ],
      },
    });

    res.json({ available: !Boolean(overlapping) });
  }),
);

// GET /api/car-rentals/bookings/user/:userId — user's rental history
router.get(
  '/bookings/user/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');

    const bookings = await prisma.carRentalBooking.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    const serialized = bookings.map((b) => serializeBooking({
      id: b.id,
      userId: b.userId,
      carId: b.carId,
      carName: b.carName,
      carType: b.carType,
      startDate: b.startDate,
      endDate: b.endDate,
      totalDays: b.totalDays,
      pricePerDay: b.pricePerDay,
      subtotal: b.subtotal,
      tax: b.tax,
      total: b.total,
      status: b.status,
      pickupLocation: b.pickupLocation ?? null,
      dropoffLocation: b.dropoffLocation ?? null,
      notes: b.notes ?? null,
      createdAt: b.createdAt,
      updatedAt: b.updatedAt,
    }));

    res.json(serialized);
  }),
);

export default router;
