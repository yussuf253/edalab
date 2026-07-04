import { Router } from 'express';
import appointmentsRoutes from './appointments.routes';
import adminRoutes from './admin.routes';
import authRoutes from './auth.routes';
import catalogRoutes from './catalog.routes';
import modulesRoutes from './modules.routes';
import messagesRoutes from './messages.routes';
import mediaRoutes from './media.routes';
import notificationsRoutes from './notifications.routes';
import ordersRoutes from './orders.routes';
import paymentsRoutes from './payments.routes';
import proAuthRoutes from './pro-auth.routes';
import proRoutes from './pro.routes';
import promotionsRoutes from './promotions.routes';
import ridesRoutes from './rides.routes';
import carRentalsRoutes from './car-rentals.routes';
import usersRoutes from './users.routes';
import realtimeRoutes from './realtime.routes';

const router = Router();

router.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    message: 'EdaLab API is running',
  });
});

router.use('/auth', authRoutes);
router.use('/admin', adminRoutes);
router.use('/catalog', catalogRoutes);
router.use('/modules', modulesRoutes);
router.use('/messages', messagesRoutes);
router.use('/media', mediaRoutes);
router.use('/users', usersRoutes);
router.use('/orders', ordersRoutes);
router.use('/payments', paymentsRoutes);
router.use('/pro-auth', proAuthRoutes);
router.use('/pro', proRoutes);
router.use('/appointments', appointmentsRoutes);
router.use('/rides', ridesRoutes);
router.use('/car-rentals', carRentalsRoutes);
router.use('/promotions', promotionsRoutes);
router.use('/notifications', notificationsRoutes);
router.use('/realtime', realtimeRoutes);

export default router;
