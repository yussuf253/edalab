"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const zod_1 = require("zod");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const serializers_1 = require("../utils/serializers");
const router = (0, express_1.Router)();
const orderItemSchema = zod_1.z.object({
    id: zod_1.z.string().optional(),
    productId: zod_1.z.string().optional(),
    name: zod_1.z.string(),
    brand: zod_1.z.string().optional(),
    price: zod_1.z.coerce.number(),
    quantity: zod_1.z.coerce.number().int().positive(),
    total: zod_1.z.coerce.number().optional(),
    color: zod_1.z.string().optional(),
    size: zod_1.z.string().optional(),
    metadata: zod_1.z.record(zod_1.z.any()).optional(),
});
const createOrderSchema = zod_1.z.object({
    userId: zod_1.z.string(),
    moduleType: zod_1.z.nativeEnum(client_1.ModuleType),
    status: zod_1.z.nativeEnum(client_1.OrderStatus).optional(),
    subtotal: zod_1.z.coerce.number(),
    tax: zod_1.z.coerce.number(),
    deliveryFee: zod_1.z.coerce.number().optional().default(0),
    discount: zod_1.z.coerce.number().optional().default(0),
    total: zod_1.z.coerce.number(),
    notes: zod_1.z.string().optional(),
    items: zod_1.z.array(orderItemSchema).default([]),
});
router.get('/:userId', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const userId = (0, http_1.getParam)(req.params.userId, 'userId');
    const orders = await db_1.prisma.order.findMany({
        where: { userId },
        include: {
            items: true,
        },
        orderBy: { createdAt: 'desc' },
    });
    res.json(orders.map((order) => ({
        id: order.id,
        userId: order.userId,
        moduleType: order.moduleType,
        status: order.status,
        subtotal: (0, serializers_1.toNumber)(order.subtotal),
        tax: (0, serializers_1.toNumber)(order.tax),
        deliveryFee: (0, serializers_1.toNumber)(order.deliveryFee),
        discount: (0, serializers_1.toNumber)(order.discount),
        total: (0, serializers_1.toNumber)(order.total),
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        items: order.items.map((item) => ({
            id: item.id,
            productId: item.productId,
            externalRefId: item.externalRefId,
            name: item.name,
            brand: item.brand,
            quantity: item.quantity,
            price: (0, serializers_1.toNumber)(item.unitPrice),
            total: (0, serializers_1.toNumber)(item.lineTotal),
            color: item.color,
            size: item.size,
            metadata: item.metadata,
        })),
    })));
}));
router.post('/', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const body = createOrderSchema.parse(req.body);
    const order = await db_1.prisma.order.create({
        data: {
            userId: body.userId,
            moduleType: body.moduleType,
            status: body.status ?? client_1.OrderStatus.PENDING,
            subtotal: new client_1.Prisma.Decimal(body.subtotal),
            tax: new client_1.Prisma.Decimal(body.tax),
            deliveryFee: new client_1.Prisma.Decimal(body.deliveryFee),
            discount: new client_1.Prisma.Decimal(body.discount),
            total: new client_1.Prisma.Decimal(body.total),
            notes: body.notes ?? null,
            items: {
                create: body.items.map((item) => ({
                    productId: item.productId ?? null,
                    externalRefId: item.id ?? null,
                    name: item.name,
                    brand: item.brand ?? null,
                    quantity: item.quantity,
                    unitPrice: new client_1.Prisma.Decimal(item.price),
                    lineTotal: new client_1.Prisma.Decimal(item.total ?? item.price * item.quantity),
                    color: item.color ?? null,
                    size: item.size ?? null,
                    metadata: item.metadata ?? undefined,
                })),
            },
        },
        include: {
            items: true,
        },
    });
    res.status(201).json({
        id: order.id,
        userId: order.userId,
        moduleType: order.moduleType,
        status: order.status,
        subtotal: (0, serializers_1.toNumber)(order.subtotal),
        tax: (0, serializers_1.toNumber)(order.tax),
        deliveryFee: (0, serializers_1.toNumber)(order.deliveryFee),
        discount: (0, serializers_1.toNumber)(order.discount),
        total: (0, serializers_1.toNumber)(order.total),
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        items: order.items.map((item) => ({
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            price: (0, serializers_1.toNumber)(item.unitPrice),
            total: (0, serializers_1.toNumber)(item.lineTotal),
        })),
    });
}));
exports.default = router;
