class HotelModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final double rating;
  final int reviewsCount;
  final double pricePerNight;
  final List<String> amenities;
  final String description;
  final List<String>? imageUrls;
  final List<HotelRoomOption> roomOptions;

  HotelModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerNight,
    required this.amenities,
    required this.description,
    this.imageUrls,
    this.roomOptions = const [],
  });

  factory HotelModel.fromApi(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Hotel',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0,
      amenities:
          (json['amenities'] as List?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      description: json['description']?.toString() ?? '',
      imageUrls: (json['imageUrls'] as List?)
          ?.map((item) => item.toString())
          .toList(),
      roomOptions:
          (json['roomOptions'] as List?)
              ?.map(
                (item) => HotelRoomOption.fromApi(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          _defaultRoomOptions((json['pricePerNight'] as num?)?.toDouble() ?? 0),
    );
  }

  static List<HotelModel> sampleHotels = [
    HotelModel(
      id: 'h1',
      name: 'Grand Royale Hotel',
      address: '123 Luxury Ave',
      city: 'New York',
      rating: 4.9,
      reviewsCount: 1204,
      pricePerNight: 299.99,
      amenities: ['Pool', 'Spa', 'Gym', 'Free WiFi', 'Restaurant'],
      description: 'Experience ultimate luxury in the heart of the city.',
      roomOptions: _defaultRoomOptions(299.99),
    ),
    HotelModel(
      id: 'h2',
      name: 'Oasis Beach Resort',
      address: '456 Sandy Boulevard',
      city: 'Miami',
      rating: 4.7,
      reviewsCount: 845,
      pricePerNight: 195.00,
      amenities: ['Beachfront', 'Pool', 'Bar', 'Free Breakfast'],
      description: 'Relax and unwind at our beautiful beachfront property.',
      roomOptions: _defaultRoomOptions(195.00),
    ),
    HotelModel(
      id: 'h3',
      name: 'Mountain View Lodge',
      address: '789 Alpine Drive',
      city: 'Aspen',
      rating: 4.8,
      reviewsCount: 562,
      pricePerNight: 350.00,
      amenities: ['Ski-in/Ski-out', 'Fireplace', 'Hot Tub', 'Restaurant'],
      description: 'The premier destination for your winter getaway.',
      roomOptions: _defaultRoomOptions(350.00),
    ),
  ];

  static List<HotelRoomOption> _defaultRoomOptions(double basePrice) {
    final normalizedBasePrice = (basePrice > 0 ? basePrice : 120).toDouble();
    return [
      HotelRoomOption(
        id: 'standard-room',
        name: 'Standard Room',
        description: '1 Bed • City View',
        pricePerNight: normalizedBasePrice,
        capacity: 2,
        available: true,
      ),
      HotelRoomOption(
        id: 'premium-suite',
        name: 'Premium Suite',
        description: '1 King Bed • Balcony',
        pricePerNight: normalizedBasePrice * 1.45,
        capacity: 2,
        available: true,
      ),
      HotelRoomOption(
        id: 'family-suite',
        name: 'Family Suite',
        description: '2 Beds • Family Stay',
        pricePerNight: normalizedBasePrice * 1.8,
        capacity: 4,
        available: true,
      ),
    ];
  }
}

class HotelRoomOption {
  final String id;
  final String name;
  final String description;
  final double pricePerNight;
  final int capacity;
  final bool available;

  const HotelRoomOption({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerNight,
    required this.capacity,
    this.available = true,
  });

  factory HotelRoomOption.fromApi(Map<String, dynamic> json) {
    return HotelRoomOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Room',
      description: json['description']?.toString() ?? '',
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble() ?? 0,
      capacity: (json['capacity'] as num?)?.toInt() ?? 2,
      available: json['available'] as bool? ?? true,
    );
  }
}
