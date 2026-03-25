import { ModuleType, PaymentMethodType, PrismaClient } from '@prisma/client';
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
  const stores = [
    {
      id: 'store-nike',
      name: 'Nike',
      slug: 'nike',
      tagline: 'Performance shoes, apparel, and everyday essentials.',
      description: 'Official Nike-inspired storefront for footwear, apparel, and accessories.',
      imageUrl: null,
      rating: 4.8,
      reviewCount: 2340,
      badge: 'Popular',
      minPrice: 39.99,
      maxPrice: 189.99,
      highlightsJson: ['Fast shipping', 'New drops weekly'],
    },
    {
      id: 'store-apple',
      name: 'Apple',
      slug: 'apple',
      tagline: 'Premium devices, audio, and accessories.',
      description: 'A premium electronics storefront with audio gear and devices.',
      imageUrl: null,
      rating: 4.9,
      reviewCount: 5600,
      badge: 'Top Rated',
      minPrice: 49.99,
      maxPrice: 1299.99,
      highlightsJson: ['Official products', '1-year warranty'],
    },
    {
      id: 'store-levis',
      name: "Levi's",
      slug: 'levis',
      tagline: 'Timeless denim and casual essentials.',
      description: 'Classic wardrobe picks and casual essentials with iconic denim.',
      imageUrl: null,
      rating: 4.6,
      reviewCount: 1800,
      badge: null,
      minPrice: 29.99,
      maxPrice: 119.99,
      highlightsJson: ['Classic fits', 'Seasonal discounts'],
    },
    {
      id: 'store-samsung',
      name: 'Samsung',
      slug: 'samsung',
      tagline: 'Smart devices for work, fitness, and everyday life.',
      description: 'Smart wearables and connected devices for a modern lifestyle.',
      imageUrl: null,
      rating: 4.7,
      reviewCount: 3200,
      badge: 'New',
      minPrice: 99.99,
      maxPrice: 799.99,
      highlightsJson: ['Smart living', 'Latest releases'],
    },
    {
      id: 'store-ray-ban',
      name: 'Ray-Ban',
      slug: 'ray-ban',
      tagline: 'Iconic eyewear and accessories.',
      description: 'Timeless accessories and signature eyewear collections.',
      imageUrl: null,
      rating: 4.5,
      reviewCount: 890,
      badge: null,
      minPrice: 79.99,
      maxPrice: 249.99,
      highlightsJson: ['Iconic styles', 'UV protection'],
    },
    {
      id: 'store-dyson',
      name: 'Dyson',
      slug: 'dyson',
      tagline: 'High-performance home technology.',
      description: 'Premium home technology built for smart, efficient living.',
      imageUrl: null,
      rating: 4.8,
      reviewCount: 1100,
      badge: 'Premium',
      minPrice: 199.99,
      maxPrice: 899.99,
      highlightsJson: ['Premium tech', 'Home innovation'],
    },
  ];

  for (const store of stores) {
    await prisma.shoppingStore.upsert({
      where: { id: store.id },
      update: store,
      create: store,
    });
  }
}

async function seedProducts() {
  const products = [
    {
      id: 'p1',
      moduleType: ModuleType.SHOPPING,
      categoryId: 'shopping-shoes',
      shopId: 'store-nike',
      name: 'Nike Air Max 270',
      brand: 'Nike',
      description: 'The Nike Air Max 270 delivers visible cushioning under every step with modern comfort.',
      price: 129.99,
      originalPrice: 159.99,
      rating: 4.8,
      reviewCount: 2340,
      imageUrlsJson: [],
      colorsJson: ['Black', 'White', 'Blue', 'Red'],
      sizesJson: ['US 7', 'US 8', 'US 9', 'US 10', 'US 11'],
      tagsJson: ['Best Seller'],
      featuresJson: ['Lightweight mesh upper', 'Max Air 270 unit', 'Foam midsole', 'Rubber outsole'],
      badge: 'Best Seller',
      inStock: true,
      isOrganic: false,
    },
    {
      id: 'p2',
      moduleType: ModuleType.SHOPPING,
      categoryId: 'shopping-electronics',
      shopId: 'store-apple',
      name: 'Apple AirPods Pro',
      brand: 'Apple',
      description: 'Active Noise Cancellation with customizable fit and immersive sound.',
      price: 249.99,
      originalPrice: null,
      rating: 4.9,
      reviewCount: 5600,
      imageUrlsJson: [],
      colorsJson: ['White'],
      sizesJson: [],
      tagsJson: ['Top Rated'],
      featuresJson: ['Active Noise Cancellation', 'Transparency mode', 'Spatial audio', 'MagSafe charging'],
      badge: 'Top Rated',
      inStock: true,
      isOrganic: false,
    },
    {
      id: 'p3',
      moduleType: ModuleType.SHOPPING,
      categoryId: 'shopping-clothing',
      shopId: 'store-levis',
      name: "Levi's 501 Original",
      brand: "Levi's",
      description: 'The original jean with iconic straight fit and signature button fly.',
      price: 79.99,
      originalPrice: 98.0,
      rating: 4.6,
      reviewCount: 1800,
      imageUrlsJson: [],
      colorsJson: ['Dark Blue', 'Light Blue', 'Black'],
      sizesJson: ['28', '30', '32', '34', '36'],
      tagsJson: ['Classic'],
      featuresJson: ['100% Cotton', 'Button fly', 'Straight fit', 'Made for everyday wear'],
      badge: null,
      inStock: true,
      isOrganic: false,
    },
    {
      id: 'p4',
      moduleType: ModuleType.SHOPPING,
      categoryId: 'shopping-electronics',
      shopId: 'store-samsung',
      name: 'Samsung Galaxy Watch',
      brand: 'Samsung',
      description: 'Track your fitness and stay connected with advanced health monitoring.',
      price: 299.99,
      originalPrice: 349.99,
      rating: 4.7,
      reviewCount: 3200,
      imageUrlsJson: [],
      colorsJson: ['Black', 'Silver', 'Rose Gold'],
      sizesJson: ['40mm', '44mm'],
      tagsJson: ['New'],
      featuresJson: ['Heart rate monitor', 'Sleep tracking', 'GPS', 'Water resistant'],
      badge: 'New',
      inStock: true,
      isOrganic: false,
    },
    {
      id: 'p5',
      moduleType: ModuleType.SHOPPING,
      categoryId: 'shopping-accessories',
      shopId: 'store-ray-ban',
      name: 'Ray-Ban Aviator',
      brand: 'Ray-Ban',
      description: 'Timeless aviator sunglasses originally designed for pilots.',
      price: 163.0,
      originalPrice: null,
      rating: 4.5,
      reviewCount: 890,
      imageUrlsJson: [],
      colorsJson: ['Gold/Green', 'Silver/Blue', 'Black/Gray'],
      sizesJson: [],
      tagsJson: ['Classic'],
      featuresJson: ['Crystal lenses', 'Metal frame', '100% UV protection', 'Iconic design'],
      badge: null,
      inStock: true,
      isOrganic: false,
    },
    {
      id: 'p6',
      moduleType: ModuleType.SHOPPING,
      categoryId: 'shopping-home',
      shopId: 'store-dyson',
      name: 'Dyson V15 Detect',
      brand: 'Dyson',
      description: 'Powerful intelligent cordless vacuum that reveals microscopic dust.',
      price: 749.99,
      originalPrice: null,
      rating: 4.8,
      reviewCount: 1100,
      imageUrlsJson: [],
      colorsJson: [],
      sizesJson: [],
      tagsJson: ['Premium'],
      featuresJson: ['Laser dust detection', '60 min runtime', 'LCD screen', 'HEPA filtration'],
      badge: 'Premium',
      inStock: true,
      isOrganic: false,
    },
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
    {
      id: 'm1',
      moduleType: ModuleType.PHARMACY,
      categoryId: 'pharmacy-pain-relief',
      name: 'Paracetamol 500mg',
      brand: null,
      description: 'Effective pain relief and fever reduction.',
      price: 4.99,
      originalPrice: null,
      rating: 4.8,
      reviewCount: 154,
      dosage: 'Take 1-2 tablets every 4-6 hours',
      packageSize: '20 Tablets',
      requiresPrescription: false,
      imageUrlsJson: [],
      colorsJson: [],
      sizesJson: [],
      tagsJson: [],
      featuresJson: [],
      badge: null,
      inStock: true,
      isOrganic: false,
    },
    {
      id: 'm2',
      moduleType: ModuleType.PHARMACY,
      categoryId: 'pharmacy-antibiotics',
      name: 'Amoxicillin 250mg',
      brand: null,
      description: 'Used to treat a wide variety of bacterial infections.',
      price: 12.99,
      originalPrice: null,
      rating: 4.9,
      reviewCount: 89,
      dosage: 'Take 1 capsule every 8 hours',
      packageSize: '15 Capsules',
      requiresPrescription: true,
      imageUrlsJson: [],
      colorsJson: [],
      sizesJson: [],
      tagsJson: [],
      featuresJson: [],
      badge: null,
      inStock: true,
      isOrganic: false,
    },
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
  const doctors = [
    {
      id: 'd1',
      name: 'Dr. Sarah Johnson',
      specialty: 'Cardiologist',
      rating: 4.9,
      reviewCount: 1200,
      experience: '15 years',
      consultationFee: 50,
      isAvailable: true,
      about: 'Board-certified cardiologist specializing in preventive cardiology and cardiac rehabilitation.',
      location: 'City Medical Center, 123 Health Street',
      languagesJson: ['English', 'Spanish'],
      servicesJson: ['Heart Checkup', 'ECG', 'Echocardiogram', 'Stress Test', 'Cardiac Rehab'],
      workingHoursJson: {
        weekdays: '09:00 AM - 05:00 PM',
        saturday: '10:00 AM - 02:00 PM',
        sunday: 'Closed',
      },
    },
    {
      id: 'd2',
      name: 'Dr. Michael Chen',
      specialty: 'Dermatologist',
      rating: 4.8,
      reviewCount: 890,
      experience: '10 years',
      consultationFee: 45,
      isAvailable: true,
      about: 'Specializes in medical and cosmetic dermatology.',
      location: 'Skin Health Clinic, 456 Beauty Ave',
      languagesJson: ['English'],
      servicesJson: ['Skin Consultation', 'Dermatology Checkup'],
      workingHoursJson: {
        weekdays: '09:00 AM - 05:00 PM',
        saturday: '10:00 AM - 02:00 PM',
        sunday: 'Closed',
      },
    },
  ];

  for (const doctor of doctors) {
    await prisma.doctor.upsert({
      where: { id: doctor.id },
      update: doctor,
      create: doctor,
    });
  }
}

async function seedRestaurants() {
  const restaurants = [
    {
      id: 'r1',
      name: 'Burger Palace',
      cuisine: 'Burgers, Fast Food',
      rating: 4.8,
      reviewCount: 1200,
      deliveryTime: '15-25',
      deliveryFee: 0,
      imageUrl: null,
      isOpen: true,
      distanceKm: 1.2,
      tagsJson: ['Popular', 'Fast Delivery'],
    },
    {
      id: 'r2',
      name: 'Pizza Royal',
      cuisine: 'Pizza, Italian',
      rating: 4.6,
      reviewCount: 850,
      deliveryTime: '20-30',
      deliveryFee: 2.99,
      imageUrl: null,
      isOpen: true,
      distanceKm: 2.1,
      tagsJson: ['Italian', 'Pizza'],
    },
  ];

  for (const restaurant of restaurants) {
    await prisma.restaurant.upsert({
      where: { id: restaurant.id },
      update: restaurant,
      create: restaurant,
    });
  }

  const menuCategories = [
    { id: 'r1-popular', restaurantId: 'r1', name: 'Popular', sortOrder: 1 },
    { id: 'r1-sides', restaurantId: 'r1', name: 'Sides', sortOrder: 2 },
    { id: 'r1-drinks', restaurantId: 'r1', name: 'Drinks', sortOrder: 3 },
  ];

  for (const category of menuCategories) {
    await prisma.restaurantMenuCategory.upsert({
      where: { id: category.id },
      update: category,
      create: category,
    });
  }

  const menuItems = [
    {
      id: 'food-m1',
      categoryId: 'r1-popular',
      name: 'Classic Cheese Burger',
      description: 'Juicy beef patty with cheddar, lettuce, and tomato.',
      price: 12.99,
      imageUrl: null,
      isPopular: true,
      isAvailable: true,
      customizationsJson: ['Extra Cheese', 'No Onion', 'Spicy Sauce'],
    },
    {
      id: 'food-m2',
      categoryId: 'r1-sides',
      name: 'Loaded Fries',
      description: 'Cheese, jalapenos, and sour cream.',
      price: 7.99,
      imageUrl: null,
      isPopular: true,
      isAvailable: true,
      customizationsJson: ['Extra Cheese'],
    },
    {
      id: 'food-m3',
      categoryId: 'r1-drinks',
      name: 'Fresh Lemonade',
      description: 'Freshly squeezed with mint.',
      price: 4.49,
      imageUrl: null,
      isPopular: false,
      isAvailable: true,
      customizationsJson: ['Less Ice'],
    },
  ];

  for (const item of menuItems) {
    await prisma.restaurantMenuItem.upsert({
      where: { id: item.id },
      update: item,
      create: item,
    });
  }
}

async function seedHotels() {
  const hotels = [
    {
      id: 'h1',
      name: 'Grand Royale Hotel',
      address: '123 Luxury Ave',
      city: 'New York',
      rating: 4.9,
      reviewsCount: 1204,
      pricePerNight: 299.99,
      amenitiesJson: ['Pool', 'Spa', 'Gym', 'Free WiFi', 'Restaurant'],
      description: 'Experience ultimate luxury in the heart of the city.',
      imageUrlsJson: [],
    },
    {
      id: 'h2',
      name: 'Oasis Beach Resort',
      address: '456 Sandy Boulevard',
      city: 'Miami',
      rating: 4.7,
      reviewsCount: 845,
      pricePerNight: 195,
      amenitiesJson: ['Beachfront', 'Pool', 'Bar', 'Free Breakfast'],
      description: 'Relax and unwind at our beautiful beachfront property.',
      imageUrlsJson: [],
    },
  ];

  for (const hotel of hotels) {
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
  const services = [
    {
      id: 'l1',
      name: 'Wash & Fold',
      description: 'Standard washing and folding for regular clothes.',
      price: 25,
      unit: 'per bag',
      iconUrl: 'wash',
      active: true,
    },
    {
      id: 'l2',
      name: 'Dry Cleaning',
      description: 'Professional dry cleaning for delicate fabrics.',
      price: 15,
      unit: 'per item',
      iconUrl: 'dry',
      active: true,
    },
    {
      id: 'l3',
      name: 'Ironing Only',
      description: 'Professional pressing and ironing service.',
      price: 5,
      unit: 'per item',
      iconUrl: 'iron',
      active: true,
    },
  ];

  for (const service of services) {
    await prisma.laundryService.upsert({
      where: { id: service.id },
      update: service,
      create: service,
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
  await seedCategories();
  await seedShoppingStores();
  await seedProducts();
  await seedDoctors();
  await seedRestaurants();
  await seedHotels();
  await seedRideCategories();
  await seedLaundryServices();
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
