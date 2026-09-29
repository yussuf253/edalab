/**
 * Imports REAL menus from edalab_menus_import.csv into the food catalog.
 *
 * Restaurants covered:
 *  - "Lados"                     -> existing restaurant r18 (sample items removed)
 *  - "Royal Coffee & Fast-Food"  -> new restaurant r21, exposed as "Royal Café"
 *
 * Every CSV row becomes a menu item under a per-restaurant menu category
 * derived from the CSV `categorie` column. Item ids are deterministic
 * (`csvmenu-<restaurantKey>-<n>`) and everything is upserted, so the script
 * is idempotent.
 *
 * Because this import replaces the Lados sample menu, it also deletes the
 * old sample items with the `food-r18-*` id prefix created by
 * seed-menu-items-r18-r20.ts. Use --keep-samples to skip that cleanup.
 *
 * Run from backend/:
 *   npx tsx prisma/seed-menus-from-csv.ts            (dry run: report only)
 *   npx tsx prisma/seed-menus-from-csv.ts --apply    (writes to database)
 */
import fs from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
dotenv.config();

const prisma = new PrismaClient();

type ImportOptions = {
  inputPath: string;
  apply: boolean;
  keepSamples: boolean;
};

type MenuRow = {
  restaurant: string;
  nom: string;
  categorie: string;
  prix: number;
  description: string;
  imageUrl: string | null;
};

// Maps a CSV restaurant name to the database restaurant it feeds.
type RestaurantTarget = {
  csvName: string;
  restaurantId: string;
  name: string;
  cuisine: string;
  slugBase: string;
};

const RESTAURANT_TARGETS: RestaurantTarget[] = [
  {
    csvName: 'Lados',
    restaurantId: 'r18',
    name: 'Lados',
    cuisine: 'Fast Food, Burgers',
    slugBase: 'lados',
  },
  {
    csvName: 'Royal Coffee & Fast-Food',
    restaurantId: 'r21',
    name: 'Royal Café',
    cuisine: 'Fast Food, Coffee & Cafe',
    slugBase: 'royal-cafe',
  },
];

// Lados sample items previously created by seed-menu-items-r18-r20.ts use
// deterministic ids food-r18-01 ... food-r18-50. Cleaning them by prefix
// makes this import safe to re-run after a full reseed.
const LADOS_SAMPLE_ITEM_PREFIX = 'food-r18-';

function parseArgs(argv: string[]): ImportOptions {
  const options: ImportOptions = {
    inputPath: process.env.EDALAB_MENUS_INPUT?.trim() ?? path.resolve(__dirname, '..', '..', 'edalab_menus_import.csv'),
    apply: false,
    keepSamples: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--input' && argv[i + 1]) {
      options.inputPath = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === '--apply') {
      options.apply = true;
      continue;
    }
    if (arg === '--keep-samples') {
      options.keepSamples = true;
      continue;
    }
    if (arg === '--dry-run') {
      options.apply = false;
      continue;
    }
    if (arg === '--help' || arg === '-h') {
      printHelpAndExit();
    }
  }

  options.inputPath = path.resolve(options.inputPath);
  return options;
}

function printHelpAndExit(): never {
  console.log(`
Usage:
  tsx prisma/seed-menus-from-csv.ts --apply [--input <csv-path>] [--keep-samples]

Options:
  --input <path>     CSV file path (default: ../../edalab_menus_import.csv)
  --apply            Apply upserts to database
  --dry-run          Extraction only, no database writes (default)
  --keep-samples     Do NOT delete the old food-r18-* Lados sample items
  --help             Show help
`);
  process.exit(0);
}

// Minimal CSV parser mirroring importKikiDropRestaurants.ts (handles quoted
// fields, escaped quotes and the BOM that Excel adds to the export).
function parseCsvLine(line: string): string[] {
  const fields: string[] = [];
  let value = '';
  let inQuotes = false;

  for (let index = 0; index < line.length; index += 1) {
    const char = line[index];
    if (char === '"') {
      if (inQuotes && line[index + 1] === '"') {
        value += '"';
        index += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }
    if (char === ',' && !inQuotes) {
      fields.push(value);
      value = '';
      continue;
    }
    value += char;
  }
  fields.push(value);
  return fields;
}

function parseCsv(csvText: string): MenuRow[] {
  const lines = csvText
    .replace(/^\uFEFF/, '')
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n')
    .split('\n')
    .filter((line) => line.trim().length > 0);

  if (lines.length === 0) return [];

  const header = parseCsvLine(lines[0]).map((entry) => entry.trim());
  const requiredColumns = ['restaurant', 'nom', 'categorie', 'prix', 'description'];
  for (const column of requiredColumns) {
    if (!header.includes(column)) {
      throw new Error(`CSV is missing required column "${column}". Found: ${header.join(', ')}`);
    }
  }

  const rows: MenuRow[] = [];
  for (let i = 1; i < lines.length; i += 1) {
    const parsed = parseCsvLine(lines[i]);
    const row: Record<string, string> = {};
    for (let j = 0; j < header.length; j += 1) {
      row[header[j]] = (parsed[j] ?? '').trim();
    }

    const prix = Number(row.prix?.replace(',', '.'));
    if (!row.restaurant || !row.nom || !Number.isFinite(prix)) {
      console.warn(`Skipping malformed CSV row ${i + 1}: ${lines[i].slice(0, 80)}`);
      continue;
    }

    rows.push({
      restaurant: row.restaurant,
      nom: row.nom,
      categorie: row.categorie?.trim() || 'Menu',
      prix,
      description: row.description ?? '',
      imageUrl: row.image_url && row.image_url.startsWith('http') ? row.image_url : null,
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

type SeedPlan = {
  restaurants: Array<{ target: RestaurantTarget; itemCount: number }>;
  categories: Array<{
    id: string;
    restaurantId: string;
    name: string;
    sortOrder: number;
    itemCount: number;
  }>;
  items: Array<{
    id: string;
    restaurantId: string;
    categoryId: string;
    name: string;
    description: string;
    price: number;
    imageUrl: string | null;
  }>;
};

function buildPlan(rows: MenuRow[]): SeedPlan {
  const plan: SeedPlan = { restaurants: [], categories: [], items: [] };

  for (const target of RESTAURANT_TARGETS) {
    const restaurantRows = rows.filter((row) => row.restaurant === target.csvName);
    if (restaurantRows.length === 0) {
      console.warn(`No rows found in CSV for restaurant "${target.csvName}" — nothing to import.`);
      continue;
    }

    plan.restaurants.push({ target, itemCount: restaurantRows.length });

    // Preserve first-appearance order of categories in the CSV.
    const categoryOrder: string[] = [];
    const byCategory = new Map<string, MenuRow[]>();
    for (const row of restaurantRows) {
      if (!byCategory.has(row.categorie)) {
        byCategory.set(row.categorie, []);
        categoryOrder.push(row.categorie);
      }
      byCategory.get(row.categorie)!.push(row);
    }

    categoryOrder.forEach((categorie, categoryIndex) => {
      const categoryId = `${target.restaurantId}-csv-${slugify(categorie)}`;
      const categoryRows = byCategory.get(categorie)!;
      plan.categories.push({
        id: categoryId,
        restaurantId: target.restaurantId,
        name: categorie,
        sortOrder: categoryIndex,
        itemCount: categoryRows.length,
      });

      categoryRows.forEach((row, itemIndex) => {
        plan.items.push({
          id: `csvmenu-${target.slugBase}-${slugify(categorie)}-${String(itemIndex + 1).padStart(2, '0')}`,
          restaurantId: target.restaurantId,
          categoryId,
          name: row.nom,
          description: row.description,
          price: row.prix,
          imageUrl: row.imageUrl,
        });
      });
    });
  }

  return plan;
}

function summarize(plan: SeedPlan) {
  console.log('Import plan:');
  for (const entry of plan.restaurants) {
    console.log(`  ${entry.target.name} (${entry.target.restaurantId}): ${entry.itemCount} items`);
    for (const category of plan.categories.filter((c) => c.restaurantId === entry.target.restaurantId)) {
      console.log(`    - ${category.name}: ${category.itemCount} items`);
    }
  }
}

async function ensureRestaurant(target: RestaurantTarget) {
  // Royal Café is new: create it if missing. Existing restaurants (Lados)
  // keep their catalog data untouched — only the name/cuisine is aligned.
  await prisma.restaurant.upsert({
    where: { id: target.restaurantId },
    update: { name: target.name, cuisine: target.cuisine },
    create: {
      id: target.restaurantId,
      name: target.name,
      cuisine: target.cuisine,
      rating: 4.2,
      reviewCount: 0,
      deliveryTime: '25-35',
      deliveryFee: 2,
      imageUrl: null,
      isOpen: true,
      distanceKm: null,
      tagsJson: ['Fast Food', 'Coffee', 'Djibouti City'],
    },
  });
}

async function applyToDatabase(plan: SeedPlan, keepSamples: boolean) {
  for (const { target } of plan.restaurants) {
    await ensureRestaurant(target);
  }

  for (const category of plan.categories) {
    await prisma.restaurantMenuCategory.upsert({
      where: { id: category.id },
      update: { restaurantId: category.restaurantId, name: category.name, sortOrder: category.sortOrder },
      create: {
        id: category.id,
        restaurantId: category.restaurantId,
        name: category.name,
        sortOrder: category.sortOrder,
      },
    });
  }

  for (const item of plan.items) {
    await prisma.restaurantMenuItem.upsert({
      where: { id: item.id },
      update: {
        restaurantId: item.restaurantId,
        categoryId: item.categoryId,
        name: item.name,
        description: item.description,
        price: item.price,
        imageUrl: item.imageUrl,
        isAvailable: true,
      },
      create: {
        id: item.id,
        restaurantId: item.restaurantId,
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

  // Remove the Lados sample items unless explicitly kept.
  if (!keepSamples) {
    const deleted = await prisma.restaurantMenuItem.deleteMany({
      where: { id: { startsWith: LADOS_SAMPLE_ITEM_PREFIX } },
    });
    if (deleted.count > 0) {
      console.log(`Deleted ${deleted.count} Lados sample items (${LADOS_SAMPLE_ITEM_PREFIX}*)`);
    }
  }
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!fs.existsSync(options.inputPath)) {
    throw new Error(`CSV file not found: ${options.inputPath}`);
  }

  const rows = parseCsv(fs.readFileSync(options.inputPath, 'utf8'));
  if (rows.length === 0) {
    throw new Error(`No menu rows parsed from ${options.inputPath}`);
  }

  const plan = buildPlan(rows);
  summarize(plan);

  if (!options.apply) {
    console.log('Dry run mode: database was not modified. Re-run with --apply to write.');
    return;
  }

  await applyToDatabase(plan, options.keepSamples);
  console.log(`Import completed: ${plan.items.length} menu items across ${plan.restaurants.length} restaurants.`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error('edalab_menus_import.csv import failed:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
