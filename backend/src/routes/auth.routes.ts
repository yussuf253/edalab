import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { hashPassword, verifyPassword } from '../utils/password';
import { signAccessToken } from '../utils/jwt';
import { parseFullName, sanitizeUser } from '../utils/serializers';

const router = Router();

const registerSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2),
  phone: z.string().trim().optional().or(z.literal('')),
  password: z.string().min(6),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const body = registerSchema.parse(req.body);
    const existingUser = await prisma.user.findUnique({
      where: { email: body.email.toLowerCase() },
    });

    if (existingUser) {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }

    const name = parseFullName(body.name);
    const user = await prisma.user.create({
      data: {
        email: body.email.toLowerCase(),
        firstName: name.firstName,
        lastName: name.lastName,
        phone: body.phone?.trim() || null,
        passwordHash: await hashPassword(body.password),
      },
      include: {
        addresses: {
          orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
        },
      },
    });

    const safeUser = sanitizeUser(user);
    const token = signAccessToken({ userId: user.id, email: user.email });

    res.status(201).json({ token, user: safeUser });
  }),
);

router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const body = loginSchema.parse(req.body);
    const user = await prisma.user.findUnique({
      where: { email: body.email.toLowerCase() },
      include: {
        addresses: {
          orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
        },
      },
    });

    if (!user || !(await verifyPassword(body.password, user.passwordHash))) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const safeUser = sanitizeUser(user);
    const token = signAccessToken({ userId: user.id, email: user.email });

    res.json({ token, user: safeUser });
  }),
);

export default router;
