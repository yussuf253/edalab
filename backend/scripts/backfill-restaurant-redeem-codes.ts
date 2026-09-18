/**
 * Backfills `redeemCode` for every restaurant that doesn't have one.
 *
 * Run: npx ts-node scripts/backfill-restaurant-redeem-codes.ts
 * (or compile/transpile via tsx: npx tsx scripts/backfill-restaurant-redeem-codes.ts)
 */
import { PrismaClient } from '@prisma/client';
import { randomInt } from 'node:crypto';

const ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

function generateCode(): string {
  let code = '';
  for (let i = 0; i < 8; i += 1) {
    code += ALPHABET[randomInt(ALPHABET.length)];
  }
  return code;
}

async function main() {
  const prisma = new PrismaClient();
  try {
    const restaurants = await prisma.restaurant.findMany({
      where: { redeemCode: null },
      select: { id: true, name: true },
    });

    console.log(`Restaurants missing a redeem code: ${restaurants.length}`);

    const used = new Set(
      (
        await prisma.restaurant.findMany({
          where: { redeemCode: { not: null } },
          select: { redeemCode: true },
        })
      )
        .map((r) => r.redeemCode)
        .filter((code): code is string => code !== null),
    );

    let updated = 0;
    for (const restaurant of restaurants) {
      let code = generateCode();
      // Collision-check against codes we know about (DB unique constraint is
      // the final guard, but retrying here keeps the loop deterministic).
      while (used.has(code)) {
        code = generateCode();
      }
      used.add(code);

      await prisma.restaurant.update({
        where: { id: restaurant.id },
        data: { redeemCode: code },
      });
      updated += 1;
      console.log(`  ${restaurant.name} → ${code}`);
    }

    console.log(`Done. ${updated} restaurants updated.`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
