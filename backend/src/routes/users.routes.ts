import { Router } from 'express';
import { ModuleType, PaymentMethodType } from '@prisma/client';
import { z } from 'zod';
import { randomUUID } from 'crypto';
import fs from 'fs/promises';
import path from 'path';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { hashPassword, verifyPassword } from '../utils/password';
import { signAccessToken } from '../utils/jwt';
import { parseFullName, sanitizeUser, toNumber } from '../utils/serializers';

const router = Router();

const profileSchema = z.object({
  email: z.string().email(),
  name: z.string().min(2),
  phone: z.string().trim().optional().or(z.literal('')),
  avatarUrl: z.string().trim().optional().or(z.literal('')),
});

const addressSchema = z.object({
  label: z.string().min(1),
  address: z.string().trim().optional().or(z.literal('')),
  city: z.string().trim().optional().or(z.literal('')),
  quartier: z.string().trim().optional().or(z.literal('')),
  zipCode: z.string().trim().optional().or(z.literal('')),
  latitude: z.number().optional().nullable(),
  longitude: z.number().optional().nullable(),
  isDefault: z.boolean().optional().default(false),
});

const paymentMethodSchema = z.object({
  type: z.nativeEnum(PaymentMethodType),
  brand: z.string().trim().optional().or(z.literal('')),
  last4: z.string().trim().optional().or(z.literal('')),
  expiryMonth: z.number().int().min(1).max(12).optional().nullable(),
  expiryYear: z.number().int().min(2024).optional().nullable(),
  isDefault: z.boolean().optional().default(false),
});

const uploadAvatarSchema = z.object({
  fileName: z.string().min(1).max(180).optional().nullable(),
  mimeType: z.string().max(120).optional().nullable(),
  dataBase64: z.string().min(24),
});

const wishlistSchema = z.object({
  moduleType: z.nativeEnum(ModuleType),
  entityId: z.string(),
  title: z.string(),
  subtitle: z.string().optional(),
  imageUrl: z.string().optional(),
  price: z.number().optional().nullable(),
});

async function getUserWithAddresses(userId: string) {
  return prisma.user.findUnique({
    where: { id: userId },
    include: {
      addresses: {
        orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
      },
    },
  });
}

function fileExtensionFromMimeType(mimeType: string | null | undefined) {
  const normalized = mimeType?.trim().toLowerCase();
  switch (normalized) {
    case 'image/jpeg':
    case 'image/jpg':
      return 'jpg';
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/heic':
      return 'heic';
    case 'image/heif':
      return 'heif';
    default:
      return null;
  }
}

function sanitizedBaseFileName(name: string | null | undefined) {
  const trimmed = name?.trim();
  if (!trimmed) return null;
  const safe = trimmed
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
  return safe.length > 0 ? safe : null;
}

function decodedBase64Image(dataBase64: string) {
  const payload = dataBase64.trim();
  const base64Data = payload.includes(',')
    ? payload.split(',').pop() ?? payload
    : payload;
  return Buffer.from(base64Data, 'base64');
}

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const { email, name, phone, password } = z
      .object({
        email: z.string().email(),
        name: z.string().min(2),
        phone: z.string().trim().optional().or(z.literal('')),
        password: z.string().min(6),
      })
      .parse(req.body);

    const existingUser = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
    if (existingUser) {
      return res.status(409).json({ error: 'An account with this email already exists.' });
    }

    const parsedName = parseFullName(name);
    const user = await prisma.user.create({
      data: {
        email: email.toLowerCase(),
        firstName: parsedName.firstName,
        lastName: parsedName.lastName,
        phone: phone?.trim() || null,
        passwordHash: await hashPassword(password),
      },
      include: {
        addresses: {
          orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
        },
      },
    });

    res.status(201).json(sanitizeUser(user));
  }),
);

router.post(
  '/login',
  asyncHandler(async (req, res) => {
    const { email, password } = z
      .object({
        email: z.string().email(),
        password: z.string().min(1),
      })
      .parse(req.body);

    const user = await prisma.user.findUnique({
      where: { email: email.toLowerCase() },
      include: {
        addresses: {
          orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
        },
      },
    });

    if (!user || !(await verifyPassword(password, user.passwordHash))) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const safeUser = sanitizeUser(user);
    const token = signAccessToken({ userId: user.id, email: user.email });

    res.json({
      ...safeUser,
      token,
    });
  }),
);

router.get(
  '/:id',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const user = await getUserWithAddresses(userId);
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    res.json(sanitizeUser(user));
  }),
);

router.post(
  '/:id/avatar-upload',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const body: z.infer<typeof uploadAvatarSchema> = uploadAvatarSchema.parse(
      req.body,
    );

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const fileBuffer = decodedBase64Image(body.dataBase64);
    if (!fileBuffer || fileBuffer.length === 0) {
      return res.status(400).json({ error: 'Invalid image payload.' });
    }

    if (fileBuffer.length > 6 * 1024 * 1024) {
      return res
        .status(413)
        .json({ error: 'Image is too large. Max size is 6MB.' });
    }

    const extFromName = path
      .extname(body.fileName ?? '')
      .replace('.', '')
      .toLowerCase();
    const fallbackExt =
      fileExtensionFromMimeType(body.mimeType) ||
      extFromName ||
      'jpg';
    const extension = fallbackExt.replace(/[^a-z0-9]/gi, '') || 'jpg';
    const baseName = sanitizedBaseFileName(body.fileName) ?? randomUUID();
    const fileName = `${baseName}-${Date.now()}.${extension}`;

    const uploadsDir = path.resolve(process.cwd(), 'uploads', 'avatars');
    await fs.mkdir(uploadsDir, { recursive: true });
    const absoluteFilePath = path.join(uploadsDir, fileName);
    await fs.writeFile(absoluteFilePath, fileBuffer);

    const relativePath = `/uploads/avatars/${fileName}`;
    const host = req.get('host');
    const url = host
      ? `${req.protocol}://${host}${relativePath}`
      : relativePath;

    res.status(201).json({
      userId,
      fileName,
      path: relativePath,
      url,
      mimeType: body.mimeType ?? null,
      uploadedAt: new Date().toISOString(),
    });
  }),
);

router.patch(
  '/:id',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const body = profileSchema.parse(req.body);
    const existingUser = await prisma.user.findUnique({ where: { id: userId } });
    if (!existingUser) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const emailOwner = await prisma.user.findUnique({ where: { email: body.email.toLowerCase() } });
    if (emailOwner && emailOwner.id !== userId) {
      return res.status(409).json({ error: 'That email is already being used by another account.' });
    }

    const parsedName = parseFullName(body.name);
    const updatedUser = await prisma.user.update({
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

    res.json(sanitizeUser(updatedUser));
  }),
);

router.post(
  '/:id/addresses',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const body = addressSchema.parse(req.body);
    const user = await prisma.user.findUnique({ where: { id: userId } });

    if (!user) {
      return res.status(404).json({ error: 'User not found.' });
    }

    await prisma.$transaction(async (tx) => {
      const existingCount = await tx.address.count({ where: { userId } });
      const shouldBeDefault = body.isDefault || existingCount === 0;
      const city = body.city?.trim() || null;
      const quartier = body.quartier?.trim() || null;
      const line1 =
        body.address?.trim() ||
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
    res.status(201).json(sanitizeUser(updatedUser!));
  }),
);

router.patch(
  '/:id/addresses/:addressId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const addressId = getParam(req.params.addressId, 'addressId');
    const body = addressSchema.partial().parse(req.body);

    const address = await prisma.address.findFirst({
      where: { id: addressId, userId },
    });

    if (!address) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    await prisma.$transaction(async (tx) => {
      const hasLatitude = Object.prototype.hasOwnProperty.call(body, 'latitude');
      const hasLongitude = Object.prototype.hasOwnProperty.call(body, 'longitude');
      const hasAddress = Object.prototype.hasOwnProperty.call(body, 'address');
      const nextCity =
        body.city === undefined
          ? address.city
          : body.city === ''
            ? null
            : body.city.trim();
      const nextQuartier =
        body.quartier === undefined
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
    res.json(sanitizeUser(updatedUser!));
  }),
);

router.patch(
  '/:id/addresses/:addressId/default',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const addressId = getParam(req.params.addressId, 'addressId');

    const address = await prisma.address.findFirst({
      where: { id: addressId, userId },
    });

    if (!address) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    await prisma.$transaction(async (tx) => {
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
    res.json(sanitizeUser(updatedUser!));
  }),
);

router.delete(
  '/:id/addresses/:addressId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const addressId = getParam(req.params.addressId, 'addressId');
    const address = await prisma.address.findFirst({
      where: { id: addressId, userId },
    });

    if (!address) {
      return res.status(404).json({ error: 'Address not found.' });
    }

    await prisma.address.delete({ where: { id: addressId } });

    if (address.isDefault) {
      const replacement = await prisma.address.findFirst({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
      });

      if (replacement) {
        await prisma.address.update({
          where: { id: replacement.id },
          data: { isDefault: true },
        });
      }
    }

    const updatedUser = await getUserWithAddresses(userId);
    res.json(sanitizeUser(updatedUser!));
  }),
);

router.get(
  '/:id/payment-methods',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const methods = await prisma.paymentMethod.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
    });

    res.json(
      methods.map((method) => ({
        id: method.id,
        type: method.type,
        brand: method.brand,
        last4: method.last4,
        expiryMonth: method.expiryMonth,
        expiryYear: method.expiryYear,
        isDefault: method.isDefault,
      })),
    );
  }),
);

router.post(
  '/:id/payment-methods',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const body = paymentMethodSchema.parse(req.body);

    await prisma.$transaction(async (tx) => {
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

    const methods = await prisma.paymentMethod.findMany({
      where: { userId },
      orderBy: [{ isDefault: 'desc' }, { updatedAt: 'desc' }],
    });

    res.status(201).json(
      methods.map((method) => ({
        id: method.id,
        type: method.type,
        brand: method.brand,
        last4: method.last4,
        expiryMonth: method.expiryMonth,
        expiryYear: method.expiryYear,
        isDefault: method.isDefault,
      })),
    );
  }),
);

router.patch(
  '/:id/payment-methods/:paymentMethodId/default',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const paymentMethodId = getParam(req.params.paymentMethodId, 'paymentMethodId');

    await prisma.$transaction(async (tx) => {
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
  }),
);

router.delete(
  '/:id/payment-methods/:paymentMethodId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const paymentMethodId = getParam(req.params.paymentMethodId, 'paymentMethodId');
    const method = await prisma.paymentMethod.findFirst({
      where: { id: paymentMethodId, userId },
    });

    if (!method) {
      return res.status(404).json({ error: 'Payment method not found.' });
    }

    await prisma.paymentMethod.delete({ where: { id: paymentMethodId } });
    res.status(204).send();
  }),
);

router.get(
  '/:id/wishlist',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const items = await prisma.wishlistItem.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    res.json(
      items.map((item) => ({
        id: item.id,
        moduleType: item.moduleType,
        entityId: item.entityId,
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        price: toNumber(item.price),
      })),
    );
  }),
);

router.post(
  '/:id/wishlist',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const body = wishlistSchema.parse(req.body);

    const item = await prisma.wishlistItem.upsert({
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
      price: toNumber(item.price),
    });
  }),
);

router.delete(
  '/:id/wishlist/:entityId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const entityId = getParam(req.params.entityId, 'entityId');
    const moduleTypeValue = req.query.moduleType?.toString().toUpperCase();

    if (!moduleTypeValue || !(moduleTypeValue in ModuleType)) {
      return res.status(400).json({ error: 'moduleType is required.' });
    }

    await prisma.wishlistItem.deleteMany({
      where: {
        userId,
        entityId,
        moduleType: moduleTypeValue as ModuleType,
      },
    });

    res.status(204).send();
  }),
);

router.get(
  '/:id/coupons',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.id, 'userId');
    const coupons = await prisma.userCoupon.findMany({
      where: { userId },
      include: { promotion: true },
      orderBy: { createdAt: 'desc' },
    });

    res.json(
      coupons.map((coupon) => ({
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
          discountValue: toNumber(coupon.promotion.discountValue),
          active: coupon.promotion.active,
          metadata: coupon.promotion.metadata,
        },
      })),
    );
  }),
);

export default router;
