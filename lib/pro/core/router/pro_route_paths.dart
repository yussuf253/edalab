import '../models/pro_profile.dart';

class ProRoutePaths {
  ProRoutePaths._();

  static const onboarding = '/onboarding';
  static const entry = '/';
  static const login = '/login';
  static const register = '/register';
  static const signup = '/pro/signup';

  static const dashboard = '/pro/dashboard';
  static const operations = '/pro/operations';
  static const inbox = '/pro/inbox';
  static const insights = '/pro/insights';
  static const account = '/pro/account';

  static const shopHome = '/pro/shop';
  static const shopQueue = '/pro/shop/queue';
  static const shopCatalog = '/pro/shop/catalog';
  static const shopProducts = '/pro/shop/products';

  static const providerHome = '/pro/provider';
  static const providerQueue = '/pro/provider/queue';
  static const providerAvailability = '/pro/provider/availability';
  static const providerSchedule = '/pro/provider/schedule';

  static const doctorHome = '/pro/doctor';
  static const doctorAppointments = '/pro/doctor/appointments';
  static const doctorAvailability = '/pro/doctor/availability';
  static const doctorSchedule = '/pro/doctor/schedule';

  static const deliveryHome = '/pro/delivery';
  static const deliveryQueue = '/pro/delivery/queue';
  static String deliveryActive(String orderId) =>
      '/pro/delivery/active-delivery/$orderId';

  static const riderHome = '/pro/rider';
  static const riderQueue = '/pro/rider/queue';
  static String riderActiveTrip(String rideId) =>
      '/pro/rider/active-trip/$rideId';

  static String homeForProfileType(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return shopHome;
      case ProProfileType.provider:
        return providerHome;
      case ProProfileType.doctor:
        return doctorHome;
      case ProProfileType.delivery:
        return deliveryHome;
      case ProProfileType.rider:
        return riderHome;
    }
  }

  static String queueForModule(ProModule module) {
    switch (module) {
      case ProModule.shopping:
        return '$shopQueue?module=shopping';
      case ProModule.food:
        return '$shopQueue?module=food';
      case ProModule.pharmacy:
        return '$shopQueue?module=pharmacy';
      case ProModule.services:
        return '$providerQueue?module=services';
      case ProModule.laundry:
        return '$providerQueue?module=laundry';
      case ProModule.doctor:
        return doctorAppointments;
      case ProModule.shoppingDelivery:
      case ProModule.foodDelivery:
      case ProModule.pharmacyDelivery:
        return deliveryQueue;
      case ProModule.ride:
        return riderQueue;
    }
  }
}
