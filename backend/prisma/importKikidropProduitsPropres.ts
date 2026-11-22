/**
 * Imports restaurants + menus from `kikidrop_produits_propres.xlsx`
 * (sheets: "Magasins" = stores, "Produits" = products/menu items).
 *
 * Safety rules baked into this script:
 *  - Existing restaurants are resolved by NORMALIZED NAME (accents, case,
 *    punctuation and spacing ignored), so the 100+ stores already imported by
 *    importKikiDropRestaurants.ts are updated, never duplicated.
 *  - New restaurants only get created for food businesses. Pharmacies, beauty,
 *    vape/tobacco, clothing, electronics, gas, wholesale & grocery-only stores
 *    are skipped and reported (see SKIP_STORES / NON_FOOD_PATTERNS).
 *  - NOTHING is deleted. Curated menus (Lados, Aska Tacos, SOHO, Royal Café…)
 *    are untouched; if an item name already exists for a restaurant, the CSV
 *    row is skipped instead of duplicated.
 *  - Restaurant ids for new rows are deterministic
 *    (`kiki-rest-<sha1(name::address)>`), menu ids too (`kikidrop-<sha1>`),
 *    so the script is idempotent and safe to re-run.
 *
 * Run from backend/:
 *   npx tsx prisma/importKikidropProduitsPropres.ts \
 *     --input ../kikidrop_produits_propres.xlsx            (dry run + report)
 *   npx tsx prisma/importKikidropProduitsPropres.ts \
 *     --input ../kikidrop_produits_propres.xlsx --apply    (writes to database)
 */
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
dotenv.config();

const prisma = new PrismaClient();

const RESTAURANT_ID_PREFIX = 'kiki-rest-';
const ITEM_ID_PREFIX = 'kikidrop-';
const REPORT_PATH = path.resolve(__dirname, 'generated/kikidrop_produits_import_report.json');
const XLSX_TMP_DIR = path.resolve(__dirname, 'generated/xlsx');
const DJIBOUTI_CENTER = { lat: 11.595, lon: 43.148 };

/**
 * Stores that are not restaurants. They exist in kikidrop (and in the file)
 * but belong to the pharmacy / shopping / grocery modules, not to Food.
 * Matched on normalized name; regexes cover whole families (pharmacies…).
 */
const NON_FOOD_PATTERNS: RegExp[] = [
  /pharmacie/,
  /perfum/,
  /parfum/,
  /cosmetic/,
  /cosmetique/,
  /beauty/,
  /vapour|vape/,
  /khat/,
  /clothing|outlet|magasin/,
  /baby station/,
  /brico/,
  /flowers|fleur/,
  /gaz|fuel/,
  /mobile|electronics/,
  /paiement/,
  /hypermarch/,
  /^le marche$/,
  /nougaprix/,
  /roi des epices/,
  /ruches de doaan/,
  /zawam honey/,
  /eau boissons en volume/,
  /sheraton events/,
  /joy svamc/,
  /mbbs/,
  /wally shop/,
  /khaty s shop/,
  /^sh beauty box$/,
  /camellia powders/,
  /al haramain perfumes/,
  /glow orginal/,
  /^djib nature detox$/,
  /karim flowers/,
];

const FOOD_KEYWORDS = [
  'restaurant',
  'cafe',
  'coffee',
  'pizza',
  'burger',
  'taco',
  'sushi',
  'shawarma',
  'grill',
  'bbq',
  'pasta',
  'bakery',
  'patis',
  'chicken',
  'sandwich',
  'food',
  'kebab',
  'fries',
  'indien',
  'indian',
  'bento',
  'barbecue',
  'wings',
  'cream',
  'naan',
  'mouk',
  'mukbass',
  'samba',
  'libanais',
  'hummus',
  'senegalais',
  'sénégalais',
] as const;

type DedicatedFoodCategory = { id: string; label: string; keywords: string[] };

const DEDICATED_FOOD_CATEGORIES: DedicatedFoodCategory[] = [
  { id: 'burgers_fastfood', label: 'Burgers & Fast Food', keywords: ['burger', 'chicking', 'chicken', 'fast food', 'smash', 'wings'] },
  { id: 'pizza_italian', label: 'Pizza & Italian', keywords: ['pizza', 'pasta', 'pizzaiolo', 'albertos', 'amore', 'italian'] },
  { id: 'tacos_mexican', label: 'Tacos & Mexican', keywords: ['taco', 'mexic'] },
  { id: 'coffee_cafe', label: 'Coffee & Cafe', keywords: ['coffee', 'cafe', 'cafet', 'lavazza', 'velvet'] },
  { id: 'bakery_desserts', label: 'Bakery & Desserts', keywords: ['bakery', 'cake', 'patis', 'moulin', 'dessert', 'sweet'] },
  { id: 'sushi_asian', label: 'Sushi & Asian', keywords: ['sushi', 'bento', 'wok', 'asian', 'ramen', 'noodle'] },
  { id: 'bbq_grill_kebab', label: 'BBQ, Grill & Kebab', keywords: ['bbq', 'barbecue', 'grill', 'kebab', 'shawarma'] },
  { id: 'middle_eastern', label: 'Middle Eastern', keywords: ['hummus', 'libanais', 'arab', 'yemen', 'levant', 'mandi', 'mukbass', 'moukbasa'] },
  { id: 'healthy_salad', label: 'Healthy & Salad', keywords: ['healthy', 'salad', 'vegan', 'vegetarian'] },
  { id: 'icecream_frozen', label: 'Ice Cream & Frozen Treats', keywords: ['cold stone', 'ice cream', 'gelato', 'frozen yogurt'] },
  { id: 'indian', label: 'Indian', keywords: ['indien', 'indian', 'naan'] },
  { id: 'general_restaurants', label: 'General Restaurants', keywords: ['restaurant', 'house', 'kitchen', 'diner', 'samba'] },
  { id: 'international_other', label: 'International & Other', keywords: [] },
];

/** Rubric → category label hints, used when the name is not conclusive. */
const RUBRIC_HINTS: Array<{ match: string; id: string }> = [
  { match: 'asian', id: 'sushi_asian' },
  { match: 'italian', id: 'pizza_italian' },
  { match: 'yemeni', id: 'middle_eastern' },
  { match: 'lebanese', id: 'middle_eastern' },
  { match: 'indian', id: 'indian' },
  { match: 'west african', id: 'general_restaurants' },
];

type StoreRow = {
  name: string;
  rubrics: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
  rating: number;
  isOpen: boolean;
  available: boolean;
  productCount: number;
};

type ProductRow = {
  store: string;
  category: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string | null;
};

type ExistingRestaurant = {
  id: string;
  name: string;
  imageUrl: string | null;
  cityZone: string[];
};

type NewRestaurantSeed = {
  id: string;
  name: string;
  cuisine: string;
  rating: number;
  isOpen: boolean;
  deliveryTime: string;
  deliveryFee: number;
  imageUrl: string | null;
  distanceKm: number | null;
  tags: string[];
};

type MenuCategorySeed = {
  id: string;
  restaurantId: string;
  name: string;
  sortOrder: number;
};

type MenuItemSeed = {
  id: string;
  restaurantId: string;
  categoryId: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string | null;
};

// ── helpers ────────────────────────────────────────────────────────────────

function printHelpAndExit(): never {
  console.log(`
Usage:
  tsx prisma/importKikidropProduitsPropres.ts --input <xlsx> [options]

Options:
  --input <path>   kikidrop_produits_propres.xlsx (default: ../kikidrop_produits_propres.xlsx)
  --apply          Write restaurants + menus to the database
  --prune-samples  Delete the 3 placeholder seed items on r2/r12 (opt-in)
  --dry-run        Extraction + report only (default)
  --help           Show help

Requires python3 with openpyxl to read the .xlsx workbook.
`);
  process.exit(0);
}

type Options = { inputPath: string; apply: boolean; pruneSamples: boolean };

/**
 * Placeholder menu rows created by the original seed (USD sample prices).
 * They are only removed when --prune-samples is passed explicitly, and only
 * for restaurants that receive a real imported menu.
 */
const SEED_SAMPLE_ITEM_IDS: Record<string, string[]> = {
  r2: ['food-m3', 'food-m4'],
  r12: ['food-m20'],
};

function parseArgs(argv: string[]): Options {
  const options: Options = {
    inputPath: process.env.KIKIDROP_PRODUITS_INPUT?.trim() ?? path.resolve(__dirname, '..', '..', 'kikidrop_produits_propres.xlsx'),
    apply: false,
    pruneSamples: false,
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
    if (arg === '--dry-run') {
      options.apply = false;
      continue;
    }
    if (arg === '--prune-samples') {
      options.pruneSamples = true;
      continue;
    }
    if (arg === '--help' || arg === '-h') {
      printHelpAndExit();
    }
  }

  options.inputPath = path.resolve(options.inputPath);
  return options;
}

function normalize(value: string): string {
  return (value ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[\u2019\u2018]/g, "'")
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function slugify(value: string): string {
  return normalize(value).replace(/\s+/g, '-');
}

function slugHash(value: string): string {
  return crypto.createHash('sha1').update(value).digest('hex').slice(0, 12);
}

function itemHash(value: string): string {
  return crypto.createHash('sha1').update(value).digest('hex').slice(0, 18);
}

/** Minimal CSV parser (quoted fields, escaped quotes, BOM). */
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

function parseCsv(text: string): Array<Record<string, string>> {
  const lines = text
    .replace(/^\uFEFF/, '')
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n')
    .split('\n')
    .filter((line) => line.trim().length > 0);
  if (lines.length === 0) return [];

  const header = parseCsvLine(lines[0]).map((entry) => entry.trim());
  const rows: Array<Record<string, string>> = [];
  for (let i = 1; i < lines.length; i += 1) {
    const parsed = parseCsvLine(lines[i]);
    const row: Record<string, string> = {};
    for (let j = 0; j < header.length; j += 1) {
      row[header[j]] = (parsed[j] ?? '').trim();
    }
    rows.push(row);
  }
  return rows;
}

/** Converts the workbook sheets to CSV (kept simple: python3 + openpyxl). */
function workbookToCsv(xlsxPath: string, sheets: string[]): Record<string, string> {
  fs.mkdirSync(XLSX_TMP_DIR, { recursive: true });
  const script = `
import csv, sys
import openpyxl
wb = openpyxl.load_workbook(sys.argv[1], data_only=True)
for name in sys.argv[3:]:
    if name not in wb.sheetnames:
        raise SystemExit("Missing sheet: " + name)
    with open(sys.argv[2] + "/" + name + ".csv", "w", newline="", encoding="utf-8") as fh:
        csv.writer(fh).writerows(wb[name].iter_rows(values_only=True))
`;
  execFileSync('python3', ['-c', script, xlsxPath, XLSX_TMP_DIR, ...sheets], { stdio: 'inherit' });
  return Object.fromEntries(sheets.map((sheet) => [sheet, path.join(XLSX_TMP_DIR, `${sheet}.csv`)]));
}

function parseStore(record: Record<string, string>): StoreRow {
  const num = (value: string | undefined) => {
    const parsed = Number((value ?? '').replace(',', '.'));
    return Number.isFinite(parsed) ? parsed : null;
  };
  const lat = num(record['Latitude']);
  const lon = num(record['Longitude']);
  const note = num(record['Note']);
  return {
    name: record['Magasin'] ?? '',
    rubrics: record['Rubriques'] ?? '',
    address: record['Adresse'] ?? '',
    latitude: lat != null && lat !== 0 ? lat : null,
    longitude: lon != null && lon !== 0 ? lon : null,
    rating: note == null ? 0 : Number(Math.max(0, Math.min(5, note)).toFixed(2)),
    isOpen: (record['Ouvert'] ?? '').toLowerCase() === 'oui',
    available: (record['Disponible'] ?? '').toLowerCase() === 'oui',
    productCount: Number(record['Nb produits'] ?? 0) || 0,
  };
}

function parseProduct(record: Record<string, string>): ProductRow | null {
  const name = record['Produit']?.trim() ?? '';
  const price = Number((record['Prix (Fdj)'] ?? '').replace(',', '.'));
  const store = record['Magasin']?.trim() ?? '';
  if (store.length === 0 || name.length === 0 || !Number.isFinite(price)) return null;
  const image = record['Image']?.trim() ?? '';
  return {
    store,
    category: record['Catégorie']?.trim() || 'Menu',
    name,
    description: record['Description']?.trim() ?? '',
    price: Number(price.toFixed(2)),
    imageUrl: image.startsWith('http') ? image : null,
  };
}

function classifyCategory(name: string, rubrics: string): DedicatedFoodCategory {
  const byName = normalize(name);
  for (const category of DEDICATED_FOOD_CATEGORIES) {
    if (category.keywords.length === 0) continue;
    if (category.keywords.some((keyword) => byName.includes(keyword))) return category;
  }
  const normalizedRubrics = normalize(rubrics);
  for (const hint of RUBRIC_HINTS) {
    if (normalizedRubrics.includes(hint.match)) {
      return DEDICATED_FOOD_CATEGORIES.find((category) => category.id === hint.id)!;
    }
  }
  return DEDICATED_FOOD_CATEGORIES.find((category) => category.id === 'international_other')!;
}

function inferCuisine(name: string): string {
  const text = normalize(name);
  if (text.includes('pizza')) return 'Italian, Pizza';
  if (text.includes('burger') || text.includes('chicking')) return 'Fast Food, Burgers';
  if (text.includes('sushi')) return 'Japanese, Sushi';
  if (text.includes('taco')) return 'Mexican';
  if (text.includes('indien') || text.includes('indian')) return 'Indian';
  if (text.includes('naan')) return 'Indian, Fast Food';
  if (text.includes('cafe') || text.includes('coffee')) return 'Cafe, Beverages';
  if (text.includes('bakery') || text.includes('patisserie') || text.includes('cake')) return 'Bakery, Desserts';
  if (text.includes('bbq') || text.includes('barbecue')) return 'Grill, BBQ';
  if (text.includes('pasta')) return 'Italian';
  if (text.includes('wings')) return 'Fast Food, Wings';
  if (text.includes('mukbass') || text.includes('moukbasa') || text.includes('yemen')) return 'Yemeni, Middle Eastern';
  if (text.includes('hummus') || text.includes('libanais')) return 'Lebanese, Middle Eastern';
  if (text.includes('samba') || text.includes('senegalais')) return 'West African';
  return 'International';
}

function haversineKm(lat: number | null, lon: number | null): number | null {
  if (lat == null || lon == null) return null;
  const toRad = (value: number) => (value * Math.PI) / 180;
  const dLat = toRad(lat - DJIBOUTI_CENTER.lat);
  const dLon = toRad(lon - DJIBOUTI_CENTER.lon);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(DJIBOUTI_CENTER.lat)) * Math.cos(toRad(lat)) * Math.sin(dLon / 2) ** 2;
  return Number((2 * 6371 * Math.asin(Math.sqrt(a))).toFixed(2));
}

function deliveryFeeByDistance(distanceKm: number | null): number {
  if (distanceKm == null) return 2.5;
  if (distanceKm <= 3) return 1.0;
  if (distanceKm <= 6) return 1.8;
  if (distanceKm <= 12) return 2.5;
  return 3.2;
}

function isNonFoodStore(store: StoreRow): boolean {
  const name = normalize(store.name);
  if (NON_FOOD_PATTERNS.some((pattern) => pattern.test(name))) return true;
  // Stores whose only signals are non-food rubrics and no food keyword.
  const hasFoodKeyword = FOOD_KEYWORDS.some((keyword) => name.includes(keyword));
  if (hasFoodKeyword) return false;
  const rubrics = normalize(store.rubrics);
  const hasFoodRubric = /all food|fast food|café ptit dej|cafe ptit dej|asian|italian|west african|yemeni|lebanese|indian|tacos|pizza|burger/.test(rubrics);
  const hasNonFoodRubric = /pharmacies|beauty|clothing|tobacco|electronics|kikigaz|events/.test(rubrics);
  return hasNonFoodRubric && !hasFoodRubric;
}

// ── main ───────────────────────────────────────────────────────────────────

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!fs.existsSync(options.inputPath)) {
    throw new Error(`Input file not found: ${options.inputPath}`);
  }

  const csvPaths = workbookToCsv(options.inputPath, ['Magasins', 'Produits']);
  const stores = parseCsv(fs.readFileSync(csvPaths.Magasins, 'utf8')).map(parseStore).filter((store) => store.name.length > 0);
  const products = parseCsv(fs.readFileSync(csvPaths.Produits, 'utf8'))
    .map(parseProduct)
    .filter((row): row is ProductRow => row != null);

  const existing = (await prisma.restaurant.findMany({
    select: {
      id: true,
      name: true,
      imageUrl: true,
      cityZone: true,
      menuItems: { select: { id: true, name: true } },
    },
  })) as Array<ExistingRestaurant & { menuItems: Array<{ id: string; name: string }> }>;

  // Some names already exist twice (a seeded `r*` row and its kikidrop
  // counterpart, e.g. "La Chaumiere" / "LA CHAUMIERE"). When that happens,
  // always resolve to the kikidrop row so matching is deterministic.
  const existingByNorm = new Map<string, (typeof existing)[number]>();
  const duplicateNameGroups: Array<{ name: string; ids: string[] }> = [];
  for (const restaurant of existing) {
    const key = normalize(restaurant.name);
    const current = existingByNorm.get(key);
    if (current == null) {
      existingByNorm.set(key, restaurant);
      continue;
    }
    duplicateNameGroups.push({ name: restaurant.name, ids: [current.id, restaurant.id] });
    if (!current.id.startsWith(RESTAURANT_ID_PREFIX) && restaurant.id.startsWith(RESTAURANT_ID_PREFIX)) {
      existingByNorm.set(key, restaurant);
    }
  }

  const ambiguousNames = new Set(duplicateNameGroups.map((entry) => normalize(entry.name)));
  const skippedAmbiguous: Array<{ name: string; ids: string[]; products: number }> = [];
  const skippedNonFood: Array<{ name: string; products: number }> = [];
  const matched: Array<{ name: string; id: string; products: number; newItems: number; skippedExistingNames: number }> = [];
  const toCreate: Array<{ store: StoreRow; seed: NewRestaurantSeed; products: ProductRow[] }> = [];
  const newRestaurantSeeds: NewRestaurantSeed[] = [];
  const updatedExisting: Array<{ id: string; name: string; fields: string[] }> = [];

  // Group products by normalized store name.
  const productsByStore = new Map<string, ProductRow[]>();
  for (const product of products) {
    const key = normalize(product.store);
    const bucket = productsByStore.get(key) ?? [];
    bucket.push(product);
    productsByStore.set(key, bucket);
  }

  const usedIds = new Set(existing.map((restaurant) => restaurant.id));

  for (const store of stores) {
    const key = normalize(store.name);
    const storeProducts = productsByStore.get(key) ?? [];

    if (isNonFoodStore(store)) {
      skippedNonFood.push({ name: store.name, products: storeProducts.length });
      continue;
    }

    // Two DB rows share this name (seed + kikidrop import). Writing a menu to
    // either one would duplicate data in the app, so leave both untouched until
    // the duplicates are merged manually.
    if (ambiguousNames.has(key)) {
      skippedAmbiguous.push({
        name: store.name,
        ids: duplicateNameGroups.find((entry) => normalize(entry.name) === key)?.ids ?? [],
        products: storeProducts.length,
      });
      continue;
    }

    const current = existingByNorm.get(key);
    if (current) {
      const fields: string[] = [];
      const data: Record<string, unknown> = {};
      if (store.rating > 0) {
        data.rating = store.rating;
        fields.push('rating');
      }
      if (store.isOpen) {
        data.isOpen = true;
        fields.push('isOpen');
      }
      if (current.cityZone.length === 0) {
        data.cityZone = ['djibouti_ville'];
        fields.push('cityZone');
      }
      const firstImage = storeProducts.find((product) => product.imageUrl != null)?.imageUrl ?? null;
      if (current.imageUrl == null && firstImage != null) {
        data.imageUrl = firstImage;
        fields.push('imageUrl');
      }

      const curatedNames = new Set(
        current.menuItems
          .filter((item) => !item.id.startsWith(ITEM_ID_PREFIX))
          .map((item) => normalize(item.name)),
      );
      const newItems = storeProducts.filter((product) => !curatedNames.has(normalize(product.name))).length;
      matched.push({
        name: store.name,
        id: current.id,
        products: storeProducts.length,
        newItems,
        skippedExistingNames: storeProducts.length - newItems,
      });
      if (fields.length > 0) updatedExisting.push({ id: current.id, name: current.name, fields });
      if (Object.keys(data).length > 0) {
        // Stored on the seed object so the apply step can reuse it.
        (current as unknown as { updateData?: Record<string, unknown> }).updateData = data;
      }
      continue;
    }

    const distanceKm = haversineKm(store.latitude, store.longitude);
    const category = classifyCategory(store.name, store.rubrics);
    const firstImage = storeProducts.find((product) => product.imageUrl != null)?.imageUrl ?? null;
    let id = `${RESTAURANT_ID_PREFIX}${slugHash(`${store.name}::${normalize(store.address)}`)}`;
    while (usedIds.has(id)) id = `${RESTAURANT_ID_PREFIX}${slugHash(`${store.name}::${normalize(store.address)}::${Math.random()}`)}`;
    usedIds.add(id);

    const seed: NewRestaurantSeed = {
      id,
      name: store.name,
      cuisine: inferCuisine(store.name),
      rating: store.rating,
      isOpen: store.isOpen,
      deliveryTime: '30-40',
      deliveryFee: deliveryFeeByDistance(distanceKm),
      imageUrl: firstImage,
      distanceKm,
      tags: [category.label, store.address.split(',')[0]?.trim() || 'Djibouti', 'Local'],
    };
    newRestaurantSeeds.push(seed);
    toCreate.push({ store, seed, products: storeProducts });
  }

  // ── menu plan (only for restaurants we matched or created) ───────────────
  const restaurantIdByStore = new Map<string, string>();
  for (const entry of matched) restaurantIdByStore.set(normalize(entry.name), entry.id);
  for (const entry of toCreate) restaurantIdByStore.set(normalize(entry.seed.name), entry.seed.id);

  const categories: MenuCategorySeed[] = [];
  const items: MenuItemSeed[] = [];
  const seenItemIds = new Set<string>();
  const duplicateRows: Array<{ restaurant: string; name: string; rows: number }> = [];

  for (const [storeKey, restaurantId] of restaurantIdByStore) {
    const storeProducts = productsByStore.get(storeKey) ?? [];
    if (storeProducts.length === 0) continue;

    const current = existingByNorm.get(storeKey);
    const curatedNames = new Set(
      (current?.menuItems ?? [])
        .filter((item) => !item.id.startsWith(ITEM_ID_PREFIX))
        .map((item) => normalize(item.name)),
    );

    const categoryOrder: string[] = [];
    const categoryIdBySlug = new Map<string, string>();
    const rowCountByKey = new Map<string, number>();

    for (const product of storeProducts) {
      const categoryName = product.category || 'Menu';
      const categorySlug = slugify(categoryName) || 'menu';
      if (!categoryIdBySlug.has(categorySlug)) {
        const categoryId = `${restaurantId}-xlsx-${categorySlug}`;
        categoryIdBySlug.set(categorySlug, categoryId);
        categoryOrder.push(categorySlug);
        categories.push({
          id: categoryId,
          restaurantId,
          name: categoryName,
          sortOrder: categoryOrder.length,
        });
      }

      if (curatedNames.has(normalize(product.name))) continue;

      const dedupeKey = `${categorySlug}|${normalize(product.name)}|${product.price}`;
      const count = (rowCountByKey.get(dedupeKey) ?? 0) + 1;
      rowCountByKey.set(dedupeKey, count);
      if (count > 1) {
        const already = duplicateRows.find((entry) => entry.restaurant === restaurantId && entry.name === product.name);
        if (already) already.rows += 1;
        else duplicateRows.push({ restaurant: restaurantId, name: product.name, rows: 2 });
        continue;
      }

      const id = `${ITEM_ID_PREFIX}${itemHash(`${restaurantId}|${categorySlug}|${normalize(product.name)}|${product.price}`)}`;
      if (seenItemIds.has(id)) continue;
      seenItemIds.add(id);
      items.push({
        id,
        restaurantId,
        categoryId: categoryIdBySlug.get(categorySlug)!,
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      });
    }
  }

  // Restaurants in the file that already exist but got no menu rows (0 products).
  const emptyRestaurants = [...restaurantIdByStore.entries()]
    .filter(([storeKey]) => (productsByStore.get(storeKey) ?? []).length === 0)
    .map(([storeKey, id]) => ({ id, name: stores.find((store) => normalize(store.name) === storeKey)?.name ?? storeKey }));

  // Existing restaurants that no longer appear in the file (informational only).
  const fileNames = new Set(stores.map((store) => normalize(store.name)));
  const notInFile = existing
    .filter((restaurant) => !fileNames.has(normalize(restaurant.name)))
    .map((restaurant) => ({ id: restaurant.id, name: restaurant.name, menuItems: restaurant.menuItems.length }));

  const report = {
    generatedAt: new Date().toISOString(),
    sourcePath: options.inputPath,
    summary: {
      storesInFile: stores.length,
      productsInFile: products.length,
      existingRestaurantsMatched: matched.length,
      newFoodRestaurants: newRestaurantSeeds.length,
      nonFoodStoresSkipped: skippedNonFood.length,
      ambiguousDuplicateNamesSkipped: skippedAmbiguous.length,
      menuCategories: categories.length,
      menuItems: items.length,
      duplicateProductRowsCollapsed: duplicateRows.reduce((sum, entry) => sum + entry.rows - 1, 0),
      restaurantsWithEmptyMenu: emptyRestaurants.length,
      existingRestaurantsNotInFile: notInFile.length,
      preExistingDuplicateNames: duplicateNameGroups.length,
    },
    preExistingDuplicateNames: duplicateNameGroups,
    newRestaurants: newRestaurantSeeds,
    matchedRestaurants: matched,
    skippedNonFood,
    skippedAmbiguous,
    emptyRestaurants,
    existingNotInFile: notInFile,
    sampleDuplicateRows: duplicateRows.slice(0, 20),
  };

  fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
  fs.writeFileSync(REPORT_PATH, JSON.stringify(report, null, 2), 'utf8');

  console.log('Kikidrop produits propres — import plan');
  console.log(JSON.stringify(report.summary, null, 2));
  console.log('\nNew food restaurants:');
  for (const seed of newRestaurantSeeds) {
    const productCount = productsByStore.get(normalize(seed.name))?.length ?? 0;
    console.log(`  + ${seed.id}  ${seed.name}  (${productCount} products)`);
  }
  console.log('\nSkipped non-food stores:');
  for (const entry of skippedNonFood) console.log(`  - ${entry.name} (${entry.products} products)`);
  console.log(`\nReport written to ${REPORT_PATH}`);

  if (!options.apply) {
    console.log('\nDry run: database was not modified. Re-run with --apply to write.');
    return;
  }

  // ── apply ────────────────────────────────────────────────────────────────
  console.log('\nApplying to database…');

  for (const restaurant of existing as Array<ExistingRestaurant & { updateData?: Record<string, unknown> }>) {
    if (restaurant.updateData == null) continue;
    await prisma.restaurant.update({ where: { id: restaurant.id }, data: restaurant.updateData });
  }

  for (const seed of newRestaurantSeeds) {
    const data = {
      name: seed.name,
      cuisine: seed.cuisine,
      cityZone: ['djibouti_ville'],
      rating: seed.rating,
      reviewCount: 0,
      deliveryTime: seed.deliveryTime,
      deliveryFee: seed.deliveryFee,
      imageUrl: seed.imageUrl,
      isOpen: seed.isOpen,
      distanceKm: seed.distanceKm,
      tagsJson: seed.tags,
    };
    await prisma.restaurant.upsert({
      where: { id: seed.id },
      update: data,
      create: { id: seed.id, ...data },
    });
  }

  // Categories are deterministic, so existing ones are only refreshed when
  // their name/sort order actually changed; the rest are inserted in bulk.
  const existingCategories = new Map<string, { name: string; sortOrder: number }>();
  const categoryTargetIds = [...new Set(categories.map((category) => category.restaurantId))];
  for (let i = 0; i < categoryTargetIds.length; i += 50) {
    const rows = await prisma.restaurantMenuCategory.findMany({
      where: { restaurantId: { in: categoryTargetIds.slice(i, i + 50) } },
      select: { id: true, name: true, sortOrder: true },
    });
    for (const row of rows) existingCategories.set(row.id, row);
  }

  const newCategories = categories.filter((category) => !existingCategories.has(category.id));
  const changedCategories = categories.filter((category) => {
    const current = existingCategories.get(category.id);
    return current != null && (current.name !== category.name || current.sortOrder !== category.sortOrder);
  });

  for (let i = 0; i < newCategories.length; i += 500) {
    await prisma.restaurantMenuCategory.createMany({ data: newCategories.slice(i, i + 500), skipDuplicates: true });
  }
  for (const category of changedCategories) {
    await prisma.restaurantMenuCategory.update({
      where: { id: category.id },
      data: { name: category.name, sortOrder: category.sortOrder },
    });
  }

  // Insert only the items that do not exist yet; never touch curated ones.
  const targetIds = [...new Set(items.map((item) => item.restaurantId))];
  const existingItemIds = new Set<string>();
  for (let i = 0; i < targetIds.length; i += 50) {
    const chunk = targetIds.slice(i, i + 50);
    const rows = await prisma.restaurantMenuItem.findMany({
      where: { restaurantId: { in: chunk } },
      select: { id: true },
    });
    for (const row of rows) existingItemIds.add(row.id);
  }

  const missing = items.filter((item) => !existingItemIds.has(item.id));
  for (let i = 0; i < missing.length; i += 500) {
    await prisma.restaurantMenuItem.createMany({
      data: missing.slice(i, i + 500).map((item) => ({
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
      })),
      skipDuplicates: true,
    });
  }

  let prunedSamples = 0;
  if (options.pruneSamples) {
    for (const [restaurantId, sampleIds] of Object.entries(SEED_SAMPLE_ITEM_IDS)) {
      const importedCount = await prisma.restaurantMenuItem.count({
        where: { restaurantId, id: { startsWith: ITEM_ID_PREFIX } },
      });
      if (importedCount === 0) continue;
      const deleted = await prisma.restaurantMenuItem.deleteMany({
        where: { id: { in: sampleIds }, restaurantId },
      });
      prunedSamples += deleted.count;
    }
  }

  console.log(
    `Created/updated ${newRestaurantSeeds.length} restaurants, ` +
      `${newCategories.length} new + ${changedCategories.length} refreshed categories, ` +
      `${missing.length} menu items (${items.length - missing.length} already present).`,
  );
  console.log(
    prunedSamples > 0
      ? `Deleted ${prunedSamples} placeholder seed items (--prune-samples).`
      : 'No placeholder deletions (pass --prune-samples to remove the 3 seed samples on r2/r12).',
  );
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error('Kikidrop produits import failed:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
