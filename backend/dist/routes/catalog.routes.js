"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const express_1 = require("express");
const db_1 = require("../db");
const async_handler_1 = require("../utils/async-handler");
const http_1 = require("../utils/http");
const serializers_1 = require("../utils/serializers");
const router = (0, express_1.Router)();
function readJsonStringArray(value) {
    if (!Array.isArray(value)) {
        return [];
    }
    return value
        .map((entry) => (typeof entry === 'string' ? entry : null))
        .filter((entry) => entry != null);
}
function toFiniteNumber(value) {
    if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
    }
    if (typeof value === 'string' && value.trim().length > 0) {
        const parsed = Number(value);
        return Number.isFinite(parsed) ? parsed : null;
    }
    return null;
}
function readBooleanQuery(value) {
    const normalized = value?.toString().trim().toLowerCase();
    return (normalized === '1' ||
        normalized === 'true' ||
        normalized === 'yes' ||
        normalized === 'y');
}
function toRadians(value) {
    return (value * Math.PI) / 180;
}
function haversineDistanceKm(startLatitude, startLongitude, endLatitude, endLongitude) {
    const earthRadiusKm = 6371;
    const latitudeDelta = toRadians(endLatitude - startLatitude);
    const longitudeDelta = toRadians(endLongitude - startLongitude);
    const startLatRad = toRadians(startLatitude);
    const endLatRad = toRadians(endLatitude);
    const a = Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
        Math.cos(startLatRad) *
            Math.cos(endLatRad) *
            Math.sin(longitudeDelta / 2) *
            Math.sin(longitudeDelta / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return earthRadiusKm * c;
}
function serviceZoneFromAvailabilityJson(value) {
    const defaults = {
        enabled: false,
        centerLatitude: null,
        centerLongitude: null,
        radiusKm: 1,
    };
    const map = value != null && typeof value === 'object' && !Array.isArray(value)
        ? value
        : {};
    const nested = map.serviceZone != null &&
        typeof map.serviceZone === 'object' &&
        !Array.isArray(map.serviceZone)
        ? map.serviceZone
        : {};
    const enabled = nested.enabled == null
        ? defaults.enabled
        : readBooleanQuery(nested.enabled);
    const centerLatitude = toFiniteNumber(nested.centerLatitude ?? defaults.centerLatitude);
    const centerLongitude = toFiniteNumber(nested.centerLongitude ?? defaults.centerLongitude);
    const radiusRaw = toFiniteNumber(nested.radiusKm ?? defaults.radiusKm);
    return {
        enabled,
        centerLatitude: centerLatitude != null && centerLatitude >= -90 && centerLatitude <= 90
            ? centerLatitude
            : defaults.centerLatitude,
        centerLongitude: centerLongitude != null && centerLongitude >= -180 && centerLongitude <= 180
            ? centerLongitude
            : defaults.centerLongitude,
        radiusKm: radiusRaw != null && radiusRaw > 0 && radiusRaw <= 120
            ? radiusRaw
            : defaults.radiusKm,
    };
}
function compareNullableNumberAsc(left, right) {
    if (left == null && right == null)
        return 0;
    if (left == null)
        return 1;
    if (right == null)
        return -1;
    return left - right;
}
function serializeHomeServiceCategory(category) {
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
function serializeHomeServiceProvider(provider) {
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
        rating: (0, serializers_1.toNumber)(provider.rating),
        reviewCount: provider.reviewCount,
        yearsExperience: provider.yearsExperience,
        startingPrice: (0, serializers_1.toNumber)(provider.startingPrice),
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
function slugifyStoreName(value) {
    return value
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
}
function buildHotelRoomOptions(basePriceRaw) {
    const basePrice = (0, serializers_1.toNumber)(basePriceRaw) ?? 0;
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
function serializeProduct(product) {
    return {
        id: product.id,
        moduleType: product.moduleType,
        categoryId: product.categoryId,
        category: product.category?.name ?? product.categoryId,
        name: product.name,
        brand: product.brand,
        description: product.description,
        price: (0, serializers_1.toNumber)(product.price),
        originalPrice: (0, serializers_1.toNumber)(product.originalPrice),
        unit: product.unit,
        dosage: product.dosage,
        packageSize: product.packageSize,
        requiresPrescription: product.requiresPrescription,
        rating: (0, serializers_1.toNumber)(product.rating),
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
function serializeShoppingStore(store, products) {
    const categories = Array.from(new Set(products
        .map((item) => item.category?.name ?? item.categoryId)
        .filter((entry) => Boolean(entry))));
    return {
        id: store.slug,
        name: store.name,
        tagline: store.tagline ?? 'Curated shopping picks for every style.',
        imageUrl: store.imageUrl ?? '',
        rating: (0, serializers_1.toNumber)(store.rating) ?? 0,
        reviewCount: store.reviewCount,
        productCount: products.length,
        categories,
        badge: store.badge,
        minPrice: (0, serializers_1.toNumber)(store.minPrice) ?? 0,
        maxPrice: (0, serializers_1.toNumber)(store.maxPrice) ?? 0,
        highlights: readJsonStringArray(store.highlightsJson),
    };
}
router.get('/shopping-stores', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const stores = await db_1.prisma.shoppingStore.findMany({
        include: {
            products: {
                where: { moduleType: client_1.ModuleType.SHOPPING },
                include: { category: true, shop: true },
            },
        },
        orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });
    res.json(stores
        .map((store) => serializeShoppingStore(store, store.products))
        .filter((store) => store.productCount > 0));
}));
router.get('/shopping-stores/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const storeId = (0, http_1.getParam)(req.params.id, 'storeId');
    const store = await db_1.prisma.shoppingStore.findFirst({
        where: { slug: storeId },
    });
    if (!store) {
        return res.status(404).json({ error: 'Store not found.' });
    }
    const storeProducts = await db_1.prisma.product.findMany({
        where: {
            moduleType: client_1.ModuleType.SHOPPING,
            shopId: store.id,
        },
        include: { category: true, shop: true },
        orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });
    res.json({
        ...serializeShoppingStore(store, storeProducts),
        products: storeProducts.map((product) => serializeProduct(product)),
    });
}));
router.get('/products', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const moduleTypeParam = req.query.moduleType?.toString().toUpperCase();
    const moduleType = moduleTypeParam && moduleTypeParam in client_1.ModuleType
        ? moduleTypeParam
        : undefined;
    const categoryId = req.query.categoryId?.toString();
    const products = await db_1.prisma.product.findMany({
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
}));
router.get('/products/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const productId = (0, http_1.getParam)(req.params.id, 'productId');
    const product = await db_1.prisma.product.findUnique({
        where: { id: productId },
        include: {
            category: true,
            shop: true,
        },
    });
    if (!product) {
        return res.status(404).json({ error: 'Product not found.' });
    }
    res.json(serializeProduct(product));
}));
router.get('/doctors', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const doctors = await db_1.prisma.doctor.findMany({
        orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });
    res.json(doctors.map((doctor) => ({
        id: doctor.id,
        name: doctor.name,
        specialty: doctor.specialty,
        providerType: doctor.providerType,
        rating: (0, serializers_1.toNumber)(doctor.rating),
        reviewCount: doctor.reviewCount,
        experience: doctor.experience,
        consultationFee: (0, serializers_1.toNumber)(doctor.consultationFee),
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
    })));
}));
router.get('/doctors/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const doctorId = (0, http_1.getParam)(req.params.id, 'doctorId');
    const doctor = await db_1.prisma.doctor.findUnique({
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
        rating: (0, serializers_1.toNumber)(doctor.rating),
        reviewCount: doctor.reviewCount,
        experience: doctor.experience,
        consultationFee: (0, serializers_1.toNumber)(doctor.consultationFee),
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
}));
router.get('/home-service-categories', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const categories = await db_1.prisma.homeServiceCategory.findMany({
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
}));
router.get('/home-service-providers', (0, async_handler_1.asyncHandler)(async (req, res) => {
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
    const providers = await db_1.prisma.homeServiceProvider.findMany({
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
        const distanceKm = hasSearchLocation &&
            zone.centerLatitude != null &&
            zone.centerLongitude != null
            ? haversineDistanceKm(zone.centerLatitude, zone.centerLongitude, latitude, longitude)
            : null;
        const withinProviderZone = distanceKm != null &&
            zone.enabled &&
            distanceKm <= zone.radiusKm;
        const withinRequestedRadius = distanceKm != null && requestedRadiusKm != null
            ? distanceKm <= requestedRadiusKm
            : null;
        const matchesNearbyScope = nearOnly &&
            hasSearchLocation &&
            withinProviderZone &&
            (withinRequestedRadius ?? false);
        return {
            ...serialized,
            serviceZone: zone,
            distanceKm: distanceKm == null ? null : Number(distanceKm.toFixed(3)),
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
            if (ratingDiff !== 0)
                return ratingDiff;
            const reviewsDiff = (right.reviewCount ?? 0) - (left.reviewCount ?? 0);
            if (reviewsDiff !== 0)
                return reviewsDiff;
            return compareNullableNumberAsc(left.distanceKm, right.distanceKm);
        }
        if (sortBy === 'reviews') {
            const reviewsDiff = (right.reviewCount ?? 0) - (left.reviewCount ?? 0);
            if (reviewsDiff !== 0)
                return reviewsDiff;
            const ratingDiff = (right.rating ?? 0) - (left.rating ?? 0);
            if (ratingDiff !== 0)
                return ratingDiff;
            return compareNullableNumberAsc(left.distanceKm, right.distanceKm);
        }
        const distanceDiff = compareNullableNumberAsc(left.distanceKm, right.distanceKm);
        if (distanceDiff !== 0)
            return distanceDiff;
        const ratingDiff = (right.rating ?? 0) - (left.rating ?? 0);
        if (ratingDiff !== 0)
            return ratingDiff;
        return (right.reviewCount ?? 0) - (left.reviewCount ?? 0);
    });
    const limited = limit != null && limit > 0 ? mapped.slice(0, limit) : mapped;
    res.json(limited.map(({ matchesNearbyScope, ...provider }) => provider));
}));
router.get('/home-service-providers/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const providerId = (0, http_1.getParam)(req.params.id, 'providerId');
    const provider = await db_1.prisma.homeServiceProvider.findUnique({
        where: { id: providerId },
        include: {
            category: true,
        },
    });
    if (!provider) {
        return res.status(404).json({ error: 'Home service provider not found.' });
    }
    res.json(serializeHomeServiceProvider(provider));
}));
router.get('/restaurants', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const restaurants = await db_1.prisma.restaurant.findMany({
        include: {
            menuCategories: {
                orderBy: { sortOrder: 'asc' },
                include: { items: true },
            },
        },
        orderBy: [{ rating: 'desc' }, { reviewCount: 'desc' }],
    });
    res.json(restaurants.map((restaurant) => ({
        id: restaurant.id,
        name: restaurant.name,
        cuisine: restaurant.cuisine,
        rating: (0, serializers_1.toNumber)(restaurant.rating),
        reviewCount: restaurant.reviewCount,
        deliveryTime: restaurant.deliveryTime,
        deliveryFee: (0, serializers_1.toNumber)(restaurant.deliveryFee),
        imageUrl: restaurant.imageUrl,
        isOpen: restaurant.isOpen,
        distance: (0, serializers_1.toNumber)(restaurant.distanceKm),
        tags: restaurant.tagsJson ?? [],
        menu: restaurant.menuCategories.map((category) => ({
            name: category.name,
            items: category.items.map((item) => ({
                id: item.id,
                name: item.name,
                description: item.description,
                price: (0, serializers_1.toNumber)(item.price),
                imageUrl: item.imageUrl,
                isPopular: item.isPopular,
                isAvailable: item.isAvailable,
                customizations: item.customizationsJson ?? [],
            })),
        })),
    })));
}));
router.get('/restaurants/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const restaurantId = (0, http_1.getParam)(req.params.id, 'restaurantId');
    const restaurant = await db_1.prisma.restaurant.findUnique({
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
        rating: (0, serializers_1.toNumber)(restaurant.rating),
        reviewCount: restaurant.reviewCount,
        deliveryTime: restaurant.deliveryTime,
        deliveryFee: (0, serializers_1.toNumber)(restaurant.deliveryFee),
        imageUrl: restaurant.imageUrl,
        isOpen: restaurant.isOpen,
        distance: (0, serializers_1.toNumber)(restaurant.distanceKm),
        tags: restaurant.tagsJson ?? [],
        menu: restaurant.menuCategories.map((category) => ({
            name: category.name,
            items: category.items.map((item) => ({
                id: item.id,
                name: item.name,
                description: item.description,
                price: (0, serializers_1.toNumber)(item.price),
                imageUrl: item.imageUrl,
                isPopular: item.isPopular,
                isAvailable: item.isAvailable,
                customizations: item.customizationsJson ?? [],
            })),
        })),
    });
}));
router.get('/hotels', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const hotels = await db_1.prisma.hotel.findMany({
        orderBy: [{ rating: 'desc' }, { reviewsCount: 'desc' }],
    });
    res.json(hotels.map((hotel) => ({
        id: hotel.id,
        name: hotel.name,
        address: hotel.address,
        city: hotel.city,
        rating: (0, serializers_1.toNumber)(hotel.rating),
        reviewsCount: hotel.reviewsCount,
        pricePerNight: (0, serializers_1.toNumber)(hotel.pricePerNight),
        amenities: hotel.amenitiesJson ?? [],
        description: hotel.description,
        imageUrls: hotel.imageUrlsJson ?? [],
        roomOptions: buildHotelRoomOptions(hotel.pricePerNight),
    })));
}));
router.get('/hotels/:id', (0, async_handler_1.asyncHandler)(async (req, res) => {
    const hotelId = (0, http_1.getParam)(req.params.id, 'hotelId');
    const hotel = await db_1.prisma.hotel.findUnique({
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
        rating: (0, serializers_1.toNumber)(hotel.rating),
        reviewsCount: hotel.reviewsCount,
        pricePerNight: (0, serializers_1.toNumber)(hotel.pricePerNight),
        amenities: hotel.amenitiesJson ?? [],
        description: hotel.description,
        imageUrls: hotel.imageUrlsJson ?? [],
        roomOptions: buildHotelRoomOptions(hotel.pricePerNight),
    });
}));
router.get('/ride-categories', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const categories = await db_1.prisma.rideCategory.findMany({
        where: { active: true },
        orderBy: { createdAt: 'asc' },
    });
    res.json(categories.map((category) => ({
        id: category.id,
        name: category.name,
        description: category.description,
        capacity: category.capacity,
        basePrice: (0, serializers_1.toNumber)(category.basePrice),
        pricePerMile: (0, serializers_1.toNumber)(category.pricePerKm),
        timeToArrive: category.etaLabel,
    })));
}));
router.get('/laundry-services', (0, async_handler_1.asyncHandler)(async (_req, res) => {
    const services = await db_1.prisma.laundryService.findMany({
        where: { active: true },
        orderBy: { createdAt: 'asc' },
    });
    res.json(services.map((service) => ({
        id: service.id,
        name: service.name,
        description: service.description,
        price: (0, serializers_1.toNumber)(service.price),
        unit: service.unit,
        iconUrl: service.iconUrl,
    })));
}));
exports.default = router;
