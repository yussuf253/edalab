import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../models/pro_profile.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
          ProModule.parcelDelivery,
        ];
      case ProProfileType.rider:
        return [ProModule.ride];
    }
  }

  static List<ProModule> getDefaultModulesForProfile(ProProfileType type) {
    // Only the primary (first) module is a sensible fallback — never grant
    // every module for the profile type by default.
    final modules = getModulesForProfile(type);
    return modules.isEmpty ? const [] : [modules.first];
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
      case ProModule.parcelDelivery:
        return 'Parcel Delivery';
      case ProModule.ride:
        return 'Ride';
      case ProModule.ecologicalCleaning:
        return 'Ecological Cleaning';
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
      case ProModule.parcelDelivery:
        return 'Accept parcel requests and manage pickup through proof of delivery.';
      case ProModule.ride:
        return 'Accept ride requests, manage trips, and track rider earnings.';
      case ProModule.ecologicalCleaning:
        return 'Eco-friendly cleaning services and sustainability operations.';
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
      case ProModule.parcelDelivery:
        return AppColors.shopping;
      case ProModule.services:
        return AppColors.homeServices;
      case ProModule.laundry:
        return AppColors.laundry;
      case ProModule.doctor:
        return AppColors.doctor;
      case ProModule.ride:
        return AppColors.ride;
      case ProModule.ecologicalCleaning:
        return AppColors.homeServices;
    }
  }

  static IconData getModuleIcon(ProModule module) {
    switch (module) {
      case ProModule.shopping:
        return LucideIcons.store;
      case ProModule.food:
        return LucideIcons.utensilsCrossed;
      case ProModule.pharmacy:
        return LucideIcons.pill;
      case ProModule.services:
        return LucideIcons.hammer;
      case ProModule.laundry:
        return LucideIcons.washingMachine;
      case ProModule.doctor:
        return LucideIcons.briefcaseMedical;
      case ProModule.shoppingDelivery:
        return LucideIcons.package;
      case ProModule.foodDelivery:
        return LucideIcons.scooter;
      case ProModule.pharmacyDelivery:
        return LucideIcons.pill;
      case ProModule.parcelDelivery:
        return LucideIcons.package;
      case ProModule.ride:
        return LucideIcons.carTaxiFront;
      case ProModule.ecologicalCleaning:
        return LucideIcons.broom;
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
        return LucideIcons.store;
      case ProProfileType.provider:
        return LucideIcons.broom;
      case ProProfileType.doctor:
        return LucideIcons.cross;
      case ProProfileType.delivery:
        return LucideIcons.truck;
      case ProProfileType.rider:
        return LucideIcons.carTaxiFront;
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
