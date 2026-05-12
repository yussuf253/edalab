import 'package:flutter/material.dart';
import 'dart:convert';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../models/cart_model.dart';
import '../modules/module_access_service.dart';
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

  Map<String, Object?> _cartSnapshot({String? moduleType}) {
    final scopedItems = moduleType == null
        ? _items
        : getModuleItems(moduleType);
    final scopedSubtotal = moduleType == null
        ? subtotal
        : getModuleSubtotal(moduleType);
    return {
      'module_type': moduleType ?? 'all',
      'item_count': scopedItems.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      ),
      'line_count': scopedItems.length,
      'subtotal': scopedSubtotal,
      'has_promo': (_promoCode?.isNotEmpty ?? false),
    };
  }

  String _safeError(Object error) {
    final message = ApiClient.userFacingError(error).trim();
    if (message.isEmpty) return 'unknown';
    return message.length > 120 ? '${message.substring(0, 120)}...' : message;
  }

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
      AnalyticsService.instance.track(
        AnalyticsEvents.cartHydrated,
        properties: _cartSnapshot(),
      );
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
    if (!ModuleAccessService.instance.isEnabled(item.moduleType)) {
      return;
    }

    final existingIndex = _items.indexWhere(
      (i) => i.id == item.id && i.moduleType == item.moduleType,
    );
    final wasExisting = existingIndex >= 0;
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    _persistCart();
    AnalyticsService.instance.track(
      AnalyticsEvents.cartItemAdded,
      properties: {
        'item_id': item.id,
        'module_type': item.moduleType,
        'quantity': item.quantity,
        'unit_price': item.price,
        'merged_existing_line': wasExisting,
        ..._cartSnapshot(moduleType: item.moduleType),
      },
    );
    notifyListeners();
  }

  void removeItem(String id) {
    final removedItems = _items.where((item) => item.id == id).toList();
    _items.removeWhere((item) => item.id == id);
    _persistCart();
    final removedQuantity = removedItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    if (removedQuantity > 0) {
      AnalyticsService.instance.track(
        AnalyticsEvents.cartItemRemoved,
        properties: {
          'item_id': id,
          'removed_quantity': removedQuantity,
          ..._cartSnapshot(),
        },
      );
    }
    notifyListeners();
  }

  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final previousQuantity = _items[index].quantity;
      final moduleType = _items[index].moduleType;
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _persistCart();
      AnalyticsService.instance.track(
        AnalyticsEvents.cartItemQuantityChanged,
        properties: {
          'item_id': id,
          'module_type': moduleType,
          'previous_quantity': previousQuantity,
          'next_quantity': quantity <= 0 ? 0 : quantity,
          ..._cartSnapshot(moduleType: moduleType),
        },
      );
      notifyListeners();
    }
  }

  void incrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final previousQuantity = _items[index].quantity;
      final moduleType = _items[index].moduleType;
      _items[index].quantity++;
      _persistCart();
      AnalyticsService.instance.track(
        AnalyticsEvents.cartItemQuantityChanged,
        properties: {
          'item_id': id,
          'module_type': moduleType,
          'previous_quantity': previousQuantity,
          'next_quantity': _items[index].quantity,
          ..._cartSnapshot(moduleType: moduleType),
        },
      );
      notifyListeners();
    }
  }

  void decrementQuantity(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      final previousQuantity = _items[index].quantity;
      final moduleType = _items[index].moduleType;
      if (_items[index].quantity <= 1) {
        _items.removeAt(index);
      } else {
        _items[index].quantity--;
      }
      _persistCart();
      AnalyticsService.instance.track(
        AnalyticsEvents.cartItemQuantityChanged,
        properties: {
          'item_id': id,
          'module_type': moduleType,
          'previous_quantity': previousQuantity,
          'next_quantity': previousQuantity <= 1 ? 0 : previousQuantity - 1,
          ..._cartSnapshot(moduleType: moduleType),
        },
      );
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
      AnalyticsService.instance.track(
        AnalyticsEvents.cartPromoApplied,
        properties: {
          'promo_code': _promoCode,
          'discount_value': _promoDiscount,
          ..._cartSnapshot(),
        },
      );
      notifyListeners();
      return;
    }

    AnalyticsService.instance.track(
      AnalyticsEvents.cartPromoRejected,
      properties: {'promo_code': code.toUpperCase(), ..._cartSnapshot()},
    );
  }

  void removePromo() {
    final removedCode = _promoCode;
    final removedDiscount = _promoDiscount;
    _promoCode = null;
    _promoDiscount = 0;
    _persistCart();
    if (removedCode != null) {
      AnalyticsService.instance.track(
        AnalyticsEvents.cartPromoRemoved,
        properties: {
          'promo_code': removedCode,
          'discount_value': removedDiscount,
          ..._cartSnapshot(),
        },
      );
    }
    notifyListeners();
  }

  void clearModuleCart(String moduleType) {
    final removedItems = getModuleItems(moduleType);
    _items.removeWhere((item) => item.moduleType == moduleType);
    _persistCart();
    AnalyticsService.instance.track(
      AnalyticsEvents.cartModuleCleared,
      properties: {
        'module_type': moduleType,
        'removed_line_count': removedItems.length,
        'removed_item_count': removedItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ),
        ..._cartSnapshot(moduleType: moduleType),
      },
    );
    notifyListeners();
  }

  void clearCart() {
    final removedLineCount = _items.length;
    final removedItemCount = itemCount;
    _items.clear();
    _promoCode = null;
    _promoDiscount = 0;
    _persistCart();
    AnalyticsService.instance.track(
      AnalyticsEvents.cartCleared,
      properties: {
        'removed_line_count': removedLineCount,
        'removed_item_count': removedItemCount,
      },
    );
    notifyListeners();
  }

  Future<String?> submitModuleOrder(
    String userId,
    String moduleType, {
    Map<String, dynamic>? orderMetadata,
    bool deferNotifications = false,
  }) async {
    final moduleItems = getModuleItems(moduleType);
    if (moduleItems.isEmpty) return null;
    if (!ModuleAccessService.instance.isEnabled(moduleType)) return null;

    final sub = getModuleSubtotal(moduleType);
    final modTax = sub * 0.08;
    final modTotal = sub + modTax;
    final normalizedModuleType = moduleType.toLowerCase();
    final supportsCatalogProduct = {
      'shopping',
      'pharmacy',
      'grocery',
    }.contains(normalizedModuleType);

    final itemsJson = moduleItems.map((item) {
      final itemMetadata =
          <String, dynamic>{
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
    }).toList();

    AnalyticsService.instance.track(
      AnalyticsEvents.orderSubmitAttempted,
      properties: {
        'module_type': normalizedModuleType,
        'line_count': moduleItems.length,
        'item_count': moduleItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        ),
        'subtotal': sub,
        'total': modTotal,
      },
    );

    try {
      final response = await ApiClient.post('/orders', {
        'userId': userId,
        'moduleType': moduleType.toUpperCase(),
        'subtotal': sub,
        'tax': modTax,
        'deliveryFee': 0,
        'total': modTotal,
        'deferNotifications': deferNotifications,
        'items': itemsJson,
      });

      clearModuleCart(moduleType);
      final orderId = response is Map ? response['id']?.toString() : null;
      AnalyticsService.instance.track(
        AnalyticsEvents.orderSubmitSucceeded,
        properties: {
          'module_type': normalizedModuleType,
          'line_count': moduleItems.length,
          'item_count': moduleItems.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          ),
          'subtotal': sub,
          'total': modTotal,
          'order_id': orderId,
        },
      );
      return orderId;
    } catch (e) {
      debugPrint('Failed to submit order: $e');
      AnalyticsService.instance.track(
        AnalyticsEvents.orderSubmitFailed,
        properties: {
          'module_type': normalizedModuleType,
          'line_count': moduleItems.length,
          'item_count': moduleItems.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          ),
          'subtotal': sub,
          'total': modTotal,
          'error': _safeError(e),
        },
      );
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
