import {
  ModuleType,
  NotificationModule,
  NotificationPriority,
  NotificationType,
  Prisma,
} from '@prisma/client';
import { randomUUID } from 'crypto';

import { prisma } from '../db';
import { sendPushToUser } from './push';
import { hashPassword } from './password';

// ---------------------------------------------------------------------------
// Super admin fan-out. Super admins have no pro profile, so their notification
// inbox is backed by a plain `User` row keyed by the admin email (created
// lazily on first use). Every platform-wide operation notifies those inboxes
// with the PRO push audience so the admin app receives push + in-app updates.
// ---------------------------------------------------------------------------

export function isSuperAdminEmail(email: string | null | undefined): boolean {
  if (!email) return false;
  const normalized = email.trim().toLowerCase();
  if (!normalized) return false;

  const configured = (
    process.env.SUPER_ADMIN_EMAILS ||
    process.env.SUPER_ADMIN_EMAIL ||
    'admin@edalab.com'
  )
    .split(',')
    .map((entry) => entry.trim().toLowerCase())
    .filter(Boolean);

  return (
    configured.includes(normalized) ||
    normalized.startsWith('admin@') ||
    normalized.includes('+admin@')
  );
}

async function ensureNotificationUser(email: string): Promise<string | null> {
  const normalized = email.trim().toLowerCase();
  if (!normalized) return null;

  try {
    const existing = await prisma.user.findFirst({
      where: { email: { equals: normalized, mode: 'insensitive' } },
      select: { id: true },
    });
    if (existing) return existing.id;

    const created = await prisma.user.create({
      data: {
        email: normalized,
        firstName: 'Super',
        lastName: 'Admin',
        // Never used for login: super admins authenticate through their
        // pro account. The hash just has to satisfy the column contract.
        passwordHash: await hashPassword(randomUUID()),
      },
      select: { id: true },
    });
    return created.id;
  } catch (error) {
    // Unique-violation race (or transient failure): re-read what exists.
    try {
      const existing = await prisma.user.findFirst({
        where: { email: { equals: normalized, mode: 'insensitive' } },
        select: { id: true },
      });
      return existing?.id ?? null;
    } catch {
      console.error('[ADMIN NOTIFY] Failed to resolve admin inbox user', {
        email: normalized,
        error: error instanceof Error ? error.message : String(error),
      });
      return null;
    }
  }
}

/**
 * Resolve the notification-inbox user id for a super admin email, or null
 * when the email isn't a configured super admin. Never throws.
 */
export async function resolveSuperAdminNotificationUserId(
  email: string | null | undefined,
): Promise<string | null> {
  if (!isSuperAdminEmail(email)) return null;
  try {
    return await ensureNotificationUser(email!);
  } catch {
    return null;
  }
}

let adminUserCache: { resolvedAt: number; ids: string[] } | null = null;
const ADMIN_USER_CACHE_TTL_MS = 60_000;

/**
 * All super-admin inbox user ids (one per non-banned pro account with an
 * admin email). Short-lived cache so per-event fan-out stays cheap.
 */
export async function resolveSuperAdminUserIds(): Promise<string[]> {
  if (adminUserCache && Date.now() - adminUserCache.resolvedAt < ADMIN_USER_CACHE_TTL_MS) {
    return adminUserCache.ids;
  }

  try {
    const accounts = await prisma.proAccount.findMany({
      select: { email: true, banned: true },
    });
    const adminEmails = Array.from(
      new Set(
        accounts
          .filter((account) => !account.banned && isSuperAdminEmail(account.email))
          .map((account) => account.email.trim().toLowerCase()),
      ),
    );

    const ids: string[] = [];
    for (const email of adminEmails) {
      const id = await ensureNotificationUser(email);
      if (id) ids.push(id);
    }

    adminUserCache = { resolvedAt: Date.now(), ids };
    return ids;
  } catch (error) {
    console.error('[ADMIN NOTIFY] Failed to resolve super admin users', {
      error: error instanceof Error ? error.message : String(error),
    });
    return adminUserCache?.ids ?? [];
  }
}

type SuperAdminEvent = {
  title: string;
  body: string;
  module?: NotificationModule;
  type?: NotificationType;
  route?: string;
  dedupeKey?: string;
  metadata?: Prisma.InputJsonValue;
  priority?: NotificationPriority;
};

/**
 * Fan an operation out to every super admin inbox + their pro-app push
 * tokens. Best-effort: failures are logged and never propagate, so core
 * flows (signup, order creation, ...) can't be broken by notification bugs.
 */
export async function notifySuperAdmins(event: SuperAdminEvent): Promise<void> {
  try {
    const userIds = await resolveSuperAdminUserIds();
    if (userIds.length === 0) return;

    for (const userId of userIds) {
      try {
        await createBackendNotification({
          userId,
          type: event.type ?? NotificationType.SYSTEM,
          module: event.module ?? NotificationModule.SYSTEM,
          title: event.title,
          body: event.body,
          route: event.route ?? null,
          dedupeKey: event.dedupeKey ? `admin:${event.dedupeKey}` : null,
          metadata: event.metadata,
          priority: event.priority ?? NotificationPriority.HIGH,
          audience: 'PRO',
        });
      } catch (error) {
        // Per-recipient isolation: one broken push target must not starve
        // the remaining admin inboxes.
        console.error('[ADMIN NOTIFY] Failed to notify one super admin', {
          title: event.title,
          userId,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    }
  } catch (error) {
    console.error('[ADMIN NOTIFY] Failed to notify super admins', {
      title: event.title,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

async function actorEmailFor(userId: string): Promise<string | null> {
  try {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { email: true },
    });
    return user?.email ?? null;
  } catch {
    return null;
  }
}

function orderModuleLabel(moduleType: ModuleType): string {
  switch (moduleType) {
    case ModuleType.FOOD:
      return 'food';
    case ModuleType.HOTEL:
      return 'hotel';
    case ModuleType.HOME_SERVICES:
      return 'home service';
    case ModuleType.HOUSE_HELP:
      return 'house help';
    case ModuleType.LAUNDRY:
      return 'laundry';
    case ModuleType.SHOPPING:
      return 'shopping';
    case ModuleType.GROCERY:
      return 'grocery';
    case ModuleType.PHARMACY:
      return 'pharmacy';
    case ModuleType.HEALTH_SERVICES:
      return 'health service';
    case ModuleType.DOCTOR:
      return 'doctor';
    case ModuleType.RIDE:
      return 'ride';
    case ModuleType.PARCEL:
      return 'parcel';
  }
}

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
  /** Which app surface the notification targets; defaults to the user app. */
  audience?: 'USER' | 'PRO';
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
  audience = 'USER',
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
    audience,
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

export async function createMessageNotification({
  userId,
  conversationId,
  title,
  body,
  route,
  actorRole,
  entityType,
  entityId,
  moduleType,
  dedupeKey,
  audience,
}: {
  userId: string;
  conversationId: string;
  title: string;
  body: string;
  route: string;
  actorRole: string;
  entityType: string;
  entityId: string;
  moduleType: ModuleType;
  dedupeKey: string;
  audience?: 'USER' | 'PRO';
}) {
  return createBackendNotification({
    userId,
    type: NotificationType.SYSTEM,
    module: NotificationModule.MESSAGES,
    title,
    body,
    route,
    dedupeKey,
    audience: audience ?? (route.startsWith('/pro/') ? 'PRO' : 'USER'),
    metadata: {
      kind: 'message',
      conversationId,
      actorRole,
      entityType,
      entityId,
      moduleType,
      route,
    },
  });
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
  const customerNotification = await buildCustomerOrderNotification({
    userId,
    orderId,
    moduleType,
    moduleName,
  });

  // Doctor and ride orders have dedicated creation helpers that fan out to
  // the super admin themselves — skip to avoid duplicate admin alerts.
  if (moduleType !== ModuleType.DOCTOR && moduleType !== ModuleType.RIDE) {
    const detailName = moduleName?.trim() ?? '';
    const label = orderModuleLabel(moduleType);
    const actor = (await actorEmailFor(userId)) ?? 'A customer';
    const isBooking =
      moduleType === ModuleType.HOTEL ||
      moduleType === ModuleType.HOME_SERVICES ||
      moduleType === ModuleType.HOUSE_HELP;

    await notifySuperAdmins({
      title: isBooking
        ? moduleType === ModuleType.HOTEL
          ? 'New hotel booking'
          : 'New service booking'
        : `New ${label} order`,
      body: detailName.length > 0
        ? `${actor} placed an order at ${detailName}.`
        : `${actor} placed a new ${label} ${isBooking ? 'booking' : 'order'}.`,
      module: NotificationModule.ORDERS,
      type: NotificationType.ORDER,
      route: '/pro/admin/orders',
      dedupeKey: `order-created:${orderId}`,
      metadata: {
        orderId,
        moduleType,
        moduleName: moduleName ?? null,
        userId,
        source: 'order_created',
      },
    });
  }

  return customerNotification;
}

async function buildCustomerOrderNotification({
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
            : `Your order from ${detailName} is confirmed and already being prepared.`,
        route: `/food/tracking/${orderId}`,
        dedupeKey: `order:${orderId}:/food/tracking/${orderId}`,
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
            : `${detailName} is booked and confirmed.`,
        route: `/hotel/order/${orderId}`,
        dedupeKey: `order:${orderId}:/hotel/order/${orderId}`,
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
            : `${detailName} has been scheduled successfully.`,
        route: `/home-services/booking/${orderId}`,
        dedupeKey: `order:${orderId}:/home-services/booking/${orderId}`,
        metadata: {
          orderId,
          moduleType,
          moduleName,
        },
      });
    case ModuleType.HOUSE_HELP:
      return createBackendNotification({
        userId,
        type: NotificationType.SYSTEM,
        module: NotificationModule.HOME_SERVICES,
        title: 'House help scheduled',
        body: detailName.length === 0
            ? 'Your house help booking is confirmed.'
            : `${detailName} has been scheduled successfully.`,
        route: `/home-services/booking/${orderId}`,
        dedupeKey: `order:${orderId}:/home-services/booking/${orderId}`,
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
            : `${detailName} is scheduled for pickup.`,
        route: `/laundry/tracking/${orderId}`,
        dedupeKey: `order:${orderId}:/laundry/tracking/${orderId}`,
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
        body: detailName.length === 0
            ? 'Your shopping order is confirmed and will move through fulfillment shortly.'
            : `${detailName} is confirmed and will move through fulfillment shortly.`,
        route: `/shopping/order/${orderId}`,
        dedupeKey: `order:${orderId}:/shopping/order/${orderId}`,
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
        body: detailName.length === 0
            ? 'Your grocery order is confirmed and the store is preparing your items.'
            : `${detailName} is confirmed and the store is preparing your items.`,
        route: '/orders',
        dedupeKey: `order:${orderId}:/orders`,
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
        body: detailName.length === 0
            ? 'Your pharmacy order is confirmed. Double-check the medicines when they arrive.'
            : `${detailName} is confirmed. Double-check the medicines when they arrive.`,
        route: `/pharmacy/order/${orderId}`,
        dedupeKey: `order:${orderId}:/pharmacy/order/${orderId}`,
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
  const actor = (await actorEmailFor(userId)) ?? 'A customer';

  await notifySuperAdmins({
    title: 'New appointment booked',
    body: `${actor} booked an appointment with ${doctorName} at ${timeSlot}.`,
    module: NotificationModule.DOCTOR,
    type: NotificationType.APPOINTMENT,
    route: '/pro/admin/appointments',
    dedupeKey: `appointment-created:${appointmentId}`,
    metadata: { appointmentId, doctorName, timeSlot, userId },
  });

  return createBackendNotification({
    userId,
    type: NotificationType.APPOINTMENT,
    module: NotificationModule.DOCTOR,
    title: 'Appointment booked',
    body: `${doctorName} is scheduled for ${timeSlot}.`,
    route: '/doctor/appointments',
    dedupeKey: `appointment:${appointmentId}:/doctor/appointments`,
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
  const actor = (await actorEmailFor(userId)) ?? 'A customer';

  await notifySuperAdmins({
    title: 'New ride requested',
    body: pickupLabel.length > 0
      ? `${actor} requested a ride (pickup: ${pickupLabel}).`
      : `${actor} requested a new ride.`,
    module: NotificationModule.RIDE,
    type: NotificationType.RIDE,
    route: '/pro/admin/rides',
    dedupeKey: `ride-created:${rideId}`,
    metadata: { rideId, vehicleName, pickupLabel, userId },
  });

  return createBackendNotification({
    userId,
    type: NotificationType.RIDE,
    module: NotificationModule.RIDE,
    title: 'Ride confirmed',
    body: `${vehicleName} is assigned and heading to ${pickupLabel}.`,
    route: `/ride/tracking/${rideId}`,
    dedupeKey: `ride:${rideId}:/ride/tracking/${rideId}`,
    metadata: {
      rideId,
      vehicleName,
      pickupLabel,
    },
  });
}
