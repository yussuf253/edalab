class GroceryCategory {
  final String id;
  final String name;
  final String?
  iconUrl; // Or IconData if preferred, but string works for sample

  GroceryCategory({required this.id, required this.name, this.iconUrl});
}

class GroceryModel {
  final String id;
  final String name;
  final String categoryId;
  final String? categoryName;
  final double price;
  final String unit; // 'kg', 'lb', 'piece', 'bunch'
  final String description;
  final String? imageUrl;
  final bool isOrganic;
  final double rating;

  GroceryModel({
    required this.id,
    required this.name,
    required this.categoryId,
    this.categoryName,
    required this.price,
    required this.unit,
    required this.description,
    this.imageUrl,
    this.isOrganic = false,
    required this.rating,
  });

  factory GroceryModel.fromApi(Map<String, dynamic> json) {
    return GroceryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Grocery Item',
      categoryId: json['categoryId']?.toString() ?? 'grocery',
      categoryName: json['category']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      unit: json['unit']?.toString() ?? 'unit',
      description: json['description']?.toString() ?? '',
      imageUrl: (json['images'] as List?)?.isNotEmpty == true
          ? json['images'][0]?.toString()
          : json['imageUrl']?.toString(),
      isOrganic: json['isOrganic'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }

  static List<GroceryCategory> sampleCategories = [
    GroceryCategory(id: 'grocery-fruits-veg', name: 'Fruits & Veg'),
    GroceryCategory(id: 'grocery-dairy-eggs', name: 'Dairy & Eggs'),
    GroceryCategory(id: 'grocery-meat-seafood', name: 'Meat & Seafood'),
    GroceryCategory(id: 'grocery-bakery', name: 'Bakery'),
    GroceryCategory(id: 'grocery-beverages', name: 'Beverages'),
  ];

  static List<GroceryModel> sampleItems = [
    GroceryModel(
      id: 'g1',
      name: 'Fresh Organic Bananas',
      categoryId: 'grocery-fruits-veg',
      price: 2.99,
      unit: 'bunch',
      description: 'Sweet, organic bananas perfect for snacking.',
      isOrganic: true,
      rating: 4.8,
    ),
    GroceryModel(
      id: 'g2',
      name: 'Whole Milk 1 Gallon',
      categoryId: 'grocery-dairy-eggs',
      price: 4.49,
      unit: 'gallon',
      description: 'Farm fresh whole milk fortified with Vitamin D.',
      isOrganic: false,
      rating: 4.7,
    ),
    GroceryModel(
      id: 'g3',
      name: 'Free Range Eggs',
      categoryId: 'grocery-dairy-eggs',
      price: 5.99,
      unit: 'dozen',
      description: 'Large brown eggs from free roaming chickens.',
      isOrganic: true,
      rating: 4.9,
    ),
    GroceryModel(
      id: 'g4',
      name: 'Salmon Fillet',
      categoryId: 'grocery-meat-seafood',
      price: 12.99,
      unit: 'lb',
      description: 'Wild caught Alaskan salmon fillet.',
      isOrganic: false,
      rating: 4.6,
    ),
    GroceryModel(
      id: 'g5',
      name: 'Sourdough Bread',
      categoryId: 'grocery-bakery',
      price: 5.49,
      unit: 'loaf',
      description: 'Freshly baked artisan sourdough bread.',
      isOrganic: false,
      rating: 4.8,
    ),
  ];
}
