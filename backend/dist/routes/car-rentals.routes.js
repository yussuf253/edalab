"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const serializers_1 = require("../utils/serializers");
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
const router = (0, express_1.Router)();
// ─── Validation Schemas ────────────────────────────────────────────────────
const createCarRentalBookingSchema = zod_1.z.object({
    userId: zod_1.z.string().min(1),
    carId: zod_1.z.string().min(1),
    startDate: zod_1.z.string().datetime(),
    endDate: zod_1.z.string().datetime(),
    pickupLocation: zod_1.z.string().trim().min(1).max(200),
    dropoffLocation: zod_1.z.string().trim().max(200).optional(),
    notes: zod_1.z.string().trim().max(500).optional(),
});
// ─── Serializers ────────────────────────────────────────────────────────────
function serializeCarFromProduct(product) {
    const metadata = product.metadata && typeof product.metadata === 'object' && !Array.isArray(product.metadata)
        ? product.metadata
        : {};
    const readJsonArray = (value) => {
        if (!Array.isArray(value))
            return [];
        return value.filter((v) => typeof v === 'string');
    };
    const images = readJsonArray(product.imageUrlsJson);
    const features = readJsonArray(product.featuresJson);
    const tags = readJsonArray(product.tagsJson);
    return {
        id: product.id,
        name: product.name,
        type: (metadata.type?.toString() ?? product.brand ?? tags[0] ?? 'Standard'),
        description: product.description,
        pricePerDay: (0, serializers_1.toNumber)(product.price) ?? 0,
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
function serializeBooking(booking) {
    return {
        id: booking.id,
        userId: booking.userId,
        carId: booking.carId,
        carName: booking.carName,
        carType: booking.carType,
        startDate: booking.startDate,
        endDate: booking.endDate,
        totalDays: booking.totalDays,
        pricePerDay: (0, serializers_1.toNumber)(booking.pricePerDay),
        subtotal: (0, serializers_1.toNumber)(booking.subtotal),
        tax: (0, serializers_1.toNumber)(booking.tax),
        total: (0, serializers_1.toNumber)(booking.total),
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
router.get('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const typeFilter = req.query.type?.toString().trim();
    const minSeats = req.query.minSeats ? Number(req.query.minSeats) : undefined;
    const products = await db_1.prisma.product.findMany({
        where: {
            moduleType: client_1.ModuleType.RIDE,
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
    res.json({ cars, types });
}));
// GET /api/car-rentals/:carId — single car details
router.get('/:carId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const carId = (0, http_1.getParam)(req.params.carId, 'carId');
    const product = await db_1.prisma.product.findFirst({
        where: {
            id: carId,
            moduleType: client_1.ModuleType.RIDE,
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
}));
// POST /api/car-rentals/bookings — create a rental booking
// NOTE: Uses raw SQL until CarRentalBooking model is added to schema.
// After adding the model, swap to: prisma.carRentalBooking.create(...)
router.post('/bookings', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createCarRentalBookingSchema.parse(req.body);
    const car = await db_1.prisma.product.findFirst({
        where: {
            id: body.carId,
            moduleType: client_1.ModuleType.RIDE,
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
    const totalDays = Math.max(1, Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)));
    const pricePerDay = (0, serializers_1.toNumber)(car.price) ?? 0;
    const subtotal = pricePerDay * totalDays;
    const tax = subtotal * 0.08;
    const total = subtotal + tax;
    const carMetadata = car.metadata && typeof car.metadata === 'object' && !Array.isArray(car.metadata)
        ? car.metadata
        : {};
    // Fallback: create an Order record until CarRentalBooking table exists
    const order = await db_1.prisma.order.create({
        data: {
            userId: body.userId,
            moduleType: client_1.ModuleType.RIDE,
            status: client_1.OrderStatus.CONFIRMED,
            subtotal: new client_1.Prisma.Decimal(subtotal),
            tax: new client_1.Prisma.Decimal(tax),
            deliveryFee: new client_1.Prisma.Decimal(0),
            discount: new client_1.Prisma.Decimal(0),
            total: new client_1.Prisma.Decimal(total),
            notes: body.notes ?? null,
            metadata: {
                rentalBooking: true,
                carId: body.carId,
                carName: car.name,
                carType: carMetadata.type?.toString() ?? car.brand ?? 'Standard',
                startDate: startDate.toISOString(),
                endDate: endDate.toISOString(),
                totalDays,
                pricePerDay,
                pickupLocation: body.pickupLocation,
                dropoffLocation: body.dropoffLocation ?? body.pickupLocation,
            },
            items: {
                create: [
                    {
                        productId: body.carId,
                        name: car.name,
                        brand: carMetadata.type?.toString() ?? car.brand ?? 'Car Rental',
                        quantity: totalDays,
                        unitPrice: new client_1.Prisma.Decimal(pricePerDay),
                        lineTotal: new client_1.Prisma.Decimal(subtotal),
                        metadata: {
                            startDate: startDate.toISOString(),
                            endDate: endDate.toISOString(),
                            totalDays,
                            pickupLocation: body.pickupLocation,
                            dropoffLocation: body.dropoffLocation ?? body.pickupLocation,
                            rentalBooking: true,
                        },
                    },
                ],
            },
        },
        include: { items: true },
    });
    const meta = order.metadata;
    res.status(201).json({
        id: order.id,
        userId: order.userId,
        carId: meta.carId?.toString() ?? body.carId,
        carName: meta.carName?.toString() ?? car.name,
        carType: meta.carType?.toString() ?? 'Standard',
        startDate: meta.startDate,
        endDate: meta.endDate,
        totalDays: typeof meta.totalDays === 'number' ? meta.totalDays : totalDays,
        pricePerDay: typeof meta.pricePerDay === 'number' ? meta.pricePerDay : pricePerDay,
        subtotal: (0, serializers_1.toNumber)(order.subtotal),
        tax: (0, serializers_1.toNumber)(order.tax),
        total: (0, serializers_1.toNumber)(order.total),
        status: order.status,
        pickupLocation: meta.pickupLocation?.toString() ?? body.pickupLocation,
        dropoffLocation: meta.dropoffLocation?.toString() ?? body.pickupLocation,
        notes: order.notes,
        createdAt: order.createdAt,
    });
}));
// GET /api/car-rentals/bookings/user/:userId — user's rental history
router.get('/bookings/user/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const orders = await db_1.prisma.order.findMany({
        where: {
            userId,
            moduleType: client_1.ModuleType.RIDE,
            metadata: {
                path: ['rentalBooking'],
                equals: true,
            },
        },
        include: { items: true },
        orderBy: { createdAt: 'desc' },
    });
    const bookings = orders.map((order) => {
        const meta = order.metadata;
        return {
            id: order.id,
            userId: order.userId,
            carId: meta.carId?.toString() ?? '',
            carName: meta.carName?.toString() ?? 'Car',
            carType: meta.carType?.toString() ?? 'Standard',
            startDate: meta.startDate,
            endDate: meta.endDate,
            totalDays: typeof meta.totalDays === 'number' ? meta.totalDays : 1,
            pricePerDay: typeof meta.pricePerDay === 'number' ? meta.pricePerDay : 0,
            subtotal: (0, serializers_1.toNumber)(order.subtotal),
            tax: (0, serializers_1.toNumber)(order.tax),
            total: (0, serializers_1.toNumber)(order.total),
            status: order.status,
            pickupLocation: meta.pickupLocation?.toString() ?? null,
            dropoffLocation: meta.dropoffLocation?.toString() ?? null,
            notes: order.notes,
            createdAt: order.createdAt,
        };
    });
    res.json(bookings);
}));
exports.default = router;
