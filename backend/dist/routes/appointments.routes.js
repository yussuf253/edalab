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
function serializeAppointmentStatus(status) {
    return status === client_1.AppointmentStatus.UPCOMING ? 'pending' : status.toLowerCase();
}
router.get('/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const appointments = await db_1.prisma.appointment.findMany({
        where: { userId },
        orderBy: { appointmentAt: 'asc' },
    });
    res.json(appointments.map((appointment) => ({
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
    })));
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
    res.status(201).json({
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
    });
}));
router.patch('/:appointmentId/status', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const appointmentId = (0, http_1.getParam)(req.params.appointmentId, 'appointmentId');
    const body = updateAppointmentStatusSchema.parse(req.body);
    const appointment = await db_1.prisma.appointment.update({
        where: { id: appointmentId },
        data: { status: body.status },
    });
    res.json({
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
    });
}));
exports.default = router;
