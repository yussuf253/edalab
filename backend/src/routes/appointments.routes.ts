import { AppointmentStatus, ModuleType } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { isModuleEnabled, moduleName } from '../utils/module-settings';
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

const createHomeCareAppointmentSchema = createAppointmentSchema.extend({
  type: z.string().min(1).optional(),
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

const homeCareAppointmentTypes = new Set<string>([
  'home_visit',
  'phone_advice',
  'video_support',
  'nursing_visit',
  'elderly_monitoring',
  'post_op_care',
]);

function serializeAppointmentStatus(status: AppointmentStatus) {
  return status === AppointmentStatus.UPCOMING
    ? 'pending'
    : status.toLowerCase();
}

function isHomeCareAppointmentType(value: string | null | undefined) {
  if (value == null) return false;
  const normalized = value.trim().toLowerCase();
  if (normalized.length === 0) return false;
  return (
    normalized.startsWith('home_') || homeCareAppointmentTypes.has(normalized)
  );
}

function normalizeHomeCareAppointmentType(value: string | undefined) {
  const normalized = value?.trim().toLowerCase() ?? '';
  if (normalized.length === 0) {
    return 'home_visit';
  }
  if (isHomeCareAppointmentType(normalized)) {
    return normalized;
  }
  return `home_${normalized}`;
}

function serializeAppointment(
  appointment: {
    id: string;
    userId: string;
    doctorId: string;
    appointmentAt: Date;
    timeSlot: string;
    appointmentType: string;
    status: AppointmentStatus;
    notes: string | null;
    createdAt: Date;
    updatedAt: Date;
  },
) {
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

router.get(
  '/home-care/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const appointments = await prisma.appointment.findMany({
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
  }),
);

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const appointments = await prisma.appointment.findMany({
      where: { userId },
      orderBy: { appointmentAt: 'asc' },
    });

    res.json(appointments.map(serializeAppointment));
  }),
);

router.post(
  '/home-care',
  asyncHandler(async (req, res) => {
    const body = createHomeCareAppointmentSchema.parse(req.body);

    if (!(await isModuleEnabled(ModuleType.DOCTOR))) {
      return res.status(403).json({
        error: `${moduleName(ModuleType.DOCTOR)} module is currently disabled.`,
      });
    }

    const appointment = await prisma.appointment.create({
      data: {
        userId: body.userId,
        doctorId: body.doctorId,
        appointmentAt: new Date(body.date),
        timeSlot: body.timeSlot,
        appointmentType: normalizeHomeCareAppointmentType(body.type),
        status: AppointmentStatus.PENDING,
        notes: body.notes ?? 'Home care booking via EdaLab Super App',
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

    res.status(201).json(serializeAppointment(appointment));
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const body = createAppointmentSchema.parse(req.body);

    if (!(await isModuleEnabled(ModuleType.DOCTOR))) {
      return res.status(403).json({
        error: `${moduleName(ModuleType.DOCTOR)} module is currently disabled.`,
      });
    }

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

    res.status(201).json(serializeAppointment(appointment));
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

    res.json(serializeAppointment(appointment));
  }),
);

export default router;
