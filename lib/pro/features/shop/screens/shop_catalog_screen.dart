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
  late Future<Map<String, dynamic>> _availabilityFuture;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _availabilityFuture = _loadAvailability();
  }

  Future<Map<String, dynamic>> _loadAvailability() async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/shop-availability',
      forceRefresh: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> _refresh() async {
    final future = _loadAvailability();
    setState(() {
      _availabilityFuture = future;
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
          future: _availabilityFuture,
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
                    (module) => _AvailabilityList(
                      module: module,
                      items:
                          (data[_keyForModule(module)] as List<dynamic>? ??
                                  const [])
                              .map(
                                (entry) =>
                                    Map<String, dynamic>.from(entry as Map),
                              )
                              .toList(growable: false),
                      busyIds: _busyIds,
                      onToggle: (targetId, enabled) => _toggleAvailability(
                        module: _keyForModule(module),
                        targetId: targetId,
                        enabled: enabled,
                      ),
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

class _AvailabilityList extends StatelessWidget {
  final ProModule module;
  final List<Map<String, dynamic>> items;
  final Set<String> busyIds;
  final Future<void> Function(String targetId, bool enabled) onToggle;

  const _AvailabilityList({
    required this.module,
    required this.items,
    required this.busyIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = ProModuleHelper.getModuleColor(module);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No ${ProModuleHelper.getModuleName(module)} business is bound to this shop profile yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id']?.toString() ?? '';
        final enabled = item['enabled'] as bool? ?? false;
        final isBusy = busyIds.contains(id);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(ProModuleHelper.getModuleIcon(module), color: color),
          ),
          title: Text(
            item['name']?.toString() ?? 'Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            enabled ? _enabledLabel(module) : _disabledLabel(module),
          ),
          trailing: Switch(
            value: enabled,
            onChanged: isBusy ? null : (value) => onToggle(id, value),
          ),
        );
      },
    );
  }

  String _enabledLabel(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'Open for customers';
      case ProModule.pharmacy:
        return 'In stock';
      default:
        return 'Store open';
    }
  }

  String _disabledLabel(ProModule module) {
    switch (module) {
      case ProModule.food:
        return 'Temporarily closed';
      case ProModule.pharmacy:
        return 'Out of stock';
      default:
        return 'Store paused';
    }
  }
}
