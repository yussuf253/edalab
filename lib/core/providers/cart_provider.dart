import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../network/api_client.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? _promoCode;
  double _promoDiscount = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get deliveryFee => subtotal > 50 ? 0 : 5.99;
  double get tax => subtotal * 0.08;
  double get discount => _promoDiscount;
  double get total => subtotal + deliveryFee + tax - _promoDiscount;
  String? get promoCode => _promoCode;

  // Get items from a specific module
  List<CartItem> getModuleItems(String moduleType) {
    return _items.where((item) => item.moduleType == moduleType).toList();
  }

  int getModuleItemCount(String moduleType) {
    return getModuleItems(moduleType).fold(0, (sum, item) => sum + item.quantity);
  }

  double getModuleSubtotal(String moduleType) {
    return getModuleItems(moduleType).fold(0, (sum, item) => sum + item.total);
  }

  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id && i.moduleType == item.moduleType);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
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
      notifyListeners();
    }
  }

  void incrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity++;
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
      notifyListeners();
    }
  }

  void removePromo() {
    _promoCode = null;
    _promoDiscount = 0;
    notifyListeners();
  }

  void clearModuleCart(String moduleType) {
    _items.removeWhere((item) => item.moduleType == moduleType);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _promoCode = null;
    _promoDiscount = 0;
    notifyListeners();
  }

  Future<bool> submitModuleOrder(String userId, String moduleType) async {
    final moduleItems = getModuleItems(moduleType);
    if (moduleItems.isEmpty) return false;

    final sub = getModuleSubtotal(moduleType);
    final modTax = sub * 0.08;
    final modTotal = sub + modTax;

    final itemsJson = moduleItems.map((item) => {
      'id': item.id,
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'total': item.total,
    }).toList();

    try {
      await ApiClient.post('/orders', {
        'userId': userId,
        'moduleType': moduleType.toUpperCase(),
        'subtotal': sub,
        'tax': modTax,
        'deliveryFee': 0,
        'total': modTotal,
        'items': itemsJson,
      });

      clearModuleCart(moduleType);
      return true;
    } catch (e) {
      print('Failed to submit order: $e');
      return false;
    }
  }
}
