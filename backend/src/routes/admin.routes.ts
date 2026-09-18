import { Router } from 'express';
import type { NextFunction, Request, Response } from 'express';
import { randomInt } from 'crypto';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';
import { asyncHandler } from '../utils/async-handler';

const router = Router();

function configuredAdminEmails() {
  return (process.env.SUPER_ADMIN_EMAILS || process.env.SUPER_ADMIN_EMAIL || 'admin@edalab.com')
    .split(',')
    .map((email) => email.trim().toLowerCase())
    .filter(Boolean);
}

async function requireSuperAdmin(req: Request, res: Response, next: NextFunction) {
  if (req.auth?.accountType !== 'pro') {
    return res.status(403).json({ error: 'Super admin access requires a pro account.' });
  }

  const account = await prisma.proAccount.findUnique({
    where: { id: req.auth.userId },
    select: { email: true, banned: true },
  });

  const email = account?.email.toLowerCase().trim() ?? '';
  const allowedEmails = configuredAdminEmails();
  const allowed =
    allowedEmails.includes(email) || email.startsWith('admin@') || email.includes('+admin@');

  if (!account || account.banned || !allowed) {
    return res.status(403).json({ error: 'Super admin access is required.' });
  }

  next();
}

router.use(requireAuth, requireSuperAdmin);

function serializeMoney(value: unknown) {
  return Number(value ?? 0);
}

function countByStatus(rows: Array<{ status: unknown; _count: unknown }>) {
  return rows.map((row) => ({
    status: String(row.status),
    count:
      typeof row._count === 'number'
        ? row._count
        : Number((row._count as Record<string, unknown>)?._all ?? 0),
  }));
}

router.get(
  '/overview',
  asyncHandler(async (_req, res) => {
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const [
      userCount,
      bannedUserCount,
      proAccountCount,
      bannedProAccountCount,
      proProfileCount,
      orderCount,
      rideCount,
      appointmentCount,
      laundryOrderCount,
      hotelBookingCount,
      todayOrders,
      todayRides,
      todayAppointments,
      orderRevenue,
      rideRevenue,
      laundryRevenue,
      hotelRevenue,
      orderStatus,
      rideStatus,
      appointmentStatus,
      laundryStatus,
      hotelStatus,
      recentOrders,
      recentRides,
      recentAppointments,
      recentLaundryOrders,
      recentHotelBookings,
      recentUsers,
      recentProAccounts,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.user.count({ where: { banned: true } }),
      prisma.proAccount.count(),
      prisma.proAccount.count({ where: { banned: true } }),
      prisma.proProfile.count(),
      prisma.order.count(),
      prisma.rideBooking.count(),
      prisma.appointment.count(),
      prisma.laundryOrder.count(),
      prisma.hotelBooking.count(),
      prisma.order.count({ where: { createdAt: { gte: since } } }),
      prisma.rideBooking.count({ where: { createdAt: { gte: since } } }),
      prisma.appointment.count({ where: { createdAt: { gte: since } } }),
      prisma.order.aggregate({ _sum: { total: true } }),
      prisma.rideBooking.aggregate({ _sum: { total: true } }),
      prisma.laundryOrder.aggregate({ _sum: { total: true } }),
      prisma.hotelBooking.aggregate({ _sum: { total: true } }),
      prisma.order.groupBy({ by: ['status'], _count: { _all: true } }),
      prisma.rideBooking.groupBy({ by: ['status'], _count: { _all: true } }),
      prisma.appointment.groupBy({ by: ['status'], _count: { _all: true } }),
      prisma.laundryOrder.groupBy({ by: ['status'], _count: { _all: true } }),
      prisma.hotelBooking.groupBy({ by: ['status'], _count: { _all: true } }),
      prisma.order.findMany({
        take: 12,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { email: true, firstName: true, lastName: true } } },
      }),
      prisma.rideBooking.findMany({
        take: 12,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { email: true, firstName: true, lastName: true } } },
      }),
      prisma.appointment.findMany({
        take: 12,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { email: true, firstName: true, lastName: true } } },
      }),
      prisma.laundryOrder.findMany({
        take: 12,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { email: true, firstName: true, lastName: true } } },
      }),
      prisma.hotelBooking.findMany({
        take: 12,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { email: true, firstName: true, lastName: true } } },
      }),
      prisma.user.findMany({
        take: 12,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          phone: true,
          banned: true,
          banReason: true,
          createdAt: true,
        },
      }),
      prisma.proAccount.findMany({
        take: 12,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          fullName: true,
          phone: true,
          banned: true,
          banReason: true,
          createdAt: true,
          proProfile: { select: { businessName: true, type: true, activeModules: true } },
        },
      }),
    ]);

    const revenueTotal =
      serializeMoney(orderRevenue._sum.total) +
      serializeMoney(rideRevenue._sum.total) +
      serializeMoney(laundryRevenue._sum.total) +
      serializeMoney(hotelRevenue._sum.total);

    res.json({
      metrics: {
        users: userCount,
        bannedUsers: bannedUserCount,
        proAccounts: proAccountCount,
        bannedProAccounts: bannedProAccountCount,
        proProfiles: proProfileCount,
        orders: orderCount,
        rides: rideCount,
        appointments: appointmentCount,
        laundryOrders: laundryOrderCount,
        hotelBookings: hotelBookingCount,
        todayOrders,
        todayRides,
        todayAppointments,
        revenueTotal,
      },
      statusBreakdowns: {
        orders: countByStatus(orderStatus),
        rides: countByStatus(rideStatus),
        appointments: countByStatus(appointmentStatus),
        laundry: countByStatus(laundryStatus),
        hotels: countByStatus(hotelStatus),
      },
      recentActivity: [
        ...recentOrders.map((order) => ({
          id: order.id,
          type: 'order',
          title: `${order.moduleType} order`,
          subtitle: order.user.email,
          status: order.status,
          amount: serializeMoney(order.total),
          createdAt: order.createdAt,
        })),
        ...recentRides.map((ride) => ({
          id: ride.id,
          type: 'ride',
          title: `${ride.pickupLabel} to ${ride.dropoffLabel}`,
          subtitle: ride.user.email,
          status: ride.status,
          amount: serializeMoney(ride.total),
          createdAt: ride.createdAt,
        })),
        ...recentAppointments.map((appointment) => ({
          id: appointment.id,
          type: 'appointment',
          title: appointment.appointmentType,
          subtitle: appointment.user.email,
          status: appointment.status,
          amount: null,
          createdAt: appointment.createdAt,
        })),
        ...recentLaundryOrders.map((order) => ({
          id: order.id,
          type: 'laundry',
          title: `${order.itemCount} laundry item(s)`,
          subtitle: order.user.email,
          status: order.status,
          amount: serializeMoney(order.total),
          createdAt: order.createdAt,
        })),
        ...recentHotelBookings.map((booking) => ({
          id: booking.id,
          type: 'hotel',
          title: booking.guestName,
          subtitle: booking.user.email,
          status: booking.status,
          amount: serializeMoney(booking.total),
          createdAt: booking.createdAt,
        })),
      ]
        .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
        .slice(0, 24),
      recentUsers,
      recentProAccounts,
    });
  }),
);

router.patch(
  '/users/:id/ban',
  asyncHandler(async (req, res) => {
    const id = String(req.params.id);
    const banned = req.body?.banned === true;
    const banReason = banned
      ? String(req.body?.banReason || 'Account suspended by admin.')
      : null;
    const user = await prisma.user.update({
      where: { id },
      data: { banned, banReason },
      select: {
        id: true,
        email: true,
        firstName: true,
        lastName: true,
        banned: true,
        banReason: true,
      },
    });
    res.json(user);
  }),
);

router.patch(
  '/pro-accounts/:id/ban',
  asyncHandler(async (req, res) => {
    const id = String(req.params.id);
    const banned = req.body?.banned === true;
    const banReason = banned
      ? String(req.body?.banReason || 'Account suspended by admin.')
      : null;
    const account = await prisma.proAccount.update({
      where: { id },
      data: { banned, banReason },
      select: {
        id: true,
        email: true,
        fullName: true,
        banned: true,
        banReason: true,
      },
    });
    res.json(account);
  }),
);

const RESTAURANT_REDEEM_CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

// GET /admin/pro-profiles/:id/binding-names — resolve the profile's binding
// IDs to real business names so admins can review them by name.
router.get(
  '/pro-profiles/:id/binding-names',
  asyncHandler(async (req, res) => {
    const id = String(req.params.id);
    const profile = await prisma.proProfile.findUnique({
      where: { id },
      select: { bindings: true },
    });
    if (!profile) {
      return res.status(404).json({ error: 'Pro profile not found.' });
    }

    const bindings = (profile.bindings ?? {}) as Record<string, unknown>;
    const idsFrom = (key: string): string[] => {
      const raw = bindings[key];
      return Array.isArray(raw) ? raw.map((entry) => String(entry)) : [];
    };
    const unique = (values: string[]) => Array.from(new Set(values));

    const [
      stores,
      restaurants,
      pharmacies,
      providers,
      doctors,
      laundryServices,
    ] = await Promise.all([
      prisma.shoppingStore.findMany({
        where: { id: { in: unique(idsFrom('shoppingStoreIds')) } },
        select: { id: true, name: true },
      }),
      prisma.restaurant.findMany({
        where: { id: { in: unique(idsFrom('restaurantIds')) } },
        select: { id: true, name: true },
      }),
      prisma.pharmacy.findMany({
        where: { id: { in: unique(idsFrom('pharmacyBusinesses')) } },
        select: { id: true, name: true },
      }),
      prisma.homeServiceProvider.findMany({
        where: { id: { in: unique(idsFrom('providerIds')) } },
        select: { id: true, name: true },
      }),
      prisma.doctor.findMany({
        where: { id: { in: unique(idsFrom('doctorIds')) } },
        select: { id: true, name: true },
      }),
      prisma.laundryService.findMany({
        where: { id: { in: unique(idsFrom('laundryServiceIds')) } },
        select: { id: true, name: true },
      }),
    ]);

    // Keep the same keys as `bindings` so the client can label them
    // consistently; every entry maps an id to its display name.
    res.json({
      names: {
        shoppingStoreIds: stores.map((row) => ({ id: row.id, name: row.name })),
        restaurantIds: restaurants.map((row) => ({
          id: row.id,
          name: row.name,
        })),
        pharmacyBusinesses: pharmacies.map((row) => ({
          id: row.id,
          name: row.name,
        })),
        providerIds: providers.map((row) => ({ id: row.id, name: row.name })),
        doctorIds: doctors.map((row) => ({ id: row.id, name: row.name })),
        laundryServiceIds: laundryServices.map((row) => ({
          id: row.id,
          name: row.name,
        })),
      },
    });
  }),
);

async function nextRestaurantRedeemCode() {
  for (let attempt = 0; attempt < 10; attempt += 1) {
    let code = '';
    for (let index = 0; index < 8; index += 1) {
      code += RESTAURANT_REDEEM_CODE_ALPHABET[randomInt(
        RESTAURANT_REDEEM_CODE_ALPHABET.length,
      )];
    }
    const existing = await prisma.restaurant.findUnique({
      where: { redeemCode: code },
      select: { id: true },
    });
    if (!existing) return code;
  }
  throw new Error('Could not generate a unique restaurant redeem code.');
}

// GET /admin/restaurant-redeem-code/:restaurantId — reveal a restaurant's redeem code.
router.get(
  '/restaurant-redeem-code/:restaurantId',
  asyncHandler(async (req, res) => {
    const id = String(req.params.restaurantId);
    const restaurant = await prisma.restaurant.findUnique({
      where: { id },
      select: { id: true, name: true, redeemCode: true },
    });
    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found.' });
    }
    res.json(restaurant);
  }),
);

// POST /admin/restaurant-redeem-code/:restaurantId/regenerate — issue a fresh code.
router.post(
  '/restaurant-redeem-code/:restaurantId/regenerate',
  asyncHandler(async (req, res) => {
    const id = String(req.params.restaurantId);
    const restaurant = await prisma.restaurant.update({
      where: { id },
      data: { redeemCode: await nextRestaurantRedeemCode() },
      select: { id: true, name: true, redeemCode: true },
    });
    res.json(restaurant);
  }),
);

// GET /admin/pro-profiles/pending — pro profiles awaiting verification.
router.get(
  '/pro-profiles/pending',
  asyncHandler(async (_req, res) => {
    const profiles = await prisma.proProfile.findMany({
      where: { isVerified: false },
      orderBy: { createdAt: 'asc' },
      select: {
        id: true,
        userId: true,
        businessName: true,
        type: true,
        activeModules: true,
        avatarUrl: true,
        isVerified: true,
        bindings: true,
        createdAt: true,
        account: { select: { id: true, email: true, fullName: true, phone: true, banned: true } },
      },
    });
    res.json({ profiles });
  }),
);

// POST /admin/pro-profiles/:id/verify — approve a pro profile.
router.post(
  '/pro-profiles/:id/verify',
  asyncHandler(async (req, res) => {
    const id = String(req.params.id);
    const profile = await prisma.proProfile.update({
      where: { id },
      data: { isVerified: true },
      select: { id: true, businessName: true, isVerified: true },
    });
    res.json(profile);
  }),
);

// POST /admin/pro-profiles/:id/reject — permanently remove a rejected profile
// and its linked pro account so the signup can be redone cleanly.
router.post(
  '/pro-profiles/:id/reject',
  asyncHandler(async (req, res) => {
    const id = String(req.params.id);
    const profile = await prisma.proProfile.findUnique({
      where: { id },
      select: { id: true, accountId: true, businessName: true },
    });
    if (!profile) {
      return res.status(404).json({ error: 'Pro profile not found.' });
    }

    // Prevent admins from rejecting already-verified profiles by mistake.
    const existing = await prisma.proProfile.findUnique({
      where: { id },
      select: { isVerified: true },
    });
    if (existing?.isVerified) {
      return res
        .status(409)
        .json({ error: 'This profile is already verified and cannot be rejected.' });
    }

    await prisma.proProfile.delete({ where: { id } });
    if (profile.accountId) {
      await prisma.proAccount.deleteMany({ where: { id: profile.accountId } });
    }

    res.json({ id: profile.id, rejected: true, businessName: profile.businessName });
  }),
);

export default router;
