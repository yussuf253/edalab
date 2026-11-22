/**
 * Merges the two duplicated restaurant rows created by the old kikidrop
 * import into their curated seed rows:
 *
 *   kiki-rest-ac2fee84d346 ("LA CHAUMIERE")  ->  r2  ("La Chaumiere")
 *   kiki-rest-5ca9ec5ef608 ("LA FONTAINE")   ->  r12 ("La Fontaine")
 *
 * The kept rows are the seeded ones (proper name casing + curated cuisine,
 * tags, delivery pricing). Everything that points at the dropped row is
 * repointed first, inside a single transaction:
 *   - Order.moduleRefId            (food orders referencing the restaurant)
 *   - Conversation.entityId        (only FOOD entity conversations)
 *   - WishlistItem.entityId
 *   - ProProfile.bindings.restaurantIds (JSON array)
 *   - menu categories and menu items (moved to the kept restaurant)
 * Only then is the duplicate row deleted. Placeholder seed items are kept;
 * pass --prune-samples to remove the 3 USD sample rows as well.
 *
 * Run from backend/:
 *   npx tsx prisma/merge-duplicate-restaurants.ts             (dry run)
 *   npx tsx prisma/merge-duplicate-restaurants.ts --apply     (writes)
 */
import fs from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
dotenv.config();

const prisma = new PrismaClient();

const ITEM_ID_PREFIX = 'kikidrop-';
const REPORT_PATH = path.resolve(__dirname, 'generated/merge_duplicate_restaurants_report.json');

/** Placeholder rows from the original seed (USD sample prices). */
const SEED_SAMPLE_ITEM_IDS: Record<string, string[]> = {
  r2: ['food-m3', 'food-m4'],
  r12: ['food-m20'],
};

type Pair = { keepId: string; dropId: string; label: string };

const PAIRS: Pair[] = [
  { keepId: 'r2', dropId: 'kiki-rest-ac2fee84d346', label: 'La Chaumiere' },
  { keepId: 'r12', dropId: 'kiki-rest-5ca9ec5ef608', label: 'La Fontaine' },
];

type Options = { apply: boolean; pruneSamples: boolean };

function parseArgs(argv: string[]): Options {
  const options: Options = { apply: false, pruneSamples: false };
  for (const arg of argv) {
    if (arg === '--apply') options.apply = true;
    else if (arg === '--prune-samples') options.pruneSamples = true;
    else if (arg === '--dry-run') options.apply = false;
    else if (arg === '--help' || arg === '-h') {
      console.log(`
Usage:
  tsx prisma/merge-duplicate-restaurants.ts [--apply] [--prune-samples]

  --apply           Write the merge (default: dry run)
  --prune-samples   Also delete the 3 USD placeholder seed items
`);
      process.exit(0);
    }
  }
  return options;
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const report: Array<Record<string, unknown>> = [];

  for (const pair of PAIRS) {
    const keep = await prisma.restaurant.findUnique({
      where: { id: pair.keepId },
      include: { _count: { select: { menuItems: true, menuCategories: true } } },
    });
    const drop = await prisma.restaurant.findUnique({
      where: { id: pair.dropId },
      include: { _count: { select: { menuItems: true, menuCategories: true } } },
    });

    if (keep == null) {
      console.warn(`[${pair.label}] kept row ${pair.keepId} is missing — skipped.`);
      report.push({ ...pair, status: 'skipped-missing-keep' });
      continue;
    }
    if (drop == null) {
      let prunedSamples = 0;
      if (options.apply && options.pruneSamples) {
        const deleted = await prisma.restaurantMenuItem.deleteMany({
          where: { id: { in: SEED_SAMPLE_ITEM_IDS[pair.keepId] ?? [] }, restaurantId: pair.keepId },
        });
        prunedSamples = deleted.count;
      }
      console.log(
        `[${pair.label}] ${pair.dropId} already merged into ${pair.keepId} — nothing to move` +
          (prunedSamples > 0 ? `, deleted ${prunedSamples} placeholder items.` : '.'),
      );
      report.push({ ...pair, status: 'already-merged', prunedSamples });
      continue;
    }

    const [orders, conversations, wishlist, bindings] = await Promise.all([
      prisma.order.count({ where: { moduleRefId: pair.dropId } }),
      prisma.conversation.count({ where: { entityId: pair.dropId } }),
      prisma.wishlistItem.count({ where: { entityId: pair.dropId } }),
      prisma.proProfile.findMany({
        where: { bindings: { not: null } },
        select: { id: true, bindings: true },
      }),
    ]);
    const bindingHits = bindings.filter((profile) =>
      JSON.stringify(profile.bindings).includes(pair.dropId),
    );

    // Unique (userId, entityType, entityId) / (userId, moduleType, entityId)
    // collisions would make a blind repoint fail; detect them up front.
    const conversationConflicts = conversations === 0 ? 0 : await prisma.$queryRawUnsafe<Array<{ count: bigint }>>(
      `select count(*)::int as count from "Conversation" d
         join "Conversation" k
           on k."userId" = d."userId" and k."entityType" = d."entityType" and k."entityId" = $1
        where d."entityId" = $2`,
      pair.keepId,
      pair.dropId,
    );
    const wishlistConflicts = wishlist === 0 ? 0 : await prisma.$queryRawUnsafe<Array<{ count: bigint }>>(
      `select count(*)::int as count from "WishlistItem" d
         join "WishlistItem" k
           on k."userId" = d."userId" and k."moduleType" = d."moduleType" and k."entityId" = $1
        where d."entityId" = $2`,
      pair.keepId,
      pair.dropId,
    );

    const entry = {
      ...pair,
      status: options.apply ? 'merged' : 'planned',
      keepName: keep.name,
      dropName: drop.name,
      movedMenuItems: drop._count.menuItems,
      movedMenuCategories: drop._count.menuCategories,
      keptMenuItemsAfter: keep._count.menuItems + drop._count.menuItems,
      references: {
        orders,
        conversations,
        conversationConflicts: Number(conversationConflicts?.[0]?.count ?? 0),
        wishlist,
        wishlistConflicts: Number(wishlistConflicts?.[0]?.count ?? 0),
        proBindings: bindingHits.length,
      },
      copiedFields: [] as string[],
    };

    if (!options.apply) {
      console.log(`[${pair.label}] plan: ${pair.dropId} -> ${pair.keepId}`);
      console.log(`  move ${entry.movedMenuItems} items / ${entry.movedMenuCategories} categories`);
      console.log(`  references: ${JSON.stringify(entry.references)}`);
      report.push(entry);
      continue;
    }

    if (entry.references.conversationConflicts > 0 || entry.references.wishlistConflicts > 0) {
      throw new Error(
        `[${pair.label}] Refusing to merge: duplicate conversation/wishlist rows would collide on the kept restaurant.`,
      );
    }

    await prisma.$transaction(async (tx) => {
      // 1. Repoint anything that references the duplicate.
      await tx.order.updateMany({
        where: { moduleRefId: pair.dropId },
        data: { moduleRefId: pair.keepId },
      });
      await tx.conversation.updateMany({
        where: { entityId: pair.dropId },
        data: { entityId: pair.keepId },
      });
      await tx.wishlistItem.updateMany({
        where: { entityId: pair.dropId },
        data: { entityId: pair.keepId },
      });

      const profiles = await tx.proProfile.findMany({
        where: { bindings: { not: null } },
        select: { id: true, bindings: true },
      });
      for (const profile of profiles) {
        const serialized = JSON.stringify(profile.bindings);
        if (!serialized.includes(pair.dropId)) continue;
        await tx.proProfile.update({
          where: { id: profile.id },
          data: {
            bindings: JSON.parse(serialized.split(`"${pair.dropId}"`).join(`"${pair.keepId}"`)),
          },
        });
        entry.copiedFields.push(`proProfile:${profile.id}:bindings`);
      }

      // 2. Move the menu (categories first, then items).
      const movedCategories = await tx.restaurantMenuCategory.updateMany({
        where: { restaurantId: pair.dropId },
        data: { restaurantId: pair.keepId },
      });
      const movedItems = await tx.restaurantMenuItem.updateMany({
        where: { restaurantId: pair.dropId },
        data: { restaurantId: pair.keepId },
      });
      (entry as Record<string, unknown>).movedCategoriesWritten = movedCategories.count;
      (entry as Record<string, unknown>).movedItemsWritten = movedItems.count;

      // 3. Enrich the kept row from the duplicate where it is missing data.
      const data: Record<string, unknown> = {};
      if (keep.imageUrl == null && drop.imageUrl != null) data.imageUrl = drop.imageUrl;
      if (Number(keep.rating) === 0 && Number(drop.rating) > 0) data.rating = drop.rating;
      if (data.imageUrl != null) entry.copiedFields.push('imageUrl');
      if (data.rating != null) entry.copiedFields.push('rating');
      if (Object.keys(data).length > 0) {
        await tx.restaurant.update({ where: { id: pair.keepId }, data });
      }

      // 4. Optional cleanup of USD placeholder seed rows.
      if (options.pruneSamples) {
        const sampleIds = SEED_SAMPLE_ITEM_IDS[pair.keepId] ?? [];
        if (sampleIds.length > 0) {
          const deleted = await tx.restaurantMenuItem.deleteMany({
            where: { id: { in: sampleIds }, restaurantId: pair.keepId },
          });
          entry.copiedFields.push(`deletedSamples:${deleted.count}`);
        }
      }

      // 5. The duplicate must be empty now; delete it.
      const remaining = await tx.restaurantMenuItem.count({ where: { restaurantId: pair.dropId } });
      if (remaining > 0) {
        throw new Error(`[${pair.label}] ${remaining} menu items still attached to ${pair.dropId}.`);
      }
      await tx.restaurant.delete({ where: { id: pair.dropId } });
    });

    console.log(
      `[${pair.label}] merged ${pair.dropId} -> ${pair.keepId}: ` +
        `${entry.movedMenuItems} items, ${entry.movedMenuCategories} categories, ` +
        `orders=${orders}, conversations=${conversations}, wishlist=${wishlist}.`,
    );
    report.push(entry);
  }

  fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
  fs.writeFileSync(REPORT_PATH, JSON.stringify({ generatedAt: new Date().toISOString(), applied: options.apply, pairs: report }, null, 2), 'utf8');
  console.log(`\nReport: ${REPORT_PATH}`);
  if (!options.apply) console.log('Dry run: database was not modified. Re-run with --apply to merge.');
}

main()
  .then(async () => prisma.$disconnect())
  .catch(async (error) => {
    console.error('Restaurant merge failed:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
