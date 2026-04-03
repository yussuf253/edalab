class PharmacyModel {
  final String id;
  final String name;
  final String category; // 'Pain Relief', 'First Aid', 'Vitamins', etc.
  final double price;
  final String description;
  final String? imageUrl;
  final bool requiresPrescription;
  final String dosage;
  final String size; // e.g., '30 Tablets'
  final double rating;
  final int reviewsCount;
  final String? sourceBusiness;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.imageUrl,
    this.requiresPrescription = false,
    required this.dosage,
    required this.size,
    required this.rating,
    required this.reviewsCount,
    this.sourceBusiness,
  });

  factory PharmacyModel.fromApi(Map<String, dynamic> json) {
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : const <String, dynamic>{};

    return PharmacyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Medicine',
      category:
          json['category']?.toString() ??
          json['categoryId']?.toString() ??
          'General',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
      imageUrl: (json['images'] as List?)?.isNotEmpty == true
          ? json['images'][0]?.toString()
          : json['imageUrl']?.toString(),
      requiresPrescription: json['requiresPrescription'] as bool? ?? false,
      dosage: json['dosage']?.toString() ?? 'Use as directed.',
      size: json['packageSize']?.toString() ?? json['size']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount:
          (json['reviewCount'] as num?)?.toInt() ??
          (json['reviewsCount'] as num?)?.toInt() ??
          0,
      sourceBusiness:
          metadata['sourceBusiness']?.toString() ??
          json['shopName']?.toString(),
    );
  }

  static List<PharmacyModel> sampleItems = [
    PharmacyModel(
      id: 'p1',
      name: 'Paracetamol 500mg',
      category: 'Pain Relief',
      price: 4.99,
      description: 'Effective pain relief and fever reduction.',
      requiresPrescription: false,
      dosage: 'Take 1-2 tablets every 4-6 hours',
      size: '20 Tablets',
      rating: 4.8,
      reviewsCount: 154,
    ),
    PharmacyModel(
      id: 'p2',
      name: 'Amoxicillin 250mg',
      category: 'Antibiotics',
      price: 12.99,
      description: 'Used to treat a wide variety of bacterial infections.',
      requiresPrescription: true,
      dosage: 'Take 1 capsule every 8 hours',
      size: '15 Capsules',
      rating: 4.9,
      reviewsCount: 89,
    ),
    PharmacyModel(
      id: 'p3',
      name: 'Vitamin D3 1000 IU',
      category: 'Vitamins',
      price: 9.99,
      description: 'Supports bone health and immune system.',
      requiresPrescription: false,
      dosage: 'Take 1 softgel daily with a meal',
      size: '60 Softgels',
      rating: 4.7,
      reviewsCount: 432,
    ),
    PharmacyModel(
      id: 'p4',
      name: 'Cough Syrup',
      category: 'Cold & Flu',
      price: 8.49,
      description: 'Soothes dry cough and throat irritation.',
      requiresPrescription: false,
      dosage: '10ml every 4 hours for adults',
      size: '150 ml Glass Bottle',
      rating: 4.5,
      reviewsCount: 201,
    ),
  ];
}
