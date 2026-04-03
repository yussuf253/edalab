import 'dart:convert';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum NotificationModule {
  system,
  messages,
  orders,
  food,
  shopping,
  grocery,
  pharmacy,
  ride,
  hotel,
  doctor,
  homeServices,
  laundry,
  promotions,
  account,
}

enum NotificationPriority { low, normal, high, urgent }

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.module,
    required this.createdAt,
    this.priority = NotificationPriority.normal,
    this.readAt,
    this.route,
    this.metadata = const {},
    this.dedupeKey,
  });

  final String id;
  final String title;
  final String body;
  final NotificationModule module;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? route;
  final Map<String, dynamic> metadata;
  final String? dedupeKey;

  bool get isRead => readAt != null;

  AppNotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationModule? module,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? readAt,
    bool clearReadAt = false,
    String? route,
    bool clearRoute = false,
    Map<String, dynamic>? metadata,
    String? dedupeKey,
    bool clearDedupeKey = false,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      module: module ?? this.module,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      route: clearRoute ? null : (route ?? this.route),
      metadata: metadata ?? this.metadata,
      dedupeKey: clearDedupeKey ? null : (dedupeKey ?? this.dedupeKey),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'module': module.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'route': route,
      'metadata': metadata,
      'dedupeKey': dedupeKey,
    };
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      module: NotificationModule.values.firstWhere(
        (item) => item.name == json['module'],
        orElse: () => NotificationModule.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: json['readAt'] == null
          ? null
          : DateTime.tryParse(json['readAt'].toString()),
      route: json['route']?.toString(),
      metadata: _safeMap(json['metadata']),
      dedupeKey: json['dedupeKey']?.toString(),
    );
  }

  factory AppNotificationModel.fromApi(Map<String, dynamic> json) {
    final metadata = _safeMap(json['metadata']);
    final rawType =
        json['module']?.toString() ??
        json['type']?.toString() ??
        metadata['module']?.toString();
    final rawPriority = json['priority']?.toString();
    final createdAt =
        DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
        DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
        DateTime.now();
    final route =
        json['route']?.toString() ??
        metadata['route']?.toString() ??
        _fallbackRouteForModule(_moduleFromRaw(rawType));

    return AppNotificationModel(
      id: json['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Notification',
      body:
          json['body']?.toString() ??
          json['message']?.toString() ??
          json['description']?.toString() ??
          '',
      module: _moduleFromRaw(rawType),
      priority: _priorityFromRaw(rawPriority),
      createdAt: createdAt,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : (json['read'] == true ? createdAt : null),
      route: route,
      metadata: metadata,
      dedupeKey:
          json['dedupeKey']?.toString() ??
          metadata['dedupeKey']?.toString(),
    );
  }

  Map<String, dynamic> toApiJson({
    String? userId,
    bool includeReadState = true,
  }) {
    return {
      'id': id,
      ...?userId == null ? null : {'userId': userId},
      'title': title,
      'body': body,
      'module': module.name,
      'type': module.name.toUpperCase(),
      'priority': priority.name,
      'route': route,
      'metadata': metadata,
      'dedupeKey': dedupeKey,
      'createdAt': createdAt.toIso8601String(),
      if (includeReadState) 'readAt': readAt?.toIso8601String(),
    };
  }

  static List<AppNotificationModel> decodeList(String raw) {
    final decoded = json.decode(raw);
    if (decoded is! List) return const [];
    return decoded
        .map(
          (item) => AppNotificationModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  static String encodeList(List<AppNotificationModel> items) {
    return json.encode(items.map((item) => item.toJson()).toList());
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  static NotificationModule _moduleFromRaw(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return NotificationModule.system;
    return NotificationModule.values.firstWhere(
      (item) => item.name.toLowerCase() == normalized,
      orElse: () {
        switch (normalized) {
          case 'appointment':
          case 'health':
            return NotificationModule.doctor;
          case 'promo':
          case 'promotion':
            return NotificationModule.promotions;
          case 'home_services':
          case 'home-service':
            return NotificationModule.homeServices;
          case 'hotel_booking':
            return NotificationModule.hotel;
          default:
            return NotificationModule.system;
        }
      },
    );
  }

  static NotificationPriority _priorityFromRaw(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    return NotificationPriority.values.firstWhere(
      (item) => item.name == normalized,
      orElse: () => NotificationPriority.normal,
    );
  }

  static String? _fallbackRouteForModule(NotificationModule module) {
    switch (module) {
      case NotificationModule.orders:
        return '/orders';
      case NotificationModule.messages:
        return '/messages';
      case NotificationModule.food:
        return '/food';
      case NotificationModule.shopping:
        return '/shopping';
      case NotificationModule.grocery:
        return '/grocery';
      case NotificationModule.pharmacy:
        return '/pharmacy';
      case NotificationModule.ride:
        return '/ride';
      case NotificationModule.hotel:
        return '/hotel';
      case NotificationModule.doctor:
        return '/doctor/appointments';
      case NotificationModule.homeServices:
        return '/home-services';
      case NotificationModule.laundry:
        return '/laundry';
      case NotificationModule.promotions:
        return '/promotions';
      case NotificationModule.account:
        return '/profile/settings';
      case NotificationModule.system:
        return '/notifications';
    }
  }
}

extension AppNotificationPresentation on AppNotificationModel {
  IconData get icon {
    switch (module) {
      case NotificationModule.orders:
      case NotificationModule.shopping:
      case NotificationModule.food:
      case NotificationModule.grocery:
      case NotificationModule.pharmacy:
        return Icons.shopping_bag_rounded;
      case NotificationModule.ride:
        return Icons.directions_car_rounded;
      case NotificationModule.messages:
        return Icons.chat_bubble_rounded;
      case NotificationModule.hotel:
        return Icons.hotel_rounded;
      case NotificationModule.doctor:
        return Icons.medical_services_rounded;
      case NotificationModule.homeServices:
        return Icons.home_repair_service_rounded;
      case NotificationModule.laundry:
        return Icons.local_laundry_service_rounded;
      case NotificationModule.promotions:
        return Icons.local_offer_rounded;
      case NotificationModule.account:
        return Icons.verified_user_rounded;
      case NotificationModule.system:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (module) {
      case NotificationModule.shopping:
        return AppColors.shopping;
      case NotificationModule.food:
        return AppColors.food;
      case NotificationModule.grocery:
        return AppColors.grocery;
      case NotificationModule.pharmacy:
        return AppColors.pharmacy;
      case NotificationModule.ride:
        return AppColors.ride;
      case NotificationModule.messages:
        return AppColors.primary;
      case NotificationModule.hotel:
        return AppColors.hotel;
      case NotificationModule.doctor:
        return AppColors.doctor;
      case NotificationModule.homeServices:
        return AppColors.homeServices;
      case NotificationModule.laundry:
        return AppColors.laundry;
      case NotificationModule.promotions:
        return AppColors.warning;
      case NotificationModule.account:
        return AppColors.info;
      case NotificationModule.orders:
        return AppColors.success;
      case NotificationModule.system:
        return AppColors.mediumGrey;
    }
  }

  String get moduleLabel {
    switch (module) {
      case NotificationModule.orders:
        return 'Orders';
      case NotificationModule.messages:
        return 'Messages';
      case NotificationModule.food:
        return 'Food';
      case NotificationModule.shopping:
        return 'Shopping';
      case NotificationModule.grocery:
        return 'Grocery';
      case NotificationModule.pharmacy:
        return 'Pharmacy';
      case NotificationModule.ride:
        return 'Ride';
      case NotificationModule.hotel:
        return 'Hotel';
      case NotificationModule.doctor:
        return 'Health';
      case NotificationModule.homeServices:
        return 'Home Services';
      case NotificationModule.laundry:
        return 'Laundry';
      case NotificationModule.promotions:
        return 'Promotions';
      case NotificationModule.account:
        return 'Account';
      case NotificationModule.system:
        return 'System';
    }
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.promotionsEnabled = true,
    this.locationAlertsEnabled = true,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool promotionsEnabled;
  final bool locationAlertsEnabled;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? promotionsEnabled,
    bool? locationAlertsEnabled,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      promotionsEnabled: promotionsEnabled ?? this.promotionsEnabled,
      locationAlertsEnabled:
          locationAlertsEnabled ?? this.locationAlertsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'promotionsEnabled': promotionsEnabled,
      'locationAlertsEnabled': locationAlertsEnabled,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      promotionsEnabled: json['promotionsEnabled'] as bool? ?? true,
      locationAlertsEnabled: json['locationAlertsEnabled'] as bool? ?? true,
    );
  }

  static NotificationPreferences decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const NotificationPreferences();
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        return NotificationPreferences.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return const NotificationPreferences();
  }

  String encode() => json.encode(toJson());
}
