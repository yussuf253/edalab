import { ModuleType } from '@prisma/client';
import { Router } from 'express';
import { prisma } from '../db';
import { asyncHandler } from '../utils/async-handler';
import { getParam } from '../utils/http';
import { toNumber } from '../utils/serializers';

const router = Router();

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
      },
      orderBy: [{ createdAt: 'desc' }],
    });

    res.json(
      products.map((product) => ({
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
        images: product.imageUrlsJson ?? [],
        colors: product.colorsJson ?? [],
        sizes: product.sizesJson ?? [],
        tags: product.tagsJson ?? [],
        features: product.featuresJson ?? [],
        badge: product.badge,
        inStock: product.inStock,
        isOrganic: product.isOrganic,
        metadata: product.metadata,
      })),
    );
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
      },
    });

    if (!product) {
      return res.status(404).json({ error: 'Product not found.' });
    }

    res.json({
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
      images: product.imageUrlsJson ?? [],
      colors: product.colorsJson ?? [],
      sizes: product.sizesJson ?? [],
      tags: product.tagsJson ?? [],
      features: product.featuresJson ?? [],
      badge: product.badge,
      inStock: product.inStock,
      isOrganic: product.isOrganic,
      metadata: product.metadata,
    });
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
        rating: toNumber(doctor.rating),
        reviewCount: doctor.reviewCount,
        experience: doctor.experience,
        consultationFee: toNumber(doctor.consultationFee),
        isAvailable: doctor.isAvailable,
        imageUrl: doctor.imageUrl,
        about: doctor.about,
        location: doctor.location,
        languages: doctor.languagesJson ?? [],
        services: doctor.servicesJson ?? [],
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
      rating: toNumber(doctor.rating),
      reviewCount: doctor.reviewCount,
      experience: doctor.experience,
      consultationFee: toNumber(doctor.consultationFee),
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
