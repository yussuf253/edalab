import 'dart:typed_data';

import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/media_upload_service.dart';
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

  AppLocalizations get l10n => AppLocalizations.of(context)!;

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.createStoreFirstMessage)));
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

  Future<void> _openRestaurantSetupSheet({
    required Map<String, dynamic>? existingRestaurant,
  }) async {
    final nameController = TextEditingController(
      text: existingRestaurant?['name']?.toString().trim().isNotEmpty == true
          ? existingRestaurant!['name'].toString().trim()
          : widget.businessName,
    );
    final cuisineController = TextEditingController(
      text: existingRestaurant?['cuisine']?.toString().trim() ?? '',
    );
    var uploadedImageUrl =
        existingRestaurant?['imageUrl']?.toString().trim() ?? '';
    Uint8List? pickedImageBytes;
    var isUploadingImage = false;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickAndUploadImage() async {
              if (isUploadingImage) return;
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1800,
                imageQuality: 88,
              );
              if (file == null) return;

              final bytes = await file.readAsBytes();
              if (!mounted) return;
              setModalState(() {
                pickedImageBytes = bytes;
                isUploadingImage = true;
              });

              try {
                final uploaded = await MediaUploadService.uploadImage(
                  scope: MediaUploadScope.restaurant,
                  ownerId: widget.userId,
                  fileName: file.name,
                  mimeType: file.mimeType,
                  bytes: bytes,
                );
                if (!mounted) return;
                setModalState(() {
                  uploadedImageUrl = uploaded.url;
                });
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              } finally {
                if (mounted) {
                  setModalState(() => isUploadingImage = false);
                }
              }
            }

            Future<void> submit() async {
              if (isSubmitting || isUploadingImage) return;
              if (nameController.text.trim().length < 2) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.enterValidRestaurantNameError)),
                );
                return;
              }
              setModalState(() => isSubmitting = true);
              try {
                final response = Map<String, dynamic>.from(
                  await ApiClient.post('/pro/${widget.userId}/restaurant', {
                        'name': nameController.text.trim(),
                        'imageUrl': uploadedImageUrl,
                        if (cuisineController.text.trim().isNotEmpty)
                          'cuisine': cuisineController.text.trim(),
                      })
                      as Map,
                );
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      (response['created'] as bool? ?? false)
                          ? l10n.restaurantCreatedSuccessfully
                          : l10n.restaurantUpdatedSuccessfully,
                    ),
                  ),
                );
                await _refresh();
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                setModalState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingRestaurant == null
                          ? l10n.connectRestaurant
                          : l10n.editRestaurant,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.restaurantName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cuisineController,
                      decoration: InputDecoration(
                        labelText: l10n.cuisineLabel,
                        hintText: l10n.cuisineHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 156,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pickedImageBytes != null
                          ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                          : (uploadedImageUrl.isNotEmpty
                                ? Image.network(
                                    uploadedImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(
                                        Icons.restaurant_outlined,
                                        size: 38,
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.restaurant_outlined,
                                      size: 38,
                                    ),
                                  )),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isUploadingImage ? null : pickAndUploadImage,
                      icon: isUploadingImage
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        isUploadingImage
                            ? l10n.uploadingImage
                            : l10n.uploadRestaurantImage,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSubmitting || isUploadingImage
                            ? null
                            : submit,
                        icon: isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSubmitting
                              ? l10n.saving
                              : existingRestaurant == null
                              ? l10n.connectRestaurant
                              : l10n.saveRestaurant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    cuisineController.dispose();
  }

  Future<void> _createPharmacyBusiness() async {
    try {
      await ApiClient.post('/pro/${widget.userId}/pharmacy-business', {
        'name': widget.businessName,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pharmacyConnectedSuccessfully)),
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

  Map<String, dynamic>? _primaryRestaurant(Map<String, dynamic> data) {
    final restaurants = (data['food'] as List<dynamic>? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
    return restaurants.isEmpty ? null : restaurants.first;
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
                l10n.shopStorefrontTitle(widget.businessName),
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
                l10n.shopStorefrontTitle(widget.businessName),
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
        final primaryRestaurant = _primaryRestaurant(data);
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
              l10n.shopStorefrontTitle(widget.businessName),
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
                  ProModule.food => () => _openRestaurantSetupSheet(
                    existingRestaurant: primaryRestaurant,
                  ),
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.moduleFilter,
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
    final l10n = AppLocalizations.of(context)!;
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
          l10n.moduleControls(ProModuleHelper.getModuleName(module)),
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
            hintText: _searchHint(module, l10n),
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
        if (module == ProModule.food)
          _FoodActionsRow(
            summary: summary,
            onCreateOrEditRestaurant: onCreateModule,
          ),
        if (module == ProModule.shopping ||
            module == ProModule.pharmacy ||
            module == ProModule.food)
          const SizedBox(height: 16),
        _StorefrontSummaryCard(module: module, summary: summary),
        const SizedBox(height: 16),
        Text(
          l10n.catalogEntries,
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(l10n.noStorefrontMatch, textAlign: TextAlign.center),
            ),
          )
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

  String _searchHint(ProModule module, AppLocalizations l10n) {
    switch (module) {
      case ProModule.food:
        return l10n.searchFoodHint;
      case ProModule.pharmacy:
        return l10n.searchPharmacyHint;
      default:
        return l10n.searchStorefrontHint;
    }
  }
}

class _StorefrontSummaryCard extends StatelessWidget {
  final ProModule module;
  final Map<String, dynamic> summary;

  const _StorefrontSummaryCard({required this.module, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = ProModuleHelper.getModuleColor(module);
    final metrics = (summary['metrics'] as List<dynamic>? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);

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
                l10n.moduleStorefrontSubtitle(
                  ProModuleHelper.getModuleName(module),
                ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            summary['subtitle']?.toString() ?? l10n.liveOperationalSummary,
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
    final l10n = AppLocalizations.of(context)!;
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
                  ? (isPharmacy ? l10n.editPharmacy : l10n.editStoreSetup)
                  : (isPharmacy ? l10n.connectPharmacy : l10n.createStore),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasBindings ? onAddProduct : null,
            icon: const Icon(Icons.add_box_outlined),
            label: Text(isPharmacy ? l10n.addMedicine : l10n.addProduct),
          ),
        ),
      ],
    );
  }
}

class _FoodActionsRow extends StatelessWidget {
  final Map<String, dynamic> summary;
  final Future<void> Function()? onCreateOrEditRestaurant;

  const _FoodActionsRow({
    required this.summary,
    required this.onCreateOrEditRestaurant,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasBindings = summary['hasBindings'] as bool? ?? false;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onCreateOrEditRestaurant,
        icon: Icon(
          hasBindings ? Icons.edit_outlined : Icons.add_business_outlined,
        ),
        label: Text(
          hasBindings ? l10n.editRestaurantSetup : l10n.connectRestaurant,
        ),
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

  const _StorefrontItemCard({
    required this.module,
    required this.item,
    required this.color,
    required this.isBusy,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                        item['name']?.toString() ?? l10n.storeLabel,
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
                  enabled
                      ? _enabledLabel(module, l10n)
                      : _disabledLabel(module, l10n),
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

  String _enabledLabel(ProModule module, AppLocalizations l10n) {
    switch (module) {
      case ProModule.food:
        return l10n.restaurantOpen;
      case ProModule.pharmacy:
        return l10n.inStock;
      default:
        return l10n.storeOpen;
    }
  }

  String _disabledLabel(ProModule module, AppLocalizations l10n) {
    switch (module) {
      case ProModule.food:
        return l10n.restaurantPaused;
      case ProModule.pharmacy:
        return l10n.outOfStock;
      default:
        return l10n.storePaused;
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
    final l10n = AppLocalizations.of(context)!;
    final hasBindings = summary['hasBindings'] as bool? ?? false;
    final message =
        summary['emptyStateMessage']?.toString().trim().isNotEmpty == true
        ? summary['emptyStateMessage']!.toString()
        : hasBindings
        ? _connectedEmptyMessage(module, l10n)
        : _unboundMessage(module, l10n);

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
                label: Text(_createLabel(module, l10n)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _createLabel(ProModule module, AppLocalizations l10n) {
    switch (module) {
      case ProModule.food:
        return l10n.createRestaurant;
      case ProModule.pharmacy:
        return l10n.createPharmacy;
      default:
        return l10n.createStore;
    }
  }

  String _unboundMessage(ProModule module, AppLocalizations l10n) {
    switch (module) {
      case ProModule.food:
        return l10n.noRestaurantBound;
      case ProModule.pharmacy:
        return l10n.noPharmacyBound;
      default:
        return l10n.noStoreBound;
    }
  }

  String _connectedEmptyMessage(ProModule module, AppLocalizations l10n) {
    switch (module) {
      case ProModule.food:
        return l10n.restaurantConnectedNoMenu;
      case ProModule.pharmacy:
        return l10n.pharmacyConnectedNoMedicines;
      default:
        return l10n.storeConnectedNoStorefront;
    }
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
    final l10n = AppLocalizations.of(context)!;
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
            l10n.shopStorefrontTitle(businessName),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.manageAvailabilitySubtitle,
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
                  label: Text(l10n.openQueue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenProducts,
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text(l10n.productsLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
