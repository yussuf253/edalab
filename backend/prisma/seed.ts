import { ModuleType, PaymentMethodType, PrismaClient } from '@prisma/client';
import {
  djiboutiDoctors,
  djiboutiHomeServiceCategories,
  djiboutiHomeServiceProviders,
  djiboutiHotels,
  djiboutiLaundryServices,
  djiboutiPharmacyProducts,
  djiboutiRestaurantMenuCategories,
  djiboutiRestaurantMenuItems,
  djiboutiRestaurants,
  djiboutiShoppingProducts,
  djiboutiShoppingStores,
} from './djiboutiSeedData';
import { hashPassword } from '../src/utils/password';

const prisma = new PrismaClient();

async function seedUsers() {
  const passwordHash = await hashPassword('Password123');

  const user = await prisma.user.upsert({
    where: { email: 'demo@edalab.com' },
    update: {
      firstName: 'Demo',
      lastName: 'User',
      phone: '+253777000111',
      passwordHash,
      points: 2450,
    },
    create: {
      email: 'demo@edalab.com',
      passwordHash,
      firstName: 'Demo',
      lastName: 'User',
      phone: '+253777000111',
      points: 2450,
    },
  });

  await prisma.address.upsert({
    where: { id: 'addr_demo_home' },
    update: {
      userId: user.id,
      label: 'Home',
      line1: '123 Main Street',
      city: 'Djibouti',
      postalCode: '00000',
      country: 'DJ',
      isDefault: true,
    },
    create: {
      id: 'addr_demo_home',
      userId: user.id,
      label: 'Home',
      line1: '123 Main Street',
      city: 'Djibouti',
      postalCode: '00000',
      country: 'DJ',
      isDefault: true,
    },
  });

  await prisma.paymentMethod.upsert({
    where: { id: 'pm_demo_card' },
    update: {
      userId: user.id,
      type: PaymentMethodType.CARD,
      brand: 'Visa',
      last4: '4242',
      expiryMonth: 12,
      expiryYear: 2028,
      isDefault: true,
    },
    create: {
      id: 'pm_demo_card',
      userId: user.id,
      type: PaymentMethodType.CARD,
      brand: 'Visa',
      last4: '4242',
      expiryMonth: 12,
      expiryYear: 2028,
      isDefault: true,
    },
  });
}

async function seedAppModules() {
  const modules = [
    {
      id: 'module-shopping',
      moduleType: ModuleType.SHOPPING,
      name: 'Shopping',
      slug: 'shopping',
      active: true,
      sortOrder: 1,
    },
    {
      id: 'module-food',
      moduleType: ModuleType.FOOD,
      name: 'Food',
      slug: 'food',
      active: true,
      sortOrder: 2,
    },
    {
      id: 'module-doctor',
      moduleType: ModuleType.DOCTOR,
      name: 'Doctor',
      slug: 'doctor',
      active: true,
      sortOrder: 3,
    },
    {
      id: 'module-hotel',
      moduleType: ModuleType.HOTEL,
      name: 'Hotel',
      slug: 'hotel',
      active: true,
      sortOrder: 4,
    },
    {
      id: 'module-ride',
      moduleType: ModuleType.RIDE,
      name: 'Ride',
      slug: 'ride',
      active: true,
      sortOrder: 5,
    },
    {
      id: 'module-pharmacy',
      moduleType: ModuleType.PHARMACY,
      name: 'Pharmacy',
      slug: 'pharmacy',
      active: true,
      sortOrder: 6,
    },
    {
      id: 'module-grocery',
      moduleType: ModuleType.GROCERY,
      name: 'Grocery',
      slug: 'grocery',
      active: true,
      sortOrder: 7,
    },
    {
      id: 'module-home-services',
      moduleType: ModuleType.HOME_SERVICES,
      name: 'Home Services',
      slug: 'home-services',
      active: true,
      sortOrder: 8,
    },
    {
      id: 'module-laundry',
      moduleType: ModuleType.LAUNDRY,
      name: 'Laundry',
      slug: 'laundry',
      active: true,
      sortOrder: 9,
    },
  ];

  for (const module of modules) {
    await prisma.appModule.upsert({
      where: { moduleType: module.moduleType },
      update: {
        name: module.name,
        slug: module.slug,
        active: module.active,
        sortOrder: module.sortOrder,
      },
      create: module,
    });
  }
}

async function seedCategories() {
  const categories = [
    { id: 'shopping-shoes', moduleType: ModuleType.SHOPPING, name: 'Shoes', slug: 'shopping-shoes', sortOrder: 1 },
    { id: 'shopping-electronics', moduleType: ModuleType.SHOPPING, name: 'Electronics', slug: 'shopping-electronics', sortOrder: 2 },
    { id: 'shopping-clothing', moduleType: ModuleType.SHOPPING, name: 'Clothing', slug: 'shopping-clothing', sortOrder: 3 },
    { id: 'shopping-home', moduleType: ModuleType.SHOPPING, name: 'Home', slug: 'shopping-home', sortOrder: 4 },
    { id: 'shopping-accessories', moduleType: ModuleType.SHOPPING, name: 'Accessories', slug: 'shopping-accessories', sortOrder: 5 },
    { id: 'grocery-fruits-veg', moduleType: ModuleType.GROCERY, name: 'Fruits & Veg', slug: 'grocery-fruits-veg', sortOrder: 1 },
    { id: 'grocery-dairy-eggs', moduleType: ModuleType.GROCERY, name: 'Dairy & Eggs', slug: 'grocery-dairy-eggs', sortOrder: 2 },
    { id: 'grocery-meat-seafood', moduleType: ModuleType.GROCERY, name: 'Meat & Seafood', slug: 'grocery-meat-seafood', sortOrder: 3 },
    { id: 'grocery-bakery', moduleType: ModuleType.GROCERY, name: 'Bakery', slug: 'grocery-bakery', sortOrder: 4 },
    { id: 'pharmacy-pain-relief', moduleType: ModuleType.PHARMACY, name: 'Pain Relief', slug: 'pharmacy-pain-relief', sortOrder: 1 },
    { id: 'pharmacy-antibiotics', moduleType: ModuleType.PHARMACY, name: 'Antibiotics', slug: 'pharmacy-antibiotics', sortOrder: 2 },
    { id: 'pharmacy-vitamins', moduleType: ModuleType.PHARMACY, name: 'Vitamins', slug: 'pharmacy-vitamins', sortOrder: 3 },
    { id: 'pharmacy-cold-flu', moduleType: ModuleType.PHARMACY, name: 'Cold & Flu', slug: 'pharmacy-cold-flu', sortOrder: 4 },
  ];

  for (const category of categories) {
    await prisma.productCategory.upsert({
      where: { id: category.id },
      update: category,
      create: category,
    });
  }
}

async function seedShoppingStores() {
  await prisma.shoppingStore.deleteMany({
    where: {
      id: {
        in: ['store-nike', 'store-apple', 'store-levis', 'store-samsung', 'store-ray-ban', 'store-dyson'],
      },
    },
  });

  for (const store of djiboutiShoppingStores) {
    await prisma.shoppingStore.upsert({
      where: { id: store.id },
      update: store,
      create: store,
    });
  }
}

async function seedProducts() {
  const products = [
    ...djiboutiShoppingProducts,
    {
      id: 'g1',
      moduleType: ModuleType.GROCERY,
      categoryId: 'grocery-fruits-veg',
      name: 'Fresh Organic Bananas',
      brand: null,
      description: 'Sweet, organic bananas perfect for snacking.',
      price: 2.99,
      originalPrice: null,
      rating: 4.8,
      reviewCount: 0,
      unit: 'bunch',
      imageUrlsJson: [],
      colorsJson: [],
      sizesJson: [],
      tagsJson: ['Organic'],
      featuresJson: [],
      badge: null,
      inStock: true,
      isOrganic: true,
    },
    {
      id: 'g2',
      moduleType: ModuleType.GROCERY,
      categoryId: 'grocery-dairy-eggs',
      name: 'Whole Milk 1 Gallon',
      brand: null,
      description: 'Farm fresh whole milk fortified with Vitamin D.',
      price: 4.49,
      originalPrice: null,
      rating: 4.7,
      reviewCount: 0,
      unit: 'gallon',
      imageUrlsJson: [],
      colorsJson: [],
      sizesJson: [],
      tagsJson: [],
      featuresJson: [],
      badge: null,
      inStock: true,
      isOrganic: false,
    },
    ...djiboutiPharmacyProducts,
  ];

  for (const product of products) {
    await prisma.product.upsert({
      where: { id: product.id },
      update: product,
      create: product,
    });
  }
}

async function seedDoctors() {
  await prisma.doctor.deleteMany({
    where: {
      id: {
        in: ['d6', 'd7', 'd8'],
      },
    },
  });

  for (const doctor of djiboutiDoctors) {
    await prisma.doctor.upsert({
      where: { id: doctor.id },
      update: doctor,
      create: doctor,
    });
  }
}

async function seedRestaurants() {
  for (const restaurant of djiboutiRestaurants) {
    await prisma.restaurant.upsert({
      where: { id: restaurant.id },
      update: restaurant,
      create: restaurant,
    });
  }

  for (const category of djiboutiRestaurantMenuCategories) {
    await prisma.restaurantMenuCategory.upsert({
      where: { id: category.id },
      update: category,
      create: category,
    });
  }

  for (const item of djiboutiRestaurantMenuItems) {
    await prisma.restaurantMenuItem.upsert({
      where: { id: item.id },
      update: item,
      create: item,
    });
  }
}

async function seedHotels() {
  for (const hotel of djiboutiHotels) {
    await prisma.hotel.upsert({
      where: { id: hotel.id },
      update: hotel,
      create: hotel,
    });
  }
}

async function seedRideCategories() {
  const categories = [
    {
      id: 'ride-economy',
      name: 'Economy',
      description: 'Affordable, everyday rides',
      capacity: 4,
      basePrice: 5,
      pricePerKm: 1.2,
      etaLabel: '3 min',
      active: true,
    },
    {
      id: 'ride-premium',
      name: 'Premium',
      description: 'Luxury rides with highly rated drivers',
      capacity: 4,
      basePrice: 10,
      pricePerKm: 2.5,
      etaLabel: '5 min',
      active: true,
    },
    {
      id: 'ride-xl',
      name: 'XL',
      description: 'Groups up to 6 people',
      capacity: 6,
      basePrice: 8,
      pricePerKm: 1.8,
      etaLabel: '7 min',
      active: true,
    },
  ];

  for (const category of categories) {
    await prisma.rideCategory.upsert({
      where: { id: category.id },
      update: category,
      create: category,
    });
  }
}

async function seedLaundryServices() {
  for (const service of djiboutiLaundryServices) {
    await prisma.laundryService.upsert({
      where: { id: service.id },
      update: service,
      create: service,
    });
  }
}

async function seedHomeServices() {
  await prisma.homeServiceProvider.deleteMany({
    where: {
      id: {
        in: ['hsp-7', 'hsp-8'],
      },
    },
  });

  for (const category of djiboutiHomeServiceCategories) {
    await prisma.homeServiceCategory.upsert({
      where: { id: category.id },
      update: category,
      create: category,
    });
  }

  for (const provider of djiboutiHomeServiceProviders) {
    await prisma.homeServiceProvider.upsert({
      where: { id: provider.id },
      update: provider,
      create: provider,
    });
  }
}

async function seedPromotions() {
  const promotions = [
    {
      id: 'promo_special_ride',
      moduleType: ModuleType.RIDE,
      title: 'First 3 Rides Free',
      description: 'New user exclusive offer for your first commute.',
      code: null,
      discountType: 'FREE_RIDES',
      discountValue: null,
      active: true,
      priority: 100,
      metadata: { kind: 'special', icon: 'ride' },
    },
    {
      id: 'promo_special_laundry',
      moduleType: ModuleType.LAUNDRY,
      title: 'Laundry Weekend',
      description: '50% off on wash and fold orders.',
      code: null,
      discountType: 'PERCENTAGE',
      discountValue: 50,
      active: true,
      priority: 90,
      metadata: { kind: 'special', icon: 'laundry' },
    },
    {
      id: 'promo_flash_food',
      moduleType: ModuleType.FOOD,
      title: 'Dinner Rush Flash Sale',
      description: 'Late-night meals and free delivery boosts after 7 PM.',
      code: null,
      discountType: 'PERCENTAGE',
      discountValue: 20,
      active: true,
      priority: 80,
      metadata: { kind: 'flash', reason: 'High evening demand' },
    },
    {
      id: 'promo_flash_grocery',
      moduleType: ModuleType.GROCERY,
      title: 'Fresh Basket Countdown',
      description: 'Produce and pantry staples are discounted before noon.',
      code: null,
      discountType: 'PERCENTAGE',
      discountValue: 15,
      active: true,
      priority: 70,
      metadata: { kind: 'flash', reason: 'Morning produce push' },
    },
    {
      id: 'promo_coupon_hotel',
      moduleType: ModuleType.HOTEL,
      title: 'Weekend Escape Package',
      description: 'Use this when you are ready to confirm a stay booking.',
      code: 'STAY25',
      discountType: 'PERCENTAGE',
      discountValue: 25,
      active: true,
      priority: 60,
      metadata: { kind: 'coupon', reason: 'City-stay promotion' },
    },
    {
      id: 'promo_coupon_doctor',
      moduleType: ModuleType.DOCTOR,
      title: 'First Visit Consultation',
      description: 'Reduced fee for your first online consultation booking.',
      code: 'HEALTH10',
      discountType: 'PERCENTAGE',
      discountValue: 10,
      active: true,
      priority: 50,
      metadata: { kind: 'coupon', reason: 'New patient offer' },
    },
    {
      id: 'promo_coupon_pharmacy',
      moduleType: ModuleType.PHARMACY,
      title: 'Daily Care Bundle',
      description: 'Works best when your pharmacy cart already has refill items.',
      code: 'CARE15',
      discountType: 'PERCENTAGE',
      discountValue: 15,
      active: true,
      priority: 40,
      metadata: { kind: 'coupon', reason: 'Refill essentials' },
    },
  ];

  for (const promotion of promotions) {
    await prisma.promotion.upsert({
      where: { id: promotion.id },
      update: promotion,
      create: promotion,
    });
  }
}

async function seedNotifications() {
  const demoUser = await prisma.user.findUnique({
    where: { email: 'demo@edalab.com' },
  });

  if (!demoUser) {
    return;
  }

  const notifications = [
    {
      id: 'notif_order_delivered',
      userId: demoUser.id,
      type: 'ORDER' as const,
      title: 'Order Delivered!',
      body: 'Your latest order has been delivered successfully.',
      data: { moduleType: 'FOOD' },
    },
    {
      id: 'notif_appointment',
      userId: demoUser.id,
      type: 'APPOINTMENT' as const,
      title: 'Appointment Reminder',
      body: 'Your next appointment is coming up soon.',
      data: { moduleType: 'DOCTOR' },
    },
    {
      id: 'notif_promo',
      userId: demoUser.id,
      type: 'PROMOTION' as const,
      title: 'Promo Alert',
      body: 'Fresh discounts are available across grocery and pharmacy.',
      data: { moduleType: 'GROCERY' },
    },
  ];

  for (const notification of notifications) {
    await prisma.notification.upsert({
      where: { id: notification.id },
      update: notification,
      create: notification,
    });
  }
}

async function seedAccountData() {
  const demoUser = await prisma.user.findUnique({
    where: { email: 'demo@edalab.com' },
  });

  if (!demoUser) {
    return;
  }

  const wishlistItems = [
    {
      id: 'wish_airpods',
      userId: demoUser.id,
      moduleType: ModuleType.SHOPPING,
      entityId: 'p2',
      title: 'Apple AirPods Pro',
      subtitle: 'Apple',
      imageUrl: null,
      price: 249.99,
    },
    {
      id: 'wish_banana',
      userId: demoUser.id,
      moduleType: ModuleType.GROCERY,
      entityId: 'g1',
      title: 'Fresh Organic Bananas',
      subtitle: 'Organic Produce',
      imageUrl: null,
      price: 2.99,
    },
  ];

  for (const item of wishlistItems) {
    await prisma.wishlistItem.upsert({
      where: { id: item.id },
      update: item,
      create: item,
    });
  }

  const coupons = [
    {
      id: 'coupon_demo_stay',
      userId: demoUser.id,
      promotionId: 'promo_coupon_hotel',
      status: 'AVAILABLE',
    },
    {
      id: 'coupon_demo_health',
      userId: demoUser.id,
      promotionId: 'promo_coupon_doctor',
      status: 'AVAILABLE',
    },
  ];

  for (const coupon of coupons) {
    await prisma.userCoupon.upsert({
      where: { id: coupon.id },
      update: coupon,
      create: coupon,
    });
  }
}

async function main() {
  await seedUsers();
  await seedAppModules();
  await seedCategories();
  await seedShoppingStores();
  await seedProducts();
  await seedDoctors();
  await seedRestaurants();
  await seedHotels();
  await seedRideCategories();
  await seedLaundryServices();
  await seedHomeServices();
  await seedPromotions();
  await seedNotifications();
  await seedAccountData();
}

main()
  .then(async () => {
    await prisma.$disconnect();
    console.log('Seed completed successfully.');
  })
  .catch(async (error) => {
    console.error('Seed failed:', error);
    await prisma.$disconnect();
    process.exit(1);
  });
