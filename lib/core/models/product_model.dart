class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String description;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final List<String> images;
  final List<String> colors;
  final List<String> sizes;
  final String category;
  final String? badge;
  final bool isFavorite;
  final bool inStock;
  final List<String> features;
  final String? shopId;
  final String? shopName;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    this.images = const [],
    this.colors = const [],
    this.sizes = const [],
    required this.category,
    this.badge,
    this.isFavorite = false,
    this.inStock = true,
    this.features = const [],
    this.shopId,
    this.shopName,
  });

  double get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  ProductModel copyWith({bool? isFavorite}) {
    return ProductModel(
      id: id,
      name: name,
      brand: brand,
      description: description,
      price: price,
      originalPrice: originalPrice,
      rating: rating,
      reviewCount: reviewCount,
      images: images,
      colors: colors,
      sizes: sizes,
      category: category,
      badge: badge,
      isFavorite: isFavorite ?? this.isFavorite,
      inStock: inStock,
      features: features,
      shopId: shopId,
      shopName: shopName,
    );
  }

  factory ProductModel.fromApi(Map<String, dynamic> json) {
    List<String> readStringList(dynamic value) {
      if (value is List) {
        return value.map((entry) => entry.toString()).toList();
      }
      return const [];
    }

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      images: readStringList(json['images']),
      colors: readStringList(json['colors']),
      sizes: readStringList(json['sizes']),
      category: json['category'] as String? ?? json['categoryId'] as String? ?? 'Uncategorized',
      badge: json['badge'] as String?,
      inStock: json['inStock'] as bool? ?? true,
      features: readStringList(json['features']),
      shopId: json['shopId']?.toString(),
      shopName: json['shopName']?.toString(),
    );
  }

}
