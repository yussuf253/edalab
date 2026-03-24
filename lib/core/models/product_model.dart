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
    );
  }

  static List<ProductModel> sampleProducts = [
    ProductModel(
      id: 'p1', name: 'Nike Air Max 270', brand: 'Nike',
      description: 'The Nike Air Max 270 delivers visible cushioning under every step. Updated for modern comfort, it nods to the original 1991 Air Max 180 with its exaggerated tongue top and heritage tongue.',
      price: 129.99, originalPrice: 159.99, rating: 4.8, reviewCount: 2340,
      category: 'Shoes', badge: 'Best Seller',
      colors: ['Black', 'White', 'Blue', 'Red'],
      sizes: ['US 7', 'US 8', 'US 9', 'US 10', 'US 11'],
      features: ['Lightweight mesh upper', 'Max Air 270 unit', 'Foam midsole', 'Rubber outsole'],
    ),
    ProductModel(
      id: 'p2', name: 'Apple AirPods Pro', brand: 'Apple',
      description: 'Active Noise Cancellation for immersive sound. Transparency mode for hearing the world around you. A more customizable fit for comfort.',
      price: 249.99, rating: 4.9, reviewCount: 5600,
      category: 'Electronics', badge: 'Top Rated',
      colors: ['White'],
      features: ['Active Noise Cancellation', 'Transparency mode', 'Spatial audio', 'MagSafe charging'],
    ),
    ProductModel(
      id: 'p3', name: 'Levi\'s 501 Original', brand: 'Levi\'s',
      description: 'The original jean. The iconic straight fit with signature button fly. Sits at the waist with a regular fit through the hip and thigh.',
      price: 79.99, originalPrice: 98.00, rating: 4.6, reviewCount: 1800,
      category: 'Clothing',
      colors: ['Dark Blue', 'Light Blue', 'Black'],
      sizes: ['28', '30', '32', '34', '36'],
      features: ['100% Cotton', 'Button fly', 'Straight fit', 'Made in USA'],
    ),
    ProductModel(
      id: 'p4', name: 'Samsung Galaxy Watch', brand: 'Samsung',
      description: 'Track your fitness and stay connected with the Samsung Galaxy Watch. Features advanced health monitoring.',
      price: 299.99, originalPrice: 349.99, rating: 4.7, reviewCount: 3200,
      category: 'Electronics', badge: 'New',
      colors: ['Black', 'Silver', 'Rose Gold'],
      sizes: ['40mm', '44mm'],
      features: ['Heart rate monitor', 'Sleep tracking', 'GPS', 'Water resistant'],
    ),
    ProductModel(
      id: 'p5', name: 'Ray-Ban Aviator', brand: 'Ray-Ban',
      description: 'The Ray-Ban Aviator Classic is a timeless icon. Originally designed for U.S. aviators.',
      price: 163.00, rating: 4.5, reviewCount: 890,
      category: 'Accessories',
      colors: ['Gold/Green', 'Silver/Blue', 'Black/Gray'],
      features: ['Crystal lenses', 'Metal frame', '100% UV protection', 'Iconic design'],
    ),
    ProductModel(
      id: 'p6', name: 'Dyson V15 Detect', brand: 'Dyson',
      description: 'Intelligently reveals microscopic dust. Dyson\'s most powerful, intelligent cordless vacuum.',
      price: 749.99, rating: 4.8, reviewCount: 1100,
      category: 'Home', badge: 'Premium',
      features: ['Laser dust detection', '60 min runtime', 'LCD screen', 'HEPA filtration'],
    ),
  ];
}
