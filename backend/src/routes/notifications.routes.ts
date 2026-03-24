import { NotificationType } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';

const router = Router();

const createNotificationSchema = z.object({
  userId: z.string(),
  type: z.nativeEnum(NotificationType),
  title: z.string().min(1),
  body: z.string().min(1),
  data: z.record(z.any()).optional(),
});

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    res.json(
      notifications.map((notification) => ({
        id: notification.id,
        userId: notification.userId,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        data: notification.data,
        readAt: notification.readAt,
        createdAt: notification.createdAt,
      })),
    );
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const body = createNotificationSchema.parse(req.body);

    const notification = await prisma.notification.create({
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
  }),
);

router.patch(
  '/:id/read',
  asyncHandler(async (req, res) => {
    const id = getParam(req.params.id, 'notificationId');
    const notification = await prisma.notification.update({
      where: { id },
      data: { readAt: new Date() },
    });

    res.json({
      id: notification.id,
      readAt: notification.readAt,
    });
  }),
);

export default router;
