"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isSuperAdminEmail = isSuperAdminEmail;
exports.resolveSuperAdminNotificationUserId = resolveSuperAdminNotificationUserId;
exports.resolveSuperAdminUserIds = resolveSuperAdminUserIds;
exports.notifySuperAdmins = notifySuperAdmins;
exports.createBackendNotification = createBackendNotification;
exports.createMessageNotification = createMessageNotification;
exports.createOrderCreatedNotification = createOrderCreatedNotification;
exports.createAppointmentCreatedNotification = createAppointmentCreatedNotification;
exports.createRideCreatedNotification = createRideCreatedNotification;
const client_1 = require("@prisma/client");
const crypto_1 = require("crypto");
const db_1 = require("../db");
const push_1 = require("./push");
const password_1 = require("./password");
// ---------------------------------------------------------------------------
// Super admin fan-out. Super admins have no pro profile, so their notification
// inbox is backed by a plain `User` row keyed by the admin email (created
// lazily on first use). Every platform-wide operation notifies those inboxes
// with the PRO push audience so the admin app receives push + in-app updates.
// ---------------------------------------------------------------------------
function isSuperAdminEmail(email) {
    if (!email)
        return false;
    const normalized = email.trim().toLowerCase();
    if (!normalized)
        return false;
    const configured = (process.env.SUPER_ADMIN_EMAILS ||
        process.env.SUPER_ADMIN_EMAIL ||
        'admin@edalab.com')
        .split(',')
        .map((entry) => entry.trim().toLowerCase())
        .filter(Boolean);
    return (configured.includes(normalized) ||
        normalized.startsWith('admin@') ||
        normalized.includes('+admin@'));
}
async function ensureNotificationUser(email) {
    const normalized = email.trim().toLowerCase();
    if (!normalized)
        return null;
    try {
        const existing = await db_1.prisma.user.findFirst({
            where: { email: { equals: normalized, mode: 'insensitive' } },
            select: { id: true },
        });
        if (existing)
            return existing.id;
        const created = await db_1.prisma.user.create({
            data: {
                email: normalized,
                firstName: 'Super',
                lastName: 'Admin',
                // Never used for login: super admins authenticate through their
                // pro account. The hash just has to satisfy the column contract.
                passwordHash: await (0, password_1.hashPassword)((0, crypto_1.randomUUID)()),
            },
            select: { id: true },
        });
        return created.id;
    }
    catch (error) {
        // Unique-violation race (or transient failure): re-read what exists.
        try {
            const existing = await db_1.prisma.user.findFirst({
                where: { email: { equals: normalized, mode: 'insensitive' } },
                select: { id: true },
            });
            return existing?.id ?? null;
        }
        catch {
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
async function resolveSuperAdminNotificationUserId(email) {
    if (!isSuperAdminEmail(email))
        return null;
    try {
        return await ensureNotificationUser(email);
    }
    catch {
        return null;
    }
}
let adminUserCache = null;
const ADMIN_USER_CACHE_TTL_MS = 60_000;
/**
 * All super-admin inbox user ids (one per non-banned pro account with an
 * admin email). Short-lived cache so per-event fan-out stays cheap.
 */
async function resolveSuperAdminUserIds() {
    if (adminUserCache && Date.now() - adminUserCache.resolvedAt < ADMIN_USER_CACHE_TTL_MS) {
        return adminUserCache.ids;
    }
    try {
        const accounts = await db_1.prisma.proAccount.findMany({
            select: { email: true, banned: true },
        });
        const adminEmails = Array.from(new Set(accounts
            .filter((account) => !account.banned && isSuperAdminEmail(account.email))
            .map((account) => account.email.trim().toLowerCase())));
        const ids = [];
        for (const email of adminEmails) {
            const id = await ensureNotificationUser(email);
            if (id)
                ids.push(id);
        }
        adminUserCache = { resolvedAt: Date.now(), ids };
        return ids;
    }
    catch (error) {
        console.error('[ADMIN NOTIFY] Failed to resolve super admin users', {
            error: error instanceof Error ? error.message : String(error),
        });
        return adminUserCache?.ids ?? [];
    }
}
/**
 * Fan an operation out to every super admin inbox + their pro-app push
 * tokens. Best-effort: failures are logged and never propagate, so core
 * flows (signup, order creation, ...) can't be broken by notification bugs.
 */
async function notifySuperAdmins(event) {
    try {
        const userIds = await resolveSuperAdminUserIds();
        if (userIds.length === 0)
            return;
        for (const userId of userIds) {
            try {
                await createBackendNotification({
                    userId,
                    type: event.type ?? client_1.NotificationType.SYSTEM,
                    module: event.module ?? client_1.NotificationModule.SYSTEM,
                    title: event.title,
                    body: event.body,
                    route: event.route ?? null,
                    dedupeKey: event.dedupeKey ? `admin:${event.dedupeKey}` : null,
                    metadata: event.metadata,
                    priority: event.priority ?? client_1.NotificationPriority.HIGH,
                    audience: 'PRO',
                });
            }
            catch (error) {
                // Per-recipient isolation: one broken push target must not starve
                // the remaining admin inboxes.
                console.error('[ADMIN NOTIFY] Failed to notify one super admin', {
                    title: event.title,
                    userId,
                    error: error instanceof Error ? error.message : String(error),
                });
            }
        }
    }
    catch (error) {
        console.error('[ADMIN NOTIFY] Failed to notify super admins', {
            title: event.title,
            error: error instanceof Error ? error.message : String(error),
        });
    }
}
async function actorEmailFor(userId) {
    try {
        const user = await db_1.prisma.user.findUnique({
            where: { id: userId },
            select: { email: true },
        });
        return user?.email ?? null;
    }
    catch {
        return null;
    }
}
function orderModuleLabel(moduleType) {
    switch (moduleType) {
        case client_1.ModuleType.FOOD:
            return 'food';
        case client_1.ModuleType.HOTEL:
            return 'hotel';
        case client_1.ModuleType.HOME_SERVICES:
            return 'home service';
        case client_1.ModuleType.HOUSE_HELP:
            return 'house help';
        case client_1.ModuleType.LAUNDRY:
            return 'laundry';
        case client_1.ModuleType.SHOPPING:
            return 'shopping';
        case client_1.ModuleType.GROCERY:
            return 'grocery';
        case client_1.ModuleType.PHARMACY:
            return 'pharmacy';
        case client_1.ModuleType.HEALTH_SERVICES:
            return 'health service';
        case client_1.ModuleType.DOCTOR:
            return 'doctor';
        case client_1.ModuleType.RIDE:
            return 'ride';
        case client_1.ModuleType.PARCEL:
            return 'parcel';
    }
}
async function createBackendNotification({ userId, type, module, title, body, route, dedupeKey, metadata, priority = client_1.NotificationPriority.HIGH, audience = 'USER', }) {
    if (dedupeKey) {
        const existing = await db_1.prisma.notification.findFirst({
            where: {
                userId,
                dedupeKey,
            },
        });
        if (existing) {
            return existing;
        }
    }
    const notification = await db_1.prisma.notification.create({
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
    await (0, push_1.sendPushToUser)({
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
                ? metadata
                : {}),
        },
    });
    return notification;
}
async function createMessageNotification({ userId, conversationId, title, body, route, actorRole, entityType, entityId, moduleType, dedupeKey, audience, }) {
    return createBackendNotification({
        userId,
        type: client_1.NotificationType.SYSTEM,
        module: client_1.NotificationModule.MESSAGES,
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
async function createOrderCreatedNotification({ userId, orderId, moduleType, moduleName, }) {
    const customerNotification = await buildCustomerOrderNotification({
        userId,
        orderId,
        moduleType,
        moduleName,
    });
    // Doctor and ride orders have dedicated creation helpers that fan out to
    // the super admin themselves — skip to avoid duplicate admin alerts.
    if (moduleType !== client_1.ModuleType.DOCTOR && moduleType !== client_1.ModuleType.RIDE) {
        const detailName = moduleName?.trim() ?? '';
        const label = orderModuleLabel(moduleType);
        const actor = (await actorEmailFor(userId)) ?? 'A customer';
        const isBooking = moduleType === client_1.ModuleType.HOTEL ||
            moduleType === client_1.ModuleType.HOME_SERVICES ||
            moduleType === client_1.ModuleType.HOUSE_HELP;
        await notifySuperAdmins({
            title: isBooking
                ? moduleType === client_1.ModuleType.HOTEL
                    ? 'New hotel booking'
                    : 'New service booking'
                : `New ${label} order`,
            body: detailName.length > 0
                ? `${actor} placed an order at ${detailName}.`
                : `${actor} placed a new ${label} ${isBooking ? 'booking' : 'order'}.`,
            module: client_1.NotificationModule.ORDERS,
            type: client_1.NotificationType.ORDER,
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
async function buildCustomerOrderNotification({ userId, orderId, moduleType, moduleName, }) {
    const detailName = moduleName?.trim() ?? '';
    switch (moduleType) {
        case client_1.ModuleType.FOOD:
            return createBackendNotification({
                userId,
                type: client_1.NotificationType.ORDER,
                module: client_1.NotificationModule.FOOD,
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
        case client_1.ModuleType.HOTEL:
            return createBackendNotification({
                userId,
                type: client_1.NotificationType.ORDER,
                module: client_1.NotificationModule.HOTEL,
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
        case client_1.ModuleType.HOME_SERVICES:
            return createBackendNotification({
                userId,
                type: client_1.NotificationType.SYSTEM,
                module: client_1.NotificationModule.HOME_SERVICES,
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
        case client_1.ModuleType.HOUSE_HELP:
            return createBackendNotification({
                userId,
                type: client_1.NotificationType.SYSTEM,
                module: client_1.NotificationModule.HOME_SERVICES,
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
        case client_1.ModuleType.LAUNDRY:
            return createBackendNotification({
                userId,
                type: client_1.NotificationType.LAUNDRY,
                module: client_1.NotificationModule.LAUNDRY,
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
        case client_1.ModuleType.SHOPPING:
            return createBackendNotification({
                userId,
                type: client_1.NotificationType.ORDER,
                module: client_1.NotificationModule.SHOPPING,
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
        case client_1.ModuleType.GROCERY:
            return createBackendNotification({
                userId,
                type: client_1.NotificationType.ORDER,
                module: client_1.NotificationModule.GROCERY,
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
        case client_1.ModuleType.PHARMACY:
            return createBackendNotification({
                userId,
                type: client_1.NotificationType.ORDER,
                module: client_1.NotificationModule.PHARMACY,
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
        case client_1.ModuleType.DOCTOR:
        case client_1.ModuleType.RIDE:
            return null;
    }
}
async function createAppointmentCreatedNotification({ userId, appointmentId, doctorName, timeSlot, }) {
    const actor = (await actorEmailFor(userId)) ?? 'A customer';
    await notifySuperAdmins({
        title: 'New appointment booked',
        body: `${actor} booked an appointment with ${doctorName} at ${timeSlot}.`,
        module: client_1.NotificationModule.DOCTOR,
        type: client_1.NotificationType.APPOINTMENT,
        route: '/pro/admin/appointments',
        dedupeKey: `appointment-created:${appointmentId}`,
        metadata: { appointmentId, doctorName, timeSlot, userId },
    });
    return createBackendNotification({
        userId,
        type: client_1.NotificationType.APPOINTMENT,
        module: client_1.NotificationModule.DOCTOR,
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
async function createRideCreatedNotification({ userId, rideId, vehicleName, pickupLabel, }) {
    const actor = (await actorEmailFor(userId)) ?? 'A customer';
    await notifySuperAdmins({
        title: 'New ride requested',
        body: pickupLabel.length > 0
            ? `${actor} requested a ride (pickup: ${pickupLabel}).`
            : `${actor} requested a new ride.`,
        module: client_1.NotificationModule.RIDE,
        type: client_1.NotificationType.RIDE,
        route: '/pro/admin/rides',
        dedupeKey: `ride-created:${rideId}`,
        metadata: { rideId, vehicleName, pickupLabel, userId },
    });
    return createBackendNotification({
        userId,
        type: client_1.NotificationType.RIDE,
        module: client_1.NotificationModule.RIDE,
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
