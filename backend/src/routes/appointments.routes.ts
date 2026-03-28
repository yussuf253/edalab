import { AppointmentStatus } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { createAppointmentCreatedNotification } from '../utils/notifications';

const router = Router();

const createAppointmentSchema = z.object({
  userId: z.string(),
  doctorId: z.string(),
  date: z.string().datetime(),
  timeSlot: z.string().min(1),
  type: z.string().min(1),
  notes: z.string().optional(),
});

const updateAppointmentStatusSchema = z.object({
  status: z.enum([
    'PENDING',
    'APPROVED',
    'REJECTED',
    'COMPLETED',
    'CANCELLED',
    'NO_SHOW',
  ]),
});

function serializeAppointmentStatus(status: AppointmentStatus) {
  return status === AppointmentStatus.UPCOMING ? 'pending' : status.toLowerCase();
}

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const appointments = await prisma.appointment.findMany({
      where: { userId },
      orderBy: { appointmentAt: 'asc' },
    });

    res.json(
      appointments.map((appointment) => ({
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
      })),
    );
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const body = createAppointmentSchema.parse(req.body);

    const appointment = await prisma.appointment.create({
      data: {
        userId: body.userId,
        doctorId: body.doctorId,
        appointmentAt: new Date(body.date),
        timeSlot: body.timeSlot,
        appointmentType: body.type,
        status: AppointmentStatus.PENDING,
        notes: body.notes ?? null,
      },
      include: {
        doctor: true,
      },
    });

    await createAppointmentCreatedNotification({
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
  }),
);

router.patch(
  '/:appointmentId/status',
  asyncHandler(async (req, res) => {
    const appointmentId = getParam(req.params.appointmentId, 'appointmentId');
    const body = updateAppointmentStatusSchema.parse(req.body);

    const appointment = await prisma.appointment.update({
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
  }),
);

export default router;
