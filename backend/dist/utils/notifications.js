"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createBackendNotification = createBackendNotification;
exports.createMessageNotification = createMessageNotification;
exports.createOrderCreatedNotification = createOrderCreatedNotification;
exports.createAppointmentCreatedNotification = createAppointmentCreatedNotification;
exports.createRideCreatedNotification = createRideCreatedNotification;
const client_1 = require("@prisma/client");
const db_1 = require("../db");
const push_1 = require("./push");
async function createBackendNotification({ userId, type, module, title, body, route, dedupeKey, metadata, priority = client_1.NotificationPriority.HIGH, }) {
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
async function createMessageNotification({ userId, conversationId, title, body, route, actorRole, entityType, entityId, moduleType, dedupeKey, }) {
    return createBackendNotification({
        userId,
        type: client_1.NotificationType.SYSTEM,
        module: client_1.NotificationModule.MESSAGES,
        title,
        body,
        route,
        dedupeKey,
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
