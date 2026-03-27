import { ModuleType, OrderStatus, Prisma } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { createOrderCreatedNotification } from '../utils/notifications';
import { toNumber } from '../utils/serializers';

const router = Router();

const orderItemSchema = z.object({
  id: z.string().optional(),
  productId: z.string().optional(),
  name: z.string(),
  brand: z.string().optional(),
  price: z.coerce.number(),
  quantity: z.coerce.number().int().positive(),
  total: z.coerce.number().optional(),
  color: z.string().optional().nullable(),
  size: z.string().optional().nullable(),
  metadata: z.record(z.any()).optional(),
});

const createOrderSchema = z.object({
  userId: z.string(),
  moduleType: z.nativeEnum(ModuleType),
  status: z.nativeEnum(OrderStatus).optional(),
  subtotal: z.coerce.number(),
  tax: z.coerce.number(),
  deliveryFee: z.coerce.number().optional().default(0),
  discount: z.coerce.number().optional().default(0),
  total: z.coerce.number(),
  notes: z.string().optional(),
  items: z.array(orderItemSchema).default([]),
});

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const [orders, appointments, rideBookings, hotelBookings, laundryOrders] =
      await Promise.all([
        prisma.order.findMany({
          where: { userId },
          include: {
            items: true,
          },
        }) as Promise<
          Prisma.OrderGetPayload<{ include: { items: true } }>[]
        >,
        prisma.appointment.findMany({
          where: { userId },
          include: {
            doctor: true,
          },
        }),
        prisma.rideBooking.findMany({
          where: { userId },
          include: {
            rideCategory: true,
          },
        }),
        prisma.hotelBooking.findMany({
          where: { userId },
          include: {
            hotel: true,
          },
        }),
        prisma.laundryOrder.findMany({
          where: { userId },
          include: {
            service: true,
          },
        }),
      ]);

    const history = [
      ...orders.map((order) => {
        const firstMetadata =
          order.items[0]?.metadata && typeof order.items[0].metadata === 'object'
            ? (order.items[0].metadata as Record<string, unknown>)
            : null;

        return {
          id: order.id,
          entryType: 'ORDER',
          userId: order.userId,
          moduleType: order.moduleType,
          moduleName:
            order.items[0]?.brand ??
            order.items[0]?.name ??
            order.moduleType.toLowerCase(),
          status: order.status,
          subtotal: toNumber(order.subtotal),
          tax: toNumber(order.tax),
          deliveryFee: toNumber(order.deliveryFee),
          discount: toNumber(order.discount),
          total: toNumber(order.total),
          createdAt: order.createdAt,
          updatedAt: order.updatedAt,
          address:
            typeof firstMetadata?.address === 'string'
              ? firstMetadata.address
              : null,
          deliveryLabel:
            typeof firstMetadata?.deliveryLabel === 'string'
              ? firstMetadata.deliveryLabel
              : null,
          deliveryEta:
            typeof firstMetadata?.deliveryEta === 'string'
              ? firstMetadata.deliveryEta
              : null,
          paymentLabel:
            typeof firstMetadata?.paymentLabel === 'string'
              ? firstMetadata.paymentLabel
              : null,
          trackingRoute:
            order.moduleType === 'FOOD' &&
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
            price: toNumber(item.unitPrice),
            total: toNumber(item.lineTotal),
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
        moduleType: ModuleType.DOCTOR,
        moduleName: appointment.doctor.name,
        status: appointment.status,
        subtotal: toNumber(appointment.doctor.consultationFee) ?? 0,
        tax: 0,
        deliveryFee: 0,
        discount: 0,
        total: toNumber(appointment.doctor.consultationFee) ?? 0,
        createdAt: appointment.createdAt,
        updatedAt: appointment.updatedAt,
        trackingRoute: '/doctor/appointments',
        items: [
          {
            id: appointment.id,
            name:
              appointment.appointmentType === 'in_person'
                  ? 'In-person consultation'
                  : appointment.appointmentType === 'video'
                  ? 'Video consultation'
                  : appointment.appointmentType === 'chat'
                  ? 'Chat consultation'
                  : 'Consultation',
            quantity: 1,
            price: toNumber(appointment.doctor.consultationFee) ?? 0,
            total: toNumber(appointment.doctor.consultationFee) ?? 0,
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
        moduleType: ModuleType.RIDE,
        moduleName: ride.rideCategory.name,
        status: ride.status,
        subtotal: toNumber(ride.estimatedFare),
        tax: toNumber(ride.tax),
        deliveryFee: 0,
        discount: 0,
        total: toNumber(ride.total),
        createdAt: ride.createdAt,
        updatedAt: ride.updatedAt,
        trackingRoute:
          !['COMPLETED', 'CANCELLED'].includes(ride.status)
              ? `/ride/tracking/${ride.id}`
              : null,
        items: [
          {
            id: ride.id,
            name: ride.vehicleName,
            quantity: 1,
            price: toNumber(ride.estimatedFare) ?? 0,
            total: toNumber(ride.total) ?? 0,
            metadata: {
              pickup: ride.pickupLabel,
              destination: ride.dropoffLabel,
              eta: ride.etaLabel,
              distanceKm: toNumber(ride.distanceKm),
            },
          },
        ],
      })),
      ...hotelBookings.map((booking) => ({
        id: booking.id,
        entryType: 'HOTEL_BOOKING',
        userId: booking.userId,
        moduleType: ModuleType.HOTEL,
        moduleName: booking.hotel.name,
        status:
          booking.status === 'CHECKED_OUT' ? 'COMPLETED' : booking.status,
        subtotal: toNumber(booking.subtotal),
        tax: toNumber(booking.tax),
        deliveryFee: toNumber(booking.serviceFee),
        discount: 0,
        total: toNumber(booking.total),
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
        trackingRoute: null,
        items: [
          {
            id: booking.id,
            name: booking.roomType,
            quantity: booking.nights,
            price: toNumber(booking.subtotal) ?? 0,
            total: toNumber(booking.total) ?? 0,
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
        moduleType: ModuleType.LAUNDRY,
        moduleName: order.service.name,
        status: order.status,
        subtotal: toNumber(order.subtotal),
        tax: toNumber(order.tax),
        deliveryFee: 0,
        discount: 0,
        total: toNumber(order.total),
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        trackingRoute: null,
        items: [
          {
            id: order.id,
            name: order.service.name,
            quantity: order.itemCount,
            price: toNumber(order.subtotal) ?? 0,
            total: toNumber(order.total) ?? 0,
            metadata: {
              pickupAt: order.pickupAt,
              timeSlot: order.timeSlot,
              itemBreakdown: order.itemBreakdown,
            },
          },
        ],
      })),
    ].sort(
      (a, b) =>
        new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
    );

    res.json(history);
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const body: z.infer<typeof createOrderSchema> = createOrderSchema.parse(
      req.body,
    );

    const order = await prisma.order.create({
      data: {
        userId: body.userId,
        moduleType: body.moduleType,
        status: body.status ?? OrderStatus.PENDING,
        subtotal: new Prisma.Decimal(body.subtotal),
        tax: new Prisma.Decimal(body.tax),
        deliveryFee: new Prisma.Decimal(body.deliveryFee),
        discount: new Prisma.Decimal(body.discount),
        total: new Prisma.Decimal(body.total),
        notes: body.notes ?? null,
        items: {
          create: body.items.map((item) => ({
            productId: item.productId ?? null,
            externalRefId: item.id ?? null,
            name: item.name,
            brand: item.brand ?? null,
            quantity: item.quantity,
            unitPrice: new Prisma.Decimal(item.price),
            lineTotal: new Prisma.Decimal(item.total ?? item.price * item.quantity),
            color: item.color ?? null,
            size: item.size ?? null,
            metadata: item.metadata ?? undefined,
          })),
        },
      },
      include: {
        items: true,
      },
    }) as Prisma.OrderGetPayload<{ include: { items: true } }>;

    const primaryLabel =
      order.items[0]?.brand ??
      order.items[0]?.name ??
      order.moduleType.toLowerCase();
    await createOrderCreatedNotification({
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
      subtotal: toNumber(order.subtotal),
      tax: toNumber(order.tax),
      deliveryFee: toNumber(order.deliveryFee),
      discount: toNumber(order.discount),
      total: toNumber(order.total),
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: order.items.map((item) => ({
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        price: toNumber(item.unitPrice),
        total: toNumber(item.lineTotal),
      })),
    });
  }),
);

export default router;
