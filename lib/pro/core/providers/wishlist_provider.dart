import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../network/api_client.dart';

class WishlistProvider extends ChangeNotifier {
  final List<ProductModel> _items = [];
  final Set<String> _foodFavoriteIds = <String>{};
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
      _foodFavoriteIds.clear();
      notifyListeners();
      return;
    }

    try {
      final response = await ApiClient.get('/users/$userId/wishlist');
      final entries = (response as List)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
      final items = entries
          .where(
            (entry) =>
                entry['moduleType'].toString().toUpperCase() == 'SHOPPING',
          )
          .map((item) {
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
      final foodIds = entries
          .where(
            (entry) => entry['moduleType'].toString().toUpperCase() == 'FOOD',
          )
          .map((entry) => entry['entityId']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      _items
        ..clear()
        ..addAll(items);
      _foodFavoriteIds
        ..clear()
        ..addAll(foodIds);
      notifyListeners();
    } catch (_) {
      _items.clear();
      _foodFavoriteIds.clear();
      notifyListeners();
    }
  }

  bool isFavorite(String productId) {
    return _items.any((item) => item.id == productId);
  }

  bool isFoodFavorite(String itemId) {
    return _foodFavoriteIds.contains(itemId);
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
            'imageUrl': product.images.isNotEmpty ? product.images.first : '',
          });
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  Future<void> toggleFoodFavorite({
    required String itemId,
    required String title,
    required String subtitle,
    required double price,
    String? imageUrl,
  }) async {
    if (_foodFavoriteIds.contains(itemId)) {
      _foodFavoriteIds.remove(itemId);
      if (_userId != null && _userId!.isNotEmpty) {
        try {
          await ApiClient.delete(
            '/users/${_userId!}/wishlist/$itemId?moduleType=food',
          );
        } catch (_) {}
      }
    } else {
      _foodFavoriteIds.add(itemId);
      if (_userId != null && _userId!.isNotEmpty) {
        try {
          await ApiClient.post('/users/${_userId!}/wishlist', {
            'moduleType': 'FOOD',
            'entityId': itemId,
            'title': title,
            'subtitle': subtitle,
            'price': price,
            'imageUrl': imageUrl ?? '',
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
    _foodFavoriteIds.clear();
    notifyListeners();
  }
}
