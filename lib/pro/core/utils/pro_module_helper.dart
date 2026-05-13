import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/pro_profile.dart';

class ProModuleHelper {
  static List<ProModule> getModulesForProfile(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return [ProModule.shopping, ProModule.food, ProModule.pharmacy];
      case ProProfileType.provider:
        return [ProModule.services, ProModule.laundry];
      case ProProfileType.doctor:
        return [ProModule.doctor];
      case ProProfileType.delivery:
        return [
          ProModule.shoppingDelivery,
          ProModule.foodDelivery,
          ProModule.pharmacyDelivery,
        ];
      case ProProfileType.rider:
        return [ProModule.ride];
    }
  }

  static List<ProModule> getDefaultModulesForProfile(ProProfileType type) {
    return getModulesForProfile(type);
  }

  static List<ProModule> sanitizeModules(
    ProProfileType type,
    Iterable<ProModule> selectedModules,
  ) {
    final allowed = getModulesForProfile(type).toSet();
    final normalized = selectedModules.where(allowed.contains).toSet().toList();

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return getDefaultModulesForProfile(type);
  }

  static String getModuleName(ProModule module) {
    switch (module) {
      case ProModule.shopping:
        return 'Shopping';
      case ProModule.food:
        return 'Food';
      case ProModule.pharmacy:
        return 'Pharmacy';
      case ProModule.services:
        return 'Services';
      case ProModule.laundry:
        return 'Laundry';
      case ProModule.doctor:
        return 'Doctor';
      case ProModule.shoppingDelivery:
        return 'Shopping Delivery';
      case ProModule.foodDelivery:
        return 'Food Delivery';
      case ProModule.pharmacyDelivery:
        return 'Pharmacy Delivery';
      case ProModule.ride:
        return 'Ride';
    }
  }

  static String getModuleDescription(ProModule module) {
    switch (module) {
      case ProModule.shopping:
        return 'Catalog, stock, order fulfillment, and retail operations.';
      case ProModule.food:
        return 'Menus, prep queue, food orders, and kitchen operations.';
      case ProModule.pharmacy:
        return 'Medicines, prescription flow, and pharmacy order handling.';
      case ProModule.services:
        return 'Bookings, staff allocation, and in-home service operations.';
      case ProModule.laundry:
        return 'Pickup scheduling, cleaning workflow, and delivery status.';
      case ProModule.doctor:
        return 'Appointments, consultations, and patient-facing doctor tools.';
      case ProModule.shoppingDelivery:
        return 'Deliver shopping orders from store pickup to customer dropoff.';
      case ProModule.foodDelivery:
        return 'Handle restaurant pickups and food delivery dispatches.';
      case ProModule.pharmacyDelivery:
        return 'Complete pharmacy deliveries with medicine-sensitive handling.';
      case ProModule.ride:
        return 'Accept ride requests, manage trips, and track rider earnings.';
    }
  }

  static Color getModuleColor(ProModule module) {
    switch (module) {
      case ProModule.shopping:
      case ProModule.shoppingDelivery:
        return AppColors.shopping;
      case ProModule.food:
      case ProModule.foodDelivery:
        return AppColors.food;
      case ProModule.pharmacy:
      case ProModule.pharmacyDelivery:
        return AppColors.pharmacy;
      case ProModule.services:
        return AppColors.homeServices;
      case ProModule.laundry:
        return AppColors.laundry;
      case ProModule.doctor:
        return AppColors.doctor;
      case ProModule.ride:
        return AppColors.ride;
    }
  }

  static IconData getModuleIcon(ProModule module) {
    switch (module) {
      case ProModule.shopping:
        return Icons.storefront;
      case ProModule.food:
        return Icons.restaurant_menu;
      case ProModule.pharmacy:
        return Icons.local_pharmacy;
      case ProModule.services:
        return Icons.home_repair_service;
      case ProModule.laundry:
        return Icons.local_laundry_service;
      case ProModule.doctor:
        return Icons.medical_services;
      case ProModule.shoppingDelivery:
        return Icons.inventory_2_outlined;
      case ProModule.foodDelivery:
        return Icons.delivery_dining;
      case ProModule.pharmacyDelivery:
        return Icons.medication_outlined;
      case ProModule.ride:
        return Icons.local_taxi;
    }
  }

  static String getProfileName(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return 'Store Profile';
      case ProProfileType.provider:
        return 'Provider Profile';
      case ProProfileType.doctor:
        return 'Doctor Profile';
      case ProProfileType.delivery:
        return 'Delivery Profile';
      case ProProfileType.rider:
        return 'Rider Profile';
    }
  }

  static String getProfileDescription(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return 'Manage shopping, food, and pharmacy businesses from one store profile.';
      case ProProfileType.provider:
        return 'Operate service and laundry businesses with one provider account.';
      case ProProfileType.doctor:
        return 'Run doctor appointments and patient consultations.';
      case ProProfileType.delivery:
        return 'Receive and complete delivery orders from shopping, food, and pharmacy.';
      case ProProfileType.rider:
        return 'Accept ride requests and manage the transport side of the platform.';
    }
  }

  static IconData getProfileIcon(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return Icons.store;
      case ProProfileType.provider:
        return Icons.cleaning_services;
      case ProProfileType.doctor:
        return Icons.local_hospital;
      case ProProfileType.delivery:
        return Icons.local_shipping;
      case ProProfileType.rider:
        return Icons.two_wheeler;
    }
  }

  static Color getProfileColor(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return AppColors.shopping;
      case ProProfileType.provider:
        return AppColors.homeServices;
      case ProProfileType.doctor:
        return AppColors.doctor;
      case ProProfileType.delivery:
        return AppColors.food;
      case ProProfileType.rider:
        return AppColors.ride;
    }
  }
}
