class RideCategory {
  final String id;
  final String name; // e.g., 'Economy', 'Premium', 'XL'
  final String description;
  final int capacity;
  final double basePrice;
  final double pricePerMile;
  final String timeToArrive;

  RideCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.capacity,
    required this.basePrice,
    required this.pricePerMile,
    required this.timeToArrive,
  });

  factory RideCategory.fromApi(Map<String, dynamic> json) {
    return RideCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Ride',
      description: json['description']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      pricePerMile: (json['pricePerMile'] as num?)?.toDouble() ?? 0,
      timeToArrive: json['timeToArrive']?.toString() ?? '5 min',
    );
  }
}

class RideModel {
  static List<RideCategory> sampleCategories = [
    RideCategory(
      id: 'r1',
      name: 'Economy',
      description: 'Affordable, everyday rides',
      capacity: 4,
      basePrice: 5.0,
      pricePerMile: 1.2,
      timeToArrive: '3 min',
    ),
    RideCategory(
      id: 'r2',
      name: 'Premium',
      description: 'Luxury rides with highly rated drivers',
      capacity: 4,
      basePrice: 10.0,
      pricePerMile: 2.5,
      timeToArrive: '5 min',
    ),
    RideCategory(
      id: 'r3',
      name: 'XL',
      description: 'Groups up to 6 people',
      capacity: 6,
      basePrice: 8.0,
      pricePerMile: 1.8,
      timeToArrive: '7 min',
    ),
  ];
}
