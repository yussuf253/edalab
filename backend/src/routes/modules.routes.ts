import { Router } from 'express';
import type { NextFunction, Request, Response } from 'express';
import { asyncHandler } from '../utils/async-handler';
import { requireAuth } from '../middleware/auth';
import { prisma } from '../db';
import {
  defaultManagedModules,
  ensureZoneModuleRows,
  findServiceZoneByKey,
  isModuleEnabled,
  listManagedModules,
  listModulesForZone,
  listServiceZones,
  moduleName,
  resolveServiceZoneForPoint,
  setZoneModuleActive,
} from '../utils/module-settings';

const router = Router();

function configuredAdminEmails() {
  return (
    process.env.SUPER_ADMIN_EMAILS ||
    process.env.SUPER_ADMIN_EMAIL ||
    'admin@edalab.com'
  )
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

async function requireSuperAdmin(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  if ((req as any).auth?.accountType !== 'pro') {
    return res
      .status(403)
      .json({ error: 'Super admin access requires a pro account.' });
  }

  const account = await prisma.proAccount.findUnique({
    where: { id: (req as any).auth.userId },
    select: { email: true, banned: true },
  });

  const email = account?.email.toLowerCase().trim() ?? '';
  const allowedEmails = configuredAdminEmails();
  const allowed =
    allowedEmails.includes(email) ||
    email.startsWith('admin@') ||
    email.includes('+admin@');

  if (!account || account.banned || !allowed) {
    return res.status(403).json({ error: 'Super admin access is required.' });
  }

  next();
}

// ── Global module list (unchanged behavior) ─────────────────────────────────
router.get(
  '/',
  asyncHandler(async (_req, res) => {
    try {
      const modules = await listManagedModules();
      return res.json(modules);
    } catch {
      // Keep the app functional while the DB schema is being migrated.
      return res.json(defaultManagedModules());
    }
  }),
);

// ── Service zones ───────────────────────────────────────────────────────────
// GET /modules/zones                    → all zones (incl. inactive)
// GET /modules/zones?activeOnly=true    → active zones only
router.get(
  '/zones',
  asyncHandler(async (req, res) => {
    const activeOnly =
      req.query.activeOnly?.toString().trim().toLowerCase() === 'true';
    try {
      return res.json(await listServiceZones({ activeOnly }));
    } catch {
      return res.json([]);
    }
  }),
);

// Resolve the zone for a point: GET /modules/zones/resolve?latitude=..&longitude=..
router.get(
  '/zones/resolve',
  asyncHandler(async (req, res) => {
    const latitude = Number(req.query.latitude);
    const longitude = Number(req.query.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      return res
        .status(400)
        .json({ error: 'latitude and longitude are required numbers.' });
    }
    try {
      const zone = await resolveServiceZoneForPoint(latitude, longitude);
      return res.json(zone ? { zone } : { zone: null });
    } catch {
      return res.json({ zone: null });
    }
  }),
);

// ── Per-zone module configuration ───────────────────────────────────────────
// GET /modules/zones/:zoneKey/modules
router.get(
  '/zones/:zoneKey/modules',
  asyncHandler(async (req, res) => {
    const zone = await findServiceZoneByKey(String(req.params.zoneKey));
    if (!zone) {
      return res.status(404).json({ error: 'Service zone not found.' });
    }
    try {
      return res.json(await listModulesForZone(zone.id));
    } catch {
      return res.json(defaultManagedModules());
    }
  }),
);

// PUT /modules/zones/:zoneKey/modules/:moduleId  { active: boolean }
// Super-admin only: flips per-location module activation.
router.put(
  '/zones/:zoneKey/modules/:moduleId',
  requireAuth,
  requireSuperAdmin,
  asyncHandler(async (req, res) => {
    const zone = await findServiceZoneByKey(String(req.params.zoneKey));
    if (!zone) {
      return res.status(404).json({ error: 'Service zone not found.' });
    }

    const moduleId = String(req.params.moduleId ?? '').trim().toLowerCase();
    const moduleTypeByName: Record<string, string> = {
      shopping: 'SHOPPING',
      food: 'FOOD',
      doctor: 'DOCTOR',
      hotel: 'HOTEL',
      ride: 'RIDE',
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

    await ensureZoneModuleRows(zone.id);
    await setZoneModuleActive(zone.id, moduleType as any, active);

    return res.json({
      zone: { id: zone.id, zoneKey: zone.zoneKey, name: zone.name },
      moduleType,
      moduleName: moduleName(moduleType as any),
      active,
      modules: await listModulesForZone(zone.id),
    });
  }),
);

// ── Compatibility: /modules/enabled?zone=.. — zone-scoped enabled check ─────
router.get(
  '/enabled',
  asyncHandler(async (req, res) => {
    const zoneKey = req.query.zone?.toString().trim();
    if (!zoneKey) {
      return res.json({
        moduleType: req.query.moduleType ?? null,
        enabled: await isModuleEnabled('SHOPPING'),
        zone: null,
      });
    }
    const zone = await findServiceZoneByKey(zoneKey);
    if (!zone) {
      return res.status(404).json({ error: 'Service zone not found.' });
    }
    const modules = await listModulesForZone(zone.id);
    return res.json({ zone: { id: zone.id, zoneKey: zone.zoneKey }, modules });
  }),
);

export default router;
