import 'package:edalab/core/providers/city_availability_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/messages/screens/chat_screen.dart';
import '../../features/auth/screens/pro_login_screen.dart';
import '../../features/auth/screens/pro_register_screen.dart';
import '../../features/auth/screens/pro_signup_screen.dart';
import '../../features/account/screens/pro_profile_management_screen.dart';
import '../../features/delivery/screens/delivery_queue_screen.dart';
import '../../features/doctor/screens/doctor_appointments_queue_screen.dart';
import '../../features/doctor/screens/doctor_availability_screen.dart';
import '../../features/doctor/screens/doctor_home_care_queue_screen.dart';
import '../../features/dashboard/screens/pro_dashboard_screen.dart';
import '../../features/doctor/screens/doctor_schedule_settings_screen.dart';
import '../../features/doctor/screens/doctor_setup_screen.dart';
import '../../features/entry/screens/pro_city_gate_screen.dart';
import '../../features/entry/screens/pro_entry_screen.dart';
import '../../features/onboarding/screens/pro_onboarding_screen.dart';
import '../../features/provider/screens/provider_availability_screen.dart';
import '../../features/provider/screens/provider_job_detail_screen.dart';
import '../../features/provider/screens/provider_jobs_queue_screen.dart';
import '../../features/provider/screens/provider_schedule_settings_screen.dart';
import '../../features/rider/screens/rider_active_delivery_screen.dart';
import '../../features/rider/screens/rider_active_trip_screen.dart';
import '../../features/rider/screens/rider_queue_screen.dart';
import '../../features/shop/screens/shop_orders_queue_screen.dart';
import '../../features/shop/screens/shop_products_screen.dart';
import '../../features/restaurant/screens/restaurant_menu_screen.dart';
import '../../features/shop/screens/shop_store_setup_screen.dart';
import '../../features/auth/screens/pro_banned_screen.dart';
import '../../features/super_admin/screens/pro_super_admin_screen.dart';
import '../models/pro_profile.dart';
import '../providers/pro_auth_provider.dart';
import 'pro_route_paths.dart';

final GlobalKey<NavigatorState> _proNavigatorKey = GlobalKey<NavigatorState>();

// Export for use in pro_auth_provider.dart
GlobalKey<NavigatorState> get proNavigatorKey => _proNavigatorKey;

/// Dashboard tab roots managed by ProDashboardScreen's internal index —
/// pushing them would stack a second dashboard on top of the current one.
const _proDashboardRoots = {
  ProRoutePaths.dashboard,
  ProRoutePaths.operations,
  ProRoutePaths.inbox,
  ProRoutePaths.insights,
  ProRoutePaths.account,
};

void openProAppRoute(String route) {
  final context = _proNavigatorKey.currentContext;
  if (context == null) return;
  if (_proDashboardRoots.contains(route)) {
    context.go(route);
    return;
  }
  context.push(route);
}

Widget _withProfile(
  BuildContext context,
  Widget Function(ProProfile profile) builder,
) {
  final profile = context.read<ProAuthProvider>().currentProfile;
  if (profile == null) {
    return const ProEntryScreen();
  }
  return builder(profile);
}

/// Maps a pro route path prefix to the ProModule it requires, or null for
/// paths available to every profile (dashboard, inbox, account, chat…).
ProModule? _moduleForPath(String path) {
  const table = <String, ProModule>{
    '/pro/shop/queue': ProModule.shopping,
    '/pro/shop/products': ProModule.shopping,
    '/pro/shop/store-setup': ProModule.shopping,
    '/pro/shop/restaurant-menu': ProModule.food,
    '/pro/provider/queue': ProModule.services,
    '/pro/provider/job': ProModule.services,
    '/pro/provider/availability': ProModule.services,
    '/pro/provider/schedule': ProModule.services,
    '/pro/doctor/setup': ProModule.doctor,
    '/pro/doctor/appointments': ProModule.doctor,
    '/pro/doctor/home-care': ProModule.doctor,
    '/pro/doctor/availability': ProModule.doctor,
    '/pro/doctor/schedule': ProModule.doctor,
    '/pro/delivery/queue': ProModule.shoppingDelivery,
    '/pro/delivery/active-delivery': ProModule.shoppingDelivery,
    '/pro/rider/queue': ProModule.ride,
    '/pro/rider/active-trip': ProModule.ride,
  };
  for (final entry in table.entries) {
    if (path == entry.key || path.startsWith('${entry.key}/')) {
      return entry.value;
    }
  }
  return null;
}

GoRouter createProAppRouter({
  required ProAuthProvider proAuthProvider,
  required CityAvailabilityProvider cityAvailabilityProvider,
  required bool hasSeenOnboarding,
}) {
  return GoRouter(
    navigatorKey: _proNavigatorKey,
    refreshListenable: Listenable.merge([
      proAuthProvider,
      cityAvailabilityProvider,
    ]),
    initialLocation: hasSeenOnboarding
        ? ProRoutePaths.entry
        : ProRoutePaths.onboarding,
    redirect: (context, state) {
      final path = state.uri.path;
      if (proAuthProvider.isBanned) {
        return path == '/banned' ? null : '/banned';
      }
      if (path == '/banned' && !proAuthProvider.isBanned) {
        return proAuthProvider.isAuthenticated
            ? ProRoutePaths.entry
            : ProRoutePaths.login;
      }
      // City rollout gate: pro operatives work inside active service zones
      // only. Blocks every route while the availability check is failing,
      // mirroring the user app's gate.
      if (cityAvailabilityProvider.isBlocking) {
        return path == '/city-unavailable' ? null : '/city-unavailable';
      }
      if (path == '/city-unavailable' && !cityAvailabilityProvider.isBlocking) {
        return proAuthProvider.isAuthenticated
            ? ProRoutePaths.entry
            : ProRoutePaths.login;
      }
      // Profile-module gate: block pro feature routes whose module isn't in
      // the profile's activeModules, so a disabled module's screens stay
      // unreachable even by deep link or stale push notification.
      final profile = proAuthProvider.currentProfile;
      if (profile != null) {
        final requiredModule = _moduleForPath(path);
        if (requiredModule != null &&
            !profile.activeModules.contains(requiredModule)) {
          return ProRoutePaths.homeForProfileType(profile.type);
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: ProRoutePaths.onboarding,
        builder: (context, state) => const ProOnboardingScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.entry,
        builder: (context, state) => const ProEntryScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.login,
        builder: (context, state) => const ProLoginScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.register,
        builder: (context, state) => const ProRegisterScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.signup,
        builder: (context, state) => const ProSignupScreen(),
      ),
      GoRoute(
        path: '/banned',
        builder: (context, state) => ProBannedScreen(
          banReason: state.extra as String? ?? proAuthProvider.banReason,
        ),
      ),
      GoRoute(
        path: '/city-unavailable',
        builder: (context, state) => const ProCityGateScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.dashboard,
        builder: (context, state) => const ProDashboardScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.operations,
        builder: (context, state) => const ProDashboardScreen(initialIndex: 1),
      ),
      GoRoute(
        path: ProRoutePaths.inbox,
        builder: (context, state) => const ProDashboardScreen(initialIndex: 2),
      ),
      GoRoute(
        path: ProRoutePaths.insights,
        builder: (context, state) => const ProDashboardScreen(initialIndex: 3),
      ),
      GoRoute(
        path: ProRoutePaths.account,
        builder: (context, state) => const ProDashboardScreen(initialIndex: 4),
      ),
      GoRoute(
        path: ProRoutePaths.superAdmin,
        builder: (context, state) => const ProSuperAdminScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.profileManagement,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProProfileManagementScreen(profile: profile),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.shopHome,
        builder: (context, state) => const ProDashboardScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.shopStoreSetup,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ShopStoreSetupScreen(
            userId: profile.userId,
            businessName: profile.businessName,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.shopQueue,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ShopOrdersQueueScreen(
            userId: profile.userId,
            businessName: profile.businessName,
            initialModule: state.uri.queryParameters['module'] ?? 'all',
            activeModules: profile.activeModules,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.shopCatalog,
        redirect: (_, state) => ProRoutePaths.shopProducts,
      ),
      GoRoute(
        path: ProRoutePaths.shopProducts,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ShopProductsScreen(
            userId: profile.userId,
            businessName: profile.businessName,
            activeModules: profile.activeModules,
            initialModule: state.uri.queryParameters['module'] ?? 'shopping',
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.restaurantMenu,
        builder: (context, state) => _withProfile(
          context,
          (profile) => RestaurantMenuScreen(userId: profile.userId),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.providerHome,
        builder: (context, state) => const ProDashboardScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.providerQueue,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProviderJobsQueueScreen(
            userId: profile.userId,
            businessName: profile.businessName,
            initialModule: state.uri.queryParameters['module'] ?? 'all',
            activeModules: profile.activeModules,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.providerJobDetail,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProviderJobDetailScreen(
            userId: profile.userId,
            businessName: profile.businessName,
            queueItem: {
              'id': state.pathParameters['id'] ?? '',
              'module': 'services',
            },
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.providerAvailability,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProviderAvailabilityScreen(
            userId: profile.userId,
            businessName: profile.businessName,
            activeModules: profile.activeModules,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.providerSchedule,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProviderScheduleSettingsScreen(
            userId: profile.userId,
            businessName: profile.businessName,
            activeModules: profile.activeModules,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.doctorSetup,
        builder: (context, state) => _withProfile(
          context,
          (profile) => DoctorSetupScreen(
            userId: profile.userId,
            businessName: profile.businessName,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.doctorHome,
        builder: (context, state) => const ProDashboardScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.doctorAppointments,
        builder: (context, state) => _withProfile(
          context,
          (profile) => DoctorAppointmentsQueueScreen(
            userId: profile.userId,
            businessName: profile.businessName,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.doctorHomeCare,
        builder: (context, state) => _withProfile(
          context,
          (profile) => DoctorHomeCareQueueScreen(
            userId: profile.userId,
            businessName: profile.businessName,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.doctorAvailability,
        builder: (context, state) => _withProfile(
          context,
          (profile) => DoctorAvailabilityScreen(
            userId: profile.userId,
            businessName: profile.businessName,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.doctorSchedule,
        builder: (context, state) => _withProfile(
          context,
          (profile) => DoctorScheduleSettingsScreen(
            userId: profile.userId,
            businessName: profile.businessName,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.deliveryHome,
        builder: (context, state) => const ProDashboardScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.deliveryQueue,
        builder: (context, state) => _withProfile(
          context,
          (profile) => DeliveryQueueScreen(
            userId: profile.userId,
            businessName: profile.businessName,
          ),
        ),
      ),
      GoRoute(
        path: '/pro/delivery/active-delivery/:id',
        builder: (context, state) => _withProfile(
          context,
          (profile) => RiderActiveDeliveryScreen(
            orderId: state.pathParameters['id']!,
            userId: profile.userId,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.riderHome,
        builder: (context, state) => const ProDashboardScreen(),
      ),
      GoRoute(
        path: ProRoutePaths.riderQueue,
        builder: (context, state) => _withProfile(
          context,
          (profile) => RiderQueueScreen(
            userId: profile.userId,
            businessName: profile.businessName,
          ),
        ),
      ),
      GoRoute(
        path: '/pro/rider/active-trip/:id',
        builder: (context, state) => _withProfile(
          context,
          (profile) => RiderActiveTripScreen(
            rideId: state.pathParameters['id']!,
            userId: profile.userId,
          ),
        ),
      ),
      GoRoute(
        path: '/pro/messages/chat/:id',
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['id']!,
          isProView: true,
        ),
      ),
    ],
  );
}
