import '../../../core/network/api_client.dart';

class CarRentalCar {
  final String id;
  final String name;
  final String type;
  final String description;
  final double pricePerDay;
  final String unit;
  final String? badge;
  final String? imageUrl;
  final List<String> imageUrls;
  final List<String> features;
  final int seats;
  final String transmission;
  final String fuelType;
  final int? year;
  final String mileage;
  final bool available;

  const CarRentalCar({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.pricePerDay,
    required this.unit,
    this.badge,
    this.imageUrl,
    required this.imageUrls,
    required this.features,
    required this.seats,
    required this.transmission,
    required this.fuelType,
    this.year,
    required this.mileage,
    required this.available,
  });

  factory CarRentalCar.fromApi(Map<String, dynamic> data) {
    return CarRentalCar(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      type: data['type']?.toString() ?? 'Standard',
      description: data['description']?.toString() ?? '',
      pricePerDay: (data['pricePerDay'] as num?)?.toDouble() ?? 0,
      unit: data['unit']?.toString() ?? 'per day',
      badge: data['badge']?.toString(),
      imageUrl: data['imageUrl']?.toString(),
      imageUrls: (data['imageUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      features: (data['features'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      seats: (data['seats'] as num?)?.toInt() ?? 5,
      transmission: data['transmission']?.toString() ?? 'Automatic',
      fuelType: data['fuelType']?.toString() ?? 'Petrol',
      year: (data['year'] as num?)?.toInt(),
      mileage: data['mileage']?.toString() ?? 'Unlimited',
      available: data['available'] as bool? ?? true,
    );
  }

}

class CarRentalBooking {
  final String id;
  final String userId;
  final String carId;
  final String carName;
  final String carType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double pricePerDay;
  final double subtotal;
  final double tax;
  final double total;
  final String status;
  final String? pickupLocation;
  final String? dropoffLocation;
  final String? notes;
  final DateTime createdAt;

  const CarRentalBooking({
    required this.id,
    required this.userId,
    required this.carId,
    required this.carName,
    required this.carType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.pricePerDay,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.pickupLocation,
    this.dropoffLocation,
    this.notes,
    required this.createdAt,
  });

  factory CarRentalBooking.fromApi(Map<String, dynamic> data) {
    return CarRentalBooking(
      id: data['id']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      carId: data['carId']?.toString() ?? '',
      carName: data['carName']?.toString() ?? '',
      carType: data['carType']?.toString() ?? '',
      startDate: DateTime.tryParse(data['startDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate: DateTime.tryParse(data['endDate']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
      totalDays: (data['totalDays'] as num?)?.toInt() ?? 1,
      pricePerDay: (data['pricePerDay'] as num?)?.toDouble() ?? 0,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      status: data['status']?.toString() ?? 'CONFIRMED',
      pickupLocation: data['pickupLocation']?.toString(),
      dropoffLocation: data['dropoffLocation']?.toString(),
      notes: data['notes']?.toString(),
      createdAt:
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CarRentalService {
  static Future<List<CarRentalCar>> fetchCars({String? type}) async {
    try {
      final query = type != null ? '?type=${Uri.encodeComponent(type)}' : '';
      final response = await ApiClient.get('/car-rentals$query');
      final data = response as Map<String, dynamic>?;
      final carList = data?['cars'] as List? ?? [];
      final cars = carList
          .map((item) =>
              CarRentalCar.fromApi(Map<String, dynamic>.from(item as Map)))
          .toList();
      return cars;
    } catch (_) {
      return const [];
    }
  }

  static Future<CarRentalCar> fetchCar(String carId) async {
    final response = await ApiClient.get('/car-rentals/$carId');
    return CarRentalCar.fromApi(Map<String, dynamic>.from(response as Map));
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
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'pickupLocation': pickupLocation,
      if (dropoffLocation != null) 'dropoffLocation': dropoffLocation,
      if (notes != null) 'notes': notes,
    });
    return CarRentalBooking.fromApi(Map<String, dynamic>.from(response as Map));
  }

  static Future<List<CarRentalBooking>> fetchUserBookings(String userId) async {
    final response =
        await ApiClient.get('/car-rentals/bookings/user/$userId');
    final list = response as List? ?? [];
    return list
        .map((item) =>
            CarRentalBooking.fromApi(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
