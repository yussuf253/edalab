class RestaurantModel {
  final String id;
  final String name;
  final String category;
  final String cuisine;
  final double rating;
  final int reviewCount;
  final String deliveryTime;
  final String deliveryFee;
  final String? imageUrl;
  final bool isOpen;
  final double distance;
  final List<MenuCategory> menu;
  final List<String> tags;

  RestaurantModel({
    required this.id,
    required this.name,
    this.category = 'International & Other',
    required this.cuisine,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTime,
    required this.deliveryFee,
    this.imageUrl,
    this.isOpen = true,
    required this.distance,
    this.menu = const [],
    this.tags = const [],
  });

  factory RestaurantModel.fromApi(Map<String, dynamic> json) {
    final menuJson = (json['menu'] as List?)?.cast<dynamic>() ?? const [];
    String? readImageUrl() {
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
          pick(proProfile['avatarUrl']);
    }

    return RestaurantModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Restaurant',
      category:
          json['category']?.toString() ??
          ((json['tags'] as List?)?.isNotEmpty == true
              ? json['tags'][0]?.toString() ?? 'International & Other'
              : 'International & Other'),
      cuisine: json['cuisine']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      deliveryTime: json['deliveryTime']?.toString() ?? '20-30',
      deliveryFee: _formatDeliveryFee(json['deliveryFee']),
      imageUrl: readImageUrl(),
      isOpen: json['isOpen'] as bool? ?? true,
      distance: (json['distance'] as num?)?.toDouble() ?? 0,
      menu: menuJson
          .map(
            (category) => MenuCategory.fromApi(
              Map<String, dynamic>.from(category as Map),
            ),
          )
          .toList(),
      tags:
          (json['tags'] as List?)?.map((tag) => tag.toString()).toList() ??
          const [],
    );
  }

  static String _formatDeliveryFee(dynamic value) {
    if (value == null) return 'Free';
    final amount = (value as num?)?.toDouble();
    if (amount == null || amount <= 0) return 'Free';
    return 'DJF${amount.toStringAsFixed(2)}';
  }

  static List<RestaurantModel> sampleRestaurants = [
    RestaurantModel(
      id: 'r1',
      name: 'Burger Palace',
      category: 'Burgers & Fast Food',
      cuisine: 'Burgers, Fast Food',
      rating: 4.8,
      reviewCount: 1200,
      deliveryTime: '15-25',
      deliveryFee: 'Free',
      distance: 1.2,
      tags: ['Popular', 'Fast Delivery'],
      menu: [
        MenuCategory('Popular', [
          MenuItem(
            id: 'm1',
            name: 'Classic Cheese Burger',
            description: 'Juicy beef patty with cheddar, lettuce, tomato',
            price: 12.99,
            isPopular: true,
          ),
          MenuItem(
            id: 'm2',
            name: 'BBQ Bacon Burger',
            description: 'Smoky BBQ sauce, crispy bacon, onion rings',
            price: 15.99,
          ),
          MenuItem(
            id: 'm3',
            name: 'Veggie Delight',
            description: 'Plant-based patty, avocado, fresh salad',
            price: 11.99,
            isPopular: true,
          ),
        ]),
        MenuCategory('Sides', [
          MenuItem(
            id: 'm4',
            name: 'Loaded Fries',
            description: 'Cheese, jalapenos, sour cream',
            price: 7.99,
            isPopular: true,
          ),
          MenuItem(
            id: 'm5',
            name: 'Onion Rings',
            description: 'Crispy battered onion rings',
            price: 5.99,
          ),
          MenuItem(
            id: 'm6',
            name: 'Coleslaw',
            description: 'Fresh homemade coleslaw',
            price: 3.99,
          ),
        ]),
        MenuCategory('Drinks', [
          MenuItem(
            id: 'm7',
            name: 'Milkshake',
            description: 'Vanilla, Chocolate, or Strawberry',
            price: 5.99,
          ),
          MenuItem(
            id: 'm8',
            name: 'Fresh Lemonade',
            description: 'Freshly squeezed with mint',
            price: 4.49,
          ),
          MenuItem(
            id: 'm9',
            name: 'Iced Coffee',
            description: 'Cold brew with cream',
            price: 4.99,
          ),
        ]),
      ],
    ),
    RestaurantModel(
      id: 'r2',
      name: 'Pizza Royal',
      category: 'Pizza & Italian',
      cuisine: 'Pizza, Italian',
      rating: 4.6,
      reviewCount: 850,
      deliveryTime: '20-30',
      deliveryFee: 'DJF2.99',
      distance: 2.1,
      tags: ['Italian', 'Pizza'],
    ),
    RestaurantModel(
      id: 'r3',
      name: 'Sushi Master',
      category: 'Sushi & Asian',
      cuisine: 'Japanese, Sushi',
      rating: 4.9,
      reviewCount: 2100,
      deliveryTime: '25-35',
      deliveryFee: 'DJF3.99',
      distance: 3.5,
      tags: ['Top Rated', 'Japanese'],
    ),
    RestaurantModel(
      id: 'r4',
      name: 'Taco Fiesta',
      category: 'Tacos & Mexican',
      cuisine: 'Mexican, Tacos',
      rating: 4.5,
      reviewCount: 670,
      deliveryTime: '15-20',
      deliveryFee: 'Free',
      distance: 0.8,
      tags: ['Mexican', 'Nearby'],
    ),
    RestaurantModel(
      id: 'r5',
      name: 'Dragon Wok',
      category: 'Sushi & Asian',
      cuisine: 'Chinese, Asian',
      rating: 4.7,
      reviewCount: 1500,
      deliveryTime: '30-40',
      deliveryFee: 'DJF1.99',
      distance: 4.2,
      tags: ['Chinese', 'Asian'],
    ),
    RestaurantModel(
      id: 'r6',
      name: 'Curry House',
      category: 'Indian',
      cuisine: 'Indian, Curry',
      rating: 4.4,
      reviewCount: 920,
      deliveryTime: '25-35',
      deliveryFee: 'DJF2.49',
      distance: 2.8,
      tags: ['Indian', 'Spicy'],
    ),
  ];
}

class MenuCategory {
  final String name;
  final List<MenuItem> items;

  MenuCategory(this.name, this.items);

  factory MenuCategory.fromApi(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?)?.cast<dynamic>() ?? const [];
    return MenuCategory(
      json['name']?.toString() ?? 'Menu',
      itemsJson
          .map(
            (item) => MenuItem.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final bool isPopular;
  final bool isAvailable;
  final List<String>? customizations;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.isPopular = false,
    this.isAvailable = true,
    this.customizations,
  });

  factory MenuItem.fromApi(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Item',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      isPopular: json['isPopular'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      customizations: (json['customizations'] as List?)
          ?.map((item) => item.toString())
          .toList(),
    );
  }
}
