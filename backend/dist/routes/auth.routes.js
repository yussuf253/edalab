"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const password_1 = require("../utils/password");
const jwt_1 = require("../utils/jwt");
const serializers_1 = require("../utils/serializers");
const email_verification_1 = require("../utils/email-verification");
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
const emailSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
});
const verifyEmailSchema = zod_1.z.object({
    token: zod_1.z.string().trim().min(16),
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
    const verification = (0, email_verification_1.createEmailVerificationChallenge)();
    const user = await db_1.prisma.user.create({
        data: {
            email,
            firstName: name.firstName,
            lastName: name.lastName,
            phone: body.phone?.trim() || null,
            passwordHash: await (0, password_1.hashPassword)(body.password),
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
    const delivery = await (0, email_verification_1.sendEmailVerification)({
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
    if ((0, email_verification_1.hasPendingEmailVerification)(user)) {
        return res.status(403).json({
            code: 'EMAIL_NOT_VERIFIED',
            error: 'Please verify your email address before signing in.',
            email: user.email,
        });
    }
    const safeUser = (0, serializers_1.sanitizeUser)(user);
    const token = (0, jwt_1.signAccessToken)({ userId: user.id, email: user.email });
    res.json({ token, user: safeUser });
}));
router.post('/resend-verification', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = emailSchema.parse(req.body);
    const user = await db_1.prisma.user.findUnique({
        where: { email: body.email.toLowerCase() },
    });
    if (!user || !(0, email_verification_1.hasPendingEmailVerification)(user)) {
        return res.json({ ok: true });
    }
    const verification = (0, email_verification_1.createEmailVerificationChallenge)();
    await db_1.prisma.user.update({
        where: { id: user.id },
        data: {
            emailVerificationTokenHash: verification.tokenHash,
            emailVerificationExpiresAt: verification.expiresAt,
            emailVerificationSentAt: new Date(),
        },
    });
    const delivery = await (0, email_verification_1.sendEmailVerification)({
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
}));
async function verifyUserEmail(token) {
    const tokenHash = (0, email_verification_1.hashEmailVerificationToken)(token);
    const user = await db_1.prisma.user.findFirst({
        where: { emailVerificationTokenHash: tokenHash },
    });
    if (!user) {
        return { status: 400, payload: { error: 'Invalid verification link.' } };
    }
    if (user.emailVerificationExpiresAt != null &&
        user.emailVerificationExpiresAt.getTime() < Date.now()) {
        return {
            status: 400,
            payload: { error: 'This verification link has expired.' },
        };
    }
    await db_1.prisma.user.update({
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
router.get('/verify-email', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = verifyEmailSchema.parse({ token: req.query.token });
    const result = await verifyUserEmail(body.token);
    res.status(result.status).json(result.payload);
}));
router.post('/verify-email', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = verifyEmailSchema.parse(req.body);
    const result = await verifyUserEmail(body.token);
    res.status(result.status).json(result.payload);
}));
exports.default = router;
