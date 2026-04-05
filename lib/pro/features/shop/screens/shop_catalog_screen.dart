import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/utils/pro_module_helper.dart';

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
  String _searchQuery = '';

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

  Future<void> _showCreateShoppingStoreForm() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ShoppingStoreFormDialog(
        initialName: widget.businessName,
      ),
    );
    if (result == null) return;

    try {
      final response = Map<String, dynamic>.from(
        await ApiClient.post('/pro/${widget.userId}/shopping-store', result)
            as Map,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (response['created'] as bool? ?? false)
                ? 'Store created and connected to your profile.'
                : 'Existing store updated and connected to your profile.',
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

  Future<void> _showCreateShoppingProductForm(
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ShoppingProductFormDialog(stores: shoppingStores),
    );
    if (result == null) return;

    try {
      await ApiClient.post('/pro/${widget.userId}/shopping-products', result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added to your catalog.'),
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

  Future<void> _openPreview(ProModule module, Map<String, dynamic> item) async {
    if (module == ProModule.shopping) {
      final previewId = item['previewId']?.toString() ?? '';
      if (previewId.isEmpty) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _StorePreviewSheet(storeSlug: previewId),
      );
      return;
    }

    if (module == ProModule.food) {
      final restaurantId = item['id']?.toString() ?? '';
      if (restaurantId.isEmpty) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _RestaurantPreviewSheet(restaurantId: restaurantId),
      );
    }
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
    final tabs = storeModules.isEmpty ? [ProModule.shopping] : storeModules;

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.businessName} Storefront',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              isScrollable: true,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: tabs
                  .map(
                    (module) =>
                        Tab(text: ProModuleHelper.getModuleName(module)),
                  )
                  .toList(),
            ),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _storefrontFuture,
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
            return TabBarView(
              children: tabs
                  .map(
                    (module) => _StorefrontModuleTab(
                      module: module,
                      summary: Map<String, dynamic>.from(
                        (data['${_keyForModule(module)}Summary'] as Map?) ??
                            const <String, dynamic>{},
                      ),
                      items:
                          (data[_keyForModule(module)] as List<dynamic>? ??
                                  const [])
                              .map(
                                (entry) =>
                                    Map<String, dynamic>.from(entry as Map),
                              )
                              .toList(growable: false),
                      searchQuery: _searchQuery,
                      onSearchChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      busyIds: _busyIds,
                      onToggle: (targetId, enabled) => _toggleAvailability(
                        module: _keyForModule(module),
                        targetId: targetId,
                        enabled: enabled,
                      ),
                      onCreateModule: switch (module) {
                        ProModule.shopping => _showCreateShoppingStoreForm,
                        ProModule.food => _createRestaurant,
                        ProModule.pharmacy => _createPharmacyBusiness,
                        _ => null,
                      },
                      onAddShoppingProduct: module == ProModule.shopping
                          ? () => _showCreateShoppingProductForm(
                              (data['shopping'] as List<dynamic>? ?? const [])
                                  .map(
                                    (entry) => Map<String, dynamic>.from(
                                      entry as Map,
                                    ),
                                  )
                                  .toList(growable: false),
                            )
                          : null,
                      onPreview: (item) => _openPreview(module, item),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
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
  final Future<void> Function(Map<String, dynamic> item) onPreview;

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
    required this.onPreview,
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        if (module == ProModule.shopping)
          _ShoppingActionsRow(
            summary: summary,
            onCreateStore: onCreateModule,
            onAddProduct: onAddShoppingProduct,
          ),
        if (module == ProModule.shopping) const SizedBox(height: 16),
        _StorefrontSummaryCard(module: module, summary: summary),
        const SizedBox(height: 16),
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
                onPreview: module == ProModule.pharmacy
                    ? null
                    : () => onPreview(item),
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
  final Map<String, dynamic> summary;
  final Future<void> Function()? onCreateStore;
  final Future<void> Function()? onAddProduct;

  const _ShoppingActionsRow({
    required this.summary,
    required this.onCreateStore,
    required this.onAddProduct,
  });

  @override
  Widget build(BuildContext context) {
    final hasBindings = summary['hasBindings'] as bool? ?? false;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onCreateStore,
            icon: const Icon(Icons.add_business_outlined),
            label: Text(hasBindings ? 'Edit Store Setup' : 'Create Store'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasBindings ? onAddProduct : null,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Add Product'),
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
  final VoidCallback? onPreview;

  const _StorefrontItemCard({
    required this.module,
    required this.item,
    required this.color,
    required this.isBusy,
    required this.onToggle,
    this.onPreview,
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
                const Spacer(),
                if (onPreview != null)
                  OutlinedButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(
                      module == ProModule.food ? 'View Menu' : 'View Catalog',
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

class _ShoppingStoreFormDialog extends StatefulWidget {
  final String initialName;

  const _ShoppingStoreFormDialog({required this.initialName});

  @override
  State<_ShoppingStoreFormDialog> createState() =>
      _ShoppingStoreFormDialogState();
}

class _ShoppingStoreFormDialogState extends State<_ShoppingStoreFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _taglineController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Store'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Store name'),
                  validator: (value) => (value == null || value.trim().length < 2)
                      ? 'Enter a store name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _taglineController,
                  decoration: const InputDecoration(labelText: 'Tagline'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 3,
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://...',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop({
              'name': _nameController.text.trim(),
              'tagline': _taglineController.text.trim(),
              'description': _descriptionController.text.trim(),
              'imageUrl': _imageUrlController.text.trim(),
            });
          },
          child: const Text('Save Store'),
        ),
      ],
    );
  }
}

class _ShoppingProductFormDialog extends StatefulWidget {
  final List<Map<String, dynamic>> stores;

  const _ShoppingProductFormDialog({required this.stores});

  @override
  State<_ShoppingProductFormDialog> createState() =>
      _ShoppingProductFormDialogState();
}

class _ShoppingProductFormDialogState extends State<_ShoppingProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStoreId;
  final _categoryController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _unitController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _inStock = true;

  @override
  void initState() {
    super.initState();
    _selectedStoreId = widget.stores.isNotEmpty
        ? widget.stores.first['id']?.toString()
        : null;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _unitController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedStoreId,
                  items: widget.stores
                      .map(
                        (store) => DropdownMenuItem<String>(
                          value: store['id']?.toString(),
                          child: Text(store['name']?.toString() ?? 'Store'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedStoreId = value),
                  decoration: const InputDecoration(labelText: 'Store'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Catalog category'),
                  validator: (value) => (value == null || value.trim().length < 2)
                      ? 'Enter a category'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product name'),
                  validator: (value) => (value == null || value.trim().length < 2)
                      ? 'Enter a product name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 3,
                  maxLines: 4,
                  validator: (value) => (value == null || value.trim().length < 4)
                      ? 'Enter a description'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Price'),
                  validator: (value) =>
                      (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter a valid price' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _originalPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Original price'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _inStock,
                  onChanged: (value) => setState(() => _inStock = value),
                  title: const Text('Available in stock'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (_selectedStoreId == null || _selectedStoreId!.isEmpty) return;
            Navigator.of(context).pop({
              'storeId': _selectedStoreId,
              'categoryName': _categoryController.text.trim(),
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'price': double.parse(_priceController.text.trim()),
              'originalPrice':
                  _originalPriceController.text.trim().isEmpty
                      ? null
                      : double.tryParse(_originalPriceController.text.trim()),
              'unit': _unitController.text.trim(),
              'imageUrl': _imageUrlController.text.trim(),
              'inStock': _inStock,
            });
          },
          child: const Text('Add Product'),
        ),
      ],
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
            Text(
              message,
              textAlign: TextAlign.center,
            ),
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

class _StorePreviewSheet extends StatelessWidget {
  final String storeSlug;

  const _StorePreviewSheet({required this.storeSlug});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadStore(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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

            final store = snapshot.data ?? const <String, dynamic>{};
            final products = (store['products'] as List<dynamic>? ?? const [])
                .map((entry) => Map<String, dynamic>.from(entry as Map))
                .toList(growable: false);

            return Material(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    store['name']?.toString() ?? 'Store preview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(store['tagline']?.toString() ?? ''),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PreviewMetricChip(
                        label: 'Products',
                        value: '${products.length}',
                      ),
                      _PreviewMetricChip(
                        label: 'Categories',
                        value:
                            '${(store['categories'] as List<dynamic>? ?? const []).length}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...products.map(
                    (product) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(product['name']?.toString() ?? 'Product'),
                      subtitle: Text(
                        [
                          product['category']?.toString() ?? '',
                          product['price']?.toString() ?? '',
                        ].where((entry) => entry.isNotEmpty).join(' • '),
                      ),
                      trailing: Text(
                        (product['inStock'] as bool? ?? false)
                            ? 'In stock'
                            : 'Out of stock',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadStore() async {
    final response = await ApiClient.get('/catalog/shopping-stores/$storeSlug');
    return Map<String, dynamic>.from(response as Map);
  }
}

class _RestaurantPreviewSheet extends StatelessWidget {
  final String restaurantId;

  const _RestaurantPreviewSheet({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadRestaurant(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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

            final restaurant = snapshot.data ?? const <String, dynamic>{};
            final menu = (restaurant['menu'] as List<dynamic>? ?? const [])
                .map((entry) => Map<String, dynamic>.from(entry as Map))
                .toList(growable: false);

            return Material(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    restaurant['name']?.toString() ?? 'Restaurant preview',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(restaurant['cuisine']?.toString() ?? ''),
                  const SizedBox(height: 20),
                  ...menu.map((category) {
                    final items =
                        (category['items'] as List<dynamic>? ?? const [])
                            .map(
                              (entry) =>
                                  Map<String, dynamic>.from(entry as Map),
                            )
                            .toList(growable: false);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name']?.toString() ?? 'Menu section',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        ...items.map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item['name']?.toString() ?? 'Dish'),
                            subtitle: Text(
                              item['description']?.toString() ?? '',
                            ),
                            trailing: Text(
                              (item['isAvailable'] as bool? ?? false)
                                  ? 'Available'
                                  : 'Hidden',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadRestaurant() async {
    final response = await ApiClient.get('/catalog/restaurants/$restaurantId');
    return Map<String, dynamic>.from(response as Map);
  }
}

class _PreviewMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$value $label'),
    );
  }
}
