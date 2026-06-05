"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const password_1 = require("../utils/password");
const jwt_1 = require("../utils/jwt");
const serializers_1 = require("../utils/serializers");
const supabase_admin_service_1 = require("../services/supabase-admin.service");
const env_1 = require("../config/env");
const router = (0, express_1.Router)();
const registerSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    name: zod_1.z.string().min(2),
    phone: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    password: zod_1.z.string().min(6),
});
const loginSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(1),
});
const confirmSchema = zod_1.z.object({
    token: zod_1.z.string().trim().min(1),
    email: zod_1.z.string().email(),
});
router.post('/register', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = registerSchema.parse(req.body);
    const email = body.email.toLowerCase();
    const existingUser = await db_1.prisma.user.findUnique({
        where: { email },
    });
    if (existingUser) {
        return res.status(409).json({ error: 'An account with this email already exists.' });
    }
    const name = (0, serializers_1.parseFullName)(body.name);
    // Create user in Supabase Auth with metadata (handles email verification)
    const { data: authData, error: authError } = await supabase_admin_service_1.supabaseAdmin.auth.signUp({
        email,
        password: body.password,
        options: {
            emailRedirectTo: `${env_1.env.PUBLIC_BASE_URL}/auth/confirm`,
            data: {
                displayName: [name.firstName, name.lastName].filter(Boolean).join(' '),
                phone: body.phone?.trim() || null,
            },
        },
    });
    if (authError) {
        return res.status(400).json({ error: authError.message });
    }
    const user = await db_1.prisma.user.create({
        data: {
            email,
            firstName: name.firstName,
            lastName: name.lastName,
            phone: body.phone?.trim() || null,
            passwordHash: await (0, password_1.hashPassword)(body.password),
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
}));
router.post('/login', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = loginSchema.parse(req.body);
    const user = await db_1.prisma.user.findUnique({
        where: { email: body.email.toLowerCase() },
        include: {
            addresses: {
                orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
            },
        },
    });
    if (!user || !(await (0, password_1.verifyPassword)(body.password, user.passwordHash))) {
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
    const safeUser = (0, serializers_1.sanitizeUser)(user);
    const token = (0, jwt_1.signAccessToken)({ userId: user.id, email: user.email });
    res.json({ token, user: safeUser });
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
    // Get the user from Prisma
    const user = await db_1.prisma.user.findUnique({
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
    const safeUser = (0, serializers_1.sanitizeUser)(user);
    const jwtToken = (0, jwt_1.signAccessToken)({ userId: user.id, email: user.email });
    res.json({
        message: 'Email verified successfully!',
        verified: true,
        user: safeUser,
        token: jwtToken,
    });
}));
// GET endpoint for email confirmation (called by frontend after redirect)
router.get('/confirm', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const accessToken = req.query.access_token;
    const tokenType = req.query.token_type;
    const expiresIn = req.query.expires_in;
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
    // Get the user from Prisma
    const user = await db_1.prisma.user.findUnique({
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
    const safeUser = (0, serializers_1.sanitizeUser)(user);
    const jwtToken = (0, jwt_1.signAccessToken)({ userId: user.id, email: user.email });
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
}));
exports.default = router;
