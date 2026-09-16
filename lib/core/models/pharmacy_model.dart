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
  final bool inStock;
  /// Units available. Null when the backend does not report a quantity.
  final int? stockQty;
  /// Quantity at or below which the item is considered low stock.
  final int lowStockThreshold;
  /// True when stock is non-zero but at or below [lowStockThreshold].
  bool get isLowStock =>
      inStock && stockQty != null && stockQty! <= lowStockThreshold;

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
    this.inStock = true,
    this.stockQty,
    this.lowStockThreshold = 5,
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
          '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      description: json['description']?.toString() ?? '',
      imageUrl: (json['images'] as List?)?.isNotEmpty == true
          ? json['images'][0]?.toString()
          : json['imageUrl']?.toString(),
      requiresPrescription: json['requiresPrescription'] as bool? ?? false,
      dosage: json['dosage']?.toString() ?? '',
      size: json['packageSize']?.toString() ?? json['size']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount:
          (json['reviewCount'] as num?)?.toInt() ??
          (json['reviewsCount'] as num?)?.toInt() ??
          0,
      sourceBusiness:
          metadata['sourceBusiness']?.toString() ??
          json['shopName']?.toString(),
      inStock: json['inStock'] as bool? ?? true,
      stockQty: metadata['stockQty'] is num
          ? (metadata['stockQty'] as num).toInt()
          : null,
      lowStockThreshold: metadata['lowStockThreshold'] is num
          ? (metadata['lowStockThreshold'] as num).toInt()
          : 5,
    );
  }

}
