import '/pro/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';
import '../widgets/shop_module_bottom_nav.dart';
import 'shop_product_create_screen.dart';
import 'shop_store_setup_screen.dart';

class ShopProductsScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final List<ProModule> activeModules;
  final String initialModule;

  const ShopProductsScreen({
    super.key,
    required this.userId,
    required this.businessName,
    this.activeModules = const [],
    this.initialModule = 'shopping',
  });

  @override
  State<ShopProductsScreen> createState() => _ShopProductsScreenState();
}

class _ShopProductsScreenState extends State<ShopProductsScreen> {
  late Future<Map<String, dynamic>> _productsFuture;
  final Set<String> _busyIds = <String>{};
  String _selectedStoreId = 'all';
  String _selectedStockFilter = 'all';
  String _searchQuery = '';
  late final List<String> _allowedModules = _resolveAllowedModules();
  late String _selectedModule = _normalizeSelectedModule(widget.initialModule);

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _productsFuture = _loadProducts();
  }

  List<String> _resolveAllowedModules() {
    final modules = <String>[];
    for (final module in widget.activeModules) {
      switch (module) {
        case ProModule.shopping:
          modules.add('shopping');
          break;
        case ProModule.pharmacy:
          modules.add('pharmacy');
          break;
        default:
          break;
      }
    }
    if (modules.isEmpty) {
      return const ['shopping'];
    }
    return modules.toSet().toList(growable: false);
  }

  String _normalizeSelectedModule(String requested) {
    if (_allowedModules.contains(requested)) {
      return requested;
    }
    return _allowedModules.first;
  }

  Color _moduleColor(String module) {
    return module == 'pharmacy' ? AppColors.pharmacy : AppColors.shopping;
  }

  String _moduleLabel(String module) {
    return module == 'pharmacy' ? l10n.pharmacyLabel : l10n.shoppingLabel;
  }

  bool get _isPharmacyModule => _selectedModule == 'pharmacy';

  Future<Map<String, dynamic>> _loadProducts() async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/shopping-products?module=$_selectedModule',
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
        {'module': _selectedModule, 'inStock': inStock},
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
      final message = _isPharmacyModule
          ? l10n.connectPharmacyMessage
          : l10n.createStoreFirstMessage;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopProductCreateScreen(
          userId: widget.userId,
          stores: stores,
          module: _selectedModule,
        ),
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
    await context.push('${ProRoutePaths.shopQueue}?module=$_selectedModule');
    if (!mounted) return;
    await _refresh();
  }

  bool _matchesStockFilter(bool inStock) {
    switch (_selectedStockFilter) {
      case 'in_stock':
        return inStock;
      case 'out_of_stock':
        return !inStock;
      default:
        return true;
    }
  }

  bool _matchesSearch(Map<String, dynamic> product) {
    if (_searchQuery.trim().isEmpty) return true;
    final query = _searchQuery.trim().toLowerCase();
    final haystack = [
      product['name']?.toString() ?? '',
      product['storeName']?.toString() ?? '',
      product['categoryName']?.toString() ?? '',
      product['unit']?.toString() ?? '',
      product['badge']?.toString() ?? '',
      product['description']?.toString() ?? '',
      product['dosage']?.toString() ?? '',
      product['packageSize']?.toString() ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  String _formatPrice(dynamic value) {
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) return '';
    return '\$${parsed.toStringAsFixed(2)}';
  }

  void _changeModule(String module) {
    if (_selectedModule == module) return;
    setState(() {
      _selectedModule = module;
      _selectedStoreId = 'all';
      _selectedStockFilter = 'all';
      _searchQuery = '';
      _productsFuture = _loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final moduleColor = _moduleColor(_selectedModule);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isPharmacyModule
              ? l10n.shopQueueTitle(l10n.medicinesLabel)
              : l10n.shopQueueTitle(l10n.productsLabel),
        ),
        backgroundColor: moduleColor,
        foregroundColor: Colors.white,
      ),
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

          final inStockCount = products
              .where((p) => p['inStock'] == true)
              .length;
          final outOfStockCount = products.length - inStockCount;

          final filteredProducts = products
              .where((product) {
                if (selectedStoreId != 'all' &&
                    product['storeId']?.toString() != selectedStoreId) {
                  return false;
                }
                final inStock = product['inStock'] as bool? ?? false;
                if (!_matchesStockFilter(inStock)) return false;
                return _matchesSearch(product);
              })
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_allowedModules.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allowedModules
                          .map(
                            (module) => ChoiceChip(
                              label: Text(
                                _moduleLabel(module),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _selectedModule == module
                                      ? _moduleColor(module)
                                      : Colors.black87,
                                ),
                              ),
                              selected: _selectedModule == module,
                              selectedColor: _moduleColor(
                                module,
                              ).withValues(alpha: 0.16),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: _selectedModule == module
                                    ? _moduleColor(module)
                                    : Colors.black26,
                              ),
                              showCheckmark: false,
                              onSelected: (_) => _changeModule(module),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: moduleColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _QueueMetric(
                        label: _isPharmacyModule
                            ? l10n.medicinesLabel
                            : l10n.productsLabel,
                        value: '${products.length}',
                      ),
                      const SizedBox(width: 8),
                      _QueueMetric(label: l10n.inStock, value: '$inStockCount'),
                      const SizedBox(width: 8),
                      _QueueMetric(
                        label: l10n.outLabel,
                        value: '$outOfStockCount',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openCreateProduct(
                          stores
                              .map(
                                (store) => {
                                  'id': store['id']?.toString(),
                                  'name':
                                      store['name']?.toString() ??
                                      (_isPharmacyModule
                                          ? 'Pharmacy'
                                          : 'Store'),
                                },
                              )
                              .toList(growable: false),
                        ),
                        icon: const Icon(Icons.add_box_outlined),
                        label: Text(
                          _isPharmacyModule
                              ? l10n.addMedicine
                              : l10n.addProduct,
                        ),
                      ),
                    ),
                    if (!_isPharmacyModule) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openStoreSetup(
                            stores.isEmpty ? null : stores.first,
                          ),
                          icon: const Icon(Icons.store_mall_directory_outlined),
                          label: Text(
                            stores.isEmpty ? l10n.createStore : l10n.storeSetup,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(
                          _isPharmacyModule
                              ? l10n.allPharmaciesCount(products.length)
                              : l10n.allStoresCount(products.length),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selectedStoreId == 'all'
                                ? moduleColor
                                : Colors.black87,
                          ),
                        ),
                        selected: selectedStoreId == 'all',
                        selectedColor: moduleColor.withValues(alpha: 0.16),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selectedStoreId == 'all'
                              ? moduleColor
                              : Colors.black26,
                        ),
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _selectedStoreId = 'all'),
                      ),
                      ...stores.map((store) {
                        final id = store['id']?.toString() ?? '';
                        final selected = selectedStoreId == id;
                        return ChoiceChip(
                          label: Text(
                            _isPharmacyModule
                                ? l10n.pharmacyCountLabel(
                                    store['name']?.toString() ??
                                        l10n.pharmacyLabel,
                                    store['productCount']?.toString() ?? '0',
                                  )
                                : l10n.storeCountLabel(
                                    store['name']?.toString() ??
                                        l10n.storeLabel,
                                    store['productCount']?.toString() ?? '0',
                                  ),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected ? moduleColor : Colors.black87,
                            ),
                          ),
                          selected: selected,
                          selectedColor: moduleColor.withValues(alpha: 0.16),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: selected ? moduleColor : Colors.black26,
                          ),
                          showCheckmark: false,
                          onSelected: (_) => setState(
                            () => _selectedStoreId = id.isEmpty ? 'all' : id,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in ['all', 'in_stock', 'out_of_stock'])
                        ChoiceChip(
                          label: Text(
                            switch (status) {
                              'in_stock' => l10n.inStock,
                              'out_of_stock' => l10n.outOfStock,
                              _ => l10n.allStatus,
                            },
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _selectedStockFilter == status
                                  ? moduleColor
                                  : Colors.black87,
                            ),
                          ),
                          selected: _selectedStockFilter == status,
                          selectedColor: moduleColor.withValues(alpha: 0.16),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: _selectedStockFilter == status
                                ? moduleColor
                                : Colors.black26,
                          ),
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _selectedStockFilter = status),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: _isPharmacyModule
                        ? l10n.searchMedicinesHint
                        : l10n.searchProductsHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 16),
                if (snapshot.connectionState == ConnectionState.waiting)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.white,
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 34),
                        const SizedBox(height: 10),
                        const CircularProgressIndicator(),
                        const SizedBox(height: 10),
                        Text(l10n.loadingProducts),
                      ],
                    ),
                  )
                else if (filteredProducts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        l10n.noProductsMatch,
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
        onProducts: () {},
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final id = product['id']?.toString() ?? '';
    final inStock = product['inStock'] as bool? ?? false;
    final isBusy = _busyIds.contains(id);
    final imageUrl = product['imageUrl']?.toString() ?? '';
    final price = _formatPrice(product['price']);
    final originalPrice = _formatPrice(product['originalPrice']);
    final unit = product['unit']?.toString() ?? '';
    final badge = product['badge']?.toString() ?? '';
    final storeName = product['storeName']?.toString() ?? 'Store';
    final categoryName = product['categoryName']?.toString() ?? 'General';
    final dosage = product['dosage']?.toString().trim() ?? '';
    final packageSize = product['packageSize']?.toString().trim() ?? '';
    final needsPrescription = product['requiresPrescription'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          if (price.isNotEmpty) Text(price),
                          if (originalPrice.isNotEmpty)
                            Text(l10n.wasOriginalPrice(originalPrice)),
                          if (unit.isNotEmpty) Text(unit),
                          if (badge.isNotEmpty) Text(badge),
                        ],
                      ),
                      if (_isPharmacyModule &&
                          (dosage.isNotEmpty ||
                              packageSize.isNotEmpty ||
                              needsPrescription)) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (dosage.isNotEmpty) _TagPill(text: dosage),
                            if (packageSize.isNotEmpty)
                              _TagPill(text: packageSize),
                            if (needsPrescription)
                              _TagPill(
                                text: l10n.prescriptionRequired,
                                color: AppColors.pharmacy,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  inStock ? l10n.inStock : l10n.outOfStock,
                  style: TextStyle(
                    color: inStock
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: inStock,
                  onChanged: isBusy
                      ? null
                      : (value) => _toggleStock(productId: id, inStock: value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueMetric extends StatelessWidget {
  final String label;
  final String value;

  const _QueueMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String text;
  final Color color;

  const _TagPill({required this.text, this.color = Colors.black87});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
