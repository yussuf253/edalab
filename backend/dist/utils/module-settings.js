"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.defaultManagedModules = defaultManagedModules;
exports.moduleName = moduleName;
exports.isManagedModule = isManagedModule;
exports.isModuleEnabled = isModuleEnabled;
exports.listManagedModules = listManagedModules;
exports.listServiceZones = listServiceZones;
exports.resolveServiceZoneForPoint = resolveServiceZoneForPoint;
exports.findServiceZoneByKey = findServiceZoneByKey;
exports.listModulesForZone = listModulesForZone;
exports.setZoneModuleActive = setZoneModuleActive;
exports.ensureZoneModuleRows = ensureZoneModuleRows;
exports.resolveZoneFromRequest = resolveZoneFromRequest;
const client_1 = require("@prisma/client");
const db_1 = require("../db");
const MANAGED_MODULES = [
    { moduleType: client_1.ModuleType.SHOPPING, id: 'shopping', name: 'Shopping', sortOrder: 1 },
    { moduleType: client_1.ModuleType.FOOD, id: 'food', name: 'Food', sortOrder: 2 },
    { moduleType: client_1.ModuleType.DOCTOR, id: 'doctor', name: 'Doctor', sortOrder: 3 },
    { moduleType: client_1.ModuleType.HOTEL, id: 'hotel', name: 'Hotel', sortOrder: 4 },
    { moduleType: client_1.ModuleType.RIDE, id: 'ride', name: 'Ride', sortOrder: 5 },
    { moduleType: client_1.ModuleType.PARCEL, id: 'parcel', name: 'Parcel Delivery', sortOrder: 6 },
    { moduleType: client_1.ModuleType.PHARMACY, id: 'pharmacy', name: 'Pharmacy', sortOrder: 7 },
    { moduleType: client_1.ModuleType.GROCERY, id: 'grocery', name: 'Grocery', sortOrder: 8 },
    { moduleType: client_1.ModuleType.HOME_SERVICES, id: 'home-services', name: 'Home Services', sortOrder: 9 },
    { moduleType: client_1.ModuleType.LAUNDRY, id: 'laundry', name: 'Laundry', sortOrder: 10 },
];
const moduleMap = new Map(MANAGED_MODULES.map((entry) => [entry.moduleType, entry]));
function defaultManagedModules() {
    return MANAGED_MODULES.map((definition) => ({
        id: definition.id,
        moduleType: definition.moduleType,
        name: definition.name,
        active: true,
        sortOrder: definition.sortOrder,
    }));
}
function canonicalModuleType(moduleType) {
    if (moduleType === client_1.ModuleType.HOUSE_HELP) {
        return client_1.ModuleType.HOME_SERVICES;
    }
    return moduleType;
}
function moduleName(moduleType) {
    const canonical = canonicalModuleType(moduleType);
    return moduleMap.get(canonical)?.name ?? canonical;
}
function isManagedModule(moduleType) {
    return moduleMap.has(canonicalModuleType(moduleType));
}
async function isModuleEnabled(moduleType) {
    const canonical = canonicalModuleType(moduleType);
    const config = await db_1.prisma.appModule.findUnique({
        where: { moduleType: canonical },
        select: { active: true },
    });
    return config?.active ?? true;
}
async function listManagedModules() {
    const records = await db_1.prisma.appModule.findMany({
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
function zoneZoneKey(value) {
    return value.trim().toLowerCase().replace(/[\s-]+/g, '_');
}
function zoneSummary(zone) {
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
async function listServiceZones(options) {
    const zones = await db_1.prisma.serviceZone.findMany({
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
async function resolveServiceZoneForPoint(latitude, longitude) {
    const zones = await db_1.prisma.serviceZone.findMany({
        where: { active: true },
    });
    for (const zone of zones) {
        const distanceKm = haversineKm(latitude, longitude, zone.centerLatitude, zone.centerLongitude);
        if (distanceKm <= zone.radiusKm) {
            return zone;
        }
    }
    // Outside every active zone: no zone applies. Callers treat this as "show
    // everything" rather than guessing the nearest city the user isn't in.
    return null;
}
/** Finds a zone by zoneKey (or id as a fallback), regardless of active state. */
async function findServiceZoneByKey(zoneKey) {
    const normalized = zoneZoneKey(zoneKey);
    if (normalized.length === 0)
        return null;
    const zone = await db_1.prisma.serviceZone.findUnique({
        where: { zoneKey: normalized },
    });
    if (zone)
        return zone;
    return db_1.prisma.serviceZone.findUnique({ where: { id: zoneKey } });
}
/**
 * Lists managed modules scoped to one zone. Zone rows default to active, so a
 * module with no ZoneModuleConfig row is treated as enabled for that zone.
 */
async function listModulesForZone(zoneId) {
    const [globalConfigs, zoneConfigs] = await Promise.all([
        db_1.prisma.appModule.findMany(),
        db_1.prisma.zoneModuleConfig.findMany({ where: { zoneId } }),
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
            active: (globalRecord?.active ?? true) &&
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
async function setZoneModuleActive(zoneId, moduleType, active) {
    const canonical = canonicalModuleType(moduleType);
    if (!moduleMap.has(canonical)) {
        throw new Error(`Module ${moduleType} is not managed.`);
    }
    await db_1.prisma.zoneModuleConfig.upsert({
        where: {
            zoneId_moduleType: { zoneId, moduleType: canonical },
        },
        update: { active },
        create: { zoneId, moduleType: canonical, active },
    });
    return listModulesForZone(zoneId);
}
/** Ensures every managed module has a zone config row for the zone (active=true). */
async function ensureZoneModuleRows(zoneId) {
    const existing = await db_1.prisma.zoneModuleConfig.findMany({
        where: { zoneId },
        select: { moduleType: true },
    });
    const existingTypes = new Set(existing.map((entry) => entry.moduleType));
    const missing = MANAGED_MODULES.filter((definition) => !existingTypes.has(definition.moduleType));
    if (missing.length === 0)
        return;
    await db_1.prisma.zoneModuleConfig.createMany({
        data: missing.map((definition) => ({
            zoneId,
            moduleType: definition.moduleType,
            active: true,
        })),
    });
}
function haversineKm(startLatitude, startLongitude, endLatitude, endLongitude) {
    const toRadians = (value) => (value * Math.PI) / 180;
    const earthRadiusKm = 6371;
    const latitudeDelta = toRadians(endLatitude - startLatitude);
    const longitudeDelta = toRadians(endLongitude - startLongitude);
    const a = Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
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
async function resolveZoneFromRequest(query) {
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
function toFiniteNumber(value) {
    if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
    }
    if (typeof value === 'string' && value.trim().length > 0) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : null;
    }
    return null;
}
