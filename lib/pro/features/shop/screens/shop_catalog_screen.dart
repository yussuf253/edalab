import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../widgets/shop_module_bottom_nav.dart';
import 'shop_product_create_screen.dart';
import 'shop_store_setup_screen.dart';

class ShopCatalogScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final List<ProModule> modules;

  const ShopCatalogScreen({
    super.key,
    required this.userId,
    required this.businessName,
    required this.modules,
  });

  @override
  State<ShopCatalogScreen> createState() => _ShopCatalogScreenState();
}

class _ShopCatalogScreenState extends State<ShopCatalogScreen> {
  late Future<Map<String, dynamic>> _storefrontFuture;
  final Set<String> _busyIds = <String>{};
  final Map<ProModule, String> _searchByModule = <ProModule, String>{};
  ProModule? _selectedModule;

  @override
  void initState() {
    super.initState();
    _storefrontFuture = _loadStorefront();
  }

  Future<Map<String, dynamic>> _loadStorefront() async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/shop-availability',
      forceRefresh: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> _refresh() async {
    final future = _loadStorefront();
    setState(() {
      _storefrontFuture = future;
    });
    await future;
  }

  Future<void> _toggleAvailability({
    required String module,
    required String targetId,
    required bool enabled,
  }) async {
    setState(() => _busyIds.add(targetId));
    try {
      await ApiClient.post('/pro/${widget.userId}/shop-availability', {
        'module': module,
        'targetId': targetId,
        'enabled': enabled,
      });
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
        setState(() => _busyIds.remove(targetId));
      }
    }
  }

  Future<void> _openShoppingStoreSetupScreen({
    required Map<String, dynamic>? existingStore,
  }) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopStoreSetupScreen(
          userId: widget.userId,
          businessName: widget.businessName,
          initialStore: existingStore,
        ),
      ),
    );
    if (updated != true || !mounted) return;
    await _refresh();
  }

  Future<void> _openCreateShoppingProductScreen(
    List<Map<String, dynamic>> shoppingStores,
  ) async {
    if (shoppingStores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a store first before adding products.'),
        ),
      );
      return;
    }

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopProductCreateScreen(
          userId: widget.userId,
          stores: shoppingStores,
        ),
      ),
    );
    if (created != true || !mounted) return;
    await _refresh();
  }

  Future<void> _openQueue({String? module}) async {
    final path = module == null || module.isEmpty
        ? ProRoutePaths.shopQueue
        : '${ProRoutePaths.shopQueue}?module=$module';
    await context.push(path);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openProductsManager({String? module}) async {
    final path = module == null || module.isEmpty
        ? ProRoutePaths.shopProducts
        : '${ProRoutePaths.shopProducts}?module=$module';
    await context.push(path);
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _createRestaurant() async {
    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/pro/${widget.userId}/restaurant', {
              'name': widget.businessName,
            })
            as Map,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (response['created'] as bool? ?? false)
                ? 'Restaurant created and connected to your profile.'
                : 'Existing restaurant connected to your profile.',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _createPharmacyBusiness() async {
    try {
      await ApiClient.post('/pro/${widget.userId}/pharmacy-business', {
        'name': widget.businessName,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pharmacy business connected to your profile.'),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _shoppingStoresFromData(
    Map<String, dynamic> data,
  ) {
    return (data['shopping'] as List<dynamic>? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  Map<String, dynamic>? _primaryShoppingStore(Map<String, dynamic> data) {
    final stores = _shoppingStoresFromData(data);
    return stores.isEmpty ? null : stores.first;
  }

  int _ordersInProgressFromSummary(Map<String, dynamic> summary) {
    final metrics = (summary['metrics'] as List<dynamic>? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
    for (final metric in metrics) {
      final label = metric['label']?.toString().toLowerCase() ?? '';
      if (!label.contains('orders in progress')) continue;
      final value = metric['value']?.toString() ?? '0';
      final match = RegExp(r'\d+').firstMatch(value);
      return int.tryParse(match?.group(0) ?? '') ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final storeModules = widget.modules
        .where(
          (module) => {
            ProModule.shopping,
            ProModule.food,
            ProModule.pharmacy,
          }.contains(module),
        )
        .toList(growable: false);
    final modules = storeModules.isEmpty ? [ProModule.shopping] : storeModules;
    final selectedModule = modules.contains(_selectedModule)
        ? _selectedModule!
        : modules.first;

    return FutureBuilder<Map<String, dynamic>>(
      future: _storefrontFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                '${widget.businessName} Storefront',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                '${widget.businessName} Storefront',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data ?? const <String, dynamic>{};
        final shoppingStores = _shoppingStoresFromData(data);
        final primaryShoppingStore = _primaryShoppingStore(data);
        final activeSummary = Map<String, dynamic>.from(
          (data['${_keyForModule(selectedModule)}Summary'] as Map?) ??
              const <String, dynamic>{},
        );
        final activeItems =
            (data[_keyForModule(selectedModule)] as List<dynamic>? ?? const [])
                .map((entry) => Map<String, dynamic>.from(entry as Map))
                .toList(growable: false);

        final orderChips = modules
            .map(
              (module) => (
                module: module,
                count: _ordersInProgressFromSummary(
                  Map<String, dynamic>.from(
                    (data['${_keyForModule(module)}Summary'] as Map?) ??
                        const <String, dynamic>{},
                  ),
                ),
              ),
            )
            .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              '${widget.businessName} Storefront',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StorefrontHeaderCard(
                businessName: widget.businessName,
                selectedModule: selectedModule,
                onOpenQueue: () =>
                    _openQueue(module: _keyForModule(selectedModule)),
                onOpenProducts: () =>
                    _openProductsManager(module: _keyForModule(selectedModule)),
              ),
              const SizedBox(height: 12),
              _RecentOrdersModuleChips(
                chips: orderChips,
                selected: selectedModule,
                onSelect: (module) {
                  setState(() {
                    _selectedModule = module;
                  });
                },
              ),
              const SizedBox(height: 12),
              _StorefrontModuleTab(
                module: selectedModule,
                summary: activeSummary,
                items: activeItems,
                searchQuery: _searchByModule[selectedModule] ?? '',
                onSearchChanged: (value) {
                  setState(() {
                    _searchByModule[selectedModule] = value;
                  });
                },
                busyIds: _busyIds,
                onToggle: (targetId, enabled) => _toggleAvailability(
                  module: _keyForModule(selectedModule),
                  targetId: targetId,
                  enabled: enabled,
                ),
                onCreateModule: switch (selectedModule) {
                  ProModule.shopping => () => _openShoppingStoreSetupScreen(
                    existingStore: primaryShoppingStore,
                  ),
                  ProModule.food => _createRestaurant,
                  ProModule.pharmacy => _createPharmacyBusiness,
                  _ => null,
                },
                onAddShoppingProduct: selectedModule == ProModule.shopping
                    ? () => _openCreateShoppingProductScreen(shoppingStores)
                    : selectedModule == ProModule.pharmacy
                    ? () => _openProductsManager(module: 'pharmacy')
                    : null,
              ),
            ],
          ),
          bottomNavigationBar: ShopModuleBottomNav(
            activeTab: ShopModuleBottomTab.products,
            onOrders: () => _openQueue(module: _keyForModule(selectedModule)),
            onProducts: _openProductsManager,
          ),
        );
      },
    );
  }

  String _keyForModule(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'food';
      case ProModule.pharmacy:
        return 'pharmacy';
      default:
        return 'shopping';
    }
  }
}

class _RecentOrdersModuleChips extends StatelessWidget {
  final List<({ProModule module, int count})> chips;
  final ProModule selected;
  final ValueChanged<ProModule> onSelect;

  const _RecentOrdersModuleChips({
    required this.chips,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Module Filter',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map((chip) {
                  final color = ProModuleHelper.getModuleColor(chip.module);
                  final isSelected = selected == chip.module;
                  return ChoiceChip(
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: color.withValues(alpha: 0.16),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? color : Colors.black26,
                      width: isSelected ? 1.4 : 1,
                    ),
                    onSelected: (_) => onSelect(chip.module),
                    label: Text(
                      '${ProModuleHelper.getModuleName(chip.module)} • ${chip.count}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isSelected ? color : Colors.black87,
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _StorefrontModuleTab extends StatelessWidget {
  final ProModule module;
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> items;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Set<String> busyIds;
  final Future<void> Function(String targetId, bool enabled) onToggle;
  final Future<void> Function()? onCreateModule;
  final Future<void> Function()? onAddShoppingProduct;

  const _StorefrontModuleTab({
    required this.module,
    required this.summary,
    required this.items,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.busyIds,
    required this.onToggle,
    required this.onCreateModule,
    required this.onAddShoppingProduct,
  });

  @override
  Widget build(BuildContext context) {
    final color = ProModuleHelper.getModuleColor(module);
    final filteredItems = items
        .where((item) {
          if (searchQuery.trim().isEmpty) return true;
          final haystack = [
            item['name'],
            item['subtitle'],
            item['detail'],
            ...(item['metrics'] as List<dynamic>? ?? const []),
          ].join(' ').toLowerCase();
          return haystack.contains(searchQuery.trim().toLowerCase());
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${ProModuleHelper.getModuleName(module)} controls',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: ValueKey('${module.name}:$searchQuery'),
          initialValue: searchQuery,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: _searchHint(module),
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),
        if (module == ProModule.shopping || module == ProModule.pharmacy)
          _ShoppingActionsRow(
            module: module,
            summary: summary,
            onCreateStore: onCreateModule,
            onAddProduct: onAddShoppingProduct,
          ),
        if (module == ProModule.shopping || module == ProModule.pharmacy)
          const SizedBox(height: 16),
        _StorefrontSummaryCard(module: module, summary: summary),
        const SizedBox(height: 16),
        Text(
          'Catalog Entries',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _EmptyModuleState(
            module: module,
            summary: summary,
            onCreateModule: onCreateModule,
          )
        else if (filteredItems.isEmpty)
          const _EmptySearchState()
        else
          ...filteredItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StorefrontItemCard(
                module: module,
                item: item,
                color: color,
                isBusy: busyIds.contains(item['id']?.toString() ?? ''),
                onToggle: (enabled) =>
                    onToggle(item['id']?.toString() ?? '', enabled),
              ),
            ),
          ),
      ],
    );
  }

  String _searchHint(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'Search your restaurants and menu activity';
      case ProModule.pharmacy:
        return 'Search medicines in your pharmacy catalog';
      default:
        return 'Search your storefront and inventory';
    }
  }
}

class _StorefrontSummaryCard extends StatelessWidget {
  final ProModule module;
  final Map<String, dynamic> summary;

  const _StorefrontSummaryCard({required this.module, required this.summary});

  @override
  Widget build(BuildContext context) {
    final metrics = (summary['metrics'] as List<dynamic>? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
    final color = ProModuleHelper.getModuleColor(module);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary['title']?.toString() ??
                '${ProModuleHelper.getModuleName(module)} storefront',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            summary['subtitle']?.toString() ?? 'Live operational summary',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: metrics
                  .map(
                    (metric) => Container(
                      constraints: const BoxConstraints(minWidth: 130),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            metric['value']?.toString() ?? '0',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metric['label']?.toString() ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShoppingActionsRow extends StatelessWidget {
  final ProModule module;
  final Map<String, dynamic> summary;
  final Future<void> Function()? onCreateStore;
  final Future<void> Function()? onAddProduct;

  const _ShoppingActionsRow({
    required this.module,
    required this.summary,
    required this.onCreateStore,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final hasBindings = summary['hasBindings'] as bool? ?? false;
    final isPharmacy = module == ProModule.pharmacy;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onCreateStore,
            icon: const Icon(Icons.add_business_outlined),
            label: Text(
              hasBindings
                  ? (isPharmacy ? 'Edit Pharmacy' : 'Edit Store Setup')
                  : (isPharmacy ? 'Connect Pharmacy' : 'Create Store'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasBindings ? onAddProduct : null,
            icon: const Icon(Icons.add_box_outlined),
            label: Text(isPharmacy ? 'Add Medicine' : 'Add Product'),
          ),
        ),
      ],
    );
  }
}

class _StorefrontItemCard extends StatelessWidget {
  final ProModule module;
  final Map<String, dynamic> item;
  final Color color;
  final bool isBusy;
  final ValueChanged<bool> onToggle;

  const _StorefrontItemCard({
    required this.module,
    required this.item,
    required this.color,
    required this.isBusy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = item['enabled'] as bool? ?? false;
    final metrics = (item['metrics'] as List<dynamic>? ?? const [])
        .map((entry) => entry.toString())
        .where((entry) => entry.trim().isNotEmpty)
        .toList(growable: false);
    final imageUrl = item['imageUrl']?.toString() ?? '';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StorefrontAvatar(
                  module: module,
                  color: color,
                  imageUrl: imageUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name']?.toString() ?? 'Store item',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(item['subtitle']?.toString() ?? ''),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: isBusy ? null : onToggle),
              ],
            ),
            if ((item['detail']?.toString().trim().isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              Text(
                item['detail']?.toString() ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metrics
                    .map(
                      (metric) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(metric),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  enabled ? _enabledLabel(module) : _disabledLabel(module),
                  style: TextStyle(
                    color: enabled ? color : Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _enabledLabel(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'Restaurant is open';
      case ProModule.pharmacy:
        return 'In stock';
      default:
        return 'Store is open';
    }
  }

  String _disabledLabel(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'Restaurant is paused';
      case ProModule.pharmacy:
        return 'Out of stock';
      default:
        return 'Store is paused';
    }
  }
}

class _StorefrontAvatar extends StatelessWidget {
  final ProModule module;
  final Color color;
  final String imageUrl;

  const _StorefrontAvatar({
    required this.module,
    required this.color,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrl,
          height: 56,
          width: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackIcon(),
        ),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(ProModuleHelper.getModuleIcon(module), color: color),
    );
  }
}

class _EmptyModuleState extends StatelessWidget {
  final ProModule module;
  final Map<String, dynamic> summary;
  final Future<void> Function()? onCreateModule;

  const _EmptyModuleState({
    required this.module,
    required this.summary,
    this.onCreateModule,
  });

  @override
  Widget build(BuildContext context) {
    final hasBindings = summary['hasBindings'] as bool? ?? false;
    final message =
        summary['emptyStateMessage']?.toString().trim().isNotEmpty == true
        ? summary['emptyStateMessage']!.toString()
        : hasBindings
        ? _connectedEmptyMessage(module)
        : _unboundMessage(module);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (!hasBindings && onCreateModule != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreateModule,
                icon: const Icon(Icons.add_business_outlined),
                label: Text(_createLabel(module)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _createLabel(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'Create Restaurant';
      case ProModule.pharmacy:
        return 'Create Pharmacy';
      default:
        return 'Create Store';
    }
  }

  String _unboundMessage(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'No restaurant is bound to this shop profile yet.';
      case ProModule.pharmacy:
        return 'No pharmacy business is bound to this shop profile yet.';
      default:
        return 'No shopping store is bound to this shop profile yet.';
    }
  }

  String _connectedEmptyMessage(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'Your restaurant is connected, but no menu records are available right now.';
      case ProModule.pharmacy:
        return 'Your pharmacy is connected, but no medicines are listed yet.';
      default:
        return 'Your shopping store is connected, but no storefront records are available right now.';
    }
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No storefront items match your search yet.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StorefrontHeaderCard extends StatelessWidget {
  final String businessName;
  final ProModule selectedModule;
  final VoidCallback onOpenQueue;
  final VoidCallback onOpenProducts;

  const _StorefrontHeaderCard({
    required this.businessName,
    required this.selectedModule,
    required this.onOpenQueue,
    required this.onOpenProducts,
  });

  @override
  Widget build(BuildContext context) {
    final color = ProModuleHelper.getModuleColor(selectedModule);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$businessName Storefront',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage availability, review inventory, and jump into queue actions quickly.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenQueue,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.shopping,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Open Queue'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenProducts,
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Products'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
