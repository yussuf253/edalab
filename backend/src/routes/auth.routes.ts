import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { hashPassword, verifyPassword } from '../utils/password';
import { signAccessToken } from '../utils/jwt';
import { parseFullName, sanitizeUser } from '../utils/serializers';
import {
  createEmailVerificationChallenge,
  hashEmailVerificationToken,
  hasPendingEmailVerification,
  sendEmailVerification,
} from '../utils/email-verification';

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

const emailSchema = z.object({
  email: z.string().email(),
});

const verifyEmailSchema = z.object({
  token: z.string().trim().min(16),
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

    const name = parseFullName(body.name);
    const verification = createEmailVerificationChallenge();
    const user = await prisma.user.create({
      data: {
        email,
        firstName: name.firstName,
        lastName: name.lastName,
        phone: body.phone?.trim() || null,
        passwordHash: await hashPassword(body.password),
        emailVerifiedAt: null,
        emailVerificationTokenHash: verification.tokenHash,
        emailVerificationExpiresAt: verification.expiresAt,
        emailVerificationSentAt: new Date(),
      },
      include: {
        addresses: {
          orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
        },
      },
    });

    const delivery = await sendEmailVerification({
      email: user.email,
      name: [user.firstName, user.lastName].filter(Boolean).join(' '),
      token: verification.token,
      kind: 'auth',
    });

    res.status(201).json({
      requiresEmailVerification: true,
      email: user.email,
      verificationEmailSent: delivery.sent,
      verificationUrl: delivery.verificationUrl,
      devToken: delivery.devToken,
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

    if (hasPendingEmailVerification(user)) {
      return res.status(403).json({
        code: 'EMAIL_NOT_VERIFIED',
        error: 'Please verify your email address before signing in.',
        email: user.email,
      });
    }

    const safeUser = sanitizeUser(user);
    const token = signAccessToken({ userId: user.id, email: user.email });

    res.json({ token, user: safeUser });
  }),
);

router.post(
  '/resend-verification',
  asyncHandler(async (req, res) => {
    const body = emailSchema.parse(req.body);
    const user = await prisma.user.findUnique({
      where: { email: body.email.toLowerCase() },
    });

    if (!user || !hasPendingEmailVerification(user)) {
      return res.json({ ok: true });
    }

    const verification = createEmailVerificationChallenge();
    await prisma.user.update({
      where: { id: user.id },
      data: {
        emailVerificationTokenHash: verification.tokenHash,
        emailVerificationExpiresAt: verification.expiresAt,
        emailVerificationSentAt: new Date(),
      },
    });

    const delivery = await sendEmailVerification({
      email: user.email,
      name: [user.firstName, user.lastName].filter(Boolean).join(' '),
      token: verification.token,
      kind: 'auth',
    });

    res.json({
      ok: true,
      verificationEmailSent: delivery.sent,
      verificationUrl: delivery.verificationUrl,
      devToken: delivery.devToken,
    });
  }),
);

async function verifyUserEmail(token: string) {
  const tokenHash = hashEmailVerificationToken(token);
  const user = await prisma.user.findFirst({
    where: { emailVerificationTokenHash: tokenHash },
  });

  if (!user) {
    return { status: 400, payload: { error: 'Invalid verification link.' } };
  }

  if (
    user.emailVerificationExpiresAt != null &&
    user.emailVerificationExpiresAt.getTime() < Date.now()
  ) {
    return {
      status: 400,
      payload: { error: 'This verification link has expired.' },
    };
  }

  await prisma.user.update({
    where: { id: user.id },
    data: {
      emailVerifiedAt: new Date(),
      emailVerificationTokenHash: null,
      emailVerificationExpiresAt: null,
      emailVerificationSentAt: null,
    },
  });

  return {
    status: 200,
    payload: { verified: true, email: user.email },
  };
}

router.get(
  '/verify-email',
  asyncHandler(async (req, res) => {
    const body = verifyEmailSchema.parse({ token: req.query.token });
    const result = await verifyUserEmail(body.token);
    res.status(result.status).json(result.payload);
  }),
);

router.post(
  '/verify-email',
  asyncHandler(async (req, res) => {
    const body = verifyEmailSchema.parse(req.body);
    const result = await verifyUserEmail(body.token);
    res.status(result.status).json(result.payload);
  }),
);

export default router;
