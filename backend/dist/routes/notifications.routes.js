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
    userId: zod_1.z.string(),
    type: zod_1.z.nativeEnum(client_1.NotificationType),
    title: zod_1.z.string().min(1),
    body: zod_1.z.string().min(1),
    data: zod_1.z.record(zod_1.z.any()).optional(),
});
router.get('/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const notifications = await db_1.prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
    });
    res.json(notifications.map((notification) => ({
        id: notification.id,
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        data: notification.data,
        readAt: notification.readAt,
        createdAt: notification.createdAt,
    })));
}));
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createNotificationSchema.parse(req.body);
    const notification = await db_1.prisma.notification.create({
        data: {
            userId: body.userId,
            type: body.type,
            title: body.title,
            body: body.body,
            data: body.data ?? undefined,
        },
    });
    res.status(201).json({
        id: notification.id,
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        data: notification.data,
        readAt: notification.readAt,
        createdAt: notification.createdAt,
    });
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
exports.default = router;
