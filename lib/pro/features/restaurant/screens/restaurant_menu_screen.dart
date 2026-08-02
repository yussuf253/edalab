import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../l10n/app_localizations.dart';
import 'restaurant_menu_item_edit_screen.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String userId;

  const RestaurantMenuScreen({super.key, required this.userId});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  late Future<Map<String, dynamic>?> _menuFuture;
  final Set<String> _busyItemIds = <String>{};

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _menuFuture = _loadMenu();
  }

  Future<Map<String, dynamic>?> _loadMenu() async {
    try {
      final response = await ApiClient.get(
        '/pro/${widget.userId}/restaurant-menu',
      );
      final restaurants = (response as Map)['restaurants'] as List?;
      if (restaurants == null || restaurants.isEmpty) return null;
      // A shop pro is typically bound to a single restaurant; use the first.
      return Map<String, dynamic>.from(restaurants.first as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh() async {
    final future = _loadMenu();
    setState(() => _menuFuture = future);
    await future;
  }

  Future<void> _toggleAvailability(
    Map<String, dynamic> item,
    bool value,
  ) async {
    final id = item['id']?.toString();
    if (id == null) return;
    setState(() => _busyItemIds.add(id));
    try {
      await ApiClient.patch('/pro/${widget.userId}/restaurant-menu/items/$id', {
        'isAvailable': value,
      });
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(id));
    }
  }

  Future<void> _addCategory(String restaurantId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addMenuCategory),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.newCategoryName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      await ApiClient.post('/pro/${widget.userId}/restaurant-menu/categories', {
        'name': name,
        'restaurantId': restaurantId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.categoryCreated)));
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
    }
  }

  Future<void> _openItemEditor({
    required String restaurantId,
    required List<Map<String, dynamic>> categories,
    Map<String, dynamic>? item,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RestaurantMenuItemEditScreen(
          userId: widget.userId,
          restaurantId: restaurantId,
          categories: categories,
          existingItem: item,
        ),
      ),
    );
    if (saved == true) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.restaurantMenuTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _menuFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final restaurant = snapshot.data;
          if (restaurant == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(ProDesignSystem.spacing24),
                child: Text(
                  l10n.restaurantMenuNoBinding,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final restaurantId = restaurant['id'].toString();
          final categories = List<Map<String, dynamic>>.from(
            (restaurant['categories'] as List? ?? [])
                .map((c) => Map<String, dynamic>.from(c as Map)),
          );
          final items = List<Map<String, dynamic>>.from(
            (restaurant['items'] as List? ?? [])
                .map((i) => Map<String, dynamic>.from(i as Map)),
          );

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(ProDesignSystem.spacing24),
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.restaurant_menu_rounded,
                    size: 48,
                    color: AppColors.grey.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: ProDesignSystem.spacing16),
                  Text(
                    l10n.restaurantMenuEmptyState,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final itemsByCategory = <String?, List<Map<String, dynamic>>>{};
          for (final item in items) {
            final categoryId = item['categoryId']?.toString();
            itemsByCategory.putIfAbsent(categoryId, () => []).add(item);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(ProDesignSystem.spacing16),
              children: [
                for (final category in categories)
                  if ((itemsByCategory[category['id']] ?? []).isNotEmpty)
                    _CategorySection(
                      title: category['name']?.toString() ?? '',
                      items: itemsByCategory[category['id']] ?? [],
                      busyItemIds: _busyItemIds,
                      onToggleAvailability: _toggleAvailability,
                      onTapItem: (item) => _openItemEditor(
                        restaurantId: restaurantId,
                        categories: categories,
                        item: item,
                      ),
                    ),
                if ((itemsByCategory[null] ?? []).isNotEmpty)
                  _CategorySection(
                    title: l10n.uncategorizedItems,
                    items: itemsByCategory[null] ?? [],
                    busyItemIds: _busyItemIds,
                    onToggleAvailability: _toggleAvailability,
                    onTapItem: (item) => _openItemEditor(
                      restaurantId: restaurantId,
                      categories: categories,
                      item: item,
                    ),
                  ),
                const SizedBox(height: ProDesignSystem.spacing32),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>?>(
        future: _menuFuture,
        builder: (context, snapshot) {
          final restaurant = snapshot.data;
          if (restaurant == null) return const SizedBox.shrink();
          final restaurantId = restaurant['id'].toString();
          final categories = List<Map<String, dynamic>>.from(
            (restaurant['categories'] as List? ?? [])
                .map((c) => Map<String, dynamic>.from(c as Map)),
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'add_category',
                onPressed: () => _addCategory(restaurantId),
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.food,
                icon: const Icon(Icons.category_outlined),
                label: Text(l10n.addMenuCategory),
              ),
              const SizedBox(width: ProDesignSystem.spacing12),
              FloatingActionButton.extended(
                heroTag: 'add_item',
                onPressed: () => _openItemEditor(
                  restaurantId: restaurantId,
                  categories: categories,
                ),
                backgroundColor: AppColors.food,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addMenuItem),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Set<String> busyItemIds;
  final void Function(Map<String, dynamic> item, bool value)
  onToggleAvailability;
  final void Function(Map<String, dynamic> item) onTapItem;

  const _CategorySection({
    required this.title,
    required this.items,
    required this.busyItemIds,
    required this.onToggleAvailability,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: ProDesignSystem.spacing8,
              left: 4,
            ),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          ModernCard(
            padding: EdgeInsets.zero,
            backgroundColor: AppColors.white,
            shadows: ProDesignSystem.shadowElevation1,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _MenuItemRow(
                    item: items[i],
                    isBusy: busyItemIds.contains(items[i]['id']?.toString()),
                    onToggleAvailability: (value) =>
                        onToggleAvailability(items[i], value),
                    onTap: () => onTapItem(items[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isBusy;
  final ValueChanged<bool> onToggleAvailability;
  final VoidCallback onTap;

  const _MenuItemRow({
    required this.item,
    required this.isBusy,
    required this.onToggleAvailability,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final isAvailable = item['isAvailable'] as bool? ?? true;
    final customizations = item['customizations'];
    final hasCustomizations =
        customizations is Map &&
        (customizations['groups'] as List?)?.isNotEmpty == true;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ProDesignSystem.spacing16,
          vertical: ProDesignSystem.spacing12,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? '',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'DJF${price.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (hasCustomizations) ...[
                    const SizedBox(height: 2),
                    Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: AppColors.grey,
                    ),
                  ],
                ],
              ),
            ),
            if (isBusy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: isAvailable,
                activeColor: AppColors.food,
                onChanged: onToggleAvailability,
              ),
          ],
        ),
      ),
    );
  }
}
