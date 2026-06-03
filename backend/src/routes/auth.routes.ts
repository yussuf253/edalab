import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { hashPassword, verifyPassword } from '../utils/password';
import { signAccessToken } from '../utils/jwt';
import { parseFullName, sanitizeUser } from '../utils/serializers';
import { supabaseAdmin } from '../services/supabase-admin.service';
import { env } from '../config/env';

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
    const email = body.email.toLowerCase();
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }

    // Create user in Supabase Auth (handles email verification)
    const { data: authData, error: authError } = await supabaseAdmin.auth.signUp({
      email,
      password: body.password,
      options: {
        emailRedirectTo: `${env.PUBLIC_BASE_URL}/auth/confirm`,
      },
    });

    if (authError) {
      return res.status(400).json({ error: authError.message });
    }

    const name = parseFullName(body.name);
    const user = await prisma.user.create({
      data: {
        email,
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

    res.status(201).json({
      user: sanitizeUser(user),
      token: signAccessToken({ userId: user.id, email: user.email }),
    });
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
