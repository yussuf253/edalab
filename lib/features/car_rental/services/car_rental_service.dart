import '../../../core/network/api_client.dart';
import '../../../core/config/zone_scope.dart';

class CarRentalBooking {
  final String id;
  final String carId;
  final String? carName;
  final DateTime startDate;
  final DateTime endDate;
  final int? totalPrice;
  final String status;
  final int totalDays;
  final String? pickupLocation;
  final String? dropoffLocation;

  CarRentalBooking({
    required this.id,
    required this.carId,
    this.carName,
    required this.startDate,
    required this.endDate,
    this.totalPrice,
    required this.status,
    this.totalDays = 1,
    this.pickupLocation,
    this.dropoffLocation,
  });

  bool get isPast => endDate.isBefore(DateTime.now());
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get canCancel =>
      !isCancelled && !isCompleted && startDate.isAfter(DateTime.now());

  factory CarRentalBooking.fromApi(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return CarRentalBooking(
      id: (map['id'] ?? map['_id'] ?? map['bookingId'])?.toString() ?? '',
      carId: (map['carId'] ?? map['car']?['id'])?.toString() ?? '',
      carName: map['car']?['name']?.toString() ?? map['carName']?.toString(),
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      totalPrice: (map['totalPrice'] ?? map['total'] ?? map['price']) is num
          ? ((map['totalPrice'] ?? map['total'] ?? map['price']) as num).toInt()
          : null,
      status: map['status']?.toString() ?? 'confirmed',
      totalDays: (map['totalDays'] as num?)?.toInt() ?? 1,
      pickupLocation: map['pickupLocation']?.toString(),
      dropoffLocation: map['dropoffLocation']?.toString(),
    );
  }
}

class CarRentalBookingsService {
  CarRentalBookingsService._();

  /// Backend contract expected: `GET /car-rentals/bookings/user/{userId}`
  /// returning a list of booking objects. Returns null (not an empty list)
  /// on failure, so the screen can tell "no bookings yet" apart from
  /// "couldn't reach the server" and show the right message for each.
  static Future<List<CarRentalBooking>?> fetchUserBookings(
    String userId,
  ) async {
    try {
      final resp = await ApiClient.get('/car-rentals/bookings/user/$userId');
      final list = resp is List
          ? resp
          : (resp is Map && resp['items'] is List)
          ? resp['items'] as List
          : null;
      if (list == null) return null;
      return list
          .whereType<Map>()
          .map((e) => CarRentalBooking.fromApi(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Backend contract expected: `POST /car-rentals/bookings/{bookingId}/cancel`
  static Future<bool> cancelBooking(String bookingId, String userId) async {
    try {
      await ApiClient.post('/car-rentals/bookings/$bookingId/cancel', {
        'userId': userId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

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
  final String description;
  final String? imageUrl;
  final List<String> imageUrls;
  final String mileage;
  final bool available;

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
    this.description = '',
    this.imageUrl,
    this.imageUrls = const [],
    this.mileage = 'Unlimited',
    this.available = true,
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
      pricePerDay: ((map['pricePerDay'] ?? map['price']) as num?)?.toInt() ?? 0,
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
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString(),
      imageUrls:
          (map['imageUrls'] as List?)?.map((e) => e.toString()).toList() ??
          (map['imageUrlsJson'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      mileage: map['mileage']?.toString() ?? 'Unlimited',
      available: map['available'] as bool? ?? map['inStock'] as bool? ?? true,
    );
  }
}

class CarRentalService {
  static Future<List<CarRentalCar>> fetchCars({String? type}) async {
    final params = <String, String>{};
    if (type != null && type.isNotEmpty) params['type'] = type;
    final query = Uri(queryParameters: params).query;
    final path = '/car-rentals${query.isEmpty ? '' : '?$query'}';
    final resp = await ApiClient.get(ZoneScope.appendZone(path));
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

  static Future<CarRentalCar> fetchCar(String carId) async {
    final response = await ApiClient.get(
      ZoneScope.appendZone('/car-rentals/$carId'),
      forceRefresh: true,
    );
    return CarRentalCar.fromApi(Map<String, dynamic>.from(response as Map));
  }

  static Future<bool> checkAvailability({
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final query = Uri(
      queryParameters: {
        'carId': carId,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
      },
    ).query;
    final response = await ApiClient.get(
      ZoneScope.appendZone('/car-rentals/bookings/availability?$query'),
      forceRefresh: true,
    );
    return (response as Map)['available'] as bool? ?? false;
  }

  static Future<CarRentalBooking> createBooking({
    required String userId,
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    required String pickupLocation,
    String? dropoffLocation,
    String? notes,
  }) async {
    final response = await ApiClient.post('/car-rentals/bookings', {
      'userId': userId,
      'carId': carId,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'pickupLocation': pickupLocation,
      'dropoffLocation': ?dropoffLocation,
      'notes': ?notes,
      'zone': ?ZoneScope.currentZoneKey,
    });
    return CarRentalBooking.fromApi(Map<String, dynamic>.from(response as Map));
  }
}
