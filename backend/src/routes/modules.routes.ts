import { Router } from 'express';
import { asyncHandler } from '../utils/async-handler';
import {
  defaultManagedModules,
  listManagedModules,
} from '../utils/module-settings';

const router = Router();

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

export default router;
