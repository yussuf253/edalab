/**
 * Updates existing menu items' imageUrl from the food-matched CSV
 * (edalab_menus_import.csv with TheMealDB photo URLs).
 *
 * Matches items by (restaurantId, name) so only imageUrls change.
 * Items with an empty image_url in the CSV are left untouched.
 *
 * Run from backend/:
 *   npx tsx prisma/update-item-images.ts            (dry run)
 *   npx tsx prisma/update-item-images.ts --apply    (writes)
 */
import fs from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
dotenv.config();

const prisma = new PrismaClient();
const apply = process.argv.includes('--apply');
const inputPath =
  process.env.IMAGES_CSV?.trim() ??
  path.resolve(
    __dirname,
    '..',
    '..',
    process.argv.find((a) => a.startsWith('--csv='))?.slice(6) ??
      'edalab_menus_import.csv',
  );

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

const RESTAURANT_IDS: Record<string, string> = {
  Lados: 'r18',
  'Royal Coffee & Fast-Food': 'r21',
};

async function main() {
  const csv = fs.readFileSync(inputPath, 'utf8').replace(/^\uFEFF/, '');
  const lines = csv.split('\n').filter((l) => l.trim().length > 0);
  const header = parseCsvLine(lines[0]).map((h) => h.trim());
  const col = (name: string) => header.indexOf(name);

  const restaurantCol = col('restaurant');
  const nomCol = col('nom');
  const imageCol = col('image_url');

  let matched = 0;
  let skippedNoImage = 0;
  let notFound = 0;

  for (let i = 1; i < lines.length; i += 1) {
    const fields = parseCsvLine(lines[i]);
    const restaurant = (fields[restaurantCol] ?? '').trim();
    const nom = (fields[nomCol] ?? '').trim();
    const imageUrl = (fields[imageCol] ?? '').trim();

    if (!imageUrl || !imageUrl.startsWith('http')) { skippedNoImage += 1; continue; }

    const restaurantId = RESTAURANT_IDS[restaurant];
    if (!restaurantId) { console.warn(`Unknown restaurant "${restaurant}"`); notFound += 1; continue; }

    if (!apply) {
      console.log(`[dry-run] ${restaurant} / ${nom} -> ${imageUrl.slice(0, 80)}...`);
      matched += 1;
      continue;
    }

    const result = await prisma.restaurantMenuItem.updateMany({
      where: { restaurantId, name: nom },
      data: { imageUrl },
    });
    if (result.count === 0) { console.warn(`NOT FOUND: ${restaurantId} / "${nom}"`); notFound += 1; }
    else matched += result.count;
  }

  console.log(apply
    ? `Updated ${matched} items, ${skippedNoImage} skipped (no image in CSV), ${notFound} not found.`
    : `Dry run: ${matched} would be updated, ${skippedNoImage} skipped (no image), ${notFound} unknown. Re-run with --apply.`);
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => { console.error(e); await prisma.$disconnect(); process.exit(1); });
