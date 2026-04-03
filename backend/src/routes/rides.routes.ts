import { Prisma, RideStatus } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { createRideCreatedNotification } from '../utils/notifications';
import { toNumber } from '../utils/serializers';

const router = Router();

const createRideSchema = z.object({
  userId: z.string(),
  rideCategoryId: z.string(),
  paymentMethodId: z.string().optional(),
  pickupAddressId: z.string().optional(),
  dropoffAddressId: z.string().optional(),
  pickupLabel: z.string().min(1),
  dropoffLabel: z.string().min(1),
  distanceKm: z.coerce.number().positive(),
  estimatedFare: z.coerce.number().nonnegative(),
  tax: z.coerce.number().nonnegative(),
  total: z.coerce.number().nonnegative(),
  etaLabel: z.string().optional(),
  driverName: z.string().optional(),
  driverPhone: z.string().optional(),
  vehicleName: z.string().min(1),
  trackingData: z.record(z.any()).optional(),
});

function serializeRideBooking(
  booking: Prisma.RideBookingGetPayload<{
    include: {
      rideCategory: true;
      paymentMethod: true;
      pickupAddress: true;
      dropoffAddress: true;
    };
  }>,
) {
  return {
    id: booking.id,
    userId: booking.userId,
    driverUserId: booking.driverUserId,
    rideCategoryId: booking.rideCategoryId,
    status: booking.status.toLowerCase(),
    pickup: booking.pickupLabel,
    destination: booking.dropoffLabel,
    distanceKm: toNumber(booking.distanceKm),
    estimatedFare: toNumber(booking.estimatedFare),
    tax: toNumber(booking.tax),
    total: toNumber(booking.total),
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
      basePrice: toNumber(booking.rideCategory.basePrice),
      pricePerKm: toNumber(booking.rideCategory.pricePerKm),
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

router.get(
  '/user/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const bookings = await prisma.rideBooking.findMany({
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
  }),
);

router.get(
  '/:rideId',
  asyncHandler(async (req, res) => {
    const rideId = getParam(req.params.rideId, 'rideId');
    const booking = await prisma.rideBooking.findUnique({
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
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const body = createRideSchema.parse(req.body);

    const booking = await prisma.rideBooking.create({
      data: {
        userId: body.userId,
        rideCategoryId: body.rideCategoryId,
        paymentMethodId: body.paymentMethodId ?? null,
        pickupAddressId: body.pickupAddressId ?? null,
        dropoffAddressId: body.dropoffAddressId ?? null,
        pickupLabel: body.pickupLabel,
        dropoffLabel: body.dropoffLabel,
        distanceKm: new Prisma.Decimal(body.distanceKm),
        estimatedFare: new Prisma.Decimal(body.estimatedFare),
        tax: new Prisma.Decimal(body.tax),
        total: new Prisma.Decimal(body.total),
        status: RideStatus.REQUESTED,
        etaLabel: body.etaLabel ?? null,
        driverName: body.driverName ?? null,
        driverPhone: body.driverPhone ?? null,
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

    await createRideCreatedNotification({
      userId: booking.userId,
      rideId: booking.id,
      vehicleName: booking.vehicleName,
      pickupLabel: booking.pickupLabel,
    });

    res.status(201).json(serializeRideBooking(booking));
  }),
);

export default router;
