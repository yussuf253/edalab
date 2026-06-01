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
import {
  createEmailVerificationChallenge,
  hashEmailVerificationToken,
  hasPendingEmailVerification,
  sendEmailVerification,
} from '../utils/email-verification';

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

const emailSchema = z.object({
  email: z.string().trim().email(),
});

const verifyEmailSchema = z.object({
  token: z.string().trim().min(16),
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

    const verification = createEmailVerificationChallenge();
    const account = await prisma.proAccount.create({
      data: {
        email,
        fullName: body.fullName.trim(),
        phone: body.phone?.trim() || null,
        passwordHash: await hashPassword(body.password),
        emailVerifiedAt: null,
        emailVerificationTokenHash: verification.tokenHash,
        emailVerificationExpiresAt: verification.expiresAt,
        emailVerificationSentAt: new Date(),
      },
    });

    const delivery = await sendEmailVerification({
      email: account.email,
      name: account.fullName,
      token: verification.token,
      kind: 'pro-auth',
    });

    res.status(201).json({
      requiresEmailVerification: true,
      email: account.email,
      verificationEmailSent: delivery.sent,
      verificationUrl: delivery.verificationUrl,
      devToken: delivery.devToken,
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

    if (hasPendingEmailVerification(account)) {
      return res.status(403).json({
        code: 'EMAIL_NOT_VERIFIED',
        error: 'Please verify your email address before signing in.',
        email: account.email,
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

router.post(
  '/resend-verification',
  asyncHandler(async (req, res) => {
    const body = emailSchema.parse(req.body);
    const account = await prisma.proAccount.findUnique({
      where: { email: body.email.toLowerCase() },
    });

    if (!account || !hasPendingEmailVerification(account)) {
      return res.json({ ok: true });
    }

    const verification = createEmailVerificationChallenge();
    await prisma.proAccount.update({
      where: { id: account.id },
      data: {
        emailVerificationTokenHash: verification.tokenHash,
        emailVerificationExpiresAt: verification.expiresAt,
        emailVerificationSentAt: new Date(),
      },
    });

    const delivery = await sendEmailVerification({
      email: account.email,
      name: account.fullName,
      token: verification.token,
      kind: 'pro-auth',
    });

    res.json({
      ok: true,
      verificationEmailSent: delivery.sent,
      verificationUrl: delivery.verificationUrl,
      devToken: delivery.devToken,
    });
  }),
);

async function verifyProEmail(token: string) {
  const tokenHash = hashEmailVerificationToken(token);
  const account = await prisma.proAccount.findFirst({
    where: { emailVerificationTokenHash: tokenHash },
  });

  if (!account) {
    return { status: 400, payload: { error: 'Invalid verification link.' } };
  }

  if (
    account.emailVerificationExpiresAt != null &&
    account.emailVerificationExpiresAt.getTime() < Date.now()
  ) {
    return {
      status: 400,
      payload: { error: 'This verification link has expired.' },
    };
  }

  await prisma.proAccount.update({
    where: { id: account.id },
    data: {
      emailVerifiedAt: new Date(),
      emailVerificationTokenHash: null,
      emailVerificationExpiresAt: null,
      emailVerificationSentAt: null,
    },
  });

  return {
    status: 200,
    payload: { verified: true, email: account.email },
  };
}

router.get(
  '/verify-email',
  asyncHandler(async (req, res) => {
    const body = verifyEmailSchema.parse({ token: req.query.token });
    const result = await verifyProEmail(body.token);
    res.status(result.status).json(result.payload);
  }),
);

router.post(
  '/verify-email',
  asyncHandler(async (req, res) => {
    const body = verifyEmailSchema.parse(req.body);
    const result = await verifyProEmail(body.token);
    res.status(result.status).json(result.payload);
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

    res.json({
      account: serializeProAccount(account),
      profile: account.proProfile ? serializeProProfile(account.proProfile) : null,
    });
  }),
);

router.post(
  '/profile',
  requireAuth,
  asyncHandler(async (req, res) => {
    const accountId = proAccountIdFromRequest(req);
    if (accountId == null) {
      return res
        .status(403)
        .json({ error: 'This endpoint requires a pro account session.' });
    }
    const body = proProfileSetupSchema.parse(req.body);
    const activeModules = sanitizeModulesForProfile(
      body.type,
      body.activeModules,
    );
    const resolvedBindingsRaw = await resolveBindings(
      body.businessName.trim(),
      activeModules,
    );
    const resolvedBindings = normalizeBindingsForProfileType(
      body.type,
      resolvedBindingsRaw,
    );
    const bindingOverrides = body.bindingOverrides;
    const sanitizedOverrides =
      bindingOverrides == null
        ? null
        : await sanitizeProviderBindingOverrides(activeModules, bindingOverrides);
    const mergedBindings = {
      ...resolvedBindings,
      ...(bindingOverrides?.providerIds === undefined
        ? {}
        : { providerIds: sanitizedOverrides?.providerIds ?? [] }),
      ...(bindingOverrides?.laundryServiceIds === undefined
        ? {}
        : { laundryServiceIds: sanitizedOverrides?.laundryServiceIds ?? [] }),
    };
    const avatarUrl = body.avatarUrl?.trim() || null;

    const payload = await prisma.$transaction(async (tx) => {
      const account = await tx.proAccount.findUnique({
        where: { id: accountId },
        include: { proProfile: true },
      });

      if (!account) {
        throw new Error('Pro account not found.');
      }

      if (account.proProfile) {
        const ownedLaundryServiceIds = await syncLaundryOwnership(
          account.proProfile.userId,
          body.type,
          activeModules,
          mergedBindings,
          tx,
        );
        const bindings = {
          ...mergedBindings,
          laundryServiceIds: ownedLaundryServiceIds,
        };
        const updatedProfile = await tx.proProfile.update({
          where: { id: account.proProfile.id },
          data: {
            type: body.type,
            activeModules,
            businessName: body.businessName.trim(),
            avatarUrl,
            bindings,
          },
        });

        const updatedAccount = await tx.proAccount.update({
          where: { id: account.id },
          data: {
            avatarUrl: avatarUrl ?? account.avatarUrl,
          },
        });

        return {
          account: updatedAccount,
          profile: updatedProfile,
          created: false,
        };
      }

      const legacyUser = await tx.user.findUnique({
        where: { email: account.email },
        include: { proProfile: true },
      });

      if (
        legacyUser?.proProfile != null &&
        legacyUser.proProfile.accountId == null
      ) {
        const ownedLaundryServiceIds = await syncLaundryOwnership(
          legacyUser.id,
          body.type,
          activeModules,
          mergedBindings,
          tx,
        );
        const bindings = {
          ...mergedBindings,
          laundryServiceIds: ownedLaundryServiceIds,
        };
        const linkedProfile = await tx.proProfile.update({
          where: { id: legacyUser.proProfile.id },
          data: {
            accountId: account.id,
            type: body.type,
            activeModules,
            businessName: body.businessName.trim(),
            avatarUrl: avatarUrl ?? account.avatarUrl,
            bindings,
          },
        });

        const updatedAccount = await tx.proAccount.update({
          where: { id: account.id },
          data: {
            avatarUrl: avatarUrl ?? account.avatarUrl,
          },
        });

        return {
          account: updatedAccount,
          profile: linkedProfile,
          created: true,
        };
      }

      const name = parseFullName(account.fullName);
      const internalUser = await tx.user.create({
        data: {
          email: buildInternalUserEmail(account.id),
          firstName: name.firstName,
          lastName: name.lastName,
          phone: account.phone,
          avatarUrl: avatarUrl ?? account.avatarUrl,
          passwordHash: await hashPassword(
            `pro:${account.id}:${Date.now().toString()}`,
          ),
        },
      });

      const ownedLaundryServiceIds = await syncLaundryOwnership(
        internalUser.id,
        body.type,
        activeModules,
        mergedBindings,
        tx,
      );
      const bindings = {
        ...mergedBindings,
        laundryServiceIds: ownedLaundryServiceIds,
      };

      const profile = await tx.proProfile.create({
        data: {
          accountId: account.id,
          userId: internalUser.id,
          type: body.type,
          activeModules,
          businessName: body.businessName.trim(),
          avatarUrl: avatarUrl ?? account.avatarUrl,
          bindings,
          isOnline: true,
          isVerified: false,
        },
      });

      const updatedAccount = await tx.proAccount.update({
        where: { id: account.id },
        data: {
          avatarUrl: avatarUrl ?? account.avatarUrl,
        },
      });

      return {
        account: updatedAccount,
        profile,
        created: true,
      };
    }, { timeout: 15000, maxWait: 10000 });

    res.status(payload.created ? 201 : 200).json({
      account: serializeProAccount(payload.account),
      profile: serializeProProfile(payload.profile),
    });
  }),
);

export default router;
