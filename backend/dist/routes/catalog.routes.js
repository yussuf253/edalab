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
function slugifyStoreName(value) {
    return value
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '-')
        .replace(/^-+|-+$/g, '');
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
        rating: (0, serializers_1.toNumber)(doctor.rating),
        reviewCount: doctor.reviewCount,
        experience: doctor.experience,
        consultationFee: (0, serializers_1.toNumber)(doctor.consultationFee),
        isAvailable: doctor.isAvailable,
        imageUrl: doctor.imageUrl,
        about: doctor.about,
        location: doctor.location,
        languages: doctor.languagesJson ?? [],
        services: doctor.servicesJson ?? [],
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
        rating: (0, serializers_1.toNumber)(doctor.rating),
        reviewCount: doctor.reviewCount,
        experience: doctor.experience,
        consultationFee: (0, serializers_1.toNumber)(doctor.consultationFee),
        isAvailable: doctor.isAvailable,
        imageUrl: doctor.imageUrl,
        about: doctor.about,
        location: doctor.location,
        languages: doctor.languagesJson ?? [],
        services: doctor.servicesJson ?? [],
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
