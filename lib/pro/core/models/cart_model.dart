class CartItem {
  final String id;
  final String name;
  final String? brand;
  final double price;
  final String? imageUrl;
  final String? description;
  final String? color;
  final String? size;
  final String? shopId;
  final String? shopName;
  int quantity;
  final String moduleType; // 'shopping', 'food', 'pharmacy', 'grocery'

  CartItem({
    required this.id,
    required this.name,
    this.brand,
    required this.price,
    this.imageUrl,
    this.description,
    this.color,
    this.size,
    this.shopId,
    this.shopName,
    this.quantity = 1,
    required this.moduleType,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'color': color,
      'size': size,
      'shopId': shopId,
      'shopName': shopName,
      'quantity': quantity,
      'moduleType': moduleType,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      brand: json['brand']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      shopId: json['shopId']?.toString(),
      shopName: json['shopName']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      moduleType: json['moduleType']?.toString() ?? '',
    );
  }
}

class OrderModel {
  final String id;
  final String moduleType;
  final String moduleName;
  final String status; // 'active', 'completed', 'cancelled'
  final double total;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final List<CartItem> items;
  final String? trackingInfo;

  OrderModel({
    required this.id,
    required this.moduleType,
    required this.moduleName,
    required this.status,
    required this.total,
    required this.createdAt,
    this.deliveredAt,
    this.items = const [],
    this.trackingInfo,
  });

}
