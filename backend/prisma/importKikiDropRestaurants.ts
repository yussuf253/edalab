import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
dotenv.config();

type ImportOptions = {
  inputPath: string;
  outputPath: string;
  apply: boolean;
  prune: boolean;
};

type KikiRow = {
  order: string;
  startUrl: string;
  name: string;
  area: string;
  eta: string;
  distanceText: string;
  hoursText: string;
  ratingText: string;
  sponsoredText: string;
  imageUrl: string;
};

type RestaurantSeed = {
  id: string;
  sourceKey: string;
  name: string;
  categoryId: string;
  categoryLabel: string;
  cuisine: string;
  rating: number;
  reviewCount: number;
  deliveryTime: string;
  deliveryFee: number;
  imageUrl: string | null;
  isOpen: boolean;
  distanceKm: number | null;
  tagsJson: string[];
};

const prisma = new PrismaClient();
const RESTAURANT_ID_PREFIX = 'kiki-rest-';
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
] as const;

const NON_FOOD_KEYWORDS = [
  'pharm',
  'magasin',
  'vapour',
  'khat',
  'powder',
  'miel',
  'parfum',
  'perfume',
  'tobacco',
  'beauty',
  'flower',
  'flowers',
  'electronics',
  'mobile',
  'quincaillerie',
  'hardware',
  'parts',
  'tyre',
  'garage',
  'brico',
  'camellia',
] as const;

type DedicatedFoodCategory = {
  id: string;
  label: string;
  keywords: string[];
};

const DEDICATED_FOOD_CATEGORIES: DedicatedFoodCategory[] = [
  {
    id: 'burgers_fastfood',
    label: 'Burgers & Fast Food',
    keywords: ['burger', 'chicking', 'chicken', 'fast food', 'smash'],
  },
  {
    id: 'pizza_italian',
    label: 'Pizza & Italian',
    keywords: ['pizza', 'pasta', 'pizzaiolo', 'albertos', 'amore'],
  },
  {
    id: 'tacos_mexican',
    label: 'Tacos & Mexican',
    keywords: ['taco', 'mexic'],
  },
  {
    id: 'coffee_cafe',
    label: 'Coffee & Cafe',
    keywords: ['coffee', 'cafe', 'cafet', 'lavazza'],
  },
  {
    id: 'bakery_desserts',
    label: 'Bakery & Desserts',
    keywords: ['bakery', 'cake', 'patis', 'moulin', 'dessert', 'sweet'],
  },
  {
    id: 'sushi_asian',
    label: 'Sushi & Asian',
    keywords: ['sushi', 'bento', 'wok', 'asian', 'ramen', 'noodle'],
  },
  {
    id: 'bbq_grill_kebab',
    label: 'BBQ, Grill & Kebab',
    keywords: ['bbq', 'barbecue', 'grill', 'kebab', 'shawarma'],
  },
  {
    id: 'middle_eastern',
    label: 'Middle Eastern',
    keywords: ['hummus', 'libanais', 'arab', 'yemen', 'levant'],
  },
  {
    id: 'healthy_salad',
    label: 'Healthy & Salad',
    keywords: ['healthy', 'salad', 'vegan', 'vegetarian'],
  },
  {
    id: 'icecream_frozen',
    label: 'Ice Cream & Frozen Treats',
    keywords: ['cold stone', 'ice cream', 'gelato', 'frozen yogurt'],
  },
  {
    id: 'indian',
    label: 'Indian',
    keywords: ['indien', 'indian'],
  },
  {
    id: 'general_restaurants',
    label: 'General Restaurants',
    keywords: ['restaurant', 'house', 'kitchen', 'diner'],
  },
  {
    id: 'international_other',
    label: 'International & Other',
    keywords: [],
  },
];

function printHelpAndExit() {
  console.log(`
Usage:
  tsx prisma/importKikiDropRestaurants.ts --input <csv-path> [options]

Options:
  --output <path>   Extraction JSON output path
  --apply           Apply upserts to database
  --prune           Delete stale previous kiki-rest-* restaurants
  --dry-run         Extraction only (default)
  --help            Show help
`);
  process.exit(0);
}

function parseArgs(argv: string[]): ImportOptions {
  const options: ImportOptions = {
    inputPath: process.env.KIKIDROP_INPUT?.trim() ?? '',
    outputPath: process.env.KIKIDROP_OUTPUT?.trim() ?? '',
    apply: false,
    prune: false,
  };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--input' && argv[i + 1]) {
      options.inputPath = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === '--output' && argv[i + 1]) {
      options.outputPath = argv[i + 1];
      i += 1;
      continue;
    }
    if (arg === '--apply') {
      options.apply = true;
      continue;
    }
    if (arg === '--prune') {
      options.prune = true;
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

  if (options.inputPath.length === 0) {
    throw new Error(
      'Missing --input. Example: tsx prisma/importKikiDropRestaurants.ts --input assets/kikidrop-com-2026-04-13.csv',
    );
  }

  if (options.outputPath.length === 0) {
    options.outputPath = path.resolve(
      __dirname,
      'generated/kikidrop_restaurants_extracted.json',
    );
  } else {
    options.outputPath = path.resolve(options.outputPath);
  }

  options.inputPath = path.resolve(options.inputPath);
  return options;
}

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

function parseCsv(csvText: string): Array<Record<string, string>> {
  const lines = csvText
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n')
    .split('\n')
    .filter((line) => line.trim().length > 0);
  if (lines.length === 0) return [];

  const header = parseCsvLine(lines[0]).map((entry) =>
    entry.replace(/^\uFEFF/, '').trim(),
  );

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

function normalize(value: string): string {
  return value.trim().toLowerCase();
}

function slugHash(value: string): string {
  return crypto.createHash('sha1').update(value).digest('hex').slice(0, 12);
}

function stableRestaurantId(sourceKey: string): string {
  return `${RESTAURANT_ID_PREFIX}${slugHash(sourceKey)}`;
}

function parseRating(text: string): number {
  const parsed = Number(text);
  if (!Number.isFinite(parsed)) return 0;
  return Number(Math.max(0, Math.min(5, parsed)).toFixed(2));
}

function parseDistanceKm(text: string): number | null {
  const match = text.match(/(\d+(?:\.\d+)?)/);
  if (!match) return null;
  const parsed = Number(match[1]);
  if (!Number.isFinite(parsed)) return null;
  return Number(parsed.toFixed(2));
}

function inferCuisine(name: string): string {
  const text = normalize(name);
  if (text.includes('pizza')) return 'Italian, Pizza';
  if (text.includes('burger') || text.includes('chicking')) {
    return 'Fast Food, Burgers';
  }
  if (text.includes('sushi')) return 'Japanese, Sushi';
  if (text.includes('taco')) return 'Mexican';
  if (text.includes('indien') || text.includes('indian')) return 'Indian';
  if (text.includes('cafe') || text.includes('coffee')) return 'Cafe, Beverages';
  if (text.includes('bakery') || text.includes('patisserie') || text.includes('cake')) {
    return 'Bakery, Desserts';
  }
  if (text.includes('bbq') || text.includes('barbecue')) return 'Grill, BBQ';
  if (text.includes('pasta')) return 'Italian';
  return 'International';
}

function classifyDedicatedCategory(name: string): DedicatedFoodCategory {
  const normalized = normalize(name);
  for (const category of DEDICATED_FOOD_CATEGORIES) {
    if (category.keywords.length === 0) continue;
    if (category.keywords.some((keyword) => normalized.includes(keyword))) {
      return category;
    }
  }
  return (
    DEDICATED_FOOD_CATEGORIES.find(
      (category) => category.id === 'international_other',
    ) ?? DEDICATED_FOOD_CATEGORIES[DEDICATED_FOOD_CATEGORIES.length - 1]
  );
}

function isLikelyRestaurant(row: KikiRow): boolean {
  const name = normalize(row.name);
  const eta = normalize(row.eta);
  const hasFoodKeyword = FOOD_KEYWORDS.some((keyword) => name.includes(keyword));
  const hasNonFoodKeyword = NON_FOOD_KEYWORDS.some((keyword) => name.includes(keyword));
  const looksLongLeadDelivery = eta.includes('day');

  if (hasFoodKeyword) return true;
  if (hasNonFoodKeyword || looksLongLeadDelivery) return false;
  return true;
}

function normalizeEta(etaText: string): string {
  const cleaned = etaText.trim().replace(/\s+/g, ' ');
  if (cleaned.length === 0) return '30-40';
  if (cleaned.toLowerCase() === '1 day') return '60+';
  const minutesMatch = cleaned.match(/(\d+)\s*mins?/i);
  if (minutesMatch) {
    const minutes = Number(minutesMatch[1]);
    if (Number.isFinite(minutes) && minutes > 0) {
      const from = Math.max(10, Math.round(minutes - 5));
      const to = Math.round(minutes + 5);
      return `${from}-${to}`;
    }
  }
  const hourAndMinutes = cleaned.match(/(\d+)\s*hr,\s*(\d+)\s*mins?/i);
  if (hourAndMinutes) {
    const hours = Number(hourAndMinutes[1]);
    const minutes = Number(hourAndMinutes[2]);
    const total = hours * 60 + minutes;
    return `${Math.max(30, total - 10)}-${total + 10}`;
  }
  const hourOnly = cleaned.match(/(\d+)\s*hr/i);
  if (hourOnly) {
    const total = Number(hourOnly[1]) * 60;
    return `${Math.max(30, total - 10)}-${total + 10}`;
  }
  return '30-40';
}

function deliveryFeeByDistance(distanceKm: number | null): number {
  if (distanceKm == null) return 2.5;
  if (distanceKm <= 3) return 1.0;
  if (distanceKm <= 6) return 1.8;
  if (distanceKm <= 12) return 2.5;
  return 3.2;
}

function isOpenFromHours(hours: string): boolean {
  const text = normalize(hours);
  if (text.length === 0) return true;
  if (text.includes('closed')) return false;
  return true;
}

function mapRowsToSeeds(rows: KikiRow[]) {
  const seeds: RestaurantSeed[] = [];
  const skipped: Record<string, number> = {};
  const seen = new Set<string>();

  for (const row of rows) {
    const name = row.name.trim();
    if (name.length < 2) {
      skipped.missing_name = (skipped.missing_name ?? 0) + 1;
      continue;
    }

    if (!isLikelyRestaurant(row)) {
      skipped.non_food_listing = (skipped.non_food_listing ?? 0) + 1;
      continue;
    }

    const sourceKey = `${name}::${row.area.trim().toLowerCase()}`;
    if (seen.has(sourceKey)) {
      skipped.duplicate = (skipped.duplicate ?? 0) + 1;
      continue;
    }
    seen.add(sourceKey);

    const distanceKm = parseDistanceKm(row.distanceText);
    const area = row.area.trim();
    const category = classifyDedicatedCategory(name);
    const tags = [
      category.label,
      area.length > 0 && area !== '-' ? area : 'Djibouti',
      row.sponsoredText.trim().length > 0 ? 'Sponsored' : 'Local',
    ];

    seeds.push({
      id: stableRestaurantId(sourceKey),
      sourceKey,
      name,
      categoryId: category.id,
      categoryLabel: category.label,
      cuisine: inferCuisine(name),
      rating: parseRating(row.ratingText),
      reviewCount: 0,
      deliveryTime: normalizeEta(row.eta),
      deliveryFee: deliveryFeeByDistance(distanceKm),
      imageUrl: row.imageUrl.trim().length > 0 ? row.imageUrl.trim() : null,
      isOpen: isOpenFromHours(row.hoursText),
      distanceKm,
      tagsJson: tags,
    });
  }

  return { seeds, skipped };
}

function buildCategoryCounts(seeds: RestaurantSeed[]) {
  const counts = new Map<string, number>();
  for (const seed of seeds) {
    counts.set(seed.categoryId, (counts.get(seed.categoryId) ?? 0) + 1);
  }
  return DEDICATED_FOOD_CATEGORIES.map((category) => ({
    id: category.id,
    label: category.label,
    count: counts.get(category.id) ?? 0,
  })).filter((entry) => entry.count > 0);
}

async function applySeeds(
  seeds: RestaurantSeed[],
  prune: boolean,
) {
  for (const seed of seeds) {
    await prisma.restaurant.upsert({
      where: { id: seed.id },
      update: {
        name: seed.name,
        cuisine: seed.cuisine,
        rating: seed.rating,
        reviewCount: seed.reviewCount,
        deliveryTime: seed.deliveryTime,
        deliveryFee: seed.deliveryFee,
        imageUrl: seed.imageUrl,
        isOpen: seed.isOpen,
        distanceKm: seed.distanceKm,
        tagsJson: seed.tagsJson,
      },
      create: {
        id: seed.id,
        name: seed.name,
        cuisine: seed.cuisine,
        rating: seed.rating,
        reviewCount: seed.reviewCount,
        deliveryTime: seed.deliveryTime,
        deliveryFee: seed.deliveryFee,
        imageUrl: seed.imageUrl,
        isOpen: seed.isOpen,
        distanceKm: seed.distanceKm,
        tagsJson: seed.tagsJson,
      },
    });
  }

  if (!prune) return;

  const currentIds = seeds.map((seed) => seed.id);
  await prisma.restaurant.deleteMany({
    where:
      currentIds.length > 0
        ? {
            id: { startsWith: RESTAURANT_ID_PREFIX },
            NOT: { id: { in: currentIds } },
          }
        : { id: { startsWith: RESTAURANT_ID_PREFIX } },
  });
}

function toKikiRows(rows: Array<Record<string, string>>): KikiRow[] {
  return rows.map((row) => ({
    order: row.web_scraper_order ?? '',
    startUrl: row.web_scraper_start_url ?? '',
    name: row.data ?? '',
    area: row.data2 ?? '',
    eta: row.data3 ?? '',
    distanceText: row.data4 ?? '',
    hoursText: row.data5 ?? '',
    ratingText: row.data6 ?? '',
    sponsoredText: row.data8 ?? '',
    imageUrl: row.image ?? '',
  }));
}

function ensureOutputDir(outputPath: string) {
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const rawCsv = fs.readFileSync(options.inputPath, 'utf8');
  const parsedRows = parseCsv(rawCsv);
  const mappedRows = toKikiRows(parsedRows);
  const { seeds, skipped } = mapRowsToSeeds(mappedRows);
  const categoryCounts = buildCategoryCounts(seeds);

  const report = {
    generatedAt: new Date().toISOString(),
    sourcePath: options.inputPath,
    summary: {
      csvRows: mappedRows.length,
      extractedRestaurants: seeds.length,
      skipped,
      categoryCounts,
    },
    categories: categoryCounts,
    restaurants: seeds,
  };

  ensureOutputDir(options.outputPath);
  fs.writeFileSync(options.outputPath, JSON.stringify(report, null, 2), 'utf8');

  console.log('Kikidrop extraction completed.');
  console.log(`Input file: ${options.inputPath}`);
  console.log(`Output file: ${options.outputPath}`);
  console.log('Summary:', JSON.stringify(report.summary, null, 2));

  if (!options.apply) {
    console.log('Dry run mode: database was not modified.');
    return;
  }

  await applySeeds(seeds, options.prune);
  console.log(
    options.prune
      ? 'Kikidrop restaurant import completed with pruning.'
      : 'Kikidrop restaurant import completed.',
  );
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error('Kikidrop import failed:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
