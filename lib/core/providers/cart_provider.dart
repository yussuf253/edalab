import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/cart_model.dart';
import '../network/api_client.dart';
import '../storage/app_preferences.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _promoCode;
  double _promoDiscount = 0;
  bool _isHydrating = true;
  Future<void>? _hydrateFuture;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;
  bool get isHydrating => _isHydrating;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get deliveryFee => subtotal > 50 ? 0 : 5.99;
  double get tax => subtotal * 0.08;
  double get discount => _promoDiscount;
  double get total => subtotal + deliveryFee + tax - _promoDiscount;
  String? get promoCode => _promoCode;

  Future<void> initialize() async {
    await refreshFromStorage();
  }

  Future<void> refreshFromStorage() {
    if (_hydrateFuture != null) {
      return _hydrateFuture!;
    }

    _isHydrating = true;
    notifyListeners();

    final future = _loadFromStorage();
    _hydrateFuture = future;
    future.whenComplete(() => _hydrateFuture = null);
    return future;
  }

  Future<void> _loadFromStorage() async {
    final startedAt = DateTime.now();
    try {
      final rawItems = await AppPreferences.getCartItemsJson();
      final rawPromoCode = await AppPreferences.getCartPromoCode();
      final rawPromoDiscount = await AppPreferences.getCartPromoDiscount();

      if (rawItems != null && rawItems.isNotEmpty) {
        final decoded = json.decode(rawItems);
        if (decoded is List) {
          _items
            ..clear()
            ..addAll(
              decoded.map(
                (item) =>
                    CartItem.fromJson(Map<String, dynamic>.from(item as Map)),
              ),
            );
        }
      }

      _promoCode = rawPromoCode;
      _promoDiscount = rawPromoDiscount;
    } catch (_) {
      _items.clear();
      _promoCode = null;
      _promoDiscount = 0;
    } finally {
      final elapsed = DateTime.now().difference(startedAt);
      const minimumHydration = Duration(milliseconds: 350);
      if (elapsed < minimumHydration) {
        await Future<void>.delayed(minimumHydration - elapsed);
      }
      _isHydrating = false;
      notifyListeners();
    }
  }

  // Get items from a specific module
  List<CartItem> getModuleItems(String moduleType) {
    return _items.where((item) => item.moduleType == moduleType).toList();
  }

  int getModuleItemCount(String moduleType) {
    return getModuleItems(
      moduleType,
    ).fold(0, (sum, item) => sum + item.quantity);
  }

  double getModuleSubtotal(String moduleType) {
    return getModuleItems(moduleType).fold(0, (sum, item) => sum + item.total);
  }

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere(
      (i) => i.id == item.id && i.moduleType == item.moduleType,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    _persistCart();
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _persistCart();
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _persistCart();
      notifyListeners();
    }
  }

  void incrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity++;
      _persistCart();
      notifyListeners();
    }
  }

  void decrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      if (_items[index].quantity <= 1) {
        _items.removeAt(index);
      } else {
        _items[index].quantity--;
      }
      _persistCart();
      notifyListeners();
    }
  }

  void applyPromo(String code) {
    // Simulated promo codes
    final promos = {
      'FIRST50': 0.50,
      'SAVE20': 0.20,
      'FRESH30': 0.30,
      'WELCOME': 0.15,
    };

    if (promos.containsKey(code.toUpperCase())) {
      _promoCode = code.toUpperCase();
      _promoDiscount = subtotal * promos[_promoCode]!;
      _persistCart();
      notifyListeners();
    }
  }

  void removePromo() {
    _promoCode = null;
    _promoDiscount = 0;
    _persistCart();
    notifyListeners();
  }

  void clearModuleCart(String moduleType) {
    _items.removeWhere((item) => item.moduleType == moduleType);
    _persistCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _promoCode = null;
    _promoDiscount = 0;
    _persistCart();
    notifyListeners();
  }

  Future<String?> submitModuleOrder(
    String userId,
    String moduleType, {
    Map<String, dynamic>? orderMetadata,
  }) async {
    final moduleItems = getModuleItems(moduleType);
    if (moduleItems.isEmpty) return null;

    final sub = getModuleSubtotal(moduleType);
    final modTax = sub * 0.08;
    final modTotal = sub + modTax;
    final normalizedModuleType = moduleType.toLowerCase();
    final supportsCatalogProduct = {
      'shopping',
      'pharmacy',
      'grocery',
    }.contains(normalizedModuleType);

    final itemsJson = moduleItems
        .map((item) {
          final itemMetadata = <String, dynamic>{
            ...?orderMetadata,
            'itemName': item.name,
            'itemImageUrl': item.imageUrl,
            'itemDescription': item.description,
            'shopId': item.shopId,
            'shopName': item.shopName,
          }..removeWhere((_, value) {
              if (value == null) return true;
              if (value is String && value.trim().isEmpty) return true;
              return false;
            });

          final effectiveBrand =
              (item.brand != null && item.brand!.trim().isNotEmpty)
              ? item.brand
              : item.shopName;

          return {
            'id': item.id,
            if (supportsCatalogProduct) 'productId': item.id,
            'name': item.name,
            'brand': effectiveBrand,
            'price': item.price,
            'quantity': item.quantity,
            'total': item.total,
            'color': item.color,
            'size': item.size,
            'metadata': itemMetadata,
          };
        })
        .toList();

    try {
      final response = await ApiClient.post('/orders', {
        'userId': userId,
        'moduleType': moduleType.toUpperCase(),
        'subtotal': sub,
        'tax': modTax,
        'deliveryFee': 0,
        'total': modTotal,
        'items': itemsJson,
      });

      clearModuleCart(moduleType);
      return response is Map ? response['id']?.toString() : null;
    } catch (e) {
      debugPrint('Failed to submit order: $e');
      return null;
    }
  }

  Future<void> _persistCart() async {
    final itemsJson = json.encode(_items.map((item) => item.toJson()).toList());
    await AppPreferences.setCartItemsJson(itemsJson);
    await AppPreferences.setCartPromoCode(_promoCode);
    await AppPreferences.setCartPromoDiscount(_promoDiscount);
    if (_items.isEmpty &&
        (_promoCode == null || _promoCode!.isEmpty) &&
        _promoDiscount == 0) {
      await AppPreferences.clearCartState();
    }
  }
}
