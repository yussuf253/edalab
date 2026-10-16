"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const module_settings_1 = require("../utils/module-settings");
const serializers_1 = require("../utils/serializers");
const router = (0, express_1.Router)();
const parcelFees = {
    [client_1.ParcelSize.SMALL]: 500,
    [client_1.ParcelSize.MEDIUM]: 800,
    [client_1.ParcelSize.LARGE]: 1200,
};
const createParcelSchema = zod_1.z.object({
    userId: zod_1.z.string().min(1),
    senderName: zod_1.z.string().trim().min(2).max(120),
    senderPhone: zod_1.z.string().trim().min(5).max(40),
    recipientName: zod_1.z.string().trim().min(2).max(120),
    recipientPhone: zod_1.z.string().trim().min(5).max(40),
    pickupAddress: zod_1.z.string().trim().min(5).max(300),
    dropoffAddress: zod_1.z.string().trim().min(5).max(300),
    packageDescription: zod_1.z.string().trim().min(2).max(300),
    packageSize: zod_1.z.nativeEnum(client_1.ParcelSize),
    notes: zod_1.z.string().trim().max(500).optional(),
});
const parcelStatusSchema = zod_1.z.object({
    status: zod_1.z.nativeEnum(client_1.ParcelStatus),
});
function serializeParcel(parcel) {
    return {
        id: parcel.id,
        userId: parcel.userId,
        courierUserId: parcel.courierUserId,
        senderName: parcel.senderName,
        senderPhone: parcel.senderPhone,
        recipientName: parcel.recipientName,
        recipientPhone: parcel.recipientPhone,
        pickupAddress: parcel.pickupAddress,
        dropoffAddress: parcel.dropoffAddress,
        packageDescription: parcel.packageDescription,
        packageSize: parcel.packageSize,
        status: parcel.status,
        deliveryFee: (0, serializers_1.toNumber)(parcel.deliveryFee),
        currency: parcel.currency,
        notes: parcel.notes,
        courier: parcel.courier
            ? {
                name: `${parcel.courier.firstName} ${parcel.courier.lastName}`.trim(),
                phone: parcel.courier.phone,
            }
            : null,
        createdAt: parcel.createdAt,
        updatedAt: parcel.updatedAt,
    };
}
async function parcelCourierProfile(userId) {
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile ||
        profile.type !== client_1.ProProfileType.DELIVERY ||
        !profile.activeModules.includes(client_1.ProModule.PARCEL_DELIVERY)) {
        return { error: 'Parcel delivery is not enabled for this courier profile.', status: 403 };
    }
    return { profile };
}
router.get('/pricing', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    res.json({ currency: 'DJF', fees: parcelFees });
}));
router.get('/user/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const parcels = await db_1.prisma.parcelDelivery.findMany({
        where: { userId },
        include: {
            courier: { select: { firstName: true, lastName: true, phone: true } },
        },
        orderBy: { createdAt: 'desc' },
    });
    res.json(parcels.map(serializeParcel));
}));
router.get('/pro/:userId/queue', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const access = await parcelCourierProfile(userId);
    if ('error' in access) {
        return res.status(access.status ?? 403).json({ error: access.error });
    }
    const parcels = await db_1.prisma.parcelDelivery.findMany({
        where: {
            OR: [
                { status: client_1.ParcelStatus.REQUESTED, courierUserId: null },
                {
                    courierUserId: userId,
                    status: {
                        in: [
                            client_1.ParcelStatus.ACCEPTED,
                            client_1.ParcelStatus.PICKED_UP,
                            client_1.ParcelStatus.IN_TRANSIT,
                        ],
                    },
                },
            ],
        },
        include: {
            customer: { select: { firstName: true, lastName: true, phone: true } },
        },
        orderBy: { createdAt: 'asc' },
    });
    res.json(parcels.map((parcel) => ({
        ...serializeParcel(parcel),
        customerName: `${parcel.customer.firstName} ${parcel.customer.lastName}`.trim(),
        customerPhone: parcel.customer.phone,
        queueType: parcel.courierUserId === userId ? 'assigned' : 'open',
    })));
}));
router.post('/pro/:userId/:parcelId/claim', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const parcelId = (0, http_1.getParam)(req.params.parcelId, 'parcelId');
    const access = await parcelCourierProfile(userId);
    if ('error' in access) {
        return res.status(access.status ?? 403).json({ error: access.error });
    }
    if (!access.profile.isOnline) {
        return res.status(403).json({ error: 'Turn online before claiming parcels.' });
    }
    const result = await db_1.prisma.parcelDelivery.updateMany({
        where: {
            id: parcelId,
            status: client_1.ParcelStatus.REQUESTED,
            courierUserId: null,
        },
        data: { courierUserId: userId, status: client_1.ParcelStatus.ACCEPTED },
    });
    if (result.count === 0) {
        return res.status(409).json({ error: 'Parcel is no longer available.' });
    }
    const parcel = await db_1.prisma.parcelDelivery.findUnique({
        where: { id: parcelId },
        include: { courier: { select: { firstName: true, lastName: true, phone: true } } },
    });
    if (!parcel)
        return res.status(404).json({ error: 'Parcel not found.' });
    res.json(serializeParcel(parcel));
}));
router.patch('/pro/:userId/:parcelId/status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const parcelId = (0, http_1.getParam)(req.params.parcelId, 'parcelId');
    const body = parcelStatusSchema.parse(req.body);
    const access = await parcelCourierProfile(userId);
    if ('error' in access) {
        return res.status(access.status ?? 403).json({ error: access.error });
    }
    const parcel = await db_1.prisma.parcelDelivery.findFirst({
        where: { id: parcelId, courierUserId: userId },
        select: { status: true },
    });
    const nextStatus = {
        [client_1.ParcelStatus.ACCEPTED]: client_1.ParcelStatus.PICKED_UP,
        [client_1.ParcelStatus.PICKED_UP]: client_1.ParcelStatus.IN_TRANSIT,
        [client_1.ParcelStatus.IN_TRANSIT]: client_1.ParcelStatus.DELIVERED,
    };
    if (!parcel || nextStatus[parcel.status] !== body.status) {
        return res.status(409).json({ error: 'Parcel status transition is not allowed.' });
    }
    const result = await db_1.prisma.parcelDelivery.updateMany({
        where: { id: parcelId, courierUserId: userId, status: parcel.status },
        data: { status: body.status },
    });
    if (result.count === 0) {
        return res.status(409).json({ error: 'Parcel status changed. Refresh and try again.' });
    }
    const updated = await db_1.prisma.parcelDelivery.findUnique({
        where: { id: parcelId },
        include: { courier: { select: { firstName: true, lastName: true, phone: true } } },
    });
    if (!updated)
        return res.status(404).json({ error: 'Parcel not found.' });
    res.json(serializeParcel(updated));
}));
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createParcelSchema.parse(req.body);
    if (!(await (0, module_settings_1.isModuleEnabled)(client_1.ModuleType.PARCEL))) {
        return res.status(403).json({ error: `${(0, module_settings_1.moduleName)(client_1.ModuleType.PARCEL)} module is currently disabled.` });
    }
    const user = await db_1.prisma.user.findUnique({
        where: { id: body.userId },
        select: { id: true },
    });
    if (!user)
        return res.status(404).json({ error: 'Customer account not found.' });
    const parcel = await db_1.prisma.parcelDelivery.create({
        data: {
            userId: body.userId,
            senderName: body.senderName,
            senderPhone: body.senderPhone,
            recipientName: body.recipientName,
            recipientPhone: body.recipientPhone,
            pickupAddress: body.pickupAddress,
            dropoffAddress: body.dropoffAddress,
            packageDescription: body.packageDescription,
            packageSize: body.packageSize,
            deliveryFee: new client_1.Prisma.Decimal(parcelFees[body.packageSize]),
            notes: body.notes || null,
        },
    });
    res.status(201).json(serializeParcel(parcel));
}));
router.post('/:parcelId/cancel', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const parcelId = (0, http_1.getParam)(req.params.parcelId, 'parcelId');
    const userId = zod_1.z.string().min(1).parse(req.body.userId);
    const result = await db_1.prisma.parcelDelivery.updateMany({
        where: { id: parcelId, userId, status: client_1.ParcelStatus.REQUESTED },
        data: { status: client_1.ParcelStatus.CANCELLED },
    });
    if (result.count === 0) {
        return res.status(409).json({ error: 'Only unassigned parcel requests can be cancelled.' });
    }
    res.json({ id: parcelId, status: client_1.ParcelStatus.CANCELLED });
}));
exports.default = router;
