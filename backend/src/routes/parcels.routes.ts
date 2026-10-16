import {
  ModuleType,
  ParcelSize,
  ParcelStatus,
  Prisma,
  ProModule,
  ProProfileType,
} from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { isModuleEnabled, moduleName } from '../utils/module-settings';
import { toNumber } from '../utils/serializers';

const router = Router();

const parcelFees: Record<ParcelSize, number> = {
  [ParcelSize.SMALL]: 500,
  [ParcelSize.MEDIUM]: 800,
  [ParcelSize.LARGE]: 1200,
};

const createParcelSchema = z.object({
  userId: z.string().min(1),
  senderName: z.string().trim().min(2).max(120),
  senderPhone: z.string().trim().min(5).max(40),
  recipientName: z.string().trim().min(2).max(120),
  recipientPhone: z.string().trim().min(5).max(40),
  pickupAddress: z.string().trim().min(5).max(300),
  dropoffAddress: z.string().trim().min(5).max(300),
  packageDescription: z.string().trim().min(2).max(300),
  packageSize: z.nativeEnum(ParcelSize),
  notes: z.string().trim().max(500).optional(),
});

const parcelStatusSchema = z.object({
  status: z.nativeEnum(ParcelStatus),
});

function serializeParcel(parcel: {
  id: string;
  userId: string;
  courierUserId: string | null;
  senderName: string;
  senderPhone: string;
  recipientName: string;
  recipientPhone: string;
  pickupAddress: string;
  dropoffAddress: string;
  packageDescription: string;
  packageSize: ParcelSize;
  status: ParcelStatus;
  deliveryFee: Prisma.Decimal;
  currency: string;
  notes: string | null;
  createdAt: Date;
  updatedAt: Date;
  customer?: { firstName: string; lastName: string; phone: string | null };
  courier?: { firstName: string; lastName: string; phone: string | null } | null;
}) {
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
    deliveryFee: toNumber(parcel.deliveryFee),
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

async function parcelCourierProfile(userId: string) {
  const profile = await prisma.proProfile.findUnique({ where: { userId } });
  if (
    !profile ||
    profile.type !== ProProfileType.DELIVERY ||
    !profile.activeModules.includes(ProModule.PARCEL_DELIVERY)
  ) {
    return { error: 'Parcel delivery is not enabled for this courier profile.', status: 403 };
  }
  return { profile };
}

router.get(
  '/pricing',
  asyncHandler(async (_req, res) => {
    res.json({ currency: 'DJF', fees: parcelFees });
  }),
);

router.get(
  '/user/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const parcels = await prisma.parcelDelivery.findMany({
      where: { userId },
      include: {
        courier: { select: { firstName: true, lastName: true, phone: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    res.json(parcels.map(serializeParcel));
  }),
);

router.get(
  '/pro/:userId/queue',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const access = await parcelCourierProfile(userId);
    if ('error' in access) {
      return res.status(access.status ?? 403).json({ error: access.error });
    }
    const parcels = await prisma.parcelDelivery.findMany({
      where: {
        OR: [
          { status: ParcelStatus.REQUESTED, courierUserId: null },
          {
            courierUserId: userId,
            status: {
              in: [
                ParcelStatus.ACCEPTED,
                ParcelStatus.PICKED_UP,
                ParcelStatus.IN_TRANSIT,
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
    res.json(
      parcels.map((parcel) => ({
        ...serializeParcel(parcel),
        customerName: `${parcel.customer.firstName} ${parcel.customer.lastName}`.trim(),
        customerPhone: parcel.customer.phone,
        queueType: parcel.courierUserId === userId ? 'assigned' : 'open',
      })),
    );
  }),
);

router.post(
  '/pro/:userId/:parcelId/claim',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const parcelId = getParam(req.params.parcelId, 'parcelId');
    const access = await parcelCourierProfile(userId);
    if ('error' in access) {
      return res.status(access.status ?? 403).json({ error: access.error });
    }
    if (!access.profile.isOnline) {
      return res.status(403).json({ error: 'Turn online before claiming parcels.' });
    }

    const result = await prisma.parcelDelivery.updateMany({
      where: {
        id: parcelId,
        status: ParcelStatus.REQUESTED,
        courierUserId: null,
      },
      data: { courierUserId: userId, status: ParcelStatus.ACCEPTED },
    });
    if (result.count === 0) {
      return res.status(409).json({ error: 'Parcel is no longer available.' });
    }
    const parcel = await prisma.parcelDelivery.findUnique({
      where: { id: parcelId },
      include: { courier: { select: { firstName: true, lastName: true, phone: true } } },
    });
    if (!parcel) return res.status(404).json({ error: 'Parcel not found.' });
    res.json(serializeParcel(parcel));
  }),
);

router.patch(
  '/pro/:userId/:parcelId/status',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const parcelId = getParam(req.params.parcelId, 'parcelId');
    const body = parcelStatusSchema.parse(req.body);
    const access = await parcelCourierProfile(userId);
    if ('error' in access) {
      return res.status(access.status ?? 403).json({ error: access.error });
    }

    const parcel = await prisma.parcelDelivery.findFirst({
      where: { id: parcelId, courierUserId: userId },
      select: { status: true },
    });
    const nextStatus: Partial<Record<ParcelStatus, ParcelStatus>> = {
      [ParcelStatus.ACCEPTED]: ParcelStatus.PICKED_UP,
      [ParcelStatus.PICKED_UP]: ParcelStatus.IN_TRANSIT,
      [ParcelStatus.IN_TRANSIT]: ParcelStatus.DELIVERED,
    };
    if (!parcel || nextStatus[parcel.status] !== body.status) {
      return res.status(409).json({ error: 'Parcel status transition is not allowed.' });
    }
    const result = await prisma.parcelDelivery.updateMany({
      where: { id: parcelId, courierUserId: userId, status: parcel.status },
      data: { status: body.status },
    });
    if (result.count === 0) {
      return res.status(409).json({ error: 'Parcel status changed. Refresh and try again.' });
    }
    const updated = await prisma.parcelDelivery.findUnique({
      where: { id: parcelId },
      include: { courier: { select: { firstName: true, lastName: true, phone: true } } },
    });
    if (!updated) return res.status(404).json({ error: 'Parcel not found.' });
    res.json(serializeParcel(updated));
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const body = createParcelSchema.parse(req.body);
    if (!(await isModuleEnabled(ModuleType.PARCEL))) {
      return res.status(403).json({ error: `${moduleName(ModuleType.PARCEL)} module is currently disabled.` });
    }
    const user = await prisma.user.findUnique({
      where: { id: body.userId },
      select: { id: true },
    });
    if (!user) return res.status(404).json({ error: 'Customer account not found.' });
    const parcel = await prisma.parcelDelivery.create({
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
        deliveryFee: new Prisma.Decimal(parcelFees[body.packageSize]),
        notes: body.notes || null,
      },
    });
    res.status(201).json(serializeParcel(parcel));
  }),
);

router.post(
  '/:parcelId/cancel',
  asyncHandler(async (req, res) => {
    const parcelId = getParam(req.params.parcelId, 'parcelId');
    const userId = z.string().min(1).parse(req.body.userId);
    const result = await prisma.parcelDelivery.updateMany({
      where: { id: parcelId, userId, status: ParcelStatus.REQUESTED },
      data: { status: ParcelStatus.CANCELLED },
    });
    if (result.count === 0) {
      return res.status(409).json({ error: 'Only unassigned parcel requests can be cancelled.' });
    }
    res.json({ id: parcelId, status: ParcelStatus.CANCELLED });
  }),
);

export default router;