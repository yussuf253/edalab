import {
  ModuleType,
  NotificationModule,
  NotificationPriority,
  NotificationType,
  Prisma,
} from '@prisma/client';

import { prisma } from '../db';
import { sendPushToUser } from './push';

type NotificationPayload = {
  userId: string;
  type: NotificationType;
  module: NotificationModule;
  title: string;
  body: string;
  route?: string | null;
  dedupeKey?: string | null;
  metadata?: Prisma.InputJsonValue;
  priority?: NotificationPriority;
};

export async function createBackendNotification({
  userId,
  type,
  module,
  title,
  body,
  route,
  dedupeKey,
  metadata,
  priority = NotificationPriority.HIGH,
}: NotificationPayload) {
  if (dedupeKey) {
    const existing = await prisma.notification.findFirst({
      where: {
        userId,
        dedupeKey,
      },
    });

    if (existing) {
      return existing;
    }
  }

  const notification = await prisma.notification.create({
    data: {
      userId,
      type,
      module,
      priority,
      title,
      body,
      route: route ?? null,
      dedupeKey: dedupeKey ?? null,
      data: metadata ?? undefined,
      metadata: metadata ?? undefined,
    },
  });

  await sendPushToUser({
    userId,
    title,
    body,
    route,
    module: module.toString().toLowerCase(),
    priority: priority.toString().toLowerCase(),
    dedupeKey,
    metadata: {
      notificationId: notification.id,
      ...(metadata && typeof metadata === 'object'
          ? (metadata as Record<string, unknown>)
          : {}),
    },
  });

  return notification;
}

export async function createOrderCreatedNotification({
  userId,
  orderId,
  moduleType,
  moduleName,
}: {
  userId: string;
  orderId: string;
  moduleType: ModuleType;
  moduleName?: string | null;
}) {
  const detailName = moduleName?.trim() ?? '';

  switch (moduleType) {
    case ModuleType.FOOD:
      return createBackendNotification({
        userId,
        type: NotificationType.ORDER,
        module: NotificationModule.FOOD,
        title: 'Food order confirmed',
        body: detailName.length === 0
            ? 'Your food order is confirmed and the kitchen has started preparing it.'
            : 'Your order from $detailName is confirmed and already being prepared.',
        route: '/food/tracking/$orderId',
        dedupeKey: 'order:$orderId:/food/tracking/$orderId',
        metadata: {
          orderId,
          moduleType,
          moduleName,
        },
      });
    case ModuleType.HOTEL:
      return createBackendNotification({
        userId,
        type: NotificationType.ORDER,
        module: NotificationModule.HOTEL,
        title: 'Hotel stay confirmed',
        body: detailName.length === 0
            ? 'Your hotel booking is confirmed.'
            : '$detailName is booked and confirmed.',
        route: '/hotel/order/$orderId',
        dedupeKey: 'order:$orderId:/hotel/order/$orderId',
        metadata: {
          orderId,
          moduleType,
          moduleName,
        },
      });
    case ModuleType.HOME_SERVICES:
      return createBackendNotification({
        userId,
        type: NotificationType.SYSTEM,
        module: NotificationModule.HOME_SERVICES,
        title: 'Home service scheduled',
        body: detailName.length === 0
            ? 'Your home service booking is confirmed.'
            : '$detailName has been scheduled successfully.',
        route: '/home-services/booking/$orderId',
        dedupeKey: 'order:$orderId:/home-services/booking/$orderId',
        metadata: {
          orderId,
          moduleType,
          moduleName,
        },
      });
    case ModuleType.LAUNDRY:
      return createBackendNotification({
        userId,
        type: NotificationType.LAUNDRY,
        module: NotificationModule.LAUNDRY,
        title: 'Laundry pickup scheduled',
        body: detailName.length === 0
            ? 'Your laundry order is scheduled and we will keep you updated.'
            : '$detailName is scheduled for pickup.',
        route: '/laundry',
        dedupeKey: 'order:$orderId:/laundry',
        metadata: {
          orderId,
          moduleType,
          moduleName,
        },
      });
    case ModuleType.SHOPPING:
      return createBackendNotification({
        userId,
        type: NotificationType.ORDER,
        module: NotificationModule.SHOPPING,
        title: 'Shopping order confirmed',
        body: 'Your shopping order is confirmed and will move through fulfillment shortly.',
        route: '/orders',
        dedupeKey: 'order:$orderId:/orders',
        metadata: {
          orderId,
          moduleType,
          moduleName,
        },
      });
    case ModuleType.GROCERY:
      return createBackendNotification({
        userId,
        type: NotificationType.ORDER,
        module: NotificationModule.GROCERY,
        title: 'Grocery order confirmed',
        body: 'Your grocery order is confirmed and the store is preparing your items.',
        route: '/orders',
        dedupeKey: 'order:$orderId:/orders',
        metadata: {
          orderId,
          moduleType,
          moduleName,
        },
      });
    case ModuleType.PHARMACY:
      return createBackendNotification({
        userId,
        type: NotificationType.ORDER,
        module: NotificationModule.PHARMACY,
        title: 'Pharmacy order confirmed',
        body: 'Your pharmacy order is confirmed. Double-check the medicines when they arrive.',
        route: '/orders',
        dedupeKey: 'order:$orderId:/orders',
        metadata: {
          orderId,
          moduleType,
          moduleName,
        },
      });
    case ModuleType.DOCTOR:
    case ModuleType.RIDE:
      return null;
  }
}

export async function createAppointmentCreatedNotification({
  userId,
  appointmentId,
  doctorName,
  timeSlot,
}: {
  userId: string;
  appointmentId: string;
  doctorName: string;
  timeSlot: string;
}) {
  return createBackendNotification({
    userId,
    type: NotificationType.APPOINTMENT,
    module: NotificationModule.DOCTOR,
    title: 'Appointment booked',
    body: '$doctorName is scheduled for $timeSlot.',
    route: '/doctor/appointments',
    dedupeKey: 'appointment:$appointmentId:/doctor/appointments',
    metadata: {
      appointmentId,
      doctorName,
      timeSlot,
    },
  });
}

export async function createRideCreatedNotification({
  userId,
  rideId,
  vehicleName,
  pickupLabel,
}: {
  userId: string;
  rideId: string;
  vehicleName: string;
  pickupLabel: string;
}) {
  return createBackendNotification({
    userId,
    type: NotificationType.RIDE,
    module: NotificationModule.RIDE,
    title: 'Ride confirmed',
    body: '$vehicleName is assigned and heading to $pickupLabel.',
    route: '/ride/tracking/$rideId',
    dedupeKey: 'ride:$rideId:/ride/tracking/$rideId',
    metadata: {
      rideId,
      vehicleName,
      pickupLabel,
    },
  });
}
