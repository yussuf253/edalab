"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const password_1 = require("../utils/password");
const jwt_1 = require("../utils/jwt");
const serializers_1 = require("../utils/serializers");
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
router.post('/register', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = registerSchema.parse(req.body);
    const existingUser = await db_1.prisma.user.findUnique({
        where: { email: body.email.toLowerCase() },
    });
    if (existingUser) {
        return res.status(409).json({ error: 'An account with this email already exists.' });
    }
    const name = (0, serializers_1.parseFullName)(body.name);
    const user = await db_1.prisma.user.create({
        data: {
            email: body.email.toLowerCase(),
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
    const safeUser = (0, serializers_1.sanitizeUser)(user);
    const token = (0, jwt_1.signAccessToken)({ userId: user.id, email: user.email });
    res.status(201).json({ token, user: safeUser });
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
    const safeUser = (0, serializers_1.sanitizeUser)(user);
    const token = (0, jwt_1.signAccessToken)({ userId: user.id, email: user.email });
    res.json({ token, user: safeUser });
}));
exports.default = router;
