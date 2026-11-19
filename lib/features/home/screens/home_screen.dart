import 'package:flutter/material.dart';
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
import '../../../core/widgets/app_search_bar.dart';
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
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: AppSearchBar(
                  hint: l10n.t('common.search_services'),
                  readOnly: true,
                  onTap: () => context.push('/search'),
                ),
              ),
            ),

            // Promo Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _PromoBanner(),
              ),
            ),

            // Services Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                child: Column(
                  children: [
                    SectionHeader(title: l10n.t('home.services')),
                    const SizedBox(height: 14),
                    _ServicesGrid(enabledModules: enabledModuleIds),
                  ],
                ),
              ),
            ),

            //Special Offers
            if (hasEnabledOfferModules)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: Column(
                    children: [
                      SectionHeader(
                        title: '${l10n.t('home.special_offers')} 🔥',
                        //actionText: l10n.t('common.see_all'),
                        //onAction: () => context.push('/promotions'),
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
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
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

            // Top Doctors
            if (moduleProvider.isEnabled('doctor'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
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

            // Trending Products
            if (moduleProvider.isEnabled('shopping'))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
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
    // Greeting line boxes: bodySmall (12 × 1.5) over h4 (18 × 1.4), and the
    // SectionHeader row is a single h4 line — all scaled like real Text is.
    final locationLineBox = 12 * 1.5 * textScale;
    final nameLineBox = 18 * 1.4 * textScale;
    final sectionHeaderHeight = 18 * 1.4 * textScale;
    final serviceCount = _serviceModuleKeys
        .where((moduleId) => enabledModuleIds.contains(moduleId))
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AppShimmer(
          child: CustomScrollView(
            slivers: [
              // Greeting row — same spot as the loaded header row.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      const ShimmerBlock(width: 48, height: 48, radius: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: locationLineBox,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ShimmerBlock(
                                  width: 110,
                                  height: 12,
                                  radius: 6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: nameLineBox,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: ShimmerBlock(
                                  width: 150,
                                  height: 18,
                                  radius: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const ShimmerBlock(width: 48, height: 48, radius: 14),
                    ],
                  ),
                ),
              ),

              // Search bar — AppSearchBar is 50 tall with radiusLg.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: const ShimmerBlock(
                    width: double.infinity,
                    height: 50,
                    radius: AppSpacing.radiusLg,
                  ),
                ),
              ),

              // Promo banner — 132 tall, radius 20.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: const ShimmerBlock(
                    width: double.infinity,
                    height: 132,
                    radius: 20,
                  ),
                ),
              ),

              // Services grid.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
                  child: Column(
                    children: [
                      _shimmerSectionHeader(
                        titleWidth: 96,
                        height: sectionHeaderHeight,
                      ),
                      const SizedBox(height: 14),
                      _ServicesGridShimmer(count: serviceCount),
                    ],
                  ),
                ),
              ),

              // Special offers (grocery / pharmacy / ride).
              if (hasEnabledOfferModules)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child: Column(
                      children: [
                        _shimmerSectionHeader(
                          titleWidth: 130,
                          height: sectionHeaderHeight,
                        ),
                        const SizedBox(height: 12),
                        _shimmerCardRow(height: 92, cardWidth: 280),
                      ],
                    ),
                  ),
                ),

              // Popular restaurants (food).
              if (moduleProvider.isEnabled('food'))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Column(
                      children: [
                        _shimmerSectionHeader(
                          titleWidth: 150,
                          height: sectionHeaderHeight,
                          showAction: true,
                        ),
                        const SizedBox(height: 16),
                        _shimmerCardRow(height: 230, cardWidth: 220),
                      ],
                    ),
                  ),
                ),

              // Top doctors.
              if (moduleProvider.isEnabled('doctor'))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Column(
                      children: [
                        _shimmerSectionHeader(
                          titleWidth: 130,
                          height: sectionHeaderHeight,
                          showAction: true,
                        ),
                        const SizedBox(height: 16),
                        _shimmerCardRow(height: 110, cardWidth: 260),
                      ],
                    ),
                  ),
                ),

              // Trending products (shopping).
              if (moduleProvider.isEnabled('shopping'))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 24),
                    child: Column(
                      children: [
                        _shimmerSectionHeader(
                          titleWidth: 160,
                          height: sectionHeaderHeight,
                          showAction: true,
                        ),
                        const SizedBox(height: 16),
                        _shimmerCardRow(height: 260, cardWidth: 180),
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
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: user?.avatarUrl != null && user!.avatarUrl!.trim().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stackTrace) => const Icon(
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
              mainAxisAlignment: MainAxisAlignment.center,
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
          fit: BoxFit.cover,
          alignment: Alignment.center,
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
        key: 'parcel',
        assetPath: 'assets/icons/package.png',
        title: l10n.t('home.parcel'),
        color: AppColors.shopping,
        bgColor: AppColors.shoppingBg,
        route: '/parcel',
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
      _ServiceItem(
        key: 'grocery',
        assetPath: 'assets/icons/grocery.png',
        title: l10n.t('home.grocery'),
        color: AppColors.grocery,
        bgColor: AppColors.groceryBg,
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

    // ── 2 modules: two wide cards side-by-side (each spans 2 normal slots) ──
    if (services.length == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _WideServiceCard(service: services[0])),
              const SizedBox(width: 10),
              Expanded(child: _WideServiceCard(service: services[1])),
            ],
          ),
        ),
      );
    }

    // ── 3 modules: two normal cards + one wide card filling remaining space ──
    if (services.length == 3) {
      const cardHeight = 80.0;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: cardHeight,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: _NarrowServiceCard(service: services[0]),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _NarrowServiceCard(service: services[1]),
              ),
              const SizedBox(width: 8),
              // Third card spans 2 normal slots → wide horizontal layout
              Expanded(flex: 2, child: _WideServiceCard(service: services[2])),
            ],
          ),
        ),
      );
    }

    // ── 4+ modules: original 4-column grid ───────────────────────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          childAspectRatio: serviceGridAspectRatio,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () => context.push(service.route),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final iconSize = constraints.maxHeight >= 92 ? 58.0 : 54.0;
                final iconPadding = iconSize >= 58 ? 11.0 : 10.0;
                final gap = constraints.maxHeight >= 92 ? 7.0 : 6.0;
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

// ── Wide card: horizontal layout (icon left, label right) ────────────────────
// Used for 2-module layout (each card) and 3-module layout (third card).
class _WideServiceCard extends StatelessWidget {
  const _WideServiceCard({required this.service});
  final _ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(service.route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  service.assetPath,
                  fit: BoxFit.contain,
                  color: AppColors.primary,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.widgets_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                service.title,
                style: AppTextStyles.labelMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Narrow card: vertical layout matching original grid cell ─────────────────
// Used for the first two cards in the 3-module layout.
class _NarrowServiceCard extends StatelessWidget {
  const _NarrowServiceCard({required this.service});
  final _ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(service.route),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Image.asset(
                service.assetPath,
                fit: BoxFit.contain,
                color: AppColors.primary,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.widgets_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            service.title,
            style: AppTextStyles.labelMedium,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
/// (h4: 18px × 1.4, scaled by the system text scale).
Widget _shimmerSectionHeader({
  required double titleWidth,
  required double height,
  bool showAction = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerBlock(width: titleWidth, height: 18),
          if (showAction) const ShimmerBlock(width: 52, height: 14, radius: 7),
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

/// Services grid skeleton: reproduces the loaded grid's branching layouts
/// (0 / 1 / 2 / 3 / 4+ enabled modules) with the same dimensions.
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

    // 2 modules: two wide cards side by side (74 tall = 14 padding + 46 icon).
    if (count == 2) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: ShimmerBlock(
                width: double.infinity,
                height: 74,
                radius: 20,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ShimmerBlock(
                width: double.infinity,
                height: 74,
                radius: 20,
              ),
            ),
          ],
        ),
      );
    }

    // 3 modules: two normal slots + one wide slot, 80 tall.
    if (count == 3) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: ShimmerBlock(
                  width: double.infinity,
                  height: 80,
                  radius: 20,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: ShimmerBlock(
                  width: double.infinity,
                  height: 80,
                  radius: 20,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ShimmerBlock(
                  width: double.infinity,
                  height: 80,
                  radius: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 1 or 4+ modules: the same 4-column grid the loaded view uses.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          childAspectRatio: _servicesGridAspectRatio(context),
        ),
        itemCount: count,
        itemBuilder: (context, index) => const _GridServiceTileShimmer(),
      ),
    );
  }
}

/// One grid cell: icon block over label block, matching the loaded tile
/// (transparent cell, 54–58px icon, centred label underneath).
class _GridServiceTileShimmer extends StatelessWidget {
  const _GridServiceTileShimmer();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.maxHeight >= 92 ? 58.0 : 54.0;
        final gap = constraints.maxHeight >= 92 ? 7.0 : 6.0;
        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            ShimmerBlock(width: iconSize, height: iconSize, radius: 18),
            SizedBox(height: gap),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ShimmerBlock(width: 52, height: 12, radius: 6),
              ),
            ),
          ],
        );
      },
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
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: offers.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final offer = offers[index];
          return Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: offer.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: offer.color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: offer.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(offer.icon, color: offer.color, size: 22),
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
                      const SizedBox(height: 6),
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
                        child:
                            restaurant.imageUrl != null &&
                                restaurant.imageUrl!.trim().isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.network(
                                  restaurant.imageUrl!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) {
                                    return Center(
                                      child: Icon(
                                        Icons.restaurant_rounded,
                                        size: 40,
                                        color: AppColors.food.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Center(
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
                        child:
                            doctor.imageUrl != null &&
                                doctor.imageUrl!.trim().isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  doctor.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.doctor,
                                    size: 28,
                                  ),
                                ),
                              )
                            : const Icon(
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
                                  'DJF${product.price.toStringAsFixed(0)}',
                                  style: AppTextStyles.priceSmall,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  product.originalPrice != null
                                      ? 'DJF${product.originalPrice!.toStringAsFixed(0)}'
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
