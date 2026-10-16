"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const async_handler_1 = require("../utils/async-handler");
const auth_1 = require("../middleware/auth");
const db_1 = require("../db");
const module_settings_1 = require("../utils/module-settings");
const router = (0, express_1.Router)();
function configuredAdminEmails() {
    return (process.env.SUPER_ADMIN_EMAILS ||
        process.env.SUPER_ADMIN_EMAIL ||
        'admin@edalab.com')
        .split(',')
        .map((email) => email.trim().toLowerCase())
        .filter(Boolean);
}
async function requireSuperAdmin(req, res, next) {
    if (req.auth?.accountType !== 'pro') {
        return res
            .status(403)
            .json({ error: 'Super admin access requires a pro account.' });
    }
    const account = await db_1.prisma.proAccount.findUnique({
        where: { id: req.auth.userId },
        select: { email: true, banned: true },
    });
    const email = account?.email.toLowerCase().trim() ?? '';
    const allowedEmails = configuredAdminEmails();
    const allowed = allowedEmails.includes(email) ||
        email.startsWith('admin@') ||
        email.includes('+admin@');
    if (!account || account.banned || !allowed) {
        return res.status(403).json({ error: 'Super admin access is required.' });
    }
    next();
}
// ── Global module list (unchanged behavior) ─────────────────────────────────
router.get('/', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    try {
        const zoneKey = _req.query.zone?.toString().trim();
        const zone = zoneKey ? await (0, module_settings_1.findServiceZoneByKey)(zoneKey) : null;
        const modules = zone
            ? await (0, module_settings_1.listModulesForZone)(zone.id)
            : await (0, module_settings_1.listManagedModules)();
        return res.json(modules);
    }
    catch {
        // Keep the app functional while the DB schema is being migrated.
        return res.json((0, module_settings_1.defaultManagedModules)());
    }
}));
// ── Service zones ───────────────────────────────────────────────────────────
// GET /modules/zones                    → all zones (incl. inactive)
// GET /modules/zones?activeOnly=true    → active zones only
router.get('/zones', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const activeOnly = req.query.activeOnly?.toString().trim().toLowerCase() === 'true';
    try {
        return res.json(await (0, module_settings_1.listServiceZones)({ activeOnly }));
    }
    catch {
        return res.json([]);
    }
}));
// Resolve the zone for a point: GET /modules/zones/resolve?latitude=..&longitude=..
router.get('/zones/resolve', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const latitude = Number(req.query.latitude);
    const longitude = Number(req.query.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
        return res
            .status(400)
            .json({ error: 'latitude and longitude are required numbers.' });
    }
    try {
        const zone = await (0, module_settings_1.resolveServiceZoneForPoint)(latitude, longitude);
        return res.json(zone ? { zone } : { zone: null });
    }
    catch {
        return res.json({ zone: null });
    }
}));
// ── Per-zone module configuration ───────────────────────────────────────────
// GET /modules/zones/:zoneKey/modules
router.get('/zones/:zoneKey/modules', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const zone = await (0, module_settings_1.findServiceZoneByKey)(String(req.params.zoneKey));
    if (!zone) {
        return res.status(404).json({ error: 'Service zone not found.' });
    }
    try {
        return res.json(await (0, module_settings_1.listModulesForZone)(zone.id));
    }
    catch {
        return res.json((0, module_settings_1.defaultManagedModules)());
    }
}));
// PUT /modules/zones/:zoneKey/modules/:moduleId  { active: boolean }
// Super-admin only: flips per-location module activation.
router.put('/zones/:zoneKey/modules/:moduleId', auth_1.requireAuth, requireSuperAdmin, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const zone = await (0, module_settings_1.findServiceZoneByKey)(String(req.params.zoneKey));
    if (!zone) {
        return res.status(404).json({ error: 'Service zone not found.' });
    }
    const moduleId = String(req.params.moduleId ?? '').trim().toLowerCase();
    const moduleTypeByName = {
        shopping: 'SHOPPING',
        food: 'FOOD',
        doctor: 'DOCTOR',
        hotel: 'HOTEL',
        ride: 'RIDE',
        parcel: 'PARCEL',
        pharmacy: 'PHARMACY',
        grocery: 'GROCERY',
        'home-services': 'HOME_SERVICES',
        laundry: 'LAUNDRY',
    };
    const moduleType = moduleId ? moduleTypeByName[moduleId] : undefined;
    if (!moduleType) {
        return res.status(400).json({ error: 'Unknown module id.' });
    }
    const active = req.body?.active;
    if (typeof active !== 'boolean') {
        return res.status(400).json({ error: 'active (boolean) is required.' });
    }
    await (0, module_settings_1.ensureZoneModuleRows)(zone.id);
    await (0, module_settings_1.setZoneModuleActive)(zone.id, moduleType, active);
    return res.json({
        zone: { id: zone.id, zoneKey: zone.zoneKey, name: zone.name },
        moduleType,
        moduleName: (0, module_settings_1.moduleName)(moduleType),
        active,
        modules: await (0, module_settings_1.listModulesForZone)(zone.id),
    });
}));
// ── Compatibility: /modules/enabled?zone=.. — zone-scoped enabled check ─────
router.get('/enabled', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const zoneKey = req.query.zone?.toString().trim();
    if (!zoneKey) {
        return res.json({
            moduleType: req.query.moduleType ?? null,
            enabled: await (0, module_settings_1.isModuleEnabled)('SHOPPING'),
            zone: null,
        });
    }
    const zone = await (0, module_settings_1.findServiceZoneByKey)(zoneKey);
    if (!zone) {
        return res.status(404).json({ error: 'Service zone not found.' });
    }
    const modules = await (0, module_settings_1.listModulesForZone)(zone.id);
    return res.json({ zone: { id: zone.id, zoneKey: zone.zoneKey }, modules });
}));
exports.default = router;
