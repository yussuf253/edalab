import { ProModule, ProProfileType } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';
import {
  resolveBindings,
  sanitizeProviderBindingOverrides,
  syncLaundryOwnership,
} from './pro.routes';
import { asyncHandler } from '../utils/async-handler';
import { signAccessToken } from '../utils/jwt';
import { hashPassword, verifyPassword } from '../utils/password';
import { parseFullName } from '../utils/serializers';
import { supabaseAdmin } from '../services/supabase-admin.service';
import { env } from '../config/env';

const router = Router();

const proAccountRegisterSchema = z.object({
  fullName: z.string().trim().min(2),
  email: z.string().trim().email(),
  phone: z.string().trim().optional().or(z.literal('')),
  password: z.string().min(6),
});

const proAccountLoginSchema = z.object({
  email: z.string().trim().email(),
  password: z.string().min(1),
});

const confirmSchema = z.object({
  token: z.string().trim().min(1),
  email: z.string().email(),
});

const proProfileSetupSchema = z.object({
  type: z.nativeEnum(ProProfileType),
  activeModules: z.array(z.nativeEnum(ProModule)).min(1),
  businessName: z.string().trim().min(2),
  avatarUrl: z.string().trim().optional().nullable(),
  bindingOverrides: z
    .object({
      providerIds: z.array(z.string().min(1)).optional(),
      laundryServiceIds: z.array(z.string().min(1)).optional(),
    })
    .optional(),
});

function serializeProAccount(account: {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  avatarUrl: string | null;
  createdAt: Date;
  updatedAt: Date;
}) {
  return {
    id: account.id,
    email: account.email,
    fullName: account.fullName,
    phone: account.phone,
    avatarUrl: account.avatarUrl,
    createdAt: account.createdAt,
    updatedAt: account.updatedAt,
  };
}

function serializeProProfile(profile: {
  id: string;
  accountId: string | null;
  userId: string;
  type: ProProfileType;
  activeModules: ProModule[];
  businessName: string;
  avatarUrl: string | null;
  isOnline: boolean;
  isVerified: boolean;
  createdAt: Date;
  updatedAt: Date;
}) {
  return {
    id: profile.id,
    accountId: profile.accountId,
    userId: profile.userId,
    type: profile.type.toLowerCase(),
    activeModules: profile.activeModules.map((module) => module.toLowerCase()),
    businessName: profile.businessName,
    avatarUrl: profile.avatarUrl,
    isOnline: profile.isOnline,
    isVerified: profile.isVerified,
    createdAt: profile.createdAt,
    updatedAt: profile.updatedAt,
  };
}

function allowedModulesForProfile(type: ProProfileType): ProModule[] {
  switch (type) {
    case ProProfileType.SHOP:
      return [ProModule.SHOPPING, ProModule.FOOD, ProModule.PHARMACY];
    case ProProfileType.PROVIDER:
      return [ProModule.SERVICES, ProModule.LAUNDRY];
    case ProProfileType.DOCTOR:
      return [ProModule.DOCTOR];
    case ProProfileType.DELIVERY:
      return [
        ProModule.SHOPPING_DELIVERY,
        ProModule.FOOD_DELIVERY,
        ProModule.PHARMACY_DELIVERY,
      ];
    case ProProfileType.RIDER:
      return [ProModule.RIDE];
  }
}

function sanitizeModulesForProfile(
  type: ProProfileType,
  modules: ProModule[],
): ProModule[] {
  const allowed = new Set(allowedModulesForProfile(type));
  const sanitized = Array.from(
    new Set(modules.filter((module) => allowed.has(module))),
  );

  return sanitized.length > 0 ? sanitized : [allowedModulesForProfile(type)[0]];
}

function normalizeBindingsForProfileType(
  type: ProProfileType,
  bindings: Awaited<ReturnType<typeof resolveBindings>>,
) {
  if (type !== ProProfileType.PROVIDER) {
    return bindings;
  }

  return {
    ...bindings,
    providerIds: [],
    laundryServiceIds: [],
  };
}

function proAccountIdFromRequest(req: Express.Request) {
  return req.auth?.accountType == 'pro' ? req.auth.userId : null;
}

function buildInternalUserEmail(accountId: string) {
  return `pro-${accountId}@edalab.internal`;
}

router.post(
  '/register',
  asyncHandler(async (req, res) => {
    const body = proAccountRegisterSchema.parse(req.body);
    const email = body.email.toLowerCase();
    const existingAccount = await prisma.proAccount.findUnique({
      where: { email },
    });

    if (existingAccount) {
      return res
        .status(409)
        .json({ error: 'A pro account with this email already exists.' });
    }

    // Create user in Supabase Auth with metadata (handles email verification)
    const { data: authData, error: authError } = await supabaseAdmin.auth.signUp({
      email,
      password: body.password,
      options: {
        emailRedirectTo: `${env.PUBLIC_BASE_URL}/auth/confirm`,
        data: {
          displayName: body.fullName.trim(),
          phone: body.phone?.trim() || null,
        },
      },
    });

    if (authError) {
      return res.status(400).json({ error: authError.message });
    }

    const account = await prisma.proAccount.create({
      data: {
        email,
        fullName: body.fullName.trim(),
        phone: body.phone?.trim() || null,
        passwordHash: await hashPassword(body.password),
      },
    });

    // Return message about email verification - don't return account data yet
    res.status(201).json({
      message: 'Please check your email to verify your account before signing in.',
      email: account.email,
      requiresEmailVerification: true,
    });
  }),
);

router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const body = proAccountLoginSchema.parse(req.body);
    const email = body.email.toLowerCase();
    const account = await prisma.proAccount.findUnique({
      where: { email },
      include: { proProfile: true },
    });

    if (!account || !(await verifyPassword(body.password, account.passwordHash))) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    // Check if account is banned
    if (account.banned) {
      return res.status(403).json({ 
        error: 'Your account has been suspended.',
        banReason: account.banReason,
        banned: true,
      });
    }

    const token = signAccessToken({
      userId: account.id,
      email: account.email,
      accountType: 'pro',
    });

    res.json({
      token,
      account: serializeProAccount(account),
      profile: account.proProfile ? serializeProProfile(account.proProfile) : null,
    });
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

    // Get the account from Prisma
    const account = await prisma.proAccount.findUnique({
      where: { email: authData.user.email },
      include: { proProfile: true },
    });

    if (!account) {
      return res.status(404).json({ error: 'Account not found.' });
    }

    const tokenResult = signAccessToken({
      userId: account.id,
      email: account.email,
      accountType: 'pro',
    });

    res.json({
      message: 'Email verified successfully!',
      verified: true,
      account: serializeProAccount(account),
      profile: account.proProfile ? serializeProProfile(account.proProfile) : null,
      token: tokenResult,
    });
  }),
);

// GET endpoint for email confirmation (called by frontend after redirect)
router.get(
  '/confirm',
  asyncHandler(async (req, res) => {
    const accessToken = req.query.access_token as string;
    const tokenType = req.query.token_type as string;

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

    // Get the account from Prisma
    const account = await prisma.proAccount.findUnique({
      where: { email: authData.user.email },
      include: { proProfile: true },
    });

    if (!account) {
      return res.status(404).json({ error: 'Account not found.' });
    }

    const tokenResult = signAccessToken({
      userId: account.id,
      email: account.email,
      accountType: 'pro',
    });

    const profileJson = account.proProfile ? JSON.stringify(serializeProAccount(account)) : 'null';
    
    // Return HTML page that auto-closes and sends token to frontend
    res.send(`
      <!DOCTYPE html>
      <html>
      <head><title>Email Verified</title></head>
      <body>
        <script>
          window.opener.postMessage({ 
            type: 'PRO_EMAIL_VERIFIED', 
            token: '${tokenResult}', 
            account: ${JSON.stringify(serializeProAccount(account))},
            profile: ${profileJson}
          }, '*');
          window.close();
        </script>
      </body>
      </html>
    `);
  }),
);
router.get(
  '/me',
  requireAuth,
  asyncHandler(async (req, res) => {
    const accountId = proAccountIdFromRequest(req);
    if (accountId == null) {
      return res
        .status(403)
        .json({ error: 'This endpoint requires a pro account session.' });
    }

    const account = await prisma.proAccount.findUnique({
      where: { id: accountId },
      include: { proProfile: true },
    });

    if (!account) {
      return res.status(404).json({ error: 'Pro account not found.' });
    }

    // Check if account is banned
    if (account.banned) {
      return res.status(403).json({
        error: 'Your account has been suspended.',
        banReason: account.banReason,
        banned: true,
      });
    }

    res.json({
      account: serializeProAccount(account),
      profile: account.proProfile ? serializeProProfile(account.proProfile) : null,
    });
  }),
);

export default router;
