
enum ProProfileType {
  shop,
  provider,
  doctor,
  delivery,
  rider,
}

enum ProModule {
  shopping,
  food,
  pharmacy,
  services,
  laundry,
  doctor,
  shoppingDelivery,
  foodDelivery,
  pharmacyDelivery,
  ride,
}

class ProProfile {
  final String id;
  final String userId;
  final ProProfileType type;
  final List<ProModule> activeModules;
  final String businessName;
  final String? avatarUrl;
  final bool isOnline;
  final bool isVerified;
  
  const ProProfile({
    required this.id,
    required this.userId,
    required this.type,
    required this.activeModules,
    required this.businessName,
    this.avatarUrl,
    this.isOnline = true,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'activeModules': activeModules.map((e) => e.name).toList(),
      'businessName': businessName,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'isVerified': isVerified,
    };
  }

  factory ProProfile.fromJson(Map<String, dynamic> json) {
    final rawModules = (json['activeModules'] as List<dynamic>? ?? const []);
    final parsedModules = rawModules
        .map(_moduleFromRaw)
        .toSet()
        .toList(growable: false);

    return ProProfile(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      type: _typeFromRaw(
        json['type']?.toString(),
        parsedModules,
      ),
      activeModules: parsedModules,
      businessName: json['businessName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  ProProfile copyWith({
    String? id,
    String? userId,
    ProProfileType? type,
    List<ProModule>? activeModules,
    String? businessName,
    String? avatarUrl,
    bool? isOnline,
    bool? isVerified,
  }) {
    return ProProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      activeModules: activeModules ?? this.activeModules,
      businessName: businessName ?? this.businessName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  static ProProfileType _typeFromRaw(
    String? rawType,
    List<ProModule> modules,
  ) {
    switch (rawType) {
      case 'SHOP':
      case 'shop':
        return ProProfileType.shop;
      case 'PROVIDER':
      case 'provider':
        return ProProfileType.provider;
      case 'DOCTOR':
      case 'doctor':
        return ProProfileType.doctor;
      case 'DELIVERY':
      case 'delivery':
        return ProProfileType.delivery;
      case 'RIDER':
      case 'rider':
        final isDeliveryProfile = modules.any(
          (module) => {
            ProModule.shoppingDelivery,
            ProModule.foodDelivery,
            ProModule.pharmacyDelivery,
          }.contains(module),
        );
        return isDeliveryProfile ? ProProfileType.delivery : ProProfileType.rider;
      default:
        return ProProfileType.shop;
    }
  }

  static ProModule _moduleFromRaw(dynamic raw) {
    switch (raw?.toString()) {
      case 'stores':
      case 'shopping':
        return ProModule.shopping;
      case 'food':
      case 'restaurant':
      case 'restaurants':
        return ProModule.food;
      case 'pharmacy':
      case 'pharmacies':
        return ProModule.pharmacy;
      case 'services':
      case 'homeServices':
      case 'home_services':
        return ProModule.services;
      case 'laundry':
        return ProModule.laundry;
      case 'consultations':
      case 'telemedicine':
      case 'doctor':
        return ProModule.doctor;
      case 'shopDelivery':
      case 'shoppingDelivery':
      case 'shopping_delivery':
        return ProModule.shoppingDelivery;
      case 'foodDelivery':
      case 'food_delivery':
        return ProModule.foodDelivery;
      case 'pharmacyDelivery':
      case 'pharmacy_delivery':
        return ProModule.pharmacyDelivery;
      case 'ride':
      case 'rider':
        return ProModule.ride;
      default:
        return ProModule.shopping;
    }
  }
}
