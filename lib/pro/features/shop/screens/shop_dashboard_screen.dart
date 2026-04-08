import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/widgets/pro_drawer.dart';
import 'shop_catalog_screen.dart';
import 'shop_orders_queue_screen.dart';

class ShopDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const ShopDashboardScreen({super.key, required this.profile});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  late Future<ProDashboardData> _dashboardFuture;
  final Set<String> _busyItemIds = <String>{};
  String _selectedOrderModule = 'all';

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant ShopDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.userId != widget.profile.userId) {
      _dashboardFuture = _loadDashboard();
    }
  }

  Future<ProDashboardData> _loadDashboard() async {
    final response = Map<String, dynamic>.from(
      await ApiClient.get('/pro/${widget.profile.userId}/dashboard') as Map,
    );
    return ProDashboardData.fromJson(response);
  }

  Future<void> _refreshDashboard() async {
    final future = _loadDashboard();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  Future<void> _openStorefront() async {
    final activeModules = widget.profile.activeModules
        .where(
          (module) => {
            ProModule.shopping,
            ProModule.food,
            ProModule.pharmacy,
          }.contains(module),
        )
        .toList(growable: false);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopCatalogScreen(
          userId: widget.profile.userId,
          businessName: widget.profile.businessName,
          modules: activeModules,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _openQueue({String initialModule = 'all'}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopOrdersQueueScreen(
          userId: widget.profile.userId,
          businessName: widget.profile.businessName,
          initialModule: initialModule,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  String? _nextShopStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'CONFIRMED';
      case 'CONFIRMED':
        return 'PROCESSING';
      case 'PROCESSING':
        return 'DISPATCHED';
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  String _statusActionLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Confirm';
      case 'CONFIRMED':
        return 'Prep';
      case 'PROCESSING':
        return 'Dispatch';
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return 'Complete';
      default:
        return 'Done';
    }
  }

  Future<void> _advanceOrderStatus(ProDashboardItem item) async {
    final nextStatus = _nextShopStatus(item.status);
    if (nextStatus == null) return;

    setState(() {
      _busyItemIds.add(item.id);
    });
    try {
      await ApiClient.post('/pro/${widget.profile.userId}/shop-order-status', {
        'orderId': item.id,
        'status': nextStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order updated to ${nextStatus.replaceAll('_', ' ')}.'),
        ),
      );
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busyItemIds.remove(item.id);
        });
      }
    }
  }

  List<_RecentOrderEntry> _collectRecentOrders(
    List<ProDashboardModuleSummary> summaries,
  ) {
    final entries = summaries
        .expand(
          (summary) => summary.recentItems.map(
            (item) => _RecentOrderEntry(
              module: summary.module,
              moduleTitle: summary.title,
              color: ProModuleHelper.getModuleColor(
                _moduleFromSummary(summary.module),
              ),
              item: item,
            ),
          ),
        )
        .toList(growable: false);

    entries.sort((left, right) {
      final leftDate =
          DateTime.tryParse(left.item.meta ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          DateTime.tryParse(right.item.meta ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return rightDate.compareTo(leftDate);
    });
    return entries.take(4).toList(growable: false);
  }

  ProModule _moduleFromSummary(String module) {
    switch (module) {
      case 'food':
        return ProModule.food;
      case 'pharmacy':
        return ProModule.pharmacy;
      default:
        return ProModule.shopping;
    }
  }

  List<String> _orderFilterModules(List<_RecentOrderEntry> entries) {
    final modules = entries.map((entry) => entry.module).toSet().toList()
      ..sort();
    return ['all', ...modules];
  }

  List<_RecentOrderEntry> _filterRecentOrders(List<_RecentOrderEntry> entries) {
    if (_selectedOrderModule == 'all') return entries;
    return entries
        .where((entry) => entry.module == _selectedOrderModule)
        .toList(growable: false);
  }

  bool _isActionableStatus(String status) {
    final normalized = status.toUpperCase();
    return !{'COMPLETED', 'CANCELLED', 'REFUNDED'}.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const ProDrawer(),
      appBar: AppBar(
        title: Text(widget.profile.businessName),
        elevation: 0,
        backgroundColor: AppColors.shopping,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(ProRoutePaths.inbox),
          ),
        ],
      ),
      body: FutureBuilder<ProDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final stats = data?.stats ?? const <ProDashboardMetric>[];
          final moduleSummaries =
              data?.moduleSummaries ?? const <ProDashboardModuleSummary>[];
          final recentOrders = _collectRecentOrders(moduleSummaries);
          final orderFilterModules = _orderFilterModules(recentOrders);
          final filteredRecentOrders = _filterRecentOrders(recentOrders);
          final actionableCount = recentOrders
              .where((entry) => _isActionableStatus(entry.item.status))
              .length;

          if (snapshot.connectionState == ConnectionState.waiting &&
              data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DashboardHero(
                  businessName: widget.profile.businessName,
                  scopeNote: data?.scopeNote,
                  onOpenOrders: () => _openQueue(),
                  onOpenCatalog: _openStorefront,
                ),
                const SizedBox(height: 12),
                if (stats.isNotEmpty)
                  _StatsGrid(stats: stats.take(4).toList(growable: false)),
                const SizedBox(height: 16),
                Text(
                  'Manage Store',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _ManagementGrid(
                  onOrders: () => _openQueue(),
                  onCatalog: _openStorefront,
                  onProducts: _openStorefront,
                ),
                const SizedBox(height: 20),
                Text(
                  'Store Sections',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (moduleSummaries.isEmpty)
                  const _EmptyStoreState()
                else
                  ...moduleSummaries.map(
                    (summary) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ModuleSnapshotCard(
                        summary: summary,
                        onOpen: () => _openQueue(initialModule: summary.module),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _OrdersSectionCard(
                  totalOrders: recentOrders.length,
                  actionableCount: actionableCount,
                  moduleCount: orderFilterModules.length - 1,
                  selectedModule: _selectedOrderModule,
                  availableModules: orderFilterModules,
                  onSelectModule: (module) {
                    setState(() {
                      _selectedOrderModule = module;
                    });
                  },
                  onOpenQueue: () => _openQueue(
                    initialModule:
                        _selectedOrderModule == 'all'
                            ? 'all'
                            : _selectedOrderModule,
                  ),
                  child: recentOrders.isEmpty
                      ? const _EmptyOrdersState(compact: true)
                      : Column(
                          children: filteredRecentOrders
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LiveOrderCard(
                                    entry: entry,
                                    isBusy: _busyItemIds.contains(entry.item.id),
                                    actionLabel: _statusActionLabel(
                                      entry.item.status,
                                    ),
                                    canAdvance:
                                        _nextShopStatus(entry.item.status) !=
                                        null,
                                    onAdvance: () =>
                                        _advanceOrderStatus(entry.item),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String businessName;
  final String? scopeNote;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenCatalog;

  const _DashboardHero({
    required this.businessName,
    required this.scopeNote,
    required this.onOpenOrders,
    required this.onOpenCatalog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.shopping, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            businessName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Orders, catalog, and stock controls in one place.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (scopeNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              scopeNote!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.shopping,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Orders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenCatalog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Catalog'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<ProDashboardMetric> stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return SizedBox(
            width: 150,
            child: _StatTile(stat: stat),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final ProDashboardMetric stat;

  const _StatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            stat.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ManagementGrid extends StatelessWidget {
  final VoidCallback onOrders;
  final VoidCallback onCatalog;
  final VoidCallback onProducts;

  const _ManagementGrid({
    required this.onOrders,
    required this.onCatalog,
    required this.onProducts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          _ManagementCard(
            icon: Icons.receipt_long_outlined,
            title: 'Orders Queue',
            subtitle: 'Review incoming orders and update status.',
            tag: 'Queue',
            onTap: onOrders,
          ),
          const Divider(height: 1),
          _ManagementCard(
            icon: Icons.storefront_outlined,
            title: 'Storefront Catalog',
            subtitle: 'Manage store info, visibility, and menu/catalog.',
            tag: 'Catalog',
            onTap: onCatalog,
          ),
          const Divider(height: 1),
          _ManagementCard(
            icon: Icons.inventory_2_outlined,
            title: 'Stock & Products',
            subtitle: 'Add products and control item availability.',
            tag: 'Inventory',
            onTap: onProducts,
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: AppColors.shopping.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.shopping),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.shopping.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: AppColors.shopping,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _OrdersSectionCard extends StatelessWidget {
  final int totalOrders;
  final int actionableCount;
  final int moduleCount;
  final String selectedModule;
  final List<String> availableModules;
  final ValueChanged<String> onSelectModule;
  final VoidCallback onOpenQueue;
  final Widget child;

  const _OrdersSectionCard({
    required this.totalOrders,
    required this.actionableCount,
    required this.moduleCount,
    required this.selectedModule,
    required this.availableModules,
    required this.onSelectModule,
    required this.onOpenQueue,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Orders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review incoming orders and move them through the queue.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onOpenQueue,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open queue'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OrderSummaryTile(
                  value: '$totalOrders',
                  label: 'Live now',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OrderSummaryTile(
                  value: '$actionableCount',
                  label: 'Need action',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OrderSummaryTile(
                  value: '$moduleCount',
                  label: 'Active lanes',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableModules
                .map(
                  (module) => ChoiceChip(
                    label: Text(_moduleLabel(module)),
                    selected: selectedModule == module,
                    onSelected: (_) => onSelectModule(module),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  String _moduleLabel(String module) {
    switch (module) {
      case 'shopping':
        return 'Shopping';
      case 'food':
        return 'Food';
      case 'pharmacy':
        return 'Pharmacy';
      default:
        return 'All';
    }
  }
}

class _OrderSummaryTile extends StatelessWidget {
  final String value;
  final String label;

  const _OrderSummaryTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.shopping.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ModuleSnapshotCard extends StatelessWidget {
  final ProDashboardModuleSummary summary;
  final VoidCallback onOpen;

  const _ModuleSnapshotCard({required this.summary, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final module = _moduleFromSummary(summary.module);
    final color = ProModuleHelper.getModuleColor(module);
    final previewMetrics = summary.metrics.take(2).toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(ProModuleHelper.getModuleIcon(module), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                ...previewMetrics.map((metric) => Text(metric)),
              ],
            ),
          ),
          OutlinedButton(onPressed: onOpen, child: const Text('Open')),
        ],
      ),
    );
  }

  ProModule _moduleFromSummary(String module) {
    switch (module) {
      case 'food':
        return ProModule.food;
      case 'pharmacy':
        return ProModule.pharmacy;
      default:
        return ProModule.shopping;
    }
  }
}

class _LiveOrderCard extends StatelessWidget {
  final _RecentOrderEntry entry;
  final bool isBusy;
  final bool canAdvance;
  final String actionLabel;
  final VoidCallback onAdvance;

  const _LiveOrderCard({
    required this.entry,
    required this.isBusy,
    required this.canAdvance,
    required this.actionLabel,
    required this.onAdvance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.moduleTitle,
                  style: TextStyle(
                    color: entry.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                entry.item.status.replaceAll('_', ' '),
                style: TextStyle(
                  color: entry.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            entry.item.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(entry.item.subtitle),
          if ((entry.item.amount?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 8),
            Text(
              entry.item.amount!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          if (canAdvance) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isBusy ? null : onAdvance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: entry.color,
                  foregroundColor: Colors.white,
                ),
                child: Text(isBusy ? 'Updating...' : actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyStoreState extends StatelessWidget {
  const _EmptyStoreState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: const Text(
        'No store sections are connected yet. Match the business name to a real store, restaurant, or pharmacy listing to start managing it here.',
      ),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  final bool compact;

  const _EmptyOrdersState({this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: compact ? null : Border.all(color: Colors.black12),
      ),
      child: const Text(
        'No live orders right now. New shopping, food, and pharmacy orders will appear here.',
      ),
    );
  }
}

class _RecentOrderEntry {
  final String module;
  final String moduleTitle;
  final Color color;
  final ProDashboardItem item;

  const _RecentOrderEntry({
    required this.module,
    required this.moduleTitle,
    required this.color,
    required this.item,
  });
}
