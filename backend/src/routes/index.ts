import { Router } from 'express';
import appointmentsRoutes from './appointments.routes';
import authRoutes from './auth.routes';
import catalogRoutes from './catalog.routes';
import modulesRoutes from './modules.routes';
import notificationsRoutes from './notifications.routes';
import ordersRoutes from './orders.routes';
import promotionsRoutes from './promotions.routes';
import usersRoutes from './users.routes';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    message: 'EdaLab API is running',
  });
});

router.use('/auth', authRoutes);
router.use('/catalog', catalogRoutes);
router.use('/modules', modulesRoutes);
router.use('/users', usersRoutes);
router.use('/orders', ordersRoutes);
router.use('/appointments', appointmentsRoutes);
router.use('/promotions', promotionsRoutes);
router.use('/notifications', notificationsRoutes);

export default router;
