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


}
