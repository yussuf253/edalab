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
const createHotelBookingSchema = zod_1.z
    .object({
    userId: zod_1.z.string(),
    hotelId: zod_1.z.string(),
    roomType: zod_1.z.string().min(1),
    guestName: zod_1.z.string().min(1),
    guestEmail: zod_1.z.string().email(),
    guestPhone: zod_1.z.string().optional().nullable(),
    specialRequests: zod_1.z.string().optional().nullable(),
    checkInAt: zod_1.z.coerce.date(),
    checkOutAt: zod_1.z.coerce.date(),
    nights: zod_1.z.coerce.number().int().positive(),
    guestCount: zod_1.z.coerce.number().int().positive(),
    subtotal: zod_1.z.coerce.number(),
    serviceFee: zod_1.z.coerce.number(),
    tax: zod_1.z.coerce.number(),
    total: zod_1.z.coerce.number(),
})
    .superRefine((value, ctx) => {
    if (value.checkOutAt <= value.checkInAt) {
        ctx.addIssue({
            code: zod_1.z.ZodIssueCode.custom,
            message: 'Check-out must be after check-in.',
            path: ['checkOutAt'],
        });
    }
});
function serializeHotelBooking(booking) {
    return {
        id: booking.id,
        userId: booking.userId,
        hotelId: booking.hotelId,
        hotelName: booking.hotel.name,
        moduleType: client_1.ModuleType.HOTEL,
        status: booking.status === client_1.HotelBookingStatus.CHECKED_OUT
            ? 'COMPLETED'
            : booking.status,
        roomType: booking.roomType,
        guestName: booking.guestName,
        guestEmail: booking.guestEmail,
        guestPhone: booking.guestPhone,
        specialRequests: booking.specialRequests,
        checkInAt: booking.checkInAt,
        checkOutAt: booking.checkOutAt,
        nights: booking.nights,
        guestCount: booking.guestCount,
        subtotal: (0, serializers_1.toNumber)(booking.subtotal),
        serviceFee: (0, serializers_1.toNumber)(booking.serviceFee),
        tax: (0, serializers_1.toNumber)(booking.tax),
        total: (0, serializers_1.toNumber)(booking.total),
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
        items: [
            {
                id: booking.id,
                name: booking.roomType,
                quantity: booking.nights,
                price: (0, serializers_1.toNumber)(booking.subtotal) ?? 0,
                total: (0, serializers_1.toNumber)(booking.total) ?? 0,
                metadata: {
                    hotelId: booking.hotelId,
                    hotelName: booking.hotel.name,
                    checkInAt: booking.checkInAt,
                    checkOutAt: booking.checkOutAt,
                    guestCount: booking.guestCount,
                    nights: booking.nights,
                },
            },
        ],
    };
}
function metadataRecord(value) {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
        return { ...value };
    }
    return {};
}
function firstImageFromJson(value) {
    if (!Array.isArray(value))
        return null;
    const image = value.find((entry) => typeof entry === 'string');
    return typeof image === 'string' ? image : null;
}
function firstNonEmptyString(...values) {
    for (const value of values) {
        if (value && value.trim().length > 0) {
            return value.trim();
        }
    }
    return null;
}
function enrichOrderItemMetadata(item) {
    const metadata = metadataRecord(item.metadata);
    const shop = item.product?.shop;
    if (shop) {
        metadata.shopId ??= shop.id;
        metadata.shopName ??= shop.name;
        metadata.shopSlug ??= shop.slug;
    }
    if (item.product) {
        metadata.productName ??= item.product.name;
        metadata.productDescription ??= item.product.description;
        const productImage = firstImageFromJson(item.product.imageUrlsJson);
        if (productImage != null) {
            metadata.productImage ??= productImage;
        }
    }
    return metadata;
}
function resolveOrderModuleName(order) {
    if (order.moduleType === client_1.ModuleType.SHOPPING) {
        for (const item of order.items) {
            const metadata = enrichOrderItemMetadata(item);
            if (typeof metadata.shopName === 'string' &&
                metadata.shopName.trim().length > 0) {
                return metadata.shopName.trim();
            }
            if (item.product?.shop?.name &&
                item.product.shop.name.trim().length > 0) {
                return item.product.shop.name.trim();
            }
        }
    }
    return (firstNonEmptyString(order.items[0]?.brand, order.items[0]?.name, order.moduleType.toLowerCase()) ?? order.moduleType.toLowerCase());
}
function serializeOrderDetail(order) {
    const firstMetadata = order.items[0]
        ? enrichOrderItemMetadata(order.items[0])
        : null;
    return {
        id: order.id,
        userId: order.userId,
        moduleType: order.moduleType,
        moduleName: resolveOrderModuleName(order),
        status: order.status,
        subtotal: (0, serializers_1.toNumber)(order.subtotal),
        tax: (0, serializers_1.toNumber)(order.tax),
        deliveryFee: (0, serializers_1.toNumber)(order.deliveryFee),
        discount: (0, serializers_1.toNumber)(order.discount),
        total: (0, serializers_1.toNumber)(order.total),
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        address: typeof firstMetadata?.address === 'string' ? firstMetadata.address : null,
        deliveryLabel: typeof firstMetadata?.deliveryLabel === 'string'
            ? firstMetadata.deliveryLabel
            : null,
        deliveryEta: typeof firstMetadata?.deliveryEta === 'string'
            ? firstMetadata.deliveryEta
            : null,
        notes: order.notes,
        deliveryAssignee: order.deliveryAssignee
            ? {
                userId: order.deliveryAssignee.id,
                name: `${order.deliveryAssignee.firstName} ${order.deliveryAssignee.lastName}`.trim(),
                phone: order.deliveryAssignee.phone,
            }
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
            metadata: enrichOrderItemMetadata(item),
        })),
    };
}
router.get('/detail/:orderId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const orderId = (0, http_1.getParam)(req.params.orderId, 'orderId');
    const order = await db_1.prisma.order.findUnique({
        where: { id: orderId },
        include: {
            items: {
                include: {
                    product: {
                        include: {
                            shop: true,
                        },
                    },
                },
            },
            deliveryAssignee: true,
        },
    });
    if (!order) {
        return res.status(404).json({ error: 'Order not found.' });
    }
    res.json(serializeOrderDetail(order));
}));
router.get('/hotel-bookings/:bookingId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const bookingId = (0, http_1.getParam)(req.params.bookingId, 'bookingId');
    const booking = await db_1.prisma.hotelBooking.findUnique({
        where: { id: bookingId },
        include: {
            hotel: true,
        },
    });
    if (!booking) {
        return res.status(404).json({ error: 'Hotel booking not found.' });
    }
    res.json(serializeHotelBooking(booking));
}));
router.post('/hotel-bookings', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createHotelBookingSchema.parse(req.body);
    const hotel = await db_1.prisma.hotel.findUnique({
        where: { id: body.hotelId },
    });
    if (!hotel) {
        return res.status(404).json({ error: 'Hotel not found.' });
    }
    const booking = await db_1.prisma.hotelBooking.create({
        data: {
            userId: body.userId,
            hotelId: body.hotelId,
            status: client_1.HotelBookingStatus.CONFIRMED,
            roomType: body.roomType,
            guestName: body.guestName.trim(),
            guestEmail: body.guestEmail.trim().toLowerCase(),
            guestPhone: body.guestPhone?.trim() || null,
            specialRequests: body.specialRequests?.trim() || null,
            checkInAt: body.checkInAt,
            checkOutAt: body.checkOutAt,
            nights: body.nights,
            guestCount: body.guestCount,
            subtotal: new client_1.Prisma.Decimal(body.subtotal),
            serviceFee: new client_1.Prisma.Decimal(body.serviceFee),
            tax: new client_1.Prisma.Decimal(body.tax),
            total: new client_1.Prisma.Decimal(body.total),
        },
        include: {
            hotel: true,
        },
    });
    await (0, notifications_1.createOrderCreatedNotification)({
        userId: booking.userId,
        orderId: booking.id,
        moduleType: client_1.ModuleType.HOTEL,
        moduleName: hotel.name,
    });
    res.status(201).json(serializeHotelBooking(booking));
}));
router.get('/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const [orders, appointments, rideBookings, hotelBookings, laundryOrders] = await Promise.all([
        db_1.prisma.order.findMany({
            where: { userId },
            include: {
                items: {
                    include: {
                        product: {
                            include: {
                                shop: true,
                            },
                        },
                    },
                },
                deliveryAssignee: true,
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
            const firstMetadata = order.items[0]
                ? enrichOrderItemMetadata(order.items[0])
                : null;
            return {
                id: order.id,
                entryType: 'ORDER',
                userId: order.userId,
                moduleType: order.moduleType,
                moduleName: resolveOrderModuleName(order),
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
                deliveryAssigneeName: order.deliveryAssignee?.firstName && order.deliveryAssignee?.lastName
                    ? `${order.deliveryAssignee.firstName} ${order.deliveryAssignee.lastName}`.trim()
                    : null,
                deliveryAssigneePhone: order.deliveryAssignee?.phone ?? null,
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
                    metadata: enrichOrderItemMetadata(item),
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
            trackingRoute: `/hotel/order/${booking.id}`,
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
            items: {
                include: {
                    product: {
                        include: {
                            shop: true,
                        },
                    },
                },
            },
            deliveryAssignee: true,
        },
    });
    const primaryLabel = resolveOrderModuleName(order);
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
            metadata: enrichOrderItemMetadata(item),
        })),
    });
}));
exports.default = router;
