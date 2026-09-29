/**
 * Replaces the sample menus of Aska Tacos (r19) and SOHO Café (r20) with their
 * real menus:
 *
 *  - Aska Tacos: full menu imported from aska_tacos_menu.csv (37 items).
 *    Old sample items with the `food-r19-*` id prefix are deleted.
 *  - SOHO Café: 10 items (4 mains + juices) provided inline below.
 *    Old sample items with the `food-r20-*` id prefix are deleted.
 *
 * Both restaurants keep their catalog data (rating, fees, etc.); only menu
 * categories and items are rebuilt. Category ids are stable
 * (`r19-<slug>`, `r20-<slug>`) so re-runs upsert instead of duplicating.
 *
 * Run from backend/:
 *   npx tsx prisma/seed-aska-soho-real-menus.ts            (dry run)
 *   npx tsx prisma/seed-aska-soho-real-menus.ts --apply    (writes)
 */
import fs from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
dotenv.config();

const prisma = new PrismaClient();
const apply = process.argv.includes('--apply');

type MenuRow = {
  restaurant: string;
  nom: string;
  categorie: string;
  prix: number;
  description: string;
  imageUrl: string | null;
};

// --- SOHO Café inline menu (from the owner) ---
const SOHO_BASE =
  'https://snapcalorie-webflow-website.s3.us-east-2.amazonaws.com/media/food_pics_v2/medium/';
const SOHO_ITEMS: Array<{
  nom: string;
  categorie: string;
  prix: number;
  description: string;
  imageUrl: string;
}> = [
  { nom: 'Tacos', categorie: 'Tacos', prix: 750, description: 'Tacos SOHO Café', imageUrl: SOHO_BASE + 'tacos.jpg' },
  { nom: 'Tacos avec frites', categorie: 'Tacos', prix: 1100, description: 'Tacos servi avec frites', imageUrl: SOHO_BASE + 'tacos.jpg' },
  { nom: 'Burger', categorie: 'Burgers', prix: 750, description: 'Burger SOHO Café', imageUrl: SOHO_BASE + 'hamburger.jpg' },
  { nom: 'Burger avec frites', categorie: 'Burgers', prix: 1100, description: 'Burger servi avec frites', imageUrl: SOHO_BASE + 'hamburger.jpg' },
  { nom: 'Pasta avec poulet', categorie: 'Pasta', prix: 800, description: 'Pasta au poulet', imageUrl: SOHO_BASE + 'chicken_pasta.jpg' },
  { nom: 'Jus de Mangue', categorie: 'Jus', prix: 350, description: 'Jus de mangue frais', imageUrl: SOHO_BASE + 'mango.jpg' },
  { nom: 'Jus de Papaye', categorie: 'Jus', prix: 350, description: 'Jus de papaye frais', imageUrl: SOHO_BASE + 'papaya.jpg' },
  { nom: 'Jus de Citron', categorie: 'Jus', prix: 350, description: 'Jus de citron frais', imageUrl: SOHO_BASE + 'lemon.jpg' },
  { nom: 'Jus de Mélon', categorie: 'Jus', prix: 350, description: 'Jus de melon frais', imageUrl: SOHO_BASE + 'cantaloupe.jpg' },
];

function parseCsvLine(line: string): string[] {
  const fields: string[] = [];
  let value = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i += 1) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') { value += '"'; i += 1; } else { inQuotes = !inQuotes; }
      continue;
    }
    if (ch === ',' && !inQuotes) { fields.push(value); value = ''; continue; }
    value += ch;
  }
  fields.push(value);
  return fields;
}

function parseAskaCsv(): MenuRow[] {
  const csvPath = path.resolve(__dirname, '..', '..', 'aska_tacos_menu.csv');
  const csv = fs.readFileSync(csvPath, 'utf8').replace(/^\uFEFF/, '');
  const lines = csv.split('\n').filter((l) => l.trim().length > 0);
  const header = parseCsvLine(lines[0]).map((h) => h.trim());
  const col = (name: string) => header.indexOf(name);

  const rows: MenuRow[] = [];
  for (let i = 1; i < lines.length; i += 1) {
    const f = parseCsvLine(lines[i]);
    const prix = Number((f[col('prix')] ?? '').replace(',', '.'));
    if (!Number.isFinite(prix)) {
      console.warn(`Skipping malformed row ${i + 1}`);
      continue;
    }
    const imageUrl = (f[col('image_url')] ?? '').trim();
    rows.push({
      restaurant: (f[col('restaurant')] ?? '').trim(),
      nom: (f[col('nom')] ?? '').trim(),
      categorie: (f[col('categorie')] ?? '').trim() || 'Menu',
      prix,
      description: (f[col('description')] ?? '').trim(),
      imageUrl: imageUrl.startsWith('http') ? imageUrl : null,
    });
  }
  return rows;
}

function slugify(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

type PlanItem = {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string | null;
};

type Plan = {
  restaurantId: string;
  categories: Array<{ id: string; name: string; sortOrder: number }>;
  items: PlanItem[];
};

function buildPlan(restaurantId: string, rows: MenuRow[]): Plan {
  const categoryOrder: string[] = [];
  const byCategory = new Map<string, MenuRow[]>();
  for (const row of rows) {
    if (!byCategory.has(row.categorie)) {
      byCategory.set(row.categorie, []);
      categoryOrder.push(row.categorie);
    }
    byCategory.get(row.categorie)!.push(row);
  }

  const plan: Plan = { restaurantId, categories: [], items: [] };
  categoryOrder.forEach((categorie, index) => {
    const categoryId = `${restaurantId}-${slugify(categorie)}`;
    plan.categories.push({ id: categoryId, name: categorie, sortOrder: index });
    byCategory.get(categorie)!.forEach((row, itemIndex) => {
      plan.items.push({
        id: `askasoho-${restaurantId}-${slugify(row.nom)}-${String(itemIndex + 1).padStart(2, '0')}`,
        categoryId,
        name: row.nom,
        description: row.description,
        price: row.prix,
        imageUrl: row.imageUrl,
      });
    });
  });
  return plan;
}

async function applyPlan(plan: Plan, deletePrefix: string) {
  for (const category of plan.categories) {
    await prisma.restaurantMenuCategory.upsert({
      where: { id: category.id },
      update: { restaurantId: plan.restaurantId, name: category.name, sortOrder: category.sortOrder },
      create: { id: category.id, restaurantId: plan.restaurantId, name: category.name, sortOrder: category.sortOrder },
    });
  }

  for (const item of plan.items) {
    await prisma.restaurantMenuItem.upsert({
      where: { id: item.id },
      update: {
        restaurantId: plan.restaurantId,
        categoryId: item.categoryId,
        name: item.name,
        description: item.description,
        price: item.price,
        imageUrl: item.imageUrl,
        isAvailable: true,
      },
      create: {
        id: item.id,
        restaurantId: plan.restaurantId,
        categoryId: item.categoryId,
        name: item.name,
        description: item.description,
        price: item.price,
        imageUrl: item.imageUrl,
        isPopular: false,
        isAvailable: true,
        customizationsJson: [],
      },
    });
  }

  // Replace old sample items
  const deleted = await prisma.restaurantMenuItem.deleteMany({
    where: { restaurantId: plan.restaurantId, id: { startsWith: deletePrefix } },
  });
  return deleted.count;
}

async function main() {
  const askaRows = parseAskaCsv().filter((r) => r.restaurant === 'Aska Tacos');
  const sohoRows: MenuRow[] = SOHO_ITEMS.map((item) => ({
    restaurant: 'SOHO Café',
    ...item,
  }));

  const askaPlan = buildPlan('r19', askaRows);
  const sohoPlan = buildPlan('r20', sohoRows);

  for (const [name, plan] of [['Aska Tacos (r19)', askaPlan], ['SOHO Café (r20)', sohoPlan]] as const) {
    console.log(`\n${name}: ${plan.items.length} items`);
    for (const category of plan.categories) {
      const count = plan.items.filter((i) => i.categoryId === category.id).length;
      console.log(`  - ${category.name}: ${count} items`);
    }
  }

  if (!apply) {
    console.log('\nDry run: database not modified. Re-run with --apply.');
    return;
  }

  const deletedAska = await applyPlan(askaPlan, 'food-r19-');
  const deletedSoho = await applyPlan(sohoPlan, 'food-r20-');
  console.log(`\nApplied. Deleted old samples: ${deletedAska} (r19), ${deletedSoho} (r20).`);
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
