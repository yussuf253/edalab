import { ModuleType, OrderStatus, Prisma } from '@prisma/client';
import { Router } from 'express';
import { z } from 'zod';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { toNumber } from '../utils/serializers';

const router = Router();

const orderItemSchema = z.object({
  id: z.string().optional(),
  productId: z.string().optional(),
  name: z.string(),
  brand: z.string().optional(),
  price: z.coerce.number(),
  quantity: z.coerce.number().int().positive(),
  total: z.coerce.number().optional(),
  color: z.string().optional(),
  size: z.string().optional(),
  metadata: z.record(z.any()).optional(),
});

const createOrderSchema = z.object({
  userId: z.string(),
  moduleType: z.nativeEnum(ModuleType),
  status: z.nativeEnum(OrderStatus).optional(),
  subtotal: z.coerce.number(),
  tax: z.coerce.number(),
  deliveryFee: z.coerce.number().optional().default(0),
  discount: z.coerce.number().optional().default(0),
  total: z.coerce.number(),
  notes: z.string().optional(),
  items: z.array(orderItemSchema).default([]),
});

router.get(
  '/:userId',
  asyncHandler(async (req, res) => {
    const userId = getParam(req.params.userId, 'userId');
    const orders = await prisma.order.findMany({
      where: { userId },
      include: {
        items: true,
      },
      orderBy: { createdAt: 'desc' },
    }) as Prisma.OrderGetPayload<{ include: { items: true } }>[];

    res.json(
      orders.map((order) => ({
        id: order.id,
        userId: order.userId,
        moduleType: order.moduleType,
        status: order.status,
        subtotal: toNumber(order.subtotal),
        tax: toNumber(order.tax),
        deliveryFee: toNumber(order.deliveryFee),
        discount: toNumber(order.discount),
        total: toNumber(order.total),
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        items: order.items.map((item) => ({
          id: item.id,
          productId: item.productId,
          externalRefId: item.externalRefId,
          name: item.name,
          brand: item.brand,
          quantity: item.quantity,
          price: toNumber(item.unitPrice),
          total: toNumber(item.lineTotal),
          color: item.color,
          size: item.size,
          metadata: item.metadata,
        })),
      })),
    );
  }),
);

router.post(
  '/',
  asyncHandler(async (req, res) => {
    const body = createOrderSchema.parse(req.body);

    const order = await prisma.order.create({
      data: {
        userId: body.userId,
        moduleType: body.moduleType,
        status: body.status ?? OrderStatus.PENDING,
        subtotal: new Prisma.Decimal(body.subtotal),
        tax: new Prisma.Decimal(body.tax),
        deliveryFee: new Prisma.Decimal(body.deliveryFee),
        discount: new Prisma.Decimal(body.discount),
        total: new Prisma.Decimal(body.total),
        notes: body.notes ?? null,
        items: {
          create: body.items.map((item) => ({
            productId: item.productId ?? null,
            externalRefId: item.id ?? null,
            name: item.name,
            brand: item.brand ?? null,
            quantity: item.quantity,
            unitPrice: new Prisma.Decimal(item.price),
            lineTotal: new Prisma.Decimal(item.total ?? item.price * item.quantity),
            color: item.color ?? null,
            size: item.size ?? null,
            metadata: item.metadata ?? undefined,
          })),
        },
      },
      include: {
        items: true,
      },
    }) as Prisma.OrderGetPayload<{ include: { items: true } }>;

    res.status(201).json({
      id: order.id,
      userId: order.userId,
      moduleType: order.moduleType,
      status: order.status,
      subtotal: toNumber(order.subtotal),
      tax: toNumber(order.tax),
      deliveryFee: toNumber(order.deliveryFee),
      discount: toNumber(order.discount),
      total: toNumber(order.total),
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      items: order.items.map((item) => ({
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        price: toNumber(item.unitPrice),
        total: toNumber(item.lineTotal),
      })),
    });
  }),
);

export default router;
