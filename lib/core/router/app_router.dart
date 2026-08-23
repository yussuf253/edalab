import 'package:edalab/features/onboarding/screens/home_onboarding_screen.dart';
import 'package:edalab/features/onboarding/screens/onboarding_screen.dart';

import '../../core/config/app_config.dart';
import 'package:edalab/features/doctor/screens/lab_tests_screen.dart';
import 'package:edalab/features/doctor/screens/physiotherapy_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../localization/app_localizations.dart';
import '../modules/module_access_service.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/city_availability_provider.dart';
import '../../features/city_gate/screens/city_not_available_screen.dart';
import '../widgets/example_version_check.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/banned_user_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/messages/screens/messages_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/promotions/screens/promotions_screen.dart';
import '../../features/cart/screens/cart_hub_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/shopping/screens/shopping_screen.dart';
import '../../features/shopping/screens/product_detail_screen.dart';
import '../../features/shopping/screens/shopping_order_detail_screen.dart';
import '../../features/shopping/screens/shopping_store_detail_screen.dart';
import '../../features/shopping/screens/cart_screen.dart';
import '../../features/shopping/screens/wishlist_screen.dart';
import '../../features/shopping/screens/shopping_category_screen.dart';
import '../../features/food/screens/food_screen.dart';
import '../../features/food/screens/restaurant_detail_screen.dart';
import '../../features/food/screens/food_dish_detail_screen.dart';
import '../../features/food/screens/food_cart_screen.dart';
import '../../features/food/screens/food_order_tracking_screen.dart';
import '../../features/doctor/screens/doctor_screen.dart';
import '../../features/doctor/screens/doctor_home_care_screen.dart';
import '../../features/doctor/screens/doctor_professionals_screen.dart';
import '../../features/doctor/screens/doctor_detail_screen.dart';
import '../../features/doctor/screens/doctor_appointment_detail_screen.dart';
import '../../features/doctor/screens/book_appointment_screen.dart';
import '../../features/doctor/screens/my_appointments_screen.dart';
import '../../features/hotel/screens/hotel_screen.dart';
import '../../features/hotel/screens/hotel_detail_screen.dart';
import '../../features/hotel/screens/hotel_booking_screen.dart';
import '../../features/hotel/screens/hotel_order_detail_screen.dart';
import '../../features/ride/screens/ride_screen.dart';
import '../../features/ride/screens/ride_booking_screen.dart';
import '../../features/ride/screens/ride_booking_summary_screen.dart';
import '../../features/ride/screens/ride_tracking_screen.dart';
import '../../features/car_rental/screens/car_rental_screen.dart';
import '../../features/car_rental/screens/car_rental_detail_screen.dart';
import '../../features/car_rental/services/car_rental_service.dart';
import '../../features/pharmacy/screens/pharmacy_screen.dart';
import '../../features/pharmacy/screens/medicine_detail_screen.dart';
import '../../features/pharmacy/screens/pharmacy_order_detail_screen.dart';
import '../../features/pharmacy/screens/pharmacy_cart_screen.dart';
import '../../features/pharmacy/screens/pharmacy_store_detail_screen.dart';
import '../../features/grocery/screens/grocery_screen.dart';
import '../../features/grocery/screens/grocery_category_screen.dart';
import '../../features/grocery/screens/grocery_cart_screen.dart';
import '../../features/grocery/screens/grocery_detail_screen.dart';
import '../../features/home_services/screens/home_services_screen.dart';
import '../../features/home_services/screens/home_service_category_screen.dart';
import '../../features/home_services/screens/home_service_provider_screen.dart';
import '../../features/home_services/screens/home_service_booking_screen.dart';
import '../../features/home_services/screens/home_service_appointment_detail_screen.dart';
import '../../features/laundry/screens/laundry_screen.dart';
import '../../features/laundry/screens/laundry_order_screen.dart';
import '../../features/laundry/screens/laundry_tracking_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/order_success_screen.dart';
import '../../features/checkout/screens/payment_success_screen.dart';
import '../../features/checkout/screens/payment_failure_screen.dart';
import '../../features/checkout/screens/payment_webview_screen.dart';
import '../../features/rewards/screens/coupons_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/addresses_screen.dart';
import '../../features/profile/screens/payment_methods_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/help_center_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/search/screens/search_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

void openAppRoute(String route) {
  final context = _rootNavigatorKey.currentContext;
  if (context == null) return;
  context.push(route);
}

GoRouter createAppRouter({
  required AuthProvider authProvider,
  required CityAvailabilityProvider cityAvailabilityProvider,
  required bool hasSeenOnboarding,
  required bool hasSeenHomeOnboarding,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: Listenable.merge([authProvider, cityAvailabilityProvider]),
    // Onboarding général → /onboarding
    // Home onboarding → géré via redirect sur /home-services
    initialLocation: hasSeenOnboarding ? '/' : '/home-onboarding',
    redirect: (context, state) {
      final path = state.uri.path;
      if (authProvider.isBanned) {
        return path == '/banned' ? null : '/banned';
      }
      if (path == '/banned' && !authProvider.isBanned) {
        return authProvider.isLoggedIn ? '/' : '/login';
      }
      // City rollout gate: block everything outside an active service zone.
      if (cityAvailabilityProvider.isBlocking) {
        return path == '/city-unavailable' ? null : '/city-unavailable';
      }
      if (path == '/city-unavailable' && !cityAvailabilityProvider.isBlocking) {
        return authProvider.isLoggedIn ? '/' : '/login';
      }
      // Home onboarding : s'affiche une seule fois au premier accès à /home-services
      if (!hasSeenHomeOnboarding && path == '/home-services') {
        return '/home-onboarding';
      }
      final moduleId = ModuleAccessService.instance.moduleForPath(path);
      if (moduleId == null) return null;
      if (ModuleAccessService.instance.isEnabled(moduleId)) return null;
      return '/';
    },
    routes: [
      // ── Onboarding général ──────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Home Services Onboarding ────────────────────────────────────────
      GoRoute(
        path: '/home-onboarding',
        builder: (context, state) => const HomeOnboardingScreen(),
      ),

      // ── Auth ────────────────────────────────────────────────────────────
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Banned ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/banned',
        builder: (context, state) => BannedUserScreen(
          banReason: state.extra as String? ?? authProvider.banReason,
        ),
      ),

      // ── City rollout gate ──────────────────────────────────────────────
      GoRoute(
        path: '/city-unavailable',
        builder: (context, state) => const CityNotAvailableScreen(),
      ),

      // ── Main App Shell ───────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartHubScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const OrdersScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: '/promotions',
        builder: (context, state) => const PromotionsScreen(),
      ),
      GoRoute(
        path: '/messages/chat/:id',
        builder: (context, state) =>
            ChatScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pro/messages/chat/:id',
        builder: (context, state) => ChatScreen(
          conversationId: state.pathParameters['id']!,
          isProView: true,
        ),
      ),

      // ── Search ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      // ── Shopping ────────────────────────────────────────────────────────
      GoRoute(
        path: '/shopping',
        builder: (context, state) => const ShoppingScreen(),
      ),
      GoRoute(
        path: '/shopping/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shopping/store/:id',
        builder: (context, state) =>
            ShoppingStoreDetailScreen(storeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shopping/category/:id',
        builder: (context, state) =>
            ShoppingCategoryScreen(categoryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/shopping/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/shopping/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/shopping/order/:id',
        builder: (context, state) => ShoppingOrderDetailScreen(
          orderId: state.pathParameters['id']!,
          order: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null,
        ),
      ),
      GoRoute(
        path: '/version-demo',
        builder: (context, state) => const ExampleVersionCheckWidget(),
      ),

      // ── Food ────────────────────────────────────────────────────────────
      GoRoute(path: '/food', builder: (context, state) => const FoodScreen()),
      GoRoute(
        path: '/food/restaurant/:id',
        builder: (context, state) =>
            RestaurantDetailScreen(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/food/dish/:id',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          final item = extra['item'];
          return FoodDishDetailScreen(
            itemId: state.pathParameters['id']!,
            item: item is MenuItem ? item : null,
            restaurantName: extra['restaurantName'] as String?,
            categoryName: extra['categoryName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/food/dishes/:id',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          final item = extra['item'];
          return FoodDishDetailScreen(
            itemId: state.pathParameters['id']!,
            item: item is MenuItem ? item : null,
            restaurantName: extra['restaurantName'] as String?,
            categoryName: extra['categoryName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/food/cart',
        builder: (context, state) => const FoodCartScreen(),
      ),
      GoRoute(
        path: '/food/tracking/:id',
        builder: (context, state) =>
            FoodOrderTrackingScreen(orderId: state.pathParameters['id']!),
      ),

      // ── Doctor ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/doctor',
        builder: (context, state) => const DoctorScreen(),
      ),
      GoRoute(
        path: '/doctor/detail/:id',
        builder: (context, state) =>
            DoctorDetailScreen(doctorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/doctor/professionals/:categoryId',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return DoctorProfessionalsScreen(
            categoryId: state.pathParameters['categoryId']!,
            categoryLabel:
                extra['label']?.toString() ??
                AppLocalizations.of(
                  context,
                ).t('home_category.available_professionals'),
            keywords:
                (extra['keywords'] as List?)
                    ?.map((item) => item.toString())
                    .toList() ??
                const [],
            initialQuery: extra['searchQuery']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: '/doctor/home-care',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return DoctorHomeCareScreen(
            initialQuery: extra['searchQuery']?.toString() ?? '',
          );
        },
      ),
      GoRoute(
        path: '/doctor/book/:id',
        builder: (context, state) =>
            BookAppointmentScreen(doctorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/doctor/appointments',
        builder: (context, state) => const MyAppointmentsScreen(),
      ),
      GoRoute(
        path: '/doctor/appointments/:id',
        builder: (context, state) => DoctorAppointmentDetailScreen(
          appointmentId: state.pathParameters['id']!,
          initialAppointment: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null,
        ),
      ),
      GoRoute(
        path: '/doctor/lab-tests',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return LabTestsScreen(
            categoryId: extra['categoryId']?.toString(),
            categoryLabel: extra['label']?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/doctor/physiotherapy',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{};
          return PhysiotherapyScreen(
            categoryId: extra['categoryId']?.toString(),
            categoryLabel: extra['label']?.toString(),
          );
        },
      ),

      // ── Hotel ────────────────────────────────────────────────────────────
      GoRoute(path: '/hotel', builder: (context, state) => const HotelScreen()),
      GoRoute(
        path: '/hotel/detail/:id',
        builder: (context, state) =>
            HotelDetailScreen(hotelId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/hotel/book/:id',
        builder: (context, state) =>
            HotelBookingScreen(hotelId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/hotel/order/:id',
        builder: (context, state) => HotelOrderDetailScreen(
          bookingId: state.pathParameters['id']!,
          booking: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null,
        ),
      ),

      // ── Ride ─────────────────────────────────────────────────────────────
      GoRoute(path: '/ride', builder: (context, state) => const RideScreen()),
      GoRoute(
        path: '/ride/book',
        builder: (context, state) => RideBookingScreen(
          bookingData: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/ride/summary',
        builder: (context, state) => RideBookingSummaryScreen(
          bookingData: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : <String, dynamic>{},
        ),
      ),
      GoRoute(
        path: '/ride/tracking/:id',
        builder: (context, state) => RideTrackingScreen(
          rideId: state.pathParameters['id']!,
          rideData: state.extra as Map<String, dynamic>?,
        ),
      ),

      // ── Car Rental ───────────────────────────────────────────────────────
      GoRoute(
        path: '/car-rental',
        builder: (context, state) => const CarRentalScreen(),
      ),
      GoRoute(
        path: '/car-rental/:carId',
        builder: (context, state) {
          final extra = state.extra;
          CarRentalCar? carData;
          Map<String, dynamic>? carMap;
          if (extra is CarRentalCar) {
            carData = extra;
          } else if (extra is Map<String, dynamic>) {
            carMap = extra;
          }
          return CarRentalDetailScreen(
            carId: state.pathParameters['carId']!,
            carData: carData,
            carMap: carMap,
          );
        },
      ),

      // ── Pharmacy ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/pharmacy',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : const <String, dynamic>{};
          return PharmacyScreen(
            initialSelectedPharmacyName: extra['selectedPharmacyName']
                ?.toString(),
          );
        },
      ),
      GoRoute(
        path: '/pharmacy/store/:id',
        builder: (context, state) => PharmacyStoreDetailScreen(
          storeId: state.pathParameters['id']!,
          initialStore: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null,
        ),
      ),
      GoRoute(
        path: '/pharmacy/medicine/:id',
        builder: (context, state) =>
            MedicineDetailScreen(medicineId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/pharmacy/cart',
        builder: (context, state) => const PharmacyCartScreen(),
      ),
      GoRoute(
        path: '/pharmacy/order/:id',
        builder: (context, state) => PharmacyOrderDetailScreen(
          orderId: state.pathParameters['id']!,
          order: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null,
        ),
      ),

      // ── Grocery ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/grocery',
        builder: (context, state) => const GroceryScreen(),
      ),
      GoRoute(
        path: '/grocery/category/:id',
        builder: (context, state) =>
            GroceryCategoryScreen(categoryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/grocery/product/:id',
        builder: (context, state) =>
            GroceryDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/grocery/cart',
        builder: (context, state) => const GroceryCartScreen(),
      ),

      // ── Home Services ────────────────────────────────────────────────────
      GoRoute(
        path: '/home-services',
        builder: (context, state) => const HomeServicesScreen(),
      ),
      GoRoute(
        path: '/home-services/category/:slug',
        builder: (context, state) => HomeServiceCategoryScreen(
          categorySlug: state.pathParameters['slug']!,
          categoryLabel: state.extra is Map
              ? (state.extra as Map)['label']?.toString()
              : null,
        ),
      ),
      GoRoute(
        path: '/home-services/provider/:id',
        builder: (context, state) =>
            HomeServiceProviderScreen(providerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/home-services/book/:id',
        builder: (context, state) =>
            HomeServiceBookingScreen(providerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/home-services/booking/:id',
        builder: (context, state) => HomeServiceAppointmentDetailScreen(
          orderId: state.pathParameters['id']!,
          initialOrder: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null,
        ),
      ),

      // ── Laundry ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/laundry',
        builder: (context, state) => const LaundryScreen(),
      ),
      GoRoute(
        path: '/laundry/order',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          final lockedRaw = query['locked']?.toLowerCase();
          final lockServiceSelection = lockedRaw == '1' || lockedRaw == 'true';
          return LaundryOrderScreen(
            initialServiceId: query['serviceId'],
            lockServiceSelection: lockServiceSelection,
          );
        },
      ),
      GoRoute(
        path: '/laundry/tracking/:id',
        builder: (context, state) =>
            LaundryTrackingScreen(orderId: state.pathParameters['id']!),
      ),

      // ── Checkout ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/checkout',
        builder: (context, state) => CheckoutScreen(
          checkoutData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: '/checkout/success',
        builder: (context, state) => OrderSuccessScreen(
          orderData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: '/payment/success',
        builder: (context, state) => PaymentSuccessScreen(
          paymentData: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: '/payment/failed',
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? Map<String, dynamic>.from(state.extra as Map<String, dynamic>)
              : <String, dynamic>{};
          return PaymentFailureScreen(
            paymentData: {...state.uri.queryParameters, ...extra},
          );
        },
      ),
      GoRoute(
        path: '/payment/webview',
        builder: (context, state) {
          final extra = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : <String, dynamic>{};
          return PaymentWebViewScreen(
            paymentUrl: extra['paymentUrl'] as String? ?? '',
            successUrl: AppConfig.getPaymentSuccessUrl(
              extra['orderId'] as String? ?? '',
            ),
            failureUrl: AppConfig.getPaymentFailureUrl('Payment failed'),
            amount: (extra['amount'] as num?)?.toDouble() ?? 0.0,
            moduleName: extra['moduleName'] as String? ?? 'Order',
          );
        },
      ),

      // ── Rewards ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/rewards',
        builder: (context, state) => const CouponsScreen(),
      ),

      // ── Profile ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/profile/payment-methods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const HelpCenterScreen(),
      ),

      // ── Notifications ────────────────────────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}
