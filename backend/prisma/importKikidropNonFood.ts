/**
 * Imports the non-food kikidrop stores (and their products) that the food
 * importer deliberately skipped, into the modules they belong to:
 *
 *   - 5 pharmacies            -> Pharmacy rows + Medicine rows (PHARMACY)
 *   - 31 other businesses     -> ShoppingStore rows + Product rows (SHOPPING)
 *
 * Products keep their source category: medicines/shopping products get a
 * ProductCategory under their own module, so store pages and category filters
 * stay usable.
 *
 * Safety:
 *  - Only the 36 stores listed in NON_FOOD_STORES are touched.
 *  - Stores that already exist in the target table are reused by normalized
 *    name (a few Google-Places shops are the same business); nothing is
 *    duplicated. The aliases are explicit below for review.
 *  - Deterministic ids (`kiki-shop-…`, `kiki-prod-…`, `kiki-pharm-…`,
 *    `kiki-med-…`) make the import idempotent.
 *  - No deletes, and an existing store's curated fields are never overwritten
 *    (only missing image/price/zone/rating are filled in).
 *
 * Run from backend/:
 *   npx tsx prisma/importKikidropNonFood.ts             (dry run)
 *   npx tsx prisma/importKikidropNonFood.ts --apply     (writes)
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
const REPORT_PATH = path.resolve(__dirname, 'generated/kikidrop_non_food_import_report.json');
const XLSX_TMP_DIR = path.resolve(__dirname, 'generated/xlsx');

/** The 36 non-food stores from the workbook (all food stores are excluded). */
const NON_FOOD_STORES = [
  'Al haramain Perfumes',
  'Baby Station',
  'BricoCoeur',
  'CAMELLIA POWDERS',
  'Cosmo',
  'Djib nature detox',
  'Eau & Boissons en volume',
  'Gaz & fuel',
  'Glow Orginal Cosmétique',
  'Hypermarché Al Gamil',
  'JOY-SVAMC',
  'Karim flowers',
  "Khaty's Shop",
  'Le Marché',
  "LET'S VAPE",
  'MBBS MAGASIN',
  'MR VAPOUR',
  'Nouga mobile',
  'NOUGAPRIX',
  'Outlet SVAMC',
  'PAIEMENT DE FACTURES ET PLANTON',
  'PHARMACIE AL HAYAT',
  'Pharmacie de la capitale',
  'PHARMACIE INTERNATIONAL',
  'PHARMACIE LA NATION',
  'PHARMACIE TAYBA',
  'RAHO KHAT',
  'Roi Des Epices',
  'RUCHES DE DOAAN POUR LE MIEL YÉMÉNITE ET LA PARFUMERIE',
  'SH Beauty Box',
  'Sheraton events',
  'Vape House',
  'WALLY SHOP',
  'Warso Khat',
  'Ximi V',
  'Zawam honey',
] as const;

/**
 * Existing ShoppingStore rows that are the same business as a kikidrop store
 * (Google Places import, older naming). Keyed by normalized kikidrop name.
 */
const SHOP_ALIASES: Record<string, string> = {
  'hypermarch al gamil': 'gps-shop-c9d7c0fbb233', // Hypermarché Al Gamil
  nougaprix: 'store-nougaprix', // Supermarche Nougaprix
  bricocoeur: 'gps-shop-69d121285a3d', // Bricocoeur- Vos Cadeaux personnalisés
  'karim flowers': 'gps-shop-bb73d0713a4f', // Kerim flower shop
};

const CITY_ZONE = 'djibouti_ville';

type StoreRow = {
  name: string;
  rubrics: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
  rating: number;
  isOpen: boolean;
  available: boolean;
};

type ProductRow = {
  store: string;
  category: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string | null;
};

type Options = { inputPath: string; apply: boolean };

function parseArgs(argv: string[]): Options {
  const options: Options = {
    inputPath: process.env.KIKIDROP_PRODUITS_INPUT?.trim() ?? path.resolve(__dirname, '..', '..', 'kikidrop_produits_propres.xlsx'),
    apply: false,
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--input' && argv[i + 1]) {
      options.inputPath = argv[i + 1];
      i += 1;
    } else if (arg === '--apply') options.apply = true;
    else if (arg === '--dry-run') options.apply = false;
    else if (arg === '--help' || arg === '-h') {
      console.log('Usage: tsx prisma/importKikidropNonFood.ts [--input <xlsx>] [--apply]');
      process.exit(0);
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

function hash(value: string, length = 12): string {
  return crypto.createHash('sha1').update(value).digest('hex').slice(0, length);
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
      } else inQuotes = !inQuotes;
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
    for (let j = 0; j < header.length; j += 1) row[header[j]] = (parsed[j] ?? '').trim();
    rows.push(row);
  }
  return rows;
}

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
  };
}

function parseProduct(record: Record<string, string>): ProductRow | null {
  const store = (record['Magasin'] ?? '').trim();
  const name = (record['Produit'] ?? '').trim();
  const price = Number((record['Prix (Fdj)'] ?? '').replace(',', '.'));
  if (store.length === 0 || name.length === 0 || !Number.isFinite(price)) return null;
  const image = (record['Image'] ?? '').trim();
  return {
    store,
    category: (record['Catégorie'] ?? '').trim(),
    name,
    description: (record['Description'] ?? '').trim(),
    price: Number(price.toFixed(2)),
    imageUrl: image.startsWith('http') ? image : null,
  };
}

function firstRubric(rubrics: string): string | null {
  const parts = rubrics
    .split(',')
    .map((part) => part.trim())
    .filter((part) => part.length > 0);
  return parts[0] ?? null;
}

function isPharmacy(store: StoreRow): boolean {
  return normalize(store.name).startsWith('pharmacie') || normalize(store.rubrics).includes('pharmacies');
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (!fs.existsSync(options.inputPath)) throw new Error(`Input file not found: ${options.inputPath}`);

  const csvPaths = workbookToCsv(options.inputPath, ['Magasins', 'Produits']);
  const allStores = parseCsv(fs.readFileSync(csvPaths.Magasins, 'utf8')).map(parseStore);
  const allProducts = parseCsv(fs.readFileSync(csvPaths.Produits, 'utf8'))
    .map(parseProduct)
    .filter((row): row is ProductRow => row != null);

  const allowed = new Set(NON_FOOD_STORES);
  const stores = allStores.filter((store) => allowed.has(store.name as (typeof NON_FOOD_STORES)[number]));
  const missingStores = NON_FOOD_STORES.filter((name) => !stores.some((store) => store.name === name));
  if (missingStores.length > 0) throw new Error(`Stores missing from the workbook: ${missingStores.join(', ')}`);

  const storeNames = new Set(stores.map((store) => store.name));
  const products = allProducts.filter((product) => storeNames.has(product.store));
  const productsByStore = new Map<string, ProductRow[]>();
  for (const product of products) {
    const key = normalize(product.store);
    const bucket = productsByStore.get(key) ?? [];
    bucket.push(product);
    productsByStore.set(key, bucket);
  }

  const existingShops = await prisma.shoppingStore.findMany({ select: { id: true, name: true, slug: true, imageUrl: true, cityZone: true, minPrice: true, maxPrice: true, rating: true } });
  const existingPharmacies = await prisma.pharmacy.findMany({ select: { id: true, name: true, imageUrl: true, cityZone: true } });
  const shopByNorm = new Map(existingShops.map((row) => [normalize(row.name), row]));
  const pharmacyByNorm = new Map(existingPharmacies.map((row) => [normalize(row.name), row]));

  const usedSlugs = new Set(existingShops.map((row) => row.slug));
  const usedIds = new Set([...existingShops.map((row) => row.id), ...existingPharmacies.map((row) => row.id)]);

  type ShopPlan = {
    store: StoreRow;
    id: string;
    slug: string;
    reuse: boolean;
    products: ProductRow[];
    updateData: Record<string, unknown>;
  };
  const shopPlans: ShopPlan[] = [];
  type PharmacyPlan = { store: StoreRow; id: string; slug: string; reuse: boolean; products: ProductRow[]; updateData: Record<string, unknown> };
  const pharmacyPlans: PharmacyPlan[] = [];

  for (const store of stores) {
    const key = normalize(store.name);
    const storeProducts = productsByStore.get(key) ?? [];
    const imageUrl = storeProducts.find((product) => product.imageUrl != null)?.imageUrl ?? null;
    const prices = storeProducts.map((product) => product.price);
    const minPrice = prices.length > 0 ? Math.min(...prices) : null;
    const maxPrice = prices.length > 0 ? Math.max(...prices) : null;

    if (isPharmacy(store)) {
      const existing = pharmacyByNorm.get(key);
      if (existing != null) {
        const data: Record<string, unknown> = {};
        if (existing.imageUrl == null && imageUrl != null) data.imageUrl = imageUrl;
        if (existing.cityZone.length === 0) data.cityZone = [CITY_ZONE];
        pharmacyPlans.push({ store, id: existing.id, slug: '', reuse: true, products: storeProducts, updateData: data });
        continue;
      }
      const id = `kiki-pharm-${hash(`${store.name}::${normalize(store.address)}`)}`;
      const baseSlug = slugify(store.name) || 'pharmacie';
      const slug = `${baseSlug}-${hash(store.name, 6)}`;
      if (usedIds.has(id) || usedSlugs.has(slug)) throw new Error(`Collision for pharmacy ${store.name}`);
      usedIds.add(id);
      usedSlugs.add(slug);
      pharmacyPlans.push({ store, id, slug, reuse: false, products: storeProducts, updateData: {} });
      continue;
    }

    const aliasId = SHOP_ALIASES[key];
    const existing = aliasId != null ? existingShops.find((row) => row.id === aliasId) ?? null : shopByNorm.get(key) ?? null;
    if (existing != null) {
      const data: Record<string, unknown> = {};
      if (existing.imageUrl == null && imageUrl != null) data.imageUrl = imageUrl;
      if (existing.minPrice == null && minPrice != null) data.minPrice = minPrice;
      if (existing.maxPrice == null && maxPrice != null) data.maxPrice = maxPrice;
      if (Number(existing.rating) === 0 && store.rating > 0) data.rating = store.rating;
      if (!existing.cityZone.includes(CITY_ZONE)) data.cityZone = [...existing.cityZone, CITY_ZONE];
      shopPlans.push({ store, id: existing.id, slug: existing.slug, reuse: true, products: storeProducts, updateData: data });
      continue;
    }

    const id = `kiki-shop-${hash(`${store.name}::${normalize(store.address)}`)}`;
    const baseSlug = slugify(store.name) || 'boutique';
    let slug = `${baseSlug}-${hash(store.name, 6)}`;
    let bump = 0;
    while (usedSlugs.has(slug) || usedIds.has(id)) {
      bump += 1;
      slug = `${baseSlug}-${hash(`${store.name}:${bump}`, 6)}`;
      if (bump > 5) throw new Error(`Cannot build a unique slug for ${store.name}`);
    }
    usedSlugs.add(slug);
    usedIds.add(id);
    shopPlans.push({ store, id, slug, reuse: false, products: storeProducts, updateData: {} });
  }

  // ── categories ───────────────────────────────────────────────────────────
  type CategoryPlan = { id: string; moduleType: 'SHOPPING' | 'PHARMACY'; name: string; slug: string; sortOrder: number };
  const categories: CategoryPlan[] = [];
  const categoryIds = new Map<string, string>(); // `${module}|${normalized name}` -> id
  const existingCategories = await prisma.productCategory.findMany({ select: { id: true, slug: true, name: true, moduleType: true } });
  const existingCategoryByKey = new Map<string, string>();
  for (const category of existingCategories) {
    existingCategoryByKey.set(`${category.moduleType}|${normalize(category.name)}`, category.id);
    categoryIds.set(`${category.moduleType}|${normalize(category.name)}`, category.id);
  }
  const usedCategorySlugs = new Set(existingCategories.map((category) => category.slug));

  for (const plan of [...shopPlans.map((p) => ({ moduleType: 'SHOPPING' as const, products: p.products })), ...pharmacyPlans.map((p) => ({ moduleType: 'PHARMACY' as const, products: p.products }))]) {
    for (const product of plan.products) {
      const name = product.category;
      if (name.length === 0) continue;
      const key = `${plan.moduleType}|${normalize(name)}`;
      if (categoryIds.has(key)) continue;
      const slugBase = `kikidrop-${plan.moduleType.toLowerCase()}-${slugify(name) || 'divers'}`;
      let slug = slugBase;
      let bump = 0;
      while (usedCategorySlugs.has(slug)) {
        bump += 1;
        slug = `${slugBase}-${bump}`;
      }
      usedCategorySlugs.add(slug);
      const id = slug;
      categoryIds.set(key, id);
      categories.push({ id, moduleType: plan.moduleType, name, slug, sortOrder: categories.length + 1 });
    }
  }

  const itemPlans: Array<{ kind: 'medicine' | 'product'; id: string; data: Record<string, unknown>; store: string; name: string }> = [];
  const seenItemIds = new Set<string>();

  for (const plan of pharmacyPlans) {
    for (const product of plan.products) {
      const id = `kiki-med-${hash(`${plan.id}|${normalize(product.category)}|${normalize(product.name)}|${product.price}`, 18)}`;
      if (seenItemIds.has(id)) continue;
      seenItemIds.add(id);
      itemPlans.push({
        kind: 'medicine',
        id,
        store: plan.store.name,
        name: product.name,
        data: {
          id,
          pharmacyId: plan.id,
          categoryId: product.category ? categoryIds.get(`PHARMACY|${normalize(product.category)}`) ?? null : null,
          name: product.name,
          description: product.description,
          price: product.price,
          rating: 0,
          reviewCount: 0,
          imageUrlsJson: product.imageUrl ? [product.imageUrl] : [],
          tagsJson: [product.category, firstRubric(plan.store.rubrics) ?? 'Djibouti'].filter(Boolean),
          requiresPrescription: false,
          inStock: true,
          metadata: { source: 'kikidrop', sourceCategory: product.category || null },
        },
      });
    }
  }

  for (const plan of shopPlans) {
    for (const product of plan.products) {
      const id = `kiki-prod-${hash(`${plan.id}|${normalize(product.category)}|${normalize(product.name)}|${product.price}`, 18)}`;
      if (seenItemIds.has(id)) continue;
      seenItemIds.add(id);
      itemPlans.push({
        kind: 'product',
        id,
        store: plan.store.name,
        name: product.name,
        data: {
          id,
          moduleType: 'SHOPPING',
          categoryId: product.category ? categoryIds.get(`SHOPPING|${normalize(product.category)}`) ?? null : null,
          name: product.name,
          cityZone: [CITY_ZONE],
          description: product.description,
          price: product.price,
          rating: 0,
          reviewCount: 0,
          imageUrlsJson: product.imageUrl ? [product.imageUrl] : [],
          tagsJson: [product.category].filter(Boolean),
          inStock: true,
          isOrganic: false,
          shopId: plan.id,
          metadata: { source: 'kikidrop', sourceCategory: product.category || null },
        },
      });
    }
  }

  const summary = {
    storesInFile: stores.length,
    pharmacies: pharmacyPlans.length,
    shoppingStores: shopPlans.length,
    reusedExistingStores: [...pharmacyPlans, ...shopPlans].filter((plan) => plan.reuse).length,
    newCategories: categories.length,
    products: products.length,
    uniqueMenuRows: itemPlans.length,
    storesWithoutProducts: [...shopPlans].filter((plan) => plan.products.length === 0).map((plan) => plan.store.name),
  };

  console.log('Kikidrop non-food import plan');
  console.log(JSON.stringify(summary, null, 2));
  console.log('\nPharmacies:');
  for (const plan of pharmacyPlans) console.log(`  ${plan.reuse ? 'reuse' : 'create'} ${plan.id} ${plan.store.name} (${plan.products.length} medicines)`);
  console.log('\nShopping stores:');
  for (const plan of shopPlans) {
    console.log(`  ${plan.reuse ? 'reuse' : 'create'} ${plan.id} ${plan.store.name} (${plan.products.length} products)`);
  }

  fs.mkdirSync(path.dirname(REPORT_PATH), { recursive: true });
  if (!options.apply) {
    fs.writeFileSync(REPORT_PATH, JSON.stringify({ generatedAt: new Date().toISOString(), applied: false, summary, categories }, null, 2), 'utf8');
    console.log(`\nDry run: database was not modified. Report: ${REPORT_PATH}`);
    console.log('Re-run with --apply to write.');
    return;
  }

  // ── apply ────────────────────────────────────────────────────────────────
  for (const pharmacy of pharmacyPlans) {
    if (pharmacy.reuse) {
      if (Object.keys(pharmacy.updateData).length > 0) {
        await prisma.pharmacy.update({ where: { id: pharmacy.id }, data: pharmacy.updateData });
      }
      continue;
    }
    await prisma.pharmacy.upsert({
      where: { id: pharmacy.id },
      update: {},
      create: {
        id: pharmacy.id,
        name: pharmacy.store.name,
        slug: pharmacy.slug,
        cityZone: [CITY_ZONE],
        description: firstRubric(pharmacy.store.rubrics),
        imageUrl: pharmacy.products.find((product) => product.imageUrl != null)?.imageUrl ?? null,
        address: pharmacy.store.address || null,
        latitude: pharmacy.store.latitude,
        longitude: pharmacy.store.longitude,
        rating: pharmacy.store.rating,
        reviewCount: 0,
        isOpen: pharmacy.store.isOpen,
        active: true,
        metadata: { source: 'kikidrop', rubrics: pharmacy.store.rubrics, available: pharmacy.store.available },
      },
    });
  }

  for (const shop of shopPlans) {
    if (shop.reuse) {
      if (Object.keys(shop.updateData).length > 0) {
        await prisma.shoppingStore.update({ where: { id: shop.id }, data: shop.updateData });
      }
      continue;
    }
    const prices = shop.products.map((product) => product.price);
    await prisma.shoppingStore.upsert({
      where: { id: shop.id },
      update: {},
      create: {
        id: shop.id,
        name: shop.store.name,
        slug: shop.slug,
        cityZone: [CITY_ZONE],
        tagline: firstRubric(shop.store.rubrics),
        description: null,
        imageUrl: shop.products.find((product) => product.imageUrl != null)?.imageUrl ?? null,
        rating: shop.store.rating,
        reviewCount: 0,
        badge: null,
        minPrice: prices.length > 0 ? Math.min(...prices) : null,
        maxPrice: prices.length > 0 ? Math.max(...prices) : null,
        highlightsJson: [firstRubric(shop.store.rubrics) ?? 'Boutique', 'Djibouti'],
        isOpen: shop.store.isOpen,
      },
    });
  }

  if (categories.length > 0) {
    await prisma.productCategory.createMany({ data: categories, skipDuplicates: true });
  }

  const existingProductIds = new Set<string>();
  const existingMedicineIds = new Set<string>();
  const productIds = itemPlans.filter((item) => item.kind === 'product').map((item) => item.id);
  const medicineIds = itemPlans.filter((item) => item.kind === 'medicine').map((item) => item.id);
  for (let i = 0; i < productIds.length; i += 500) {
    const rows = await prisma.product.findMany({ where: { id: { in: productIds.slice(i, i + 500) } }, select: { id: true } });
    for (const row of rows) existingProductIds.add(row.id);
  }
  for (let i = 0; i < medicineIds.length; i += 500) {
    const rows = await prisma.medicine.findMany({ where: { id: { in: medicineIds.slice(i, i + 500) } }, select: { id: true } });
    for (const row of rows) existingMedicineIds.add(row.id);
  }

  const newProducts = itemPlans.filter((item) => item.kind === 'product' && !existingProductIds.has(item.id)).map((item) => item.data);
  const newMedicines = itemPlans.filter((item) => item.kind === 'medicine' && !existingMedicineIds.has(item.id)).map((item) => item.data);

  for (let i = 0; i < newProducts.length; i += 500) {
    await prisma.product.createMany({ data: newProducts.slice(i, i + 500) as never, skipDuplicates: true });
  }
  for (let i = 0; i < newMedicines.length; i += 500) {
    await prisma.medicine.createMany({ data: newMedicines.slice(i, i + 500) as never, skipDuplicates: true });
  }

  fs.writeFileSync(
    REPORT_PATH,
    JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        applied: true,
        summary,
        created: { pharmacies: pharmacyPlans.filter((p) => !p.reuse).length, shoppingStores: shopPlans.filter((p) => !p.reuse).length, categories: categories.length, products: newProducts.length, medicines: newMedicines.length },
      },
      null,
      2,
    ),
    'utf8',
  );

  console.log(`\nCreated ${newProducts.length} products and ${newMedicines.length} medicines (${itemPlans.length - newProducts.length - newMedicines.length} already present).`);
  console.log(`Report: ${REPORT_PATH}`);
}

main()
  .then(async () => prisma.$disconnect())
  .catch(async (error) => {
    console.error('Kikidrop non-food import failed:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
