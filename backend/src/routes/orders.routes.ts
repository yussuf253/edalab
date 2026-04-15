import {
  HotelBookingStatus,
  ModuleType,
  NotificationModule,
  NotificationType,
  OrderStatus,
  Prisma,
  ProModule,
  ProProfileType,
} from '@prisma/client';
import { Router } from 'express';
import { randomUUID } from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import {
  createBackendNotification,
  createOrderCreatedNotification,
} from '../utils/notifications';
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

const createPharmacyPrescriptionOrderSchema = z.object({
  userId: z.string().min(1),
  pharmacyName: z.string().min(2),
  note: z.string().optional(),
  prescriptionImageUrl: z.string().url().optional(),
  latitude: z.coerce.number().optional(),
  longitude: z.coerce.number().optional(),
  address: z.string().optional(),
});

const uploadPrescriptionImageSchema = z.object({
  userId: z.string().optional().nullable(),
  fileName: z.string().min(1).max(180).optional().nullable(),
  mimeType: z.string().max(120).optional().nullable(),
  dataBase64: z.string().min(24),
});

const createHotelBookingSchema = z
  .object({
    userId: z.string(),
    hotelId: z.string(),
    roomType: z.string().min(1),
    guestName: z.string().min(1),
    guestEmail: z.string().email(),
    guestPhone: z.string().optional().nullable(),
    specialRequests: z.string().optional().nullable(),
    checkInAt: z.coerce.date(),
    checkOutAt: z.coerce.date(),
    nights: z.coerce.number().int().positive(),
    guestCount: z.coerce.number().int().positive(),
    subtotal: z.coerce.number(),
    serviceFee: z.coerce.number(),
    tax: z.coerce.number(),
    total: z.coerce.number(),
  })
  .superRefine((value, ctx) => {
    if (value.checkOutAt <= value.checkInAt) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Check-out must be after check-in.',
        path: ['checkOutAt'],
      });
    }
  });

function serializeHotelBooking(
  booking: Prisma.HotelBookingGetPayload<{
    include: {
      hotel: true;
    };
  }>,
) {
  return {
    id: booking.id,
    userId: booking.userId,
    hotelId: booking.hotelId,
    hotelName: booking.hotel.name,
    moduleType: ModuleType.HOTEL,
    status:
      booking.status === HotelBookingStatus.CHECKED_OUT
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
    subtotal: toNumber(booking.subtotal),
    serviceFee: toNumber(booking.serviceFee),
    tax: toNumber(booking.tax),
    total: toNumber(booking.total),
    createdAt: booking.createdAt,
    updatedAt: booking.updatedAt,
    items: [
      {
        id: booking.id,
        name: booking.roomType,
        quantity: booking.nights,
        price: toNumber(booking.subtotal) ?? 0,
        total: toNumber(booking.total) ?? 0,
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

type OrderWithItemsAndDelivery = Prisma.OrderGetPayload<{
  include: {
    items: {
      include: {
        product: {
          include: {
            shop: true;
          };
        };
      };
    };
    deliveryAssignee: true;
  };
}>;

type OrderItemWithProduct = OrderWithItemsAndDelivery['items'][number];

function metadataRecord(value: Prisma.JsonValue | null | undefined) {
  if (value && typeof value === 'object' && !Array.isArray(value)) {
    return { ...(value as Record<string, unknown>) };
  }
  return {} as Record<string, unknown>;
}

function normalizeStringList(value: unknown) {
  if (!Array.isArray(value)) return [];
  return value
    .map((entry) => (typeof entry === 'string' ? entry.trim() : ''))
    .filter((entry): entry is string => entry.length > 0);
}

function bindingsProviderIds(value: unknown) {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    return [];
  }
  const map = value as Record<string, unknown>;
  return normalizeStringList(map.providerIds);
}

function bindingsPharmacyBusinesses(value: unknown) {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    return [];
  }
  const map = value as Record<string, unknown>;
  return normalizeStringList(map.pharmacyBusinesses);
}

function equalsNormalizedText(left: string, right: string) {
  return left.trim().toLowerCase() === right.trim().toLowerCase();
}

function firstImageFromJson(value: Prisma.JsonValue | null | undefined) {
  if (!Array.isArray(value)) return null;
  const image = value.find((entry) => typeof entry === 'string');
  return typeof image === 'string' ? image : null;
}

function firstNonEmptyString(...values: Array<string | null | undefined>) {
  for (const value of values) {
    if (value && value.trim().length > 0) {
      return value.trim();
    }
  }
  return null;
}

function fileExtensionFromMimeType(mimeType: string | null | undefined) {
  const normalized = mimeType?.trim().toLowerCase();
  switch (normalized) {
    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    default:
      return null;
  }
}

function fileExtensionFromName(fileName: string | null | undefined) {
  const trimmed = fileName?.trim();
  if (trimmed == null || trimmed.length == 0) return null;
  const extension = trimmed.split('.').pop()?.trim().toLowerCase();
  if (extension == null || extension.length == 0) return null;
  if (['jpg', 'jpeg', 'png', 'webp'].includes(extension)) {
    return extension == 'jpeg' ? 'jpg' : extension;
  }
  return null;
}

function decodedBase64Image(dataBase64: string) {
  const payload = dataBase64.trim();
  const withoutPrefix = payload.includes(',')
    ? payload.substring(payload.indexOf(',') + 1)
    : payload;
  return Buffer.from(withoutPrefix, 'base64');
}

function enrichOrderItemMetadata(item: OrderItemWithProduct) {
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

function resolveOrderModuleName(order: OrderWithItemsAndDelivery) {
  if (order.moduleType === ModuleType.SHOPPING) {
    for (const item of order.items) {
      const metadata = enrichOrderItemMetadata(item);
      if (
        typeof metadata.shopName === 'string' &&
        metadata.shopName.trim().length > 0
      ) {
        return metadata.shopName.trim();
      }
      if (
        item.product?.shop?.name &&
        item.product.shop.name.trim().length > 0
      ) {
        return item.product.shop.name.trim();
      }
    }
  }

  return (
    firstNonEmptyString(
      order.items[0]?.brand,
      order.items[0]?.name,
      order.moduleType.toLowerCase(),
    ) ?? order.moduleType.toLowerCase()
  );
}

function serializeOrderDetail(
  order: OrderWithItemsAndDelivery,
) {
  const user = (
    order as OrderWithItemsAndDelivery & {
      user?: { firstName: string; lastName: string; phone: string | null };
    }
  ).user;
  const customerLabel = user
    ? `${user.firstName} ${user.lastName}`.trim()
    : null;
  const firstMetadata = order.items[0]
    ? enrichOrderItemMetadata(order.items[0])
    : null;

  return {
    id: order.id,
    userId: order.userId,
    moduleType: order.moduleType,
    moduleName: resolveOrderModuleName(order),
    status: order.status,
    subtotal: toNumber(order.subtotal),
    tax: toNumber(order.tax),
    deliveryFee: toNumber(order.deliveryFee),
    discount: toNumber(order.discount),
    total: toNumber(order.total),
    createdAt: order.createdAt,
    updatedAt: order.updatedAt,
    customerName: customerLabel && customerLabel.length > 0 ? customerLabel : null,
    customerPhone: user?.phone ?? null,
    address:
      typeof firstMetadata?.address === 'string' ? firstMetadata.address : null,
    deliveryLabel:
      typeof firstMetadata?.deliveryLabel === 'string'
        ? firstMetadata.deliveryLabel
        : null,
    deliveryEta:
      typeof firstMetadata?.deliveryEta === 'string'
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
      price: toNumber(item.unitPrice),
      total: toNumber(item.lineTotal),
      color: item.color,
      size: item.size,
      metadata: enrichOrderItemMetadata(item),
    })),
  };
}

router.get(
  '/detail/:orderId',
  asyncHandler(async (req, res) => {
    const orderId = getParam(req.params.orderId, 'orderId');
    const order = await prisma.order.findUnique({
      where: { id: orderId },
      include: {
        user: {
          select: { firstName: true, lastName: true, phone: true },
        },
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
  }),
);

router.get(
  '/hotel-bookings/:bookingId',
  asyncHandler(async (req, res) => {
    const bookingId = getParam(req.params.bookingId, 'bookingId');
    const booking = await prisma.hotelBooking.findUnique({
      where: { id: bookingId },
      include: {
        hotel: true,
      },
    });

    if (!booking) {
      return res.status(404).json({ error: 'Hotel booking not found.' });
    }

    res.json(serializeHotelBooking(booking));
  }),
);

router.post(
  '/hotel-bookings',
  asyncHandler(async (req, res) => {
    const body: z.infer<typeof createHotelBookingSchema> =
      createHotelBookingSchema.parse(req.body);

    const hotel = await prisma.hotel.findUnique({
      where: { id: body.hotelId },
    });

    if (!hotel) {
      return res.status(404).json({ error: 'Hotel not found.' });
    }

    const booking = await prisma.hotelBooking.create({
      data: {
        userId: body.userId,
        hotelId: body.hotelId,
        status: HotelBookingStatus.CONFIRMED,
        roomType: body.roomType,
        guestName: body.guestName.trim(),
        guestEmail: body.guestEmail.trim().toLowerCase(),
        guestPhone: body.guestPhone?.trim() || null,
        specialRequests: body.specialRequests?.trim() || null,
        checkInAt: body.checkInAt,
        checkOutAt: body.checkOutAt,
        nights: body.nights,
        guestCount: body.guestCount,
        subtotal: new Prisma.Decimal(body.subtotal),
        serviceFee: new Prisma.Decimal(body.serviceFee),
        tax: new Prisma.Decimal(body.tax),
        total: new Prisma.Decimal(body.total),
      },
      include: {
        hotel: true,
      },
    });

    await createOrderCreatedNotification({
      userId: booking.userId,
      orderId: booking.id,
      moduleType: ModuleType.HOTEL,
      moduleName: hotel.name,
    });

    res.status(201).json(serializeHotelBooking(booking));
  }),
);

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const [orders, appointments, rideBookings, hotelBookings, laundryOrders] =
      await Promise.all([
        prisma.order.findMany({
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
        }) as Promise<
          Prisma.OrderGetPayload<{
            include: {
              items: {
                include: {
                  product: {
                    include: {
                      shop: true;
                    };
                  };
                };
              };
              deliveryAssignee: true;
            };
          }>[]
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
          deliveryAssigneeName:
            order.deliveryAssignee?.firstName && order.deliveryAssignee?.lastName
              ? `${order.deliveryAssignee.firstName} ${order.deliveryAssignee.lastName}`.trim()
              : null,
          deliveryAssigneePhone: order.deliveryAssignee?.phone ?? null,
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
            metadata: enrichOrderItemMetadata(item),
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
        trackingRoute: `/hotel/order/${booking.id}`,
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
  '/pharmacy-prescription',
  asyncHandler(async (req, res) => {
    const body: z.infer<typeof createPharmacyPrescriptionOrderSchema> =
      createPharmacyPrescriptionOrderSchema.parse(req.body);

    const pharmacyName = body.pharmacyName.trim();
    const metadata: Record<string, unknown> = {
      sourceBusiness: pharmacyName,
      selectedPharmacy: pharmacyName,
      prescriptionRequest: true,
      prescriptionNote: body.note?.trim() ?? '',
      ...(((body.prescriptionImageUrl?.trim().length ?? 0) > 0)
          ? { prescriptionImageUrl: body.prescriptionImageUrl!.trim() }
          : {}),
      ...(((body.address?.trim().length ?? 0) > 0)
          ? { address: body.address!.trim() }
          : {}),
      ...((body.latitude != null && body.longitude != null)
          ? {
              serviceLocation: {
                latitude: body.latitude,
                longitude: body.longitude,
              },
            }
          : {}),
      uploadedAt: new Date().toISOString(),
    };

    const order = await prisma.order.create({
      data: {
        userId: body.userId,
        moduleType: ModuleType.PHARMACY,
        status: OrderStatus.PENDING,
        subtotal: new Prisma.Decimal(0),
        tax: new Prisma.Decimal(0),
        deliveryFee: new Prisma.Decimal(0),
        discount: new Prisma.Decimal(0),
        total: new Prisma.Decimal(0),
        notes: body.note?.trim() || null,
        items: {
          create: [
            {
              productId: null,
              externalRefId: null,
              name: 'Prescription request',
              brand: pharmacyName,
              quantity: 1,
              unitPrice: new Prisma.Decimal(0),
              lineTotal: new Prisma.Decimal(0),
              metadata: metadata as Prisma.InputJsonValue,
            },
          ],
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
    }) as OrderWithItemsAndDelivery;

    await createOrderCreatedNotification({
      userId: order.userId,
      orderId: order.id,
      moduleType: order.moduleType,
      moduleName: pharmacyName,
    });

    const shopProfiles = await prisma.proProfile.findMany({
      where: {
        type: ProProfileType.SHOP,
        activeModules: { has: ProModule.PHARMACY },
      },
      select: {
        userId: true,
        bindings: true,
      },
    });

    const recipientUserIds = Array.from(
      new Set(
        shopProfiles
          .filter((profile) =>
            bindingsPharmacyBusinesses(profile.bindings).some((business) =>
              equalsNormalizedText(business, pharmacyName),
            ),
          )
          .map((profile) => profile.userId)
          .filter((id) => id.trim().length > 0),
      ),
    );

    await Promise.allSettled(
      recipientUserIds.map((recipientUserId) =>
        createBackendNotification({
          userId: recipientUserId,
          type: NotificationType.SYSTEM,
          module: NotificationModule.PHARMACY,
          title: 'New prescription request',
          body: `A customer uploaded a prescription request for ${pharmacyName}.`,
          route: '/pro/shop/queue?module=pharmacy',
          dedupeKey: `pharmacy-rx:${order.id}:${recipientUserId}`,
          metadata: {
            orderId: order.id,
            moduleType: ModuleType.PHARMACY,
            source: 'pharmacy_prescription',
            pharmacyName,
            prescriptionRequest: true,
          },
        }),
      ),
    );

    res.status(201).json(serializeOrderDetail(order));
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
    }) as OrderWithItemsAndDelivery;

    const primaryLabel = resolveOrderModuleName(order);
    await createOrderCreatedNotification({
      userId: order.userId,
      orderId: order.id,
      moduleType: order.moduleType,
      moduleName: primaryLabel,
    });

    const serviceRequestModule =
      order.moduleType === ModuleType.HOME_SERVICES ||
      order.moduleType === ModuleType.HOUSE_HELP;

    if (serviceRequestModule) {
      const firstItem = order.items[0];
      const firstMetadata = firstItem
        ? enrichOrderItemMetadata(firstItem)
        : ({} as Record<string, unknown>);
      const poolProviderIds = normalizeStringList(firstMetadata.providerPoolIds);
      const metadataProviderId =
        typeof firstMetadata.providerId === 'string'
          ? firstMetadata.providerId.trim()
          : '';
      const directProviderId =
        firstItem?.externalRefId?.trim() || metadataProviderId;

      const targetProviderIds = Array.from(
        new Set([
          ...(directProviderId.length > 0 ? [directProviderId] : []),
          ...poolProviderIds,
        ]),
      );

      if (targetProviderIds.length > 0) {
        const providerProfiles = await prisma.proProfile.findMany({
          where: {
            type: ProProfileType.PROVIDER,
            activeModules: { has: ProModule.SERVICES },
          },
          select: {
            userId: true,
            bindings: true,
          },
        });

        const recipientUserIds = Array.from(
          new Set(
            providerProfiles
              .filter((profile) => {
                const boundProviderIds = bindingsProviderIds(profile.bindings);
                return boundProviderIds.some((id) =>
                  targetProviderIds.includes(id),
                );
              })
              .map((profile) => profile.userId)
              .filter((id) => id.trim().length > 0),
          ),
        );

        await Promise.allSettled(
          recipientUserIds.map((providerUserId) =>
            createBackendNotification({
              userId: providerUserId,
              type: NotificationType.SYSTEM,
              module: NotificationModule.HOME_SERVICES,
              title:
                order.moduleType === ModuleType.HOUSE_HELP
                  ? 'New house-help request'
                  : 'New home-service request',
              body:
                order.moduleType === ModuleType.HOUSE_HELP
                  ? 'A nearby house-help booking is waiting for provider action.'
                  : 'A new service booking is waiting for provider action.',
              route: `/pro/provider/job/${order.id}`,
              dedupeKey: `provider-request:${order.id}:${providerUserId}`,
              metadata: {
                orderId: order.id,
                moduleType: order.moduleType,
                source: 'order_created',
                queueType: poolProviderIds.length > 0 ? 'open' : 'assigned',
              },
            }),
          ),
        );
      }
    }

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
        metadata: enrichOrderItemMetadata(item),
      })),
    });
  }),
);

router.post(
  '/pharmacy-prescription/upload',
  asyncHandler(async (req, res) => {
    const body: z.infer<typeof uploadPrescriptionImageSchema> =
      uploadPrescriptionImageSchema.parse(req.body);

    const fileBuffer = decodedBase64Image(body.dataBase64);
    if (fileBuffer.length == 0) {
      return res.status(400).json({ error: 'Uploaded image is empty.' });
    }
    const maxSizeBytes = 5 * 1024 * 1024;
    if (fileBuffer.length > maxSizeBytes) {
      return res
        .status(400)
        .json({ error: 'Image is too large. Maximum size is 5 MB.' });
    }

    const extension =
      fileExtensionFromMimeType(body.mimeType) ??
      fileExtensionFromName(body.fileName) ??
      'jpg';
    const fileName = `rx-${Date.now()}-${randomUUID()}.${extension}`;
    const uploadsDir = path.resolve(
      process.cwd(),
      'uploads',
      'prescriptions',
    );
    await fs.mkdir(uploadsDir, { recursive: true });
    const absoluteFilePath = path.join(uploadsDir, fileName);
    await fs.writeFile(absoluteFilePath, fileBuffer);

    const relativePath = `/uploads/prescriptions/${fileName}`;
    const forwardedProto = req
      .header('x-forwarded-proto')
      ?.split(',')[0]
      ?.trim();
    const protocol = forwardedProto || req.protocol || 'https';
    const host = req.get('host');
    const publicUrl =
      host == null || host.trim().length == 0
        ? relativePath
        : `${protocol}://${host}${relativePath}`;

    res.status(201).json({
      fileName,
      mimeType: body.mimeType ?? null,
      sizeBytes: fileBuffer.length,
      path: relativePath,
      url: publicUrl,
    });
  }),
);

export default router;
