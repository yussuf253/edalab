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
  final Future<void> Function(Map<String, dynamic> item) onPreview;

  const _StorefrontModuleTab({
    required this.module,
    required this.summary,
    required this.items,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.busyIds,
    required this.onToggle,
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
        _StorefrontSummaryCard(module: module, summary: summary),
        const SizedBox(height: 16),
        if (items.isEmpty)
          _EmptyModuleState(module: module, summary: summary)
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

class _EmptyModuleState extends StatelessWidget {
  final ProModule module;
  final Map<String, dynamic> summary;

  const _EmptyModuleState({required this.module, required this.summary});

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
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
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
