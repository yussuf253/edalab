import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/config/zone_scope.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../food/screens/food_screen.dart';
import '../../doctor/screens/doctor_screen.dart';
import '../../shopping/screens/shopping_screen.dart';
import '../../ride/screens/ride_screen.dart';
import '../../parcel/screens/parcel_screen.dart';
import '../../pharmacy/screens/pharmacy_screen.dart';
import '../../hotel/screens/hotel_screen.dart';
import '../../home_services/screens/home_services_screen.dart';
import '../../laundry/screens/laundry_screen.dart';
import '../../grocery/screens/grocery_screen.dart';

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
        ? l10n.t('home.detecting_location')
        : (locationSubtitle ??
              locationTitle ??
              l10n.t('ride.current_location'));
    final hasEnabledOfferModules =
        moduleProvider.isEnabled('grocery') ||
        moduleProvider.isEnabled('pharmacy') ||
        moduleProvider.isEnabled('ride');

    // ── Config-not-ready guard ────────────────────────────────────────────
    // Until the persisted module config is loaded (fresh install: nothing
    // stored yet, server fetch still in flight), the enabled set only
    // reflects hardcoded defaults. Show a shimmer instead of flashing all
    // modules on for a moment.
    //
    // Hydration is awaited before the first frame, so the real wait is the
    // *first server sync* of this app run — on a fresh install nothing is
    // stored yet (the enabled set would just be the all-active defaults),
    // and even with a stored config the sync is what makes the screen
    // current. Keep the shimmer up until it settles instead of flashing
    // content that is about to change.
    final isInitialSyncPending =
        moduleProvider.isLoading && !moduleProvider.hasSyncedOnce;
    if (!moduleProvider.isReady || isInitialSyncPending) {
      return _buildInitialSyncShimmer(
        user: user,
        displayName: displayName,
        locationDisplay: locationDisplay,
        enabledModuleIds: enabledModuleIds,
        hasEnabledOfferModules: hasEnabledOfferModules,
        moduleProvider: moduleProvider,
      );
    }
    // ──────────────────────────────────────────────────────────────────────

    // ── Single-module fast-path ──────────────────────────────────────────────
    // When exactly one module is active, render its screen directly so the
    // user lands straight into the service without an extra tap.
    // The home app bar is preserved; the module screen's own AppBar (including
    // its back button) is hidden by collapsing toolbarHeight to 0 via Theme.
    if (enabledModuleIds.length == 1) {
      Widget? moduleScreen;
      switch (enabledModuleIds.first) {
        case 'food':
          moduleScreen = const FoodScreen();
        case 'doctor':
          moduleScreen = const DoctorScreen();
        case 'shopping':
          moduleScreen = const ShoppingScreen();
        case 'ride':
          moduleScreen = const RideScreen();
        case 'parcel':
          moduleScreen = const ParcelScreen();
        case 'pharmacy':
          moduleScreen = const PharmacyScreen();
        case 'hotel':
          moduleScreen = const HotelScreen();
        case 'home-services':
          moduleScreen = const HomeServicesScreen();
        case 'laundry':
          moduleScreen = const LaundryScreen();
        case 'grocery':
          moduleScreen = const GroceryScreen();
      }
      if (moduleScreen != null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildHomeAppBar(context, user, displayName, locationDisplay),
          body: Theme(
            // Collapse the inner module screen's AppBar to 0 height so its
            // title and back button are invisible without touching each screen.
            data: Theme.of(context).copyWith(
              appBarTheme: Theme.of(
                context,
              ).appBarTheme.copyWith(toolbarHeight: 0),
            ),
            child: moduleScreen,
          ),
        );
      }
    }
    // ────────────────────────────────────────────────────────────────────────

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header: greeting, location, notifications, search.
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(20, 10, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _HomeAvatar(user: user, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 13,
                                    color: AppColors.mediumGrey,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      locationDisplay,
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                displayName,
                                style: AppTextStyles.h4.copyWith(
                                  fontSize: 16.5,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const NotificationBell(
                          size: 40,
                          backgroundColor: AppColors.white,
                          iconColor: AppColors.dark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _HomeSearchPill(
                      hint: l10n.t('common.search_services'),
                      onTap: () => context.push('/search'),
                    ),
                  ],
                ),
              ),
            ),

            // Promo banner — swipeable promotions, right under the header.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: const _PromoBanner(),
              ),
            ),

            // Services Grid — module tiles under the banner.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 34, 0, 0),
                child: _ServicesGrid(enabledModules: enabledModuleIds),
              ),
            ),

            //Special Offers
            if (hasEnabledOfferModules)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: l10n.t('home.special_offers'),
                        actionText: l10n.t('common.see_all'),
                        onAction: () => context.push('/promotions'),
                      ),
                      const SizedBox(height: 12),
                      _SpecialOffers(enabledModules: enabledModuleIds),
                    ],
                  ),
                ),
              ),

            // Popular Restaurants
            if (moduleProvider.isEnabled('food'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: l10n.t('home.popular_restaurants'),
                        actionText: l10n.t('common.see_all'),
                        onAction: () => context.push('/food'),
                      ),
                      const SizedBox(height: 12),
                      _PopularRestaurants(),
                    ],
                  ),
                ),
              ),

            // Top Doctors
            if (moduleProvider.isEnabled('doctor'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: l10n.t('home.top_doctors'),
                        actionText: l10n.t('common.see_all'),
                        onAction: () => context.push('/doctor'),
                      ),
                      const SizedBox(height: 12),
                      _TopDoctors(),
                    ],
                  ),
                ),
              ),

            // Trending Products
            if (moduleProvider.isEnabled('shopping'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 22, 0, 24),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: l10n.t('home.trending_products'),
                        actionText: l10n.t('common.see_all'),
                        onAction: () => context.push('/shopping'),
                      ),
                      const SizedBox(height: 12),
                      _TrendingProducts(),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  /// Skeleton shown from the first frame until the initial module sync of
  /// this run settles.
  ///
  /// It mirrors the loaded layout section by section — same SafeArea +
  /// CustomScrollView, same paddings, same section order, sizes and
  /// visibility predicates — so nothing on screen moves when the real
  /// content replaces it.
  Widget _buildInitialSyncShimmer({
    required dynamic user,
    required String displayName,
    required String locationDisplay,
    required Set<String> enabledModuleIds,
    required bool hasEnabledOfferModules,
    required ModuleProvider moduleProvider,
  }) {
    // Single-module runs keep the home AppBar and drop straight into that
    // module's own screen, so mirror that shell instead of the hub.
    if (enabledModuleIds.length == 1) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildHomeAppBar(context, user, displayName, locationDisplay),
        body: ModuleFeedShimmer(
          accentColor: AppColors.primary,
          showSearch: true,
          showBanner: true,
          showRoundCategories: true,
        ),
      );
    }

    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    // The SectionHeader row is a single h4 line — scaled like real Text is.
    final sectionHeaderHeight = 16 * 1.4 * textScale;
    final serviceCount = _serviceModuleKeys
        .where((moduleId) => enabledModuleIds.contains(moduleId))
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: AppShimmer(
          child: CustomScrollView(
            slivers: [
              // Header block — avatar · greeting · bell · search pill.
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.fromLTRB(20, 10, 16, 16),
                  child: Column(
                    children: const [
                      Row(
                        children: [
                          ShimmerCircle(size: 42),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShimmerBlock(width: 120, height: 11, radius: 6),
                                SizedBox(height: 7),
                                ShimmerBlock(width: 150, height: 15, radius: 6),
                              ],
                            ),
                          ),
                          SizedBox(width: 8),
                          ShimmerBlock(width: 40, height: 40, radius: 20),
                        ],
                      ),
                      SizedBox(height: 14),
                      ShimmerBlock(
                        width: double.infinity,
                        height: 50,
                        radius: 14,
                      ),
                    ],
                  ),
                ),
              ),

              // Promo banner — 150 tall, radius 16.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: const ShimmerBlock(
                    width: double.infinity,
                    height: 150,
                    radius: 16,
                  ),
                ),
              ),

              // Services grid.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 18, 0, 0),
                  child: _ServicesGridShimmer(count: serviceCount),
                ),
              ),

              // Special offers (grocery / pharmacy / ride).
              if (hasEnabledOfferModules)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                    child: Column(
                      children: [
                        _shimmerSectionHeader(
                          titleWidth: 130,
                          height: sectionHeaderHeight,
                        ),
                        const SizedBox(height: 12),
                        _shimmerCardRow(height: 88, cardWidth: 280),
                      ],
                    ),
                  ),
                ),

              // Popular restaurants (food).
              if (moduleProvider.isEnabled('food'))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                    child: Column(
                      children: [
                        _shimmerSectionHeader(
                          titleWidth: 150,
                          height: sectionHeaderHeight,
                        ),
                        const SizedBox(height: 12),
                        _shimmerCardRow(height: 190, cardWidth: 184),
                      ],
                    ),
                  ),
                ),

              // Top doctors.
              if (moduleProvider.isEnabled('doctor'))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 22, 0, 0),
                    child: Column(
                      children: [
                        _shimmerSectionHeader(
                          titleWidth: 130,
                          height: sectionHeaderHeight,
                        ),
                        const SizedBox(height: 12),
                        _shimmerCardRow(height: 88, cardWidth: 256),
                      ],
                    ),
                  ),
                ),

              // Trending products (shopping).
              if (moduleProvider.isEnabled('shopping'))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 22, 0, 24),
                    child: Column(
                      children: [
                        _shimmerSectionHeader(
                          titleWidth: 160,
                          height: sectionHeaderHeight,
                        ),
                        const SizedBox(height: 12),
                        _shimmerCardRow(height: 232, cardWidth: 168),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the home-style AppBar used both in the normal hub and in
  /// single-module mode. Matches the greeting row in the regular ScrollView.
  PreferredSizeWidget _buildHomeAppBar(
    BuildContext context,
    dynamic user,
    String displayName,
    String locationDisplay,
  ) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleSpacing: 20,
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      title: Row(
        children: [
          _HomeAvatar(user: user, size: 42),
          const SizedBox(width: 12),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppColors.mediumGrey,
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        locationDisplay,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  displayName,
                  style: AppTextStyles.h4.copyWith(
                    fontSize: 16.5,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification bell
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: NotificationBell(
              size: 40,
              backgroundColor: AppColors.white,
              iconColor: AppColors.dark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Swipeable promotion banners (art ships with its own copy).
class _PromoBanner extends StatefulWidget {
  const _PromoBanner();

  @override
  State<_PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<_PromoBanner> {
  static const List<String> _promotions = [
    'assets/images/promotions/food1.png',
    'assets/images/promotions/grocery1.png',
    'assets/images/promotions/food2.png',
    'assets/images/promotions/grocery2.png',
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: _promotions.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) => Image.asset(
                _promotions[index],
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_promotions.length, (index) {
                  final isActive = index == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.white
                          : AppColors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
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
    final serviceGridAspectRatio = _servicesGridAspectRatio(context);
    final services = [
      _ServiceItem(
        key: 'food',
        assetPath: 'assets/icons/food.png',
        imagePath: 'assets/images/modules/catg_food.png',
        title: l10n.t('home.food'),
        color: AppColors.food,
        bgColor: AppColors.tile,
        route: '/food',
      ),
      _ServiceItem(
        key: 'shopping',
        assetPath: 'assets/icons/shopping.png',
        imagePath: 'assets/images/modules/catg_ecommerce.png',
        title: l10n.t('home.shopping'),
        color: AppColors.shopping,
        bgColor: AppColors.tile,
        route: '/shopping',
      ),
      _ServiceItem(
        key: 'doctor',
        assetPath: 'assets/icons/doctor.png',
        title: l10n.t('home.doctor'),
        color: AppColors.doctor,
        bgColor: AppColors.tile,
        route: '/doctor',
      ),
      _ServiceItem(
        key: 'hotel',
        assetPath: 'assets/icons/hotel.png',
        title: l10n.t('home.hotel'),
        color: AppColors.hotel,
        bgColor: AppColors.tile,
        route: '/hotel',
      ),
      _ServiceItem(
        key: 'ride',
        assetPath: 'assets/icons/car.png',
        imagePath: 'assets/images/modules/catg_ride.png',
        title: l10n.t('home.ride'),
        color: AppColors.ride,
        bgColor: AppColors.tile,
        route: '/ride',
      ),
      _ServiceItem(
        key: 'parcel',
        assetPath: 'assets/icons/package.png',
        imagePath: 'assets/images/modules/catg_parcel.png',
        title: l10n.t('home.parcel'),
        color: AppColors.shopping,
        bgColor: AppColors.tile,
        route: '/parcel',
      ),
      _ServiceItem(
        key: 'pharmacy',
        assetPath: 'assets/icons/pharmacy.png',
        imagePath: 'assets/images/modules/catg_medicine.png',
        title: l10n.t('home.pharmacy'),
        color: AppColors.pharmacy,
        bgColor: AppColors.tile,
        route: '/pharmacy',
      ),
      _ServiceItem(
        key: 'home-services',
        assetPath: 'assets/icons/repair-service.png',
        imagePath: 'assets/images/modules/catg_hanydman.png',
        title: l10n.t('home.home_services'),
        color: AppColors.homeServices,
        bgColor: AppColors.tile,
        route: '/home-services',
      ),
      _ServiceItem(
        key: 'laundry',
        assetPath: 'assets/icons/laundry.png',
        title: l10n.t('home.laundry'),
        color: AppColors.laundry,
        bgColor: AppColors.tile,
        route: '/laundry',
      ),
      _ServiceItem(
        key: 'grocery',
        assetPath: 'assets/icons/grocery.png',
        imagePath: 'assets/images/modules/catg_grocery.png',
        title: l10n.t('home.grocery'),
        color: AppColors.grocery,
        bgColor: AppColors.tile,
        route: '/grocery',
      ),
    ].where((service) => enabledModules.contains(service.key)).toList();

    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(
          child: Text(context.l10n.t('home.no_services_available')),
        ),
      );
    }

    // ── 4-column icon-tile grid (any module count) ────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 10,
          childAspectRatio: serviceGridAspectRatio,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(service.route),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = constraints.maxWidth.clamp(46.0, 62.0);
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: tileSize,
                        height: tileSize,
                        decoration: BoxDecoration(
                          color: service.imagePath == null
                              ? service.bgColor
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: service.imagePath != null
                            ? Image.asset(
                                service.imagePath!,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      Icons.widgets_rounded,
                                      color: service.color,
                                      size: 24,
                                    ),
                              )
                            : Padding(
                                padding: EdgeInsets.all(tileSize * 0.26),
                                child: Image.asset(
                                  service.assetPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.widgets_rounded,
                                      color: service.color,
                                      size: 24,
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.25,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

/// Module ids the home services grid knows how to render — keeps the
/// skeleton's tile count in step with the loaded grid.
const _serviceModuleKeys = <String>{
  'food',
  'shopping',
  'doctor',
  'hotel',
  'ride',
  'parcel',
  'pharmacy',
  'home-services',
  'laundry',
  'grocery',
};

/// Aspect ratio of the 4-column services grid, shared by the loaded grid and
/// its skeleton so both lay out identically.
double _servicesGridAspectRatio(BuildContext context) {
  final textScale = MediaQuery.textScalerOf(
    context,
  ).scale(1.0).clamp(1.0, 1.35);
  final ratio =
      0.82 -
      (context.l10n.languageCode == 'en' ? 0.0 : 0.05) -
      ((textScale - 1.0) * 0.12);
  return ratio.clamp(0.72, 0.84).toDouble();
}

/// Section-title placeholder with the same line box as [SectionHeader]
/// (h4: 16px × 1.4, scaled by the system text scale).
Widget _shimmerSectionHeader({
  required double titleWidth,
  required double height,
  bool showAction = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerBlock(width: titleWidth, height: 16),
          if (showAction) const ShimmerBlock(width: 62, height: 12, radius: 6),
        ],
      ),
    ),
  );
}

/// Horizontal card rail with the same geometry as the loaded sections
/// (20px side padding, 14px gap between cards).
Widget _shimmerCardRow({
  required double height,
  required double cardWidth,
  double radius = 16,
  int cards = 2,
}) {
  return SizedBox(
    height: height,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            for (var i = 0; i < cards; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              ShimmerBlock(width: cardWidth, height: height, radius: radius),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Services grid skeleton: reproduces the loaded grid's geometry
/// (40px icon tile + label line, 4 columns) with the same dimensions.
class _ServicesGridShimmer extends StatelessWidget {
  const _ServicesGridShimmer({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Center(child: ShimmerBlock(width: 180, height: 14, radius: 7)),
      );
    }

    // Always the same 4-column grid the loaded view uses.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 10,
          childAspectRatio: _servicesGridAspectRatio(context),
        ),
        itemCount: count,
        itemBuilder: (context, index) => const _GridServiceTileShimmer(),
      ),
    );
  }
}

/// One grid cell: icon block over label block, matching the loaded tile
/// (transparent cell, 46–62px icon tile, centred label underneath).
class _GridServiceTileShimmer extends StatelessWidget {
  const _GridServiceTileShimmer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = constraints.maxWidth.clamp(46.0, 62.0);
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            ShimmerBlock(width: tileSize, height: tileSize, radius: 16),
            const SizedBox(height: 8),
            const ShimmerBlock(width: 52, height: 11, radius: 6),
          ],
        );
      },
    );
  }
}

class _ServiceItem {
  final String key;
  final String assetPath;
  final String? imagePath;
  final String title;
  final Color color;
  final Color bgColor;
  final String route;

  const _ServiceItem({
    required this.key,
    required this.assetPath,
    this.imagePath,
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
    final l10n = context.l10n;
    final offers = [
      _OfferData(
        l10n.t('home.offer.grocery_discount'),
        l10n.t('home.offer.grocery_title'),
        l10n.t('home.offer.grocery_subtitle'),
        AppColors.grocery,
        Icons.local_grocery_store_rounded,
        moduleId: 'grocery',
      ),
      _OfferData(
        l10n.t('home.offer.pharmacy_discount'),
        l10n.t('home.offer.pharmacy_title'),
        l10n.t('home.offer.pharmacy_subtitle'),
        AppColors.pharmacy,
        Icons.medication_rounded,
        moduleId: 'pharmacy',
      ),
      _OfferData(
        l10n.t('home.offer.ride_discount'),
        l10n.t('home.offer.ride_title'),
        l10n.t('home.offer.ride_subtitle'),
        AppColors.ride,
        Icons.directions_car_rounded,
        moduleId: 'ride',
      ),
    ].where((offer) => enabledModules.contains(offer.moduleId)).toList();

    if (offers.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: offers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.tile,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(offer.icon, color: offer.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              offer.discount,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        offer.title,
                        style: AppTextStyles.labelLarge.copyWith(fontSize: 13.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
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
      future: ApiClient.get(ZoneScope.appendZone('/catalog/restaurants')),
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
            : const <RestaurantModel>[];

        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: restaurants.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return GestureDetector(
                onTap: () => context.push('/food/restaurant/${restaurant.id}'),
                child: SizedBox(
                  width: 184,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 116,
                        width: 184,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: AppColors.tile),
                              if (restaurant.imageUrl != null &&
                                  restaurant.imageUrl!.trim().isNotEmpty)
                                Image.network(
                                  restaurant.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Icon(
                                      Icons.restaurant_rounded,
                                      size: 30,
                                      color: AppColors.mediumGrey,
                                    ),
                                  ),
                                )
                              else
                                Center(
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    size: 30,
                                    color: AppColors.mediumGrey,
                                  ),
                                ),
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 10,
                                        color: AppColors.white,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        restaurant.rating.toString(),
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          height: 1.1,
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
                      const SizedBox(height: 10),
                      Text(
                        restaurant.name,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        restaurant.cuisine,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppColors.mediumGrey,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            restaurant.deliveryTime,
                            style: AppTextStyles.caption,
                          ),
                          const SizedBox(width: 6),
                          Text('•', style: AppTextStyles.caption),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              restaurant.deliveryFee,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
      future: ApiClient.get(ZoneScope.appendZone('/catalog/doctors')),
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
            : const <DoctorModel>[];

        return SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: doctors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return GestureDetector(
                onTap: () => context.push('/doctor/detail/${doctor.id}'),
                child: Container(
                  width: 256,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.tile,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child:
                            doctor.imageUrl != null &&
                                doctor.imageUrl!.trim().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  doctor.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.mediumGrey,
                                    size: 26,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person_rounded,
                                color: AppColors.mediumGrey,
                                size: 26,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              doctor.name,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctor.specialty,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 13,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${doctor.rating}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.dark,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    doctor.experience,
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

class _TrendingProducts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: ApiClient.get(
        ZoneScope.appendZone('/catalog/products?moduleType=shopping'),
      ),
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
            : const <ProductModel>[];

        return SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () => context.push('/shopping/product/${product.id}'),
                child: Container(
                  width: 168,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 128,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: AppColors.tile),
                              if (product.images.isNotEmpty &&
                                  product.images.first.trim().isNotEmpty)
                                Image.network(
                                  product.images.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Center(
                                    child: Icon(
                                      Icons.shopping_bag_rounded,
                                      size: 32,
                                      color: AppColors.mediumGrey,
                                    ),
                                  ),
                                )
                              else
                                const Center(
                                  child: Icon(
                                    Icons.shopping_bag_rounded,
                                    size: 32,
                                    color: AppColors.mediumGrey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: AppTextStyles.labelLarge.copyWith(
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.category,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'DJF${product.price.toStringAsFixed(0)}',
                                  style: AppTextStyles.priceSmall,
                                ),
                                const SizedBox(width: 5),
                                if (product.originalPrice != null)
                                  Flexible(
                                    child: Text(
                                      'DJF${product.originalPrice!.toStringAsFixed(0)}',
                                      style: AppTextStyles.priceOld,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

/// Circular avatar shown in the home header.
class _HomeAvatar extends StatelessWidget {
  const _HomeAvatar({required this.user, required this.size});

  final dynamic user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl as String?;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        shape: BoxShape.circle,
      ),
      child: avatarUrl != null && avatarUrl.trim().isNotEmpty
          ? ClipOval(
              child: Image.network(
                avatarUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: size * 0.5,
                ),
              ),
            )
          : Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: size * 0.5,
            ),
    );
  }
}

/// Soft grey pill that opens the global search screen.
class _HomeSearchPill extends StatelessWidget {
  const _HomeSearchPill({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.tile,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.mediumGrey,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13.5,
                  color: AppColors.mediumGrey,
                ),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 16,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
