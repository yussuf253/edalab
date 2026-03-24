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
    ),
  ];
}
