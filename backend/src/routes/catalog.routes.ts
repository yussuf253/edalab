import { ModuleType, Prisma } from '@prisma/client';
import { Router } from 'express';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { toNumber } from '../utils/serializers';

const router = Router();

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
    const providers = await prisma.homeServiceProvider.findMany({
      where: {
        ...(categorySlug
            ? {
                category: {
                  slug: categorySlug,
                },
              }
            : {}),
      },
      include: {
        category: true,
      },
      orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });

    res.json(providers.map((provider) => serializeHomeServiceProvider(provider)));
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
      restaurants.map((restaurant) => ({
        id: restaurant.id,
        name: restaurant.name,
        cuisine: restaurant.cuisine,
        rating: toNumber(restaurant.rating),
        reviewCount: restaurant.reviewCount,
        deliveryTime: restaurant.deliveryTime,
        deliveryFee: toNumber(restaurant.deliveryFee),
        imageUrl: restaurant.imageUrl,
        isOpen: restaurant.isOpen,
        distance: toNumber(restaurant.distanceKm),
        tags: restaurant.tagsJson ?? [],
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
      })),
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

    res.json({
      id: restaurant.id,
      name: restaurant.name,
      cuisine: restaurant.cuisine,
      rating: toNumber(restaurant.rating),
      reviewCount: restaurant.reviewCount,
      deliveryTime: restaurant.deliveryTime,
      deliveryFee: toNumber(restaurant.deliveryFee),
      imageUrl: restaurant.imageUrl,
      isOpen: restaurant.isOpen,
      distance: toNumber(restaurant.distanceKm),
      tags: restaurant.tagsJson ?? [],
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
      orderBy: { createdAt: 'asc' },
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
      orderBy: { createdAt: 'asc' },
    });

    res.json(
      services.map((service) => ({
        id: service.id,
        name: service.name,
        description: service.description,
        price: toNumber(service.price),
        unit: service.unit,
        iconUrl: service.iconUrl,
      })),
    );
  }),
);

export default router;
