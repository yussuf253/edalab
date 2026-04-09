import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../core/router/pro_route_paths.dart';
import '../widgets/shop_module_bottom_nav.dart';
import 'shop_product_create_screen.dart';
import 'shop_store_setup_screen.dart';

class ShopProductsScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const ShopProductsScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends State<ShopProductsScreen> {
  late Future<Map<String, dynamic>> _productsFuture;
  final Set<String> _busyIds = <String>{};
  String _selectedStoreId = 'all';

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  Future<Map<String, dynamic>> _loadProducts() async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/shopping-products',
      forceRefresh: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> _refresh() async {
    final future = _loadProducts();
    setState(() => _productsFuture = future);
    await future;
  }

  Future<void> _toggleStock({
    required String productId,
    required bool inStock,
  }) async {
    setState(() => _busyIds.add(productId));
    try {
      await ApiClient.patch(
        '/pro/${widget.userId}/shopping-products/$productId',
        {'inStock': inStock},
      );
      if (!mounted) return;
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(productId));
      }
    }
  }

  Future<void> _openCreateProduct(List<Map<String, dynamic>> stores) async {
    if (stores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a store first before adding products.'),
        ),
      );
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ShopProductCreateScreen(userId: widget.userId, stores: stores),
      ),
    );
    if (created != true || !mounted) return;
    await _refresh();
  }

  Future<void> _openStoreSetup(Map<String, dynamic>? store) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopStoreSetupScreen(
          userId: widget.userId,
          businessName: widget.businessName,
          initialStore: store,
        ),
      ),
    );
    if (updated != true || !mounted) return;
    await _refresh();
  }

  Future<void> _openOrders() async {
    await context.push('${ProRoutePaths.shopQueue}?module=shopping');
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openStorefront() async {
    await context.push(ProRoutePaths.shopCatalog);
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.businessName} Products')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            );
          }

          final data = snapshot.data ?? const <String, dynamic>{};
          final stores = (data['stores'] as List<dynamic>? ?? const [])
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList(growable: false);
          final products = (data['products'] as List<dynamic>? ?? const [])
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList(growable: false);
          final selectedStoreId =
              stores.any((store) => store['id']?.toString() == _selectedStoreId)
              ? _selectedStoreId
              : 'all';
          final filteredProducts = selectedStoreId == 'all'
              ? products
              : products
                    .where(
                      (product) =>
                          product['storeId']?.toString() == selectedStoreId,
                    )
                    .toList(growable: false);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openCreateProduct(
                          stores
                              .map(
                                (store) => {
                                  'id': store['id']?.toString(),
                                  'name': store['name']?.toString() ?? 'Store',
                                },
                              )
                              .toList(growable: false),
                        ),
                        icon: const Icon(Icons.add_box_outlined),
                        label: const Text('Add Product'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openStoreSetup(
                          stores.isEmpty ? null : stores.first,
                        ),
                        icon: const Icon(Icons.storefront_outlined),
                        label: Text(
                          stores.isEmpty ? 'Create Store' : 'Store Setup',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('All Stores (${products.length})'),
                      selected: selectedStoreId == 'all',
                      onSelected: (_) =>
                          setState(() => _selectedStoreId = 'all'),
                    ),
                    ...stores.map(
                      (store) => ChoiceChip(
                        label: Text(
                          '${store['name']?.toString() ?? 'Store'} (${store['productCount']?.toString() ?? '0'})',
                        ),
                        selected: selectedStoreId == store['id']?.toString(),
                        onSelected: (_) => setState(
                          () => _selectedStoreId =
                              store['id']?.toString() ?? 'all',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filteredProducts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No products found for this selection yet.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...filteredProducts.map(_buildProductCard),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: ShopModuleBottomNav(
        activeTab: ShopModuleBottomTab.products,
        onOrders: _openOrders,
        onStorefront: _openStorefront,
        onProducts: () {},
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = product['id']?.toString() ?? '';
    final inStock = product['inStock'] as bool? ?? false;
    final isBusy = _busyIds.contains(id);
    final imageUrl = product['imageUrl']?.toString() ?? '';
    final price = product['price']?.toString() ?? '';
    final originalPrice = product['originalPrice']?.toString() ?? '';
    final unit = product['unit']?.toString() ?? '';
    final badge = product['badge']?.toString() ?? '';
    final storeName = product['storeName']?.toString() ?? 'Store';
    final categoryName = product['categoryName']?.toString() ?? 'General';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.inventory_2_outlined)
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name']?.toString() ?? 'Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$storeName • $categoryName'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (price.isNotEmpty) Text('\$$price'),
                      if (originalPrice.isNotEmpty)
                        Text('was \$$originalPrice'),
                      if (unit.isNotEmpty) Text(unit),
                      if (badge.isNotEmpty) Text(badge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    inStock ? 'In stock' : 'Out of stock',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: inStock
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: inStock,
              onChanged: isBusy
                  ? null
                  : (value) => _toggleStock(productId: id, inStock: value),
            ),
          ],
        ),
      ),
    );
  }
}
