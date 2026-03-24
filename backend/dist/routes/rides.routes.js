"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const serializers_1 = require("../utils/serializers");
const router = (0, express_1.Router)();
const createRideSchema = zod_1.z.object({
    userId: zod_1.z.string(),
    rideCategoryId: zod_1.z.string(),
    paymentMethodId: zod_1.z.string().optional(),
    pickupAddressId: zod_1.z.string().optional(),
    dropoffAddressId: zod_1.z.string().optional(),
    pickupLabel: zod_1.z.string().min(1),
    dropoffLabel: zod_1.z.string().min(1),
    distanceKm: zod_1.z.coerce.number().positive(),
    estimatedFare: zod_1.z.coerce.number().nonnegative(),
    tax: zod_1.z.coerce.number().nonnegative(),
    total: zod_1.z.coerce.number().nonnegative(),
    etaLabel: zod_1.z.string().optional(),
    driverName: zod_1.z.string().optional(),
    driverPhone: zod_1.z.string().optional(),
    vehicleName: zod_1.z.string().min(1),
    trackingData: zod_1.z.record(zod_1.z.any()).optional(),
});
function serializeRideBooking(booking) {
    return {
        id: booking.id,
        userId: booking.userId,
        rideCategoryId: booking.rideCategoryId,
        status: booking.status.toLowerCase(),
        pickup: booking.pickupLabel,
        destination: booking.dropoffLabel,
        distanceKm: (0, serializers_1.toNumber)(booking.distanceKm),
        estimatedFare: (0, serializers_1.toNumber)(booking.estimatedFare),
        tax: (0, serializers_1.toNumber)(booking.tax),
        total: (0, serializers_1.toNumber)(booking.total),
        eta: booking.etaLabel,
        vehicle: booking.vehicleName,
        driverName: booking.driverName,
        driverPhone: booking.driverPhone,
        paymentMethod: booking.paymentMethod
            ? booking.paymentMethod.brand && booking.paymentMethod.last4
                ? '${booking.paymentMethod.brand} •••• ${booking.paymentMethod.last4}'
                : booking.paymentMethod.type.toLowerCase()
            : null,
        rideCategory: {
            id: booking.rideCategory.id,
            name: booking.rideCategory.name,
            description: booking.rideCategory.description,
            capacity: booking.rideCategory.capacity,
            basePrice: (0, serializers_1.toNumber)(booking.rideCategory.basePrice),
            pricePerKm: (0, serializers_1.toNumber)(booking.rideCategory.pricePerKm),
            etaLabel: booking.rideCategory.etaLabel,
        },
        pickupAddress: booking.pickupAddress
            ? {
                id: booking.pickupAddress.id,
                label: booking.pickupAddress.label,
                address: booking.pickupAddress.line1,
            }
            : null,
        dropoffAddress: booking.dropoffAddress
            ? {
                id: booking.dropoffAddress.id,
                label: booking.dropoffAddress.label,
                address: booking.dropoffAddress.line1,
            }
            : null,
        trackingData: booking.trackingData,
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
    };
}
router.get('/user/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const bookings = await db_1.prisma.rideBooking.findMany({
        where: { userId },
        include: {
            rideCategory: true,
            paymentMethod: true,
            pickupAddress: true,
            dropoffAddress: true,
        },
        orderBy: { createdAt: 'desc' },
    });
    res.json(bookings.map(serializeRideBooking));
}));
router.get('/:rideId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const rideId = (0, http_1.getParam)(req.params.rideId, 'rideId');
    const booking = await db_1.prisma.rideBooking.findUnique({
        where: { id: rideId },
        include: {
            rideCategory: true,
            paymentMethod: true,
            pickupAddress: true,
            dropoffAddress: true,
        },
    });
    if (!booking) {
        return res.status(404).json({ error: 'Ride booking not found.' });
    }
    res.json(serializeRideBooking(booking));
}));
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createRideSchema.parse(req.body);
    const booking = await db_1.prisma.rideBooking.create({
        data: {
            userId: body.userId,
            rideCategoryId: body.rideCategoryId,
            paymentMethodId: body.paymentMethodId ?? null,
            pickupAddressId: body.pickupAddressId ?? null,
            dropoffAddressId: body.dropoffAddressId ?? null,
            pickupLabel: body.pickupLabel,
            dropoffLabel: body.dropoffLabel,
            distanceKm: new client_1.Prisma.Decimal(body.distanceKm),
            estimatedFare: new client_1.Prisma.Decimal(body.estimatedFare),
            tax: new client_1.Prisma.Decimal(body.tax),
            total: new client_1.Prisma.Decimal(body.total),
            status: client_1.RideStatus.REQUESTED,
            etaLabel: body.etaLabel ?? null,
            driverName: body.driverName ?? 'Ahmed K.',
            driverPhone: body.driverPhone ?? '+253 77 123 456',
            vehicleName: body.vehicleName,
            trackingData: body.trackingData ?? undefined,
        },
        include: {
            rideCategory: true,
            paymentMethod: true,
            pickupAddress: true,
            dropoffAddress: true,
        },
    });
    res.status(201).json(serializeRideBooking(booking));
}));
exports.default = router;
