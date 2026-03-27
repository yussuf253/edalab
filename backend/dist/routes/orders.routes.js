"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const notifications_1 = require("../utils/notifications");
const serializers_1 = require("../utils/serializers");
const router = (0, express_1.Router)();
const orderItemSchema = zod_1.z.object({
    id: zod_1.z.string().optional(),
    productId: zod_1.z.string().optional(),
    name: zod_1.z.string(),
    brand: zod_1.z.string().optional(),
    price: zod_1.z.coerce.number(),
    quantity: zod_1.z.coerce.number().int().positive(),
    total: zod_1.z.coerce.number().optional(),
    color: zod_1.z.string().optional().nullable(),
    size: zod_1.z.string().optional().nullable(),
    metadata: zod_1.z.record(zod_1.z.any()).optional(),
});
const createOrderSchema = zod_1.z.object({
    userId: zod_1.z.string(),
    moduleType: zod_1.z.nativeEnum(client_1.ModuleType),
    status: zod_1.z.nativeEnum(client_1.OrderStatus).optional(),
    subtotal: zod_1.z.coerce.number(),
    tax: zod_1.z.coerce.number(),
    deliveryFee: zod_1.z.coerce.number().optional().default(0),
    discount: zod_1.z.coerce.number().optional().default(0),
    total: zod_1.z.coerce.number(),
    notes: zod_1.z.string().optional(),
    items: zod_1.z.array(orderItemSchema).default([]),
});
router.get('/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const [orders, appointments, rideBookings, hotelBookings, laundryOrders] = await Promise.all([
        db_1.prisma.order.findMany({
            where: { userId },
            include: {
                items: true,
            },
        }),
        db_1.prisma.appointment.findMany({
            where: { userId },
            include: {
                doctor: true,
            },
        }),
        db_1.prisma.rideBooking.findMany({
            where: { userId },
            include: {
                rideCategory: true,
            },
        }),
        db_1.prisma.hotelBooking.findMany({
            where: { userId },
            include: {
                hotel: true,
            },
        }),
        db_1.prisma.laundryOrder.findMany({
            where: { userId },
            include: {
                service: true,
            },
        }),
    ]);
    const history = [
        ...orders.map((order) => {
            const firstMetadata = order.items[0]?.metadata && typeof order.items[0].metadata === 'object'
                ? order.items[0].metadata
                : null;
            return {
                id: order.id,
                entryType: 'ORDER',
                userId: order.userId,
                moduleType: order.moduleType,
                moduleName: order.items[0]?.brand ??
                    order.items[0]?.name ??
                    order.moduleType.toLowerCase(),
                status: order.status,
                subtotal: (0, serializers_1.toNumber)(order.subtotal),
                tax: (0, serializers_1.toNumber)(order.tax),
                deliveryFee: (0, serializers_1.toNumber)(order.deliveryFee),
                discount: (0, serializers_1.toNumber)(order.discount),
                total: (0, serializers_1.toNumber)(order.total),
                createdAt: order.createdAt,
                updatedAt: order.updatedAt,
                address: typeof firstMetadata?.address === 'string'
                    ? firstMetadata.address
                    : null,
                deliveryLabel: typeof firstMetadata?.deliveryLabel === 'string'
                    ? firstMetadata.deliveryLabel
                    : null,
                deliveryEta: typeof firstMetadata?.deliveryEta === 'string'
                    ? firstMetadata.deliveryEta
                    : null,
                paymentLabel: typeof firstMetadata?.paymentLabel === 'string'
                    ? firstMetadata.paymentLabel
                    : null,
                trackingRoute: order.moduleType === 'FOOD' &&
                    !['COMPLETED', 'CANCELLED', 'REFUNDED'].includes(order.status)
                    ? `/food/tracking/${order.id}`
                    : null,
                items: order.items.map((item) => ({
                    id: item.id,
                    productId: item.productId,
                    externalRefId: item.externalRefId,
                    name: item.name,
                    brand: item.brand,
                    quantity: item.quantity,
                    price: (0, serializers_1.toNumber)(item.unitPrice),
                    total: (0, serializers_1.toNumber)(item.lineTotal),
                    color: item.color,
                    size: item.size,
                    metadata: item.metadata,
                })),
            };
        }),
        ...appointments.map((appointment) => ({
            id: appointment.id,
            entryType: 'APPOINTMENT',
            userId: appointment.userId,
            moduleType: client_1.ModuleType.DOCTOR,
            moduleName: appointment.doctor.name,
            status: appointment.status,
            subtotal: (0, serializers_1.toNumber)(appointment.doctor.consultationFee) ?? 0,
            tax: 0,
            deliveryFee: 0,
            discount: 0,
            total: (0, serializers_1.toNumber)(appointment.doctor.consultationFee) ?? 0,
            createdAt: appointment.createdAt,
            updatedAt: appointment.updatedAt,
            trackingRoute: '/doctor/appointments',
            items: [
                {
                    id: appointment.id,
                    name: appointment.appointmentType === 'in_person'
                        ? 'In-person consultation'
                        : appointment.appointmentType === 'video'
                            ? 'Video consultation'
                            : appointment.appointmentType === 'chat'
                                ? 'Chat consultation'
                                : 'Consultation',
                    quantity: 1,
                    price: (0, serializers_1.toNumber)(appointment.doctor.consultationFee) ?? 0,
                    total: (0, serializers_1.toNumber)(appointment.doctor.consultationFee) ?? 0,
                    metadata: {
                        doctorId: appointment.doctorId,
                        specialty: appointment.doctor.specialty,
                        date: appointment.appointmentAt,
                        timeSlot: appointment.timeSlot,
                    },
                },
            ],
        })),
        ...rideBookings.map((ride) => ({
            id: ride.id,
            entryType: 'RIDE_BOOKING',
            userId: ride.userId,
            moduleType: client_1.ModuleType.RIDE,
            moduleName: ride.rideCategory.name,
            status: ride.status,
            subtotal: (0, serializers_1.toNumber)(ride.estimatedFare),
            tax: (0, serializers_1.toNumber)(ride.tax),
            deliveryFee: 0,
            discount: 0,
            total: (0, serializers_1.toNumber)(ride.total),
            createdAt: ride.createdAt,
            updatedAt: ride.updatedAt,
            trackingRoute: !['COMPLETED', 'CANCELLED'].includes(ride.status)
                ? `/ride/tracking/${ride.id}`
                : null,
            items: [
                {
                    id: ride.id,
                    name: ride.vehicleName,
                    quantity: 1,
                    price: (0, serializers_1.toNumber)(ride.estimatedFare) ?? 0,
                    total: (0, serializers_1.toNumber)(ride.total) ?? 0,
                    metadata: {
                        pickup: ride.pickupLabel,
                        destination: ride.dropoffLabel,
                        eta: ride.etaLabel,
                        distanceKm: (0, serializers_1.toNumber)(ride.distanceKm),
                    },
                },
            ],
        })),
        ...hotelBookings.map((booking) => ({
            id: booking.id,
            entryType: 'HOTEL_BOOKING',
            userId: booking.userId,
            moduleType: client_1.ModuleType.HOTEL,
            moduleName: booking.hotel.name,
            status: booking.status === 'CHECKED_OUT' ? 'COMPLETED' : booking.status,
            subtotal: (0, serializers_1.toNumber)(booking.subtotal),
            tax: (0, serializers_1.toNumber)(booking.tax),
            deliveryFee: (0, serializers_1.toNumber)(booking.serviceFee),
            discount: 0,
            total: (0, serializers_1.toNumber)(booking.total),
            createdAt: booking.createdAt,
            updatedAt: booking.updatedAt,
            trackingRoute: null,
            items: [
                {
                    id: booking.id,
                    name: booking.roomType,
                    quantity: booking.nights,
                    price: (0, serializers_1.toNumber)(booking.subtotal) ?? 0,
                    total: (0, serializers_1.toNumber)(booking.total) ?? 0,
                    metadata: {
                        hotelId: booking.hotelId,
                        checkInAt: booking.checkInAt,
                        checkOutAt: booking.checkOutAt,
                        guestCount: booking.guestCount,
                    },
                },
            ],
        })),
        ...laundryOrders.map((order) => ({
            id: order.id,
            entryType: 'LAUNDRY_ORDER',
            userId: order.userId,
            moduleType: client_1.ModuleType.LAUNDRY,
            moduleName: order.service.name,
            status: order.status,
            subtotal: (0, serializers_1.toNumber)(order.subtotal),
            tax: (0, serializers_1.toNumber)(order.tax),
            deliveryFee: 0,
            discount: 0,
            total: (0, serializers_1.toNumber)(order.total),
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
            trackingRoute: null,
            items: [
                {
                    id: order.id,
                    name: order.service.name,
                    quantity: order.itemCount,
                    price: (0, serializers_1.toNumber)(order.subtotal) ?? 0,
                    total: (0, serializers_1.toNumber)(order.total) ?? 0,
                    metadata: {
                        pickupAt: order.pickupAt,
                        timeSlot: order.timeSlot,
                        itemBreakdown: order.itemBreakdown,
                    },
                },
            ],
        })),
    ].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    res.json(history);
}));
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createOrderSchema.parse(req.body);
    const order = await db_1.prisma.order.create({
        data: {
            userId: body.userId,
            moduleType: body.moduleType,
            status: body.status ?? client_1.OrderStatus.PENDING,
            subtotal: new client_1.Prisma.Decimal(body.subtotal),
            tax: new client_1.Prisma.Decimal(body.tax),
            deliveryFee: new client_1.Prisma.Decimal(body.deliveryFee),
            discount: new client_1.Prisma.Decimal(body.discount),
            total: new client_1.Prisma.Decimal(body.total),
            notes: body.notes ?? null,
            items: {
                create: body.items.map((item) => ({
                    productId: item.productId ?? null,
                    externalRefId: item.id ?? null,
                    name: item.name,
                    brand: item.brand ?? null,
                    quantity: item.quantity,
                    unitPrice: new client_1.Prisma.Decimal(item.price),
                    lineTotal: new client_1.Prisma.Decimal(item.total ?? item.price * item.quantity),
                    color: item.color ?? null,
                    size: item.size ?? null,
                    metadata: item.metadata ?? undefined,
                })),
            },
        },
        include: {
            items: true,
        },
    });
    const primaryLabel = order.items[0]?.brand ??
        order.items[0]?.name ??
        order.moduleType.toLowerCase();
    await (0, notifications_1.createOrderCreatedNotification)({
        userId: order.userId,
        orderId: order.id,
        moduleType: order.moduleType,
        moduleName: primaryLabel,
    });
    res.status(201).json({
        id: order.id,
        userId: order.userId,
        moduleType: order.moduleType,
        status: order.status,
        subtotal: (0, serializers_1.toNumber)(order.subtotal),
        tax: (0, serializers_1.toNumber)(order.tax),
        deliveryFee: (0, serializers_1.toNumber)(order.deliveryFee),
        discount: (0, serializers_1.toNumber)(order.discount),
        total: (0, serializers_1.toNumber)(order.total),
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        items: order.items.map((item) => ({
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            price: (0, serializers_1.toNumber)(item.unitPrice),
            total: (0, serializers_1.toNumber)(item.lineTotal),
        })),
    });
}));
exports.default = router;
