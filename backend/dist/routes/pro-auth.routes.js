"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const auth_1 = require("../middleware/auth");
const pro_routes_1 = require("./pro.routes");
const async_handler_1 = require("../utils/async-handler");
const jwt_1 = require("../utils/jwt");
const password_1 = require("../utils/password");
const serializers_1 = require("../utils/serializers");
const router = (0, express_1.Router)();
const proAccountRegisterSchema = zod_1.z.object({
    fullName: zod_1.z.string().trim().min(2),
    email: zod_1.z.string().trim().email(),
    phone: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    password: zod_1.z.string().min(6),
});
const proAccountLoginSchema = zod_1.z.object({
    email: zod_1.z.string().trim().email(),
    password: zod_1.z.string().min(1),
});
const proProfileSetupSchema = zod_1.z.object({
    type: zod_1.z.nativeEnum(client_1.ProProfileType),
    activeModules: zod_1.z.array(zod_1.z.nativeEnum(client_1.ProModule)).min(1),
    businessName: zod_1.z.string().trim().min(2),
    avatarUrl: zod_1.z.string().trim().optional().nullable(),
    bindingOverrides: zod_1.z
        .object({
        providerIds: zod_1.z.array(zod_1.z.string().min(1)).optional(),
        laundryServiceIds: zod_1.z.array(zod_1.z.string().min(1)).optional(),
    })
        .optional(),
});
function serializeProAccount(account) {
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
function serializeProProfile(profile) {
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
function allowedModulesForProfile(type) {
    switch (type) {
        case client_1.ProProfileType.SHOP:
            return [client_1.ProModule.SHOPPING, client_1.ProModule.FOOD, client_1.ProModule.PHARMACY];
        case client_1.ProProfileType.PROVIDER:
            return [client_1.ProModule.SERVICES, client_1.ProModule.LAUNDRY];
        case client_1.ProProfileType.DOCTOR:
            return [client_1.ProModule.DOCTOR];
        case client_1.ProProfileType.DELIVERY:
            return [
                client_1.ProModule.SHOPPING_DELIVERY,
                client_1.ProModule.FOOD_DELIVERY,
                client_1.ProModule.PHARMACY_DELIVERY,
            ];
        case client_1.ProProfileType.RIDER:
            return [client_1.ProModule.RIDE];
    }
}
function sanitizeModulesForProfile(type, modules) {
    const allowed = new Set(allowedModulesForProfile(type));
    const sanitized = Array.from(new Set(modules.filter((module) => allowed.has(module))));
    return sanitized.length > 0 ? sanitized : [allowedModulesForProfile(type)[0]];
}
function normalizeBindingsForProfileType(type, bindings) {
    if (type !== client_1.ProProfileType.PROVIDER) {
        return bindings;
    }
    return {
        ...bindings,
        providerIds: [],
        laundryServiceIds: [],
    };
}
function proAccountIdFromRequest(req) {
    return req.auth?.accountType == 'pro' ? req.auth.userId : null;
}
function buildInternalUserEmail(accountId) {
    return `pro-${accountId}@edalab.internal`;
}
router.post('/register', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = proAccountRegisterSchema.parse(req.body);
    const email = body.email.toLowerCase();
    const existingAccount = await db_1.prisma.proAccount.findUnique({
        where: { email },
    });
    if (existingAccount) {
        return res
            .status(409)
            .json({ error: 'A pro account with this email already exists.' });
    }
    const account = await db_1.prisma.proAccount.create({
        data: {
            email,
            fullName: body.fullName.trim(),
            phone: body.phone?.trim() || null,
            passwordHash: await (0, password_1.hashPassword)(body.password),
        },
    });
    const token = (0, jwt_1.signAccessToken)({
        userId: account.id,
        email: account.email,
        accountType: 'pro',
    });
    res.status(201).json({
        token,
        account: serializeProAccount(account),
        profile: null,
    });
}));
router.post('/login', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = proAccountLoginSchema.parse(req.body);
    const email = body.email.toLowerCase();
    const account = await db_1.prisma.proAccount.findUnique({
        where: { email },
        include: { proProfile: true },
    });
    if (!account || !(await (0, password_1.verifyPassword)(body.password, account.passwordHash))) {
        return res.status(401).json({ error: 'Invalid email or password.' });
    }
    const token = (0, jwt_1.signAccessToken)({
        userId: account.id,
        email: account.email,
        accountType: 'pro',
    });
    res.json({
        token,
        account: serializeProAccount(account),
        profile: account.proProfile ? serializeProProfile(account.proProfile) : null,
    });
}));
router.get('/me', auth_1.requireAuth, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const accountId = proAccountIdFromRequest(req);
    if (accountId == null) {
        return res
            .status(403)
            .json({ error: 'This endpoint requires a pro account session.' });
    }
    const account = await db_1.prisma.proAccount.findUnique({
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
}));
router.post('/profile', auth_1.requireAuth, (0, async_handler_1.asyncHandler)(async (req, res) => {
    const accountId = proAccountIdFromRequest(req);
    if (accountId == null) {
        return res
            .status(403)
            .json({ error: 'This endpoint requires a pro account session.' });
    }
    const body = proProfileSetupSchema.parse(req.body);
    const activeModules = sanitizeModulesForProfile(body.type, body.activeModules);
    const resolvedBindingsRaw = await (0, pro_routes_1.resolveBindings)(body.businessName.trim(), activeModules);
    const resolvedBindings = normalizeBindingsForProfileType(body.type, resolvedBindingsRaw);
    const bindingOverrides = body.bindingOverrides;
    const sanitizedOverrides = bindingOverrides == null
        ? null
        : await (0, pro_routes_1.sanitizeProviderBindingOverrides)(activeModules, bindingOverrides);
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
    const payload = await db_1.prisma.$transaction(async (tx) => {
        const account = await tx.proAccount.findUnique({
            where: { id: accountId },
            include: { proProfile: true },
        });
        if (!account) {
            throw new Error('Pro account not found.');
        }
        if (account.proProfile) {
            const ownedLaundryServiceIds = await (0, pro_routes_1.syncLaundryOwnership)(account.proProfile.userId, body.type, activeModules, mergedBindings, tx);
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
        if (legacyUser?.proProfile != null &&
            legacyUser.proProfile.accountId == null) {
            const ownedLaundryServiceIds = await (0, pro_routes_1.syncLaundryOwnership)(legacyUser.id, body.type, activeModules, mergedBindings, tx);
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
        const name = (0, serializers_1.parseFullName)(account.fullName);
        const internalUser = await tx.user.create({
            data: {
                email: buildInternalUserEmail(account.id),
                firstName: name.firstName,
                lastName: name.lastName,
                phone: account.phone,
                avatarUrl: avatarUrl ?? account.avatarUrl,
                passwordHash: await (0, password_1.hashPassword)(`pro:${account.id}:${Date.now().toString()}`),
            },
        });
        const ownedLaundryServiceIds = await (0, pro_routes_1.syncLaundryOwnership)(internalUser.id, body.type, activeModules, mergedBindings, tx);
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
}));
exports.default = router;
