import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import dotenv from 'dotenv';
import { ModuleType, Prisma, PrismaClient } from '@prisma/client';

dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
dotenv.config();

type CatalogModule = 'SHOPPING' | 'FOOD' | 'DOCTOR' | 'HOTEL' | 'PHARMACY' | 'OTHER';

type RawGooglePlace = {
  title?: string | null;
  categoryName?: string | null;
  categories?: string[] | null;
  address?: string | null;
  city?: string | null;
  countryCode?: string | null;
  phone?: string | null;
  phoneUnformatted?: string | null;
  location?: { lat?: number | null; lng?: number | null } | null;
  totalScore?: number | null;
  reviewsCount?: number | null;
  imageUrl?: string | null;
  imageUrls?: string[] | null;
  website?: string | null;
  openingHours?: Array<{ day?: string | null; hours?: string | null }> | null;
  permanentlyClosed?: boolean | null;
  temporarilyClosed?: boolean | null;
  placeId?: string | null;
  cid?: string | null;
  fid?: string | null;
  price?: string | number | null;
};

type ImportOptions = {
  inputPath: string;
  outputPath: string;
  apply: boolean;
  prune: boolean;
  includeTemporarilyClosed: boolean;
  strictQuality: boolean;
};

type ShoppingStoreSeed = {
  id: string;
  placeId: string;
  name: string;
  slug: string;
  tagline: string;
  description: string;
  imageUrl: string | null;
  isOpen: boolean;
  rating: number;
  reviewCount: number;
  badge: string | null;
  minPrice: number | null;
  maxPrice: number | null;
  highlightsJson: string[];
  categoryTokens: string[];
};

type ProductSeed = {
  id: string;
  moduleType: ModuleType;
  categoryId: string;
  shopId: string | null;
  name: string;
  brand: string | null;
  description: string;
  price: number;
  originalPrice: number | null;
  rating: number;
  reviewCount: number;
  dosage: string | null;
  packageSize: string | null;
  requiresPrescription: boolean;
  imageUrlsJson: string[];
  colorsJson: string[];
  sizesJson: string[];
  tagsJson: string[];
  featuresJson: string[];
  badge: string | null;
  inStock: boolean;
  isOrganic: boolean;
  metadata: Prisma.InputJsonValue;
};

type DoctorSeed = {
  id: string;
  placeId: string;
  name: string;
  specialty: string;
  providerType: string;
  rating: number;
  reviewCount: number;
  experience: string;
  consultationFee: number;
  isAvailable: boolean;
  isSignedUp: boolean;
  imageUrl: string | null;
  about: string;
  location: string;
  contactPhone: string | null;
  contactWhatsApp: string | null;
  languagesJson: string[];
  servicesJson: string[];
  careModesJson: string[];
  workingHoursJson: Record<string, string>;
};

type RestaurantSeed = {
  id: string;
  placeId: string;
  name: string;
  cuisine: string;
  rating: number;
  reviewCount: number;
  deliveryTime: string;
  deliveryFee: number;
  imageUrl: string | null;
  isOpen: boolean;
  distanceKm: number | null;
  tagsJson: string[];
  menuCategory: {
    id: string;
    name: string;
    sortOrder: number;
  };
  menuItem: {
    id: string;
    name: string;
    description: string;
    price: number;
    imageUrl: string | null;
    isPopular: boolean;
    isAvailable: boolean;
    customizationsJson: string[];
  };
};

type HotelSeed = {
  id: string;
  placeId: string;
  name: string;
  address: string;
  city: string;
  rating: number;
  reviewsCount: number;
  pricePerNight: number;
  amenitiesJson: string[];
  description: string;
  imageUrlsJson: string[];
};

type ExtractionResult = {
  summary: {
    inputCount: number;
    candidateCount: number;
    strictQuality: boolean;
    skippedReasons: Record<string, number>;
    mappedCounts: Record<CatalogModule, number>;
    extractedCounts: {
      shoppingStores: number;
      shoppingProducts: number;
      doctors: number;
      restaurants: number;
      hotels: number;
      pharmacyProducts: number;
    };
  };
  shoppingStores: ShoppingStoreSeed[];
  shoppingProducts: ProductSeed[];
  doctors: DoctorSeed[];
  restaurants: RestaurantSeed[];
  hotels: HotelSeed[];
  pharmacyProducts: ProductSeed[];
};

const prisma = new PrismaClient();

const PREFIXES = {
  shoppingStore: 'gps-shop-',
  shoppingProduct: 'gps-shop-product-',
  doctor: 'gps-doctor-',
  restaurant: 'gps-restaurant-',
  restaurantMenuCategory: 'gps-menu-category-',
  restaurantMenuItem: 'gps-menu-item-',
  hotel: 'gps-hotel-',
  pharmacyProduct: 'gps-pharmacy-product-',
} as const;

const DJIBOUTI_BOUNDS = {
  minLat: 10.7,
  maxLat: 12.9,
  minLng: 41.7,
  maxLng: 43.7,
};

const PHARMACY_CATEGORY_IDS = [
  'pharmacy-pain-relief',
  'pharmacy-antibiotics',
  'pharmacy-vitamins',
  'pharmacy-cold-flu',
] as const;

const SHOPPING_CATEGORY_IDS = [
  'shopping-shoes',
  'shopping-electronics',
  'shopping-clothing',
  'shopping-home',
  'shopping-accessories',
] as const;

const GENERIC_FOOD_CATEGORIES = new Set([
  'restaurant',
  'fast food restaurant',
  'coffee shop',
  'cafe',
  'family restaurant',
  'hamburger restaurant',
  'pizza restaurant',
  'sandwich shop',
  'bakery',
  'patisserie',
  'pastry shop',
  'ice cream shop',
  'caterer',
  'buffet restaurant',
  'brunch restaurant',
  'western restaurant',
  'arab restaurant',
  'food court',
]);

function parseArgs(argv: string[]): ImportOptions {
  const options: ImportOptions = {
    inputPath: process.env.GOOGLE_PLACES_INPUT?.trim() ?? '',
    outputPath: process.env.GOOGLE_PLACES_OUTPUT?.trim() ?? '',
    apply: false,
    prune: false,
    includeTemporarilyClosed: false,
    strictQuality: true,
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
    if (arg === '--include-temporarily-closed') {
      options.includeTemporarilyClosed = true;
      continue;
    }
    if (arg === '--loose-quality') {
      options.strictQuality = false;
      continue;
    }
    if (arg === '--help' || arg === '-h') {
      printHelpAndExit();
    }
  }

  if (options.inputPath.length === 0) {
    throw new Error(
      'Missing --input. Example: tsx prisma/importGooglePlaces.ts --input /path/to/dataset.json',
    );
  }

  if (options.outputPath.length === 0) {
    options.outputPath = path.resolve(
      __dirname,
      'generated/google_places_extracted.json',
    );
  } else {
    options.outputPath = path.resolve(options.outputPath);
  }

  options.inputPath = path.resolve(options.inputPath);
  return options;
}

function printHelpAndExit() {
  console.log(`
Usage:
  tsx prisma/importGooglePlaces.ts --input <dataset.json> [options]

Options:
  --output <path>                    Extraction JSON output path
  --apply                            Apply upserts to database
  --prune                            Remove stale previously imported rows (gps-* ids)
  --include-temporarily-closed       Keep temporarily closed places
  --loose-quality                    Keep lower-signal entries
  --dry-run                          Do extraction only (default)
  --help                             Show help

Environment variables:
  GOOGLE_PLACES_INPUT                Default input path
  GOOGLE_PLACES_OUTPUT               Default extraction output path
`);
  process.exit(0);
}

function normalize(value: unknown): string {
  return value?.toString().trim().toLowerCase() ?? '';
}

function toTitleCase(value: string): string {
  return value
    .split(/\s+/)
    .filter((token) => token.length > 0)
    .map((token) => token[0].toUpperCase() + token.slice(1).toLowerCase())
    .join(' ');
}

function slugify(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function safeName(value: string): boolean {
  const normalized = value.trim().toLowerCase();
  if (normalized.length < 3) return false;
  return !new Set(['edit', 'test', 'unknown']).has(normalized);
}

function collectCategoryTokens(place: RawGooglePlace): string[] {
  const raw = [place.categoryName, ...(place.categories ?? [])]
    .map((entry) => normalize(entry))
    .filter((entry) => entry.length > 0);
  return Array.from(new Set(raw));
}

function includesAny(text: string, keywords: string[]): boolean {
  return keywords.some((keyword) => text.includes(keyword));
}

function classifyPlace(place: RawGooglePlace): CatalogModule {
  const tokens = collectCategoryTokens(place);
  const combined = tokens.join(' | ');

  const pharmacyKeywords = ['pharmacy', 'drug store', 'organic drug store'];
  if (includesAny(combined, pharmacyKeywords)) return 'PHARMACY';

  const hotelKeywords = ['hotel', 'bed & breakfast', 'guest house', 'guesthouse', 'resort'];
  if (includesAny(combined, hotelKeywords)) return 'HOTEL';

  const doctorKeywords = [
    'medical clinic',
    'medical office',
    'ophthalmology clinic',
    'cardiologist',
    'hospital',
    'doctor',
    'registered general nurse',
    'dentist',
    'dental',
  ];
  if (includesAny(combined, doctorKeywords)) return 'DOCTOR';

  const foodKeywords = [
    'restaurant',
    'fast food',
    'coffee shop',
    'cafe',
    'bakery',
    'patisserie',
    'pastry shop',
    'ice cream',
    'pizza',
    'hamburger',
    'sandwich',
    'family restaurant',
    'chinese restaurant',
    'french restaurant',
    'yemeni restaurant',
    'indian restaurant',
    'brunch restaurant',
    'buffet restaurant',
    'western restaurant',
    'arab restaurant',
    'steamed bun shop',
    'caterer',
  ];
  if (includesAny(combined, foodKeywords)) return 'FOOD';

  const shoppingKeywords = [
    'electronics store',
    'store',
    'boutique',
    'supermarket',
    'hypermarket',
    'market',
    'grocery store',
    'perfume store',
    'book store',
    'furniture store',
    'furniture maker',
    'bedroom furniture store',
    'hardware store',
    'home goods store',
    'clothing store',
    "children's clothing store",
    'shoe store',
    'jewelry store',
    'gift shop',
    'convenience store',
    'flower market',
    'smart shop',
    'health and beauty shop',
    'beauty supply store',
    'beauty product supplier',
    'vaporizer store',
    'tea store',
    'game store',
    'stationery store',
    'beverage distributor',
    'food products supplier',
    'produce market',
    'cell phone store',
    'electric generator shop',
    'auto parts market',
    'auto parts store',
    'truck parts supplier',
    'tire shop',
    'building materials store',
    'dj supply store',
    'gun shop',
  ];
  const shoppingBlocked = [
    'barber shop',
    'hair salon',
    'repair shop',
    'service establishment',
    'agency',
    'photography studio',
    'musician',
    'logistics service',
    'construction company',
    'tailor',
    'business center',
    'public university',
    'port authority',
    'gym',
  ];
  if (includesAny(combined, shoppingKeywords) && !includesAny(combined, shoppingBlocked)) {
    return 'SHOPPING';
  }

  return 'OTHER';
}

function parsePrice(value: string | number | null | undefined): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Number(value.toFixed(2));
  }
  if (typeof value !== 'string') return null;
  const matched = value.replace(/,/g, '').match(/(\d+(?:\.\d+)?)/);
  if (!matched) return null;
  const parsed = Number(matched[1]);
  if (!Number.isFinite(parsed)) return null;
  return Number(parsed.toFixed(2));
}

function readRating(value: unknown): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) return 0;
  return Number(Math.max(0, Math.min(5, value)).toFixed(2));
}

function readReviewCount(value: unknown): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) return 0;
  return Math.max(0, Math.round(value));
}

function isWithinDjiboutiBounds(place: RawGooglePlace): boolean {
  const lat = place.location?.lat;
  const lng = place.location?.lng;
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return false;
  return (
    lat >= DJIBOUTI_BOUNDS.minLat &&
    lat <= DJIBOUTI_BOUNDS.maxLat &&
    lng >= DJIBOUTI_BOUNDS.minLng &&
    lng <= DJIBOUTI_BOUNDS.maxLng
  );
}

function hasPhone(place: RawGooglePlace): boolean {
  return (
    normalize(place.phoneUnformatted).length > 0 ||
    normalize(place.phone).length > 0
  );
}

function buildStableId(prefix: string, placeKey: string): string {
  const digest = crypto
    .createHash('sha1')
    .update(placeKey)
    .digest('hex')
    .slice(0, 12);
  return `${prefix}${digest}`;
}

function buildSlug(name: string, placeKey: string): string {
  const digest = crypto
    .createHash('sha1')
    .update(placeKey)
    .digest('hex')
    .slice(0, 6);
  const base = slugify(name).slice(0, 54);
  return `${base || 'listing'}-${digest}`;
}

function normalizeCity(place: RawGooglePlace): string {
  const raw = place.city?.toString().trim() ?? '';
  if (raw.length > 1 && !/\d/.test(raw)) {
    return toTitleCase(raw);
  }
  return 'Djibouti';
}

function normalizeAddress(place: RawGooglePlace): string {
  const address = place.address?.toString().trim();
  if (address && address.length > 2) return address;
  return `${normalizeCity(place)}, Djibouti`;
}

function extractImageUrls(place: RawGooglePlace): string[] {
  const combined = [
    ...(Array.isArray(place.imageUrls) ? place.imageUrls : []),
    place.imageUrl ?? '',
  ];
  const unique = new Set<string>();
  for (const entry of combined) {
    const value = entry?.toString().trim() ?? '';
    if (!value.startsWith('http')) continue;
    unique.add(value);
    if (unique.size >= 8) break;
  }
  return Array.from(unique);
}

function bestPrimaryCategory(place: RawGooglePlace): string {
  const tokens = collectCategoryTokens(place);
  if (tokens.length === 0) return 'Local business';
  return toTitleCase(tokens[0]);
}

function doctorWorkingHours(place: RawGooglePlace): Record<string, string> {
  const defaults = {
    weekdays: '09:00 AM - 05:00 PM',
    saturday: '10:00 AM - 02:00 PM',
    sunday: 'Closed',
  };
  if (!Array.isArray(place.openingHours) || place.openingHours.length === 0) {
    return defaults;
  }

  const dayMap = new Map<string, string>();
  for (const entry of place.openingHours) {
    const day = normalize(entry.day);
    const hours = entry.hours?.toString().trim();
    if (day.length === 0 || !hours || hours.length === 0) continue;
    dayMap.set(day, hours);
  }

  if (dayMap.size === 0) return defaults;
  const weekdayOrder = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
  const weekdayHours = weekdayOrder
    .map((day) => dayMap.get(day))
    .filter((value): value is string => value != null && normalize(value) !== 'closed');
  const uniqueWeekdayHours = Array.from(new Set(weekdayHours));
  const weekdays =
    uniqueWeekdayHours.length === 1
      ? uniqueWeekdayHours[0]
      : uniqueWeekdayHours.length > 1
      ? 'See schedule'
      : defaults.weekdays;

  return {
    weekdays,
    saturday: dayMap.get('saturday') ?? defaults.saturday,
    sunday: dayMap.get('sunday') ?? defaults.sunday,
  };
}

function doctorSpecialty(place: RawGooglePlace): string {
  const category = place.categoryName?.toString().trim();
  if (category && category.length > 0) return category;
  const categories = Array.isArray(place.categories) ? place.categories : [];
  if (categories.length > 0) return categories[0];
  return 'General Medicine';
}

function doctorProviderTypeFromSpecialty(specialty: string): string {
  const normalized = normalize(specialty);
  if (
    normalized.includes('nurse') ||
    normalized.includes('therapy') ||
    normalized.includes('physio') ||
    normalized.includes('rehab')
  ) {
    return 'HOME_CARE';
  }
  if (normalized.includes('clinic') || normalized.includes('hospital')) {
    return 'CLINIC';
  }
  return 'DOCTOR';
}

function doctorServicesFromSpecialty(specialty: string): string[] {
  const normalized = normalize(specialty);
  if (normalized.includes('ophthalm')) {
    return ['Eye consultation', 'Vision check', 'Eye diagnostics'];
  }
  if (normalized.includes('cardio')) {
    return ['Heart consultation', 'Cardiac follow-up', 'Preventive screening'];
  }
  if (normalized.includes('nurse')) {
    return ['Home nursing', 'Medication support', 'Routine follow-up'];
  }
  if (normalized.includes('clinic') || normalized.includes('hospital')) {
    return ['General consultation', 'Walk-in care', 'Diagnostic referral'];
  }
  return ['General consultation', 'Health checkup'];
}

function consultationFeeForSpecialty(specialty: string): number {
  const normalized = normalize(specialty);
  if (normalized.includes('cardio')) return 45;
  if (normalized.includes('ophthalm')) return 40;
  if (normalized.includes('hospital')) return 35;
  if (normalized.includes('clinic')) return 30;
  if (normalized.includes('nurse')) return 25;
  return 28;
}

function foodCuisine(place: RawGooglePlace): string {
  const all = [place.categoryName ?? '', ...(place.categories ?? [])]
    .map((entry) => entry.toString().trim())
    .filter((entry) => entry.length > 0);
  const filtered = all.filter(
    (entry) => !GENERIC_FOOD_CATEGORIES.has(entry.toLowerCase()),
  );
  const source = filtered.length > 0 ? filtered : all;
  if (source.length === 0) return 'Local Cuisine';
  return source.slice(0, 2).join(', ');
}

function computeDistanceFromDjiboutiCenter(place: RawGooglePlace): number | null {
  const lat = place.location?.lat;
  const lng = place.location?.lng;
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  const centerLat = 11.5886;
  const centerLng = 43.1456;
  const toRadians = (value: number) => (value * Math.PI) / 180;
  const earthRadiusKm = 6371;
  const latDelta = toRadians(lat - centerLat);
  const lngDelta = toRadians(lng - centerLng);
  const startLatRad = toRadians(centerLat);
  const endLatRad = toRadians(lat);

  const a =
    Math.sin(latDelta / 2) * Math.sin(latDelta / 2) +
    Math.cos(startLatRad) *
      Math.cos(endLatRad) *
      Math.sin(lngDelta / 2) *
      Math.sin(lngDelta / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Number((earthRadiusKm * c).toFixed(2));
}

function deliveryTimeFromReviewCount(reviewCount: number): string {
  if (reviewCount >= 60) return '20-30';
  if (reviewCount >= 20) return '25-35';
  return '30-40';
}

function deliveryFeeFromCity(city: string): number {
  return normalize(city) === 'djibouti' ? 2 : 3.5;
}

function hotelAmenities(place: RawGooglePlace): string[] {
  const name = normalize(place.title);
  const categories = collectCategoryTokens(place);
  const amenities = new Set<string>(['Free WiFi']);
  if (categories.some((entry) => entry.includes('resort'))) amenities.add('Beach access');
  if (name.includes('resort') || name.includes('beach')) amenities.add('Sea view');
  if ((place.reviewsCount ?? 0) >= 20) amenities.add('Breakfast');
  if ((place.reviewsCount ?? 0) >= 50) amenities.add('Restaurant');
  amenities.add('City access');
  return Array.from(amenities).slice(0, 6);
}

function shoppingCategoryId(tokens: string[]): (typeof SHOPPING_CATEGORY_IDS)[number] {
  const text = tokens.join(' | ');
  if (
    text.includes('electronics') ||
    text.includes('cell phone') ||
    text.includes('generator')
  ) {
    return 'shopping-electronics';
  }
  if (
    text.includes('clothing') ||
    text.includes('shoe') ||
    text.includes('boutique') ||
    text.includes('jewelry') ||
    text.includes('handbags')
  ) {
    return 'shopping-clothing';
  }
  if (
    text.includes('furniture') ||
    text.includes('hardware') ||
    text.includes('home goods') ||
    text.includes('building materials')
  ) {
    return 'shopping-home';
  }
  if (text.includes('beauty') || text.includes('perfume') || text.includes('gift')) {
    return 'shopping-accessories';
  }
  return 'shopping-home';
}

function shoppingProductBasePrice(categoryId: string): number {
  if (categoryId === 'shopping-electronics') return 95;
  if (categoryId === 'shopping-clothing') return 28;
  if (categoryId === 'shopping-accessories') return 18;
  if (categoryId === 'shopping-shoes') return 34;
  return 22;
}

function pharmacyCategoryId(place: RawGooglePlace): (typeof PHARMACY_CATEGORY_IDS)[number] {
  const text = collectCategoryTokens(place).join(' | ');
  if (text.includes('vitamin')) return 'pharmacy-vitamins';
  if (text.includes('antibiotic')) return 'pharmacy-antibiotics';
  if (text.includes('cold') || text.includes('flu')) return 'pharmacy-cold-flu';
  return 'pharmacy-pain-relief';
}

function pharmacyProductBasePrice(categoryId: string): number {
  if (categoryId === 'pharmacy-antibiotics') return 14;
  if (categoryId === 'pharmacy-vitamins') return 11;
  if (categoryId === 'pharmacy-cold-flu') return 9;
  return 8;
}

function badgeFromSignals(rating: number, reviewCount: number): string | null {
  if (rating >= 4.7 && reviewCount >= 20) return 'Top Rated';
  if (reviewCount >= 80) return 'Popular';
  if (reviewCount >= 20) return 'Trusted';
  if (rating >= 4.5) return 'Highly Rated';
  return null;
}

function shouldKeepRecord(
  place: RawGooglePlace,
  moduleType: CatalogModule,
  options: ImportOptions,
): { keep: boolean; reason?: string } {
  const name = place.title?.toString().trim() ?? '';
  if (!safeName(name)) return { keep: false, reason: 'invalid_name' };
  if (!place.placeId && !place.cid && !place.fid) return { keep: false, reason: 'missing_unique_key' };
  if (!isWithinDjiboutiBounds(place)) return { keep: false, reason: 'outside_djibouti_bounds' };
  if (!options.includeTemporarilyClosed && (place.temporarilyClosed || place.permanentlyClosed)) {
    return { keep: false, reason: 'closed' };
  }
  if (moduleType === 'OTHER') return { keep: false, reason: 'unsupported_category' };

  if (options.strictQuality && (moduleType === 'SHOPPING' || moduleType === 'FOOD')) {
    const rating = readRating(place.totalScore);
    const reviewCount = readReviewCount(place.reviewsCount);
    if (!hasPhone(place) && reviewCount < 2 && rating < 4) {
      return { keep: false, reason: 'low_signal' };
    }
  }

  return { keep: true };
}

function extractData(records: RawGooglePlace[], options: ImportOptions): ExtractionResult {
  const skippedReasons: Record<string, number> = {};
  const mappedCounts: Record<CatalogModule, number> = {
    SHOPPING: 0,
    FOOD: 0,
    DOCTOR: 0,
    HOTEL: 0,
    PHARMACY: 0,
    OTHER: 0,
  };

  const shoppingStores: ShoppingStoreSeed[] = [];
  const shoppingProducts: ProductSeed[] = [];
  const doctors: DoctorSeed[] = [];
  const restaurants: RestaurantSeed[] = [];
  const hotels: HotelSeed[] = [];
  const pharmacyProducts: ProductSeed[] = [];

  const seenKeys = new Set<string>();

  for (const place of records) {
    const moduleType = classifyPlace(place);
    mappedCounts[moduleType] += 1;

    const { keep, reason } = shouldKeepRecord(place, moduleType, options);
    if (!keep) {
      if (reason) skippedReasons[reason] = (skippedReasons[reason] ?? 0) + 1;
      continue;
    }

    const placeKey = place.placeId ?? place.cid ?? place.fid ?? place.title ?? '';
    if (seenKeys.has(placeKey)) {
      skippedReasons.duplicate = (skippedReasons.duplicate ?? 0) + 1;
      continue;
    }
    seenKeys.add(placeKey);

    const name = place.title?.toString().trim() ?? 'Unknown';
    const city = normalizeCity(place);
    const address = normalizeAddress(place);
    const rating = readRating(place.totalScore);
    const reviewCount = readReviewCount(place.reviewsCount);
    const imageUrls = extractImageUrls(place);
    const categoryTokens = collectCategoryTokens(place);
    const isOpen = !(place.temporarilyClosed || place.permanentlyClosed);
    const parsedPrice = parsePrice(place.price);

    if (moduleType === 'SHOPPING') {
      const id = buildStableId(PREFIXES.shoppingStore, placeKey);
      const slug = buildSlug(name, placeKey);
      const categoryId = shoppingCategoryId(categoryTokens);
      const basePrice = parsedPrice ?? shoppingProductBasePrice(categoryId);

      const store: ShoppingStoreSeed = {
        id,
        placeId: place.placeId ?? placeKey,
        name,
        slug,
        tagline: `${bestPrimaryCategory(place)} in ${city}`,
        description: `Google Places business listing for ${name} in ${city}.`,
        imageUrl: imageUrls[0] ?? null,
        isOpen,
        rating,
        reviewCount,
        badge: badgeFromSignals(rating, reviewCount),
        minPrice: parsedPrice != null ? parsedPrice : null,
        maxPrice: parsedPrice != null ? Number((parsedPrice * 2.4).toFixed(2)) : null,
        highlightsJson: Array.from(
          new Set([
            bestPrimaryCategory(place),
            city,
            ...categoryTokens.slice(0, 3).map((token) => toTitleCase(token)),
          ]),
        ).slice(0, 5),
        categoryTokens,
      };
      shoppingStores.push(store);

      const product: ProductSeed = {
        id: buildStableId(PREFIXES.shoppingProduct, placeKey),
        moduleType: ModuleType.SHOPPING,
        categoryId,
        shopId: id,
        name: `${toTitleCase(bestPrimaryCategory(place))} Essentials`,
        brand: name,
        description: `Representative catalog item for ${name}, extracted from Google Places store data.`,
        price: Number(basePrice.toFixed(2)),
        originalPrice: null,
        rating,
        reviewCount,
        dosage: null,
        packageSize: null,
        requiresPrescription: false,
        imageUrlsJson: imageUrls,
        colorsJson: [],
        sizesJson: [],
        tagsJson: ['Google Places', city],
        featuresJson: categoryTokens.slice(0, 3).map((token) => toTitleCase(token)),
        badge: store.badge,
        inStock: true,
        isOrganic: false,
        metadata: {
          source: 'google_places',
          sourcePlaceId: place.placeId ?? null,
          sourceCid: place.cid ?? null,
          sourceAddress: address,
          sourcePhone: place.phoneUnformatted ?? place.phone ?? null,
          sourceWebsite: place.website ?? null,
        } as Prisma.InputJsonObject,
      };
      shoppingProducts.push(product);
      continue;
    }

    if (moduleType === 'DOCTOR') {
      const specialty = doctorSpecialty(place);
      const providerType = doctorProviderTypeFromSpecialty(specialty);
      doctors.push({
        id: buildStableId(PREFIXES.doctor, placeKey),
        placeId: place.placeId ?? placeKey,
        name,
        specialty,
        providerType,
        rating,
        reviewCount,
        experience:
          reviewCount >= 40
            ? 'Established local practice'
            : reviewCount >= 10
            ? 'Growing local practice'
            : 'Local healthcare provider',
        consultationFee: consultationFeeForSpecialty(specialty),
        isAvailable: isOpen,
        isSignedUp: true,
        imageUrl: imageUrls[0] ?? null,
        about: `${name} is listed on Google Places as ${specialty.toLowerCase()} in ${city}.`,
        location: address,
        contactPhone: place.phoneUnformatted ?? place.phone ?? null,
        contactWhatsApp: place.phoneUnformatted ?? place.phone ?? null,
        languagesJson: ['French', 'Arabic', 'Somali'],
        servicesJson: doctorServicesFromSpecialty(specialty),
        careModesJson:
          providerType === 'HOME_CARE'
            ? ['Home Visit', 'Phone Advice']
            : ['Clinic Visit'],
        workingHoursJson: doctorWorkingHours(place),
      });
      continue;
    }

    if (moduleType === 'FOOD') {
      const restaurantId = buildStableId(PREFIXES.restaurant, placeKey);
      const cuisine = foodCuisine(place);
      restaurants.push({
        id: restaurantId,
        placeId: place.placeId ?? placeKey,
        name,
        cuisine,
        rating,
        reviewCount,
        deliveryTime: deliveryTimeFromReviewCount(reviewCount),
        deliveryFee: deliveryFeeFromCity(city),
        imageUrl: imageUrls[0] ?? null,
        isOpen,
        distanceKm: computeDistanceFromDjiboutiCenter(place),
        tagsJson: Array.from(
          new Set([
            city,
            ...categoryTokens.slice(0, 4).map((token) => toTitleCase(token)),
          ]),
        ),
        menuCategory: {
          id: buildStableId(PREFIXES.restaurantMenuCategory, placeKey),
          name: 'Popular',
          sortOrder: 1,
        },
        menuItem: {
          id: buildStableId(PREFIXES.restaurantMenuItem, placeKey),
          name: `${toTitleCase(cuisine.split(',')[0] ?? 'House')} Special`,
          description: `Representative menu item for ${name}, based on Google Places restaurant profile.`,
          price: Number((parsedPrice ?? 12).toFixed(2)),
          imageUrl: imageUrls[1] ?? imageUrls[0] ?? null,
          isPopular: true,
          isAvailable: isOpen,
          customizationsJson: ['No onions', 'Extra spicy'],
        },
      });
      continue;
    }

    if (moduleType === 'HOTEL') {
      const fallbackPrice = reviewCount >= 100 ? 145 : reviewCount >= 30 ? 120 : 95;
      hotels.push({
        id: buildStableId(PREFIXES.hotel, placeKey),
        placeId: place.placeId ?? placeKey,
        name,
        address,
        city,
        rating,
        reviewsCount: reviewCount,
        pricePerNight: Number((parsedPrice ?? fallbackPrice).toFixed(2)),
        amenitiesJson: hotelAmenities(place),
        description: `Hotel listing imported from Google Places for ${name} in ${city}.`,
        imageUrlsJson: imageUrls,
      });
      continue;
    }

    if (moduleType === 'PHARMACY') {
      const categoryId = pharmacyCategoryId(place);
      const basePrice = parsedPrice ?? pharmacyProductBasePrice(categoryId);
      pharmacyProducts.push({
        id: buildStableId(PREFIXES.pharmacyProduct, placeKey),
        moduleType: ModuleType.PHARMACY,
        categoryId,
        shopId: null,
        name: `${name} Essentials`,
        brand: name,
        description: `Pharmacy profile imported from Google Places for ${name}.`,
        price: Number(basePrice.toFixed(2)),
        originalPrice: null,
        rating,
        reviewCount,
        dosage: 'Use as directed.',
        packageSize: 'Standard pack',
        requiresPrescription: false,
        imageUrlsJson: imageUrls,
        colorsJson: [],
        sizesJson: [],
        tagsJson: ['Google Places', city],
        featuresJson: ['Pharmacy', 'In-store assistance'],
        badge: badgeFromSignals(rating, reviewCount),
        inStock: true,
        isOrganic: false,
        metadata: {
          source: 'google_places',
          sourceBusiness: name,
          sourcePlaceId: place.placeId ?? null,
          sourceCid: place.cid ?? null,
          sourceAddress: address,
          sourcePhone: place.phoneUnformatted ?? place.phone ?? null,
          sourceWebsite: place.website ?? null,
          location: {
            latitude: place.location?.lat ?? null,
            longitude: place.location?.lng ?? null,
          },
        } as Prisma.InputJsonObject,
      });
    }
  }

  return {
    summary: {
      inputCount: records.length,
      candidateCount: seenKeys.size,
      strictQuality: options.strictQuality,
      skippedReasons,
      mappedCounts,
      extractedCounts: {
        shoppingStores: shoppingStores.length,
        shoppingProducts: shoppingProducts.length,
        doctors: doctors.length,
        restaurants: restaurants.length,
        hotels: hotels.length,
        pharmacyProducts: pharmacyProducts.length,
      },
    },
    shoppingStores,
    shoppingProducts,
    doctors,
    restaurants,
    hotels,
    pharmacyProducts,
  };
}

function ensureOutputDir(outputPath: string) {
  const dir = path.dirname(outputPath);
  fs.mkdirSync(dir, { recursive: true });
}

async function ensureBaseProductCategories() {
  const shoppingCategories: Array<{
    id: string;
    name: string;
    slug: string;
    sortOrder: number;
  }> = [
    { id: 'shopping-shoes', name: 'Shoes', slug: 'shopping-shoes', sortOrder: 1 },
    {
      id: 'shopping-electronics',
      name: 'Electronics',
      slug: 'shopping-electronics',
      sortOrder: 2,
    },
    { id: 'shopping-clothing', name: 'Clothing', slug: 'shopping-clothing', sortOrder: 3 },
    { id: 'shopping-home', name: 'Home', slug: 'shopping-home', sortOrder: 4 },
    {
      id: 'shopping-accessories',
      name: 'Accessories',
      slug: 'shopping-accessories',
      sortOrder: 5,
    },
  ];

  const pharmacyCategories: Array<{
    id: string;
    name: string;
    slug: string;
    sortOrder: number;
  }> = [
    {
      id: 'pharmacy-pain-relief',
      name: 'Pain Relief',
      slug: 'pharmacy-pain-relief',
      sortOrder: 1,
    },
    {
      id: 'pharmacy-antibiotics',
      name: 'Antibiotics',
      slug: 'pharmacy-antibiotics',
      sortOrder: 2,
    },
    { id: 'pharmacy-vitamins', name: 'Vitamins', slug: 'pharmacy-vitamins', sortOrder: 3 },
    { id: 'pharmacy-cold-flu', name: 'Cold & Flu', slug: 'pharmacy-cold-flu', sortOrder: 4 },
  ];

  for (const category of shoppingCategories) {
    await prisma.productCategory.upsert({
      where: { id: category.id },
      update: {
        moduleType: ModuleType.SHOPPING,
        name: category.name,
        slug: category.slug,
        sortOrder: category.sortOrder,
        active: true,
      },
      create: {
        id: category.id,
        moduleType: ModuleType.SHOPPING,
        name: category.name,
        slug: category.slug,
        sortOrder: category.sortOrder,
        active: true,
      },
    });
  }

  for (const category of pharmacyCategories) {
    await prisma.productCategory.upsert({
      where: { id: category.id },
      update: {
        moduleType: ModuleType.PHARMACY,
        name: category.name,
        slug: category.slug,
        sortOrder: category.sortOrder,
        active: true,
      },
      create: {
        id: category.id,
        moduleType: ModuleType.PHARMACY,
        name: category.name,
        slug: category.slug,
        sortOrder: category.sortOrder,
        active: true,
      },
    });
  }
}

async function pruneStaleData(extracted: ExtractionResult) {
  const shoppingProductIds = extracted.shoppingProducts.map((entry) => entry.id);
  await prisma.product.deleteMany({
    where:
      shoppingProductIds.length > 0
        ? {
            id: { startsWith: PREFIXES.shoppingProduct },
            NOT: { id: { in: shoppingProductIds } },
          }
        : { id: { startsWith: PREFIXES.shoppingProduct } },
  });

  const pharmacyProductIds = extracted.pharmacyProducts.map((entry) => entry.id);
  await prisma.product.deleteMany({
    where:
      pharmacyProductIds.length > 0
        ? {
            id: { startsWith: PREFIXES.pharmacyProduct },
            NOT: { id: { in: pharmacyProductIds } },
          }
        : { id: { startsWith: PREFIXES.pharmacyProduct } },
  });

  const menuItemIds = extracted.restaurants.map((entry) => entry.menuItem.id);
  await prisma.restaurantMenuItem.deleteMany({
    where:
      menuItemIds.length > 0
        ? {
            id: { startsWith: PREFIXES.restaurantMenuItem },
            NOT: { id: { in: menuItemIds } },
          }
        : { id: { startsWith: PREFIXES.restaurantMenuItem } },
  });

  const menuCategoryIds = extracted.restaurants.map((entry) => entry.menuCategory.id);
  await prisma.restaurantMenuCategory.deleteMany({
    where:
      menuCategoryIds.length > 0
        ? {
            id: { startsWith: PREFIXES.restaurantMenuCategory },
            NOT: { id: { in: menuCategoryIds } },
          }
        : { id: { startsWith: PREFIXES.restaurantMenuCategory } },
  });

  const restaurantIds = extracted.restaurants.map((entry) => entry.id);
  await prisma.restaurant.deleteMany({
    where:
      restaurantIds.length > 0
        ? {
            id: { startsWith: PREFIXES.restaurant },
            NOT: { id: { in: restaurantIds } },
          }
        : { id: { startsWith: PREFIXES.restaurant } },
  });

  const shoppingStoreIds = extracted.shoppingStores.map((entry) => entry.id);
  await prisma.shoppingStore.deleteMany({
    where:
      shoppingStoreIds.length > 0
        ? {
            id: { startsWith: PREFIXES.shoppingStore },
            NOT: { id: { in: shoppingStoreIds } },
          }
        : { id: { startsWith: PREFIXES.shoppingStore } },
  });

  const doctorIds = extracted.doctors.map((entry) => entry.id);
  await prisma.doctor.deleteMany({
    where:
      doctorIds.length > 0
        ? {
            id: { startsWith: PREFIXES.doctor },
            NOT: { id: { in: doctorIds } },
          }
        : { id: { startsWith: PREFIXES.doctor } },
  });

  const hotelIds = extracted.hotels.map((entry) => entry.id);
  await prisma.hotel.deleteMany({
    where:
      hotelIds.length > 0
        ? {
            id: { startsWith: PREFIXES.hotel },
            NOT: { id: { in: hotelIds } },
          }
        : { id: { startsWith: PREFIXES.hotel } },
  });
}

async function applyToDatabase(extracted: ExtractionResult, options: ImportOptions) {
  await ensureBaseProductCategories();

  for (const store of extracted.shoppingStores) {
    await prisma.shoppingStore.upsert({
      where: { id: store.id },
      update: {
        name: store.name,
        slug: store.slug,
        tagline: store.tagline,
        description: store.description,
        imageUrl: store.imageUrl,
        isOpen: store.isOpen,
        rating: store.rating,
        reviewCount: store.reviewCount,
        badge: store.badge,
        minPrice: store.minPrice,
        maxPrice: store.maxPrice,
        highlightsJson: store.highlightsJson,
      },
      create: {
        id: store.id,
        name: store.name,
        slug: store.slug,
        tagline: store.tagline,
        description: store.description,
        imageUrl: store.imageUrl,
        isOpen: store.isOpen,
        rating: store.rating,
        reviewCount: store.reviewCount,
        badge: store.badge,
        minPrice: store.minPrice,
        maxPrice: store.maxPrice,
        highlightsJson: store.highlightsJson,
      },
    });
  }

  for (const product of extracted.shoppingProducts) {
    await prisma.product.upsert({
      where: { id: product.id },
      update: {
        moduleType: product.moduleType,
        categoryId: product.categoryId,
        shopId: product.shopId,
        name: product.name,
        brand: product.brand,
        description: product.description,
        price: product.price,
        originalPrice: product.originalPrice,
        rating: product.rating,
        reviewCount: product.reviewCount,
        dosage: product.dosage,
        packageSize: product.packageSize,
        requiresPrescription: product.requiresPrescription,
        imageUrlsJson: product.imageUrlsJson,
        colorsJson: product.colorsJson,
        sizesJson: product.sizesJson,
        tagsJson: product.tagsJson,
        featuresJson: product.featuresJson,
        badge: product.badge,
        inStock: product.inStock,
        isOrganic: product.isOrganic,
        metadata: product.metadata,
      },
      create: {
        id: product.id,
        moduleType: product.moduleType,
        categoryId: product.categoryId,
        shopId: product.shopId,
        name: product.name,
        brand: product.brand,
        description: product.description,
        price: product.price,
        originalPrice: product.originalPrice,
        rating: product.rating,
        reviewCount: product.reviewCount,
        dosage: product.dosage,
        packageSize: product.packageSize,
        requiresPrescription: product.requiresPrescription,
        imageUrlsJson: product.imageUrlsJson,
        colorsJson: product.colorsJson,
        sizesJson: product.sizesJson,
        tagsJson: product.tagsJson,
        featuresJson: product.featuresJson,
        badge: product.badge,
        inStock: product.inStock,
        isOrganic: product.isOrganic,
        metadata: product.metadata,
      },
    });
  }

  for (const doctor of extracted.doctors) {
    await prisma.doctor.upsert({
      where: { id: doctor.id },
      update: {
        name: doctor.name,
        specialty: doctor.specialty,
        providerType: doctor.providerType,
        rating: doctor.rating,
        reviewCount: doctor.reviewCount,
        experience: doctor.experience,
        consultationFee: doctor.consultationFee,
        isAvailable: doctor.isAvailable,
        isSignedUp: doctor.isSignedUp,
        imageUrl: doctor.imageUrl,
        about: doctor.about,
        location: doctor.location,
        contactPhone: doctor.contactPhone,
        contactWhatsApp: doctor.contactWhatsApp,
        languagesJson: doctor.languagesJson,
        servicesJson: doctor.servicesJson,
        careModesJson: doctor.careModesJson,
        workingHoursJson: doctor.workingHoursJson,
      },
      create: {
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        providerType: doctor.providerType,
        rating: doctor.rating,
        reviewCount: doctor.reviewCount,
        experience: doctor.experience,
        consultationFee: doctor.consultationFee,
        isAvailable: doctor.isAvailable,
        isSignedUp: doctor.isSignedUp,
        imageUrl: doctor.imageUrl,
        about: doctor.about,
        location: doctor.location,
        contactPhone: doctor.contactPhone,
        contactWhatsApp: doctor.contactWhatsApp,
        languagesJson: doctor.languagesJson,
        servicesJson: doctor.servicesJson,
        careModesJson: doctor.careModesJson,
        workingHoursJson: doctor.workingHoursJson,
      },
    });
  }

  for (const restaurant of extracted.restaurants) {
    await prisma.restaurant.upsert({
      where: { id: restaurant.id },
      update: {
        name: restaurant.name,
        cuisine: restaurant.cuisine,
        rating: restaurant.rating,
        reviewCount: restaurant.reviewCount,
        deliveryTime: restaurant.deliveryTime,
        deliveryFee: restaurant.deliveryFee,
        imageUrl: restaurant.imageUrl,
        isOpen: restaurant.isOpen,
        distanceKm: restaurant.distanceKm,
        tagsJson: restaurant.tagsJson,
      },
      create: {
        id: restaurant.id,
        name: restaurant.name,
        cuisine: restaurant.cuisine,
        rating: restaurant.rating,
        reviewCount: restaurant.reviewCount,
        deliveryTime: restaurant.deliveryTime,
        deliveryFee: restaurant.deliveryFee,
        imageUrl: restaurant.imageUrl,
        isOpen: restaurant.isOpen,
        distanceKm: restaurant.distanceKm,
        tagsJson: restaurant.tagsJson,
      },
    });

    await prisma.restaurantMenuCategory.upsert({
      where: { id: restaurant.menuCategory.id },
      update: {
        restaurantId: restaurant.id,
        name: restaurant.menuCategory.name,
        sortOrder: restaurant.menuCategory.sortOrder,
      },
      create: {
        id: restaurant.menuCategory.id,
        restaurantId: restaurant.id,
        name: restaurant.menuCategory.name,
        sortOrder: restaurant.menuCategory.sortOrder,
      },
    });

    await prisma.restaurantMenuItem.upsert({
      where: { id: restaurant.menuItem.id },
      update: {
        categoryId: restaurant.menuCategory.id,
        name: restaurant.menuItem.name,
        description: restaurant.menuItem.description,
        price: restaurant.menuItem.price,
        imageUrl: restaurant.menuItem.imageUrl,
        isPopular: restaurant.menuItem.isPopular,
        isAvailable: restaurant.menuItem.isAvailable,
        customizationsJson: restaurant.menuItem.customizationsJson,
      },
      create: {
        id: restaurant.menuItem.id,
        categoryId: restaurant.menuCategory.id,
        name: restaurant.menuItem.name,
        description: restaurant.menuItem.description,
        price: restaurant.menuItem.price,
        imageUrl: restaurant.menuItem.imageUrl,
        isPopular: restaurant.menuItem.isPopular,
        isAvailable: restaurant.menuItem.isAvailable,
        customizationsJson: restaurant.menuItem.customizationsJson,
      },
    });
  }

  for (const hotel of extracted.hotels) {
    await prisma.hotel.upsert({
      where: { id: hotel.id },
      update: {
        name: hotel.name,
        address: hotel.address,
        city: hotel.city,
        rating: hotel.rating,
        reviewsCount: hotel.reviewsCount,
        pricePerNight: hotel.pricePerNight,
        amenitiesJson: hotel.amenitiesJson,
        description: hotel.description,
        imageUrlsJson: hotel.imageUrlsJson,
      },
      create: {
        id: hotel.id,
        name: hotel.name,
        address: hotel.address,
        city: hotel.city,
        rating: hotel.rating,
        reviewsCount: hotel.reviewsCount,
        pricePerNight: hotel.pricePerNight,
        amenitiesJson: hotel.amenitiesJson,
        description: hotel.description,
        imageUrlsJson: hotel.imageUrlsJson,
      },
    });
  }

  for (const product of extracted.pharmacyProducts) {
    await prisma.product.upsert({
      where: { id: product.id },
      update: {
        moduleType: product.moduleType,
        categoryId: product.categoryId,
        shopId: product.shopId,
        name: product.name,
        brand: product.brand,
        description: product.description,
        price: product.price,
        originalPrice: product.originalPrice,
        rating: product.rating,
        reviewCount: product.reviewCount,
        dosage: product.dosage,
        packageSize: product.packageSize,
        requiresPrescription: product.requiresPrescription,
        imageUrlsJson: product.imageUrlsJson,
        colorsJson: product.colorsJson,
        sizesJson: product.sizesJson,
        tagsJson: product.tagsJson,
        featuresJson: product.featuresJson,
        badge: product.badge,
        inStock: product.inStock,
        isOrganic: product.isOrganic,
        metadata: product.metadata,
      },
      create: {
        id: product.id,
        moduleType: product.moduleType,
        categoryId: product.categoryId,
        shopId: product.shopId,
        name: product.name,
        brand: product.brand,
        description: product.description,
        price: product.price,
        originalPrice: product.originalPrice,
        rating: product.rating,
        reviewCount: product.reviewCount,
        dosage: product.dosage,
        packageSize: product.packageSize,
        requiresPrescription: product.requiresPrescription,
        imageUrlsJson: product.imageUrlsJson,
        colorsJson: product.colorsJson,
        sizesJson: product.sizesJson,
        tagsJson: product.tagsJson,
        featuresJson: product.featuresJson,
        badge: product.badge,
        inStock: product.inStock,
        isOrganic: product.isOrganic,
        metadata: product.metadata,
      },
    });
  }

  if (options.prune) {
    await pruneStaleData(extracted);
  }
}

function loadRawPlaces(inputPath: string): RawGooglePlace[] {
  const raw = fs.readFileSync(inputPath, 'utf8');
  const parsed = JSON.parse(raw);
  if (!Array.isArray(parsed)) {
    throw new Error(`Expected JSON array in ${inputPath}`);
  }
  return parsed as RawGooglePlace[];
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  const rawPlaces = loadRawPlaces(options.inputPath);
  const extracted = extractData(rawPlaces, options);

  ensureOutputDir(options.outputPath);
  fs.writeFileSync(
    options.outputPath,
    JSON.stringify(
      {
        generatedAt: new Date().toISOString(),
        sourcePath: options.inputPath,
        ...extracted,
      },
      null,
      2,
    ),
    'utf8',
  );

  console.log('Google Places extraction completed.');
  console.log(`Input file: ${options.inputPath}`);
  console.log(`Output file: ${options.outputPath}`);
  console.log('Summary:', JSON.stringify(extracted.summary, null, 2));

  if (!options.apply) {
    console.log('Dry run mode: database was not modified.');
    return;
  }

  await applyToDatabase(extracted, options);
  console.log(
    options.prune
      ? 'Database import completed with pruning.'
      : 'Database import completed (without pruning).',
  );
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error('Google Places import failed:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
