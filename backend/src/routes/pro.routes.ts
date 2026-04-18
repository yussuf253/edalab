import {
  AppointmentStatus,
  ModuleType,
  NotificationModule,
  NotificationType,
  OrderStatus,
  Prisma,
  ProModule,
  ProProfileType,
  RideStatus,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { createBackendNotification } from '../utils/notifications';
import { toNumber } from '../utils/serializers';

const router = Router();

const proProfileSchema = z.object({
  userId: z.string().min(1),
  type: z.nativeEnum(ProProfileType),
  activeModules: z.array(z.nativeEnum(ProModule)).min(1),
  businessName: z.string().trim().min(2),
  avatarUrl: z.string().trim().optional().nullable(),
  isOnline: z.boolean().optional(),
  isVerified: z.boolean().optional(),
});

const claimDeliverySchema = z.object({
  orderId: z.string().min(1),
});

const claimRideSchema = z.object({
  rideId: z.string().min(1),
});

const updateDeliveryStatusSchema = z.object({
  orderId: z.string().min(1),
  status: z.nativeEnum(OrderStatus),
});

const updateRideStatusSchema = z.object({
  rideId: z.string().min(1),
  status: z.nativeEnum(RideStatus),
});

const updateShopOrderStatusSchema = z.object({
  orderId: z.string().min(1),
  status: z.nativeEnum(OrderStatus),
});

const updateProviderOrderStatusSchema = z.object({
  orderId: z.string().min(1),
  status: z.nativeEnum(OrderStatus),
});

const updateDoctorAppointmentStatusSchema = z.object({
  appointmentId: z.string().min(1),
  status: z.nativeEnum(AppointmentStatus),
});

const updateOnlineStatusSchema = z.object({
  isOnline: z.boolean(),
});

const updateProAvatarSchema = z.object({
  avatarUrl: z.string().trim().url().optional().or(z.literal('')),
});

const updateShopAvailabilitySchema = z.object({
  module: z.enum(['shopping', 'food', 'pharmacy']),
  targetId: z.string().min(1),
  enabled: z.boolean(),
});

const createShoppingStoreSchema = z.object({
  name: z.string().trim().min(2).max(120).optional(),
  tagline: z.string().trim().max(160).optional().or(z.literal('')),
  description: z.string().trim().max(800).optional().or(z.literal('')),
  imageUrl: z.string().trim().url().optional().or(z.literal('')),
});

const createRestaurantSchema = z.object({
  name: z.string().trim().min(2).max(120).optional(),
  cuisine: z.string().trim().min(2).max(80).optional(),
  imageUrl: z.string().trim().url().optional().or(z.literal('')),
});

const createPharmacyBusinessSchema = z.object({
  name: z.string().trim().min(2).max(120).optional(),
});

const createHomeServiceProviderSchema = z.object({
  name: z.string().trim().min(2).max(120).optional(),
  title: z.string().trim().max(120).optional().or(z.literal('')),
  categoryId: z.string().trim().min(1).optional(),
  startingPrice: z.coerce.number().positive().max(100000).optional(),
  yearsExperience: z.string().trim().max(80).optional().or(z.literal('')),
  responseTime: z.string().trim().max(60).optional().or(z.literal('')),
  location: z.string().trim().max(120).optional().or(z.literal('')),
  contactPhone: z.string().trim().max(40).optional().or(z.literal('')),
  about: z.string().trim().max(800).optional().or(z.literal('')),
  imageUrl: z.string().trim().url().optional().or(z.literal('')),
  services: z.array(z.string().trim().min(1).max(80)).max(24).optional(),
  highlights: z.array(z.string().trim().min(1).max(120)).max(12).optional(),
  serviceZone: z
    .object({
      enabled: z.boolean().optional(),
      centerLatitude: z.coerce.number().min(-90).max(90).optional().nullable(),
      centerLongitude: z.coerce.number().min(-180).max(180).optional().nullable(),
      radiusKm: z.coerce.number().positive().max(120).optional(),
    })
    .optional(),
  houseHelpConfig: z
    .object({
      bookingTypes: z.array(z.string().trim().min(1).max(60)).max(8).optional(),
      shiftDurations: z.array(z.string().trim().min(1).max(60)).max(8).optional(),
      homeSizes: z.array(z.string().trim().min(1).max(40)).max(8).optional(),
      arrivalTargets: z.array(z.string().trim().min(1).max(60)).max(8).optional(),
      supplyModes: z.array(z.string().trim().min(1).max(60)).max(8).optional(),
    })
    .optional(),
});

const createShoppingProductSchema = z.object({
  module: z.enum(['shopping', 'pharmacy']).optional(),
  storeId: z.string().min(1).optional(),
  businessName: z.string().trim().max(120).optional().or(z.literal('')),
  categoryName: z.string().trim().min(2).max(80),
  name: z.string().trim().min(2).max(120),
  brand: z.string().trim().max(120).optional().or(z.literal('')),
  description: z.string().trim().min(4).max(800),
  price: z.number().positive(),
  originalPrice: z.number().positive().nullable().optional(),
  unit: z.string().trim().max(40).optional().or(z.literal('')),
  badge: z.string().trim().max(40).optional().or(z.literal('')),
  imageUrl: z.string().trim().url().optional().or(z.literal('')),
  imageUrls: z.array(z.string().trim().url()).max(8).optional(),
  colors: z.array(z.string().trim().min(1).max(40)).max(20).optional(),
  sizes: z.array(z.string().trim().min(1).max(40)).max(20).optional(),
  tags: z.array(z.string().trim().min(1).max(40)).max(20).optional(),
  features: z.array(z.string().trim().min(1).max(120)).max(30).optional(),
  dosage: z.string().trim().max(120).optional().or(z.literal('')),
  packageSize: z.string().trim().max(80).optional().or(z.literal('')),
  requiresPrescription: z.boolean().optional(),
  isOrganic: z.boolean().optional(),
  inStock: z.boolean().optional(),
});

const updateShoppingProductStockSchema = z.object({
  module: z.enum(['shopping', 'pharmacy']).optional(),
  inStock: z.boolean(),
});

const updateProviderAvailabilitySchema = z.object({
  module: z.enum(['services', 'laundry']),
  targetId: z.string().min(1),
  enabled: z.boolean(),
});

const updateProviderBindingsSchema = z
  .object({
    providerIds: z.array(z.string().min(1)).optional(),
    laundryServiceIds: z.array(z.string().min(1)).optional(),
  })
  .refine(
    (value) =>
      value.providerIds !== undefined || value.laundryServiceIds !== undefined,
    {
      message: 'At least one provider binding list must be supplied.',
    },
  );

const updateDoctorAvailabilitySchema = z.object({
  doctorId: z.string().min(1),
  enabled: z.boolean(),
});

const hoursSchema = z.object({
  weekdays: z.string().trim().max(120),
  saturday: z.string().trim().max(120),
  sunday: z.string().trim().max(120),
});

const settingsModesSchema = z.array(z.string().trim().min(1).max(40)).max(8);

const updateProviderSettingsSchema = z.object({
  providerId: z.string().min(1),
  location: z.string().trim().max(120).optional(),
  contactPhone: z.string().trim().max(40).optional(),
  responseTime: z.string().trim().max(60).optional(),
  services: z.array(z.string().trim().min(1).max(80)).max(24).optional(),
  bookingModes: settingsModesSchema.optional(),
  availability: hoursSchema.optional(),
  serviceZone: z
    .object({
      enabled: z.boolean().optional(),
      centerLatitude: z.coerce.number().min(-90).max(90).optional().nullable(),
      centerLongitude: z.coerce.number().min(-180).max(180).optional().nullable(),
      radiusKm: z.coerce.number().positive().max(120).optional(),
    })
    .optional(),
  houseHelpConfig: z
    .object({
      bookingTypes: z.array(z.string().trim().min(1).max(60)).max(8).optional(),
      shiftDurations: z.array(z.string().trim().min(1).max(60)).max(8).optional(),
      homeSizes: z.array(z.string().trim().min(1).max(40)).max(8).optional(),
      arrivalTargets: z.array(z.string().trim().min(1).max(60)).max(8).optional(),
      supplyModes: z.array(z.string().trim().min(1).max(60)).max(8).optional(),
    })
    .optional(),
});

const updateDoctorSettingsSchema = z.object({
  doctorId: z.string().min(1),
  location: z.string().trim().max(120).optional(),
  contactPhone: z.string().trim().max(40).optional(),
  contactWhatsApp: z.string().trim().max(40).optional(),
  imageUrl: z.string().trim().url().optional().or(z.literal('')),
  careModes: settingsModesSchema.optional(),
  workingHours: hoursSchema.optional(),
});

type ProBindings = {
  shoppingStoreIds: string[];
  restaurantIds: string[];
  restaurantNames: string[];
  pharmacyBusinesses: string[];
  providerIds: string[];
  doctorIds: string[];
  laundryServiceIds: string[];
};

function serializeProProfile(profile: {
  id: string;
  accountId?: string | null;
  userId: string;
  type: ProProfileType;
  activeModules: ProModule[];
  businessName: string;
  avatarUrl: string | null;
  bindings?: unknown;
  isOnline: boolean;
  isVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
}) {
  return {
    id: profile.id,
    userId: profile.userId,
    type: profile.type.toLowerCase(),
    activeModules: profile.activeModules.map((module) =>
      module.toLowerCase(),
    ),
    businessName: profile.businessName,
    avatarUrl: profile.avatarUrl,
    bindings: normalizeBindings(profile.bindings),
    isOnline: profile.isOnline,
    isVerified: profile.isVerified,
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt,
  };
}

const liveOrderStatuses: OrderStatus[] = [
  OrderStatus.PENDING,
  OrderStatus.CONFIRMED,
  OrderStatus.PROCESSING,
  OrderStatus.DISPATCHED,
  OrderStatus.IN_PROGRESS,
];
const HOUSE_HELP_MAX_MATCH_RADIUS_KM = 1;
const HOME_CARE_APPOINTMENT_TYPES = [
  'home_visit',
  'phone_advice',
  'video_support',
  'nursing_visit',
  'elderly_monitoring',
  'post_op_care',
];

function homeCareAppointmentFilter(): Prisma.AppointmentWhereInput {
  return {
    OR: [
      { appointmentType: { startsWith: 'home_' } },
      { appointmentType: { in: HOME_CARE_APPOINTMENT_TYPES } },
    ],
  };
}

function startOfToday() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
}

function formatCurrency(value: number | null | undefined) {
  return `\$${(value ?? 0).toFixed(2)}`;
}

function formatModule(value: string) {
  return value
    .toLowerCase()
    .split('_')
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join(' ');
}

function orderNotificationModule(moduleType: ModuleType): NotificationModule {
  switch (moduleType) {
    case ModuleType.FOOD:
      return NotificationModule.FOOD;
    case ModuleType.SHOPPING:
      return NotificationModule.SHOPPING;
    case ModuleType.PHARMACY:
      return NotificationModule.PHARMACY;
    case ModuleType.HOME_SERVICES:
    case ModuleType.HOUSE_HELP:
      return NotificationModule.HOME_SERVICES;
    case ModuleType.LAUNDRY:
      return NotificationModule.LAUNDRY;
    case ModuleType.HOTEL:
      return NotificationModule.HOTEL;
    case ModuleType.GROCERY:
      return NotificationModule.GROCERY;
    default:
      return NotificationModule.ORDERS;
  }
}

function orderNotificationType(moduleType: ModuleType): NotificationType {
  if (moduleType === ModuleType.LAUNDRY) {
    return NotificationType.LAUNDRY;
  }
  return NotificationType.ORDER;
}

function orderRouteForModule(moduleType: ModuleType, orderId: string): string {
  switch (moduleType) {
    case ModuleType.FOOD:
      return `/food/tracking/${orderId}`;
    case ModuleType.SHOPPING:
      return `/shopping/order/${orderId}`;
    case ModuleType.PHARMACY:
      return `/pharmacy/order/${orderId}`;
    case ModuleType.HOME_SERVICES:
    case ModuleType.HOUSE_HELP:
      return `/home-services/booking/${orderId}`;
    case ModuleType.LAUNDRY:
      return `/laundry/tracking/${orderId}`;
    case ModuleType.HOTEL:
      return `/hotel/order/${orderId}`;
    default:
      return '/orders';
  }
}

async function notifyOrderLifecycle(params: {
  userId: string;
  orderId: string;
  moduleType: ModuleType;
  status: OrderStatus;
  event: 'claimed' | 'status';
}) {
  const statusLabel = formatModule(params.status);
  const moduleLabel = formatModule(params.moduleType).toLowerCase();
  const isHomeServiceLifecycle =
    params.moduleType === ModuleType.HOME_SERVICES ||
    params.moduleType === ModuleType.HOUSE_HELP;
  const title =
    params.event === 'claimed'
      ? `${formatModule(params.moduleType)} delivery assigned`
      : isHomeServiceLifecycle
        ? (() => {
            switch (params.status) {
              case OrderStatus.CONFIRMED:
                return 'Booking confirmed';
              case OrderStatus.DISPATCHED:
                return 'Provider on the way';
              case OrderStatus.COMPLETED:
                return 'Work completed';
              default:
                return `${formatModule(params.moduleType)} order update`;
            }
          })()
        : `${formatModule(params.moduleType)} order update`;
  const body =
    params.event === 'claimed'
      ? `A courier accepted your ${moduleLabel} order. Status: ${statusLabel}.`
      : isHomeServiceLifecycle
        ? (() => {
            switch (params.status) {
              case OrderStatus.CONFIRMED:
                return `Your ${moduleLabel} booking is confirmed.`;
              case OrderStatus.DISPATCHED:
                return `Your ${moduleLabel} provider is on the way.`;
              case OrderStatus.IN_PROGRESS:
                return `Your ${moduleLabel} provider has started the work.`;
              case OrderStatus.COMPLETED:
                return `Your ${moduleLabel} service is marked as completed.`;
              default:
                return `Your ${moduleLabel} order is now ${statusLabel}.`;
            }
          })()
        : `Your ${moduleLabel} order is now ${statusLabel}.`;
  const route = orderRouteForModule(params.moduleType, params.orderId);

  try {
    await createBackendNotification({
      userId: params.userId,
      type: orderNotificationType(params.moduleType),
      module: orderNotificationModule(params.moduleType),
      title,
      body,
      route,
      dedupeKey: `pro-order:${params.orderId}:${params.status}:${params.event}`,
      metadata: {
        orderId: params.orderId,
        moduleType: params.moduleType,
        status: params.status,
        source: 'pro_status_flow',
      },
    });
  } catch (error) {
    console.error('[PRO NOTIFY] Failed to send order lifecycle notification', {
      orderId: params.orderId,
      status: params.status,
      event: params.event,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

function allowedProviderOrderTransitions(
  moduleType: ModuleType,
  currentStatus: OrderStatus,
): OrderStatus[] {
  const isServiceFlow =
    moduleType === ModuleType.HOME_SERVICES || moduleType === ModuleType.HOUSE_HELP;
  if (isServiceFlow) {
    switch (currentStatus) {
      case OrderStatus.PENDING:
        return [OrderStatus.CONFIRMED];
      case OrderStatus.CONFIRMED:
        return [OrderStatus.DISPATCHED, OrderStatus.IN_PROGRESS];
      case OrderStatus.DISPATCHED:
        return [OrderStatus.IN_PROGRESS, OrderStatus.COMPLETED];
      case OrderStatus.IN_PROGRESS:
        return [OrderStatus.COMPLETED];
      case OrderStatus.PROCESSING:
        return [OrderStatus.DISPATCHED, OrderStatus.IN_PROGRESS, OrderStatus.COMPLETED];
      default:
        return [];
    }
  }

  switch (currentStatus) {
    case OrderStatus.PENDING:
      return [OrderStatus.CONFIRMED];
    case OrderStatus.CONFIRMED:
      return [OrderStatus.PROCESSING];
    case OrderStatus.PROCESSING:
      return [OrderStatus.DISPATCHED];
    case OrderStatus.DISPATCHED:
      return [OrderStatus.IN_PROGRESS];
    case OrderStatus.IN_PROGRESS:
      return [OrderStatus.COMPLETED];
    default:
      return [];
  }
}

async function notifyRideLifecycle(params: {
  userId: string;
  rideId: string;
  status: RideStatus;
  pickupLabel?: string | null;
  event: 'claimed' | 'status';
}) {
  const statusLabel = formatModule(params.status);
  const title = params.event === 'claimed' ? 'Driver assigned' : 'Ride status update';
  const body =
    params.event === 'claimed'
      ? `Your driver is assigned${params.pickupLabel ? ` and heading to ${params.pickupLabel}` : ''}.`
      : `Your ride is now ${statusLabel}.`;

  try {
    await createBackendNotification({
      userId: params.userId,
      type: NotificationType.RIDE,
      module: NotificationModule.RIDE,
      title,
      body,
      route: `/ride/tracking/${params.rideId}`,
      dedupeKey: `pro-ride:${params.rideId}:${params.status}:${params.event}`,
      metadata: {
        rideId: params.rideId,
        status: params.status,
        source: 'pro_status_flow',
      },
    });
  } catch (error) {
    console.error('[PRO NOTIFY] Failed to send ride lifecycle notification', {
      rideId: params.rideId,
      status: params.status,
      event: params.event,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

async function notifyAppointmentLifecycle(params: {
  userId: string;
  appointmentId: string;
  status: AppointmentStatus;
  doctorId: string;
}) {
  const statusLabel = formatModule(params.status);
  try {
    await createBackendNotification({
      userId: params.userId,
      type: NotificationType.APPOINTMENT,
      module: NotificationModule.DOCTOR,
      title: 'Appointment status update',
      body: `Your appointment is now ${statusLabel}.`,
      route: '/doctor/appointments',
      dedupeKey: `pro-appointment:${params.appointmentId}:${params.status}`,
      metadata: {
        appointmentId: params.appointmentId,
        doctorId: params.doctorId,
        status: params.status,
        source: 'pro_status_flow',
      },
    });
  } catch (error) {
    console.error('[PRO NOTIFY] Failed to send appointment notification', {
      appointmentId: params.appointmentId,
      status: params.status,
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

function isPresent<T>(value: T | null): value is T {
  return value != null;
}

function normalizeText(value: string) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function slugifyStoreName(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

async function ensureUniqueSlug(
  baseValue: string,
  exists: (slug: string) => Promise<boolean>,
) {
  const baseSlug = slugifyStoreName(baseValue) || 'item';
  let slug = baseSlug;
  let suffix = 1;

  while (await exists(slug)) {
    suffix += 1;
    slug = `${baseSlug}-${suffix}`;
  }

  return slug;
}

function matchesBusinessName(query: string, candidate: string) {
  const left = normalizeText(query);
  const right = normalizeText(candidate);
  if (!left || !right) return false;
  if (left === right) return true;
  if (left.includes(right) || right.includes(left)) return true;

  const leftTokens = left.split(' ').filter((token) => token.length >= 3);
  if (leftTokens.length === 0) return false;
  return leftTokens.every((token) => right.includes(token));
}

function normalizeBindings(value: unknown): ProBindings {
  const map =
    value != null && typeof value === 'object'
      ? (value as Record<string, unknown>)
      : {};
  const finalStringList = (key: string): string[] => {
    const raw = map[key];
    if (!Array.isArray(raw)) return [];
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

function normalizeStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return Array.from(
    new Set(
      value
        .map((entry) => entry?.toString().trim() ?? '')
        .filter((entry) => entry.length > 0),
    ),
  );
}

function mergeStringLists(left: string[], right: string[]) {
  return Array.from(new Set([...left, ...right]));
}

export async function sanitizeProviderBindingOverrides(
  activeModules: ProModule[],
  overrides: {
    providerIds?: unknown;
    laundryServiceIds?: unknown;
  },
) {
  const hasServices = activeModules.includes(ProModule.SERVICES);
  const hasLaundry = activeModules.includes(ProModule.LAUNDRY);

  const providerIdsRaw = normalizeStringList(overrides.providerIds);
  const laundryServiceIdsRaw = normalizeStringList(overrides.laundryServiceIds);

  const [providers, laundryServices] = await Promise.all([
    !hasServices || providerIdsRaw.length === 0
      ? Promise.resolve([])
      : prisma.homeServiceProvider.findMany({
          where: { id: { in: providerIdsRaw } },
          select: { id: true },
        }),
    !hasLaundry || laundryServiceIdsRaw.length === 0
      ? Promise.resolve([])
      : prisma.laundryService.findMany({
          where: { id: { in: laundryServiceIdsRaw } },
          select: { id: true },
        }),
  ]);

  return {
    providerIds: providers.map((provider) => provider.id),
    laundryServiceIds: laundryServices.map((service) => service.id),
  };
}

function normalizeHours(
  value: unknown,
  defaults: { weekdays: string; saturday: string; sunday: string },
) {
  const map =
    value != null && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {};

  return {
    weekdays: map.weekdays?.toString().trim() || defaults.weekdays,
    saturday: map.saturday?.toString().trim() || defaults.saturday,
    sunday: map.sunday?.toString().trim() || defaults.sunday,
  };
}

type ServiceZoneConfig = {
  enabled: boolean;
  centerLatitude: number | null;
  centerLongitude: number | null;
  radiusKm: number;
};

type HouseHelpConfig = {
  bookingTypes: string[];
  shiftDurations: string[];
  homeSizes: string[];
  arrivalTargets: string[];
  supplyModes: string[];
};

function toFiniteNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

function defaultHouseHelpConfig(): HouseHelpConfig {
  return {
    bookingTypes: ['One-time job', 'Daily recurring', 'Weekly recurring'],
    shiftDurations: ['2 hours', '4 hours', '8 hours'],
    homeSizes: ['F2', 'F3', 'F4'],
    arrivalTargets: ['Within 30 min', 'Scheduled slot'],
    supplyModes: ['Provider supplies', 'Customer supplies'],
  };
}

function normalizeServiceZoneConfig(
  value: unknown,
  fallback?: ServiceZoneConfig,
): ServiceZoneConfig {
  const defaults: ServiceZoneConfig = fallback ?? {
    enabled: false,
    centerLatitude: null,
    centerLongitude: null,
    radiusKm: 1,
  };
  const map =
    value != null && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {};

  const radiusRaw = toFiniteNumber(map.radiusKm ?? defaults.radiusKm);
  const centerLatitude = toFiniteNumber(
    map.centerLatitude ?? defaults.centerLatitude,
  );
  const centerLongitude = toFiniteNumber(
    map.centerLongitude ?? defaults.centerLongitude,
  );

  return {
    enabled: map.enabled == null ? defaults.enabled : Boolean(map.enabled),
    centerLatitude:
      centerLatitude != null && centerLatitude >= -90 && centerLatitude <= 90
        ? centerLatitude
        : defaults.centerLatitude,
    centerLongitude:
      centerLongitude != null && centerLongitude >= -180 && centerLongitude <= 180
        ? centerLongitude
        : defaults.centerLongitude,
    radiusKm:
      radiusRaw != null && radiusRaw > 0 && radiusRaw <= 120
        ? radiusRaw
        : defaults.radiusKm,
  };
}

function normalizeHouseHelpConfig(
  value: unknown,
  fallback?: HouseHelpConfig,
): HouseHelpConfig {
  const defaults = fallback ?? defaultHouseHelpConfig();
  const map =
    value != null && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {};

  const readList = (key: keyof HouseHelpConfig, max = 8) => {
    if (!Array.isArray(map[key])) return defaults[key];
    const values = normalizeStringList(map[key]).slice(0, max);
    return values.length === 0 ? defaults[key] : values;
  };

  return {
    bookingTypes: readList('bookingTypes'),
    shiftDurations: readList('shiftDurations'),
    homeSizes: readList('homeSizes'),
    arrivalTargets: readList('arrivalTargets'),
    supplyModes: readList('supplyModes'),
  };
}

function serviceZoneFromAvailabilityJson(value: unknown): ServiceZoneConfig {
  const map =
    value != null && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {};
  const nested = map.serviceZone;
  return normalizeServiceZoneConfig(
    nested,
    normalizeServiceZoneConfig(map.serviceZone),
  );
}

function houseHelpConfigFromAvailabilityJson(value: unknown): HouseHelpConfig {
  const map =
    value != null && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {};
  return normalizeHouseHelpConfig(map.houseHelpConfig);
}

function normalizeProviderAvailabilityJson(params: {
  current: unknown;
  availability?: unknown;
  serviceZone?: unknown;
  houseHelpConfig?: unknown;
}) {
  const defaults = {
    weekdays: '08:00 AM - 06:00 PM',
    saturday: '09:00 AM - 02:00 PM',
    sunday: 'Closed',
  };
  const existingHours = normalizeHours(params.current, defaults);
  const updatedHours =
    params.availability == null
      ? existingHours
      : normalizeHours(params.availability, defaults);
  const existingServiceZone = serviceZoneFromAvailabilityJson(params.current);
  const existingHouseHelpConfig = houseHelpConfigFromAvailabilityJson(params.current);

  return {
    ...updatedHours,
    serviceZone:
      params.serviceZone == null
        ? existingServiceZone
        : normalizeServiceZoneConfig(params.serviceZone, existingServiceZone),
    houseHelpConfig:
      params.houseHelpConfig == null
        ? existingHouseHelpConfig
        : normalizeHouseHelpConfig(params.houseHelpConfig, existingHouseHelpConfig),
  };
}

function toRadians(value: number) {
  return (value * Math.PI) / 180;
}

function haversineDistanceKm(
  startLatitude: number,
  startLongitude: number,
  endLatitude: number,
  endLongitude: number,
) {
  const earthRadiusKm = 6371;
  const latitudeDelta = toRadians(endLatitude - startLatitude);
  const longitudeDelta = toRadians(endLongitude - startLongitude);
  const startLatRad = toRadians(startLatitude);
  const endLatRad = toRadians(endLatitude);

  const a =
    Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
    Math.cos(startLatRad) *
      Math.cos(endLatRad) *
      Math.sin(longitudeDelta / 2) *
      Math.sin(longitudeDelta / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

function effectiveServiceZoneRadiusKm(
  zoneRadiusKm: number,
  moduleType: ModuleType,
) {
  if (moduleType === ModuleType.HOUSE_HELP) {
    return Math.min(zoneRadiusKm, HOUSE_HELP_MAX_MATCH_RADIUS_KM);
  }
  return zoneRadiusKm;
}

function isHouseHelpCategorySlug(value: string | null | undefined) {
  const normalized = (value ?? '').toLowerCase().trim();
  return (
    normalized === 'house-help' ||
    normalized === 'house_help' ||
    normalized === 'househelp' ||
    normalized === 'maid'
  );
}

function capServiceZoneRadiusForHouseHelp(value: unknown) {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    return value;
  }
  const map = { ...(value as Record<string, unknown>) };
  const radiusRaw = toFiniteNumber(map.radiusKm);
  const normalizedRadius =
    radiusRaw == null
      ? HOUSE_HELP_MAX_MATCH_RADIUS_KM
      : Math.max(0.1, Math.min(radiusRaw, HOUSE_HELP_MAX_MATCH_RADIUS_KM));
  map.radiusKm = normalizedRadius;
  return map;
}

function orderServiceLocation(order: {
  address?: { latitude: number | null; longitude: number | null } | null;
  items: Array<{ metadata: unknown }>;
}) {
  const firstItemMetadata =
    order.items[0]?.metadata &&
    typeof order.items[0].metadata === 'object' &&
    !Array.isArray(order.items[0].metadata)
      ? (order.items[0].metadata as Record<string, unknown>)
      : null;
  const serviceLocation =
    firstItemMetadata?.serviceLocation &&
    typeof firstItemMetadata.serviceLocation === 'object' &&
    !Array.isArray(firstItemMetadata.serviceLocation)
      ? (firstItemMetadata.serviceLocation as Record<string, unknown>)
      : null;

  const latitude = toFiniteNumber(
    serviceLocation?.latitude ?? order.address?.latitude,
  );
  const longitude = toFiniteNumber(
    serviceLocation?.longitude ?? order.address?.longitude,
  );
  if (latitude == null || longitude == null) return null;
  return { latitude, longitude };
}

function assignedProviderIdFromMetadata(metadata: unknown): string | null {
  if (metadata == null || typeof metadata !== 'object' || Array.isArray(metadata)) {
    return null;
  }
  const map = metadata as Record<string, unknown>;
  const assigned = map.assignedProviderId?.toString().trim();
  if (assigned && assigned.length > 0) return assigned;
  const providerId = map.providerId?.toString().trim();
  return providerId && providerId.length > 0 ? providerId : null;
}

function firstImageUrlFromJson(value: unknown): string | null {
  if (!Array.isArray(value)) return null;
  const url = value
    .map((entry) => entry?.toString().trim() ?? '')
    .find((entry) => entry.length > 0);
  return url ?? null;
}

function normalizeComparableText(value: string) {
  return value.trim().toLowerCase();
}

function readMetadataMap(value: unknown): Record<string, unknown> | null {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function pharmacyBusinessFromOrderItem(item: {
  brand?: string | null;
  metadata?: unknown;
  product?: { metadata?: unknown } | null;
}) {
  const productMetadata = readMetadataMap(item.product?.metadata);
  const itemMetadata = readMetadataMap(item.metadata);
  const candidates = [
    productMetadata?.sourceBusiness,
    itemMetadata?.sourceBusiness,
    itemMetadata?.selectedPharmacy,
    itemMetadata?.shopName,
    item.brand,
  ];

  for (const entry of candidates) {
    const value = entry?.toString().trim();
    if (value != null && value.length > 0) {
      return value;
    }
  }
  return null;
}

function isBoundPharmacyBusiness(
  businesses: string[],
  sourceBusiness: string | null,
) {
  if (sourceBusiness == null || sourceBusiness.trim().length == 0) {
    return false;
  }
  const normalized = normalizeComparableText(sourceBusiness);
  return businesses.some(
    (value) => normalizeComparableText(value) === normalized,
  );
}

function pharmacyOrderMatchesBindings(
  bindings: ProBindings,
  items: Array<{
    brand: string | null;
    metadata: unknown;
    product: { metadata: unknown } | null;
  }>,
) {
  if (bindings.pharmacyBusinesses.length === 0) {
    return false;
  }
  return items.some((item) =>
    isBoundPharmacyBusiness(
      bindings.pharmacyBusinesses,
      pharmacyBusinessFromOrderItem(item),
    ),
  );
}

function hasShopOrderAccess(
  bindings: ProBindings,
  order: {
    moduleType: ModuleType;
    items: Array<{
      brand: string | null;
      productId: string | null;
      metadata: unknown;
      product: {
        shopId: string | null;
        metadata: unknown;
      } | null;
    }>;
  },
) {
  switch (order.moduleType) {
    case ModuleType.SHOPPING:
      return (
        bindings.shoppingStoreIds.length > 0 &&
        order.items.some((item) =>
          item.product?.shopId != null
            ? bindings.shoppingStoreIds.includes(item.product.shopId)
            : false,
        )
      );
    case ModuleType.FOOD:
      return (
        bindings.restaurantNames.length > 0 &&
        order.items.some((item) =>
          item.brand != null ? bindings.restaurantNames.includes(item.brand) : false,
        )
      );
    case ModuleType.PHARMACY:
      return pharmacyOrderMatchesBindings(bindings, order.items);
    default:
      return false;
  }
}

function hasProviderOrderAccess(
  bindings: ProBindings,
  order: {
    moduleType: ModuleType;
    items: Array<{
      externalRefId: string | null;
      metadata?: unknown;
    }>;
  },
) {
  switch (order.moduleType) {
    case ModuleType.HOME_SERVICES:
    case ModuleType.HOUSE_HELP:
      return (
        bindings.providerIds.length > 0 &&
        order.items.some((item) =>
          item.externalRefId != null
            ? bindings.providerIds.includes(item.externalRefId)
            : (() => {
                const assignedProviderId = assignedProviderIdFromMetadata(
                  item.metadata,
                );
                return (
                  assignedProviderId != null &&
                  bindings.providerIds.includes(assignedProviderId)
                );
              })(),
        )
      );
    case ModuleType.LAUNDRY:
      return (
        bindings.laundryServiceIds.length > 0 &&
        order.items.some((item) =>
          item.externalRefId != null
            ? bindings.laundryServiceIds.includes(item.externalRefId)
            : false,
        )
      );
    default:
      return false;
  }
}

function customerName(user: { firstName: string; lastName: string }) {
  return `${user.firstName} ${user.lastName}`.trim();
}

function orderAddressLabel(
  order: { metadata: unknown; address?: { line1: string } | null },
  firstItemMetadata?: unknown,
) {
  const metadata =
    order.metadata && typeof order.metadata === 'object' && !Array.isArray(order.metadata)
      ? (order.metadata as Record<string, unknown>)
      : null;
  const itemMetadata =
    firstItemMetadata &&
    typeof firstItemMetadata === 'object' &&
    !Array.isArray(firstItemMetadata)
      ? (firstItemMetadata as Record<string, unknown>)
      : null;

  return (
    itemMetadata?.address?.toString() ??
    metadata?.address?.toString() ??
    order.address?.line1 ??
    ''
  );
}

function queueSourceLabel(
  moduleType: ModuleType,
  firstItem?: { brand: string | null; name: string; metadata: unknown } | null,
) {
  const itemMetadata =
    firstItem?.metadata &&
    typeof firstItem.metadata === 'object' &&
    !Array.isArray(firstItem.metadata)
      ? (firstItem.metadata as Record<string, unknown>)
      : null;

  return (
    itemMetadata?.shopName?.toString() ??
    itemMetadata?.sourceBusiness?.toString() ??
    firstItem?.brand ??
    firstItem?.name ??
    formatModule(moduleType)
  );
}

function queueModuleForOrder(moduleType: ModuleType): string {
  switch (moduleType) {
    case ModuleType.HOME_SERVICES:
    case ModuleType.HOUSE_HELP:
      return 'services';
    default:
      return moduleType.toLowerCase();
  }
}

function serializeQueueOrderItem(
  order: {
    id: string;
    userId: string;
    moduleType: ModuleType;
    status: OrderStatus;
    total: { toString(): string } | number;
    createdAt: Date;
    notes: string | null;
    metadata: unknown;
    address?: { line1: string } | null;
    user: { firstName: string; lastName: string; phone: string | null };
    items: Array<{
      name: string;
      brand: string | null;
      quantity: number;
      externalRefId: string | null;
      metadata: unknown;
    }>;
  },
  options?: {
    providerIdOverride?: string | null;
    queueType?: 'open' | 'assigned';
    distanceKm?: number | null;
  },
) {
  const totalItems = order.items.reduce((sum, item) => sum + item.quantity, 0);
  const firstItem = order.items[0];
  const firstItemMetadata =
    firstItem?.metadata &&
    typeof firstItem.metadata === 'object' &&
    !Array.isArray(firstItem.metadata)
      ? (firstItem.metadata as Record<string, unknown>)
      : null;
  const providerId =
    options?.providerIdOverride ??
    (order.moduleType === ModuleType.HOME_SERVICES ||
        order.moduleType === ModuleType.HOUSE_HELP
      ? (firstItem?.externalRefId ??
            assignedProviderIdFromMetadata(firstItemMetadata) ??
            null)
      : null);
  const queueType =
    options?.queueType ??
    (providerId == null || providerId.trim().length === 0
      ? 'open'
      : 'assigned');
  const categorySlug = firstItemMetadata?.categorySlug?.toString() ?? null;
  const prescriptionRequest =
    firstItemMetadata?.prescriptionRequest == true ||
    firstItem?.name?.toLowerCase().includes('prescription') == true;
  const prescriptionImageUrl =
    firstItemMetadata?.prescriptionImageUrl?.toString().trim() ?? '';
  const prescriptionPharmacy =
    firstItemMetadata?.selectedPharmacy?.toString().trim() ||
    firstItemMetadata?.sourceBusiness?.toString().trim() ||
    '';
  const prescriptionNote =
    firstItemMetadata?.prescriptionNote?.toString().trim() ?? '';
  return {
    id: order.id,
    module: queueModuleForOrder(order.moduleType),
    moduleType: order.moduleType,
    status: order.status,
    title: `${formatModule(order.moduleType)} #${order.id.slice(-5)}`,
    subtitle: `${totalItems} item${totalItems == 1 ? '' : 's'} • ${queueSourceLabel(order.moduleType, firstItem)}`,
    amount: formatCurrency(
      typeof order.total === 'number'
        ? order.total
        : Number(order.total.toString()),
    ),
    customerName: customerName(order.user),
    customerPhone: order.user.phone,
    notes: order.notes,
    address: orderAddressLabel(order, firstItem?.metadata),
    createdAt: order.createdAt,
    customerUserId: order.userId,
    providerId,
    categorySlug,
    prescriptionRequest,
    prescription:
      prescriptionRequest ||
      prescriptionImageUrl.length > 0 ||
      prescriptionPharmacy.length > 0 ||
      prescriptionNote.length > 0
        ? {
            imageUrl:
              prescriptionImageUrl.length > 0 ? prescriptionImageUrl : null,
            pharmacy:
              prescriptionPharmacy.length > 0 ? prescriptionPharmacy : null,
            note: prescriptionNote.length > 0 ? prescriptionNote : null,
          }
        : null,
    queueType,
    distanceKm:
      options?.distanceKm != null
        ? Number(options.distanceKm.toFixed(1))
        : null,
  };
}

function serializeQueueAppointmentItem(
  appointment: {
    id: string;
    userId: string;
    doctor: { name: string };
    user: { firstName: string; lastName: string; phone: string | null };
    timeSlot: string;
    appointmentType: string;
    status: AppointmentStatus;
    notes: string | null;
    appointmentAt: Date;
  },
) {
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

function serializeDispatchQueueOrderItem(
  order: {
    id: string;
    moduleType: ModuleType;
    status: OrderStatus;
    total: { toString(): string } | number;
    createdAt: Date;
    notes: string | null;
    metadata: unknown;
    userId: string;
    deliveryUserId: string | null;
    user: { firstName: string; lastName: string; phone: string | null };
    address?: { line1: string } | null;
    items: Array<{
      name: string;
      brand: string | null;
      quantity: number;
      metadata: unknown;
    }>;
  },
  currentUserId: string,
) {
  const totalItems = order.items.reduce((sum, item) => sum + item.quantity, 0);
  const firstItem = order.items[0];
  return {
    id: order.id,
    module: order.moduleType.toLowerCase(),
    status: order.status,
    title: `${formatModule(order.moduleType)} #${order.id.slice(-5)}`,
    subtitle: `${totalItems} item${totalItems == 1 ? '' : 's'} • ${queueSourceLabel(order.moduleType, firstItem)}`,
    amount: formatCurrency(
      typeof order.total === 'number'
        ? order.total
        : Number(order.total.toString()),
    ),
    customerName: customerName(order.user),
    customerPhone: order.user.phone,
    notes: order.notes,
    address: orderAddressLabel(order, firstItem?.metadata),
    queueType: order.deliveryUserId == currentUserId ? 'assigned' : 'open',
    createdAt: order.createdAt,
    customerUserId: order.userId,
  };
}

function serializeRideQueueItem(
  ride: {
    id: string;
    status: RideStatus;
    createdAt: Date;
    userId: string;
    driverUserId: string | null;
    pickupLabel: string | null;
    dropoffLabel: string | null;
    etaLabel: string | null;
    estimatedFare: { toString(): string } | number | null;
    driverName: string | null;
    user: { firstName: string; lastName: string; phone: string | null };
    rideCategory: { name: string };
  },
  currentUserId: string,
) {
  const fare =
    ride.estimatedFare == null
      ? ''
      : formatCurrency(
          typeof ride.estimatedFare === 'number'
            ? ride.estimatedFare
            : Number(ride.estimatedFare.toString()),
        );

  return {
    id: ride.id,
    module: 'ride',
    status: ride.status,
    title: `${ride.rideCategory.name} Ride`,
    subtitle: `${ride.pickupLabel ?? 'Pickup pending'} -> ${ride.dropoffLabel ?? 'Dropoff pending'}`,
    amount: fare,
    pickup: ride.pickupLabel,
    destination: ride.dropoffLabel,
    eta: ride.etaLabel,
    customerName: customerName(ride.user),
    customerPhone: ride.user.phone,
    queueType: ride.driverUserId == currentUserId ? 'assigned' : 'open',
    createdAt: ride.createdAt,
    customerUserId: ride.userId,
  };
}

export async function resolveBindings(
  businessName: string,
  activeModules: ProModule[],
): Promise<ProBindings> {
  const bindings: ProBindings = {
    shoppingStoreIds: [],
    restaurantIds: [],
    restaurantNames: [],
    pharmacyBusinesses: [],
    providerIds: [],
    doctorIds: [],
    laundryServiceIds: [],
  };

  const needsShopping =
    activeModules.includes(ProModule.SHOPPING) ||
    activeModules.includes(ProModule.PHARMACY);
  const needsFood = activeModules.includes(ProModule.FOOD);
  const needsDoctor = activeModules.includes(ProModule.DOCTOR);
  const needsServices = activeModules.includes(ProModule.SERVICES);
  const needsLaundry = activeModules.includes(ProModule.LAUNDRY);

  const [stores, restaurants, doctors, providers, pharmacyProducts, laundryServices] =
    await Promise.all([
      needsShopping
        ? prisma.shoppingStore.findMany({
            select: { id: true, name: true },
          })
        : Promise.resolve([]),
      needsFood
        ? prisma.restaurant.findMany({
            select: { id: true, name: true },
          })
        : Promise.resolve([]),
      needsDoctor
        ? prisma.doctor.findMany({
            select: { id: true, name: true },
          })
        : Promise.resolve([]),
      needsServices
        ? prisma.homeServiceProvider.findMany({
            select: { id: true, name: true },
          })
        : Promise.resolve([]),
      activeModules.includes(ProModule.PHARMACY)
        ? prisma.product.findMany({
            where: { moduleType: ModuleType.PHARMACY },
            select: { metadata: true },
          })
        : Promise.resolve([]),
      needsLaundry
        ? prisma.laundryService.findMany({
            select: { id: true, name: true },
          })
        : Promise.resolve([]),
    ]);

  bindings.shoppingStoreIds = stores
    .filter((store) => matchesBusinessName(businessName, store.name))
    .map((store) => store.id);

  const matchedRestaurants = restaurants.filter((restaurant) =>
    matchesBusinessName(businessName, restaurant.name),
  );
  bindings.restaurantIds = matchedRestaurants.map((restaurant) => restaurant.id);
  bindings.restaurantNames = matchedRestaurants.map(
    (restaurant) => restaurant.name,
  );

  bindings.doctorIds = doctors
    .filter((doctor) => matchesBusinessName(businessName, doctor.name))
    .map((doctor) => doctor.id);

  bindings.providerIds = providers
    .filter((provider) => matchesBusinessName(businessName, provider.name))
    .map((provider) => provider.id);

  bindings.laundryServiceIds = laundryServices
    .filter((service) => matchesBusinessName(businessName, service.name))
    .map((service) => service.id);

  const pharmacyBusinesses = new Set<string>();
  for (const product of pharmacyProducts) {
    const metadata =
      product.metadata && typeof product.metadata === 'object'
        ? (product.metadata as Record<string, unknown>)
        : null;
    const sourceBusiness = metadata?.sourceBusiness?.toString();
    if (
      sourceBusiness != null &&
      matchesBusinessName(businessName, sourceBusiness)
    ) {
      pharmacyBusinesses.add(sourceBusiness);
    }
  }
  bindings.pharmacyBusinesses = Array.from(pharmacyBusinesses);

  return bindings;
}

function normalizeResolvedBindingsForProfileType(
  type: ProProfileType,
  bindings: ProBindings,
): ProBindings {
  if (type !== ProProfileType.PROVIDER) {
    return bindings;
  }

  return {
    ...bindings,
    providerIds: [],
    laundryServiceIds: [],
  };
}

export async function syncLaundryOwnership(
  userId: string,
  type: ProProfileType,
  activeModules: ProModule[],
  bindings: ProBindings,
  db: Pick<typeof prisma, 'laundryService'> = prisma,
) {
  const ownsLaundry =
    type === ProProfileType.PROVIDER &&
    activeModules.includes(ProModule.LAUNDRY);

  if (!ownsLaundry) {
    await db.laundryService.updateMany({
      where: { providerUserId: userId },
      data: { providerUserId: null },
    });
    return [];
  }

  await db.laundryService.updateMany({
    where: {
      providerUserId: userId,
      ...(bindings.laundryServiceIds.length === 0
        ? {}
        : { id: { notIn: bindings.laundryServiceIds } }),
    },
    data: { providerUserId: null },
  });

  if (bindings.laundryServiceIds.length > 0) {
    await db.laundryService.updateMany({
      where: {
        id: { in: bindings.laundryServiceIds },
        OR: [{ providerUserId: null }, { providerUserId: userId }],
      },
      data: { providerUserId: userId },
    });
  }

  const ownedServices = await db.laundryService.findMany({
    where: { providerUserId: userId },
    select: { id: true },
  });

  return ownedServices.map((service) => service.id);
}

async function hydrateProfileBindingsIfMissing(profile: {
  id: string;
  accountId?: string | null;
  userId: string;
  type: ProProfileType;
  activeModules: ProModule[];
  businessName: string;
  avatarUrl: string | null;
  bindings: unknown;
  isOnline: boolean;
  isVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
}) {
  const bindings = normalizeBindings(profile.bindings);
  const hasBindings =
    bindings.shoppingStoreIds.length > 0 ||
    bindings.restaurantIds.length > 0 ||
    bindings.restaurantNames.length > 0 ||
    bindings.pharmacyBusinesses.length > 0 ||
    bindings.providerIds.length > 0 ||
    bindings.doctorIds.length > 0 ||
    bindings.laundryServiceIds.length > 0;

  if (hasBindings) {
    return profile;
  }

  const resolvedBindingsRaw = await resolveBindings(
    profile.businessName,
    profile.activeModules,
  );
  const resolvedBindings = normalizeResolvedBindingsForProfileType(
    profile.type,
    resolvedBindingsRaw,
  );
  const ownedLaundryServiceIds = await syncLaundryOwnership(
    profile.userId,
    profile.type,
    profile.activeModules,
    resolvedBindings,
  );

  return prisma.proProfile.update({
    where: { id: profile.id },
    data: {
      bindings: {
        ...resolvedBindings,
        laundryServiceIds: ownedLaundryServiceIds,
      },
    },
  });
}

function emptyShopSummary(
  module: 'shopping' | 'food' | 'pharmacy',
  title: string,
  actionLabel: string,
  businessName?: string,
) {
  return {
    module,
    title,
    subtitle:
      businessName != null && businessName.trim().length > 0
        ? `No matching business is currently bound for "${businessName}". Update the pro profile business name to match the real store, restaurant, or pharmacy listing.`
        : 'No business is currently bound to this module yet.',
    metrics: [
      '0 active business units',
      '0 pending orders',
      '0 published items',
      '0 completed today',
    ],
    recentItems: [] as ReturnType<typeof orderRecentItems>,
    actionLabel,
  };
}

function deliveryModuleTypeForProfileModule(
  module: ProModule,
): 'SHOPPING' | 'FOOD' | 'PHARMACY' | null {
  switch (module) {
    case ProModule.SHOPPING_DELIVERY:
      return ModuleType.SHOPPING;
    case ProModule.FOOD_DELIVERY:
      return ModuleType.FOOD;
    case ProModule.PHARMACY_DELIVERY:
      return ModuleType.PHARMACY;
    default:
      return null;
  }
}

function highlightFromItem(
  item:
    | {
        id: string;
        title: string;
        subtitle: string;
        status: string;
        amount?: string;
        meta?: string;
      }
    | null,
  module: string,
  ctaLabel: string,
) {
  if (item == null) return null;

  return {
    requestId: item.id,
    module,
    title: item.title,
    amount: item.amount,
    lines: [item.subtitle, item.status, item.meta ?? ''],
    ctaLabel,
  };
}

function orderRecentItems(
  orders: Array<{
    id: string;
    status: OrderStatus;
    total: unknown;
    createdAt: Date;
    items: Array<{ name: string; quantity: number; brand: string | null }>;
  }>,
  label: string,
) {
  return orders.map((order) => {
    const itemCount = order.items.reduce((sum, item) => sum + item.quantity, 0);
    const firstItem = order.items[0];
    const amount =
      typeof order.total === 'number'
        ? order.total
        : Number(
            (
              order.total as { toString?: (() => string) | undefined } | null
            )?.toString?.() ?? 0,
          );
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

async function buildShoppingSummary(
  todayStart: Date,
  bindings: ProBindings,
  businessName?: string,
) {
  if (bindings.shoppingStoreIds.length === 0) {
    return emptyShopSummary(
      'shopping',
      'Shopping Store',
      'Review Store Binding',
      businessName,
    );
  }

  const orderWhere = {
    moduleType: ModuleType.SHOPPING,
    items: {
      some: {
        product: {
          shopId: { in: bindings.shoppingStoreIds },
        },
      },
    },
  };
  const [productCount, outOfStockCount, pendingOrders, completedToday, recent] =
    await Promise.all([
      prisma.product.count({
        where: {
          moduleType: ModuleType.SHOPPING,
          shopId: { in: bindings.shoppingStoreIds },
        },
      }),
      prisma.product.count({
        where: {
          moduleType: ModuleType.SHOPPING,
          inStock: false,
          shopId: { in: bindings.shoppingStoreIds },
        },
      }),
      prisma.order.count({
        where: {
          ...orderWhere,
          status: { in: liveOrderStatuses },
        },
      }),
      prisma.order.count({
        where: {
          ...orderWhere,
          status: OrderStatus.COMPLETED,
          updatedAt: { gte: todayStart },
        },
      }),
      prisma.order.findMany({
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

async function buildFoodSummary(
  todayStart: Date,
  bindings: ProBindings,
  businessName?: string,
) {
  if (bindings.restaurantIds.length === 0 || bindings.restaurantNames.length === 0) {
    return emptyShopSummary(
      'food',
      'Food Store',
      'Review Restaurant Binding',
      businessName,
    );
  }

  const orderWhere = {
    moduleType: ModuleType.FOOD,
    items: {
      some: {
        brand: { in: bindings.restaurantNames },
      },
    },
  };
  const [restaurantCount, menuCount, pendingOrders, completedToday, recent] =
    await Promise.all([
      prisma.restaurant.count({
        where: {
          isOpen: true,
          id: { in: bindings.restaurantIds },
        },
      }),
      prisma.restaurantMenuItem.count({
        where: {
          isAvailable: true,
          category: { restaurantId: { in: bindings.restaurantIds } },
        },
      }),
      prisma.order.count({
        where: {
          ...orderWhere,
          status: { in: liveOrderStatuses },
        },
      }),
      prisma.order.count({
        where: {
          ...orderWhere,
          status: OrderStatus.COMPLETED,
          updatedAt: { gte: todayStart },
        },
      }),
      prisma.order.findMany({
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

async function buildPharmacySummary(
  todayStart: Date,
  bindings: ProBindings,
  businessName?: string,
) {
  if (bindings.pharmacyBusinesses.length === 0) {
    return emptyShopSummary(
      'pharmacy',
      'Pharmacy Store',
      'Review Pharmacy Binding',
      businessName,
    );
  }

  const allProducts = await prisma.product.findMany({
    where: { moduleType: ModuleType.PHARMACY },
    select: {
      id: true,
      requiresPrescription: true,
      metadata: true,
      inStock: true,
    },
  });

  const filteredProducts = allProducts.filter((product) => {
    const metadata =
      product.metadata &&
      typeof product.metadata === 'object' &&
      !Array.isArray(product.metadata)
        ? (product.metadata as Record<string, unknown>)
        : null;
    return isBoundPharmacyBusiness(
      bindings.pharmacyBusinesses,
      metadata?.sourceBusiness?.toString() ?? null,
    );
  });

  const pharmacyOrderCandidates = await prisma.order.findMany({
    where: { moduleType: ModuleType.PHARMACY },
    select: {
      id: true,
      status: true,
      total: true,
      createdAt: true,
      updatedAt: true,
      items: {
        select: {
          name: true,
          brand: true,
          quantity: true,
          metadata: true,
          product: {
            select: { metadata: true },
          },
        },
      },
    },
    orderBy: { createdAt: 'desc' },
    take: 300,
  });

  const pharmacyOrders = pharmacyOrderCandidates.filter((order) =>
    pharmacyOrderMatchesBindings(bindings, order.items),
  );
  const pendingOrders = pharmacyOrders.filter((order) =>
    liveOrderStatuses.includes(order.status),
  ).length;
  const completedToday = pharmacyOrders.filter(
    (order) =>
      order.status === OrderStatus.COMPLETED && order.updatedAt >= todayStart,
  ).length;
  const recent = pharmacyOrders.slice(0, 3);

  const medicineCount = filteredProducts.length;
  const prescriptionItems = filteredProducts.filter(
    (product) => product.requiresPrescription,
  ).length;

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

async function buildServicesSummary(todayStart: Date, bindings: ProBindings) {
  const [providers, serviceCandidates] = await Promise.all([
    bindings.providerIds.length === 0
      ? Promise.resolve([])
      : prisma.homeServiceProvider.findMany({
          where: { id: { in: bindings.providerIds } },
          select: {
            id: true,
            isAvailable: true,
            availabilityJson: true,
          },
        }),
    bindings.providerIds.length === 0
      ? Promise.resolve([])
      : prisma.order.findMany({
          where: {
            moduleType: { in: [ModuleType.HOME_SERVICES, ModuleType.HOUSE_HELP] },
          },
          select: {
            id: true,
            moduleType: true,
            status: true,
            total: true,
            createdAt: true,
            updatedAt: true,
            address: {
              select: {
                latitude: true,
                longitude: true,
              },
            },
            items: {
              select: {
                name: true,
                quantity: true,
                brand: true,
                externalRefId: true,
                metadata: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 200,
        }),
  ]);
  const providerCount = providers.length;
  const availableCount = providers.filter((provider) => provider.isAvailable).length;

  const pickZoneProvider = (
    order: (typeof serviceCandidates)[number],
  ): { providerId: string; distanceKm: number } | null => {
    const location = orderServiceLocation(order);
    if (location == null) return null;
    const matches = providers
      .filter((provider) => provider.isAvailable)
      .map((provider) => {
        const zone = serviceZoneFromAvailabilityJson(provider.availabilityJson);
        if (
          !zone.enabled ||
          zone.centerLatitude == null ||
          zone.centerLongitude == null
        ) {
          return null;
        }
        const distanceKm = haversineDistanceKm(
          zone.centerLatitude,
          zone.centerLongitude,
          location.latitude,
          location.longitude,
        );
        if (
          distanceKm >
          effectiveServiceZoneRadiusKm(zone.radiusKm, order.moduleType)
        ) {
          return null;
        }
        return { providerId: provider.id, distanceKm };
      })
      .filter(
        (entry): entry is { providerId: string; distanceKm: number } =>
          entry != null,
      );
    matches.sort((left, right) => left.distanceKm - right.distanceKm);
    return matches.length === 0 ? null : matches[0];
  };

  const relevantOrders = serviceCandidates.filter((order) => {
    const firstItem = order.items[0];
    const directProviderId = firstItem?.externalRefId;
    const assignedProviderId = assignedProviderIdFromMetadata(firstItem?.metadata);

    if (order.moduleType === ModuleType.HOME_SERVICES) {
      return (
        directProviderId != null &&
        bindings.providerIds.includes(directProviderId)
      );
    }

    if (
      directProviderId != null &&
      bindings.providerIds.includes(directProviderId)
    ) {
      return true;
    }

    if (
      assignedProviderId != null &&
      bindings.providerIds.includes(assignedProviderId)
    ) {
      return true;
    }

    if (order.status !== OrderStatus.PENDING) return false;

    const zoneCandidate = pickZoneProvider(order);
    return zoneCandidate != null;
  });

  const pendingOrders = relevantOrders.filter((order) =>
    liveOrderStatuses.includes(order.status),
  ).length;
  const completedToday = relevantOrders.filter(
    (order) =>
      order.status === OrderStatus.COMPLETED && order.updatedAt >= todayStart,
  ).length;
  const recent = [...relevantOrders]
    .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime())
    .slice(0, 3);

  return {
    module: 'services',
    title: 'Home Services',
    subtitle:
      bindings.providerIds.length === 0
        ? 'No provider bindings were found for this profile. Update the business name to match your provider listing.'
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

async function buildLaundrySummary(todayStart: Date, bindings: ProBindings) {
  const orderWhere = {
    moduleType: ModuleType.LAUNDRY,
    items: {
      some: {
        externalRefId: { in: bindings.laundryServiceIds },
      },
    },
  };

  const [serviceCount, activeOrders, completedToday, recent] = await Promise.all([
    prisma.laundryService.count({
      where: {
        active: true,
        id: { in: bindings.laundryServiceIds },
      },
    }),
    prisma.order.count({
      where: {
        ...orderWhere,
        status: { in: liveOrderStatuses },
      },
    }),
    prisma.order.count({
      where: {
        ...orderWhere,
        status: OrderStatus.COMPLETED,
        updatedAt: { gte: todayStart },
      },
    }),
    prisma.order.findMany({
      where: orderWhere,
      include: { items: true },
      orderBy: { createdAt: 'desc' },
      take: 3,
    }),
  ]);

  return {
    module: 'laundry',
    title: 'Laundry',
    subtitle:
      bindings.laundryServiceIds.length === 0
        ? 'No laundry bindings were found for this profile. Update the business name to match your laundry listing.'
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
      amount: formatCurrency(toNumber(order.total)),
      meta: order.createdAt.toISOString(),
    })),
    actionLabel: 'Open Laundry Queue',
  };
}

async function buildDoctorSummary(todayStart: Date, bindings: ProBindings) {
  const [availableDoctors, appointmentsToday, videoToday, recent] =
    await Promise.all([
      prisma.doctor.count({
        where: {
          isAvailable: true,
          ...(bindings.doctorIds.length === 0
            ? {}
            : { id: { in: bindings.doctorIds } }),
        },
      }),
      prisma.appointment.count({
        where: {
          appointmentAt: { gte: todayStart },
          ...(bindings.doctorIds.length === 0
            ? {}
            : { doctorId: { in: bindings.doctorIds } }),
        },
      }),
      prisma.appointment.count({
        where: {
          appointmentAt: { gte: todayStart },
          appointmentType: 'video',
          ...(bindings.doctorIds.length === 0
            ? {}
            : { doctorId: { in: bindings.doctorIds } }),
        },
      }),
      prisma.appointment.findMany({
        where:
          bindings.doctorIds.length === 0
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
    subtitle:
      bindings.doctorIds.length === 0
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

async function buildDeliverySummary(
  module: ProModule,
  moduleType: ModuleType,
  title: string,
  subtitle: string,
  todayStart: Date,
  userId: string,
) {
  const assignedWhere = {
    moduleType,
    deliveryUserId: userId,
  };

  const [activeAssigned, completedToday, recent, openQueue, claimableOrder] = await Promise.all([
    prisma.order.count({
      where: {
        ...assignedWhere,
        status: { in: liveOrderStatuses },
      },
    }),
    prisma.order.count({
      where: {
        ...assignedWhere,
        status: OrderStatus.COMPLETED,
        updatedAt: { gte: todayStart },
      },
    }),
    prisma.order.findMany({
      where: assignedWhere,
      include: { items: true },
      orderBy: { createdAt: 'desc' },
      take: 3,
    }),
    prisma.order.count({
      where: {
        moduleType,
        deliveryUserId: null,
        status: { in: liveOrderStatuses },
      },
    }),
    prisma.order.findFirst({
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
    highlightedRequest: highlightFromItem(
      claimableOrder == null
        ? null
        : orderRecentItems([claimableOrder], formatModule(moduleType))[0] ?? null,
      module.toLowerCase(),
      'Accept Delivery',
    ),
  };
}

async function buildRideSummary(todayStart: Date, userId: string) {
  const activeRideStatuses: RideStatus[] = [
    RideStatus.REQUESTED,
    RideStatus.ACCEPTED,
    RideStatus.DRIVER_ARRIVING,
    RideStatus.IN_PROGRESS,
  ];

  const [activeTrips, completedToday, recent, openQueue, claimableRide] = await Promise.all([
    prisma.rideBooking.count({
      where: {
        driverUserId: userId,
        status: { in: activeRideStatuses },
      },
    }),
    prisma.rideBooking.count({
      where: {
        driverUserId: userId,
        status: RideStatus.COMPLETED,
        updatedAt: { gte: todayStart },
      },
    }),
    prisma.rideBooking.findMany({
      where: { driverUserId: userId },
      include: { rideCategory: true },
      orderBy: { createdAt: 'desc' },
      take: 3,
    }),
    prisma.rideBooking.count({
      where: {
        driverUserId: null,
        status: RideStatus.REQUESTED,
      },
    }),
    prisma.rideBooking.findFirst({
      where: {
        driverUserId: null,
        status: RideStatus.REQUESTED,
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
      amount: formatCurrency(toNumber(ride.total)),
      meta: ride.etaLabel ?? '',
    })),
    actionLabel: 'Accept Ride',
    highlightedRequest:
      claimableRide == null
        ? null
        : highlightFromItem(
            {
              id: claimableRide.id,
              title: `${claimableRide.rideCategory.name} Ride`,
              subtitle: `${claimableRide.pickupLabel} -> ${claimableRide.dropoffLabel}`,
              status: claimableRide.status,
              amount: formatCurrency(toNumber(claimableRide.total)),
              meta: claimableRide.etaLabel ?? '',
            },
            'ride',
            'Accept Ride',
          ),
  };
}

async function buildDashboard(profile: {
  userId: string;
  accountId?: string | null;
  type: ProProfileType;
  activeModules: ProModule[];
  businessName?: string;
  bindings?: unknown;
}) {
  const todayStart = startOfToday();
  const bindings = normalizeBindings(profile.bindings);

  switch (profile.type) {
    case ProProfileType.SHOP: {
      const summaries = await Promise.all(
        profile.activeModules.map((module) => {
          switch (module) {
            case ProModule.SHOPPING:
              return buildShoppingSummary(
                todayStart,
                bindings,
                profile.businessName,
              );
            case ProModule.FOOD:
              return buildFoodSummary(todayStart, bindings, profile.businessName);
            case ProModule.PHARMACY:
              return buildPharmacySummary(
                todayStart,
                bindings,
                profile.businessName,
              );
            default:
              return Promise.resolve(null);
          }
        }),
      );

      const modules = summaries.filter(isPresent);
      const pendingTotal = modules.reduce((sum, item) => {
        const raw = item.metrics[1]?.split(' ')[0] ?? '0';
        return sum + Number(raw);
      }, 0);

      return {
        headline: 'Store operations',
        scopeNote:
          'This workspace is limited to the store, restaurant, and pharmacy businesses bound to this profile. If a module shows no business, update the business name so it matches the real listing.',
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
    case ProProfileType.PROVIDER: {
      const summaries = await Promise.all(
        profile.activeModules.map((module) => {
          switch (module) {
            case ProModule.SERVICES:
              return buildServicesSummary(todayStart, bindings);
            case ProModule.LAUNDRY:
              return buildLaundrySummary(todayStart, bindings);
            default:
              return Promise.resolve(null);
          }
        }),
      );

      const modules = summaries.filter(isPresent);
      const activeWork = modules.reduce((sum, item) => {
        const raw =
          item.module === 'services'
            ? item.metrics[2]?.split(' ')[0]
            : item.metrics[1]?.split(' ')[0];
        return sum + Number(raw ?? '0');
      }, 0);
      const completedWork = modules.reduce((sum, item) => {
        const raw =
          item.module === 'services'
            ? item.metrics[3]?.split(' ')[0]
            : item.metrics[2]?.split(' ')[0];
        return sum + Number(raw ?? '0');
      }, 0);

      return {
        headline: 'Provider operations',
        scopeNote:
          'Services are scoped to bound providers, and laundry now follows explicitly owned laundry services when claimed by this provider profile.',
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
    case ProProfileType.DOCTOR: {
      const summary = await buildDoctorSummary(todayStart, bindings);

      return {
        headline: 'Doctor operations',
        scopeNote:
          'Live appointment data is scoped to bound doctors when a match is found, with platform-wide fallback otherwise.',
        stats: [
          { key: 'patients', title: 'Patients today', value: summary.metrics[1].split(' ')[0] ?? '0' },
          { key: 'video', title: 'Video queue', value: summary.metrics[2].split(' ')[0] ?? '0' },
          { key: 'clinic', title: 'Available doctors', value: summary.metrics[0].split(' ')[0] ?? '0' },
          { key: 'notes', title: 'Upcoming consults', value: `${summary.recentItems.length}` },
        ],
        moduleSummaries: [summary],
      };
    }
    case ProProfileType.DELIVERY: {
      const summaries = await Promise.all(
        profile.activeModules.map((module) => {
          switch (module) {
            case ProModule.SHOPPING_DELIVERY:
              return buildDeliverySummary(
                module,
                ModuleType.SHOPPING,
                'Shopping Delivery',
                'Shopping order dispatch queue.',
                todayStart,
                profile.userId,
              );
            case ProModule.FOOD_DELIVERY:
              return buildDeliverySummary(
                module,
                ModuleType.FOOD,
                'Food Delivery',
                'Food pickup and delivery queue.',
                todayStart,
                profile.userId,
              );
            case ProModule.PHARMACY_DELIVERY:
              return buildDeliverySummary(
                module,
                ModuleType.PHARMACY,
                'Pharmacy Delivery',
                'Pharmacy dispatch queue.',
                todayStart,
                profile.userId,
              );
            default:
              return Promise.resolve(null);
          }
        }),
      );

      const modules = summaries.filter(isPresent);
      const highlighted =
        modules.find((module) => module.highlightedRequest != null)
          ?.highlightedRequest ?? null;
      const activeAssigned = modules.reduce(
        (sum, item) => sum + Number(item.metrics[0]?.split(' ')[0] ?? '0'),
        0,
      );
      const openQueue = modules.reduce(
        (sum, item) => sum + Number(item.metrics[2]?.split(' ')[0] ?? '0'),
        0,
      );
      const completedToday = modules.reduce(
        (sum, item) => sum + Number(item.metrics[1]?.split(' ')[0] ?? '0'),
        0,
      );

      return {
        headline: 'Delivery operations',
        scopeNote:
          'Assigned delivery work is scoped to this courier profile, with the next available request surfaced for claiming.',
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
    case ProProfileType.RIDER: {
      const summary = await buildRideSummary(todayStart, profile.userId);

      return {
        headline: 'Ride operations',
        scopeNote:
          'Assigned trips are scoped to this rider profile, with the next open ride request available to claim.',
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

router.post(
  '/:userId/claim-delivery',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = claimDeliverySchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.DELIVERY) {
      return res.status(404).json({ error: 'Delivery pro profile not found.' });
    }

    if (!profile.isOnline) {
      return res.status(403).json({ error: 'Turn online before claiming deliveries.' });
    }

    const allowedModuleTypes = profile.activeModules
      .map(deliveryModuleTypeForProfileModule)
      .filter(isPresent);

    const order = await prisma.order.findUnique({
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

    const updatedOrder = await prisma.order.update({
      where: { id: order.id },
      data: {
        deliveryUserId: userId,
        status:
          order.status === OrderStatus.PENDING ||
              order.status === OrderStatus.CONFIRMED ||
              order.status === OrderStatus.PROCESSING
            ? OrderStatus.DISPATCHED
            : order.status,
      },
      include: { items: true },
    });

    await notifyOrderLifecycle({
      userId: updatedOrder.userId,
      orderId: updatedOrder.id,
      moduleType: updatedOrder.moduleType,
      status: updatedOrder.status,
      event: 'claimed',
    });

    res.json({
      id: updatedOrder.id,
      moduleType: updatedOrder.moduleType,
      status: updatedOrder.status,
      deliveryUserId: updatedOrder.deliveryUserId,
    });
  }),
);

router.post(
  '/:userId/claim-ride',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = claimRideSchema.parse(req.body);
    const [profile, user] = await Promise.all([
      prisma.proProfile.findUnique({
        where: { userId },
      }),
      prisma.user.findUnique({
        where: { id: userId },
      }),
    ]);

    if (!profile || profile.type !== ProProfileType.RIDER) {
      return res.status(404).json({ error: 'Rider pro profile not found.' });
    }

    if (!profile.isOnline) {
      return res.status(403).json({ error: 'Turn online before claiming rides.' });
    }

    if (!profile.activeModules.includes(ProModule.RIDE)) {
      return res.status(400).json({ error: 'Ride module is not enabled for this profile.' });
    }

    const ride = await prisma.rideBooking.findUnique({
      where: { id: body.rideId },
      include: { rideCategory: true },
    });

    if (!ride) {
      return res.status(404).json({ error: 'Ride request not found.' });
    }

    if (ride.driverUserId && ride.driverUserId !== userId) {
      return res.status(409).json({ error: 'Ride request already claimed.' });
    }

    const driverName =
      user == null
        ? ride.driverName
        : `${user.firstName} ${user.lastName}`.trim();

    const updatedRide = await prisma.rideBooking.update({
      where: { id: ride.id },
      data: {
        driverUserId: userId,
        driverName: driverName || ride.driverName,
        driverPhone: user?.phone ?? ride.driverPhone,
        status:
          ride.status === RideStatus.REQUESTED ? RideStatus.ACCEPTED : ride.status,
      },
    });

    await notifyRideLifecycle({
      userId: updatedRide.userId,
      rideId: updatedRide.id,
      status: updatedRide.status,
      pickupLabel: updatedRide.pickupLabel,
      event: 'claimed',
    });

    res.json({
      id: updatedRide.id,
      status: updatedRide.status,
      driverUserId: updatedRide.driverUserId,
      driverName: updatedRide.driverName,
      driverPhone: updatedRide.driverPhone,
    });
  }),
);

router.post(
  '/:userId/delivery-status',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateDeliveryStatusSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.DELIVERY) {
      return res.status(404).json({ error: 'Delivery pro profile not found.' });
    }

    const order = await prisma.order.findUnique({
      where: { id: body.orderId },
    });

    if (!order || order.deliveryUserId !== userId) {
      return res.status(404).json({ error: 'Assigned delivery request not found.' });
    }

    const updatedOrder = await prisma.order.update({
      where: { id: order.id },
      data: { status: body.status },
    });

    await notifyOrderLifecycle({
      userId: updatedOrder.userId,
      orderId: updatedOrder.id,
      moduleType: updatedOrder.moduleType,
      status: updatedOrder.status,
      event: 'status',
    });

    res.json({
      id: updatedOrder.id,
      status: updatedOrder.status,
      deliveryUserId: updatedOrder.deliveryUserId,
    });
  }),
);

router.post(
  '/:userId/ride-status',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateRideStatusSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.RIDER) {
      return res.status(404).json({ error: 'Rider pro profile not found.' });
    }

    const ride = await prisma.rideBooking.findUnique({
      where: { id: body.rideId },
    });

    if (!ride || ride.driverUserId !== userId) {
      return res.status(404).json({ error: 'Assigned ride request not found.' });
    }

    const updatedRide = await prisma.rideBooking.update({
      where: { id: ride.id },
      data: { status: body.status },
    });

    await notifyRideLifecycle({
      userId: updatedRide.userId,
      rideId: updatedRide.id,
      status: updatedRide.status,
      pickupLabel: updatedRide.pickupLabel,
      event: 'status',
    });

    res.json({
      id: updatedRide.id,
      status: updatedRide.status,
      driverUserId: updatedRide.driverUserId,
    });
  }),
);

router.post(
  '/:userId/shop-order-status',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateShopOrderStatusSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const todayStart = startOfToday();
    const order = await prisma.order.findUnique({
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

    const updatedOrder = await prisma.order.update({
      where: { id: order.id },
      data: { status: body.status },
    });

    await notifyOrderLifecycle({
      userId: updatedOrder.userId,
      orderId: updatedOrder.id,
      moduleType: updatedOrder.moduleType,
      status: updatedOrder.status,
      event: 'status',
    });

    res.json({
      id: updatedOrder.id,
      status: updatedOrder.status,
      moduleType: updatedOrder.moduleType,
    });
  }),
);

router.post(
  '/:userId/provider-order-status',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateProviderOrderStatusSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const serviceProviders =
      bindings.providerIds.length === 0
        ? []
        : await prisma.homeServiceProvider.findMany({
            where: { id: { in: bindings.providerIds } },
            select: {
              id: true,
              isAvailable: true,
              availabilityJson: true,
            },
          });
    const order = await prisma.order.findUnique({
      where: { id: body.orderId },
      include: {
        address: {
          select: {
            latitude: true,
            longitude: true,
          },
        },
        items: {
          select: {
            id: true,
            externalRefId: true,
            metadata: true,
          },
        },
      },
    });

    if (!order) {
      return res.status(404).json({ error: 'Order not found.' });
    }

    const firstItem = order.items[0];
    if (order.status === body.status) {
      return res.json({
        id: order.id,
        status: order.status,
        moduleType: order.moduleType,
      });
    }
    const allowedTransitions = allowedProviderOrderTransitions(
      order.moduleType,
      order.status,
    );
    if (!allowedTransitions.includes(body.status)) {
      return res.status(409).json({
        error: `Invalid status transition from ${order.status} to ${body.status} for this booking.`,
      });
    }

    const firstItemMetadata =
      firstItem?.metadata &&
      typeof firstItem.metadata === 'object' &&
      !Array.isArray(firstItem.metadata)
        ? ({ ...firstItem.metadata } as Record<string, unknown>)
        : {};
    const assignedProviderId = assignedProviderIdFromMetadata(firstItemMetadata);
    const canAccessAssignedProvider =
      assignedProviderId != null && bindings.providerIds.includes(assignedProviderId);
    const canAccessDirectly = hasProviderOrderAccess(bindings, order);
    const canAccess = canAccessDirectly || canAccessAssignedProvider;

    const chooseEligibleProviderForZoneOrder = () => {
      const location = orderServiceLocation(order);
      if (location == null || serviceProviders.length === 0) return null;

      const candidates = serviceProviders
        .filter((provider) => provider.isAvailable)
        .map((provider) => {
          const zone = serviceZoneFromAvailabilityJson(provider.availabilityJson);
          if (
            !zone.enabled ||
            zone.centerLatitude == null ||
            zone.centerLongitude == null
          ) {
            return null;
          }
          const distanceKm = haversineDistanceKm(
            zone.centerLatitude,
            zone.centerLongitude,
            location.latitude,
            location.longitude,
          );
          if (
            distanceKm >
            effectiveServiceZoneRadiusKm(zone.radiusKm, order.moduleType)
          ) {
            return null;
          }
          return { providerId: provider.id, distanceKm };
        })
        .filter(
          (entry): entry is { providerId: string; distanceKm: number } =>
            entry != null,
        );
      candidates.sort((left, right) => left.distanceKm - right.distanceKm);
      return candidates.length === 0 ? null : candidates[0].providerId;
    };

    if (!canAccess) {
      const isZonePlaceholderExternalRef =
        firstItem?.externalRefId == null ||
        firstItem.externalRefId === 'house-help-zone';
      const isZonePlaceholderAssignedProvider =
        assignedProviderId == null || assignedProviderId === 'house-help-zone';
      const isZoneClaimCandidate =
        order.moduleType === ModuleType.HOUSE_HELP &&
        order.status === OrderStatus.PENDING &&
        body.status === OrderStatus.CONFIRMED &&
        isZonePlaceholderExternalRef &&
        isZonePlaceholderAssignedProvider;
      if (!isZoneClaimCandidate) {
        return res.status(403).json({ error: 'Order is not assigned to this provider profile.' });
      }

      const assignedByZone = chooseEligibleProviderForZoneOrder();
      if (assignedByZone == null || firstItem == null) {
        return res.status(403).json({
          error:
            'No provider in your configured service zone can claim this house-help request.',
        });
      }

      const nextMetadata = {
        ...firstItemMetadata,
        dispatchMode: 'ZONE_POOL',
        assignedProviderId: assignedByZone,
        providerId: assignedByZone,
        assignedAt: new Date().toISOString(),
      };

      const updatedOrder = await prisma.$transaction(async (tx) => {
        const updated = await tx.order.update({
          where: { id: order.id },
          data: { status: body.status },
        });
        await tx.orderItem.update({
          where: { id: firstItem.id },
          data: { metadata: nextMetadata },
        });
        return updated;
      });

      await notifyOrderLifecycle({
        userId: updatedOrder.userId,
        orderId: updatedOrder.id,
        moduleType: updatedOrder.moduleType,
        status: updatedOrder.status,
        event: 'status',
      });

      return res.json({
        id: updatedOrder.id,
        status: updatedOrder.status,
        moduleType: updatedOrder.moduleType,
      });
    }

    if (
      order.moduleType === ModuleType.HOUSE_HELP &&
      (firstItem?.externalRefId == null ||
        firstItem?.externalRefId === 'house-help-zone') &&
      (assignedProviderId == null ||
        assignedProviderId === 'house-help-zone') &&
      body.status !== OrderStatus.CONFIRMED
    ) {
      return res.status(409).json({
        error: 'This request must be accepted first before status updates.',
      });
    }

    const updatedOrder = await prisma.order.update({
      where: { id: order.id },
      data: { status: body.status },
    });

    await notifyOrderLifecycle({
      userId: updatedOrder.userId,
      orderId: updatedOrder.id,
      moduleType: updatedOrder.moduleType,
      status: updatedOrder.status,
      event: 'status',
    });

    res.json({
      id: updatedOrder.id,
      status: updatedOrder.status,
      moduleType: updatedOrder.moduleType,
    });
  }),
);

router.post(
  '/:userId/doctor-appointment-status',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateDoctorAppointmentStatusSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.DOCTOR) {
      return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }

    const bindings = normalizeBindings(profile.bindings);
    const appointment = await prisma.appointment.findUnique({
      where: { id: body.appointmentId },
    });

    if (!appointment) {
      return res.status(404).json({ error: 'Appointment not found.' });
    }

    if (
      bindings.doctorIds.length === 0 ||
      !bindings.doctorIds.includes(appointment.doctorId)
    ) {
      return res.status(403).json({ error: 'Appointment is not assigned to this doctor profile.' });
    }

    const updatedAppointment = await prisma.appointment.update({
      where: { id: appointment.id },
      data: { status: body.status },
    });

    await notifyAppointmentLifecycle({
      userId: updatedAppointment.userId,
      appointmentId: updatedAppointment.id,
      doctorId: updatedAppointment.doctorId,
      status: updatedAppointment.status,
    });

    res.json({
      id: updatedAppointment.id,
      status: updatedAppointment.status,
      doctorId: updatedAppointment.doctorId,
      appointmentAt: updatedAppointment.appointmentAt,
    });
  }),
);

router.get(
  '/:userId/shop-queue',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const canShopping = profile.activeModules.includes(ProModule.SHOPPING);
    const canFood = profile.activeModules.includes(ProModule.FOOD);
    const canPharmacy = profile.activeModules.includes(ProModule.PHARMACY);
    const [shoppingOrders, foodOrders, pharmacyCandidates] = await Promise.all([
      !canShopping || bindings.shoppingStoreIds.length === 0
        ? Promise.resolve([])
        : prisma.order.findMany({
            where: {
              moduleType: ModuleType.SHOPPING,
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
      !canFood || bindings.restaurantNames.length === 0
        ? Promise.resolve([])
        : prisma.order.findMany({
            where: {
              moduleType: ModuleType.FOOD,
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
      !canPharmacy
        ? Promise.resolve([])
        : prisma.order.findMany({
            where: { moduleType: ModuleType.PHARMACY },
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

    const pharmacyOrders =
      !canPharmacy || bindings.pharmacyBusinesses.length === 0
        ? []
        : pharmacyCandidates.filter((order) =>
            pharmacyOrderMatchesBindings(bindings, order.items),
          );

    const items = [...shoppingOrders, ...foodOrders, ...pharmacyOrders]
      .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime())
      .map((order) => serializeQueueOrderItem(order));

    res.json(items);
  }),
);

router.get(
  '/:userId/provider-queue',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const canServices = profile.activeModules.includes(ProModule.SERVICES);
    const canLaundry = profile.activeModules.includes(ProModule.LAUNDRY);
    const [serviceProviders, serviceCandidates, laundryOrders] = await Promise.all([
      !canServices || bindings.providerIds.length === 0
        ? Promise.resolve([])
        : prisma.homeServiceProvider.findMany({
            where: { id: { in: bindings.providerIds } },
            select: {
              id: true,
              isAvailable: true,
              availabilityJson: true,
            },
          }),
      !canServices
        ? Promise.resolve([])
        : prisma.order.findMany({
            where: {
              moduleType: {
                in: [ModuleType.HOME_SERVICES, ModuleType.HOUSE_HELP],
              },
              status: {
                in: [
                  OrderStatus.PENDING,
                  OrderStatus.CONFIRMED,
                  OrderStatus.IN_PROGRESS,
                  OrderStatus.PROCESSING,
                  OrderStatus.DISPATCHED,
                  OrderStatus.COMPLETED,
                ],
              },
            },
            include: {
              user: {
                select: { firstName: true, lastName: true, phone: true },
              },
              address: { select: { line1: true, latitude: true, longitude: true } },
              items: {
                include: {
                  product: {
                    select: { shopId: true, metadata: true },
                  },
                },
              },
            },
            orderBy: { createdAt: 'desc' },
            take: 200,
          }),
      !canLaundry || bindings.laundryServiceIds.length === 0
        ? Promise.resolve([])
        : prisma.order.findMany({
            where: {
              moduleType: ModuleType.LAUNDRY,
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
              address: { select: { line1: true, latitude: true, longitude: true } },
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

    const serviceItems = !canServices
      ? []
      : (() => {
          const providerLookup = new Map(
            serviceProviders.map((provider) => [provider.id, provider]),
          );
          const candidatesByOrderId = new Map<
            string,
            {
              order: (typeof serviceCandidates)[number];
              providerIdOverride?: string | null;
              queueType?: 'open' | 'assigned';
              distanceKm?: number | null;
            }
          >();

          const pickZoneProvider = (order: (typeof serviceCandidates)[number]) => {
            const location = orderServiceLocation(order);
            if (location == null) return null;
            const matches = Array.from(providerLookup.values())
              .filter((provider) => provider.isAvailable)
              .map((provider) => {
                const zone = serviceZoneFromAvailabilityJson(provider.availabilityJson);
                if (
                  !zone.enabled ||
                  zone.centerLatitude == null ||
                  zone.centerLongitude == null
                ) {
                  return null;
                }
                const distanceKm = haversineDistanceKm(
                  zone.centerLatitude,
                  zone.centerLongitude,
                  location.latitude,
                  location.longitude,
                );
                if (
                  distanceKm >
                  effectiveServiceZoneRadiusKm(zone.radiusKm, order.moduleType)
                ) {
                  return null;
                }
                return { providerId: provider.id, distanceKm };
              })
              .filter(
                (entry): entry is { providerId: string; distanceKm: number } =>
                  entry != null,
              );
            matches.sort((left, right) => left.distanceKm - right.distanceKm);
            return matches.length > 0 ? matches[0] : null;
          };

          for (const order of serviceCandidates) {
            const firstItem = order.items[0];
            const directProviderId = firstItem?.externalRefId;
            const assignedProviderId = assignedProviderIdFromMetadata(
              firstItem?.metadata,
            );

            if (order.moduleType === ModuleType.HOME_SERVICES) {
              if (
                directProviderId != null &&
                bindings.providerIds.includes(directProviderId)
              ) {
                candidatesByOrderId.set(order.id, {
                  order,
                  providerIdOverride: directProviderId,
                  queueType: 'assigned',
                });
              }
              continue;
            }

            if (
              directProviderId != null &&
              bindings.providerIds.includes(directProviderId)
            ) {
              candidatesByOrderId.set(order.id, {
                order,
                providerIdOverride: directProviderId,
                queueType: 'assigned',
              });
              continue;
            }

            if (
              assignedProviderId != null &&
              bindings.providerIds.includes(assignedProviderId)
            ) {
              candidatesByOrderId.set(order.id, {
                order,
                providerIdOverride: assignedProviderId,
                queueType: 'assigned',
              });
              continue;
            }

            if (order.status !== OrderStatus.PENDING) {
              continue;
            }

            const zoneCandidate = pickZoneProvider(order);
            if (zoneCandidate == null) continue;
            candidatesByOrderId.set(order.id, {
              order,
              providerIdOverride: zoneCandidate.providerId,
              queueType: 'open',
              distanceKm: zoneCandidate.distanceKm,
            });
          }

          return Array.from(candidatesByOrderId.values()).map((entry) =>
            serializeQueueOrderItem(entry.order, {
              providerIdOverride: entry.providerIdOverride,
              queueType: entry.queueType,
              distanceKm: entry.distanceKm,
            }),
          );
        })();

    const items = [
      ...serviceItems,
      ...laundryOrders.map((order) => serializeQueueOrderItem(order)),
    ].sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime());

    res.json(items);
  }),
);

router.get(
  '/:userId/doctor-appointments',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.DOCTOR) {
      return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }

    const bindings = normalizeBindings(profile.bindings);
    const appointments = await prisma.appointment.findMany({
      where:
        bindings.doctorIds.length === 0
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
  }),
);

router.get(
  '/:userId/doctor-home-care-appointments',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.DOCTOR) {
      return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }

    const bindings = normalizeBindings(profile.bindings);
    const appointments = await prisma.appointment.findMany({
      where: {
        ...(bindings.doctorIds.length === 0
          ? {}
          : { doctorId: { in: bindings.doctorIds } }),
        ...homeCareAppointmentFilter(),
      },
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
  }),
);

router.get(
  '/:userId/delivery-queue',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.DELIVERY) {
      return res.status(404).json({ error: 'Delivery pro profile not found.' });
    }

    const orders = await prisma.order.findMany({
      where: {
        moduleType: {
          in: [ModuleType.SHOPPING, ModuleType.FOOD, ModuleType.PHARMACY],
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

    res.json(
      orders.map((order) => serializeDispatchQueueOrderItem(order, userId)),
    );
  }),
);

router.get(
  '/:userId/ride-queue',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.RIDER) {
      return res.status(404).json({ error: 'Rider pro profile not found.' });
    }

    const rides = await prisma.rideBooking.findMany({
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
  }),
);

router.get(
  '/:userId/shop-availability',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const todayStart = startOfToday();
    const [
      stores,
      shoppingProducts,
      shoppingOrders,
      restaurants,
      restaurantMenuItems,
      foodOrders,
      allPharmacyProducts,
      pharmacyOrderCandidates,
    ] = await Promise.all([
      bindings.shoppingStoreIds.length === 0
        ? Promise.resolve([])
        : prisma.shoppingStore.findMany({
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
        : prisma.product.findMany({
            where: {
              moduleType: ModuleType.SHOPPING,
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
        : prisma.order.findMany({
            where: {
              moduleType: ModuleType.SHOPPING,
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
        : prisma.restaurant.findMany({
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
        : prisma.restaurantMenuItem.findMany({
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
        : prisma.order.findMany({
            where: {
              moduleType: ModuleType.FOOD,
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
      prisma.product.findMany({
        where: { moduleType: ModuleType.PHARMACY },
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
      prisma.order.findMany({
        where: { moduleType: ModuleType.PHARMACY },
        select: {
          status: true,
          updatedAt: true,
          items: {
            select: {
              productId: true,
              brand: true,
              metadata: true,
              product: {
                select: {
                  metadata: true,
                },
              },
            },
          },
        },
      }),
    ]);

    const pharmacyItems: typeof allPharmacyProducts =
      bindings.pharmacyBusinesses.length === 0
        ? []
        : allPharmacyProducts.filter((product) => {
            const metadata =
              product.metadata &&
              typeof product.metadata === 'object' &&
              !Array.isArray(product.metadata)
                ? (product.metadata as Record<string, unknown>)
                : null;
            const sourceBusiness = metadata?.sourceBusiness?.toString();
            return isBoundPharmacyBusiness(
              bindings.pharmacyBusinesses,
              sourceBusiness ?? null,
            );
          });

    const pharmacyOrders =
      bindings.pharmacyBusinesses.length === 0
        ? []
        : pharmacyOrderCandidates.filter((order) =>
            pharmacyOrderMatchesBindings(bindings, order.items),
          );

    const shoppingProductCountByStore = new Map<string, number>();
    const shoppingOutOfStockByStore = new Map<string, number>();
    for (const product of shoppingProducts) {
      if (!product.shopId) continue;
      shoppingProductCountByStore.set(
        product.shopId,
        (shoppingProductCountByStore.get(product.shopId) ?? 0) + 1,
      );
      if (!product.inStock) {
        shoppingOutOfStockByStore.set(
          product.shopId,
          (shoppingOutOfStockByStore.get(product.shopId) ?? 0) + 1,
        );
      }
    }

    const shoppingLiveOrdersByStore = new Map<string, number>();
    const shoppingCompletedTodayByStore = new Map<string, number>();
    for (const order of shoppingOrders) {
      const shopIds = new Set(
        order.items
          .map((item) => item.product?.shopId)
          .filter((value): value is string => Boolean(value)),
      );
      for (const shopId of shopIds) {
        if (liveOrderStatuses.includes(order.status)) {
          shoppingLiveOrdersByStore.set(
            shopId,
            (shoppingLiveOrdersByStore.get(shopId) ?? 0) + 1,
          );
        }
        if (
          order.status === OrderStatus.COMPLETED &&
          order.updatedAt >= todayStart
        ) {
          shoppingCompletedTodayByStore.set(
            shopId,
            (shoppingCompletedTodayByStore.get(shopId) ?? 0) + 1,
          );
        }
      }
    }

    const restaurantMenuCountById = new Map<string, number>();
    const restaurantUnavailableCountById = new Map<string, number>();
    for (const item of restaurantMenuItems) {
      const restaurantId = item.category.restaurantId;
      restaurantMenuCountById.set(
        restaurantId,
        (restaurantMenuCountById.get(restaurantId) ?? 0) + 1,
      );
      if (!item.isAvailable) {
        restaurantUnavailableCountById.set(
          restaurantId,
          (restaurantUnavailableCountById.get(restaurantId) ?? 0) + 1,
        );
      }
    }

    const foodLiveOrdersByRestaurant = new Map<string, number>();
    const foodCompletedTodayByRestaurant = new Map<string, number>();
    const restaurantIdByName = new Map(
      restaurants.map((restaurant) => [restaurant.name, restaurant.id] as const),
    );
    for (const order of foodOrders) {
      const restaurantIds = new Set(
        order.items
          .map((item) => item.brand)
          .filter((value): value is string => Boolean(value))
          .map((brand) => restaurantIdByName.get(brand))
          .filter((value): value is string => Boolean(value)),
      );
      for (const restaurantId of restaurantIds) {
        if (liveOrderStatuses.includes(order.status)) {
          foodLiveOrdersByRestaurant.set(
            restaurantId,
            (foodLiveOrdersByRestaurant.get(restaurantId) ?? 0) + 1,
          );
        }
        if (
          order.status === OrderStatus.COMPLETED &&
          order.updatedAt >= todayStart
        ) {
          foodCompletedTodayByRestaurant.set(
            restaurantId,
            (foodCompletedTodayByRestaurant.get(restaurantId) ?? 0) + 1,
          );
        }
      }
    }

    const pharmacyBusinessNames = Array.from(
      new Set(
        pharmacyItems
          .map((product) => {
            const metadata =
              product.metadata &&
              typeof product.metadata === 'object' &&
              !Array.isArray(product.metadata)
                ? (product.metadata as Record<string, unknown>)
                : null;
            return metadata?.sourceBusiness?.toString();
          })
          .filter((value): value is string => Boolean(value)),
      ),
    );
    const pharmacyLiveOrderCount = pharmacyOrders.filter((order) =>
      liveOrderStatuses.includes(order.status),
    ).length;
    const pharmacyCompletedTodayCount = pharmacyOrders.filter(
      (order) =>
        order.status === OrderStatus.COMPLETED && order.updatedAt >= todayStart,
    ).length;
    const pharmacyOutOfStockCount = pharmacyItems.filter(
      (product) => !product.inStock,
    ).length;
    const pharmacyPrescriptionCount = pharmacyItems.filter(
      (product) => product.requiresPrescription,
    ).length;

    const shoppingManagedCount = stores.length;
    const shoppingActiveCount = stores.filter((store) => store.isOpen).length;
    const shoppingLiveListingCount = shoppingProducts.filter(
      (product) => product.inStock,
    ).length;
    const shoppingAttentionCount = shoppingProducts.filter(
      (product) => !product.inStock,
    ).length;

    const foodManagedCount = restaurants.length;
    const foodActiveCount = restaurants.filter((restaurant) => restaurant.isOpen).length;
    const foodLiveListingCount = restaurantMenuItems.filter(
      (item) => item.isAvailable,
    ).length;
    const foodAttentionCount = restaurantMenuItems.filter(
      (item) => !item.isAvailable,
    ).length;
    const shoppingOrdersInProgress = Array.from(
      shoppingLiveOrdersByStore.values(),
    ).reduce((sum, count) => sum + count, 0);
    const foodOrdersInProgress = Array.from(
      foodLiveOrdersByRestaurant.values(),
    ).reduce((sum, count) => sum + count, 0);

    res.json({
      shoppingSummary: {
        title: 'Shopping storefront',
        hasBindings: shoppingManagedCount > 0,
        managedCount: shoppingManagedCount,
        subtitle: shoppingManagedCount == 1
            ? '1 retail store connected'
            : `${shoppingManagedCount} retail stores connected`,
        emptyStateMessage:
            shoppingManagedCount == 0
                ? 'No shopping store is bound to this shop profile yet.'
                : 'Your shopping store is connected, but no storefront records are available right now.',
        metrics: [
          {'label': 'Open stores', 'value': `${shoppingActiveCount}`},
          {'label': 'Live listings', 'value': `${shoppingLiveListingCount}`},
          {'label': 'Need attention', 'value': `${shoppingAttentionCount}`},
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
        detail: `${shoppingProductCountByStore.get(store.id) ?? 0} live items • ${shoppingOutOfStockByStore.get(store.id) ?? 0} out of stock`,
        metrics: [
          `${shoppingLiveOrdersByStore.get(store.id) ?? 0} orders in progress`,
          `${shoppingCompletedTodayByStore.get(store.id) ?? 0} completed today`,
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
        emptyStateMessage:
            foodManagedCount == 0
                ? 'No restaurant is bound to this shop profile yet.'
                : 'Your restaurant is connected, but no menu records are available right now.',
        metrics: [
          {'label': 'Open restaurants', 'value': `${foodActiveCount}`},
          {'label': 'Available dishes', 'value': `${foodLiveListingCount}`},
          {'label': 'Need attention', 'value': `${foodAttentionCount}`},
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
        detail: `${restaurantMenuCountById.get(restaurant.id) ?? 0} menu items • ${restaurantUnavailableCountById.get(restaurant.id) ?? 0} unavailable`,
        metrics: [
          `${foodLiveOrdersByRestaurant.get(restaurant.id) ?? 0} orders in progress`,
          `${foodCompletedTodayByRestaurant.get(restaurant.id) ?? 0} completed today`,
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
                : `${pharmacyBusinessNames.length} pharmacy businesses connected`,
        emptyStateMessage:
            pharmacyBusinessNames.length === 0
                ? 'No pharmacy business is bound to this shop profile yet.'
                : 'Your pharmacy is connected, but no medicines are listed yet.',
        metrics: [
          {'label': 'Listed medicines', 'value': `${pharmacyItems.length}`},
          {'label': 'Prescription items', 'value': `${pharmacyPrescriptionCount}`},
          {'label': 'Need attention', 'value': `${pharmacyOutOfStockCount}`},
          {'label': 'Orders in progress', 'value': `${pharmacyLiveOrderCount}`},
        ],
      },
      pharmacy: pharmacyItems.map((product) => {
        const metadata =
          product.metadata &&
          typeof product.metadata === 'object' &&
          !Array.isArray(product.metadata)
            ? (product.metadata as Record<string, unknown>)
            : null;
        const sourceBusiness =
          metadata?.sourceBusiness?.toString() ?? 'Pharmacy';

        return {
          id: product.id,
          name: product.name,
          enabled: product.inStock,
          subtitle: product.category?.name ?? 'Medicine',
          detail: `${formatCurrency(toNumber(product.price))} • ${
            product.requiresPrescription
              ? 'Prescription required'
              : 'Over the counter'
          }`,
          metrics: [
            sourceBusiness,
            '$pharmacyCompletedTodayCount completed today',
          ],
        };
      }),
    });
  }),
);

router.post(
  '/:userId/shopping-store',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = createShoppingStoreSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    if (!profile.activeModules.includes(ProModule.SHOPPING)) {
      return res.status(400).json({
        error: 'Shopping is not enabled for this shop profile.',
      });
    }

    const storeName = body.name?.trim() || profile.businessName.trim();
    const matchingStore = await prisma.shoppingStore.findFirst({
      where: {
        name: {
          equals: storeName,
          mode: 'insensitive',
        },
      },
    });

    const store =
      matchingStore ??
      (await (async () => {
        const slug = await ensureUniqueSlug(
          storeName || `store-${userId.slice(-6)}`,
          async (candidate) =>
            Boolean(
              await prisma.shoppingStore.findUnique({
                where: { slug: candidate },
                select: { id: true },
              }),
            ),
        );

        return prisma.shoppingStore.create({
          data: {
            id: randomUUID(),
            name: storeName,
            slug,
            tagline: body.tagline?.trim() || 'New store on EdaLab',
            description: body.description?.trim() || null,
            imageUrl: body.imageUrl?.trim() || null,
            isOpen: true,
          },
        });
      })());

    if (matchingStore) {
      await prisma.shoppingStore.update({
        where: { id: matchingStore.id },
        data: {
          tagline: body.tagline?.trim() || matchingStore.tagline,
          description: body.description?.trim() || matchingStore.description,
          imageUrl: body.imageUrl?.trim() || matchingStore.imageUrl,
        },
      });
    }

    const resolvedBindings = await resolveBindings(
      profile.businessName,
      profile.activeModules,
    );
    const ownedLaundryServiceIds = await syncLaundryOwnership(
      profile.userId,
      profile.type,
      profile.activeModules,
      resolvedBindings,
    );
    const bindings = {
      ...resolvedBindings,
      laundryServiceIds: ownedLaundryServiceIds,
      shoppingStoreIds: Array.from(
        new Set([...resolvedBindings.shoppingStoreIds, store.id]),
      ),
    };

    await prisma.proProfile.update({
      where: { userId },
      data: {
        bindings,
      },
    });

    res.status(matchingStore ? 200 : 201).json({
      id: store.id,
      slug: store.slug,
      name: store.name,
      created: matchingStore == null,
      bindings,
    });
  }),
);

router.post(
  '/:userId/restaurant',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = createRestaurantSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    if (!profile.activeModules.includes(ProModule.FOOD)) {
      return res.status(400).json({
        error: 'Food is not enabled for this shop profile.',
      });
    }

    const restaurantName = body.name?.trim() || profile.businessName.trim();
    const matchingRestaurant = await prisma.restaurant.findFirst({
      where: {
        name: {
          equals: restaurantName,
          mode: 'insensitive',
        },
      },
    });

    const restaurant =
      matchingRestaurant ??
      (await prisma.restaurant.create({
        data: {
          id: randomUUID(),
          name: restaurantName,
          cuisine: body.cuisine?.trim() || 'General',
          imageUrl: body.imageUrl?.trim() || null,
          isOpen: true,
        },
      }));

    if (matchingRestaurant) {
      const nextCuisine = body.cuisine?.trim();
      const shouldUpdateCuisine =
        nextCuisine != null &&
        nextCuisine.length > 0 &&
        nextCuisine !== matchingRestaurant.cuisine;
      const shouldUpdateImage = body.imageUrl != null;

      if (shouldUpdateCuisine || shouldUpdateImage) {
        await prisma.restaurant.update({
          where: { id: matchingRestaurant.id },
          data: {
            cuisine: shouldUpdateCuisine ? nextCuisine : undefined,
            imageUrl:
              shouldUpdateImage ? body.imageUrl?.trim() || null : undefined,
          },
        });
      }
    }

    const resolvedBindings = await resolveBindings(
      profile.businessName,
      profile.activeModules,
    );
    const ownedLaundryServiceIds = await syncLaundryOwnership(
      profile.userId,
      profile.type,
      profile.activeModules,
      resolvedBindings,
    );
    const bindings = {
      ...resolvedBindings,
      laundryServiceIds: ownedLaundryServiceIds,
      restaurantIds: Array.from(
        new Set([...resolvedBindings.restaurantIds, restaurant.id]),
      ),
      restaurantNames: Array.from(
        new Set([...resolvedBindings.restaurantNames, restaurant.name]),
      ),
    };

    await prisma.proProfile.update({
      where: { userId },
      data: {
        bindings,
      },
    });

    res.status(matchingRestaurant ? 200 : 201).json({
      id: restaurant.id,
      name: restaurant.name,
      created: matchingRestaurant == null,
      bindings,
    });
  }),
);

router.post(
  '/:userId/pharmacy-business',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = createPharmacyBusinessSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    if (!profile.activeModules.includes(ProModule.PHARMACY)) {
      return res.status(400).json({
        error: 'Pharmacy is not enabled for this shop profile.',
      });
    }

    const businessName = body.name?.trim() || profile.businessName.trim();
    const resolvedBindings = await resolveBindings(
      profile.businessName,
      profile.activeModules,
    );
    const ownedLaundryServiceIds = await syncLaundryOwnership(
      profile.userId,
      profile.type,
      profile.activeModules,
      resolvedBindings,
    );
    const bindings = {
      ...resolvedBindings,
      laundryServiceIds: ownedLaundryServiceIds,
      pharmacyBusinesses: Array.from(
        new Set([...resolvedBindings.pharmacyBusinesses, businessName]),
      ),
    };

    await prisma.proProfile.update({
      where: { userId },
      data: {
        bindings,
      },
    });

    res.status(201).json({
      name: businessName,
      created: true,
      bindings,
    });
  }),
);

router.post(
  '/:userId/home-service-provider',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = createHomeServiceProviderSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    if (!profile.activeModules.includes(ProModule.SERVICES)) {
      return res.status(400).json({
        error: 'Services is not enabled for this provider profile.',
      });
    }

    const activeCategories = await prisma.homeServiceCategory.findMany({
      where: { active: true },
      select: { id: true, name: true, slug: true, colorHex: true, iconKey: true },
      orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
    });
    if (activeCategories.length == 0) {
      return res.status(400).json({ error: 'No active home-service categories found.' });
    }

    const fallbackCategory =
      activeCategories.find((category) => category.slug === 'house-help') ??
      activeCategories[0];
    const selectedCategory =
      body.categoryId == null
        ? fallbackCategory
        : activeCategories.find((category) => category.id === body.categoryId);
    if (!selectedCategory) {
      return res.status(400).json({ error: 'Selected home-service category is invalid.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const existingBindings = normalizeBindings(hydratedProfile.bindings);
    const providerName = body.name?.trim() || profile.businessName.trim();
    const existingProvider =
      existingBindings.providerIds.length === 0
        ? null
        : await prisma.homeServiceProvider.findFirst({
            where: {
              id: { in: existingBindings.providerIds },
              categoryId: selectedCategory.id,
              name: {
                equals: providerName,
                mode: 'insensitive',
              },
            },
            select: {
              id: true,
              title: true,
              yearsExperience: true,
              responseTime: true,
              location: true,
              contactPhone: true,
              about: true,
              imageUrl: true,
              startingPrice: true,
              servicesJson: true,
              highlightsJson: true,
              bookingModesJson: true,
              availabilityJson: true,
            },
          });

    const defaultBookingModes = ['Home Visit'];
    const serviceZoneInput = isHouseHelpCategorySlug(selectedCategory.slug)
      ? capServiceZoneRadiusForHouseHelp(body.serviceZone)
      : body.serviceZone;
    const baseAvailability = {
      weekdays: '08:00 AM - 06:00 PM',
      saturday: '09:00 AM - 02:00 PM',
      sunday: 'Closed',
      serviceZone: {
        enabled: true,
        centerLatitude: 11.5886,
        centerLongitude: 43.1457,
        radiusKm: 1,
      },
      houseHelpConfig: defaultHouseHelpConfig(),
    };
    const defaultAvailability = normalizeProviderAvailabilityJson({
      current: baseAvailability,
      serviceZone: serviceZoneInput,
      houseHelpConfig: body.houseHelpConfig,
    });
    const providerId = existingProvider?.id ?? randomUUID();
    const provider = await prisma.homeServiceProvider.upsert({
      where: { id: providerId },
      update: {
        title: body.title?.trim() || existingProvider?.title || selectedCategory.name,
        yearsExperience:
          body.yearsExperience == null
            ? existingProvider?.yearsExperience
            : body.yearsExperience.trim() || null,
        startingPrice: new Prisma.Decimal(
          body.startingPrice ?? toNumber(existingProvider?.startingPrice) ?? 25,
        ),
        responseTime:
          body.responseTime == null
            ? existingProvider?.responseTime
            : body.responseTime.trim() || null,
        location:
          body.location == null ? existingProvider?.location : body.location.trim() || null,
        contactPhone:
          body.contactPhone == null
            ? existingProvider?.contactPhone
            : body.contactPhone.trim() || null,
        about: body.about == null ? existingProvider?.about : body.about.trim() || null,
        imageUrl:
          body.imageUrl == null ? existingProvider?.imageUrl : body.imageUrl.trim() || null,
        servicesJson:
          body.services == null
            ? (existingProvider?.servicesJson ?? undefined)
            : normalizeStringList(body.services),
        highlightsJson:
          body.highlights == null
            ? (existingProvider?.highlightsJson ?? undefined)
            : normalizeStringList(body.highlights),
        bookingModesJson:
          existingProvider?.bookingModesJson == null
            ? defaultBookingModes
            : existingProvider.bookingModesJson,
        availabilityJson:
          normalizeProviderAvailabilityJson({
            current: existingProvider?.availabilityJson ?? defaultAvailability,
            serviceZone: serviceZoneInput,
            houseHelpConfig: body.houseHelpConfig,
          }),
        isAvailable: true,
      },
      create: {
        id: providerId,
        categoryId: selectedCategory.id,
        name: providerName,
        title: body.title?.trim() || selectedCategory.name,
        startingPrice: new Prisma.Decimal(body.startingPrice ?? 25),
        yearsExperience: body.yearsExperience?.trim() || null,
        responseTime: body.responseTime?.trim() || null,
        location: body.location?.trim() || null,
        contactPhone: body.contactPhone?.trim() || null,
        about: body.about?.trim() || null,
        imageUrl: body.imageUrl?.trim() || null,
        isAvailable: true,
        isVerified: false,
        servicesJson: normalizeStringList(body.services ?? []),
        highlightsJson: normalizeStringList(body.highlights ?? []),
        bookingModesJson: defaultBookingModes,
        availabilityJson: defaultAvailability,
      },
      select: {
        id: true,
        categoryId: true,
        name: true,
        title: true,
      },
    });

    const ownedLaundryServiceIds = await syncLaundryOwnership(
      profile.userId,
      profile.type,
      profile.activeModules,
      existingBindings,
    );
    const bindings = {
      ...existingBindings,
      laundryServiceIds: ownedLaundryServiceIds,
      providerIds: mergeStringLists(existingBindings.providerIds, [provider.id]),
    };

    await prisma.proProfile.update({
      where: { userId },
      data: { bindings },
    });

    res.status(existingProvider == null ? 201 : 200).json({
      id: provider.id,
      name: provider.name,
      title: provider.title,
      categoryId: provider.categoryId,
      created: existingProvider == null,
      bindings,
    });
  }),
);

router.post(
  '/:userId/shopping-products',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = createShoppingProductSchema.parse(req.body);
    const requestedModule = body.module === 'pharmacy' ? 'pharmacy' : 'shopping';
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    let moduleType: ModuleType;
    let shopId: string | null = null;
    let sourceBusiness: string;

    if (requestedModule === 'pharmacy') {
      if (!profile.activeModules.includes(ProModule.PHARMACY)) {
        return res.status(400).json({
          error: 'Pharmacy is not enabled for this shop profile.',
        });
      }
      if (bindings.pharmacyBusinesses.length === 0) {
        return res.status(400).json({
          error: 'No pharmacy business is bound to this shop profile yet.',
        });
      }
      const requestedBusiness = body.businessName?.trim() ?? '';
      const preferredBusiness =
        requestedBusiness.length > 0
          ? requestedBusiness
          : bindings.pharmacyBusinesses[0];
      const preferredNormalized = normalizeComparableText(preferredBusiness);
      const boundBusiness = bindings.pharmacyBusinesses.find(
        (value) => normalizeComparableText(value) === preferredNormalized,
      );
      if (!boundBusiness) {
        return res.status(403).json({
          error: 'Pharmacy business is not assigned to this shop profile.',
        });
      }
      moduleType = ModuleType.PHARMACY;
      sourceBusiness = boundBusiness;
    } else {
      if (!profile.activeModules.includes(ProModule.SHOPPING)) {
        return res.status(400).json({
          error: 'Shopping is not enabled for this shop profile.',
        });
      }
      if (!body.storeId || body.storeId.trim().length === 0) {
        return res.status(400).json({ error: 'Store is required.' });
      }
      const store = await prisma.shoppingStore.findUnique({
        where: { id: body.storeId },
        select: {
          id: true,
          name: true,
        },
      });

      if (!store) {
        return res.status(404).json({ error: 'Shopping store not found.' });
      }
      if (
        bindings.shoppingStoreIds.length === 0 ||
        !bindings.shoppingStoreIds.includes(store.id)
      ) {
        return res.status(403).json({
          error: 'Store is not assigned to this shop profile.',
        });
      }
      moduleType = ModuleType.SHOPPING;
      shopId = store.id;
      sourceBusiness = store.name;
    }

    const categorySlug = await ensureUniqueSlug(
      `${body.categoryName.trim()}-${moduleType.toLowerCase()}`,
      async (candidate) =>
        Boolean(
          await prisma.productCategory.findUnique({
            where: { slug: candidate },
            select: { id: true },
          }),
        ),
    );

    const existingCategory = await prisma.productCategory.findFirst({
      where: {
        moduleType,
        name: {
          equals: body.categoryName.trim(),
          mode: 'insensitive',
        },
      },
    });

    const category =
      existingCategory ??
      (await prisma.productCategory.create({
        data: {
          id: randomUUID(),
          moduleType,
          name: body.categoryName.trim(),
          slug: categorySlug,
          active: true,
        },
      }));

    const primaryImageUrl = body.imageUrl?.trim() ?? '';
    const galleryImageUrls = (body.imageUrls ?? [])
      .map((value) => value.trim())
      .filter((value) => value.length > 0);
    const imageUrls = Array.from(
      new Set([
        ...galleryImageUrls,
        ...(primaryImageUrl.length > 0 ? [primaryImageUrl] : []),
      ]),
    );
    const normalizeTextArray = (values?: string[]) =>
      (values ?? [])
        .map((value) => value.trim())
        .filter((value) => value.length > 0);

    const colors = normalizeTextArray(body.colors);
    const sizes = normalizeTextArray(body.sizes);
    const tags = normalizeTextArray(body.tags);
    const features = normalizeTextArray(body.features);
    const normalizedBrand = body.brand?.trim() || sourceBusiness;
    const normalizedBadge = body.badge?.trim() || null;

    const product = await prisma.product.create({
      data: {
        id: randomUUID(),
        moduleType,
        categoryId: category.id,
        shopId,
        name: body.name.trim(),
        brand: normalizedBrand,
        description: body.description.trim(),
        price: body.price,
        originalPrice: body.originalPrice ?? null,
        unit: body.unit?.trim() || null,
        imageUrlsJson: imageUrls,
        colorsJson: colors.length > 0 ? colors : undefined,
        sizesJson: sizes.length > 0 ? sizes : undefined,
        tagsJson: tags.length > 0 ? tags : undefined,
        featuresJson: features.length > 0 ? features : undefined,
        badge: normalizedBadge,
        dosage: body.dosage?.trim() || null,
        packageSize: body.packageSize?.trim() || null,
        requiresPrescription: body.requiresPrescription ?? false,
        inStock: body.inStock ?? true,
        isOrganic: body.isOrganic ?? false,
        metadata: {
          source: 'shop_dashboard',
          ...(shopId ? { shopId } : {}),
          shopName: sourceBusiness,
          sourceBusiness,
          categoryName: category.name,
          createdByProProfile: userId,
        },
      },
    });

    if (shopId != null) {
      const storeProducts = await prisma.product.findMany({
        where: {
          moduleType: ModuleType.SHOPPING,
          shopId,
        },
        select: {
          price: true,
        },
      });
      const prices = storeProducts
        .map((entry) => toNumber(entry.price))
        .filter((value): value is number => value != null);

      await prisma.shoppingStore.update({
        where: { id: shopId },
        data: {
          minPrice: prices.length === 0 ? null : Math.min(...prices),
          maxPrice: prices.length === 0 ? null : Math.max(...prices),
        },
      });
    }

    res.status(201).json({
      id: product.id,
      module: requestedModule,
      name: product.name,
      shopId: product.shopId,
      businessName: sourceBusiness,
      category: category.name,
      price: toNumber(product.price),
      dosage: product.dosage,
      packageSize: product.packageSize,
      requiresPrescription: product.requiresPrescription,
      inStock: product.inStock,
    });
  }),
);

router.get(
  '/:userId/shopping-products',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const requestedStoreId = req.query.storeId?.toString().trim();
    const requestedModuleRaw = req.query.module?.toString().trim().toLowerCase();
    const requestedModule =
      requestedModuleRaw === 'pharmacy' ? 'pharmacy' : 'shopping';
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    if (requestedModule === 'pharmacy') {
      if (!profile.activeModules.includes(ProModule.PHARMACY)) {
        return res.status(400).json({
          error: 'Pharmacy is not enabled for this shop profile.',
        });
      }
      if (bindings.pharmacyBusinesses.length === 0) {
        return res.json({
          module: requestedModule,
          stores: [],
          products: [],
        });
      }

      let allowedBusinesses = bindings.pharmacyBusinesses;
      if (requestedStoreId && requestedStoreId.length > 0) {
        const normalizedRequested = normalizeComparableText(requestedStoreId);
        const matchedBusiness = bindings.pharmacyBusinesses.find(
          (value) => normalizeComparableText(value) === normalizedRequested,
        );
        if (!matchedBusiness) {
          return res.status(403).json({
            error: 'Pharmacy business is not assigned to this shop profile.',
          });
        }
        allowedBusinesses = [matchedBusiness];
      }

      const allowedBusinessSet = new Set(
        allowedBusinesses.map((value) => normalizeComparableText(value)),
      );
      const productsRaw = await prisma.product.findMany({
        where: {
          moduleType: ModuleType.PHARMACY,
        },
        select: {
          id: true,
          name: true,
          brand: true,
          description: true,
          price: true,
          originalPrice: true,
          inStock: true,
          unit: true,
          badge: true,
          dosage: true,
          packageSize: true,
          requiresPrescription: true,
          imageUrlsJson: true,
          metadata: true,
          createdAt: true,
          updatedAt: true,
          category: {
            select: {
              name: true,
            },
          },
        },
        orderBy: [{ updatedAt: 'desc' }],
      });

      const products = productsRaw
        .map((product) => {
          const metadata =
            product.metadata &&
            typeof product.metadata === 'object' &&
            !Array.isArray(product.metadata)
              ? (product.metadata as Record<string, unknown>)
              : null;
          const sourceBusiness = metadata?.sourceBusiness?.toString().trim() ?? '';
          return { product, sourceBusiness };
        })
        .filter(
          ({ sourceBusiness }) =>
            sourceBusiness.length > 0 &&
            allowedBusinessSet.has(normalizeComparableText(sourceBusiness)),
        );

      const productCountByBusiness = new Map<string, number>();
      for (const { sourceBusiness } of products) {
        const key = normalizeComparableText(sourceBusiness);
        productCountByBusiness.set(
          key,
          (productCountByBusiness.get(key) ?? 0) + 1,
        );
      }

      return res.json({
        module: requestedModule,
        stores: allowedBusinesses.map((business) => ({
          id: business,
          name: business,
          isOpen: true,
          productCount:
            productCountByBusiness.get(normalizeComparableText(business)) ?? 0,
        })),
        products: products.map(({ product, sourceBusiness }) => ({
          id: product.id,
          storeId: sourceBusiness,
          storeName: sourceBusiness,
          name: product.name,
          brand: product.brand,
          description: product.description,
          categoryName: product.category?.name ?? 'Medicine',
          price: toNumber(product.price),
          originalPrice: toNumber(product.originalPrice),
          inStock: product.inStock,
          unit: product.unit,
          badge: product.badge,
          dosage: product.dosage,
          packageSize: product.packageSize,
          requiresPrescription: product.requiresPrescription,
          imageUrl: firstImageUrlFromJson(product.imageUrlsJson),
          createdAt: product.createdAt,
          updatedAt: product.updatedAt,
        })),
      });
    }

    if (!profile.activeModules.includes(ProModule.SHOPPING)) {
      return res.status(400).json({
        error: 'Shopping is not enabled for this shop profile.',
      });
    }
    if (bindings.shoppingStoreIds.length === 0) {
      return res.json({
        module: requestedModule,
        stores: [],
        products: [],
      });
    }
    if (
      requestedStoreId &&
      requestedStoreId.length > 0 &&
      !bindings.shoppingStoreIds.includes(requestedStoreId)
    ) {
      return res
        .status(403)
        .json({ error: 'Store is not assigned to this shop profile.' });
    }

    const allowedStoreIds =
      requestedStoreId && requestedStoreId.length > 0
        ? [requestedStoreId]
        : bindings.shoppingStoreIds;
    const [stores, products] = await Promise.all([
      prisma.shoppingStore.findMany({
        where: { id: { in: bindings.shoppingStoreIds } },
        select: {
          id: true,
          name: true,
          isOpen: true,
        },
        orderBy: { name: 'asc' },
      }),
      prisma.product.findMany({
        where: {
          moduleType: ModuleType.SHOPPING,
          shopId: { in: allowedStoreIds },
        },
        select: {
          id: true,
          shopId: true,
          name: true,
          brand: true,
          description: true,
          price: true,
          originalPrice: true,
          inStock: true,
          unit: true,
          badge: true,
          dosage: true,
          packageSize: true,
          requiresPrescription: true,
          imageUrlsJson: true,
          createdAt: true,
          updatedAt: true,
          category: {
            select: {
              name: true,
            },
          },
        },
        orderBy: [{ updatedAt: 'desc' }],
      }),
    ]);

    const storeNameById = new Map(stores.map((store) => [store.id, store.name]));
    const productCountByStoreId = new Map<string, number>();
    for (const product of products) {
      const storeId = product.shopId;
      if (!storeId) continue;
      productCountByStoreId.set(
        storeId,
        (productCountByStoreId.get(storeId) ?? 0) + 1,
      );
    }

    res.json({
      module: requestedModule,
      stores: stores.map((store) => ({
        id: store.id,
        name: store.name,
        isOpen: store.isOpen,
        productCount: productCountByStoreId.get(store.id) ?? 0,
      })),
      products: products.map((product) => ({
        id: product.id,
        storeId: product.shopId,
        storeName: product.shopId ? storeNameById.get(product.shopId) : null,
        name: product.name,
        brand: product.brand,
        description: product.description,
        categoryName: product.category?.name ?? 'General',
        price: toNumber(product.price),
        originalPrice: toNumber(product.originalPrice),
        inStock: product.inStock,
        unit: product.unit,
        badge: product.badge,
        dosage: product.dosage,
        packageSize: product.packageSize,
        requiresPrescription: product.requiresPrescription,
        imageUrl: firstImageUrlFromJson(product.imageUrlsJson),
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      })),
    });
  }),
);

router.patch(
  '/:userId/shopping-products/:productId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const productId = getParam(req.params.productId, 'productId');
    const body = updateShoppingProductStockSchema.parse(req.body);
    const requestedModule = body.module === 'pharmacy' ? 'pharmacy' : 'shopping';
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    if (
      requestedModule === 'pharmacy' &&
      !profile.activeModules.includes(ProModule.PHARMACY)
    ) {
      return res.status(400).json({
        error: 'Pharmacy is not enabled for this shop profile.',
      });
    }
    if (
      requestedModule === 'shopping' &&
      !profile.activeModules.includes(ProModule.SHOPPING)
    ) {
      return res.status(400).json({
        error: 'Shopping is not enabled for this shop profile.',
      });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const product = await prisma.product.findUnique({
      where: { id: productId },
      select: {
        id: true,
        moduleType: true,
        shopId: true,
        metadata: true,
      },
    });

    const expectedModuleType =
      requestedModule === 'pharmacy' ? ModuleType.PHARMACY : ModuleType.SHOPPING;
    if (!product || product.moduleType !== expectedModuleType) {
      return res.status(404).json({
        error:
          requestedModule === 'pharmacy'
            ? 'Pharmacy medicine not found.'
            : 'Shopping product not found.',
      });
    }

    if (requestedModule === 'pharmacy') {
      const metadata =
        product.metadata &&
        typeof product.metadata === 'object' &&
        !Array.isArray(product.metadata)
          ? (product.metadata as Record<string, unknown>)
          : null;
      const sourceBusiness = metadata?.sourceBusiness?.toString().trim() ?? '';
      const isBound =
        sourceBusiness.length > 0 &&
        bindings.pharmacyBusinesses.some(
          (value) =>
            normalizeComparableText(value) ===
            normalizeComparableText(sourceBusiness),
        );
      if (!isBound) {
        return res
          .status(403)
          .json({ error: 'Medicine is not assigned to this shop profile.' });
      }
    } else if (
      !product.shopId ||
      !bindings.shoppingStoreIds.includes(product.shopId)
    ) {
      return res
        .status(403)
        .json({ error: 'Product is not assigned to this shop profile.' });
    }

    const updated = await prisma.product.update({
      where: { id: product.id },
      data: {
        inStock: body.inStock,
      },
      select: {
        id: true,
        inStock: true,
      },
    });

    res.json({
      id: updated.id,
      module: requestedModule,
      inStock: updated.inStock,
    });
  }),
);

router.post(
  '/:userId/shop-availability',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateShopAvailabilitySchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.SHOP) {
      return res.status(404).json({ error: 'Shop pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);

    if (body.module === 'shopping') {
      if (
        bindings.shoppingStoreIds.length === 0 ||
        !bindings.shoppingStoreIds.includes(body.targetId)
      ) {
        return res.status(403).json({ error: 'Store is not assigned to this shop profile.' });
      }

      const store = await prisma.shoppingStore.update({
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
      if (
        bindings.restaurantIds.length === 0 ||
        !bindings.restaurantIds.includes(body.targetId)
      ) {
        return res.status(403).json({ error: 'Restaurant is not assigned to this shop profile.' });
      }

      const restaurant = await prisma.restaurant.update({
        where: { id: body.targetId },
        data: { isOpen: body.enabled },
      });

      return res.json({
        module: body.module,
        id: restaurant.id,
        enabled: restaurant.isOpen,
      });
    }

    const product = await prisma.product.findUnique({
      where: { id: body.targetId },
      select: {
        id: true,
        metadata: true,
      },
    });

    const metadata =
      product?.metadata &&
      typeof product.metadata === 'object' &&
      !Array.isArray(product.metadata)
        ? (product.metadata as Record<string, unknown>)
        : null;
    const sourceBusiness = metadata?.sourceBusiness?.toString();

    if (
      product == null ||
      sourceBusiness == null ||
      !bindings.pharmacyBusinesses.includes(sourceBusiness)
    ) {
      return res.status(403).json({ error: 'Pharmacy item is not assigned to this shop profile.' });
    }

    const updatedProduct = await prisma.product.update({
      where: { id: body.targetId },
      data: { inStock: body.enabled },
    });

    res.json({
      module: body.module,
      id: updatedProduct.id,
      enabled: updatedProduct.inStock,
    });
  }),
);

router.get(
  '/:userId/provider-bindings',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const canServices = hydratedProfile.activeModules.includes(ProModule.SERVICES);
    const canLaundry = hydratedProfile.activeModules.includes(ProModule.LAUNDRY);

    const [serviceCandidates, laundryCandidates] = await Promise.all([
      !canServices
        ? Promise.resolve([])
        : prisma.homeServiceProvider.findMany({
            select: {
              id: true,
              name: true,
              title: true,
              isAvailable: true,
              category: {
                select: {
                  name: true,
                  slug: true,
                },
              },
            },
            orderBy: [{ isAvailable: 'desc' }, { rating: 'desc' }, { name: 'asc' }],
            take: 200,
          }),
      !canLaundry
        ? Promise.resolve([])
        : prisma.laundryService.findMany({
            select: {
              id: true,
              name: true,
              active: true,
            },
            orderBy: [{ active: 'desc' }, { name: 'asc' }],
            take: 200,
          }),
    ]);

    res.json({
      bindings: {
        providerIds: bindings.providerIds,
        laundryServiceIds: bindings.laundryServiceIds,
      },
      services: serviceCandidates.map((provider) => ({
        id: provider.id,
        name: provider.name,
        title: provider.title,
        categoryName: provider.category.name,
        categorySlug: provider.category.slug,
        enabled: provider.isAvailable,
        isBound: bindings.providerIds.includes(provider.id),
      })),
      laundry: laundryCandidates.map((service) => ({
        id: service.id,
        name: service.name,
        enabled: service.active,
        isBound: bindings.laundryServiceIds.includes(service.id),
      })),
    });
  }),
);

router.post(
  '/:userId/provider-bindings',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateProviderBindingsSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const existingBindings = normalizeBindings(hydratedProfile.bindings);
    const sanitizedOverrides = await sanitizeProviderBindingOverrides(
      hydratedProfile.activeModules,
      body,
    );

    const nextBindings: ProBindings = {
      ...existingBindings,
      providerIds:
        body.providerIds === undefined
          ? existingBindings.providerIds
          : mergeStringLists([], sanitizedOverrides.providerIds),
      laundryServiceIds:
        body.laundryServiceIds === undefined
          ? existingBindings.laundryServiceIds
          : mergeStringLists([], sanitizedOverrides.laundryServiceIds),
    };

    const ownedLaundryServiceIds = await syncLaundryOwnership(
      hydratedProfile.userId,
      hydratedProfile.type,
      hydratedProfile.activeModules,
      nextBindings,
    );

    const updated = await prisma.proProfile.update({
      where: { id: hydratedProfile.id },
      data: {
        bindings: {
          ...nextBindings,
          laundryServiceIds: ownedLaundryServiceIds,
        },
      },
    });

    const normalized = normalizeBindings(updated.bindings);
    res.json({
      providerIds: normalized.providerIds,
      laundryServiceIds: normalized.laundryServiceIds,
    });
  }),
);

router.get(
  '/:userId/provider-availability',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const canServices = hydratedProfile.activeModules.includes(ProModule.SERVICES);
    const canLaundry = hydratedProfile.activeModules.includes(ProModule.LAUNDRY);
    const [providers, laundryServices] = await Promise.all([
      !canServices || bindings.providerIds.length === 0
        ? Promise.resolve([])
        : prisma.homeServiceProvider.findMany({
            where: { id: { in: bindings.providerIds } },
            select: {
              id: true,
              name: true,
              title: true,
              servicesJson: true,
              isAvailable: true,
            },
            orderBy: { name: 'asc' },
          }),
      !canLaundry || bindings.laundryServiceIds.length === 0
        ? Promise.resolve([])
        : prisma.laundryService.findMany({
            where: { id: { in: bindings.laundryServiceIds } },
            select: {
              id: true,
              name: true,
              active: true,
            },
            orderBy: { name: 'asc' },
          }),
    ]);

    res.json({
      services: providers.map((provider) => {
        const normalizedServices = normalizeStringList(provider.servicesJson).filter(
          (service) => service.trim().length > 0,
        );
        const orderedServices = [...normalizedServices].reverse();
        const overflowCount = Math.max(0, orderedServices.length - 5);
        const detailsParts = orderedServices.slice(1, 5);
        if (overflowCount > 0) {
          detailsParts.push(`+${overflowCount} more`);
        }
        return {
          id: provider.id,
          name:
            orderedServices[0] ||
            provider.title?.trim() ||
            provider.name?.trim() ||
            'Service Listing',
          details: detailsParts.length > 0 ? detailsParts.join(' • ') : null,
          enabled: provider.isAvailable,
        };
      }),
      laundry: laundryServices.map((service) => ({
        id: service.id,
        name: service.name,
        enabled: service.active,
      })),
    });
  }),
);

router.post(
  '/:userId/provider-availability',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateProviderAvailabilitySchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const canServices = hydratedProfile.activeModules.includes(ProModule.SERVICES);
    const canLaundry = hydratedProfile.activeModules.includes(ProModule.LAUNDRY);

    if (body.module === 'services') {
      if (!canServices) {
        return res.status(403).json({ error: 'Services module is not enabled for this profile.' });
      }
      if (
        bindings.providerIds.length === 0 ||
        !bindings.providerIds.includes(body.targetId)
      ) {
        return res.status(403).json({ error: 'Provider is not assigned to this profile.' });
      }

      const provider = await prisma.homeServiceProvider.update({
        where: { id: body.targetId },
        data: { isAvailable: body.enabled },
      });

      return res.json({
        module: body.module,
        id: provider.id,
        enabled: provider.isAvailable,
      });
    }

    if (!canLaundry) {
      return res.status(403).json({ error: 'Laundry module is not enabled for this profile.' });
    }

    if (
      bindings.laundryServiceIds.length === 0 ||
      !bindings.laundryServiceIds.includes(body.targetId)
    ) {
      return res.status(403).json({ error: 'Laundry service is not assigned to this profile.' });
    }

    const service = await prisma.laundryService.update({
      where: { id: body.targetId },
      data: { active: body.enabled },
    });

    res.json({
      module: body.module,
      id: service.id,
      enabled: service.active,
    });
  }),
);

router.get(
  '/:userId/doctor-availability',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.DOCTOR) {
      return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }

    const bindings = normalizeBindings(profile.bindings);
    const doctors = await prisma.doctor.findMany({
      where:
        bindings.doctorIds.length === 0
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

    res.json(
      doctors.map((doctor) => ({
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        enabled: doctor.isAvailable,
      })),
    );
  }),
);

router.post(
  '/:userId/doctor-availability',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateDoctorAvailabilitySchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.DOCTOR) {
      return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }

    const bindings = normalizeBindings(profile.bindings);
    if (
      bindings.doctorIds.length === 0 ||
      !bindings.doctorIds.includes(body.doctorId)
    ) {
      return res.status(403).json({ error: 'Doctor is not assigned to this profile.' });
    }

    const doctor = await prisma.doctor.update({
      where: { id: body.doctorId },
      data: { isAvailable: body.enabled },
    });

    res.json({
      id: doctor.id,
      enabled: doctor.isAvailable,
    });
  }),
);

router.get(
  '/:userId/provider-settings',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    const providers =
      bindings.providerIds.length === 0
          ? []
          : await prisma.homeServiceProvider.findMany({
              where: { id: { in: bindings.providerIds } },
              select: {
                id: true,
                name: true,
                title: true,
                location: true,
                contactPhone: true,
                responseTime: true,
                servicesJson: true,
                bookingModesJson: true,
                availabilityJson: true,
                category: {
                  select: {
                    slug: true,
                  },
                },
              },
              orderBy: { name: 'asc' },
            });

    res.json(
      providers.map((provider) => ({
        id: provider.id,
        name: provider.name,
        title: provider.title,
        location: provider.location,
        contactPhone: provider.contactPhone,
        responseTime: provider.responseTime,
        categorySlug: provider.category?.slug ?? null,
        services: normalizeStringList(provider.servicesJson),
        bookingModes: normalizeStringList(provider.bookingModesJson),
        availability: normalizeHours(provider.availabilityJson, {
          weekdays: '08:00 AM - 06:00 PM',
          saturday: '09:00 AM - 02:00 PM',
          sunday: 'Closed',
        }),
        serviceZone: serviceZoneFromAvailabilityJson(provider.availabilityJson),
        houseHelpConfig: houseHelpConfigFromAvailabilityJson(
          provider.availabilityJson,
        ),
      })),
    );
  }),
);

router.post(
  '/:userId/provider-settings',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateProviderSettingsSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.PROVIDER) {
      return res.status(404).json({ error: 'Provider pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);
    const bindings = normalizeBindings(hydratedProfile.bindings);
    if (
      bindings.providerIds.length === 0 ||
      !bindings.providerIds.includes(body.providerId)
    ) {
      return res.status(403).json({ error: 'Provider is not assigned to this profile.' });
    }

    const currentProvider = await prisma.homeServiceProvider.findUnique({
      where: { id: body.providerId },
      select: {
        availabilityJson: true,
        category: {
          select: {
            slug: true,
          },
        },
      },
    });
    const serviceZoneInput = isHouseHelpCategorySlug(
      currentProvider?.category?.slug,
    )
      ? capServiceZoneRadiusForHouseHelp(body.serviceZone)
      : body.serviceZone;

    const provider = await prisma.homeServiceProvider.update({
      where: { id: body.providerId },
      data: {
        location:
          body.location == null ? undefined : body.location.trim() || null,
        contactPhone:
          body.contactPhone == null
            ? undefined
            : body.contactPhone.trim() || null,
        responseTime:
          body.responseTime == null
            ? undefined
            : body.responseTime.trim() || null,
        servicesJson:
          body.services == null ? undefined : normalizeStringList(body.services),
        bookingModesJson:
          body.bookingModes == null
            ? undefined
            : normalizeStringList(body.bookingModes),
        availabilityJson:
          body.availability == null &&
              serviceZoneInput == null &&
              body.houseHelpConfig == null
            ? undefined
            : normalizeProviderAvailabilityJson({
                current: currentProvider?.availabilityJson,
                availability: body.availability,
                serviceZone: serviceZoneInput,
                houseHelpConfig: body.houseHelpConfig,
              }),
      },
      select: {
        id: true,
        name: true,
        title: true,
        location: true,
        contactPhone: true,
        responseTime: true,
        servicesJson: true,
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
      services: normalizeStringList(provider.servicesJson),
      bookingModes: normalizeStringList(provider.bookingModesJson),
      availability: normalizeHours(provider.availabilityJson, {
        weekdays: '08:00 AM - 06:00 PM',
        saturday: '09:00 AM - 02:00 PM',
        sunday: 'Closed',
      }),
      serviceZone: serviceZoneFromAvailabilityJson(provider.availabilityJson),
      houseHelpConfig: houseHelpConfigFromAvailabilityJson(
        provider.availabilityJson,
      ),
    });
  }),
);

router.get(
  '/:userId/doctor-settings',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.DOCTOR) {
      return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }

    const bindings = normalizeBindings(profile.bindings);
    const doctors = await prisma.doctor.findMany({
      where:
        bindings.doctorIds.length === 0
          ? undefined
          : { id: { in: bindings.doctorIds } },
      select: {
        id: true,
        name: true,
        specialty: true,
        imageUrl: true,
        location: true,
        contactPhone: true,
        contactWhatsApp: true,
        careModesJson: true,
        workingHoursJson: true,
      },
      orderBy: { name: 'asc' },
    });

    res.json(
      doctors.map((doctor) => ({
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        imageUrl: doctor.imageUrl,
        location: doctor.location,
        contactPhone: doctor.contactPhone,
        contactWhatsApp: doctor.contactWhatsApp,
        careModes: normalizeStringList(doctor.careModesJson),
        workingHours: normalizeHours(doctor.workingHoursJson, {
          weekdays: '09:00 AM - 05:00 PM',
          saturday: '10:00 AM - 02:00 PM',
          sunday: 'Closed',
        }),
      })),
    );
  }),
);

router.post(
  '/:userId/doctor-settings',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateDoctorSettingsSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({ where: { userId } });

    if (!profile || profile.type !== ProProfileType.DOCTOR) {
      return res.status(404).json({ error: 'Doctor pro profile not found.' });
    }

    const bindings = normalizeBindings(profile.bindings);
    if (
      bindings.doctorIds.length === 0 ||
      !bindings.doctorIds.includes(body.doctorId)
    ) {
      return res.status(403).json({ error: 'Doctor is not assigned to this profile.' });
    }

    const doctor = await prisma.doctor.update({
      where: { id: body.doctorId },
      data: {
        imageUrl:
          body.imageUrl == null ? undefined : body.imageUrl.trim() || null,
        location:
          body.location == null ? undefined : body.location.trim() || null,
        contactPhone:
          body.contactPhone == null
            ? undefined
            : body.contactPhone.trim() || null,
        contactWhatsApp:
          body.contactWhatsApp == null
            ? undefined
            : body.contactWhatsApp.trim() || null,
        careModesJson:
          body.careModes == null
            ? undefined
            : normalizeStringList(body.careModes),
        workingHoursJson:
          body.workingHours == null
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
        imageUrl: true,
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
      imageUrl: doctor.imageUrl,
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
  }),
);

router.post(
  '/:userId/avatar',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateProAvatarSchema.parse(req.body);
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
      select: { id: true, accountId: true },
    });

    if (!profile) {
      return res.status(404).json({ error: 'Pro profile not found.' });
    }

    const avatarUrl = body.avatarUrl?.trim() || null;
    const updatedProfile = await prisma.$transaction(async (tx) => {
      const nextProfile = await tx.proProfile.update({
        where: { userId },
        data: { avatarUrl },
      });

      if (profile.accountId != null) {
        await tx.proAccount.update({
          where: { id: profile.accountId },
          data: { avatarUrl },
        });
      }

      await tx.user.update({
        where: { id: userId },
        data: { avatarUrl },
      });

      return nextProfile;
    });

    res.json(serializeProProfile(updatedProfile));
  }),
);

router.post(
  '/:userId/online-status',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const body = updateOnlineStatusSchema.parse(req.body);
    const profile = await prisma.proProfile.update({
      where: { userId },
      data: { isOnline: body.isOnline },
    });

    res.json(serializeProProfile(profile));
  }),
);

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      return res.status(404).json({ error: 'Pro profile not found.' });
    }

    const hydratedProfile = await hydrateProfileBindingsIfMissing(profile);

    res.json(serializeProProfile(hydratedProfile));
  }),
);

router.get(
  '/:userId/dashboard',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const profile = await prisma.proProfile.findUnique({
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
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const body = proProfileSchema.parse(req.body);
    const user = await prisma.user.findUnique({
      where: { id: body.userId },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const resolvedBindingsRaw = await resolveBindings(
      body.businessName,
      body.activeModules,
    );
    const resolvedBindings = normalizeResolvedBindingsForProfileType(
      body.type,
      resolvedBindingsRaw,
    );
    const ownedLaundryServiceIds = await syncLaundryOwnership(
      body.userId,
      body.type,
      body.activeModules,
      resolvedBindings,
    );
    const bindings = {
      ...resolvedBindings,
      laundryServiceIds: ownedLaundryServiceIds,
    };

    const profile = await prisma.proProfile.upsert({
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
  }),
);

export default router;
