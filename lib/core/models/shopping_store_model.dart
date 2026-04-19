class ShoppingStoreModel {
  final String id;
  final String name;
  final String tagline;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final int productCount;
  final List<String> categories;
  final String? badge;
  final double minPrice;
  final double maxPrice;
  final List<String> highlights;

  ShoppingStoreModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.productCount,
    this.categories = const [],
    this.badge,
    required this.minPrice,
    required this.maxPrice,
    this.highlights = const [],
  });

  factory ShoppingStoreModel.fromApi(Map<String, dynamic> json) {
    List<String> readStringList(dynamic value) {
      if (value is List) {
        return value.map((entry) => entry.toString()).toList();
      }
      return const [];
    }

    String readImageUrl() {
      String? pick(dynamic value) {
        final text = value?.toString().trim();
        if (text == null || text.isEmpty) return null;
        return text;
      }

      final proProfile = json['proProfile'] is Map
          ? Map<String, dynamic>.from(json['proProfile'] as Map)
          : const <String, dynamic>{};
      final profile = json['profile'] is Map
          ? Map<String, dynamic>.from(json['profile'] as Map)
          : const <String, dynamic>{};

      return pick(json['imageUrl']) ??
          pick(json['profileImageUrl']) ??
          pick(json['profileAvatarUrl']) ??
          pick(json['avatarUrl']) ??
          pick(profile['imageUrl']) ??
          pick(profile['avatarUrl']) ??
          pick(proProfile['imageUrl']) ??
          pick(proProfile['avatarUrl']) ??
          '';
    }

    return ShoppingStoreModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Store',
      tagline: json['tagline']?.toString() ?? 'Curated picks for you',
      imageUrl: readImageUrl(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      categories: readStringList(json['categories']),
      badge: json['badge']?.toString(),
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0,
      maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0,
      highlights: readStringList(json['highlights']),
    );
  }

  static List<ShoppingStoreModel> sampleStores = [
    ShoppingStoreModel(
      id: 'nike',
      name: 'Nike',
      tagline: 'Performance shoes, apparel, and everyday essentials.',
      imageUrl: '',
      rating: 4.8,
      reviewCount: 2340,
      productCount: 24,
      categories: const ['Shoes', 'Clothing', 'Accessories'],
      badge: 'Popular',
      minPrice: 39.99,
      maxPrice: 189.99,
      highlights: const ['Fast shipping', 'New drops weekly'],
    ),
    ShoppingStoreModel(
      id: 'apple',
      name: 'Apple',
      tagline: 'Premium devices, audio, and accessories.',
      imageUrl: '',
      rating: 4.9,
      reviewCount: 5600,
      productCount: 16,
      categories: const ['Electronics', 'Accessories'],
      badge: 'Top Rated',
      minPrice: 49.99,
      maxPrice: 1299.99,
      highlights: const ['Official products', '1-year warranty'],
    ),
    ShoppingStoreModel(
      id: 'levi-s',
      name: "Levi's",
      tagline: 'Timeless denim and casual essentials.',
      imageUrl: '',
      rating: 4.6,
      reviewCount: 1800,
      productCount: 18,
      categories: const ['Clothing'],
      minPrice: 29.99,
      maxPrice: 119.99,
      highlights: const ['Classic fits', 'Seasonal discounts'],
    ),
  ];
}
