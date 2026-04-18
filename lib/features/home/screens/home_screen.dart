import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/notification_bell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserLocationProvider>().ensureCurrentLocation(
        requestPermission: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final locationProvider = context.watch<UserLocationProvider>();
    final moduleProvider = context.watch<ModuleProvider>();
    final enabledModuleIds = moduleProvider.enabledModuleIds;
    final locationTitle = locationProvider.location?.title;
    final locationSubtitle = locationProvider.location?.subtitle;
    final displayName = user != null && user.fullName.trim().isNotEmpty
        ? user.fullName
        : l10n.t('profile.guest');
    final locationDisplay = locationProvider.isLoading
        ? 'Detecting your location...'
        : (locationSubtitle ??
              locationTitle ??
              l10n.t('ride.current_location'));
    final hasEnabledOfferModules =
        moduleProvider.isEnabled('grocery') ||
        moduleProvider.isEnabled('pharmacy') ||
        moduleProvider.isEnabled('ride');
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FadeInLeft(
                  duration: const Duration(milliseconds: 240),
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
                        child:
                            user?.avatarUrl != null &&
                                user!.avatarUrl!.trim().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stackTrace) =>
                                      const Icon(
                                        Icons.person_rounded,
                                        color: AppColors.white,
                                        size: 24,
                                      ),
                                ),
                              )
                            : const Icon(
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
                              locationDisplay,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(displayName, style: AppTextStyles.h4),
                          ],
                        ),
                      ),
                      // Notification bell
                      const NotificationBell(),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: FadeInUp(
                  delay: const Duration(milliseconds: 20),
                  duration: const Duration(milliseconds: 240),
                  child: AppSearchBar(
                    hint: l10n.t('common.search_services'),
                    readOnly: true,
                    onTap: () => context.push('/search'),
                  ),
                ),
              ),
            ),

            // Promo Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: FadeInUp(
                  delay: const Duration(milliseconds: 40),
                  duration: const Duration(milliseconds: 240),
                  child: _PromoBanner(),
                ),
              ),
            ),

            // Services Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: FadeInUp(
                  delay: const Duration(milliseconds: 60),
                  duration: const Duration(milliseconds: 240),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: l10n.t('home.services'),
                        actionText: l10n.t('common.see_all'),
                      ),
                      const SizedBox(height: 16),
                      _ServicesGrid(enabledModules: enabledModuleIds),
                    ],
                  ),
                ),
              ),
            ),

            // Special Offers
            if (hasEnabledOfferModules)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 80),
                    duration: const Duration(milliseconds: 240),
                    child: Column(
                      children: [
                        SectionHeader(
                          title: '${l10n.t('home.special_offers')} 🔥',
                          actionText: l10n.t('common.see_all'),
                          onAction: () => context.push('/promotions'),
                        ),
                        const SizedBox(height: 16),
                        _SpecialOffers(enabledModules: enabledModuleIds),
                      ],
                    ),
                  ),
                ),
              ),

            // Popular Restaurants
            if (moduleProvider.isEnabled('food'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 240),
                    child: Column(
                      children: [
                        SectionHeader(
                          title: l10n.t('home.popular_restaurants'),
                          actionText: l10n.t('common.see_all'),
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
            if (moduleProvider.isEnabled('doctor'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 120),
                    duration: const Duration(milliseconds: 240),
                    child: Column(
                      children: [
                        SectionHeader(
                          title: l10n.t('home.top_doctors'),
                          actionText: l10n.t('common.see_all'),
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
            if (moduleProvider.isEnabled('shopping'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 28, 0, 24),
                  child: FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    duration: const Duration(milliseconds: 240),
                    child: Column(
                      children: [
                        SectionHeader(
                          title: l10n.t('home.trending_products'),
                          actionText: l10n.t('common.see_all'),
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
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/banners/banner.png'),
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.enabledModules});

  final Set<String> enabledModules;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.35);
    final serviceGridAspectRatio =
        (0.8 -
                (l10n.languageCode == 'en' ? 0.0 : 0.05) -
                ((textScale - 1.0) * 0.12))
            .clamp(0.68, 0.8);
    final services = [
      _ServiceItem(
        key: 'food',
        assetPath: 'assets/icons/food.png',
        title: l10n.t('home.food'),
        color: AppColors.food,
        bgColor: AppColors.foodBg,
        route: '/food',
      ),
      _ServiceItem(
        key: 'shopping',
        assetPath: 'assets/icons/shopping.png',
        title: l10n.t('home.shopping'),
        color: AppColors.shopping,
        bgColor: AppColors.shoppingBg,
        route: '/shopping',
      ),
      _ServiceItem(
        key: 'doctor',
        assetPath: 'assets/icons/doctor.png',
        title: l10n.t('home.doctor'),
        color: AppColors.doctor,
        bgColor: AppColors.doctorBg,
        route: '/doctor',
      ),
      _ServiceItem(
        key: 'hotel',
        assetPath: 'assets/icons/hotel.png',
        title: l10n.t('home.hotel'),
        color: AppColors.hotel,
        bgColor: AppColors.hotelBg,
        route: '/hotel',
      ),
      _ServiceItem(
        key: 'ride',
        assetPath: 'assets/icons/car.png',
        title: l10n.t('home.ride'),
        color: AppColors.ride,
        bgColor: AppColors.rideBg,
        route: '/ride',
      ),
      _ServiceItem(
        key: 'pharmacy',
        assetPath: 'assets/icons/pharmacy.png',
        title: l10n.t('home.pharmacy'),
        color: AppColors.pharmacy,
        bgColor: AppColors.pharmacyBg,
        route: '/pharmacy',
      ),
      _ServiceItem(
        key: 'home-services',
        assetPath: 'assets/icons/repair-service.png',
        title: l10n.t('home.home_services'),
        color: AppColors.homeServices,
        bgColor: AppColors.homeServicesBg,
        route: '/home-services',
      ),
      _ServiceItem(
        key: 'laundry',
        assetPath: 'assets/icons/laundry.png',
        title: l10n.t('home.laundry'),
        color: AppColors.laundry,
        bgColor: AppColors.laundryBg,
        route: '/laundry',
      ),
    ].where((service) => enabledModules.contains(service.key)).toList();

    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(child: Text('No services are available right now.')),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: serviceGridAspectRatio,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () => context.push(service.route),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final iconSize = constraints.maxHeight >= 96 ? 60.0 : 54.0;
                final iconPadding = iconSize >= 58 ? 12.0 : 10.0;
                final gap = constraints.maxHeight >= 96 ? 8.0 : 6.0;
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(iconPadding),
                        child: Image.asset(
                          service.assetPath,
                          fit: BoxFit.contain,
                          color: AppColors.primary,
                          colorBlendMode: BlendMode.srcIn,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.widgets_rounded,
                              color: AppColors.primary,
                              size: 28,
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: gap),
                    Expanded(
                      child: Text(
                        service.title,
                        style: AppTextStyles.labelMedium,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ServiceItem {
  final String key;
  final String assetPath;
  final String title;
  final Color color;
  final Color bgColor;
  final String route;

  const _ServiceItem({
    required this.key,
    required this.assetPath,
    required this.title,
    required this.color,
    required this.bgColor,
    required this.route,
  });
}

class _SpecialOffers extends StatelessWidget {
  const _SpecialOffers({required this.enabledModules});

  final Set<String> enabledModules;

  @override
  Widget build(BuildContext context) {
    final offers = [
      _OfferData(
        '40% OFF',
        'Fresh Groceries',
        'Free delivery on orders above \$30',
        AppColors.grocery,
        Icons.local_grocery_store_rounded,
        moduleId: 'grocery',
      ),
      _OfferData(
        '25% OFF',
        'Medicine Delivery',
        'Upload prescription & save more',
        AppColors.pharmacy,
        Icons.medication_rounded,
        moduleId: 'pharmacy',
      ),
      _OfferData(
        'Free Ride',
        'First 3 Rides Free',
        'New user exclusive offer',
        AppColors.ride,
        Icons.directions_car_rounded,
        moduleId: 'ride',
      ),
    ].where((offer) => enabledModules.contains(offer.moduleId)).toList();

    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: offers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: offer.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: offer.color.withValues(alpha: 0.2)),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
  final String moduleId;
  final String discount;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  _OfferData(
    this.discount,
    this.title,
    this.subtitle,
    this.color,
    this.icon, {
    required this.moduleId,
  });
}

class _PopularRestaurants extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: ApiClient.get('/catalog/restaurants'),
      builder: (context, snapshot) {
        final restaurants = snapshot.hasData
            ? ((snapshot.data as List)
                  .map(
                    (entry) => RestaurantModel.fromApi(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .take(3)
                  .toList())
            : RestaurantModel.sampleRestaurants.take(3).toList();

        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return GestureDetector(
                onTap: () => context.push('/food/restaurant/${restaurant.id}'),
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
                            Text(
                              restaurant.name,
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              restaurant.cuisine,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  restaurant.rating.toString(),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: AppColors.mediumGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  restaurant.deliveryTime,
                                  style: AppTextStyles.caption,
                                ),
                                const Spacer(),
                                Text(
                                  restaurant.deliveryFee,
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
      },
    );
  }
}

class _TopDoctors extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: ApiClient.get('/catalog/doctors'),
      builder: (context, snapshot) {
        final doctors = snapshot.hasData
            ? ((snapshot.data as List)
                  .map(
                    (entry) => DoctorModel.fromApi(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .take(3)
                  .toList())
            : DoctorModel.sampleDoctors.take(3).toList();

        return SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: doctors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return GestureDetector(
                onTap: () => context.push('/doctor/detail/${doctor.id}'),
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
                          color: AppColors.doctor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.doctor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              doctor.name,
                              style: AppTextStyles.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctor.specialty,
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${doctor.rating}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.dark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  doctor.experience,
                                  style: AppTextStyles.caption,
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
      },
    );
  }
}

class _TrendingProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: ApiClient.get('/catalog/products?moduleType=shopping'),
      builder: (context, snapshot) {
        final products = snapshot.hasData
            ? ((snapshot.data as List)
                  .map(
                    (entry) => ProductModel.fromApi(
                      Map<String, dynamic>.from(entry as Map),
                    ),
                  )
                  .take(3)
                  .toList())
            : ProductModel.sampleProducts.take(3).toList();

        return SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => context.push('/shopping/product/${product.id}'),
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
                                color: AppColors.shopping.withValues(
                                  alpha: 0.4,
                                ),
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
                            Text(
                              product.name,
                              style: AppTextStyles.labelLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.category,
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '\$${product.price.toStringAsFixed(0)}',
                                  style: AppTextStyles.priceSmall,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  product.originalPrice != null
                                      ? '\$${product.originalPrice!.toStringAsFixed(0)}'
                                      : '',
                                  style: AppTextStyles.priceOld,
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
      },
    );
  }
}
