import { ModuleType } from '@prisma/client';
import { prisma } from '../db';

type ModuleDefinition = {
  readonly moduleType: ModuleType;
  readonly id: string;
  readonly name: string;
  readonly sortOrder: number;
};

const MANAGED_MODULES: readonly ModuleDefinition[] = [
  { moduleType: ModuleType.SHOPPING, id: 'shopping', name: 'Shopping', sortOrder: 1 },
  { moduleType: ModuleType.FOOD, id: 'food', name: 'Food', sortOrder: 2 },
  { moduleType: ModuleType.DOCTOR, id: 'doctor', name: 'Doctor', sortOrder: 3 },
  { moduleType: ModuleType.HOTEL, id: 'hotel', name: 'Hotel', sortOrder: 4 },
  { moduleType: ModuleType.RIDE, id: 'ride', name: 'Ride', sortOrder: 5 },
  { moduleType: ModuleType.PHARMACY, id: 'pharmacy', name: 'Pharmacy', sortOrder: 6 },
  { moduleType: ModuleType.GROCERY, id: 'grocery', name: 'Grocery', sortOrder: 7 },
  { moduleType: ModuleType.HOME_SERVICES, id: 'home-services', name: 'Home Services', sortOrder: 8 },
  { moduleType: ModuleType.LAUNDRY, id: 'laundry', name: 'Laundry', sortOrder: 9 },
];

const moduleMap = new Map<ModuleType, ModuleDefinition>(
  MANAGED_MODULES.map((entry) => [entry.moduleType, entry]),
);

export function defaultManagedModules() {
  return MANAGED_MODULES.map((definition) => ({
    id: definition.id,
    moduleType: definition.moduleType,
    name: definition.name,
    active: true,
    sortOrder: definition.sortOrder,
  }));
}

function canonicalModuleType(moduleType: ModuleType) {
  if (moduleType === ModuleType.HOUSE_HELP) {
    return ModuleType.HOME_SERVICES;
  }
  return moduleType;
}

export function moduleName(moduleType: ModuleType) {
  const canonical = canonicalModuleType(moduleType);
  return moduleMap.get(canonical)?.name ?? canonical;
}

export function isManagedModule(moduleType: ModuleType) {
  return moduleMap.has(canonicalModuleType(moduleType));
}

export async function isModuleEnabled(moduleType: ModuleType) {
  const canonical = canonicalModuleType(moduleType);
  const config = await prisma.appModule.findUnique({
    where: { moduleType: canonical },
    select: { active: true },
  });
  return config?.active ?? true;
}

export async function listManagedModules() {
  const records = await prisma.appModule.findMany({
    where: {
      moduleType: {
        in: MANAGED_MODULES.map((entry) => entry.moduleType),
      },
    },
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
  });

  const byType = new Map(records.map((record) => [record.moduleType, record]));
  return MANAGED_MODULES.map((definition) => {
    const record = byType.get(definition.moduleType);
    return {
      id: record?.slug ?? definition.id,
      moduleType: definition.moduleType,
      name: record?.name ?? definition.name,
      active: record?.active ?? true,
      sortOrder: record?.sortOrder ?? definition.sortOrder,
    };
  }).sort((left, right) => {
    if (left.sortOrder !== right.sortOrder) {
      return left.sortOrder - right.sortOrder;
    }
    return left.name.localeCompare(right.name);
  });
}

// ── Per-location (zone) module activation ────────────────────────────────────
//
// Zones mirror the client-side CityZone list in
// `lib/core/config/service_zones.dart`. Each zone has one ZoneModuleConfig row
// per managed module; a module is usable in a zone when BOTH the global
// AppModule row and the zone-specific row are active. Missing rows default to
// active so a fresh zone is fully usable with no configuration.

export type ServiceZoneSummary = {
  id: string;
  zoneKey: string;
  name: string;
  nameEn: string | null;
  nameFr: string | null;
  nameAr: string | null;
  centerLatitude: number;
  centerLongitude: number;
  radiusKm: number;
  active: boolean;
  sortOrder: number;
};

function zoneZoneKey(value: string) {
  return value.trim().toLowerCase().replace(/[\s-]+/g, '_');
}

function zoneSummary(zone: {
  id: string;
  zoneKey: string;
  name: string;
  nameEn: string | null;
  nameFr: string | null;
  nameAr: string | null;
  centerLatitude: number;
  centerLongitude: number;
  radiusKm: number;
  active: boolean;
  sortOrder: number;
}): ServiceZoneSummary {
  return {
    id: zone.id,
    zoneKey: zone.zoneKey,
    name: zone.name,
    nameEn: zone.nameEn,
    nameFr: zone.nameFr,
    nameAr: zone.nameAr,
    centerLatitude: zone.centerLatitude,
    centerLongitude: zone.centerLongitude,
    radiusKm: zone.radiusKm,
    active: zone.active,
    sortOrder: zone.sortOrder,
  };
}

export async function listServiceZones(options?: { activeOnly?: boolean }) {
  const zones = await prisma.serviceZone.findMany({
    where: options?.activeOnly ? { active: true } : undefined,
    orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
  });
  return zones.map(zoneSummary);
}

/**
 * Resolves which active service zone contains the given point, or null when
 * the point is outside every active zone. Used to pick the zone whose module
 * config applies to a request.
 */
export async function resolveServiceZoneForPoint(
  latitude: number,
  longitude: number,
) {
  const zones = await prisma.serviceZone.findMany({
    where: { active: true },
  });
  for (const zone of zones) {
    const distanceKm = haversineKm(
      latitude,
      longitude,
      zone.centerLatitude,
      zone.centerLongitude,
    );
    if (distanceKm <= zone.radiusKm) {
      return zone;
    }
  }
  // Outside every active zone: no zone applies. Callers treat this as "show
  // everything" rather than guessing the nearest city the user isn't in.
  return null;
}

/** Finds a zone by zoneKey (or id as a fallback), regardless of active state. */
export async function findServiceZoneByKey(zoneKey: string) {
  const normalized = zoneZoneKey(zoneKey);
  if (normalized.length === 0) return null;
  const zone = await prisma.serviceZone.findUnique({
    where: { zoneKey: normalized },
  });
  if (zone) return zone;
  return prisma.serviceZone.findUnique({ where: { id: zoneKey } });
}

export type ZoneModulesPayload = Array<{
  id: string;
  moduleType: ModuleType;
  name: string;
  active: boolean;
  sortOrder: number;
}>;

/**
 * Lists managed modules scoped to one zone. Zone rows default to active, so a
 * module with no ZoneModuleConfig row is treated as enabled for that zone.
 */
export async function listModulesForZone(zoneId: string): Promise<ZoneModulesPayload> {
  const [globalConfigs, zoneConfigs] = await Promise.all([
    prisma.appModule.findMany(),
    prisma.zoneModuleConfig.findMany({ where: { zoneId } }),
  ]);

  const globalByType = new Map(globalConfigs.map((entry) => [entry.moduleType, entry]));
  const zoneByType = new Map(zoneConfigs.map((entry) => [entry.moduleType, entry]));

  return MANAGED_MODULES.map((definition) => {
    const zoneRecord = zoneByType.get(definition.moduleType);
    const globalRecord = globalByType.get(definition.moduleType);
    return {
      id: definition.id,
      moduleType: definition.moduleType,
      name: globalRecord?.name ?? definition.name,
      active:
        (globalRecord?.active ?? true) &&
        (zoneRecord?.active ?? true),
      sortOrder: definition.sortOrder,
    };
  }).sort((left, right) => left.sortOrder - right.sortOrder);
}

/**
 * Upserts the zone module toggle for one (zone, module) pair. Creating the row
 * with active=false is meaningful (module off for that zone), so this always
 * writes a row.
 */
export async function setZoneModuleActive(
  zoneId: string,
  moduleType: ModuleType,
  active: boolean,
) {
  const canonical = canonicalModuleType(moduleType);
  if (!moduleMap.has(canonical)) {
    throw new Error(`Module ${moduleType} is not managed.`);
  }
  await prisma.zoneModuleConfig.upsert({
    where: {
      zoneId_moduleType: { zoneId, moduleType: canonical },
    },
    update: { active },
    create: { zoneId, moduleType: canonical, active },
  });
  return listModulesForZone(zoneId);
}

/** Ensures every managed module has a zone config row for the zone (active=true). */
export async function ensureZoneModuleRows(zoneId: string) {
  const existing = await prisma.zoneModuleConfig.findMany({
    where: { zoneId },
    select: { moduleType: true },
  });
  const existingTypes = new Set(existing.map((entry) => entry.moduleType));
  const missing = MANAGED_MODULES.filter(
    (definition) => !existingTypes.has(definition.moduleType),
  );
  if (missing.length === 0) return;
  await prisma.zoneModuleConfig.createMany({
    data: missing.map((definition) => ({
      zoneId,
      moduleType: definition.moduleType,
      active: true,
    })),
  });
}

function haversineKm(
  startLatitude: number,
  startLongitude: number,
  endLatitude: number,
  endLongitude: number,
) {
  const toRadians = (value: number) => (value * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const latitudeDelta = toRadians(endLatitude - startLatitude);
  const longitudeDelta = toRadians(endLongitude - startLongitude);
  const a =
    Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
    Math.cos(toRadians(startLatitude)) *
      Math.cos(toRadians(endLatitude)) *
      Math.sin(longitudeDelta / 2) *
      Math.sin(longitudeDelta / 2);
  return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

/**
 * Parses a `zone` request parameter (zoneKey, or a raw lat,lng pair).
 * Returns the matching active zone, or null when no zone can be resolved.
 */
export async function resolveZoneFromRequest(
  query: Record<string, unknown>,
): Promise<{ zone: Awaited<ReturnType<typeof findServiceZoneByKey>>; } | { point: { latitude: number; longitude: number } }> {
  const zoneParam = query.zone?.toString().trim();
  if (zoneParam != null && zoneParam.length > 0) {
    const zone = await findServiceZoneByKey(zoneParam);
    if (zone != null) {
      return { zone };
    }
  }

  const latitude = toFiniteNumber(query.latitude);
  const longitude = toFiniteNumber(query.longitude);
  if (latitude != null && longitude != null) {
    return { point: { latitude, longitude } };
  }

  return { zone: null };
}

function toFiniteNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}
