"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const serializers_1 = require("../utils/serializers");
const router = (0, express_1.Router)();
router.get('/', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const promotions = await db_1.prisma.promotion.findMany({
        where: { active: true },
        orderBy: [{ priority: 'desc' }, { createdAt: 'desc' }],
    });
    const serialized = promotions.map((promotion) => {
        const metadata = promotion.metadata && typeof promotion.metadata === 'object'
            ? promotion.metadata
            : {};
        return {
            id: promotion.id,
            moduleType: promotion.moduleType,
            title: promotion.title,
            description: promotion.description,
            code: promotion.code,
            discountType: promotion.discountType,
            discountValue: (0, serializers_1.toNumber)(promotion.discountValue),
            startsAt: promotion.startsAt,
            endsAt: promotion.endsAt,
            priority: promotion.priority,
            kind: metadata.kind ?? 'coupon',
            metadata,
        };
    });
    res.json({
        specialOffers: serialized.filter((promotion) => promotion.kind == 'special'),
        flashSales: serialized.filter((promotion) => promotion.kind == 'flash'),
        coupons: serialized.filter((promotion) => promotion.kind == 'coupon'),
    });
}));
exports.default = router;
