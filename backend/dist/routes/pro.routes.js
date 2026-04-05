"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.resolveBindings = resolveBindings;
exports.syncLaundryOwnership = syncLaundryOwnership;
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const serializers_1 = require("../utils/serializers");
const router = (0, express_1.Router)();
const proProfileSchema = zod_1.z.object({
    userId: zod_1.z.string().min(1),
    type: zod_1.z.nativeEnum(client_1.ProProfileType),
    activeModules: zod_1.z.array(zod_1.z.nativeEnum(client_1.ProModule)).min(1),
    businessName: zod_1.z.string().trim().min(2),
    avatarUrl: zod_1.z.string().trim().optional().nullable(),
    isOnline: zod_1.z.boolean().optional(),
    isVerified: zod_1.z.boolean().optional(),
});
const claimDeliverySchema = zod_1.z.object({
    orderId: zod_1.z.string().min(1),
});
const claimRideSchema = zod_1.z.object({
    rideId: zod_1.z.string().min(1),
});
const updateDeliveryStatusSchema = zod_1.z.object({
    orderId: zod_1.z.string().min(1),
    status: zod_1.z.nativeEnum(client_1.OrderStatus),
});
const updateRideStatusSchema = zod_1.z.object({
    rideId: zod_1.z.string().min(1),
    status: zod_1.z.nativeEnum(client_1.RideStatus),
});
const updateShopOrderStatusSchema = zod_1.z.object({
    orderId: zod_1.z.string().min(1),
    status: zod_1.z.nativeEnum(client_1.OrderStatus),
});
const updateProviderOrderStatusSchema = zod_1.z.object({
    orderId: zod_1.z.string().min(1),
    status: zod_1.z.nativeEnum(client_1.OrderStatus),
});
const updateDoctorAppointmentStatusSchema = zod_1.z.object({
    appointmentId: zod_1.z.string().min(1),
    status: zod_1.z.nativeEnum(client_1.AppointmentStatus),
});
const updateOnlineStatusSchema = zod_1.z.object({
    isOnline: zod_1.z.boolean(),
});
const updateShopAvailabilitySchema = zod_1.z.object({
    module: zod_1.z.enum(['shopping', 'food', 'pharmacy']),
    targetId: zod_1.z.string().min(1),
    enabled: zod_1.z.boolean(),
});
const updateProviderAvailabilitySchema = zod_1.z.object({
    module: zod_1.z.enum(['services', 'laundry']),
    targetId: zod_1.z.string().min(1),
    enabled: zod_1.z.boolean(),
});
const updateDoctorAvailabilitySchema = zod_1.z.object({
    doctorId: zod_1.z.string().min(1),
    enabled: zod_1.z.boolean(),
});
const hoursSchema = zod_1.z.object({
    weekdays: zod_1.z.string().trim().max(120),
    saturday: zod_1.z.string().trim().max(120),
    sunday: zod_1.z.string().trim().max(120),
});
const settingsModesSchema = zod_1.z.array(zod_1.z.string().trim().min(1).max(40)).max(8);
const updateProviderSettingsSchema = zod_1.z.object({
    providerId: zod_1.z.string().min(1),
    location: zod_1.z.string().trim().max(120).optional(),
    contactPhone: zod_1.z.string().trim().max(40).optional(),
    responseTime: zod_1.z.string().trim().max(60).optional(),
    bookingModes: settingsModesSchema.optional(),
    availability: hoursSchema.optional(),
});
const updateDoctorSettingsSchema = zod_1.z.object({
    doctorId: zod_1.z.string().min(1),
    location: zod_1.z.string().trim().max(120).optional(),
    contactPhone: zod_1.z.string().trim().max(40).optional(),
    contactWhatsApp: zod_1.z.string().trim().max(40).optional(),
    careModes: settingsModesSchema.optional(),
    workingHours: hoursSchema.optional(),
});
function serializeProProfile(profile) {
    return {
        id: profile.id,
        userId: profile.userId,
        type: profile.type.toLowerCase(),
        activeModules: profile.activeModules.map((module) => module.toLowerCase()),
        businessName: profile.businessName,
        avatarUrl: profile.avatarUrl,
        bindings: normalizeBindings(profile.bindings),
        isOnline: profile.isOnline,
        isVerified: profile.isVerified,
        createdAt: profile.createdAt,
        updatedAt: profile.updatedAt,
    };
}
const liveOrderStatuses = [
    client_1.OrderStatus.PENDING,
    client_1.OrderStatus.CONFIRMED,
    client_1.OrderStatus.PROCESSING,
    client_1.OrderStatus.DISPATCHED,
    client_1.OrderStatus.IN_PROGRESS,
];
function startOfToday() {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}
function formatCurrency(value) {
    return `\$${(value ?? 0).toFixed(2)}`;
}
function formatModule(value) {
    return value
        .toLowerCase()
        .split('_')
        .map((part) => part[0].toUpperCase() + part.slice(1))
        .join(' ');
}
function isPresent(value) {
    return value != null;
}
function normalizeText(value) {
    return value
        .toLowerCase()
        .replace(/[^a-z0-9\s]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}
function matchesBusinessName(query, candidate) {
    const left = normalizeText(query);
    const right = normalizeText(candidate);
    if (!left || !right)
        return false;
    if (left === right)
        return true;
    if (left.includes(right) || right.includes(left))
        return true;
    const leftTokens = left.split(' ').filter((token) => token.length >= 3);
    if (leftTokens.length === 0)
        return false;
    return leftTokens.every((token) => right.includes(token));
}
function normalizeBindings(value) {
    const map = value != null && typeof value === 'object'
        ? value
        : {};
    const finalStringList = (key) => {
        const raw = map[key];
        if (!Array.isArray(raw))
            return [];
        return raw.map((entry) => entry.toString());
    };
    return {
        shoppingStoreIds: finalStringList('shoppingStoreIds'),
        restaurantIds: finalStringList('restaurantIds'),
        restaurantNames: finalStringList('restaurantNames'),
        pharmacyBusinesses: finalStringList('pharmacyBusinesses'),
        providerIds: finalStringList('providerIds'),
        doctorIds: finalStringList('doctorIds'),
        laundryServiceIds: finalStringList('laundryServiceIds'),
    };
}
function normalizeStringList(value) {
    if (!Array.isArray(value)) {
        return [];
    }
    return Array.from(new Set(value
        .map((entry) => entry?.toString().trim() ?? '')
        .filter((entry) => entry.isNotEmpty)));
}
function normalizeHours(value, defaults) {
    const map = value != null && typeof value === 'object' && !Array.isArray(value)
        ? value
        : {};
    return {
        weekdays: map.weekdays?.toString().trim() || defaults.weekdays,
        saturday: map.saturday?.toString().trim() || defaults.saturday,
        sunday: map.sunday?.toString().trim() || defaults.sunday,
    };
}
function hasShopOrderAccess(bindings, order) {
    switch (order.moduleType) {
        case client_1.ModuleType.SHOPPING:
            return (bindings.shoppingStoreIds.length > 0 &&
                order.items.some((item) => item.product?.shopId != null
                    ? bindings.shoppingStoreIds.includes(item.product.shopId)
                    : false));
        case client_1.ModuleType.FOOD:
            return (bindings.restaurantNames.length > 0 &&
                order.items.some((item) => item.brand != null ? bindings.restaurantNames.includes(item.brand) : false));
        case client_1.ModuleType.PHARMACY:
            return (bindings.pharmacyBusinesses.length > 0 &&
                order.items.some((item) => {
                    const metadata = item.product?.metadata &&
                        typeof item.product.metadata === 'object' &&
                        !Array.isArray(item.product.metadata)
                        ? item.product.metadata
                        : null;
                    const sourceBusiness = metadata?.sourceBusiness?.toString();
                    return (sourceBusiness != null &&
                        bindings.pharmacyBusinesses.includes(sourceBusiness));
                }));
        default:
            return false;
    }
}
function hasProviderOrderAccess(bindings, order) {
    switch (order.moduleType) {
        case client_1.ModuleType.HOME_SERVICES:
            return (bindings.providerIds.length > 0 &&
                order.items.some((item) => item.externalRefId != null
                    ? bindings.providerIds.includes(item.externalRefId)
                    : false));
        case client_1.ModuleType.LAUNDRY:
            return (bindings.laundryServiceIds.length > 0 &&
                order.items.some((item) => item.externalRefId != null
                    ? bindings.laundryServiceIds.includes(item.externalRefId)
                    : false));
        default:
            return false;
    }
}
function customerName(user) {
    return `${user.firstName} ${user.lastName}`.trim();
}
function orderAddressLabel(order, firstItemMetadata) {
    const metadata = order.metadata && typeof order.metadata === 'object' && !Array.isArray(order.metadata)
        ? order.metadata
        : null;
    const itemMetadata = firstItemMetadata &&
        typeof firstItemMetadata === 'object' &&
        !Array.isArray(firstItemMetadata)
        ? firstItemMetadata
        : null;
    return (itemMetadata?.address?.toString() ??
        metadata?.address?.toString() ??
        order.address?.line1 ??
        '');
}
function serializeQueueOrderItem(order) {
    const totalItems = order.items.reduce((sum, item) => sum + item.quantity, 0);
    const firstItem = order.items[0];
    return {
        id: order.id,
        module: order.moduleType.toLowerCase(),
        status: order.status,
        title: `${formatModule(order.moduleType)} #${order.id.slice(-5)}`,
        subtitle: `${totalItems} item${totalItems == 1 ? '' : 's'} • ${firstItem?.brand ?? firstItem?.name ?? formatModule(order.moduleType)}`,
        amount: formatCurrency(typeof order.total === 'number'
            ? order.total
            : Number(order.total.toString())),
        customerName: customerName(order.user),
        customerPhone: order.user.phone,
        notes: order.notes,
        address: orderAddressLabel(order, firstItem?.metadata),
        createdAt: order.createdAt,
        customerUserId: order.userId,
    };
}
function serializeQueueAppointmentItem(appointment) {
    return {
        id: appointment.id,
        module: 'doctor',
        status: appointment.status,
        title: customerName(appointment.user),
        subtitle: `${appointment.timeSlot} • ${appointment.appointmentType}`,
        doctorName: appointment.doctor.name,
        customerPhone: appointment.user.phone,
        notes: appointment.notes,
        appointmentAt: appointment.appointmentAt,
        customerUserId: appointment.userId,
    };
}
function serializeDispatchQueueOrderItem(order, currentUserId) {
    const totalItems = order.items.reduce((sum, item) => sum + item.quantity, 0);
    const firstItem = order.items[0];
    return {
        id: order.id,
        module: order.moduleType.toLowerCase(),
        status: order.status,
        title: `${formatModule(order.moduleType)} #${order.id.slice(-5)}`,
        subtitle: `${totalItems} item${totalItems == 1 ? '' : 's'} • ${firstItem?.brand ?? firstItem?.name ?? formatModule(order.moduleType)}`,
        amount: formatCurrency(typeof order.total === 'number'
            ? order.total
            : Number(order.total.toString())),
        customerName: customerName(order.user),
        customerPhone: order.user.phone,
        address: order.address?.line1 ?? '',
        queueType: order.deliveryUserId == currentUserId ? 'assigned' : 'open',
        createdAt: order.createdAt,
        customerUserId: order.userId,
    };
}
function serializeRideQueueItem(ride, currentUserId) {
    const fare = ride.estimatedFare == null
        ? ''
        : formatCurrency(typeof ride.estimatedFare === 'number'
            ? ride.estimatedFare
            : Number(ride.estimatedFare.toString()));
    return {
        id: ride.id,
        module: 'ride',
        status: ride.status,
        title: `${ride.rideCategory.name} Ride`,
        subtitle: `${ride.pickupLabel ?? 'Pickup pending'} -> ${ride.dropoffLabel ?? 'Dropoff pending'}`,
        amount: fare,
        customerName: customerName(ride.user),
        customerPhone: ride.user.phone,
        queueType: ride.driverUserId == currentUserId ? 'assigned' : 'open',
        createdAt: ride.createdAt,
        customerUserId: ride.userId,
    };
}
async function resolveBindings(businessName, activeModules) {
    const bindings = {
        shoppingStoreIds: [],
        restaurantIds: [],
        restaurantNames: [],
        pharmacyBusinesses: [],
        providerIds: [],
        doctorIds: [],
        laundryServiceIds: [],
    };
    const needsShopping = activeModules.includes(client_1.ProModule.SHOPPING) ||
        activeModules.includes(client_1.ProModule.PHARMACY);
    const needsFood = activeModules.includes(client_1.ProModule.FOOD);
    const needsDoctor = activeModules.includes(client_1.ProModule.DOCTOR);
    const needsServices = activeModules.includes(client_1.ProModule.SERVICES);
    const needsLaundry = activeModules.includes(client_1.ProModule.LAUNDRY);
    const [stores, restaurants, doctors, providers, pharmacyProducts, laundryServices] = await Promise.all([
        needsShopping
            ? db_1.prisma.shoppingStore.findMany({
                select: { id: true, name: true },
            })
            : Promise.resolve([]),
        needsFood
            ? db_1.prisma.restaurant.findMany({
                select: { id: true, name: true },
            })
            : Promise.resolve([]),
        needsDoctor
            ? db_1.prisma.doctor.findMany({
                select: { id: true, name: true },
            })
            : Promise.resolve([]),
        needsServices
            ? db_1.prisma.homeServiceProvider.findMany({
                select: { id: true, name: true },
            })
            : Promise.resolve([]),
        activeModules.includes(client_1.ProModule.PHARMACY)
            ? db_1.prisma.product.findMany({
                where: { moduleType: client_1.ModuleType.PHARMACY },
                select: { metadata: true },
            })
            : Promise.resolve([]),
        needsLaundry
            ? db_1.prisma.laundryService.findMany({
                select: { id: true, name: true },
            })
            : Promise.resolve([]),
    ]);
    bindings.shoppingStoreIds = stores
        .filter((store) => matchesBusinessName(businessName, store.name))
        .map((store) => store.id);
    const matchedRestaurants = restaurants.filter((restaurant) => matchesBusinessName(businessName, restaurant.name));
    bindings.restaurantIds = matchedRestaurants.map((restaurant) => restaurant.id);
    bindings.restaurantNames = matchedRestaurants.map((restaurant) => restaurant.name);
    bindings.doctorIds = doctors
        .filter((doctor) => matchesBusinessName(businessName, doctor.name))
        .map((doctor) => doctor.id);
    bindings.providerIds = providers
        .filter((provider) => matchesBusinessName(businessName, provider.name))
        .map((provider) => provider.id);
    bindings.laundryServiceIds = laundryServices
        .filter((service) => matchesBusinessName(businessName, service.name))
        .map((service) => service.id);
    const pharmacyBusinesses = new Set();
    for (const product of pharmacyProducts) {
        const metadata = product.metadata && typeof product.metadata === 'object'
            ? product.metadata
            : null;
        const sourceBusiness = metadata?.sourceBusiness?.toString();
        if (sourceBusiness != null &&
            matchesBusinessName(businessName, sourceBusiness)) {
            pharmacyBusinesses.add(sourceBusiness);
        }
    }
    bindings.pharmacyBusinesses = Array.from(pharmacyBusinesses);
    return bindings;
}
async function syncLaundryOwnership(userId, type, activeModules, bindings) {
    const ownsLaundry = type === client_1.ProProfileType.PROVIDER &&
        activeModules.includes(client_1.ProModule.LAUNDRY);
    if (!ownsLaundry) {
        await db_1.prisma.laundryService.updateMany({
            where: { providerUserId: userId },
            data: { providerUserId: null },
        });
        return [];
    }
    await db_1.prisma.laundryService.updateMany({
        where: {
            providerUserId: userId,
            ...(bindings.laundryServiceIds.length === 0
                ? {}
                : { id: { notIn: bindings.laundryServiceIds } }),
        },
        data: { providerUserId: null },
    });
    if (bindings.laundryServiceIds.length > 0) {
        await db_1.prisma.laundryService.updateMany({
            where: {
                id: { in: bindings.laundryServiceIds },
                OR: [{ providerUserId: null }, { providerUserId: userId }],
            },
            data: { providerUserId: userId },
        });
    }
    const ownedServices = await db_1.prisma.laundryService.findMany({
        where: { providerUserId: userId },
        select: { id: true },
    });
    return ownedServices.map((service) => service.id);
}
async function hydrateProfileBindingsIfMissing(profile) {
    const bindings = normalizeBindings(profile.bindings);
    const hasBindings = bindings.shoppingStoreIds.length > 0 ||
        bindings.restaurantIds.length > 0 ||
        bindings.restaurantNames.length > 0 ||
        bindings.pharmacyBusinesses.length > 0 ||
        bindings.providerIds.length > 0 ||
        bindings.doctorIds.length > 0 ||
        bindings.laundryServiceIds.length > 0;
    if (hasBindings) {
        return profile;
    }
    const resolvedBindings = await resolveBindings(profile.businessName, profile.activeModules);
    const ownedLaundryServiceIds = await syncLaundryOwnership(profile.userId, profile.type, profile.activeModules, resolvedBindings);
    return db_1.prisma.proProfile.update({
        where: { id: profile.id },
        data: {
            bindings: {
                ...resolvedBindings,
                laundryServiceIds: ownedLaundryServiceIds,
            },
        },
    });
}
function emptyShopSummary(module, title, actionLabel, businessName) {
    return {
        module,
        title,
        subtitle: businessName != null && businessName.trim().length > 0
            ? `No matching business is currently bound for "${businessName}". Update the pro profile business name to match the real store, restaurant, or pharmacy listing.`
            : 'No business is currently bound to this module yet.',
        metrics: [
            '0 active business units',
            '0 pending orders',
            '0 published items',
            '0 completed today',
        ],
        recentItems: [],
        actionLabel,
    };
}
function deliveryModuleTypeForProfileModule(module) {
    switch (module) {
        case client_1.ProModule.SHOPPING_DELIVERY:
            return client_1.ModuleType.SHOPPING;
        case client_1.ProModule.FOOD_DELIVERY:
            return client_1.ModuleType.FOOD;
        case client_1.ProModule.PHARMACY_DELIVERY:
            return client_1.ModuleType.PHARMACY;
        default:
            return null;
    }
}
function highlightFromItem(item, module, ctaLabel) {
    if (item == null)
        return null;
    return {
        requestId: item.id,
        module,
        title: item.title,
        amount: item.amount,
        lines: [item.subtitle, item.status, item.meta ?? ''],
        ctaLabel,
    };
}
function orderRecentItems(orders, label) {
    return orders.map((order) => {
        const itemCount = order.items.reduce((sum, item) => sum + item.quantity, 0);
        const firstItem = order.items[0];
        const amount = typeof order.total === 'number'
            ? order.total
            : Number(order.total?.toString?.() ?? 0);
        return {
            id: order.id,
            title: `${label} #${order.id.slice(-5)}`,
            subtitle: `${itemCount} item${itemCount == 1 ? '' : 's'} • ${firstItem?.brand ?? firstItem?.name ?? label}`,
            status: order.status,
            amount: formatCurrency(amount),
            meta: order.createdAt.toISOString(),
        };
    });
}
async function buildShoppingSummary(todayStart, bindings, businessName) {
    if (bindings.shoppingStoreIds.length === 0) {
        return emptyShopSummary('shopping', 'Shopping Store', 'Review Store Binding', businessName);
    }
    const orderWhere = {
        moduleType: client_1.ModuleType.SHOPPING,
        items: {
            some: {
                product: {
                    shopId: { in: bindings.shoppingStoreIds },
                },
            },
        },
    };
    const [productCount, outOfStockCount, pendingOrders, completedToday, recent] = await Promise.all([
        db_1.prisma.product.count({
            where: {
                moduleType: client_1.ModuleType.SHOPPING,
                shopId: { in: bindings.shoppingStoreIds },
            },
        }),
        db_1.prisma.product.count({
            where: {
                moduleType: client_1.ModuleType.SHOPPING,
                inStock: false,
                shopId: { in: bindings.shoppingStoreIds },
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...orderWhere,
                status: { in: liveOrderStatuses },
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...orderWhere,
                status: client_1.OrderStatus.COMPLETED,
                updatedAt: { gte: todayStart },
            },
        }),
        db_1.prisma.order.findMany({
            where: orderWhere,
            include: { items: true },
            orderBy: { createdAt: 'desc' },
            take: 3,
        }),
    ]);
    return {
        module: 'shopping',
        title: 'Shopping Store',
        subtitle: 'Live shopping catalog and order activity for your bound stores.',
        metrics: [
            `${productCount} shopping items live`,
            `${pendingOrders} pending shopping orders`,
            `${outOfStockCount} items out of stock`,
            `${completedToday} orders completed today`,
        ],
        recentItems: orderRecentItems(recent, 'Order'),
        actionLabel: 'Review Stock',
    };
}
async function buildFoodSummary(todayStart, bindings, businessName) {
    if (bindings.restaurantIds.length === 0 || bindings.restaurantNames.length === 0) {
        return emptyShopSummary('food', 'Food Store', 'Review Restaurant Binding', businessName);
    }
    const orderWhere = {
        moduleType: client_1.ModuleType.FOOD,
        items: {
            some: {
                brand: { in: bindings.restaurantNames },
            },
        },
    };
    const [restaurantCount, menuCount, pendingOrders, completedToday, recent] = await Promise.all([
        db_1.prisma.restaurant.count({
            where: {
                isOpen: true,
                id: { in: bindings.restaurantIds },
            },
        }),
        db_1.prisma.restaurantMenuItem.count({
            where: {
                isAvailable: true,
                category: { restaurantId: { in: bindings.restaurantIds } },
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...orderWhere,
                status: { in: liveOrderStatuses },
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...orderWhere,
                status: client_1.OrderStatus.COMPLETED,
                updatedAt: { gte: todayStart },
            },
        }),
        db_1.prisma.order.findMany({
            where: orderWhere,
            include: { items: true },
            orderBy: { createdAt: 'desc' },
            take: 3,
        }),
    ]);
    return {
        module: 'food',
        title: 'Food Store',
        subtitle: 'Restaurant orders and menu operations for your bound restaurants.',
        metrics: [
            `${restaurantCount} open restaurants`,
            `${menuCount} available dishes`,
            `${pendingOrders} food orders in progress`,
            `${completedToday} food orders completed today`,
        ],
        recentItems: orderRecentItems(recent, 'Food'),
        actionLabel: 'Open Kitchen Queue',
    };
}
async function buildPharmacySummary(todayStart, bindings, businessName) {
    if (bindings.pharmacyBusinesses.length === 0) {
        return emptyShopSummary('pharmacy', 'Pharmacy Store', 'Review Pharmacy Binding', businessName);
    }
    const allProducts = await db_1.prisma.product.findMany({
        where: { moduleType: client_1.ModuleType.PHARMACY },
        select: {
            id: true,
            requiresPrescription: true,
            metadata: true,
            inStock: true,
        },
    });
    const filteredProducts = allProducts.filter((product) => {
        const metadata = product.metadata && typeof product.metadata === 'object'
            ? product.metadata
            : null;
        const sourceBusiness = metadata?.sourceBusiness?.toString();
        return (sourceBusiness != null &&
            bindings.pharmacyBusinesses.includes(sourceBusiness));
    });
    const productIds = filteredProducts.map((product) => product.id);
    const [pendingOrders, completedToday, recent] = await Promise.all([
        db_1.prisma.order.count({
            where: {
                moduleType: client_1.ModuleType.PHARMACY,
                items: {
                    some: {
                        productId: { in: productIds },
                    },
                },
                status: { in: liveOrderStatuses },
            },
        }),
        db_1.prisma.order.count({
            where: {
                moduleType: client_1.ModuleType.PHARMACY,
                items: {
                    some: {
                        productId: { in: productIds },
                    },
                },
                status: client_1.OrderStatus.COMPLETED,
                updatedAt: { gte: todayStart },
            },
        }),
        db_1.prisma.order.findMany({
            where: {
                moduleType: client_1.ModuleType.PHARMACY,
                items: {
                    some: {
                        productId: { in: productIds },
                    },
                },
            },
            include: { items: true },
            orderBy: { createdAt: 'desc' },
            take: 3,
        }),
    ]);
    const medicineCount = filteredProducts.length;
    const prescriptionItems = filteredProducts.filter((product) => product.requiresPrescription).length;
    return {
        module: 'pharmacy',
        title: 'Pharmacy Store',
        subtitle: 'Medicine catalog and pharmacy order activity for your bound pharmacies.',
        metrics: [
            `${medicineCount} medicines listed`,
            `${prescriptionItems} prescription-only items`,
            `${pendingOrders} pharmacy orders in progress`,
            `${completedToday} pharmacy orders completed today`,
        ],
        recentItems: orderRecentItems(recent, 'Pharmacy'),
        actionLabel: 'Review Orders',
    };
}
async function buildServicesSummary(todayStart, bindings) {
    const orderWhere = bindings.providerIds.length === 0
        ? { moduleType: client_1.ModuleType.HOME_SERVICES }
        : {
            moduleType: client_1.ModuleType.HOME_SERVICES,
            items: {
                some: {
                    externalRefId: { in: bindings.providerIds },
                },
            },
        };
    const [providerCount, availableCount, pendingOrders, completedToday, recent] = await Promise.all([
        db_1.prisma.homeServiceProvider.count({
            where: bindings.providerIds.length === 0
                ? {}
                : { id: { in: bindings.providerIds } },
        }),
        db_1.prisma.homeServiceProvider.count({
            where: {
                isAvailable: true,
                ...(bindings.providerIds.length === 0
                    ? {}
                    : { id: { in: bindings.providerIds } }),
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...orderWhere,
                status: { in: liveOrderStatuses },
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...orderWhere,
                status: client_1.OrderStatus.COMPLETED,
                updatedAt: { gte: todayStart },
            },
        }),
        db_1.prisma.order.findMany({
            where: orderWhere,
            include: { items: true },
            orderBy: { createdAt: 'desc' },
            take: 3,
        }),
    ]);
    return {
        module: 'services',
        title: 'Home Services',
        subtitle: bindings.providerIds.length === 0
            ? 'Service bookings and provider operations across the platform.'
            : 'Service bookings and provider operations for bound providers.',
        metrics: [
            `${providerCount} service providers on platform`,
            `${availableCount} providers available now`,
            `${pendingOrders} active service bookings`,
            `${completedToday} bookings completed today`,
        ],
        recentItems: orderRecentItems(recent, 'Service'),
        actionLabel: 'Start Job',
    };
}
async function buildLaundrySummary(todayStart, bindings) {
    const orderWhere = bindings.laundryServiceIds.length === 0
        ? { moduleType: client_1.ModuleType.LAUNDRY }
        : {
            moduleType: client_1.ModuleType.LAUNDRY,
            items: {
                some: {
                    externalRefId: { in: bindings.laundryServiceIds },
                },
            },
        };
    const [serviceCount, activeOrders, completedToday, recent] = await Promise.all([
        db_1.prisma.laundryService.count({
            where: {
                active: true,
                ...(bindings.laundryServiceIds.length === 0
                    ? {}
                    : { id: { in: bindings.laundryServiceIds } }),
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...orderWhere,
                status: { in: liveOrderStatuses },
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...orderWhere,
                status: client_1.OrderStatus.COMPLETED,
                updatedAt: { gte: todayStart },
            },
        }),
        db_1.prisma.order.findMany({
            where: orderWhere,
            include: { items: true },
            orderBy: { createdAt: 'desc' },
            take: 3,
        }),
    ]);
    return {
        module: 'laundry',
        title: 'Laundry',
        subtitle: bindings.laundryServiceIds.length === 0
            ? 'Laundry pickup, cleaning, and delivery flow across the platform.'
            : 'Laundry pickup, cleaning, and delivery flow for owned laundry services.',
        metrics: [
            `${serviceCount} laundry services available`,
            `${activeOrders} active laundry orders`,
            `${completedToday} laundry orders completed today`,
        ],
        recentItems: recent.map((order) => ({
            id: order.id,
            title: `Laundry #${order.id.slice(-5)}`,
            subtitle: `${order.items.reduce((sum, item) => sum + item.quantity, 0)} items • ${order.items[0]?.name ?? 'Laundry'}`,
            status: order.status,
            amount: formatCurrency((0, serializers_1.toNumber)(order.total)),
            meta: order.createdAt.toISOString(),
        })),
        actionLabel: 'Open Laundry Queue',
    };
}
async function buildDoctorSummary(todayStart, bindings) {
    const [availableDoctors, appointmentsToday, videoToday, recent] = await Promise.all([
        db_1.prisma.doctor.count({
            where: {
                isAvailable: true,
                ...(bindings.doctorIds.length === 0
                    ? {}
                    : { id: { in: bindings.doctorIds } }),
            },
        }),
        db_1.prisma.appointment.count({
            where: {
                appointmentAt: { gte: todayStart },
                ...(bindings.doctorIds.length === 0
                    ? {}
                    : { doctorId: { in: bindings.doctorIds } }),
            },
        }),
        db_1.prisma.appointment.count({
            where: {
                appointmentAt: { gte: todayStart },
                appointmentType: 'video',
                ...(bindings.doctorIds.length === 0
                    ? {}
                    : { doctorId: { in: bindings.doctorIds } }),
            },
        }),
        db_1.prisma.appointment.findMany({
            where: bindings.doctorIds.length === 0
                ? {}
                : { doctorId: { in: bindings.doctorIds } },
            include: { doctor: true },
            orderBy: { appointmentAt: 'asc' },
            take: 4,
        }),
    ]);
    return {
        module: 'doctor',
        title: 'Doctor Practice',
        subtitle: bindings.doctorIds.length === 0
            ? 'Appointments, patient flow, and remote consultations across the platform.'
            : 'Appointments, patient flow, and remote consultations for bound doctors.',
        metrics: [
            `${availableDoctors} available doctors`,
            `${appointmentsToday} appointments scheduled today`,
            `${videoToday} video consultations today`,
        ],
        recentItems: recent.map((appointment) => ({
            id: appointment.id,
            title: appointment.doctor.name,
            subtitle: `${appointment.timeSlot} • ${appointment.appointmentType}`,
            status: appointment.status,
            amount: '',
            meta: appointment.appointmentAt.toISOString(),
        })),
        actionLabel: 'Open Appointments',
    };
}
async function buildDeliverySummary(module, moduleType, title, subtitle, todayStart, userId) {
    const assignedWhere = {
        moduleType,
        deliveryUserId: userId,
    };
    const [activeAssigned, completedToday, recent, openQueue, claimableOrder] = await Promise.all([
        db_1.prisma.order.count({
            where: {
                ...assignedWhere,
                status: { in: liveOrderStatuses },
            },
        }),
        db_1.prisma.order.count({
            where: {
                ...assignedWhere,
                status: client_1.OrderStatus.COMPLETED,
                updatedAt: { gte: todayStart },
            },
        }),
        db_1.prisma.order.findMany({
            where: assignedWhere,
            include: { items: true },
            orderBy: { createdAt: 'desc' },
            take: 3,
        }),
        db_1.prisma.order.count({
            where: {
                moduleType,
                deliveryUserId: null,
                status: { in: liveOrderStatuses },
            },
        }),
        db_1.prisma.order.findFirst({
            where: {
                moduleType,
                deliveryUserId: null,
                status: { in: liveOrderStatuses },
            },
            include: { items: true },
            orderBy: { createdAt: 'asc' },
        }),
    ]);
    return {
        module: module.toLowerCase(),
        title,
        subtitle: `${subtitle} Assigned work is scoped to this courier profile.`,
        metrics: [
            `${activeAssigned} active assigned deliveries`,
            `${completedToday} deliveries completed today`,
            `${openQueue} open requests waiting`,
        ],
        recentItems: orderRecentItems(recent, formatModule(moduleType)),
        actionLabel: 'Accept Delivery',
        highlightedRequest: highlightFromItem(claimableOrder == null
            ? null
            : orderRecentItems([claimableOrder], formatModule(moduleType))[0] ?? null, module.toLowerCase(), 'Accept Delivery'),
    };
}
async function buildRideSummary(todayStart, userId) {
    const activeRideStatuses = [
        client_1.RideStatus.REQUESTED,
        client_1.RideStatus.ACCEPTED,
        client_1.RideStatus.DRIVER_ARRIVING,
        client_1.RideStatus.IN_PROGRESS,
    ];
    const [activeTrips, completedToday, recent, openQueue, claimableRide] = await Promise.all([
        db_1.prisma.rideBooking.count({
            where: {
                driverUserId: userId,
                status: { in: activeRideStatuses },
            },
        }),
        db_1.prisma.rideBooking.count({
            where: {
                driverUserId: userId,
                status: client_1.RideStatus.COMPLETED,
                updatedAt: { gte: todayStart },
            },
        }),
        db_1.prisma.rideBooking.findMany({
            where: { driverUserId: userId },
            include: { rideCategory: true },
            orderBy: { createdAt: 'desc' },
            take: 3,
        }),
        db_1.prisma.rideBooking.count({
            where: {
                driverUserId: null,
                status: client_1.RideStatus.REQUESTED,
            },
        }),
        db_1.prisma.rideBooking.findFirst({
            where: {
                driverUserId: null,
                status: client_1.RideStatus.REQUESTED,
            },
            include: { rideCategory: true },
            orderBy: { createdAt: 'asc' },
        }),
    ]);
    return {
        module: 'ride',
        title: 'Ride Operations',
        subtitle: 'Assigned trips and nearby ride demand for this rider profile.',
        metrics: [
            `${activeTrips} active assigned trips`,
            `${completedToday} rides completed today`,
            `${openQueue} open ride requests`,
        ],
        recentItems: recent.map((ride) => ({
            id: ride.id,
            title: `${ride.rideCategory.name} Ride`,
            subtitle: `${ride.pickupLabel} -> ${ride.dropoffLabel}`,
            status: ride.status,
            amount: formatCurrency((0, serializers_1.toNumber)(ride.total)),
            meta: ride.etaLabel ?? '',
        })),
        actionLabel: 'Accept Ride',
        highlightedRequest: claimableRide == null
            ? null
            : highlightFromItem({
                id: claimableRide.id,
                title: `${claimableRide.rideCategory.name} Ride`,
                subtitle: `${claimableRide.pickupLabel} -> ${claimableRide.dropoffLabel}`,
                status: claimableRide.status,
                amount: formatCurrency((0, serializers_1.toNumber)(claimableRide.total)),
                meta: claimableRide.etaLabel ?? '',
            }, 'ride', 'Accept Ride'),
    };
}
async function buildDashboard(profile) {
    const todayStart = startOfToday();
    const bindings = normalizeBindings(profile.bindings);
    switch (profile.type) {
        case client_1.ProProfileType.SHOP: {
            const summaries = await Promise.all(profile.activeModules.map((module) => {
                switch (module) {
                    case client_1.ProModule.SHOPPING:
                        return buildShoppingSummary(todayStart, bindings, profile.businessName);
                    case client_1.ProModule.FOOD:
                        return buildFoodSummary(todayStart, bindings, profile.businessName);
                    case client_1.ProModule.PHARMACY:
                        return buildPharmacySummary(todayStart, bindings, profile.businessName);
                    default:
                        return Promise.resolve(null);
                }
            }));
            const modules = summaries.filter(isPresent);
            const pendingTotal = modules.reduce((sum, item) => {
                const raw = item.metrics[1]?.split(' ')[0] ?? '0';
                return sum + Number(raw);
            }, 0);
            return {
                headline: 'Store operations',
                scopeNote: 'This workspace is limited to the store, restaurant, and pharmacy businesses bound to this profile. If a module shows no business, update the business name so it matches the real listing.',
                stats: [
                    {
                        key: 'modules',
                        title: 'Live modules',
                        value: `${modules.length}`,
                        trend: 'Enabled for this profile',
                        isUp: true,
                    },
                    {
                        key: 'pending',
                        title: 'Pending orders',
                        value: `${pendingTotal}`,
                    },
                    {
                        key: 'entities',
                        title: 'Workstreams',
                        value: `${modules.length}`,
                    },
                    {
                        key: 'alerts',
                        title: 'Attention items',
                        value: `${modules.length + 2}`,
                    },
                ],
                moduleSummaries: modules,
            };
        }
        case client_1.ProProfileType.PROVIDER: {
            const summaries = await Promise.all(profile.activeModules.map((module) => {
                switch (module) {
                    case client_1.ProModule.SERVICES:
                        return buildServicesSummary(todayStart, bindings);
                    case client_1.ProModule.LAUNDRY:
                        return buildLaundrySummary(todayStart, bindings);
                    default:
                        return Promise.resolve(null);
                }
            }));
            const modules = summaries.filter(isPresent);
            const activeWork = modules.reduce((sum, item) => {
                const raw = item.module === 'services'
                    ? item.metrics[2]?.split(' ')[0]
                    : item.metrics[1]?.split(' ')[0];
                return sum + Number(raw ?? '0');
            }, 0);
            const completedWork = modules.reduce((sum, item) => {
                const raw = item.module === 'services'
                    ? item.metrics[3]?.split(' ')[0]
                    : item.metrics[2]?.split(' ')[0];
                return sum + Number(raw ?? '0');
            }, 0);
            return {
                headline: 'Provider operations',
                scopeNote: 'Services are scoped to bound providers, and laundry now follows explicitly owned laundry services when claimed by this provider profile.',
                stats: [
                    {
                        key: 'jobs',
                        title: 'Upcoming jobs',
                        value: `${activeWork}`,
                    },
                    {
                        key: 'completed',
                        title: 'Completed today',
                        value: `${completedWork}`,
                    },
                    { key: 'teams', title: 'Active pipelines', value: `${modules.length}` },
                    { key: 'ontime', title: 'Service modules', value: `${modules.length}` },
                ],
                moduleSummaries: modules,
            };
        }
        case client_1.ProProfileType.DOCTOR: {
            const summary = await buildDoctorSummary(todayStart, bindings);
            return {
                headline: 'Doctor operations',
                scopeNote: 'Live appointment data is scoped to bound doctors when a match is found, with platform-wide fallback otherwise.',
                stats: [
                    { key: 'patients', title: 'Patients today', value: summary.metrics[1].split(' ')[0] ?? '0' },
                    { key: 'video', title: 'Video queue', value: summary.metrics[2].split(' ')[0] ?? '0' },
                    { key: 'clinic', title: 'Available doctors', value: summary.metrics[0].split(' ')[0] ?? '0' },
                    { key: 'notes', title: 'Upcoming consults', value: `${summary.recentItems.length}` },
                ],
                moduleSummaries: [summary],
            };
        }
        case client_1.ProProfileType.DELIVERY: {
            const summaries = await Promise.all(profile.activeModules.map((module) => {
                switch (module) {
                    case client_1.ProModule.SHOPPING_DELIVERY:
                        return buildDeliverySummary(module, client_1.ModuleType.SHOPPING, 'Shopping Delivery', 'Shopping order dispatch queue.', todayStart, profile.userId);
                    case client_1.ProModule.FOOD_DELIVERY:
                        return buildDeliverySummary(module, client_1.ModuleType.FOOD, 'Food Delivery', 'Food pickup and delivery queue.', todayStart, profile.userId);
                    case client_1.ProModule.PHARMACY_DELIVERY:
                        return buildDeliverySummary(module, client_1.ModuleType.PHARMACY, 'Pharmacy Delivery', 'Pharmacy dispatch queue.', todayStart, profile.userId);
                    default:
                        return Promise.resolve(null);
                }
            }));
            const modules = summaries.filter(isPresent);
            const highlighted = modules.find((module) => module.highlightedRequest != null)
                ?.highlightedRequest ?? null;
            const activeAssigned = modules.reduce((sum, item) => sum + Number(item.metrics[0]?.split(' ')[0] ?? '0'), 0);
            const openQueue = modules.reduce((sum, item) => sum + Number(item.metrics[2]?.split(' ')[0] ?? '0'), 0);
            const completedToday = modules.reduce((sum, item) => sum + Number(item.metrics[1]?.split(' ')[0] ?? '0'), 0);
            return {
                headline: 'Delivery operations',
                scopeNote: 'Assigned delivery work is scoped to this courier profile, with the next available request surfaced for claiming.',
                stats: [
                    { key: 'active', title: 'Active requests', value: `${activeAssigned}` },
                    { key: 'completed', title: 'Completed today', value: `${completedToday}` },
                    { key: 'queue', title: 'Dispatch lanes', value: `${modules.length}` },
                    { key: 'coverage', title: 'Open queue', value: `${openQueue}` },
                ],
                moduleSummaries: modules,
                highlightedRequest: highlighted,
            };
        }
        case client_1.ProProfileType.RIDER: {
            const summary = await buildRideSummary(todayStart, profile.userId);
            return {
                headline: 'Ride operations',
                scopeNote: 'Assigned trips are scoped to this rider profile, with the next open ride request available to claim.',
                stats: [
                    { key: 'earnings_proxy', title: 'Trips today', value: `${summary.recentItems.length}` },
                    { key: 'active', title: 'Active trips', value: summary.metrics[0].split(' ')[0] ?? '0' },
                    { key: 'queue', title: 'Open requests', value: summary.metrics[2].split(' ')[0] ?? '0' },
                    { key: 'completed', title: 'Completed today', value: summary.metrics[1].split(' ')[0] ?? '0' },
                ],
                moduleSummaries: [summary],
                highlightedRequest: summary.highlightedRequest,
            };
        }
    }
}
router.post('/:userId/claim-delivery', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = claimDeliverySchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.DELIVERY) {
        return res.status(404).json({ error: 'Delivery pro profile not found.' });
    }
    if (!profile.isOnline) {
        return res.status(403).json({ error: 'Turn online before claiming deliveries.' });
    }
    const allowedModuleTypes = profile.activeModules
        .map(deliveryModuleTypeForProfileModule)
        .filter(isPresent);
    const order = await db_1.prisma.order.findUnique({
        where: { id: body.orderId },
    });
    const isAllowedModule = order
        ? allowedModuleTypes.some((moduleType) => moduleType === order.moduleType)
        : false;
    if (!order || !isAllowedModule) {
        return res.status(404).json({ error: 'Delivery request not found.' });
    }
    if (order.deliveryUserId && order.deliveryUserId !== userId) {
        return res.status(409).json({ error: 'Delivery request already claimed.' });
    }
    const updatedOrder = await db_1.prisma.order.update({
        where: { id: order.id },
        data: {
            deliveryUserId: userId,
            status: order.status === client_1.OrderStatus.PENDING ||
                order.status === client_1.OrderStatus.CONFIRMED ||
                order.status === client_1.OrderStatus.PROCESSING
                ? client_1.OrderStatus.DISPATCHED
                : order.status,
        },
        include: { items: true },
    });
    res.json({
        id: updatedOrder.id,
        moduleType: updatedOrder.moduleType,
        status: updatedOrder.status,
        deliveryUserId: updatedOrder.deliveryUserId,
    });
}));
router.post('/:userId/claim-ride', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = claimRideSchema.parse(req.body);
    const [profile, user] = await Promise.all([
        db_1.prisma.proProfile.findUnique({
            where: { userId },
        }),
        db_1.prisma.user.findUnique({
            where: { id: userId },
        }),
    ]);
    if (!profile || profile.type !== client_1.ProProfileType.RIDER) {
        return res.status(404).json({ error: 'Rider pro profile not found.' });
    }
    if (!profile.isOnline) {
        return res.status(403).json({ error: 'Turn online before claiming rides.' });
    }
    if (!profile.activeModules.includes(client_1.ProModule.RIDE)) {
        return res.status(400).json({ error: 'Ride module is not enabled for this profile.' });
    }
    const ride = await db_1.prisma.rideBooking.findUnique({
        where: { id: body.rideId },
        include: { rideCategory: true },
    });
    if (!ride) {
        return res.status(404).json({ error: 'Ride request not found.' });
    }
    if (ride.driverUserId && ride.driverUserId !== userId) {
        return res.status(409).json({ error: 'Ride request already claimed.' });
    }
    const driverName = user == null
        ? ride.driverName
        : `${user.firstName} ${user.lastName}`.trim();
    const updatedRide = await db_1.prisma.rideBooking.update({
        where: { id: ride.id },
        data: {
            driverUserId: userId,
            driverName: driverName || ride.driverName,
            driverPhone: user?.phone ?? ride.driverPhone,
            status: ride.status === client_1.RideStatus.REQUESTED ? client_1.RideStatus.ACCEPTED : ride.status,
        },
    });
    res.json({
        id: updatedRide.id,
        status: updatedRide.status,
        driverUserId: updatedRide.driverUserId,
        driverName: updatedRide.driverName,
        driverPhone: updatedRide.driverPhone,
    });
}));
router.post('/:userId/delivery-status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateDeliveryStatusSchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.DELIVERY) {
        return res.status(404).json({ error: 'Delivery pro profile not found.' });
    }
    const order = await db_1.prisma.order.findUnique({
        where: { id: body.orderId },
    });
    if (!order || order.deliveryUserId !== userId) {
        return res.status(404).json({ error: 'Assigned delivery request not found.' });
    }
    const updatedOrder = await db_1.prisma.order.update({
        where: { id: order.id },
        data: { status: body.status },
    });
    res.json({
        id: updatedOrder.id,
        status: updatedOrder.status,
        deliveryUserId: updatedOrder.deliveryUserId,
    });
}));
router.post('/:userId/ride-status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateRideStatusSchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.RIDER) {
        return res.status(404).json({ error: 'Rider pro profile not found.' });
    }
    const ride = await db_1.prisma.rideBooking.findUnique({
        where: { id: body.rideId },
    });
    if (!ride || ride.driverUserId !== userId) {
        return res.status(404).json({ error: 'Assigned ride request not found.' });
    }
    const updatedRide = await db_1.prisma.rideBooking.update({
        where: { id: ride.id },
        data: { status: body.status },
    });
    res.json({
        id: updatedRide.id,
        status: updatedRide.status,
        driverUserId: updatedRide.driverUserId,
    });
}));
router.post('/:userId/shop-order-status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateShopOrderStatusSchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.SHOP) {
        return res.status(404).json({ error: 'Shop pro profile not found.' });
    }
    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const todayStart = startOfToday();
    const order = await db_1.prisma.order.findUnique({
        where: { id: body.orderId },
        include: {
            items: {
                include: {
                    product: {
                        select: {
                            shopId: true,
                            metadata: true,
                        },
                    },
                },
            },
        },
    });
    if (!order) {
        return res.status(404).json({ error: 'Order not found.' });
    }
    if (!hasShopOrderAccess(bindings, order)) {
        return res.status(403).json({ error: 'Order is not assigned to this shop profile.' });
    }
    const updatedOrder = await db_1.prisma.order.update({
        where: { id: order.id },
        data: { status: body.status },
    });
    res.json({
        id: updatedOrder.id,
        status: updatedOrder.status,
        moduleType: updatedOrder.moduleType,
    });
}));
router.post('/:userId/provider-order-status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateProviderOrderStatusSchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.PROVIDER) {
        return res.status(404).json({ error: 'Provider pro profile not found.' });
    }
    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const order = await db_1.prisma.order.findUnique({
        where: { id: body.orderId },
        include: {
            items: {
                select: {
                    externalRefId: true,
                },
            },
        },
    });
    if (!order) {
        return res.status(404).json({ error: 'Order not found.' });
    }
    if (!hasProviderOrderAccess(bindings, order)) {
        return res.status(403).json({ error: 'Order is not assigned to this provider profile.' });
    }
    const updatedOrder = await db_1.prisma.order.update({
        where: { id: order.id },
        data: { status: body.status },
    });
    res.json({
        id: updatedOrder.id,
        status: updatedOrder.status,
        moduleType: updatedOrder.moduleType,
    });
}));
router.post('/:userId/doctor-appointment-status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateDoctorAppointmentStatusSchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.DOCTOR) {
        return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    const appointment = await db_1.prisma.appointment.findUnique({
        where: { id: body.appointmentId },
    });
    if (!appointment) {
        return res.status(404).json({ error: 'Appointment not found.' });
    }
    if (bindings.doctorIds.length === 0 ||
        !bindings.doctorIds.includes(appointment.doctorId)) {
        return res.status(403).json({ error: 'Appointment is not assigned to this doctor profile.' });
    }
    const updatedAppointment = await db_1.prisma.appointment.update({
        where: { id: appointment.id },
        data: { status: body.status },
    });
    res.json({
        id: updatedAppointment.id,
        status: updatedAppointment.status,
        doctorId: updatedAppointment.doctorId,
        appointmentAt: updatedAppointment.appointmentAt,
    });
}));
router.get('/:userId/shop-queue', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.SHOP) {
        return res.status(404).json({ error: 'Shop pro profile not found.' });
    }
    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const [shoppingOrders, foodOrders, pharmacyCandidates] = await Promise.all([
        bindings.shoppingStoreIds.length === 0
            ? Promise.resolve([])
            : db_1.prisma.order.findMany({
                where: {
                    moduleType: client_1.ModuleType.SHOPPING,
                    items: {
                        some: {
                            product: {
                                shopId: { in: bindings.shoppingStoreIds },
                            },
                        },
                    },
                },
                include: {
                    user: {
                        select: { firstName: true, lastName: true, phone: true },
                    },
                    address: { select: { line1: true } },
                    items: {
                        include: {
                            product: {
                                select: { shopId: true, metadata: true },
                            },
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
                take: 100,
            }),
        bindings.restaurantNames.length === 0
            ? Promise.resolve([])
            : db_1.prisma.order.findMany({
                where: {
                    moduleType: client_1.ModuleType.FOOD,
                    items: {
                        some: {
                            brand: { in: bindings.restaurantNames },
                        },
                    },
                },
                include: {
                    user: {
                        select: { firstName: true, lastName: true, phone: true },
                    },
                    address: { select: { line1: true } },
                    items: {
                        include: {
                            product: {
                                select: { shopId: true, metadata: true },
                            },
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
                take: 100,
            }),
        db_1.prisma.order.findMany({
            where: { moduleType: client_1.ModuleType.PHARMACY },
            include: {
                user: {
                    select: { firstName: true, lastName: true, phone: true },
                },
                address: { select: { line1: true } },
                items: {
                    include: {
                        product: {
                            select: { shopId: true, metadata: true },
                        },
                    },
                },
            },
            orderBy: { createdAt: 'desc' },
            take: 100,
        }),
    ]);
    const pharmacyOrders = bindings.pharmacyBusinesses.length === 0
        ? []
        : pharmacyCandidates.filter((order) => order.items.some((item) => {
            const metadata = item.product?.metadata &&
                typeof item.product.metadata === 'object' &&
                !Array.isArray(item.product.metadata)
                ? item.product.metadata
                : null;
            const sourceBusiness = metadata?.sourceBusiness?.toString();
            return (sourceBusiness != null &&
                bindings.pharmacyBusinesses.includes(sourceBusiness));
        }));
    const items = [...shoppingOrders, ...foodOrders, ...pharmacyOrders]
        .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime())
        .map(serializeQueueOrderItem);
    res.json(items);
}));
router.get('/:userId/provider-queue', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.PROVIDER) {
        return res.status(404).json({ error: 'Provider pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    const [serviceOrders, laundryOrders] = await Promise.all([
        db_1.prisma.order.findMany({
            where: bindings.providerIds.length === 0
                ? { moduleType: client_1.ModuleType.HOME_SERVICES }
                : {
                    moduleType: client_1.ModuleType.HOME_SERVICES,
                    items: {
                        some: {
                            externalRefId: { in: bindings.providerIds },
                        },
                    },
                },
            include: {
                user: {
                    select: { firstName: true, lastName: true, phone: true },
                },
                address: { select: { line1: true } },
                items: {
                    include: {
                        product: {
                            select: { shopId: true, metadata: true },
                        },
                    },
                },
            },
            orderBy: { createdAt: 'desc' },
            take: 100,
        }),
        db_1.prisma.order.findMany({
            where: bindings.laundryServiceIds.length === 0
                ? { moduleType: client_1.ModuleType.LAUNDRY }
                : {
                    moduleType: client_1.ModuleType.LAUNDRY,
                    items: {
                        some: {
                            externalRefId: { in: bindings.laundryServiceIds },
                        },
                    },
                },
            include: {
                user: {
                    select: { firstName: true, lastName: true, phone: true },
                },
                address: { select: { line1: true } },
                items: {
                    include: {
                        product: {
                            select: { shopId: true, metadata: true },
                        },
                    },
                },
            },
            orderBy: { createdAt: 'desc' },
            take: 100,
        }),
    ]);
    const items = [...serviceOrders, ...laundryOrders]
        .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime())
        .map(serializeQueueOrderItem);
    res.json(items);
}));
router.get('/:userId/doctor-appointments', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.DOCTOR) {
        return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    const appointments = await db_1.prisma.appointment.findMany({
        where: bindings.doctorIds.length === 0
            ? {}
            : { doctorId: { in: bindings.doctorIds } },
        include: {
            doctor: {
                select: { name: true },
            },
            user: {
                select: { firstName: true, lastName: true, phone: true },
            },
        },
        orderBy: { appointmentAt: 'asc' },
        take: 100,
    });
    res.json(appointments.map(serializeQueueAppointmentItem));
}));
router.get('/:userId/delivery-queue', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.DELIVERY) {
        return res.status(404).json({ error: 'Delivery pro profile not found.' });
    }
    const orders = await db_1.prisma.order.findMany({
        where: {
            moduleType: {
                in: [client_1.ModuleType.SHOPPING, client_1.ModuleType.FOOD, client_1.ModuleType.PHARMACY],
            },
            OR: [{ deliveryUserId: null }, { deliveryUserId: userId }],
        },
        include: {
            user: {
                select: { firstName: true, lastName: true, phone: true },
            },
            address: { select: { line1: true } },
            items: {
                select: {
                    name: true,
                    brand: true,
                    quantity: true,
                    metadata: true,
                },
            },
        },
        orderBy: { createdAt: 'desc' },
        take: 100,
    });
    res.json(orders.map((order) => serializeDispatchQueueOrderItem(order, userId)));
}));
router.get('/:userId/ride-queue', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile || profile.type !== client_1.ProProfileType.RIDER) {
        return res.status(404).json({ error: 'Rider pro profile not found.' });
    }
    const rides = await db_1.prisma.rideBooking.findMany({
        where: {
            OR: [{ driverUserId: null }, { driverUserId: userId }],
        },
        include: {
            user: {
                select: { firstName: true, lastName: true, phone: true },
            },
            rideCategory: {
                select: { name: true },
            },
        },
        orderBy: { createdAt: 'desc' },
        take: 100,
    });
    res.json(rides.map((ride) => serializeRideQueueItem(ride, userId)));
}));
router.get('/:userId/shop-availability', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.SHOP) {
        return res.status(404).json({ error: 'Shop pro profile not found.' });
    }
    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const todayStart = startOfToday();
    const [stores, shoppingProducts, shoppingOrders, restaurants, restaurantMenuItems, foodOrders, allPharmacyProducts,] = await Promise.all([
        bindings.shoppingStoreIds.length === 0
            ? Promise.resolve([])
            : db_1.prisma.shoppingStore.findMany({
                where: { id: { in: bindings.shoppingStoreIds } },
                select: {
                    id: true,
                    slug: true,
                    name: true,
                    tagline: true,
                    imageUrl: true,
                    isOpen: true,
                },
                orderBy: { name: 'asc' },
            }),
        bindings.shoppingStoreIds.length === 0
            ? Promise.resolve([])
            : db_1.prisma.product.findMany({
                where: {
                    moduleType: client_1.ModuleType.SHOPPING,
                    shopId: { in: bindings.shoppingStoreIds },
                },
                select: {
                    id: true,
                    shopId: true,
                    inStock: true,
                },
            }),
        bindings.shoppingStoreIds.length === 0
            ? Promise.resolve([])
            : db_1.prisma.order.findMany({
                where: {
                    moduleType: client_1.ModuleType.SHOPPING,
                    items: {
                        some: {
                            product: {
                                shopId: { in: bindings.shoppingStoreIds },
                            },
                        },
                    },
                },
                select: {
                    status: true,
                    updatedAt: true,
                    items: {
                        select: {
                            product: {
                                select: {
                                    shopId: true,
                                },
                            },
                        },
                    },
                },
            }),
        bindings.restaurantIds.length === 0
            ? Promise.resolve([])
            : db_1.prisma.restaurant.findMany({
                where: { id: { in: bindings.restaurantIds } },
                select: {
                    id: true,
                    name: true,
                    cuisine: true,
                    imageUrl: true,
                    isOpen: true,
                },
                orderBy: { name: 'asc' },
            }),
        bindings.restaurantIds.length === 0
            ? Promise.resolve([])
            : db_1.prisma.restaurantMenuItem.findMany({
                where: {
                    category: {
                        restaurantId: { in: bindings.restaurantIds },
                    },
                },
                select: {
                    id: true,
                    isAvailable: true,
                    category: {
                        select: {
                            restaurantId: true,
                        },
                    },
                },
            }),
        bindings.restaurantNames.length === 0
            ? Promise.resolve([])
            : db_1.prisma.order.findMany({
                where: {
                    moduleType: client_1.ModuleType.FOOD,
                    items: {
                        some: {
                            brand: { in: bindings.restaurantNames },
                        },
                    },
                },
                select: {
                    status: true,
                    updatedAt: true,
                    items: {
                        select: {
                            brand: true,
                        },
                    },
                },
            }),
        db_1.prisma.product.findMany({
            where: { moduleType: client_1.ModuleType.PHARMACY },
            select: {
                id: true,
                name: true,
                inStock: true,
                price: true,
                requiresPrescription: true,
                metadata: true,
                category: {
                    select: {
                        name: true,
                    },
                },
            },
            orderBy: { name: 'asc' },
        }),
    ]);
    const pharmacyItems = bindings.pharmacyBusinesses.length === 0
        ? []
        : allPharmacyProducts.filter((product) => {
            const metadata = product.metadata &&
                typeof product.metadata === 'object' &&
                !Array.isArray(product.metadata)
                ? product.metadata
                : null;
            const sourceBusiness = metadata?.sourceBusiness?.toString();
            return (sourceBusiness != null &&
                bindings.pharmacyBusinesses.includes(sourceBusiness));
        });
    const pharmacyProductIds = pharmacyItems.map((product) => product.id);
    const pharmacyOrders = pharmacyProductIds.length === 0
        ? []
        : await db_1.prisma.order.findMany({
            where: {
                moduleType: client_1.ModuleType.PHARMACY,
                items: {
                    some: {
                        productId: { in: pharmacyProductIds },
                    },
                },
            },
            select: {
                status: true,
                updatedAt: true,
                items: {
                    select: {
                        productId: true,
                    },
                },
            },
        });
    const shoppingProductCountByStore = new Map();
    const shoppingOutOfStockByStore = new Map();
    for (const product of shoppingProducts) {
        if (!product.shopId)
            continue;
        shoppingProductCountByStore.set(product.shopId, (shoppingProductCountByStore.get(product.shopId) ?? 0) + 1);
        if (!product.inStock) {
            shoppingOutOfStockByStore.set(product.shopId, (shoppingOutOfStockByStore.get(product.shopId) ?? 0) + 1);
        }
    }
    const shoppingLiveOrdersByStore = new Map();
    const shoppingCompletedTodayByStore = new Map();
    for (const order of shoppingOrders) {
        const shopIds = new Set(order.items
            .map((item) => item.product?.shopId)
            .filter((value) => Boolean(value)));
        for (const shopId of shopIds) {
            if (liveOrderStatuses.includes(order.status)) {
                shoppingLiveOrdersByStore.set(shopId, (shoppingLiveOrdersByStore.get(shopId) ?? 0) + 1);
            }
            if (order.status === client_1.OrderStatus.COMPLETED &&
                order.updatedAt >= todayStart) {
                shoppingCompletedTodayByStore.set(shopId, (shoppingCompletedTodayByStore.get(shopId) ?? 0) + 1);
            }
        }
    }
    const restaurantMenuCountById = new Map();
    const restaurantUnavailableCountById = new Map();
    for (const item of restaurantMenuItems) {
        const restaurantId = item.category.restaurantId;
        restaurantMenuCountById.set(restaurantId, (restaurantMenuCountById.get(restaurantId) ?? 0) + 1);
        if (!item.isAvailable) {
            restaurantUnavailableCountById.set(restaurantId, (restaurantUnavailableCountById.get(restaurantId) ?? 0) + 1);
        }
    }
    const foodLiveOrdersByRestaurant = new Map();
    const foodCompletedTodayByRestaurant = new Map();
    const restaurantIdByName = new Map(restaurants.map((restaurant) => [restaurant.name, restaurant.id]));
    for (const order of foodOrders) {
        const restaurantIds = new Set(order.items
            .map((item) => item.brand)
            .filter((value) => Boolean(value))
            .map((brand) => restaurantIdByName.get(brand))
            .filter((value) => Boolean(value)));
        for (const restaurantId of restaurantIds) {
            if (liveOrderStatuses.includes(order.status)) {
                foodLiveOrdersByRestaurant.set(restaurantId, (foodLiveOrdersByRestaurant.get(restaurantId) ?? 0) + 1);
            }
            if (order.status === client_1.OrderStatus.COMPLETED &&
                order.updatedAt >= todayStart) {
                foodCompletedTodayByRestaurant.set(restaurantId, (foodCompletedTodayByRestaurant.get(restaurantId) ?? 0) + 1);
            }
        }
    }
    const pharmacyBusinessNames = Array.from(new Set(pharmacyItems
        .map((product) => {
        const metadata = product.metadata &&
            typeof product.metadata === 'object' &&
            !Array.isArray(product.metadata)
            ? product.metadata
            : null;
        return metadata?.sourceBusiness?.toString();
    })
        .filter((value) => Boolean(value))));
    const pharmacyLiveOrderCount = pharmacyOrders.filter((order) => liveOrderStatuses.includes(order.status)).length;
    const pharmacyCompletedTodayCount = pharmacyOrders.filter((order) => order.status === client_1.OrderStatus.COMPLETED && order.updatedAt >= todayStart).length;
    const pharmacyOutOfStockCount = pharmacyItems.filter((product) => !product.inStock).length;
    const pharmacyPrescriptionCount = pharmacyItems.filter((product) => product.requiresPrescription).length;
    const shoppingManagedCount = stores.length;
    const shoppingActiveCount = stores.filter((store) => store.isOpen).length;
    const shoppingLiveListingCount = shoppingProducts.filter((product) => product.inStock).length;
    const shoppingAttentionCount = shoppingProducts.filter((product) => !product.inStock).length;
    const foodManagedCount = restaurants.length;
    const foodActiveCount = restaurants.filter((restaurant) => restaurant.isOpen).length;
    const foodLiveListingCount = restaurantMenuItems.filter((item) => item.isAvailable).length;
    const foodAttentionCount = restaurantMenuItems.filter((item) => !item.isAvailable).length;
    const shoppingOrdersInProgress = Array.from(shoppingLiveOrdersByStore.values()).reduce((sum, count) => sum + count, 0);
    const foodOrdersInProgress = Array.from(foodLiveOrdersByRestaurant.values()).reduce((sum, count) => sum + count, 0);
    res.json({
        shoppingSummary: {
            title: 'Shopping storefront',
            hasBindings: shoppingManagedCount > 0,
            managedCount: shoppingManagedCount,
            subtitle: shoppingManagedCount == 1
                ? '1 retail store connected'
                : `${shoppingManagedCount} retail stores connected`,
            emptyStateMessage: shoppingManagedCount == 0
                ? 'No shopping store is bound to this shop profile yet.'
                : 'Your shopping store is connected, but no storefront records are available right now.',
            metrics: [
                { 'label': 'Open stores', 'value': `${shoppingActiveCount}` },
                { 'label': 'Live listings', 'value': `${shoppingLiveListingCount}` },
                { 'label': 'Need attention', 'value': `${shoppingAttentionCount}` },
                {
                    'label': 'Orders in progress',
                    'value': `${shoppingOrdersInProgress}`,
                },
            ],
        },
        shopping: stores.map((store) => ({
            id: store.id,
            previewId: store.slug,
            name: store.name,
            enabled: store.isOpen,
            subtitle: store.tagline ?? 'Retail storefront',
            detail: '${shoppingProductCountByStore.get(store.id) ?? 0} live items • ${shoppingOutOfStockByStore.get(store.id) ?? 0} out of stock',
            metrics: [
                '${shoppingLiveOrdersByStore.get(store.id) ?? 0} orders in progress',
                '${shoppingCompletedTodayByStore.get(store.id) ?? 0} completed today',
            ],
            imageUrl: store.imageUrl,
        })),
        foodSummary: {
            title: 'Food storefront',
            hasBindings: foodManagedCount > 0,
            managedCount: foodManagedCount,
            subtitle: foodManagedCount == 1
                ? '1 restaurant connected'
                : `${foodManagedCount} restaurants connected`,
            emptyStateMessage: foodManagedCount == 0
                ? 'No restaurant is bound to this shop profile yet.'
                : 'Your restaurant is connected, but no menu records are available right now.',
            metrics: [
                { 'label': 'Open restaurants', 'value': `${foodActiveCount}` },
                { 'label': 'Available dishes', 'value': `${foodLiveListingCount}` },
                { 'label': 'Need attention', 'value': `${foodAttentionCount}` },
                {
                    'label': 'Orders in progress',
                    'value': `${foodOrdersInProgress}`,
                },
            ],
        },
        food: restaurants.map((restaurant) => ({
            id: restaurant.id,
            name: restaurant.name,
            enabled: restaurant.isOpen,
            subtitle: restaurant.cuisine,
            detail: '${restaurantMenuCountById.get(restaurant.id) ?? 0} menu items • ${restaurantUnavailableCountById.get(restaurant.id) ?? 0} unavailable',
            metrics: [
                '${foodLiveOrdersByRestaurant.get(restaurant.id) ?? 0} orders in progress',
                '${foodCompletedTodayByRestaurant.get(restaurant.id) ?? 0} completed today',
            ],
            imageUrl: restaurant.imageUrl,
        })),
        pharmacySummary: {
            title: 'Pharmacy storefront',
            hasBindings: pharmacyBusinessNames.length > 0,
            managedCount: pharmacyBusinessNames.length,
            subtitle: pharmacyBusinessNames.length === 0
                ? 'No pharmacy business connected'
                : pharmacyBusinessNames.length == 1
                    ? '1 pharmacy business connected'
                    : '${pharmacyBusinessNames.length} pharmacy businesses connected',
            emptyStateMessage: pharmacyBusinessNames.length === 0
                ? 'No pharmacy business is bound to this shop profile yet.'
                : 'Your pharmacy is connected, but no medicines are listed yet.',
            metrics: [
                { 'label': 'Listed medicines', 'value': '${pharmacyItems.length}' },
                { 'label': 'Prescription items', 'value': `${pharmacyPrescriptionCount}` },
                { 'label': 'Need attention', 'value': `${pharmacyOutOfStockCount}` },
                { 'label': 'Orders in progress', 'value': `${pharmacyLiveOrderCount}` },
            ],
        },
        pharmacy: pharmacyItems.map((product) => {
            const metadata = product.metadata &&
                typeof product.metadata === 'object' &&
                !Array.isArray(product.metadata)
                ? product.metadata
                : null;
            const sourceBusiness = metadata?.sourceBusiness?.toString() ?? 'Pharmacy';
            return {
                id: product.id,
                name: product.name,
                enabled: product.inStock,
                subtitle: product.category?.name ?? 'Medicine',
                detail: `${formatCurrency((0, serializers_1.toNumber)(product.price))} • ${product.requiresPrescription
                    ? 'Prescription required'
                    : 'Over the counter'}`,
                metrics: [
                    sourceBusiness,
                    '$pharmacyCompletedTodayCount completed today',
                ],
            };
        }),
    });
}));
router.post('/:userId/shop-availability', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateShopAvailabilitySchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.SHOP) {
        return res.status(404).json({ error: 'Shop pro profile not found.' });
    }
    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    if (body.module === 'shopping') {
        if (bindings.shoppingStoreIds.length === 0 ||
            !bindings.shoppingStoreIds.includes(body.targetId)) {
            return res.status(403).json({ error: 'Store is not assigned to this shop profile.' });
        }
        const store = await db_1.prisma.shoppingStore.update({
            where: { id: body.targetId },
            data: { isOpen: body.enabled },
        });
        return res.json({
            module: body.module,
            id: store.id,
            enabled: store.isOpen,
        });
    }
    if (body.module === 'food') {
        if (bindings.restaurantIds.length === 0 ||
            !bindings.restaurantIds.includes(body.targetId)) {
            return res.status(403).json({ error: 'Restaurant is not assigned to this shop profile.' });
        }
        const restaurant = await db_1.prisma.restaurant.update({
            where: { id: body.targetId },
            data: { isOpen: body.enabled },
        });
        return res.json({
            module: body.module,
            id: restaurant.id,
            enabled: restaurant.isOpen,
        });
    }
    const product = await db_1.prisma.product.findUnique({
        where: { id: body.targetId },
        select: {
            id: true,
            metadata: true,
        },
    });
    const metadata = product?.metadata &&
        typeof product.metadata === 'object' &&
        !Array.isArray(product.metadata)
        ? product.metadata
        : null;
    const sourceBusiness = metadata?.sourceBusiness?.toString();
    if (product == null ||
        sourceBusiness == null ||
        !bindings.pharmacyBusinesses.includes(sourceBusiness)) {
        return res.status(403).json({ error: 'Pharmacy item is not assigned to this shop profile.' });
    }
    const updatedProduct = await db_1.prisma.product.update({
        where: { id: body.targetId },
        data: { inStock: body.enabled },
    });
    res.json({
        module: body.module,
        id: updatedProduct.id,
        enabled: updatedProduct.inStock,
    });
}));
router.get('/:userId/provider-availability', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.PROVIDER) {
        return res.status(404).json({ error: 'Provider pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    const [providers, laundryServices] = await Promise.all([
        db_1.prisma.homeServiceProvider.findMany({
            where: bindings.providerIds.length === 0
                ? undefined
                : { id: { in: bindings.providerIds } },
            select: {
                id: true,
                name: true,
                isAvailable: true,
            },
            orderBy: { name: 'asc' },
        }),
        db_1.prisma.laundryService.findMany({
            where: bindings.laundryServiceIds.length === 0
                ? undefined
                : { id: { in: bindings.laundryServiceIds } },
            select: {
                id: true,
                name: true,
                active: true,
            },
            orderBy: { name: 'asc' },
        }),
    ]);
    res.json({
        services: providers.map((provider) => ({
            id: provider.id,
            name: provider.name,
            enabled: provider.isAvailable,
        })),
        laundry: laundryServices.map((service) => ({
            id: service.id,
            name: service.name,
            enabled: service.active,
        })),
    });
}));
router.post('/:userId/provider-availability', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateProviderAvailabilitySchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.PROVIDER) {
        return res.status(404).json({ error: 'Provider pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    if (body.module === 'services') {
        if (bindings.providerIds.length === 0 ||
            !bindings.providerIds.includes(body.targetId)) {
            return res.status(403).json({ error: 'Provider is not assigned to this profile.' });
        }
        const provider = await db_1.prisma.homeServiceProvider.update({
            where: { id: body.targetId },
            data: { isAvailable: body.enabled },
        });
        return res.json({
            module: body.module,
            id: provider.id,
            enabled: provider.isAvailable,
        });
    }
    if (bindings.laundryServiceIds.length === 0 ||
        !bindings.laundryServiceIds.includes(body.targetId)) {
        return res.status(403).json({ error: 'Laundry service is not assigned to this profile.' });
    }
    const service = await db_1.prisma.laundryService.update({
        where: { id: body.targetId },
        data: { active: body.enabled },
    });
    res.json({
        module: body.module,
        id: service.id,
        enabled: service.active,
    });
}));
router.get('/:userId/doctor-availability', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.DOCTOR) {
        return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    const doctors = await db_1.prisma.doctor.findMany({
        where: bindings.doctorIds.length === 0
            ? undefined
            : { id: { in: bindings.doctorIds } },
        select: {
            id: true,
            name: true,
            specialty: true,
            isAvailable: true,
        },
        orderBy: { name: 'asc' },
    });
    res.json(doctors.map((doctor) => ({
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        enabled: doctor.isAvailable,
    })));
}));
router.post('/:userId/doctor-availability', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateDoctorAvailabilitySchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.DOCTOR) {
        return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    if (bindings.doctorIds.length === 0 ||
        !bindings.doctorIds.includes(body.doctorId)) {
        return res.status(403).json({ error: 'Doctor is not assigned to this profile.' });
    }
    const doctor = await db_1.prisma.doctor.update({
        where: { id: body.doctorId },
        data: { isAvailable: body.enabled },
    });
    res.json({
        id: doctor.id,
        enabled: doctor.isAvailable,
    });
}));
router.get('/:userId/provider-settings', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.PROVIDER) {
        return res.status(404).json({ error: 'Provider pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    const providers = await db_1.prisma.homeServiceProvider.findMany({
        where: bindings.providerIds.length === 0
            ? undefined
            : { id: { in: bindings.providerIds } },
        select: {
            id: true,
            name: true,
            title: true,
            location: true,
            contactPhone: true,
            responseTime: true,
            bookingModesJson: true,
            availabilityJson: true,
        },
        orderBy: { name: 'asc' },
    });
    res.json(providers.map((provider) => ({
        id: provider.id,
        name: provider.name,
        title: provider.title,
        location: provider.location,
        contactPhone: provider.contactPhone,
        responseTime: provider.responseTime,
        bookingModes: normalizeStringList(provider.bookingModesJson),
        availability: normalizeHours(provider.availabilityJson, {
            weekdays: '08:00 AM - 06:00 PM',
            saturday: '09:00 AM - 02:00 PM',
            sunday: 'Closed',
        }),
    })));
}));
router.post('/:userId/provider-settings', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateProviderSettingsSchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.PROVIDER) {
        return res.status(404).json({ error: 'Provider pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    if (bindings.providerIds.length === 0 ||
        !bindings.providerIds.includes(body.providerId)) {
        return res.status(403).json({ error: 'Provider is not assigned to this profile.' });
    }
    const provider = await db_1.prisma.homeServiceProvider.update({
        where: { id: body.providerId },
        data: {
            location: body.location == null ? undefined : body.location.trim() || null,
            contactPhone: body.contactPhone == null
                ? undefined
                : body.contactPhone.trim() || null,
            responseTime: body.responseTime == null
                ? undefined
                : body.responseTime.trim() || null,
            bookingModesJson: body.bookingModes == null
                ? undefined
                : normalizeStringList(body.bookingModes),
            availabilityJson: body.availability == null
                ? undefined
                : normalizeHours(body.availability, {
                    weekdays: '08:00 AM - 06:00 PM',
                    saturday: '09:00 AM - 02:00 PM',
                    sunday: 'Closed',
                }),
        },
        select: {
            id: true,
            name: true,
            title: true,
            location: true,
            contactPhone: true,
            responseTime: true,
            bookingModesJson: true,
            availabilityJson: true,
        },
    });
    res.json({
        id: provider.id,
        name: provider.name,
        title: provider.title,
        location: provider.location,
        contactPhone: provider.contactPhone,
        responseTime: provider.responseTime,
        bookingModes: normalizeStringList(provider.bookingModesJson),
        availability: normalizeHours(provider.availabilityJson, {
            weekdays: '08:00 AM - 06:00 PM',
            saturday: '09:00 AM - 02:00 PM',
            sunday: 'Closed',
        }),
    });
}));
router.get('/:userId/doctor-settings', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.DOCTOR) {
        return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    const doctors = await db_1.prisma.doctor.findMany({
        where: bindings.doctorIds.length === 0
            ? undefined
            : { id: { in: bindings.doctorIds } },
        select: {
            id: true,
            name: true,
            specialty: true,
            location: true,
            contactPhone: true,
            contactWhatsApp: true,
            careModesJson: true,
            workingHoursJson: true,
        },
        orderBy: { name: 'asc' },
    });
    res.json(doctors.map((doctor) => ({
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        location: doctor.location,
        contactPhone: doctor.contactPhone,
        contactWhatsApp: doctor.contactWhatsApp,
        careModes: normalizeStringList(doctor.careModesJson),
        workingHours: normalizeHours(doctor.workingHoursJson, {
            weekdays: '09:00 AM - 05:00 PM',
            saturday: '10:00 AM - 02:00 PM',
            sunday: 'Closed',
        }),
    })));
}));
router.post('/:userId/doctor-settings', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateDoctorSettingsSchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.findUnique({ where: { userId } });
    if (!profile || profile.type !== client_1.ProProfileType.DOCTOR) {
        return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }
    const bindings = normalizeBindings(profile.bindings);
    if (bindings.doctorIds.length === 0 ||
        !bindings.doctorIds.includes(body.doctorId)) {
        return res.status(403).json({ error: 'Doctor is not assigned to this profile.' });
    }
    const doctor = await db_1.prisma.doctor.update({
        where: { id: body.doctorId },
        data: {
            location: body.location == null ? undefined : body.location.trim() || null,
            contactPhone: body.contactPhone == null
                ? undefined
                : body.contactPhone.trim() || null,
            contactWhatsApp: body.contactWhatsApp == null
                ? undefined
                : body.contactWhatsApp.trim() || null,
            careModesJson: body.careModes == null
                ? undefined
                : normalizeStringList(body.careModes),
            workingHoursJson: body.workingHours == null
                ? undefined
                : normalizeHours(body.workingHours, {
                    weekdays: '09:00 AM - 05:00 PM',
                    saturday: '10:00 AM - 02:00 PM',
                    sunday: 'Closed',
                }),
        },
        select: {
            id: true,
            name: true,
            specialty: true,
            location: true,
            contactPhone: true,
            contactWhatsApp: true,
            careModesJson: true,
            workingHoursJson: true,
        },
    });
    res.json({
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        location: doctor.location,
        contactPhone: doctor.contactPhone,
        contactWhatsApp: doctor.contactWhatsApp,
        careModes: normalizeStringList(doctor.careModesJson),
        workingHours: normalizeHours(doctor.workingHoursJson, {
            weekdays: '09:00 AM - 05:00 PM',
            saturday: '10:00 AM - 02:00 PM',
            sunday: 'Closed',
        }),
    });
}));
router.post('/:userId/online-status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const body = updateOnlineStatusSchema.parse(req.body);
    const profile = await db_1.prisma.proProfile.update({
        where: { userId },
        data: { isOnline: body.isOnline },
    });
    res.json(serializeProProfile(profile));
}));
router.get('/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile) {
        return res.status(404).json({ error: 'Pro profile not found.' });
    }
    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    res.json(serializeProProfile(hydratedProfile));
}));
router.get('/:userId/dashboard', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const profile = await db_1.prisma.proProfile.findUnique({
        where: { userId },
    });
    if (!profile) {
        return res.status(404).json({ error: 'Pro profile not found.' });
    }
    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const dashboard = await buildDashboard(hydratedProfile);
    res.json({
        profile: serializeProProfile(hydratedProfile),
        ...dashboard,
    });
}));
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = proProfileSchema.parse(req.body);
    const user = await db_1.prisma.user.findUnique({
        where: { id: body.userId },
    });
    if (!user) {
        return res.status(404).json({ error: 'User not found.' });
    }
    const resolvedBindings = await resolveBindings(body.businessName, body.activeModules);
    const ownedLaundryServiceIds = await syncLaundryOwnership(body.userId, body.type, body.activeModules, resolvedBindings);
    const bindings = {
        ...resolvedBindings,
        laundryServiceIds: ownedLaundryServiceIds,
    };
    const profile = await db_1.prisma.proProfile.upsert({
        where: { userId: body.userId },
        create: {
            userId: body.userId,
            type: body.type,
            activeModules: body.activeModules,
            businessName: body.businessName,
            avatarUrl: body.avatarUrl?.trim() || null,
            bindings,
            isOnline: body.isOnline ?? true,
            isVerified: body.isVerified ?? false,
        },
        update: {
            type: body.type,
            activeModules: body.activeModules,
            businessName: body.businessName,
            avatarUrl: body.avatarUrl?.trim() || null,
            bindings,
            isOnline: body.isOnline ?? true,
            isVerified: body.isVerified ?? false,
        },
    });
    res.status(201).json(serializeProProfile(profile));
}));
exports.default = router;
