"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const router = (0, express_1.Router)();
const createNotificationSchema = zod_1.z.object({
    userId: zod_1.z.string().min(1),
    id: zod_1.z.string().optional(),
    title: zod_1.z.string().min(1),
    body: zod_1.z.string().min(1),
    module: zod_1.z.nativeEnum(client_1.NotificationModule).optional(),
    type: zod_1.z.nativeEnum(client_1.NotificationType).optional(),
    priority: zod_1.z.nativeEnum(client_1.NotificationPriority).optional(),
    route: zod_1.z.string().optional().nullable(),
    dedupeKey: zod_1.z.string().optional().nullable(),
    metadata: zod_1.z.record(zod_1.z.any()).optional(),
    data: zod_1.z.record(zod_1.z.any()).optional(),
    createdAt: zod_1.z.string().datetime().optional(),
    readAt: zod_1.z.string().datetime().optional().nullable(),
});
const registerDeviceTokenSchema = zod_1.z.object({
    userId: zod_1.z.string().min(1),
    token: zod_1.z.string().min(1),
    platform: zod_1.z.nativeEnum(client_1.DevicePlatform).optional(),
});
function inferTypeFromModule(module) {
    switch (module) {
        case client_1.NotificationModule.ORDERS:
        case client_1.NotificationModule.FOOD:
        case client_1.NotificationModule.SHOPPING:
        case client_1.NotificationModule.GROCERY:
        case client_1.NotificationModule.PHARMACY:
        case client_1.NotificationModule.HOTEL:
            return client_1.NotificationType.ORDER;
        case client_1.NotificationModule.DOCTOR:
            return client_1.NotificationType.APPOINTMENT;
        case client_1.NotificationModule.RIDE:
            return client_1.NotificationType.RIDE;
        case client_1.NotificationModule.LAUNDRY:
            return client_1.NotificationType.LAUNDRY;
        case client_1.NotificationModule.PROMOTIONS:
            return client_1.NotificationType.PROMOTION;
        case client_1.NotificationModule.MESSAGES:
        case client_1.NotificationModule.HOME_SERVICES:
        case client_1.NotificationModule.ACCOUNT:
        case client_1.NotificationModule.SYSTEM:
            return client_1.NotificationType.SYSTEM;
    }
}
function inferModuleFromType(type) {
    switch (type) {
        case client_1.NotificationType.ORDER:
            return client_1.NotificationModule.ORDERS;
        case client_1.NotificationType.APPOINTMENT:
            return client_1.NotificationModule.DOCTOR;
        case client_1.NotificationType.PROMOTION:
            return client_1.NotificationModule.PROMOTIONS;
        case client_1.NotificationType.RIDE:
            return client_1.NotificationModule.RIDE;
        case client_1.NotificationType.LAUNDRY:
            return client_1.NotificationModule.LAUNDRY;
        case client_1.NotificationType.SYSTEM:
            return client_1.NotificationModule.SYSTEM;
    }
}
function parseModule(raw) {
    if (typeof raw !== 'string')
        return undefined;
    const normalized = raw.trim().toUpperCase();
    if (!normalized)
        return undefined;
    if (normalized in client_1.NotificationModule) {
        return normalized;
    }
    switch (normalized) {
        case 'PROMOTION':
            return client_1.NotificationModule.PROMOTIONS;
        case 'MESSAGE':
            return client_1.NotificationModule.MESSAGES;
        case 'ACCOUNTS':
            return client_1.NotificationModule.ACCOUNT;
        case 'HOME-SERVICES':
        case 'HOME_SERVICE':
            return client_1.NotificationModule.HOME_SERVICES;
        default:
            return undefined;
    }
}
function parseType(raw) {
    if (typeof raw !== 'string')
        return undefined;
    const normalized = raw.trim().toUpperCase();
    if (!normalized)
        return undefined;
    if (normalized in client_1.NotificationType) {
        return normalized;
    }
    switch (normalized) {
        case 'PROMOTIONS':
            return client_1.NotificationType.PROMOTION;
        default:
            return undefined;
    }
}
function parsePriority(raw) {
    if (typeof raw !== 'string')
        return undefined;
    const normalized = raw.trim().toUpperCase();
    if (!normalized)
        return undefined;
    return normalized in client_1.NotificationPriority
        ? normalized
        : undefined;
}
function parsePlatform(raw) {
    if (typeof raw !== 'string')
        return client_1.DevicePlatform.UNKNOWN;
    const normalized = raw.trim().toUpperCase();
    return normalized in client_1.DevicePlatform
        ? normalized
        : client_1.DevicePlatform.UNKNOWN;
}
function serializeNotification(notification) {
    return {
        id: notification.id,
        userId: notification.userId,
        type: notification.type,
        module: notification.module,
        priority: notification.priority,
        title: notification.title,
        body: notification.body,
        route: notification.route,
        dedupeKey: notification.dedupeKey,
        metadata: notification.metadata ?? notification.data,
        data: notification.data,
        readAt: notification.readAt,
        createdAt: notification.createdAt,
    };
}
router.get('/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const notifications = await db_1.prisma.notification.findMany({
        where: { userId },
        orderBy: [{ createdAt: 'desc' }],
        take: 100,
    });
    res.json(notifications.map((notification) => serializeNotification(notification)));
}));
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const parsed = createNotificationSchema.parse({
        ...req.body,
        module: parseModule(req.body.module),
        type: parseType(req.body.type),
        priority: parsePriority(req.body.priority),
    });
    const module = parsed.module ?? inferModuleFromType(parsed.type ?? client_1.NotificationType.SYSTEM);
    const type = parsed.type ?? inferTypeFromModule(module);
    if (parsed.dedupeKey) {
        const existing = await db_1.prisma.notification.findFirst({
            where: {
                userId: parsed.userId,
                dedupeKey: parsed.dedupeKey,
            },
        });
        if (existing) {
            return res.json(serializeNotification(existing));
        }
    }
    const notification = await db_1.prisma.notification.create({
        data: {
            id: parsed.id,
            userId: parsed.userId,
            type,
            module,
            priority: parsed.priority ?? client_1.NotificationPriority.NORMAL,
            title: parsed.title,
            body: parsed.body,
            route: parsed.route ?? null,
            dedupeKey: parsed.dedupeKey ?? null,
            data: parsed.data ?? parsed.metadata ?? undefined,
            metadata: parsed.metadata ?? parsed.data ?? undefined,
            createdAt: parsed.createdAt ? new Date(parsed.createdAt) : undefined,
            readAt: parsed.readAt ? new Date(parsed.readAt) : null,
        },
    });
    res.status(201).json(serializeNotification(notification));
}));
router.patch('/:id/read', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const id = (0, http_1.getParam)(req.params.id, 'notificationId');
    const notification = await db_1.prisma.notification.update({
        where: { id },
        data: { readAt: new Date() },
    });
    res.json({
        id: notification.id,
        readAt: notification.readAt,
    });
}));
router.post('/device-tokens', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = registerDeviceTokenSchema.parse({
        ...req.body,
        platform: parsePlatform(req.body.platform),
    });
    const record = await db_1.prisma.deviceToken.upsert({
        where: { token: body.token },
        create: {
            userId: body.userId,
            token: body.token,
            platform: body.platform ?? client_1.DevicePlatform.UNKNOWN,
        },
        update: {
            userId: body.userId,
            platform: body.platform ?? client_1.DevicePlatform.UNKNOWN,
            lastSeenAt: new Date(),
        },
    });
    res.status(201).json({
        id: record.id,
        userId: record.userId,
        token: record.token,
        platform: record.platform,
        lastSeenAt: record.lastSeenAt,
    });
}));
exports.default = router;
