import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FadeInDown(
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning 👋',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Youssouf Hassan',
                              style: AppTextStyles.h4,
                            ),
                          ],
                        ),
                      ),
                      // Notification bell
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppSpacing.shadowSm,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.dark,
                                size: 24,
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: AppSearchBar(
                    hint: 'Search services, products, restaurants...',
                    readOnly: true,
                    onTap: () => context.push('/search'),
                    suffix: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Promo Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: _PromoBanner(),
                ),
              ),
            ),

            // Services Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: Column(
                    children: [
                      const SectionHeader(
                        title: 'Services',
                        actionText: 'See All',
                      ),
                      const SizedBox(height: 16),
                      _ServicesGrid(),
                    ],
                  ),
                ),
              ),
            ),

            // Special Offers
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    children: [
                      const SectionHeader(
                        title: 'Special Offers 🔥',
                        actionText: 'See All',
                      ),
                      const SizedBox(height: 16),
                      _SpecialOffers(),
                    ],
                  ),
                ),
              ),
            ),

            // Popular Restaurants
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: 'Popular Restaurants',
                        actionText: 'See All',
                        onAction: () => context.push('/food'),
                      ),
                      const SizedBox(height: 16),
                      _PopularRestaurants(),
                    ],
                  ),
                ),
              ),
            ),

            // Top Doctors
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 550),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: 'Top Doctors',
                        actionText: 'See All',
                        onAction: () => context.push('/doctor'),
                      ),
                      const SizedBox(height: 16),
                      _TopDoctors(),
                    ],
                  ),
                ),
              ),
            ),

            // Trending Products
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 24),
                child: FadeInDown(
                  delay: const Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: 'Trending Products',
                        actionText: 'See All',
                        onAction: () => context.push('/shopping'),
                      ),
                      const SizedBox(height: 16),
                      _TrendingProducts(),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎉 LIMITED OFFER',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Get 30% Off',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'On your first order from any service',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          // CTA
          Positioned(
            right: 20,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Order Now',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  final _services = const [
    _ServiceItem(icon: Icons.fastfood_rounded, title: 'Food', color: AppColors.food, bgColor: AppColors.foodBg, route: '/food'),
    _ServiceItem(icon: Icons.shopping_bag_rounded, title: 'Shopping', color: AppColors.shopping, bgColor: AppColors.shoppingBg, route: '/shopping'),
    _ServiceItem(icon: Icons.local_hospital_rounded, title: 'Doctor', color: AppColors.doctor, bgColor: AppColors.doctorBg, route: '/doctor'),
    _ServiceItem(icon: Icons.hotel_rounded, title: 'Hotel', color: AppColors.hotel, bgColor: AppColors.hotelBg, route: '/hotel'),
    _ServiceItem(icon: Icons.directions_car_rounded, title: 'Ride', color: AppColors.ride, bgColor: AppColors.rideBg, route: '/ride'),
    _ServiceItem(icon: Icons.local_pharmacy_rounded, title: 'Pharmacy', color: AppColors.pharmacy, bgColor: AppColors.pharmacyBg, route: '/pharmacy'),
    _ServiceItem(icon: Icons.local_grocery_store_rounded, title: 'Grocery', color: AppColors.grocery, bgColor: AppColors.groceryBg, route: '/grocery'),
    _ServiceItem(icon: Icons.local_laundry_service_rounded, title: 'Laundry', color: AppColors.laundry, bgColor: AppColors.laundryBg, route: '/laundry'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return GestureDetector(
            onTap: () => context.push(service.route),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: service.bgColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(service.icon, color: service.color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  service.title,
                  style: AppTextStyles.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceItem {
  final IconData icon;
  final String title;
  final Color color;
  final Color bgColor;
  final String route;

  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.bgColor,
    required this.route,
  });
}

class _SpecialOffers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final offers = [
      _OfferData('40% OFF', 'Fresh Groceries', 'Free delivery on orders above \$30', AppColors.grocery, Icons.local_grocery_store_rounded),
      _OfferData('25% OFF', 'Medicine Delivery', 'Upload prescription & save more', AppColors.pharmacy, Icons.medication_rounded),
      _OfferData('Free Ride', 'First 3 Rides Free', 'New user exclusive offer', AppColors.ride, Icons.directions_car_rounded),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: offer.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: offer.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: offer.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(offer.icon, color: offer.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: offer.color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          offer.discount,
                          style: AppTextStyles.badge.copyWith(fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        offer.title,
                        style: AppTextStyles.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        offer.subtitle,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OfferData {
  final String discount;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  _OfferData(this.discount, this.title, this.subtitle, this.color, this.icon);
}

class _PopularRestaurants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final restaurants = [
      _RestaurantData('Burger Palace', 'Burgers, Fast Food', 4.8, '15-25 min', '\$\$'),
      _RestaurantData('Pizza Royal', 'Pizza, Italian', 4.6, '20-30 min', '\$\$\$'),
      _RestaurantData('Sushi Master', 'Japanese, Sushi', 4.9, '25-35 min', '\$\$\$'),
    ];

    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final r = restaurants[index];
          return GestureDetector(
            onTap: () => context.push('/food/restaurant/r$index'),
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.food.withValues(alpha: 0.3),
                          AppColors.food.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 40,
                        color: AppColors.food.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: AppTextStyles.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          r.cuisine,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 4),
                            Text(
                              r.rating.toString(),
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.schedule_rounded, size: 14, color: AppColors.mediumGrey),
                            const SizedBox(width: 4),
                            Text(r.deliveryTime, style: AppTextStyles.caption),
                            const Spacer(),
                            Text(
                              r.priceRange,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantData {
  final String name;
  final String cuisine;
  final double rating;
  final String deliveryTime;
  final String priceRange;

  _RestaurantData(this.name, this.cuisine, this.rating, this.deliveryTime, this.priceRange);
}

class _TopDoctors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final doctors = [
      _DoctorData('Dr. Sarah Johnson', 'Cardiologist', 4.9, '15 years exp', AppColors.doctor),
      _DoctorData('Dr. Michael Chen', 'Dermatologist', 4.8, '10 years exp', AppColors.pharmacy),
      _DoctorData('Dr. Emily Williams', 'Pediatrician', 4.7, '12 years exp', AppColors.primary),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: doctors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final d = doctors[index];
          return GestureDetector(
            onTap: () => context.push('/doctor/detail/d$index'),
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: d.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: d.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(d.name, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(d.specialty, style: AppTextStyles.caption),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text('${d.rating}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark)),
                            const SizedBox(width: 8),
                            Text(d.experience, style: AppTextStyles.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DoctorData {
  final String name;
  final String specialty;
  final double rating;
  final String experience;
  final Color color;

  _DoctorData(this.name, this.specialty, this.rating, this.experience, this.color);
}

class _TrendingProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final products = [
      _ProductData('AirPods Pro 2', 'Electronics', '\$249', '\$299', 4.8),
      _ProductData('Nike Air Max', 'Footwear', '\$180', '\$220', 4.7),
      _ProductData('Smart Watch', 'Wearables', '\$199', '\$299', 4.6),
    ];

    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final p = products[index];
          return GestureDetector(
            onTap: () => context.push('/shopping/product/p$index'),
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.extraLightGrey,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            size: 44,
                            color: AppColors.shopping.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: AppSpacing.shadowSm,
                          ),
                          child: const Icon(
                            Icons.favorite_border_rounded,
                            size: 16,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: AppTextStyles.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(p.category, style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(p.price, style: AppTextStyles.priceSmall),
                            const SizedBox(width: 6),
                            Text(p.oldPrice, style: AppTextStyles.priceOld),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductData {
  final String name;
  final String category;
  final String price;
  final String oldPrice;
  final double rating;

  _ProductData(this.name, this.category, this.price, this.oldPrice, this.rating);
}
