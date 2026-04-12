import 'package:flutter/material.dart';

class HomeServiceCategoryModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String iconKey;
  final String colorHex;
  final int providerCount;

  const HomeServiceCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.iconKey,
    required this.colorHex,
    required this.providerCount,
  });

  factory HomeServiceCategoryModel.fromApi(Map<String, dynamic> json) {
    return HomeServiceCategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Service',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      iconKey: json['iconKey']?.toString() ?? 'home',
      colorHex: json['colorHex']?.toString() ?? '#0F9D92',
      providerCount: (json['providerCount'] as num?)?.toInt() ?? 0,
    );
  }

  IconData get icon {
    switch (iconKey) {
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'beauty':
        return Icons.content_cut_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      case 'house_help':
      case 'house-help':
      case 'househelp':
      case 'maid':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.home_repair_service_rounded;
    }
  }

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final value = int.tryParse(normalized, radix: 16) ?? 0xFF0F9D92;
    return Color(value);
  }
}

class HomeServiceProviderModel {
  final String id;
  final String categoryId;
  final String? categoryName;
  final String? categorySlug;
  final String? categoryIconKey;
  final String? categoryColorHex;
  final String name;
  final String title;
  final double rating;
  final int reviewCount;
  final String? yearsExperience;
  final double startingPrice;
  final bool isAvailable;
  final bool isVerified;
  final String? responseTime;
  final String? imageUrl;
  final String? about;
  final String? location;
  final String? contactPhone;
  final List<String> services;
  final List<String> highlights;
  final List<String> bookingModes;
  final Map<String, dynamic> availability;
  final Map<String, dynamic> serviceZone;
  final double? distanceKm;
  final bool? withinProviderZone;
  final bool? withinRequestedRadius;

  const HomeServiceProviderModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.title,
    required this.rating,
    required this.reviewCount,
    required this.startingPrice,
    required this.isAvailable,
    required this.isVerified,
    this.categoryName,
    this.categorySlug,
    this.categoryIconKey,
    this.categoryColorHex,
    this.yearsExperience,
    this.responseTime,
    this.imageUrl,
    this.about,
    this.location,
    this.contactPhone,
    this.services = const [],
    this.highlights = const [],
    this.bookingModes = const [],
    this.availability = const {},
    this.serviceZone = const {},
    this.distanceKm,
    this.withinProviderZone,
    this.withinRequestedRadius,
  });

  factory HomeServiceProviderModel.fromApi(Map<String, dynamic> json) {
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'] as Map)
        : null;
    return HomeServiceProviderModel(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: category?['name']?.toString(),
      categorySlug: category?['slug']?.toString(),
      categoryIconKey: category?['iconKey']?.toString(),
      categoryColorHex: category?['colorHex']?.toString(),
      name: json['name']?.toString() ?? 'Professional',
      title: json['title']?.toString() ?? 'Home Service Provider',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      yearsExperience: json['yearsExperience']?.toString(),
      startingPrice: (json['startingPrice'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      responseTime: json['responseTime']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      about: json['about']?.toString(),
      location: json['location']?.toString(),
      contactPhone: json['contactPhone']?.toString(),
      services:
          (json['services'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      highlights:
          (json['highlights'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      bookingModes:
          (json['bookingModes'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      availability: Map<String, dynamic>.from(
        (json['availability'] as Map?) ?? const <String, dynamic>{},
      ),
      serviceZone: Map<String, dynamic>.from(
        (json['serviceZone'] as Map?) ?? const <String, dynamic>{},
      ),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      withinProviderZone: json['withinProviderZone'] as bool?,
      withinRequestedRadius: json['withinRequestedRadius'] as bool?,
    );
  }

  String get primaryMode =>
      bookingModes.isNotEmpty ? bookingModes.first : 'Home Visit';

  IconData get categoryIcon {
    switch (categoryIconKey) {
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
        return Icons.electrical_services_rounded;
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'beauty':
        return Icons.content_cut_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      case 'house_help':
      case 'house-help':
      case 'househelp':
      case 'maid':
        return Icons.cleaning_services_rounded;
      default:
        return Icons.home_repair_service_rounded;
    }
  }

  Color get categoryColor {
    final hex = (categoryColorHex ?? '#0F9D92').replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'FF$hex' : hex;
    final value = int.tryParse(normalized, radix: 16) ?? 0xFF0F9D92;
    return Color(value);
  }
}
