"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const module_settings_1 = require("../utils/module-settings");
const notifications_1 = require("../utils/notifications");
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
    const customerName = `${booking.user.firstName} ${booking.user.lastName}`.trim();
    return {
        id: booking.id,
        userId: booking.userId,
        driverUserId: booking.driverUserId,
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
        customerName: customerName.length === 0 ? null : customerName,
        customerPhone: booking.user.phone,
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
            user: {
                select: { firstName: true, lastName: true, phone: true },
            },
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
            user: {
                select: { firstName: true, lastName: true, phone: true },
            },
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
    if (!(await (0, module_settings_1.isModuleEnabled)(client_1.ModuleType.RIDE))) {
        return res.status(403).json({
            error: `${(0, module_settings_1.moduleName)(client_1.ModuleType.RIDE)} module is currently disabled.`,
        });
    }
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
            driverName: body.driverName ?? null,
            driverPhone: body.driverPhone ?? null,
            vehicleName: body.vehicleName,
            trackingData: body.trackingData ?? undefined,
        },
        include: {
            user: {
                select: { firstName: true, lastName: true, phone: true },
            },
            rideCategory: true,
            paymentMethod: true,
            pickupAddress: true,
            dropoffAddress: true,
        },
    });
    await (0, notifications_1.createRideCreatedNotification)({
        userId: booking.userId,
        rideId: booking.id,
        vehicleName: booking.vehicleName,
        pickupLabel: booking.pickupLabel,
    });
    res.status(201).json(serializeRideBooking(booking));
}));
exports.default = router;
