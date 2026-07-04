"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const db_1 = require("../db");
const auth_1 = require("../middleware/auth");
const async_handler_1 = require("../utils/async-handler");
const router = (0, express_1.Router)();
function configuredAdminEmails() {
    return (process.env.SUPER_ADMIN_EMAILS || process.env.SUPER_ADMIN_EMAIL || 'admin@edalab.com')
        .split(',')
        .map((email) => email.trim().toLowerCase())
        .filter(Boolean);
}
async function requireSuperAdmin(req, res, next) {
    if (req.auth?.accountType !== 'pro') {
        return res.status(403).json({ error: 'Super admin access requires a pro account.' });
    }
    const account = await db_1.prisma.proAccount.findUnique({
        where: { id: req.auth.userId },
        select: { email: true, banned: true },
    });
    const email = account?.email.toLowerCase().trim() ?? '';
    const allowedEmails = configuredAdminEmails();
    const allowed = allowedEmails.includes(email) || email.startsWith('admin@') || email.includes('+admin@');
    if (!account || account.banned || !allowed) {
        return res.status(403).json({ error: 'Super admin access is required.' });
    }
    next();
}
router.use(auth_1.requireAuth, requireSuperAdmin);
function serializeMoney(value) {
    return Number(value ?? 0);
}
function countByStatus(rows) {
    return rows.map((row) => ({
        status: String(row.status),
        count: typeof row._count === 'number'
            ? row._count
            : Number(row._count?._all ?? 0),
    }));
}
router.get('/overview', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const [userCount, bannedUserCount, proAccountCount, bannedProAccountCount, proProfileCount, orderCount, rideCount, appointmentCount, laundryOrderCount, hotelBookingCount, todayOrders, todayRides, todayAppointments, orderRevenue, rideRevenue, laundryRevenue, hotelRevenue, orderStatus, rideStatus, appointmentStatus, laundryStatus, hotelStatus, recentOrders, recentRides, recentAppointments, recentLaundryOrders, recentHotelBookings, recentUsers, recentProAccounts,] = await Promise.all([
        db_1.prisma.user.count(),
        db_1.prisma.user.count({ where: { banned: true } }),
        db_1.prisma.proAccount.count(),
        db_1.prisma.proAccount.count({ where: { banned: true } }),
        db_1.prisma.proProfile.count(),
        db_1.prisma.order.count(),
        db_1.prisma.rideBooking.count(),
        db_1.prisma.appointment.count(),
        db_1.prisma.laundryOrder.count(),
        db_1.prisma.hotelBooking.count(),
        db_1.prisma.order.count({ where: { createdAt: { gte: since } } }),
        db_1.prisma.rideBooking.count({ where: { createdAt: { gte: since } } }),
        db_1.prisma.appointment.count({ where: { createdAt: { gte: since } } }),
        db_1.prisma.order.aggregate({ _sum: { total: true } }),
        db_1.prisma.rideBooking.aggregate({ _sum: { total: true } }),
        db_1.prisma.laundryOrder.aggregate({ _sum: { total: true } }),
        db_1.prisma.hotelBooking.aggregate({ _sum: { total: true } }),
        db_1.prisma.order.groupBy({ by: ['status'], _count: { _all: true } }),
        db_1.prisma.rideBooking.groupBy({ by: ['status'], _count: { _all: true } }),
        db_1.prisma.appointment.groupBy({ by: ['status'], _count: { _all: true } }),
        db_1.prisma.laundryOrder.groupBy({ by: ['status'], _count: { _all: true } }),
        db_1.prisma.hotelBooking.groupBy({ by: ['status'], _count: { _all: true } }),
        db_1.prisma.order.findMany({
            take: 12,
            orderBy: { createdAt: 'desc' },
            include: { user: { select: { email: true, firstName: true, lastName: true } } },
        }),
        db_1.prisma.rideBooking.findMany({
            take: 12,
            orderBy: { createdAt: 'desc' },
            include: { user: { select: { email: true, firstName: true, lastName: true } } },
        }),
        db_1.prisma.appointment.findMany({
            take: 12,
            orderBy: { createdAt: 'desc' },
            include: { user: { select: { email: true, firstName: true, lastName: true } } },
        }),
        db_1.prisma.laundryOrder.findMany({
            take: 12,
            orderBy: { createdAt: 'desc' },
            include: { user: { select: { email: true, firstName: true, lastName: true } } },
        }),
        db_1.prisma.hotelBooking.findMany({
            take: 12,
            orderBy: { createdAt: 'desc' },
            include: { user: { select: { email: true, firstName: true, lastName: true } } },
        }),
        db_1.prisma.user.findMany({
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
        db_1.prisma.proAccount.findMany({
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
    const revenueTotal = serializeMoney(orderRevenue._sum.total) +
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
}));
router.patch('/users/:id/ban', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const id = String(req.params.id);
    const banned = req.body?.banned === true;
    const banReason = banned
        ? String(req.body?.banReason || 'Account suspended by admin.')
        : null;
    const user = await db_1.prisma.user.update({
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
}));
router.patch('/pro-accounts/:id/ban', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const id = String(req.params.id);
    const banned = req.body?.banned === true;
    const banReason = banned
        ? String(req.body?.banReason || 'Account suspended by admin.')
        : null;
    const account = await db_1.prisma.proAccount.update({
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
}));
exports.default = router;
