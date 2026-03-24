import { Router } from 'express';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { toNumber } from '../utils/serializers';

const router = Router();

router.get(
  '/',
  asyncHandler(async (_req, res) => {
    const promotions = await prisma.promotion.findMany({
      where: { active: true },
      orderBy: [{ priority: 'desc' }, { createdAt: 'desc' }],
    });

    const serialized = promotions.map((promotion) => {
      const metadata =
        promotion.metadata && typeof promotion.metadata === 'object'
          ? (promotion.metadata as Record<string, unknown>)
          : {};

      return {
        id: promotion.id,
        moduleType: promotion.moduleType,
        title: promotion.title,
        description: promotion.description,
        code: promotion.code,
        discountType: promotion.discountType,
        discountValue: toNumber(promotion.discountValue),
        startsAt: promotion.startsAt,
        endsAt: promotion.endsAt,
        priority: promotion.priority,
        kind: (metadata.kind as string | undefined) ?? 'coupon',
        metadata,
      };
    });

    res.json({
      specialOffers: serialized.filter((promotion) => promotion.kind == 'special'),
      flashSales: serialized.filter((promotion) => promotion.kind == 'flash'),
      coupons: serialized.filter((promotion) => promotion.kind == 'coupon'),
    });
  }),
);

export default router;
