import '../../../core/network/api_client.dart';

class CarRentalCar {
  final String id;
  final String name;
  final String type;
  final int seats;
  final int pricePerDay;
  final String transmission;
  final String fuelType;
  final int year;
  final String? badge;
  final List<String> features;

  CarRentalCar({
    required this.id,
    required this.name,
    required this.type,
    required this.seats,
    required this.pricePerDay,
    required this.transmission,
    required this.fuelType,
    required this.year,
    this.badge,
    required this.features,
  });

  factory CarRentalCar.fromApi(Map<String, dynamic> map) {
    return CarRentalCar(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: map['brand']?.toString() ?? map['type']?.toString() ?? '',
      seats:
          (map['metadata']?['seats'] as num?)?.toInt() ??
          (map['seats'] as num?)?.toInt() ??
          4,
      pricePerDay: (map['price'] as num?)?.toInt() ?? 0,
      transmission:
          map['metadata']?['transmission']?.toString() ??
          map['transmission']?.toString() ??
          '',
      fuelType:
          map['metadata']?['fuelType']?.toString() ??
          map['fuelType']?.toString() ??
          '',
      year:
          (map['metadata']?['year'] as num?)?.toInt() ??
          (map['year'] as num?)?.toInt() ??
          0,
      badge: map['badge']?.toString(),
      features:
          (map['featuresJson'] as List?)?.map((e) => e.toString()).toList() ??
          (map['features'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }
}

class CarRentalService {
  static Future<List<CarRentalCar>> fetchCars() async {
    final resp = await ApiClient.get('/car-rentals');
    if (resp is List) {
      return resp
          .whereType<Map>()
          .map((m) => CarRentalCar.fromApi(Map<String, dynamic>.from(m)))
          .toList();
    }
    if (resp is Map && resp['items'] is List) {
      return (resp['items'] as List)
          .whereType<Map>()
          .map((m) => CarRentalCar.fromApi(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }
}
