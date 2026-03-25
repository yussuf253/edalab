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
      providerType: 'DOCTOR',
      rating: 4.9,
      reviewCount: 1200,
      experience: '15 years',
      consultationFee: 50,
      isAvailable: true,
      isSignedUp: true,
      about: 'Board-certified cardiologist specializing in preventive cardiology and cardiac rehabilitation.',
      location: 'City Medical Center, 123 Health Street',
      contactPhone: '+253770000201',
      contactWhatsApp: '+253770000201',
      languagesJson: ['English', 'Spanish'],
      servicesJson: ['Heart Checkup', 'ECG', 'Echocardiogram', 'Stress Test', 'Cardiac Rehab'],
      careModesJson: ['Clinic Visit', 'Video Consultation'],
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
      providerType: 'DOCTOR',
      rating: 4.8,
      reviewCount: 890,
      experience: '10 years',
      consultationFee: 45,
      isAvailable: true,
      isSignedUp: true,
      about: 'Specializes in medical and cosmetic dermatology.',
      location: 'Skin Health Clinic, 456 Beauty Ave',
      contactPhone: '+253770000202',
      contactWhatsApp: '+253770000202',
      languagesJson: ['English'],
      servicesJson: ['Skin Consultation', 'Dermatology Checkup'],
      careModesJson: ['Clinic Visit', 'Video Consultation'],
      workingHoursJson: {
        weekdays: '09:00 AM - 05:00 PM',
        saturday: '10:00 AM - 02:00 PM',
        sunday: 'Closed',
      },
    },
    {
      id: 'd3',
      name: 'Amina Hassan',
      specialty: 'Home Nursing',
      providerType: 'HOME_CARE',
      rating: 4.9,
      reviewCount: 410,
      experience: '11 years',
      consultationFee: 35,
      isAvailable: true,
      isSignedUp: true,
      about: 'Licensed home nurse for wound care, injections, medication administration, and elderly support at home.',
      location: 'Home visits across Djibouti City',
      contactPhone: '+253770000203',
      contactWhatsApp: '+253770000203',
      languagesJson: ['English', 'French', 'Arabic'],
      servicesJson: ['Home Nursing', 'Wound Dressing', 'Injection Care', 'Elderly Monitoring'],
      careModesJson: ['Home Visit', 'Phone Advice'],
      workingHoursJson: {
        weekdays: '08:00 AM - 07:00 PM',
        saturday: '08:00 AM - 04:00 PM',
        sunday: 'Emergency only',
      },
    },
    {
      id: 'd4',
      name: 'Mohamed Ali',
      specialty: 'Physiotherapy',
      providerType: 'HOME_CARE',
      rating: 4.7,
      reviewCount: 298,
      experience: '9 years',
      consultationFee: 40,
      isAvailable: true,
      isSignedUp: false,
      about: 'Mobile physiotherapist focused on post-surgery recovery, chronic pain management, and movement rehabilitation at home.',
      location: 'Home rehabilitation service',
      contactPhone: '+253770000204',
      contactWhatsApp: '+253770000204',
      languagesJson: ['English', 'French'],
      servicesJson: ['Physiotherapy', 'Rehab Sessions', 'Back Pain Therapy', 'Kine Exercises'],
      careModesJson: ['Home Visit'],
      workingHoursJson: {
        weekdays: '09:00 AM - 06:00 PM',
        saturday: '09:00 AM - 01:00 PM',
        sunday: 'Closed',
      },
    },
    {
      id: 'd5',
      name: 'Samira Aden',
      specialty: 'Mental Therapy',
      providerType: 'HOME_CARE',
      rating: 4.8,
      reviewCount: 355,
      experience: '7 years',
      consultationFee: 38,
      isAvailable: true,
      isSignedUp: false,
      about: 'Provides at-home and remote psychological support, stress management guidance, and family counseling.',
      location: 'At-home and online support',
      contactPhone: '+253770000205',
      contactWhatsApp: '+253770000205',
      languagesJson: ['English', 'Somali', 'Arabic'],
      servicesJson: ['Mental Therapy', 'Stress Support', 'Family Counseling', 'Emotional Wellness'],
      careModesJson: ['Home Visit', 'Video Consultation', 'Phone Advice'],
      workingHoursJson: {
        weekdays: '10:00 AM - 08:00 PM',
        saturday: '10:00 AM - 03:00 PM',
        sunday: 'Closed',
      },
    },
    {
      id: 'd6',
      name: 'Dr. Emily Williams',
      specialty: 'Pediatrician',
      providerType: 'DOCTOR',
      rating: 4.7,
      reviewCount: 1500,
      experience: '12 years',
      consultationFee: 40,
      isAvailable: false,
      isSignedUp: false,
      about: 'Compassionate pediatrician providing comprehensive care for children from birth to adolescence.',
      location: 'Children\'s Health Center',
      contactPhone: '+253770000206',
      contactWhatsApp: '+253770000206',
      languagesJson: ['English'],
      servicesJson: ['Child Consultation', 'Vaccination Follow-up', 'General Pediatrics'],
      careModesJson: ['Clinic Visit', 'Video Consultation'],
      workingHoursJson: {
        weekdays: '09:00 AM - 05:00 PM',
        saturday: '10:00 AM - 02:00 PM',
        sunday: 'Closed',
      },
    },
    {
      id: 'd7',
      name: 'Dr. James Brown',
      specialty: 'Neurologist',
      providerType: 'DOCTOR',
      rating: 4.9,
      reviewCount: 2100,
      experience: '20 years',
      consultationFee: 60,
      isAvailable: true,
      isSignedUp: false,
      about: 'Leading neurologist specializing in migraine, epilepsy, and neurodegenerative disorders.',
      location: 'Brain & Spine Center',
      contactPhone: '+253770000207',
      contactWhatsApp: '+253770000207',
      languagesJson: ['English'],
      servicesJson: ['Neurology Consultation', 'Migraine Care', 'Nerve Assessment'],
      careModesJson: ['Clinic Visit', 'Video Consultation'],
      workingHoursJson: {
        weekdays: '09:00 AM - 05:00 PM',
        saturday: '10:00 AM - 02:00 PM',
        sunday: 'Closed',
      },
    },
    {
      id: 'd8',
      name: 'Dr. Lisa Anderson',
      specialty: 'Orthopedic',
      providerType: 'DOCTOR',
      rating: 4.6,
      reviewCount: 650,
      experience: '8 years',
      consultationFee: 55,
      isAvailable: false,
      isSignedUp: false,
      about: 'Specializes in sports medicine and joint replacement surgery.',
      location: 'Sports Medicine Clinic',
      contactPhone: '+253770000208',
      contactWhatsApp: '+253770000208',
      languagesJson: ['English'],
      servicesJson: ['Orthopedic Consultation', 'Joint Care', 'Sports Injury Follow-up'],
      careModesJson: ['Clinic Visit'],
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

async function seedHomeServices() {
  const categories = [
    {
      id: 'hs-cleaning',
      name: 'Home Cleaning',
      slug: 'cleaning',
      description: 'Routine, deep, and move-in cleaning for apartments and houses.',
      iconKey: 'cleaning',
      colorHex: '#0F9D92',
      sortOrder: 1,
      active: true,
    },
    {
      id: 'hs-plumbing',
      name: 'Plumbing',
      slug: 'plumbing',
      description: 'Leaks, fittings, drainage, and urgent plumbing help.',
      iconKey: 'plumbing',
      colorHex: '#3B82F6',
      sortOrder: 2,
      active: true,
    },
    {
      id: 'hs-electrical',
      name: 'Electrical',
      slug: 'electrical',
      description: 'Installations, repairs, and safe home electrical work.',
      iconKey: 'electrical',
      colorHex: '#F59E0B',
      sortOrder: 3,
      active: true,
    },
    {
      id: 'hs-ac',
      name: 'AC & Cooling',
      slug: 'ac-cooling',
      description: 'AC servicing, gas refill, and cooling-system fixes.',
      iconKey: 'ac',
      colorHex: '#06B6D4',
      sortOrder: 4,
      active: true,
    },
    {
      id: 'hs-beauty',
      name: 'Beauty at Home',
      slug: 'beauty-at-home',
      description: 'Hair, makeup, nails, and self-care professionals at home.',
      iconKey: 'beauty',
      colorHex: '#EC4899',
      sortOrder: 5,
      active: true,
    },
    {
      id: 'hs-handyman',
      name: 'Handyman',
      slug: 'handyman',
      description: 'Furniture assembly, curtain fixing, drilling, and home tasks.',
      iconKey: 'handyman',
      colorHex: '#8B5CF6',
      sortOrder: 6,
      active: true,
    },
  ];

  for (const category of categories) {
    await prisma.homeServiceCategory.upsert({
      where: { id: category.id },
      update: category,
      create: category,
    });
  }

  const providers = [
    {
      id: 'hsp-1',
      categoryId: 'hs-cleaning',
      name: 'Sparkle Home Care',
      title: 'Cleaning Crew',
      rating: 4.9,
      reviewCount: 620,
      yearsExperience: '6 years',
      startingPrice: 22,
      isAvailable: true,
      isVerified: true,
      responseTime: 'Responds in 10 min',
      about: 'Reliable team for weekly cleaning, deep cleaning, and move-in refresh services.',
      location: 'Djibouti City',
      contactPhone: '+253770010301',
      servicesJson: ['Deep Cleaning', 'Kitchen Cleaning', 'Bathroom Sanitizing', 'Move-in Cleaning'],
      highlightsJson: ['Eco-friendly products', 'Same-day availability'],
      bookingModesJson: ['Home Visit'],
      availabilityJson: { weekdays: '08:00 AM - 08:00 PM', saturday: '09:00 AM - 05:00 PM', sunday: 'Closed' },
    },
    {
      id: 'hsp-2',
      categoryId: 'hs-plumbing',
      name: 'AquaFix Pro',
      title: 'Licensed Plumber',
      rating: 4.8,
      reviewCount: 410,
      yearsExperience: '9 years',
      startingPrice: 18,
      isAvailable: true,
      isVerified: true,
      responseTime: 'Responds in 15 min',
      about: 'Home plumbing specialist for urgent leaks, taps, toilets, and drainage issues.',
      location: 'Djibouti City',
      contactPhone: '+253770010302',
      servicesJson: ['Leak Repair', 'Pipe Installation', 'Drain Cleaning', 'Toilet Repair'],
      highlightsJson: ['Emergency calls', 'Tools included'],
      bookingModesJson: ['Home Visit'],
      availabilityJson: { weekdays: '07:00 AM - 09:00 PM', saturday: '08:00 AM - 06:00 PM', sunday: 'Emergency only' },
    },
    {
      id: 'hsp-3',
      categoryId: 'hs-electrical',
      name: 'BrightWire Services',
      title: 'Certified Electrician',
      rating: 4.7,
      reviewCount: 356,
      yearsExperience: '8 years',
      startingPrice: 20,
      isAvailable: true,
      isVerified: true,
      responseTime: 'Responds in 20 min',
      about: 'Safe residential electrical work for lighting, sockets, breakers, and installations.',
      location: 'Balbala & Djibouti City',
      contactPhone: '+253770010303',
      servicesJson: ['Socket Repair', 'Light Installation', 'Breaker Check', 'Wiring'],
      highlightsJson: ['Safety-first', 'Fast diagnostics'],
      bookingModesJson: ['Home Visit'],
      availabilityJson: { weekdays: '08:00 AM - 07:00 PM', saturday: '09:00 AM - 04:00 PM', sunday: 'Closed' },
    },
    {
      id: 'hsp-4',
      categoryId: 'hs-ac',
      name: 'CoolAir Experts',
      title: 'AC Technician',
      rating: 4.9,
      reviewCount: 280,
      yearsExperience: '7 years',
      startingPrice: 24,
      isAvailable: true,
      isVerified: true,
      responseTime: 'Responds in 12 min',
      about: 'Cooling and AC maintenance service for diagnostics, gas refill, and full cleaning.',
      location: 'Djibouti City',
      contactPhone: '+253770010304',
      servicesJson: ['AC Cleaning', 'Gas Refill', 'Cooling Repair', 'Installation Check'],
      highlightsJson: ['Free diagnostics with booking', 'Weekend support'],
      bookingModesJson: ['Home Visit'],
      availabilityJson: { weekdays: '08:30 AM - 08:00 PM', saturday: '09:00 AM - 06:00 PM', sunday: 'Closed' },
    },
    {
      id: 'hsp-5',
      categoryId: 'hs-beauty',
      name: 'Glow Studio Mobile',
      title: 'Beauty Specialist',
      rating: 4.8,
      reviewCount: 540,
      yearsExperience: '5 years',
      startingPrice: 16,
      isAvailable: true,
      isVerified: true,
      responseTime: 'Responds in 18 min',
      about: 'At-home beauty sessions for makeup, hairstyling, nails, and event-ready self-care.',
      location: 'Djibouti City',
      contactPhone: '+253770010305',
      servicesJson: ['Makeup', 'Hair Styling', 'Nail Care', 'Bridal Prep'],
      highlightsJson: ['Women-only team available', 'Event packages'],
      bookingModesJson: ['Home Visit'],
      availabilityJson: { weekdays: '10:00 AM - 09:00 PM', saturday: '09:00 AM - 08:00 PM', sunday: '10:00 AM - 05:00 PM' },
    },
    {
      id: 'hsp-6',
      categoryId: 'hs-handyman',
      name: 'FixIt Handyman',
      title: 'General Handyman',
      rating: 4.6,
      reviewCount: 233,
      yearsExperience: '11 years',
      startingPrice: 14,
      isAvailable: true,
      isVerified: false,
      responseTime: 'Responds in 25 min',
      about: 'Trusted handyman for everyday fixes, drilling, shelves, curtain rails, and furniture setup.',
      location: 'Djibouti City',
      contactPhone: '+253770010306',
      servicesJson: ['Furniture Assembly', 'Curtain Installation', 'Wall Mounting', 'Minor Repairs'],
      highlightsJson: ['Affordable callout', 'Tools provided'],
      bookingModesJson: ['Home Visit'],
      availabilityJson: { weekdays: '08:00 AM - 06:00 PM', saturday: '09:00 AM - 03:00 PM', sunday: 'Closed' },
    },
    {
      id: 'hsp-7',
      categoryId: 'hs-cleaning',
      name: 'FreshNest Cleaners',
      title: 'Deep Cleaning Specialist',
      rating: 4.7,
      reviewCount: 312,
      yearsExperience: '4 years',
      startingPrice: 19,
      isAvailable: true,
      isVerified: false,
      responseTime: 'Responds in 30 min',
      about: 'Deep-clean and post-event cleanup team for homes, offices, and rental units.',
      location: 'Djibouti City',
      contactPhone: '+253770010307',
      servicesJson: ['Deep Cleaning', 'Post-event Cleanup', 'Sofa Cleaning', 'Window Cleaning'],
      highlightsJson: ['Large-team bookings', 'Office cleaning'],
      bookingModesJson: ['Home Visit'],
      availabilityJson: { weekdays: '08:00 AM - 07:00 PM', saturday: '09:00 AM - 05:00 PM', sunday: 'Closed' },
    },
    {
      id: 'hsp-8',
      categoryId: 'hs-beauty',
      name: 'Zen Spa at Home',
      title: 'Massage & Wellness',
      rating: 4.9,
      reviewCount: 188,
      yearsExperience: '6 years',
      startingPrice: 28,
      isAvailable: true,
      isVerified: true,
      responseTime: 'Responds in 14 min',
      about: 'Relaxation and wellness sessions at home, including massage and facial care.',
      location: 'Djibouti City',
      contactPhone: '+253770010308',
      servicesJson: ['Massage Therapy', 'Facial Care', 'Self-care Session'],
      highlightsJson: ['Premium oils', 'Quiet-home setup'],
      bookingModesJson: ['Home Visit'],
      availabilityJson: { weekdays: '11:00 AM - 09:00 PM', saturday: '10:00 AM - 08:00 PM', sunday: '11:00 AM - 05:00 PM' },
    },
  ];

  for (const provider of providers) {
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
