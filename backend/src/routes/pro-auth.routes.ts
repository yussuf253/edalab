import { ProModule, ProProfileType } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { requireAuth } from '../middleware/auth';
import { resolveBindings, syncLaundryOwnership } from './pro.routes';
import { asyncHandler } from '../utils/async-handler';
import { signAccessToken } from '../utils/jwt';
import { hashPassword, verifyPassword } from '../utils/password';
import { parseFullName } from '../utils/serializers';

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

const proProfileSetupSchema = z.object({
  type: z.nativeEnum(ProProfileType),
  activeModules: z.array(z.nativeEnum(ProModule)).min(1),
  businessName: z.string().trim().min(2),
  avatarUrl: z.string().trim().optional().nullable(),
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

    const account = await prisma.proAccount.create({
      data: {
        email,
        fullName: body.fullName.trim(),
        phone: body.phone?.trim() || null,
        passwordHash: await hashPassword(body.password),
      },
    });

    const token = signAccessToken({
      userId: account.id,
      email: account.email,
      accountType: 'pro',
    });

    res.status(201).json({
      token,
      account: serializeProAccount(account),
      profile: null,
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
    const resolvedBindings = await resolveBindings(
      body.businessName.trim(),
      activeModules,
    );

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
          resolvedBindings,
        );
        const bindings = {
          ...resolvedBindings,
          laundryServiceIds: ownedLaundryServiceIds,
        };
        const updatedProfile = await tx.proProfile.update({
          where: { id: account.proProfile.id },
          data: {
            type: body.type,
            activeModules,
            businessName: body.businessName.trim(),
            avatarUrl: body.avatarUrl?.trim() || null,
            bindings,
          },
        });

        const updatedAccount = await tx.proAccount.update({
          where: { id: account.id },
          data: {
            avatarUrl: body.avatarUrl?.trim() || account.avatarUrl,
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
          resolvedBindings,
        );
        const bindings = {
          ...resolvedBindings,
          laundryServiceIds: ownedLaundryServiceIds,
        };
        const linkedProfile = await tx.proProfile.update({
          where: { id: legacyUser.proProfile.id },
          data: {
            accountId: account.id,
            type: body.type,
            activeModules,
            businessName: body.businessName.trim(),
            avatarUrl: body.avatarUrl?.trim() || account.avatarUrl,
            bindings,
          },
        });

        const updatedAccount = await tx.proAccount.update({
          where: { id: account.id },
          data: {
            avatarUrl: body.avatarUrl?.trim() || account.avatarUrl,
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
          avatarUrl: body.avatarUrl?.trim() || account.avatarUrl,
          passwordHash: await hashPassword(
            `pro:${account.id}:${Date.now().toString()}`,
          ),
        },
      });

      const ownedLaundryServiceIds = await syncLaundryOwnership(
        internalUser.id,
        body.type,
        activeModules,
        resolvedBindings,
      );
      const bindings = {
        ...resolvedBindings,
        laundryServiceIds: ownedLaundryServiceIds,
      };

      const profile = await tx.proProfile.create({
        data: {
          accountId: account.id,
          userId: internalUser.id,
          type: body.type,
          activeModules,
          businessName: body.businessName.trim(),
          avatarUrl: body.avatarUrl?.trim() || account.avatarUrl,
          bindings,
          isOnline: true,
          isVerified: false,
        },
      });

      const updatedAccount = await tx.proAccount.update({
        where: { id: account.id },
        data: {
          avatarUrl: body.avatarUrl?.trim() || account.avatarUrl,
        },
      });

      return {
        account: updatedAccount,
        profile,
        created: true,
      };
    });

    res.status(payload.created ? 201 : 200).json({
      account: serializeProAccount(payload.account),
      profile: serializeProProfile(payload.profile),
    });
  }),
);

export default router;
