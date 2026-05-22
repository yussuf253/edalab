import { ModuleType, Prisma } from '@prisma/client';
import { Router } from 'express';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { toNumber } from '../utils/serializers';

const router = Router();

const ECOLOGICAL_CLEANING_CATEGORY = {
  id: 'hs-ecological-cleaning',
  name: 'Ecological Cleaning',
  slug: 'ecological-cleaning',
  description:
    'Eco-friendly car wash, living room and furniture cleaning, office cleaning, post-construction cleaning, and ecological disinfection.',
  iconKey: 'cleaning',
  colorHex: '#2F9E44',
  sortOrder: 8,
  active: true,
} as const;

type CatalogProductWithCategory = Awaited<
  ReturnType<typeof prisma.product.findMany>
>[number] & {
  category: { name: string; id: string } | null;
  shop?: {
    id: string;
    name: string;
    slug: string;
    tagline: string | null;
    description: string | null;
    imageUrl: string | null;
    rating: unknown;
    reviewCount: number;
    badge: string | null;
    minPrice: unknown;
    maxPrice: unknown;
    highlightsJson: unknown;
  } | null;
};

function readJsonStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((entry) => (typeof entry === 'string' ? entry : null))
    .filter((entry): entry is string => entry != null);
}

function toFiniteNumber(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === 'string' && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

function readBooleanQuery(value: unknown): boolean {
  const normalized = value?.toString().trim().toLowerCase();
  return (
    normalized === '1' ||
    normalized === 'true' ||
    normalized === 'yes' ||
    normalized === 'y'
  );
}

function toRadians(value: number) {
  return (value * Math.PI) / 180;
}

function haversineDistanceKm(
  startLatitude: number,
  startLongitude: number,
  endLatitude: number,
  endLongitude: number,
) {
  const earthRadiusKm = 6371;
  const latitudeDelta = toRadians(endLatitude - startLatitude);
  const longitudeDelta = toRadians(endLongitude - startLongitude);
  const startLatRad = toRadians(startLatitude);
  const endLatRad = toRadians(endLatitude);

  const a =
    Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
    Math.cos(startLatRad) *
      Math.cos(endLatRad) *
      Math.sin(longitudeDelta / 2) *
      Math.sin(longitudeDelta / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

type ServiceZoneConfig = {
  enabled: boolean;
  centerLatitude: number | null;
  centerLongitude: number | null;
  radiusKm: number;
};

type LaundryCatalogConfigItem = {
  id: string;
  label: string;
  price: number;
  category: 'unit' | 'group';
  spec?: string | null;
};

type LaundryCatalogBookingConfig = {
  itemCatalog: LaundryCatalogConfigItem[];
  pickupSlots: string[];
  turnaroundHours: number;
  minNoticeHours: number;
  maxAdvanceDays: number;
  taxRatePercent: number;
  deliveryFee: number;
};

function defaultLaundryCatalogBookingConfig(
  basePrice: number,
): LaundryCatalogBookingConfig {
  const washAndFoldBasePrice =
    Number.isFinite(basePrice) && basePrice > 0 ? basePrice : 6000;
  return {
    itemCatalog: [
      { id: 'shirts', label: 'Shirt', price: 700, category: 'unit' },
      { id: 't_shirt', label: 'T-Shirt', price: 500, category: 'unit' },
      { id: 'polo', label: 'Polo', price: 500, category: 'unit' },
      { id: 'trouser', label: 'Trouser', price: 800, category: 'unit' },
      { id: 'blazer', label: 'Blazer', price: 1500, category: 'unit' },
      { id: 'suit_2_pieces', label: 'Suit 2 pieces', price: 2000, category: 'unit' },
      { id: 'suit_3_pieces', label: 'Suit 3 pieces', price: 2700, category: 'unit' },
      { id: 'jacket', label: 'Jacket', price: 1500, category: 'unit' },
      { id: 'dress', label: 'Dress', price: 1200, category: 'unit' },
      {
        id: 'wash_fold_10_20',
        label: 'Wash & Fold 10-20 pieces',
        price: washAndFoldBasePrice,
        category: 'group',
        spec: '10 to 20 pieces',
      },
      {
        id: 'wash_fold_21_30',
        label: 'Wash & Fold 21-30 pieces',
        price: 12000,
        category: 'group',
        spec: '21 to 30 pieces',
      },
      {
        id: 'wash_fold_31_40',
        label: 'Wash & Fold 31-40 pieces',
        price: 14500,
        category: 'group',
        spec: '31 to 40 pieces',
      },
    ],
    pickupSlots: ['08:00 - 10:00', '10:00 - 12:00', '14:00 - 16:00', '16:00 - 18:00'],
    turnaroundHours: 26,
    minNoticeHours: 0,
    maxAdvanceDays: 5,
    taxRatePercent: 8,
    deliveryFee: 0,
  };
}

function unconfiguredLaundryCatalogBookingConfig(
  basePrice: number,
): LaundryCatalogBookingConfig {
  const defaults = defaultLaundryCatalogBookingConfig(basePrice);
  return {
    ...defaults,
    itemCatalog: [],
  };
}

function normalizeLaundryCatalogBookingConfig(
  value: unknown,
  fallback: LaundryCatalogBookingConfig,
): LaundryCatalogBookingConfig {
  const map =
    value != null && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {};

  const normalizeItemId = (label: string, idValue?: string) => {
    const normalizedId = (idValue ?? '')
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '');
    if (normalizedId.length > 0) {
      return normalizedId.slice(0, 40);
    }
    return label
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 40);
  };

  const itemCatalogRaw = Array.isArray(map.itemCatalog) ? map.itemCatalog : null;
  const hasItemCatalog = itemCatalogRaw != null;
  const itemCatalog =
    itemCatalogRaw == null
      ? fallback.itemCatalog
      : itemCatalogRaw
          .map((entry) =>
            entry != null && typeof entry === 'object' && !Array.isArray(entry)
              ? (entry as Record<string, unknown>)
              : null,
          )
          .filter((entry): entry is Record<string, unknown> => entry != null)
          .map((entry) => {
            const label = entry.label?.toString().trim() ?? '';
            const price = toFiniteNumber(entry.price) ?? 0;
            const id = normalizeItemId(label, entry.id?.toString());
            const rawCategory = entry.category?.toString().trim().toLowerCase() ?? '';
            const inferCategory =
              id.includes('wash_fold_') || label.toLowerCase().includes('wash & fold')
                ? 'group'
                : 'unit';
            const category =
              rawCategory === 'group' || rawCategory === 'unit'
                ? (rawCategory as 'group' | 'unit')
                : inferCategory;
            const specRaw = entry.spec?.toString().trim() ?? '';
            return {
              id,
              label,
              price,
              category,
              spec: category === 'group' && specRaw.length > 0 ? specRaw : null,
            };
          })
          .filter(
            (entry) =>
              entry.id.length > 0 &&
              entry.label.length > 0 &&
              Number.isFinite(entry.price) &&
              entry.price > 0 &&
              (entry.category === 'unit' || entry.category === 'group'),
          )
          .slice(0, 24);

  const pickupSlotsRaw = Array.isArray(map.pickupSlots) ? map.pickupSlots : null;
  const pickupSlots =
    pickupSlotsRaw == null
      ? fallback.pickupSlots
      : readJsonStringArray(pickupSlotsRaw).map((entry) => entry.trim()).filter(
          (entry) => entry.length > 0,
        ).slice(0, 12);

  const turnaroundHoursRaw = toFiniteNumber(map.turnaroundHours);
  const minNoticeHoursRaw = toFiniteNumber(map.minNoticeHours);
  const maxAdvanceDaysRaw = toFiniteNumber(map.maxAdvanceDays);
  const taxRatePercentRaw = toFiniteNumber(map.taxRatePercent);
  const deliveryFeeRaw = toFiniteNumber(map.deliveryFee);

  return {
    itemCatalog: hasItemCatalog ? itemCatalog : fallback.itemCatalog,
    pickupSlots: pickupSlots.length > 0 ? pickupSlots : fallback.pickupSlots,
    turnaroundHours:
      turnaroundHoursRaw != null &&
      Number.isInteger(turnaroundHoursRaw) &&
      turnaroundHoursRaw >= 1 &&
      turnaroundHoursRaw <= 168
        ? turnaroundHoursRaw
        : fallback.turnaroundHours,
    minNoticeHours:
      minNoticeHoursRaw != null &&
      Number.isInteger(minNoticeHoursRaw) &&
      minNoticeHoursRaw >= 0 &&
      minNoticeHoursRaw <= 72
        ? minNoticeHoursRaw
        : fallback.minNoticeHours,
    maxAdvanceDays:
      maxAdvanceDaysRaw != null &&
      Number.isInteger(maxAdvanceDaysRaw) &&
      maxAdvanceDaysRaw >= 1 &&
      maxAdvanceDaysRaw <= 30
        ? maxAdvanceDaysRaw
        : fallback.maxAdvanceDays,
    taxRatePercent:
      taxRatePercentRaw != null &&
      Number.isFinite(taxRatePercentRaw) &&
      taxRatePercentRaw >= 0 &&
      taxRatePercentRaw <= 40
        ? Number(taxRatePercentRaw.toFixed(2))
        : fallback.taxRatePercent,
    deliveryFee:
      deliveryFeeRaw != null &&
      Number.isFinite(deliveryFeeRaw) &&
      deliveryFeeRaw >= 0 &&
      deliveryFeeRaw <= 100000
        ? Number(deliveryFeeRaw.toFixed(2))
        : fallback.deliveryFee,
  };
}

function serviceZoneFromAvailabilityJson(value: unknown): ServiceZoneConfig {
  const defaults: ServiceZoneConfig = {
    enabled: false,
    centerLatitude: null,
    centerLongitude: null,
    radiusKm: 1,
  };
  const map =
    value != null && typeof value === 'object' && !Array.isArray(value)
      ? (value as Record<string, unknown>)
      : {};
  const nested =
    map.serviceZone != null &&
    typeof map.serviceZone === 'object' &&
    !Array.isArray(map.serviceZone)
      ? (map.serviceZone as Record<string, unknown>)
      : {};

  const enabled =
    nested.enabled == null
      ? defaults.enabled
      : readBooleanQuery(nested.enabled);
  const centerLatitude = toFiniteNumber(
    nested.centerLatitude ?? defaults.centerLatitude,
  );
  const centerLongitude = toFiniteNumber(
    nested.centerLongitude ?? defaults.centerLongitude,
  );
  const radiusRaw = toFiniteNumber(nested.radiusKm ?? defaults.radiusKm);

  return {
    enabled,
    centerLatitude:
      centerLatitude != null && centerLatitude >= -90 && centerLatitude <= 90
        ? centerLatitude
        : defaults.centerLatitude,
    centerLongitude:
      centerLongitude != null && centerLongitude >= -180 && centerLongitude <= 180
        ? centerLongitude
        : defaults.centerLongitude,
    radiusKm:
      radiusRaw != null && radiusRaw > 0 && radiusRaw <= 120
        ? radiusRaw
        : defaults.radiusKm,
  };
}

function compareNullableNumberAsc(left: number | null, right: number | null) {
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return left - right;
}

type PharmacyGeoPoint = {
  latitude: number;
  longitude: number;
  address?: string;
};

const djiboutiPharmacyGeoByName: Record<string, PharmacyGeoPoint> = {
  'pharmacie dawo': {
    latitude: 11.5858,
    longitude: 43.1457,
    address: 'Quartier 7, Djibouti City',
  },
  gpca: {
    latitude: 11.5897,
    longitude: 43.1483,
    address: 'Plateau du Serpent, Djibouti City',
  },
  'pharmacie riyadh': {
    latitude: 11.5798,
    longitude: 43.1476,
    address: 'Riyadh District, Djibouti City',
  },
  'pharmacie du mall': {
    latitude: 11.5625,
    longitude: 43.1498,
    address: 'Djibouti Mall Area',
  },
  "grande pharmacie de la corne d'afrique": {
    latitude: 11.5719,
    longitude: 43.1436,
    address: 'La Plaine, Djibouti City',
  },
  'independence pharmacy': {
    latitude: 11.5727,
    longitude: 43.1452,
    address: 'Independence District, Djibouti City',
  },
  'pharmacie para': {
    latitude: 11.5809,
    longitude: 43.1443,
    address: 'Near Stadium, Djibouti City',
  },
  "pharmacie de l'ocean indien": {
    latitude: 11.5752,
    longitude: 43.1462,
    address: 'Central Djibouti City',
  },
  'pharmacie de la mer rouge': {
    latitude: 11.5689,
    longitude: 43.1408,
    address: 'Mer Rouge Area, Djibouti City',
  },
  'pharmacie principale': {
    latitude: 11.5668,
    longitude: 43.1439,
    address: 'Rue d Ethiopie, La Plaine',
  },
  'pharmacie polyclinique nawil': {
    latitude: 11.5846,
    longitude: 43.1524,
    address: 'Plateau du Serpent',
  },
  'pharmacie avicenne': {
    latitude: 11.5784,
    longitude: 43.1414,
    address: 'Avenue 26, Djibouti City',
  },
};

function normalizeBusinessName(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[’']/g, "'")
    .replace(/\s+/g, ' ');
}

function pharmacyGeoForBusiness(value: string): PharmacyGeoPoint | null {
  const normalized = normalizeBusinessName(value);
  return djiboutiPharmacyGeoByName[normalized] ?? null;
}

function serializeHomeServiceCategory(
  category: Awaited<ReturnType<typeof prisma.homeServiceCategory.findMany>>[number] & {
    providers?: { id: string }[];
  },
) {
  return {
    id: category.id,
    name: category.name,
    slug: category.slug,
    description: category.description,
    iconKey: category.iconKey,
    colorHex: category.colorHex,
    providerCount: category.providers?.length ?? 0,
  };
}

function serializeHomeServiceProvider(
  provider: Awaited<ReturnType<typeof prisma.homeServiceProvider.findMany>>[number] & {
    category?: {
      id: string;
      name: string;
      slug: string;
      iconKey: string;
      colorHex: string;
    } | null;
  },
) {
  return {
    id: provider.id,
    categoryId: provider.categoryId,
    category: provider.category == null
        ? null
        : {
            id: provider.category.id,
            name: provider.category.name,
            slug: provider.category.slug,
            iconKey: provider.category.iconKey,
            colorHex: provider.category.colorHex,
          },
    name: provider.name,
    title: provider.title,
    rating: toNumber(provider.rating),
    reviewCount: provider.reviewCount,
    yearsExperience: provider.yearsExperience,
    startingPrice: toNumber(provider.startingPrice),
    isAvailable: provider.isAvailable,
    isVerified: provider.isVerified,
    responseTime: provider.responseTime,
    imageUrl: provider.imageUrl,
    about: provider.about,
    location: provider.location,
    contactPhone: provider.contactPhone,
    services: readJsonStringArray(provider.servicesJson),
    highlights: readJsonStringArray(provider.highlightsJson),
    bookingModes: readJsonStringArray(provider.bookingModesJson),
    availability: provider.availabilityJson ?? {},
  };
}

function slugifyStoreName(value: string) {
  return value
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function buildHotelRoomOptions(
  basePriceRaw: Prisma.Decimal | number | null | undefined,
) {
  const basePrice = toNumber(basePriceRaw) ?? 0;
  const normalizedBasePrice = basePrice > 0 ? basePrice : 120;

  return [
    {
      id: 'standard-room',
      name: 'Standard Room',
      description: '1 Bed • City View',
      pricePerNight: Number(normalizedBasePrice.toFixed(2)),
      capacity: 2,
      available: true,
    },
    {
      id: 'premium-suite',
      name: 'Premium Suite',
      description: '1 King Bed • Balcony',
      pricePerNight: Number((normalizedBasePrice * 1.45).toFixed(2)),
      capacity: 2,
      available: true,
    },
    {
      id: 'family-suite',
      name: 'Family Suite',
      description: '2 Beds • Family Stay',
      pricePerNight: Number((normalizedBasePrice * 1.8).toFixed(2)),
      capacity: 4,
      available: true,
    },
  ];
}

function serializeProduct(product: CatalogProductWithCategory) {
  return {
    id: product.id,
    moduleType: product.moduleType,
    categoryId: product.categoryId,
    category: product.category?.name ?? product.categoryId,
    name: product.name,
    brand: product.brand,
    description: product.description,
    price: toNumber(product.price),
    originalPrice: toNumber(product.originalPrice),
    unit: product.unit,
    dosage: product.dosage,
    packageSize: product.packageSize,
    requiresPrescription: product.requiresPrescription,
    rating: toNumber(product.rating),
    reviewCount: product.reviewCount,
    images: readJsonStringArray(product.imageUrlsJson),
    colors: readJsonStringArray(product.colorsJson),
    sizes: readJsonStringArray(product.sizesJson),
    tags: readJsonStringArray(product.tagsJson),
    features: readJsonStringArray(product.featuresJson),
    badge: product.badge,
    inStock: product.inStock,
    isOrganic: product.isOrganic,
    metadata: product.metadata,
    shopId: product.shopId,
    shopName: product.shop?.name ?? product.brand,
  };
}

function serializeShoppingStore(
  store: Awaited<ReturnType<typeof prisma.shoppingStore.findMany>>[number],
  products: CatalogProductWithCategory[],
) {
  const categories = Array.from(
    new Set(
      products
        .map((item) => item.category?.name ?? item.categoryId)
        .filter((entry): entry is string => Boolean(entry)),
    ),
  );

  return {
    id: store.slug,
    name: store.name,
    tagline: store.tagline ?? 'Curated shopping picks for every style.',
    imageUrl: store.imageUrl ?? '',
    rating: toNumber(store.rating) ?? 0,
    reviewCount: store.reviewCount,
    productCount: products.length,
    categories,
    badge: store.badge,
    minPrice: toNumber(store.minPrice) ?? 0,
    maxPrice: toNumber(store.maxPrice) ?? 0,
    highlights: readJsonStringArray(store.highlightsJson),
  };
}

router.get(
  '/pharmacies',
  asyncHandler(async (req, res) => {
    const latitude = toFiniteNumber(req.query.latitude);
    const longitude = toFiniteNumber(req.query.longitude);
    const hasSearchLocation = latitude != null && longitude != null;
    const nearOnly = readBooleanQuery(req.query.nearOnly);
    const sortBy = req.query.sort?.toString().trim().toLowerCase() ?? 'distance';
    const radiusRaw = toFiniteNumber(req.query.radiusKm);
    const radiusKm =
      radiusRaw != null && radiusRaw > 0 ? Math.min(radiusRaw, 25) : 5;

    const products = await prisma.product.findMany({
      where: {
        moduleType: ModuleType.PHARMACY,
      },
      select: {
        id: true,
        name: true,
        brand: true,
        price: true,
        rating: true,
        reviewCount: true,
        requiresPrescription: true,
        metadata: true,
      },
      orderBy: [{ reviewCount: 'desc' }, { rating: 'desc' }],
    });

    const grouped = new Map<
      string,
      {
        businessName: string;
        ratingWeightedSum: number;
        ratingWeight: number;
        fallbackRatingSum: number;
        fallbackCount: number;
        reviewCount: number;
        prescriptionCount: number;
        productCount: number;
        minPrice: number | null;
      }
    >();

    for (const product of products) {
      const metadata =
        product.metadata &&
        typeof product.metadata === 'object' &&
        !Array.isArray(product.metadata)
          ? (product.metadata as Record<string, unknown>)
          : null;
      const sourceBusiness =
        metadata?.sourceBusiness?.toString().trim() ||
        product.brand?.trim() ||
        'Pharmacy';
      const key = normalizeBusinessName(sourceBusiness);
      const current =
        grouped.get(key) ??
        {
          businessName: sourceBusiness,
          ratingWeightedSum: 0,
          ratingWeight: 0,
          fallbackRatingSum: 0,
          fallbackCount: 0,
          reviewCount: 0,
          prescriptionCount: 0,
          productCount: 0,
          minPrice: null,
        };

      const rating = toNumber(product.rating) ?? 0;
      const reviewCount = product.reviewCount ?? 0;
      if (reviewCount > 0) {
        current.ratingWeightedSum += rating * reviewCount;
        current.ratingWeight += reviewCount;
      } else {
        current.fallbackRatingSum += rating;
        current.fallbackCount += 1;
      }
      current.reviewCount += reviewCount;
      current.productCount += 1;
      if (product.requiresPrescription) {
        current.prescriptionCount += 1;
      }
      const price = toNumber(product.price);
      if (price != null) {
        current.minPrice =
          current.minPrice == null ? price : Math.min(current.minPrice, price);
      }
      grouped.set(key, current);
    }

    const pharmacies = Array.from(grouped.entries())
      .map(([key, value]) => {
        const geo = pharmacyGeoForBusiness(value.businessName);
        const distanceKm =
          hasSearchLocation && geo != null
            ? haversineDistanceKm(
                geo.latitude,
                geo.longitude,
                latitude!,
                longitude!,
              )
            : null;
        const rating =
          value.ratingWeight > 0
            ? value.ratingWeightedSum / value.ratingWeight
            : value.fallbackCount > 0
            ? value.fallbackRatingSum / value.fallbackCount
            : 0;

        return {
          id: `pharmacy-${slugifyStoreName(key)}`,
          name: value.businessName,
          businessKey: key,
          rating: Number(rating.toFixed(2)),
          reviewCount: value.reviewCount,
          productCount: value.productCount,
          prescriptionCount: value.prescriptionCount,
          minPrice: value.minPrice == null ? null : Number(value.minPrice.toFixed(2)),
          location: geo == null
            ? null
            : {
                latitude: geo.latitude,
                longitude: geo.longitude,
                address: geo.address ?? null,
              },
          distanceKm:
            distanceKm == null ? null : Number(distanceKm.toFixed(3)),
        };
      })
      .filter((entry) => {
        if (!nearOnly) return true;
        return entry.distanceKm != null && entry.distanceKm <= radiusKm;
      });

    pharmacies.sort((left, right) => {
      if (sortBy === 'rating') {
        const byRating = (right.rating ?? 0) - (left.rating ?? 0);
        if (byRating !== 0) return byRating;
        const byReviews = (right.reviewCount ?? 0) - (left.reviewCount ?? 0);
        if (byReviews !== 0) return byReviews;
        return compareNullableNumberAsc(left.distanceKm, right.distanceKm);
      }
      if (sortBy === 'reviews') {
        const byReviews = (right.reviewCount ?? 0) - (left.reviewCount ?? 0);
        if (byReviews !== 0) return byReviews;
        const byRating = (right.rating ?? 0) - (left.rating ?? 0);
        if (byRating !== 0) return byRating;
        return compareNullableNumberAsc(left.distanceKm, right.distanceKm);
      }
      return compareNullableNumberAsc(left.distanceKm, right.distanceKm);
    });

    res.json(pharmacies);
  }),
);

router.get(
  '/shopping-stores',
  asyncHandler(async (_req, res) => {
    const stores = await prisma.shoppingStore.findMany({
      include: {
        products: {
          where: { moduleType: ModuleType.SHOPPING },
          include: { category: true, shop: true },
        },
      },
      orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });

    res.json(
      stores
        .map((store) => serializeShoppingStore(store, store.products))
        .filter((store) => store.productCount > 0),
    );
  }),
);

router.get(
  '/shopping-stores/:id',
  asyncHandler(async (req, res) => {
    const storeId = getParam(req.params.id, 'storeId');
    const store = await prisma.shoppingStore.findFirst({
      where: { slug: storeId },
    });
    if (!store) {
      return res.status(404).json({ error: 'Store not found.' });
    }

    const storeProducts = await prisma.product.findMany({
      where: {
        moduleType: ModuleType.SHOPPING,
        shopId: store.id,
      },
      include: { category: true, shop: true },
      orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });

    res.json({
      ...serializeShoppingStore(store, storeProducts),
      products: storeProducts.map((product) => serializeProduct(product)),
    });
  }),
);

router.get(
  '/products',
  asyncHandler(async (req, res) => {
    const moduleTypeParam = req.query.moduleType?.toString().toUpperCase();
    const moduleType = moduleTypeParam && moduleTypeParam in ModuleType
      ? (moduleTypeParam as ModuleType)
      : undefined;
    const categoryId = req.query.categoryId?.toString();

    const products = await prisma.product.findMany({
      where: {
        ...(moduleType ? { moduleType } : {}),
        ...(categoryId ? { categoryId } : {}),
      },
      include: {
        category: true,
        shop: true,
      },
      orderBy: [{ createdAt: 'desc' }],
    });

    res.json(products.map((product) => serializeProduct(product)));
  }),
);

router.get(
  '/products/:id',
  asyncHandler(async (req, res) => {
    const productId = getParam(req.params.id, 'productId');
    const product = await prisma.product.findUnique({
      where: { id: productId },
      include: {
        category: true,
        shop: true,
      },
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found.' });
    }

    res.json(serializeProduct(product as CatalogProductWithCategory));
  }),
);

router.get(
  '/doctors',
  asyncHandler(async (_req, res) => {
    const doctors = await prisma.doctor.findMany({
      orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });

    res.json(
      doctors.map((doctor) => ({
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        providerType: doctor.providerType,
        rating: toNumber(doctor.rating),
        reviewCount: doctor.reviewCount,
        experience: doctor.experience,
        consultationFee: toNumber(doctor.consultationFee),
        isAvailable: doctor.isAvailable,
        isSignedUp: doctor.isSignedUp,
        imageUrl: doctor.imageUrl,
        about: doctor.about,
        location: doctor.location,
        contactPhone: doctor.contactPhone,
        contactWhatsApp: doctor.contactWhatsApp,
        languages: doctor.languagesJson ?? [],
        services: doctor.servicesJson ?? [],
        careModes: doctor.careModesJson ?? [],
        workingHours: doctor.workingHoursJson ?? {},
      })),
    );
  }),
);

router.get(
  '/doctors/:id',
  asyncHandler(async (req, res) => {
    const doctorId = getParam(req.params.id, 'doctorId');
    const doctor = await prisma.doctor.findUnique({
      where: { id: doctorId },
      include: {
        reviews: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!doctor) {
      return res.status(404).json({ error: 'Doctor not found.' });
    }

    res.json({
      id: doctor.id,
      name: doctor.name,
      specialty: doctor.specialty,
      providerType: doctor.providerType,
      rating: toNumber(doctor.rating),
      reviewCount: doctor.reviewCount,
      experience: doctor.experience,
      consultationFee: toNumber(doctor.consultationFee),
      isAvailable: doctor.isAvailable,
      isSignedUp: doctor.isSignedUp,
      imageUrl: doctor.imageUrl,
      about: doctor.about,
      location: doctor.location,
      contactPhone: doctor.contactPhone,
      contactWhatsApp: doctor.contactWhatsApp,
      languages: doctor.languagesJson ?? [],
      services: doctor.servicesJson ?? [],
      careModes: doctor.careModesJson ?? [],
      workingHours: doctor.workingHoursJson ?? {},
      reviews: doctor.reviews.map((review) => ({
        id: review.id,
        name: review.reviewer,
        rating: review.rating,
        comment: review.comment,
        date: review.dateLabel,
        avatarUrl: review.avatarUrl,
      })),
    });
  }),
);

router.get(
  '/home-service-categories',
  asyncHandler(async (_req, res) => {
    await prisma.homeServiceCategory.upsert({
      where: { id: ECOLOGICAL_CLEANING_CATEGORY.id },
      update: ECOLOGICAL_CLEANING_CATEGORY,
      create: ECOLOGICAL_CLEANING_CATEGORY,
    });

    const categories = await prisma.homeServiceCategory.findMany({
      where: { active: true },
      include: {
        providers: {
          where: { isAvailable: true },
          select: { id: true },
        },
      },
      orderBy: { sortOrder: 'asc' },
    });

    res.json(categories.map((category) => serializeHomeServiceCategory(category)));
  }),
);

router.get(
  '/home-service-providers',
  asyncHandler(async (req, res) => {
    const categorySlug = req.query.category?.toString();
    const availableOnly = readBooleanQuery(req.query.availableOnly);
    const nearOnly = readBooleanQuery(req.query.nearOnly);
    const latitude = toFiniteNumber(req.query.latitude);
    const longitude = toFiniteNumber(req.query.longitude);
    const hasSearchLocation = latitude != null && longitude != null;
    const minRating = toFiniteNumber(req.query.minRating);
    const minReviewsRaw = toFiniteNumber(req.query.minReviews);
    const minReviews = minReviewsRaw != null ? Math.max(0, minReviewsRaw) : null;
    const sortBy = req.query.sort?.toString().trim().toLowerCase() ?? 'distance';
    const limitRaw = toFiniteNumber(req.query.limit);
    const limit = limitRaw != null ? Math.round(limitRaw) : null;
    const requestedRadiusRaw = toFiniteNumber(req.query.radiusKm);
    const requestedRadiusKm = nearOnly
      ? Math.min(Math.max(requestedRadiusRaw ?? 1, 0.1), 1)
      : requestedRadiusRaw != null && requestedRadiusRaw > 0
      ? requestedRadiusRaw
      : null;

    const providers = await prisma.homeServiceProvider.findMany({
      where: {
        ...(categorySlug
            ? {
                category: {
                  slug: categorySlug,
                },
              }
            : {}),
        ...(availableOnly ? { isAvailable: true } : {}),
      },
      include: {
        category: true,
      },
      orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });
    const mapped = providers
      .map((provider) => {
        const serialized = serializeHomeServiceProvider(provider);
        const zone = serviceZoneFromAvailabilityJson(provider.availabilityJson);
        const distanceKm =
          hasSearchLocation &&
          zone.centerLatitude != null &&
          zone.centerLongitude != null
            ? haversineDistanceKm(
                zone.centerLatitude,
                zone.centerLongitude,
                latitude!,
                longitude!,
              )
            : null;
        const withinProviderZone =
          distanceKm != null &&
          zone.enabled &&
          distanceKm <= zone.radiusKm;
        const withinRequestedRadius =
          distanceKm != null && requestedRadiusKm != null
            ? distanceKm <= requestedRadiusKm
            : null;
        const matchesNearbyScope =
          nearOnly &&
          hasSearchLocation &&
          withinProviderZone &&
          (withinRequestedRadius ?? false);

        return {
          ...serialized,
          serviceZone: zone,
          distanceKm:
            distanceKm == null ? null : Number(distanceKm.toFixed(3)),
          withinProviderZone,
          withinRequestedRadius,
          matchesNearbyScope,
        };
      })
      .filter((provider) => {
        if (minRating != null && (provider.rating ?? 0) < minRating) {
          return false;
        }
        if (minReviews != null && (provider.reviewCount ?? 0) < minReviews) {
          return false;
        }
        if (nearOnly) {
          return provider.matchesNearbyScope;
        }
        return true;
      });

    mapped.sort((left, right) => {
      if (sortBy === 'rating') {
        const ratingDiff = (right.rating ?? 0) - (left.rating ?? 0);
        if (ratingDiff !== 0) return ratingDiff;
        const reviewsDiff = (right.reviewCount ?? 0) - (left.reviewCount ?? 0);
        if (reviewsDiff !== 0) return reviewsDiff;
        return compareNullableNumberAsc(left.distanceKm, right.distanceKm);
      }
      if (sortBy === 'reviews') {
        const reviewsDiff = (right.reviewCount ?? 0) - (left.reviewCount ?? 0);
        if (reviewsDiff !== 0) return reviewsDiff;
        const ratingDiff = (right.rating ?? 0) - (left.rating ?? 0);
        if (ratingDiff !== 0) return ratingDiff;
        return compareNullableNumberAsc(left.distanceKm, right.distanceKm);
      }
      const distanceDiff = compareNullableNumberAsc(
        left.distanceKm,
        right.distanceKm,
      );
      if (distanceDiff !== 0) return distanceDiff;
      const ratingDiff = (right.rating ?? 0) - (left.rating ?? 0);
      if (ratingDiff !== 0) return ratingDiff;
      return (right.reviewCount ?? 0) - (left.reviewCount ?? 0);
    });

    const limited =
      limit != null && limit > 0 ? mapped.slice(0, limit) : mapped;
    res.json(
      limited.map(({ matchesNearbyScope, ...provider }) => provider),
    );
  }),
);

router.get(
  '/home-service-providers/:id',
  asyncHandler(async (req, res) => {
    const providerId = getParam(req.params.id, 'providerId');
    const provider = await prisma.homeServiceProvider.findUnique({
      where: { id: providerId },
      include: {
        category: true,
      },
    });

    if (!provider) {
      return res.status(404).json({ error: 'Home service provider not found.' });
    }

    res.json(serializeHomeServiceProvider(provider));
  }),
);

router.get(
  '/restaurants',
  asyncHandler(async (_req, res) => {
    const restaurants = await prisma.restaurant.findMany({
      include: {
        menuCategories: {
          orderBy: { sortOrder: 'asc' },
          include: { items: true },
        },
      },
      orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });

    res.json(
      restaurants.map((restaurant) => {
        const tags = readJsonStringArray(restaurant.tagsJson);
        return {
          id: restaurant.id,
          name: restaurant.name,
          cuisine: restaurant.cuisine,
          category: tags[0] ?? 'International & Other',
          rating: toNumber(restaurant.rating),
          reviewCount: restaurant.reviewCount,
          deliveryTime: restaurant.deliveryTime,
          deliveryFee: toNumber(restaurant.deliveryFee),
          imageUrl: restaurant.imageUrl,
          isOpen: restaurant.isOpen,
          distance: toNumber(restaurant.distanceKm),
          tags,
          menu: restaurant.menuCategories.map((category) => ({
            name: category.name,
            items: category.items.map((item) => ({
              id: item.id,
              name: item.name,
              description: item.description,
              price: toNumber(item.price),
              imageUrl: item.imageUrl,
              isPopular: item.isPopular,
              isAvailable: item.isAvailable,
              customizations: item.customizationsJson ?? [],
            })),
          })),
        };
      }),
    );
  }),
);

router.get(
  '/restaurants/:id',
  asyncHandler(async (req, res) => {
    const restaurantId = getParam(req.params.id, 'restaurantId');
    const restaurant = await prisma.restaurant.findUnique({
      where: { id: restaurantId },
      include: {
        menuCategories: {
          orderBy: { sortOrder: 'asc' },
          include: { items: true },
        },
      },
    });

    if (!restaurant) {
      return res.status(404).json({ error: 'Restaurant not found.' });
    }

    const tags = readJsonStringArray(restaurant.tagsJson);
    res.json({
      id: restaurant.id,
      name: restaurant.name,
      cuisine: restaurant.cuisine,
      category: tags[0] ?? 'International & Other',
      rating: toNumber(restaurant.rating),
      reviewCount: restaurant.reviewCount,
      deliveryTime: restaurant.deliveryTime,
      deliveryFee: toNumber(restaurant.deliveryFee),
      imageUrl: restaurant.imageUrl,
      isOpen: restaurant.isOpen,
      distance: toNumber(restaurant.distanceKm),
      tags,
      menu: restaurant.menuCategories.map((category) => ({
        name: category.name,
        items: category.items.map((item) => ({
          id: item.id,
          name: item.name,
          description: item.description,
          price: toNumber(item.price),
          imageUrl: item.imageUrl,
          isPopular: item.isPopular,
          isAvailable: item.isAvailable,
          customizations: item.customizationsJson ?? [],
        })),
      })),
    });
  }),
);

router.get(
  '/hotels',
  asyncHandler(async (_req, res) => {
    const hotels = await prisma.hotel.findMany({
      orderBy: [{ rating: 'desc' }, { reviewsCount: 'desc' }],
    });

    res.json(
      hotels.map((hotel) => ({
        id: hotel.id,
        name: hotel.name,
        address: hotel.address,
        city: hotel.city,
        rating: toNumber(hotel.rating),
        reviewsCount: hotel.reviewsCount,
        pricePerNight: toNumber(hotel.pricePerNight),
        amenities: hotel.amenitiesJson ?? [],
        description: hotel.description,
        imageUrls: hotel.imageUrlsJson ?? [],
        roomOptions: buildHotelRoomOptions(hotel.pricePerNight),
      })),
    );
  }),
);

router.get(
  '/hotels/:id',
  asyncHandler(async (req, res) => {
    const hotelId = getParam(req.params.id, 'hotelId');
    const hotel = await prisma.hotel.findUnique({
      where: { id: hotelId },
    });

    if (!hotel) {
      return res.status(404).json({ error: 'Hotel not found.' });
    }

    res.json({
      id: hotel.id,
      name: hotel.name,
      address: hotel.address,
      city: hotel.city,
      rating: toNumber(hotel.rating),
      reviewsCount: hotel.reviewsCount,
      pricePerNight: toNumber(hotel.pricePerNight),
      amenities: hotel.amenitiesJson ?? [],
      description: hotel.description,
      imageUrls: hotel.imageUrlsJson ?? [],
      roomOptions: buildHotelRoomOptions(hotel.pricePerNight),
    });
  }),
);

router.get(
  '/ride-categories',
  asyncHandler(async (_req, res) => {
    const categories = await prisma.rideCategory.findMany({
      where: { active: true },
      orderBy: { createdAt: 'desc' },
    });

    res.json(
      categories.map((category) => ({
        id: category.id,
        name: category.name,
        description: category.description,
        capacity: category.capacity,
        basePrice: toNumber(category.basePrice),
        pricePerMile: toNumber(category.pricePerKm),
        timeToArrive: category.etaLabel,
      })),
    );
  }),
);

router.get(
  '/laundry-services',
  asyncHandler(async (_req, res) => {
    const services = await prisma.laundryService.findMany({
      where: { active: true },
      select: {
        id: true,
        name: true,
        description: true,
        price: true,
        unit: true,
        iconUrl: true,
        bookingConfigJson: true,
        providerUser: {
          select: {
            firstName: true,
            lastName: true,
            proProfile: {
              select: {
                businessName: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(
      services.map((service) => {
        const price = toNumber(service.price) ?? 0;
        const businessName = service.providerUser?.proProfile?.businessName?.trim() ?? '';
        const ownerName = `${service.providerUser?.firstName ?? ''} ${service.providerUser?.lastName ?? ''}`.trim();
        const profileName = businessName.length > 0
          ? businessName
          : ownerName.length > 0
            ? ownerName
            : null;
        const bookingFallback =
          service.bookingConfigJson == null
            ? unconfiguredLaundryCatalogBookingConfig(price)
            : defaultLaundryCatalogBookingConfig(price);
        return {
          id: service.id,
          name: service.name,
          profileName,
          description: service.description,
          price,
          unit: service.unit,
          iconUrl: service.iconUrl,
          bookingConfig: normalizeLaundryCatalogBookingConfig(
            service.bookingConfigJson,
            bookingFallback,
          ),
        };
      }),
    );
  }),
);

// Health Services Routes
router.get('/health-services/categories', asyncHandler(async (req, res) => {
  const categories = await prisma.healthServiceCategory.findMany({
    where: { active: true },
    orderBy: { sortOrder: 'asc' },
    select: {
      id: true,
      name: true,
      slug: true,
      description: true,
      iconKey: true,
      colorHex: true,
    },
  });

  res.json(categories);
}));

router.get('/health-services/tests', asyncHandler(async (req, res) => {
  const { categoryId } = req.query;

  const where: Prisma.LabTestWhereInput = {
    active: true,
    ...(categoryId ? { categoryId: categoryId as string } : {}),
  };

  const tests = await prisma.labTest.findMany({
    where,
    orderBy: { sortOrder: 'asc' },
    include: {
      category: {
        select: {
          id: true,
          name: true,
          iconKey: true,
          colorHex: true,
        },
      },
    },
  });

  res.json(
    tests.map((test) => ({
      id: test.id,
      categoryId: test.categoryId,
      name: test.name,
      description: test.description,
      fullDescription: test.fullDescription,
      price: test.price,
      originalPrice: test.originalPrice,
      preparationInstructions: test.preparationInstructions,
      sampleType: test.sampleType,
      durationLabel: test.durationLabel,
      imageUrl: test.imageUrl,
      active: test.active,
      sortOrder: test.sortOrder,
    })),
  );
}));

export default router;
