import '../../../core/network/api_client.dart';

class CarRentalBooking {
  final String id;
  final String carId;
  final String? carName;
  final DateTime startDate;
  final DateTime endDate;
  final int? totalPrice;
  final String status;

  CarRentalBooking({
    required this.id,
    required this.carId,
    this.carName,
    required this.startDate,
    required this.endDate,
    this.totalPrice,
    required this.status,
  });

  bool get isPast => endDate.isBefore(DateTime.now());
  bool get isCancelled => status.toLowerCase() == 'cancelled';

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
          ? ((map['totalPrice'] ?? map['total'] ?? map['price']) as num)
                .toInt()
          : null,
      status: map['status']?.toString() ?? 'confirmed',
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
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      await ApiClient.post('/car-rentals/bookings/$bookingId/cancel', {});
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
