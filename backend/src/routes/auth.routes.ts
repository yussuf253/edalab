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

const confirmSchema = z.object({
  token: z.string().trim().min(1),
  email: z.string().email(),
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
    
    // Create user in Supabase Auth with metadata (handles email verification)
    const { data: authData, error: authError } = await supabaseAdmin.auth.signUp({
      email,
      password: body.password,
      options: {
        emailRedirectTo: `${env.PUBLIC_BASE_URL}/auth/confirm`,
        data: {
          displayName: [name.firstName, name.lastName].filter(Boolean).join(' '),
          phone: body.phone?.trim() || null,
        },
      },
    });

    if (authError) {
      return res.status(400).json({ error: authError.message });
    }

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

    // Return message about email verification - don't return token yet
    res.status(201).json({
      message: 'Please check your email to verify your account before signing in.',
      email: user.email,
      requiresEmailVerification: true,
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

    // Check if user is banned
    if (user.banned) {
      return res.status(403).json({ 
        error: 'Your account has been suspended.',
        banReason: user.banReason,
        banned: true,
      });
    }

    const safeUser = sanitizeUser(user);
    const token = signAccessToken({ userId: user.id, email: user.email });

    res.json({ token, user: safeUser });
  }),
);

// Handle email confirmation redirect from Supabase
router.post(
  '/confirm',
  asyncHandler(async (req, res) => {
    const body = confirmSchema.parse(req.body);
    const { token, email } = body;

    // Verify the token with Supabase
    const { data: authData, error: authError } = await supabaseAdmin.auth.verifyOtp({
      token,
      email,
      type: 'signup',
    });

    if (authError || !authData.user) {
      return res.status(400).json({ 
        error: 'Invalid or expired verification link.',
        verified: false,
      });
    }

    // Get the user from Prisma
    const user = await prisma.user.findUnique({
      where: { email: authData.user.email },
      include: {
        addresses: {
          orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
        },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    // Check if user is banned
    if (user.banned) {
      return res.status(403).json({ 
        error: 'Your account has been suspended.',
        banReason: user.banReason,
        banned: true,
      });
    }

    const safeUser = sanitizeUser(user);
    const jwtToken = signAccessToken({ userId: user.id, email: user.email });

    res.json({
      message: 'Email verified successfully!',
      verified: true,
      user: safeUser,
      token: jwtToken,
    });
  }),
);

// GET endpoint for email confirmation (called by frontend after redirect)
router.get(
  '/confirm',
  asyncHandler(async (req, res) => {
    const accessToken = req.query.access_token as string;
    const tokenType = req.query.token_type as string;
    const expiresIn = req.query.expires_in as string;

    if (!accessToken || tokenType !== 'bearer') {
      return res.status(400).json({ 
        error: 'Invalid verification parameters.',
        verified: false,
      });
    }

    // Verify the access token with Supabase
    const { data: authData, error: authError } = await supabaseAdmin.auth.getUser(accessToken);

    if (authError || !authData.user) {
      return res.status(400).json({ 
        error: 'Invalid or expired verification link.',
        verified: false,
      });
    }

    // Get the user from Prisma
    const user = await prisma.user.findUnique({
      where: { email: authData.user.email },
      include: {
        addresses: {
          orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
        },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    // Check if user is banned
    if (user.banned) {
      return res.status(403).json({ 
        error: 'Your account has been suspended.',
        banReason: user.banReason,
        banned: true,
      });
    }

    const safeUser = sanitizeUser(user);
    const jwtToken = signAccessToken({ userId: user.id, email: user.email });

    // Return HTML page that auto-closes and sends token to frontend
    res.send(`
      <!DOCTYPE html>
      <html>
      <head><title>Email Verified</title></head>
      <body>
        <script>
          window.opener.postMessage({ type: 'EMAIL_VERIFIED', token: '${jwtToken}', user: ${JSON.stringify(safeUser)} }, '*');
          window.close();
        </script>
      </body>
      </html>
    `);
  }),
);

export default router;
