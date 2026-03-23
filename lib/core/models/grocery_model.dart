class GroceryCategory {
  final String id;
  final String name;
  final String? iconUrl; // Or IconData if preferred, but string works for sample

  GroceryCategory({required this.id, required this.name, this.iconUrl});
}

class GroceryModel {
  final String id;
  final String name;
  final String categoryId;
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
    required this.price,
    required this.unit,
    required this.description,
    this.imageUrl,
    this.isOrganic = false,
    required this.rating,
  });

  static List<GroceryCategory> sampleCategories = [
    GroceryCategory(id: 'c1', name: 'Fruits & Veg'),
    GroceryCategory(id: 'c2', name: 'Dairy & Eggs'),
    GroceryCategory(id: 'c3', name: 'Meat & Seafood'),
    GroceryCategory(id: 'c4', name: 'Bakery'),
    GroceryCategory(id: 'c5', name: 'Beverages'),
  ];

  static List<GroceryModel> sampleItems = [
    GroceryModel(
      id: 'g1',
      name: 'Fresh Organic Bananas',
      categoryId: 'c1',
      price: 2.99,
      unit: 'bunch',
      description: 'Sweet, organic bananas perfect for snacking.',
      isOrganic: true,
      rating: 4.8,
    ),
    GroceryModel(
      id: 'g2',
      name: 'Whole Milk 1 Gallon',
      categoryId: 'c2',
      price: 4.49,
      unit: 'gallon',
      description: 'Farm fresh whole milk fortified with Vitamin D.',
      isOrganic: false,
      rating: 4.7,
    ),
    GroceryModel(
      id: 'g3',
      name: 'Free Range Eggs',
      categoryId: 'c2',
      price: 5.99,
      unit: 'dozen',
      description: 'Large brown eggs from free roaming chickens.',
      isOrganic: true,
      rating: 4.9,
    ),
    GroceryModel(
      id: 'g4',
      name: 'Salmon Fillet',
      categoryId: 'c3',
      price: 12.99,
      unit: 'lb',
      description: 'Wild caught Alaskan salmon fillet.',
      isOrganic: false,
      rating: 4.6,
    ),
    GroceryModel(
      id: 'g5',
      name: 'Sourdough Bread',
      categoryId: 'c4',
      price: 5.49,
      unit: 'loaf',
      description: 'Freshly baked artisan sourdough bread.',
      isOrganic: false,
      rating: 4.8,
    ),
  ];
}
