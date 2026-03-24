class CartItem {
  final String id;
  final String name;
  final String? brand;
  final double price;
  final String? imageUrl;
  final String? color;
  final String? size;
  int quantity;
  final String moduleType; // 'shopping', 'food', 'pharmacy', 'grocery'

  CartItem({
    required this.id,
    required this.name,
    this.brand,
    required this.price,
    this.imageUrl,
    this.color,
    this.size,
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
      'color': color,
      'size': size,
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
      color: json['color']?.toString(),
      size: json['size']?.toString(),
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

  static List<OrderModel> sampleOrders = [
    OrderModel(
      id: 'ORD-001',
      moduleType: 'food',
      moduleName: 'Burger Palace',
      status: 'active',
      total: 32.48,
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    OrderModel(
      id: 'ORD-002',
      moduleType: 'laundry',
      moduleName: 'Wash & Fold',
      status: 'active',
      total: 30.00,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    OrderModel(
      id: 'ORD-003',
      moduleType: 'shopping',
      moduleName: 'Nike Air Max 270',
      status: 'completed',
      total: 129.99,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      deliveredAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    OrderModel(
      id: 'ORD-004',
      moduleType: 'doctor',
      moduleName: 'Dr. Sarah Johnson',
      status: 'completed',
      total: 50.00,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    OrderModel(
      id: 'ORD-005',
      moduleType: 'hotel',
      moduleName: 'Grand Royale Hotel',
      status: 'completed',
      total: 642.98,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    OrderModel(
      id: 'ORD-006',
      moduleType: 'ride',
      moduleName: 'City Ride',
      status: 'cancelled',
      total: 12.00,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];
}
