"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const client_1 = require("@prisma/client");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const password_1 = require("../utils/password");
const jwt_1 = require("../utils/jwt");
const serializers_1 = require("../utils/serializers");
const supabase_admin_service_1 = require("../services/supabase-admin.service");
const env_1 = require("../config/env");
const router = (0, express_1.Router)();
const profileSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    name: zod_1.z.string().min(2),
    phone: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    avatarUrl: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
});
const addressSchema = zod_1.z.object({
    label: zod_1.z.string().min(1),
    address: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    city: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    quartier: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    zipCode: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    latitude: zod_1.z.number().optional().nullable(),
    longitude: zod_1.z.number().optional().nullable(),
    isDefault: zod_1.z.boolean().optional().default(false),
});
const paymentMethodSchema = zod_1.z.object({
    type: zod_1.z.nativeEnum(client_1.PaymentMethodType),
    brand: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    last4: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
    expiryMonth: zod_1.z.number().int().min(1).max(12).optional().nullable(),
    expiryYear: zod_1.z.number().int().min(2024).optional().nullable(),
    isDefault: zod_1.z.boolean().optional().default(false),
});
const wishlistSchema = zod_1.z.object({
    moduleType: zod_1.z.nativeEnum(client_1.ModuleType),
    entityId: zod_1.z.string(),
    title: zod_1.z.string(),
    subtitle: zod_1.z.string().optional(),
    imageUrl: zod_1.z.string().optional(),
    price: zod_1.z.number().optional().nullable(),
});
async function getUserWithAddresses(userId) {
    return db_1.prisma.user.findUnique({
        where: { id: userId },
        include: {
            addresses: {
                orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
            },
        },
    });
}
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const { email, name, phone, password } = zod_1.z
        .object({
        email: zod_1.z.string().email(),
        name: zod_1.z.string().min(2),
        phone: zod_1.z.string().trim().optional().or(zod_1.z.literal('')),
        password: zod_1.z.string().min(6),
    })
        .parse(req.body);
    const existingUser = await db_1.prisma.user.findUnique({ where: { email: email.toLowerCase() } });
    if (existingUser) {
        return res.status(409).json({ error: 'An account with this email already exists.' });
    }
    const parsedName = (0, serializers_1.parseFullName)(name);
    // Create user in Supabase Auth with metadata
    const { data: authData, error: authError } = await supabase_admin_service_1.supabaseAdmin.auth.signUp({
        email: email.toLowerCase(),
        password,
        options: {
            emailRedirectTo: `${env_1.env.PUBLIC_BASE_URL}/auth/confirm`,
            data: {
                displayName: [parsedName.firstName, parsedName.lastName].filter(Boolean).join(' '),
                phone: phone?.trim() || null,
            },
        },
    });
    if (authError) {
        return res.status(400).json({ error: authError.message });
    }
    const user = await db_1.prisma.user.create({
        data: {
            email: email.toLowerCase(),
            firstName: parsedName.firstName,
            lastName: parsedName.lastName,
            phone: phone?.trim() || null,
            passwordHash: await (0, password_1.hashPassword)(password),
        },
        include: {
            addresses: {
                orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
            },
        },
    });
    res.status(201).json({
        message: 'Please check your email to verify your account before signing in.',
        email: user.email,
        requiresEmailVerification: true,
    });
}));
router.post('/login', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const { email, password } = zod_1.z
        .object({
        email: zod_1.z.string().email(),
        password: zod_1.z.string().min(1),
    })
        .parse(req.body);
    const user = await db_1.prisma.user.findUnique({
        where: { email: email.toLowerCase() },
        include: {
            addresses: {
                orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
            },
        },
    });
    if (!user || !(await (0, password_1.verifyPassword)(password, user.passwordHash))) {
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
    res.json({
        ...safeUser,
        token,
    });
}));
router.get('/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const user = await getUserWithAddresses(userId);
    if (!user) {
        return res.status(404).json({ error: 'User not found.' });
    }
    res.json((0, serializers_1.sanitizeUser)(user));
}));
router.patch('/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const body = profileSchema.parse(req.body);
    const existingUser = await db_1.prisma.user.findUnique({ where: { id: userId } });
    if (!existingUser) {
        return res.status(404).json({ error: 'User not found.' });
    }
    const emailOwner = await db_1.prisma.user.findUnique({ where: { email: body.email.toLowerCase() } });
    if (emailOwner && emailOwner.id !== userId) {
        return res.status(409).json({ error: 'That email is already being used by another account.' });
    }
    const parsedName = (0, serializers_1.parseFullName)(body.name);
    const updatedUser = await db_1.prisma.user.update({
        where: { id: userId },
        data: {
            email: body.email.toLowerCase(),
            firstName: parsedName.firstName,
            lastName: parsedName.lastName,
            phone: body.phone?.trim() || null,
            avatarUrl: body.avatarUrl?.trim() || null,
        },
        include: {
            addresses: {
                orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
            },
        },
    });
    res.json((0, serializers_1.sanitizeUser)(updatedUser));
}));
router.post('/:id/addresses', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const body = addressSchema.parse(req.body);
    const user = await db_1.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
        return res.status(404).json({ error: 'User not found.' });
    }
    await db_1.prisma.$transaction(async (tx) => {
        const existingCount = await tx.address.count({ where: { userId } });
        const shouldBeDefault = body.isDefault || existingCount === 0;
        const city = body.city?.trim() || null;
        const quartier = body.quartier?.trim() || null;
        const line1 = body.address?.trim() ||
            quartier ||
            city ||
            body.label.trim();
        if (shouldBeDefault) {
            await tx.address.updateMany({
                where: { userId, isDefault: true },
                data: { isDefault: false },
            });
        }
        await tx.address.create({
            data: {
                userId,
                label: body.label,
                line1,
                line2: quartier,
                city,
                postalCode: body.zipCode?.trim() || null,
                latitude: body.latitude ?? null,
                longitude: body.longitude ?? null,
                isDefault: shouldBeDefault,
            },
        });
    });
    const updatedUser = await getUserWithAddresses(userId);
    res.status(201).json((0, serializers_1.sanitizeUser)(updatedUser));
}));
router.patch('/:id/addresses/:addressId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const addressId = (0, http_1.getParam)(req.params.addressId, 'addressId');
    const body = addressSchema.partial().parse(req.body);
    const address = await db_1.prisma.address.findFirst({
        where: { id: addressId, userId },
    });
    if (!address) {
        return res.status(404).json({ error: 'Address not found.' });
    }
    await db_1.prisma.$transaction(async (tx) => {
        const hasLatitude = Object.prototype.hasOwnProperty.call(body, 'latitude');
        const hasLongitude = Object.prototype.hasOwnProperty.call(body, 'longitude');
        const hasAddress = Object.prototype.hasOwnProperty.call(body, 'address');
        const nextCity = body.city === undefined
            ? address.city
            : body.city === ''
                ? null
                : body.city.trim();
        const nextQuartier = body.quartier === undefined
            ? address.line2
            : body.quartier === ''
                ? null
                : body.quartier.trim();
        const nextLine1 = hasAddress
            ? (body.address?.trim() || nextQuartier || nextCity || address.label)
            : (address.line1 || nextQuartier || nextCity || address.label);
        if (body.isDefault) {
            await tx.address.updateMany({
                where: { userId, isDefault: true },
                data: { isDefault: false },
            });
        }
        await tx.address.update({
            where: { id: addressId },
            data: {
                label: body.label ?? address.label,
                line1: nextLine1,
                line2: nextQuartier,
                city: nextCity,
                postalCode: body.zipCode === '' ? null : body.zipCode ?? address.postalCode,
                latitude: hasLatitude ? body.latitude ?? null : address.latitude,
                longitude: hasLongitude ? body.longitude ?? null : address.longitude,
                isDefault: body.isDefault ?? address.isDefault,
            },
        });
    });
    const updatedUser = await getUserWithAddresses(userId);
    res.json((0, serializers_1.sanitizeUser)(updatedUser));
}));
router.patch('/:id/addresses/:addressId/default', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const addressId = (0, http_1.getParam)(req.params.addressId, 'addressId');
    const address = await db_1.prisma.address.findFirst({
        where: { id: addressId, userId },
    });
    if (!address) {
        return res.status(404).json({ error: 'Address not found.' });
    }
    await db_1.prisma.$transaction(async (tx) => {
        await tx.address.updateMany({
            where: { userId, isDefault: true },
            data: { isDefault: false },
        });
        await tx.address.update({
            where: { id: addressId },
            data: { isDefault: true },
        });
    });
    const updatedUser = await getUserWithAddresses(userId);
    res.json((0, serializers_1.sanitizeUser)(updatedUser));
}));
router.delete('/:id/addresses/:addressId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const addressId = (0, http_1.getParam)(req.params.addressId, 'addressId');
    const address = await db_1.prisma.address.findFirst({
        where: { id: addressId, userId },
    });
    if (!address) {
        return res.status(404).json({ error: 'Address not found.' });
    }
    await db_1.prisma.address.delete({ where: { id: addressId } });
    if (address.isDefault) {
        const replacement = await db_1.prisma.address.findFirst({
            where: { userId },
            orderBy: { updatedAt: 'desc' },
        });
        if (replacement) {
            await db_1.prisma.address.update({
                where: { id: replacement.id },
                data: { isDefault: true },
            });
        }
    }
    const updatedUser = await getUserWithAddresses(userId);
    res.json((0, serializers_1.sanitizeUser)(updatedUser));
}));
router.get('/:id/payment-methods', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const methods = await db_1.prisma.paymentMethod.findMany({
        where: { userId },
        orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
    });
    res.json(methods.map((method) => ({
        id: method.id,
        type: method.type,
        brand: method.brand,
        last4: method.last4,
        expiryMonth: method.expiryMonth,
        expiryYear: method.expiryYear,
        isDefault: method.isDefault,
    })));
}));
router.post('/:id/payment-methods', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const body = paymentMethodSchema.parse(req.body);
    await db_1.prisma.$transaction(async (tx) => {
        if (body.isDefault) {
            await tx.paymentMethod.updateMany({
                where: { userId, isDefault: true },
                data: { isDefault: false },
            });
        }
        await tx.paymentMethod.create({
            data: {
                userId,
                type: body.type,
                brand: body.brand?.trim() || null,
                last4: body.last4?.trim() || null,
                expiryMonth: body.expiryMonth ?? null,
                expiryYear: body.expiryYear ?? null,
                isDefault: body.isDefault,
            },
        });
    });
    const methods = await db_1.prisma.paymentMethod.findMany({
        where: { userId },
        orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
    });
    res.status(201).json(methods.map((method) => ({
        id: method.id,
        type: method.type,
        brand: method.brand,
        last4: method.last4,
        expiryMonth: method.expiryMonth,
        expiryYear: method.expiryYear,
        isDefault: method.isDefault,
    })));
}));
router.patch('/:id/payment-methods/:paymentMethodId/default', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const paymentMethodId = (0, http_1.getParam)(req.params.paymentMethodId, 'paymentMethodId');
    await db_1.prisma.$transaction(async (tx) => {
        await tx.paymentMethod.updateMany({
            where: { userId, isDefault: true },
            data: { isDefault: false },
        });
        await tx.paymentMethod.update({
            where: { id: paymentMethodId },
            data: { isDefault: true },
        });
    });
    res.json({ success: true });
}));
router.delete('/:id/payment-methods/:paymentMethodId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const paymentMethodId = (0, http_1.getParam)(req.params.paymentMethodId, 'paymentMethodId');
    const method = await db_1.prisma.paymentMethod.findFirst({
        where: { id: paymentMethodId, userId },
    });
    if (!method) {
        return res.status(404).json({ error: 'Payment method not found.' });
    }
    await db_1.prisma.paymentMethod.delete({ where: { id: paymentMethodId } });
    res.status(204).send();
}));
router.get('/:id/wishlist', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const items = await db_1.prisma.wishlistItem.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
    });
    res.json(items.map((item) => ({
        id: item.id,
        moduleType: item.moduleType,
        entityId: item.entityId,
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        price: (0, serializers_1.toNumber)(item.price),
    })));
}));
router.post('/:id/wishlist', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const body = wishlistSchema.parse(req.body);
    const item = await db_1.prisma.wishlistItem.upsert({
        where: {
            userId_moduleType_entityId: {
                userId,
                moduleType: body.moduleType,
                entityId: body.entityId,
            },
        },
        update: {
            title: body.title,
            subtitle: body.subtitle ?? null,
            imageUrl: body.imageUrl ?? null,
            price: body.price ?? null,
        },
        create: {
            userId,
            moduleType: body.moduleType,
            entityId: body.entityId,
            title: body.title,
            subtitle: body.subtitle ?? null,
            imageUrl: body.imageUrl ?? null,
            price: body.price ?? null,
        },
    });
    res.status(201).json({
        id: item.id,
        moduleType: item.moduleType,
        entityId: item.entityId,
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        price: (0, serializers_1.toNumber)(item.price),
    });
}));
router.delete('/:id/wishlist/:entityId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const entityId = (0, http_1.getParam)(req.params.entityId, 'entityId');
    const moduleTypeValue = req.query.moduleType?.toString().toUpperCase();
    if (!moduleTypeValue || !(moduleTypeValue in client_1.ModuleType)) {
        return res.status(400).json({ error: 'moduleType is required.' });
    }
    await db_1.prisma.wishlistItem.deleteMany({
        where: {
            userId,
            entityId,
            moduleType: moduleTypeValue,
        },
    });
    res.status(204).send();
}));
router.get('/:id/coupons', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.id, 'userId');
    const coupons = await db_1.prisma.userCoupon.findMany({
        where: { userId },
        include: { promotion: true },
        orderBy: { createdAt: 'desc' },
    });
    res.json(coupons.map((coupon) => ({
        id: coupon.id,
        status: coupon.status,
        usedAt: coupon.usedAt,
        expiresAt: coupon.expiresAt,
        promotion: {
            id: coupon.promotion.id,
            moduleType: coupon.promotion.moduleType,
            title: coupon.promotion.title,
            description: coupon.promotion.description,
            code: coupon.promotion.code,
            discountType: coupon.promotion.discountType,
            discountValue: (0, serializers_1.toNumber)(coupon.promotion.discountValue),
            active: coupon.promotion.active,
            metadata: coupon.promotion.metadata,
        },
    })));
}));
exports.default = router;
