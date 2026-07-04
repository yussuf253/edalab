"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const auth_1 = require("../middleware/auth");
const async_handler_1 = require("../utils/async-handler");
const jwt_1 = require("../utils/jwt");
const password_1 = require("../utils/password");
const supabase_admin_service_1 = require("../services/supabase-admin.service");
const env_1 = require("../config/env");
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
const confirmSchema = zod_1.z.object({
    token: zod_1.z.string().trim().min(1),
    email: zod_1.z.string().email(),
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
        banned: account.banned,
        banReason: account.banReason,
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
    // Create user in Supabase Auth with metadata (handles email verification)
    const { data: authData, error: authError } = await supabase_admin_service_1.supabaseAdmin.auth.signUp({
        email,
        password: body.password,
        options: {
            emailRedirectTo: `${env_1.env.PUBLIC_BASE_URL}/auth/confirm`,
            data: {
                displayName: body.fullName.trim(),
                phone: body.phone?.trim() || null,
            },
        },
    });
    if (authError) {
        return res.status(400).json({ error: authError.message });
    }
    const account = await db_1.prisma.proAccount.create({
        data: {
            email,
            fullName: body.fullName.trim(),
            phone: body.phone?.trim() || null,
            passwordHash: await (0, password_1.hashPassword)(body.password),
        },
    });
    // Return message about email verification - don't return account data yet
    res.status(201).json({
        message: 'Please check your email to verify your account before signing in.',
        email: account.email,
        requiresEmailVerification: true,
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
    // Check if account is banned
    if (account.banned) {
        return res.status(403).json({
            error: 'Your account has been suspended.',
            banReason: account.banReason,
            banned: true,
        });
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
// Handle email confirmation redirect from Supabase
router.post('/confirm', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = confirmSchema.parse(req.body);
    const { token, email } = body;
    // Verify the token with Supabase
    const { data: authData, error: authError } = await supabase_admin_service_1.supabaseAdmin.auth.verifyOtp({
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
    const account = await db_1.prisma.proAccount.findUnique({
        where: { email: authData.user.email },
        include: { proProfile: true },
    });
    if (!account) {
        return res.status(404).json({ error: 'Account not found.' });
    }
    const tokenResult = (0, jwt_1.signAccessToken)({
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
}));
// GET endpoint for email confirmation (called by frontend after redirect)
router.get('/confirm', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const accessToken = req.query.access_token;
    const tokenType = req.query.token_type;
    if (!accessToken || tokenType !== 'bearer') {
        return res.status(400).json({
            error: 'Invalid verification parameters.',
            verified: false,
        });
    }
    // Verify the access token with Supabase
    const { data: authData, error: authError } = await supabase_admin_service_1.supabaseAdmin.auth.getUser(accessToken);
    if (authError || !authData.user) {
        return res.status(400).json({
            error: 'Invalid or expired verification link.',
            verified: false,
        });
    }
    // Get the account from Prisma
    const account = await db_1.prisma.proAccount.findUnique({
        where: { email: authData.user.email },
        include: { proProfile: true },
    });
    if (!account) {
        return res.status(404).json({ error: 'Account not found.' });
    }
    const tokenResult = (0, jwt_1.signAccessToken)({
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
}));
exports.default = router;
