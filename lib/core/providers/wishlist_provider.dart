import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../network/api_client.dart';

class WishlistProvider extends ChangeNotifier {
  final List<ProductModel> _items = [];
  String? _userId;

  List<ProductModel> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  Future<void> syncAuth(String? userId) async {
    if (_userId == userId) {
      return;
    }

    _userId = userId;
    if (userId == null || userId.isEmpty) {
      _items.clear();
      notifyListeners();
      return;
    }

    try {
      final response = await ApiClient.get('/users/$userId/wishlist');
      final items = (response as List)
          .where(
            (entry) =>
                Map<String, dynamic>.from(
                  entry as Map,
                )['moduleType'].toString().toUpperCase() ==
                'SHOPPING',
          )
          .map((entry) {
            final item = Map<String, dynamic>.from(entry as Map);
            return ProductModel(
              id: item['entityId']?.toString() ?? '',
              name: item['title']?.toString() ?? '',
              brand: item['subtitle']?.toString() ?? '',
              description: '',
              price: (item['price'] as num?)?.toDouble() ?? 0,
              rating: 0,
              reviewCount: 0,
              category: 'Wishlist',
            );
          })
          .toList();
      _items
        ..clear()
        ..addAll(items);
      notifyListeners();
    } catch (_) {
      _items.clear();
      notifyListeners();
    }
  }

  bool isFavorite(String productId) {
    return _items.any((item) => item.id == productId);
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final index = _items.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _items.removeAt(index);
      if (_userId != null && _userId!.isNotEmpty) {
        try {
          await ApiClient.delete(
            '/users/${_userId!}/wishlist/${product.id}?moduleType=shopping',
          );
        } catch (_) {}
      }
    } else {
      _items.add(product);
      if (_userId != null && _userId!.isNotEmpty) {
        try {
          await ApiClient.post('/users/${_userId!}/wishlist', {
            'moduleType': 'SHOPPING',
            'entityId': product.id,
            'title': product.name,
            'subtitle': product.brand,
            'price': product.price,
            'imageUrl': product.images.isNotEmpty ? product.images.first : null,
          });
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.id == productId);
    if (_userId != null && _userId!.isNotEmpty) {
      try {
        await ApiClient.delete(
          '/users/${_userId!}/wishlist/$productId?moduleType=shopping',
        );
      } catch (_) {}
    }
    notifyListeners();
  }

  void clearWishlist() {
    _items.clear();
    notifyListeners();
  }
}
