"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const notifications_1 = require("../utils/notifications");
const router = (0, express_1.Router)();
const createAppointmentSchema = zod_1.z.object({
    userId: zod_1.z.string(),
    doctorId: zod_1.z.string(),
    date: zod_1.z.string().datetime(),
    timeSlot: zod_1.z.string().min(1),
    type: zod_1.z.string().min(1),
    notes: zod_1.z.string().optional(),
});
const createHomeCareAppointmentSchema = createAppointmentSchema.extend({
    type: zod_1.z.string().min(1).optional(),
});
const updateAppointmentStatusSchema = zod_1.z.object({
    status: zod_1.z.enum([
        'PENDING',
        'APPROVED',
        'REJECTED',
        'COMPLETED',
        'CANCELLED',
        'NO_SHOW',
    ]),
});
const homeCareAppointmentTypes = new Set([
    'home_visit',
    'phone_advice',
    'video_support',
    'nursing_visit',
    'elderly_monitoring',
    'post_op_care',
]);
function serializeAppointmentStatus(status) {
    return status === client_1.AppointmentStatus.UPCOMING
        ? 'pending'
        : status.toLowerCase();
}
function isHomeCareAppointmentType(value) {
    if (value == null)
        return false;
    const normalized = value.trim().toLowerCase();
    if (normalized.length === 0)
        return false;
    return (normalized.startsWith('home_') || homeCareAppointmentTypes.has(normalized));
}
function normalizeHomeCareAppointmentType(value) {
    const normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.length === 0) {
        return 'home_visit';
    }
    if (isHomeCareAppointmentType(normalized)) {
        return normalized;
    }
    return `home_${normalized}`;
}
function serializeAppointment(appointment) {
    return {
        id: appointment.id,
        userId: appointment.userId,
        doctorId: appointment.doctorId,
        date: appointment.appointmentAt,
        timeSlot: appointment.timeSlot,
        type: appointment.appointmentType,
        status: serializeAppointmentStatus(appointment.status),
        notes: appointment.notes,
        createdAt: appointment.createdAt,
        updatedAt: appointment.updatedAt,
        isHomeCare: isHomeCareAppointmentType(appointment.appointmentType),
    };
}
router.get('/home-care/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const appointments = await db_1.prisma.appointment.findMany({
        where: {
            userId,
            OR: [
                { appointmentType: { startsWith: 'home_' } },
                { appointmentType: { in: Array.from(homeCareAppointmentTypes) } },
            ],
        },
        orderBy: { appointmentAt: 'asc' },
    });
    res.json(appointments.map(serializeAppointment));
}));
router.get('/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const appointments = await db_1.prisma.appointment.findMany({
        where: { userId },
        orderBy: { appointmentAt: 'asc' },
    });
    res.json(appointments.map(serializeAppointment));
}));
router.post('/home-care', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createHomeCareAppointmentSchema.parse(req.body);
    const appointment = await db_1.prisma.appointment.create({
        data: {
            userId: body.userId,
            doctorId: body.doctorId,
            appointmentAt: new Date(body.date),
            timeSlot: body.timeSlot,
            appointmentType: normalizeHomeCareAppointmentType(body.type),
            status: client_1.AppointmentStatus.PENDING,
            notes: body.notes ?? 'Home care booking via EdaLab Super App',
        },
        include: {
            doctor: true,
        },
    });
    await (0, notifications_1.createAppointmentCreatedNotification)({
        userId: appointment.userId,
        appointmentId: appointment.id,
        doctorName: appointment.doctor.name,
        timeSlot: appointment.timeSlot,
    });
    res.status(201).json(serializeAppointment(appointment));
}));
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createAppointmentSchema.parse(req.body);
    const appointment = await db_1.prisma.appointment.create({
        data: {
            userId: body.userId,
            doctorId: body.doctorId,
            appointmentAt: new Date(body.date),
            timeSlot: body.timeSlot,
            appointmentType: body.type,
            status: client_1.AppointmentStatus.PENDING,
            notes: body.notes ?? null,
        },
        include: {
            doctor: true,
        },
    });
    await (0, notifications_1.createAppointmentCreatedNotification)({
        userId: appointment.userId,
        appointmentId: appointment.id,
        doctorName: appointment.doctor.name,
        timeSlot: appointment.timeSlot,
    });
    res.status(201).json(serializeAppointment(appointment));
}));
router.patch('/:appointmentId/status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const appointmentId = (0, http_1.getParam)(req.params.appointmentId, 'appointmentId');
    const body = updateAppointmentStatusSchema.parse(req.body);
    const appointment = await db_1.prisma.appointment.update({
        where: { id: appointmentId },
        data: { status: body.status },
    });
    res.json(serializeAppointment(appointment));
}));
exports.default = router;
