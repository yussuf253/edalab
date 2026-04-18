import {
  DevicePlatform,
  NotificationModule,
  NotificationPriority,
  NotificationType,
} from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';

import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';

const router = Router();

const createNotificationSchema = z.object({
  userId: z.string().min(1),
  id: z.string().optional(),
  title: z.string().min(1),
  body: z.string().min(1),
  module: z.nativeEnum(NotificationModule).optional(),
  type: z.nativeEnum(NotificationType).optional(),
  priority: z.nativeEnum(NotificationPriority).optional(),
  route: z.string().optional().nullable(),
  dedupeKey: z.string().optional().nullable(),
  metadata: z.record(z.any()).optional(),
  data: z.record(z.any()).optional(),
  createdAt: z.string().datetime().optional(),
  readAt: z.string().datetime().optional().nullable(),
});

const registerDeviceTokenSchema = z.object({
  userId: z.string().min(1),
  token: z.string().min(1),
  platform: z.nativeEnum(DevicePlatform).optional(),
});

function inferTypeFromModule(module: NotificationModule): NotificationType {
  switch (module) {
    case NotificationModule.ORDERS:
    case NotificationModule.FOOD:
    case NotificationModule.SHOPPING:
    case NotificationModule.GROCERY:
    case NotificationModule.PHARMACY:
    case NotificationModule.HOTEL:
      return NotificationType.ORDER;
    case NotificationModule.DOCTOR:
      return NotificationType.APPOINTMENT;
    case NotificationModule.RIDE:
      return NotificationType.RIDE;
    case NotificationModule.LAUNDRY:
      return NotificationType.LAUNDRY;
    case NotificationModule.PROMOTIONS:
      return NotificationType.PROMOTION;
    case NotificationModule.MESSAGES:
    case NotificationModule.HOME_SERVICES:
    case NotificationModule.ACCOUNT:
    case NotificationModule.SYSTEM:
      return NotificationType.SYSTEM;
  }
}

function inferModuleFromType(type: NotificationType): NotificationModule {
  switch (type) {
    case NotificationType.ORDER:
      return NotificationModule.ORDERS;
    case NotificationType.APPOINTMENT:
      return NotificationModule.DOCTOR;
    case NotificationType.PROMOTION:
      return NotificationModule.PROMOTIONS;
    case NotificationType.RIDE:
      return NotificationModule.RIDE;
    case NotificationType.LAUNDRY:
      return NotificationModule.LAUNDRY;
    case NotificationType.SYSTEM:
      return NotificationModule.SYSTEM;
  }
}

function parseModule(raw: unknown): NotificationModule | undefined {
  if (typeof raw !== 'string') return undefined;
  const normalized = raw.trim().toUpperCase();
  if (!normalized) return undefined;

  if (normalized in NotificationModule) {
    return normalized as NotificationModule;
  }

  switch (normalized) {
    case 'PROMOTION':
      return NotificationModule.PROMOTIONS;
    case 'MESSAGE':
      return NotificationModule.MESSAGES;
    case 'ACCOUNTS':
      return NotificationModule.ACCOUNT;
    case 'HOME-SERVICES':
    case 'HOME_SERVICE':
    case 'HOUSE_HELP':
    case 'HOUSE-HELP':
    case 'HOUSEHELP':
      return NotificationModule.HOME_SERVICES;
    default:
      return undefined;
  }
}

function parseType(raw: unknown): NotificationType | undefined {
  if (typeof raw !== 'string') return undefined;
  const normalized = raw.trim().toUpperCase();
  if (!normalized) return undefined;
  if (normalized in NotificationType) {
    return normalized as NotificationType;
  }
  switch (normalized) {
    case 'PROMOTIONS':
      return NotificationType.PROMOTION;
    default:
      return undefined;
  }
}

function parsePriority(raw: unknown): NotificationPriority | undefined {
  if (typeof raw !== 'string') return undefined;
  const normalized = raw.trim().toUpperCase();
  if (!normalized) return undefined;
  return normalized in NotificationPriority
    ? (normalized as NotificationPriority)
    : undefined;
}

function parsePlatform(raw: unknown): DevicePlatform {
  if (typeof raw !== 'string') return DevicePlatform.UNKNOWN;
  const normalized = raw.trim().toUpperCase();
  return normalized in DevicePlatform
    ? (normalized as DevicePlatform)
    : DevicePlatform.UNKNOWN;
}

function serializeNotification(
  notification: Awaited<ReturnType<typeof prisma.notification.findFirstOrThrow>>,
) {
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

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const notifications = await prisma.notification.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'desc' }],
      take: 100,
    });

    res.json(notifications.map((notification) => serializeNotification(notification)));
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const parsed = createNotificationSchema.parse({
      ...req.body,
      module: parseModule(req.body.module),
      type: parseType(req.body.type),
      priority: parsePriority(req.body.priority),
    });

    const module = parsed.module ?? inferModuleFromType(parsed.type ?? NotificationType.SYSTEM);
    const type = parsed.type ?? inferTypeFromModule(module);

    if (parsed.dedupeKey) {
      const existing = await prisma.notification.findFirst({
        where: {
          userId: parsed.userId,
          dedupeKey: parsed.dedupeKey,
        },
      });

      if (existing) {
        return res.json(serializeNotification(existing));
      }
    }

    const notification = await prisma.notification.create({
      data: {
        id: parsed.id,
        userId: parsed.userId,
        type,
        module,
        priority: parsed.priority ?? NotificationPriority.NORMAL,
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
  }),
);

router.patch(
  '/:id/read',
  asyncHandler(async (req, res) => {
    const id = getParam(req.params.id, 'notificationId');
    const readAt = new Date();
    const result = await prisma.notification.updateMany({
      where: { id },
      data: { readAt },
    });

    res.json({
      id,
      readAt: result.count > 0 ? readAt : null,
      updated: result.count > 0,
    });
  }),
);

router.post(
  '/device-tokens',
  asyncHandler(async (req, res) => {
    const body = registerDeviceTokenSchema.parse({
      ...req.body,
      platform: parsePlatform(req.body.platform),
    });

    const record = await prisma.deviceToken.upsert({
      where: { token: body.token },
      create: {
        userId: body.userId,
        token: body.token,
        platform: body.platform ?? DevicePlatform.UNKNOWN,
      },
      update: {
        userId: body.userId,
        platform: body.platform ?? DevicePlatform.UNKNOWN,
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
  }),
);

export default router;
