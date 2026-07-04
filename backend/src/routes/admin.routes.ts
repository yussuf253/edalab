import { Router } from 'express';
import type { NextFunction, Request, Response } from 'express';
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

export default router;
