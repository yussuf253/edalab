import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/messages/screens/chat_screen.dart';
import '../../features/account/screens/pro_account_screen.dart';
import '../../features/auth/screens/pro_login_screen.dart';
import '../../features/auth/screens/pro_register_screen.dart';
import '../../features/auth/screens/pro_signup_screen.dart';
import '../../features/delivery/screens/delivery_dashboard_screen.dart';
import '../../features/delivery/screens/delivery_queue_screen.dart';
import '../../features/doctor/screens/doctor_appointments_queue_screen.dart';
import '../../features/doctor/screens/doctor_availability_screen.dart';
import '../../features/doctor/screens/doctor_dashboard_screen.dart';
import '../../features/doctor/screens/doctor_schedule_settings_screen.dart';
import '../../features/entry/screens/pro_entry_screen.dart';
import '../../features/insights/screens/pro_insights_screen.dart';
import '../../features/messages/screens/pro_messages_screen.dart';
import '../../features/onboarding/screens/pro_onboarding_screen.dart';
import '../../features/operations/screens/pro_operations_screen.dart';
import '../../features/provider/screens/provider_availability_screen.dart';
import '../../features/provider/screens/provider_dashboard_screen.dart';
import '../../features/provider/screens/provider_jobs_queue_screen.dart';
import '../../features/provider/screens/provider_schedule_settings_screen.dart';
import '../../features/rider/screens/rider_active_delivery_screen.dart';
import '../../features/rider/screens/rider_active_trip_screen.dart';
import '../../features/rider/screens/rider_dashboard_screen.dart';
import '../../features/rider/screens/rider_queue_screen.dart';
import '../../features/shop/screens/shop_catalog_screen.dart';
import '../../features/shop/screens/shop_dashboard_screen.dart';
import '../../features/shop/screens/shop_orders_queue_screen.dart';
import '../models/pro_profile.dart';
import '../providers/pro_auth_provider.dart';
import 'pro_route_paths.dart';

final GlobalKey<NavigatorState> _proNavigatorKey = GlobalKey<NavigatorState>();

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

Widget _currentHome(BuildContext context) {
  return _withProfile(context, (profile) {
    switch (profile.type) {
      case ProProfileType.shop:
        return ShopDashboardScreen(profile: profile);
      case ProProfileType.provider:
        return ProviderDashboardScreen(profile: profile);
      case ProProfileType.doctor:
        return DoctorDashboardScreen(profile: profile);
      case ProProfileType.delivery:
        return DeliveryDashboardScreen(profile: profile);
      case ProProfileType.rider:
        return RiderDashboardScreen(profile: profile);
    }
  });
}

GoRouter createProAppRouter({required bool hasSeenOnboarding}) {
  return GoRouter(
    navigatorKey: _proNavigatorKey,
    initialLocation: hasSeenOnboarding
        ? ProRoutePaths.entry
        : ProRoutePaths.onboarding,
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
        path: ProRoutePaths.dashboard,
        builder: (context, state) => _currentHome(context),
      ),
      GoRoute(
        path: ProRoutePaths.operations,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProOperationsScreen(profile: profile),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.inbox,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProMessagesScreen(profile: profile),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.insights,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProInsightsScreen(profile: profile),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.account,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProAccountScreen(profile: profile),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.shopHome,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ShopDashboardScreen(profile: profile),
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
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.shopCatalog,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ShopCatalogScreen(
            userId: profile.userId,
            businessName: profile.businessName,
            modules: profile.activeModules,
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.providerHome,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProviderDashboardScreen(profile: profile),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.providerQueue,
        builder: (context, state) => _withProfile(
          context,
          (profile) => ProviderJobsQueueScreen(
            userId: profile.userId,
            businessName: profile.businessName,
            initialModule: state.uri.queryParameters['module'] ?? 'all',
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
          ),
        ),
      ),
      GoRoute(
        path: ProRoutePaths.doctorHome,
        builder: (context, state) => _withProfile(
          context,
          (profile) => DoctorDashboardScreen(profile: profile),
        ),
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
        builder: (context, state) => _withProfile(
          context,
          (profile) => DeliveryDashboardScreen(profile: profile),
        ),
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
        builder: (context, state) => _withProfile(
          context,
          (profile) => RiderDashboardScreen(profile: profile),
        ),
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
