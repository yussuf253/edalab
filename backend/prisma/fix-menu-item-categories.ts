/**
 * Fixes menu items whose `categoryId` points at a category owned by ANOTHER
 * restaurant (left behind by an old seed that reused the r1-/r2- style
 * category ids of other restaurants for Snack Attack).
 *
 * Every affected item is listed explicitly below with the category it belongs
 * to inside its own restaurant — nothing is guessed at runtime. The script
 * aborts if the database contains a mismatch that is not in this list, so a
 * new problem is never silently rewritten.
 *
 * One shop (LET'S VAPE) has no menu categories at all, so a single "Menu"
 * category is created under it before its item is moved.
 *
 * Run from backend/:
 *   npx tsx prisma/fix-menu-item-categories.ts            (dry run)
 *   npx tsx prisma/fix-menu-item-categories.ts --apply    (writes)
 */
import fs from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
dotenv.config();

const prisma = new PrismaClient();
const REPORT_PATH = path.resolve(__dirname, 'generated/fix_menu_item_categories_report.json');

const SNACK_ATTACK = 'kiki-rest-b490aa1037b2';
const LETS_VAPE = 'kiki-rest-018697fbe096';

type Fix = {
  itemId: string;
  restaurantId: string;
  itemName: string;
  fromCategory: string;
  targetCategoryName: string;
  reason: string;
};

/**
 * Hand-checked mapping. Target categories are resolved by name inside the
 * item's own restaurant, so the ids never have to be hardcoded.
 */
const FIXES: Fix[] = [
  // Hot drinks → Coffee
  { itemId: 'kiki-mi-2c3d4e5f', restaurantId: SNACK_ATTACK, itemName: 'Americano', fromCategory: 'r5-drinks', targetCategoryName: 'Coffee', reason: 'hot coffee drink' },
  { itemId: 'kiki-mi-3d4e5f6a', restaurantId: SNACK_ATTACK, itemName: 'Black coffee', fromCategory: 'r2-dessert', targetCategoryName: 'Coffee', reason: 'hot coffee drink' },
  { itemId: 'kiki-mi-5f6a7b8c', restaurantId: SNACK_ATTACK, itemName: 'Cafe latte noisette', fromCategory: 'r3-shared', targetCategoryName: 'Coffee', reason: 'latte' },
  { itemId: 'kiki-mi-6a7b8c9d', restaurantId: SNACK_ATTACK, itemName: 'Caf√© latte caramel', fromCategory: 'r1-rolls', targetCategoryName: 'Coffee', reason: 'latte (mojibake name, duplicate of the imported Café latte caramel)' },

  // Tea is the only drink that does not fit "Coffee"; Boissons is the shop's drinks bucket.
  { itemId: 'kiki-mi-8c9daef0', restaurantId: SNACK_ATTACK, itemName: 'Tea arabic', fromCategory: 'r1-rolls', targetCategoryName: 'Boissons', reason: 'tea, not coffee' },

  // Savory mains
  { itemId: 'kiki-mi-e3456789', restaurantId: SNACK_ATTACK, itemName: 'Burgers Chicken', fromCategory: 'r17-ethiopian', targetCategoryName: 'Lunch & Diner Menu', reason: 'burger main (Burger beef already there)' },
  { itemId: 'kiki-mi-f4567890', restaurantId: SNACK_ATTACK, itemName: 'Salads Chicken cesar', fromCategory: 'r13-seafood', targetCategoryName: 'Lunch & Diner Menu', reason: 'salad main, no salad category exists' },
  { itemId: 'kiki-mi-d2345678', restaurantId: SNACK_ATTACK, itemName: 'Special Chicken Waffles', fromCategory: 'r4-breakfast', targetCategoryName: 'Lunch & Diner Menu', reason: 'savory main at 1500 (sweet waffles stay in Sweets)' },
  { itemId: 'food-m1', restaurantId: SNACK_ATTACK, itemName: 'Teriyaki Chicken Bowl', fromCategory: 'r1-signatures', targetCategoryName: 'Lunch & Diner Menu', reason: 'rice bowl main' },

  // Sandwiches / wraps → Snacks Menu (it already holds the sandwiches)
  { itemId: 'kiki-mi-04567890', restaurantId: SNACK_ATTACK, itemName: 'Tacos chicken', fromCategory: 'r14-seafood', targetCategoryName: 'Snacks Menu', reason: 'fast-food snack' },
  { itemId: 'kiki-mi-c1234567', restaurantId: SNACK_ATTACK, itemName: 'Vegetable Wrap', fromCategory: 'r3-grill', targetCategoryName: 'Snacks Menu', reason: 'wrap/snack' },
  { itemId: 'kiki-mi-aef01234', restaurantId: SNACK_ATTACK, itemName: 'Wrap chicken', fromCategory: 'r16-buffet', targetCategoryName: 'Snacks Menu', reason: 'wrap/snack' },
  { itemId: 'kiki-mi-b0123456', restaurantId: SNACK_ATTACK, itemName: 'Pulled beef wrap', fromCategory: 'r4-drinks', targetCategoryName: 'Snacks Menu', reason: 'wrap/snack' },

  // Breakfast
  { itemId: 'kiki-mi-b1d2a3c4', restaurantId: SNACK_ATTACK, itemName: 'Pain au raisin', fromCategory: 'r16-buffet', targetCategoryName: 'Breakfast Menu', reason: 'viennoiserie' },
  { itemId: 'kiki-mi-f5b6c7d8', restaurantId: SNACK_ATTACK, itemName: 'Snack attack granola yogurt', fromCategory: 'r1-sides', targetCategoryName: 'Breakfast Menu', reason: 'breakfast bowl' },

  // Sweet waffles / crepes → Sweets (Crepes nature already there)
  { itemId: 'kiki-mi-15678901', restaurantId: SNACK_ATTACK, itemName: 'Crepes strawberry banana', fromCategory: 'r1-sides', targetCategoryName: 'Sweets', reason: 'sweet crepe' },
  { itemId: 'kiki-mi-14789012', restaurantId: SNACK_ATTACK, itemName: 'Waffle fruit', fromCategory: 'r4-drinks', targetCategoryName: 'Sweets', reason: 'sweet waffle' },
  { itemId: 'kiki-mi-25890123', restaurantId: SNACK_ATTACK, itemName: 'Waffle fruit nutella', fromCategory: 'r3-shared', targetCategoryName: 'Sweets', reason: 'sweet waffle' },

  // The vape shop has no categories; give it one so the item is not orphaned.
  { itemId: 'kiki-mi-36901234', restaurantId: LETS_VAPE, itemName: 'Stir fry noodles Chicken', fromCategory: 'r10-bbq', targetCategoryName: 'Menu', reason: 'restaurant has no categories yet' },
];

type Options = { apply: boolean };

function parseArgs(argv: string[]): Options {
  const options: Options = { apply: false };
  for (const arg of argv) {
    if (arg === '--apply') options.apply = true;
    else if (arg === '--dry-run') options.apply = false;
    else if (arg === '--help' || arg === '-h') {
      console.log('Usage: tsx prisma/fix-menu-item-categories.ts [--apply]');
      process.exit(0);
    }
  }
  return options;
}

async function findMismatches() {
  return prisma.$queryRawUnsafe<
    Array<{
      id: string;
      restaurantId: string;
      itemName: string;
      categoryId: string;
      categoryName: string;
      categoryRestaurantId: string;
    }>
  >(
    `select i.id as "id",
            i."restaurantId" as "restaurantId",
            i.name as "itemName",
            i."categoryId" as "categoryId",
            c.name as "categoryName",
            c."restaurantId" as "categoryRestaurantId"
       from "RestaurantMenuItem" i
       join "RestaurantMenuCategory" c on c.id = i."categoryId"
      where c."restaurantId" <> i."restaurantId"
      order by i."restaurantId", i.name`,
  );
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const mismatches = await findMismatches();

  const byId = new Map(mismatches.map((row) => [row.id, row]));
  const unknown = mismatches.filter((row) => !FIXES.some((fix) => fix.itemId === row.id));
  const stale = FIXES.filter((fix) => !byId.has(fix.itemId));

  console.log(`Mismatched items in database: ${mismatches.length}`);
  if (unknown.length > 0) {
    console.error('Unrecognised mismatches (refusing to guess):');
    for (const row of unknown) console.error(`  ${row.id} ${row.itemName} -> ${row.categoryName}`);
    process.exit(1);
  }
  if (stale.length > 0) {
    console.warn('Mappings whose item is already fixed or missing (ignored):');
    for (const fix of stale) console.warn(`  ${fix.itemId} ${fix.itemName}`);
  }

  // Resolve target category per restaurant; create "Menu" only where the
  // restaurant has no categories at all.
  const updates: Array<{ itemId: string; itemName: string; from: string; to: string; toId: string; reason: string }> = [];
  for (const fix of FIXES) {
    const row = byId.get(fix.itemId);
    if (row == null) continue;
    if (row.categoryName === fix.targetCategoryName) {
      // Already in the right category by name — only its owner was wrong.
      console.log(`  ${fix.itemId}: already in "${fix.targetCategoryName}"`);
    }

    let category = await prisma.restaurantMenuCategory.findFirst({
      where: { restaurantId: fix.restaurantId, name: fix.targetCategoryName },
      select: { id: true, name: true },
    });

    if (category == null && fix.restaurantId === LETS_VAPE && fix.targetCategoryName === 'Menu') {
      const existingCount = await prisma.restaurantMenuCategory.count({ where: { restaurantId: fix.restaurantId } });
      if (existingCount > 0) {
        throw new Error(`Refusing to create "Menu" on ${fix.restaurantId}: it already has ${existingCount} categories.`);
      }
      category = options.apply
        ? await prisma.restaurantMenuCategory.create({
            data: { id: `${fix.restaurantId}-menu`, restaurantId: fix.restaurantId, name: 'Menu', sortOrder: 1 },
            select: { id: true, name: true },
          })
        : { id: `${fix.restaurantId}-menu`, name: 'Menu' };
      console.log(`  created category "${category.name}" (${category.id}) under ${fix.restaurantId}`);
    }

    if (category == null) {
      throw new Error(`No "${fix.targetCategoryName}" category exists for ${fix.restaurantId} (${fix.itemName}).`);
    }

    updates.push({
      itemId: fix.itemId,
      itemName: fix.itemName,
      from: row.categoryName,
      to: category.name,
      toId: category.id,
      reason: fix.reason,
    });
  }

  console.log('\nPlanned moves:');
  for (const update of updates) {
    console.log(`  ${update.itemId}  ${update.itemName}: "${update.from}" -> "${update.to}"  (${update.reason})`);
  }

  if (!options.apply) {
    const report = { generatedAt: new Date().toISOString(), applied: false, mismatches: mismatches.length, updates };
    fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
    fs.writeFileSync(REPORT_PATH, JSON.stringify(report, null, 2), 'utf8');
    console.log('\nDry run: database was not modified. Re-run with --apply to write.');
    return;
  }

  await prisma.$transaction(async (tx) => {
    for (const update of updates) {
      await tx.restaurantMenuItem.update({
        where: { id: update.itemId },
        data: { categoryId: update.toId },
      });
    }
  });

  const remaining = await findMismatches();
  const report = {
    generatedAt: new Date().toISOString(),
    applied: true,
    movedItems: updates.length,
    remainingMismatches: remaining.length,
    updates,
  };
  fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
  fs.writeFileSync(REPORT_PATH, JSON.stringify(report, null, 2), 'utf8');

  console.log(`\nMoved ${updates.length} items. Remaining mismatches: ${remaining.length}`);
  if (remaining.length > 0) {
    for (const row of remaining) console.error(`  ${row.id} ${row.itemName} -> ${row.categoryName}`);
    process.exit(1);
  }
  console.log(`Report: ${REPORT_PATH}`);
}

main()
  .then(async () => prisma.$disconnect())
  .catch(async (error) => {
    console.error('Category fix failed:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
