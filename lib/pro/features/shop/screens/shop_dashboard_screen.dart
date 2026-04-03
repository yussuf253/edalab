import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/widgets/pro_drawer.dart';
import '../../../core/widgets/pro_stat_card.dart';
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
        return 'Start Prep';
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

    setState(() => _busyItemIds.add(item.id));
    try {
      await ApiClient.post('/pro/${widget.profile.userId}/shop-order-status', {
        'orderId': item.id,
        'status': nextStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order updated to ${nextStatus.replaceAll('_', ' ')}.')),
      );
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyItemIds.remove(item.id));
      }
    }
  }

  List<ProDashboardMetric> get _fallbackStats => const [
    ProDashboardMetric(
      key: 'modules',
      title: 'Live Modules',
      value: '3',
      trend: 'Enabled for this profile',
    ),
    ProDashboardMetric(
      key: 'pending',
      title: 'Pending Orders',
      value: '26',
    ),
    ProDashboardMetric(
      key: 'entities',
      title: 'Workstreams',
      value: '3',
    ),
    ProDashboardMetric(
      key: 'alerts',
      title: 'Attention Items',
      value: '5',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeModules = widget.profile.activeModules
        .where(
          (module) => {
            ProModule.shopping,
            ProModule.food,
            ProModule.pharmacy,
          }.contains(module),
        )
        .toList(growable: false);

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
          final stats = data?.stats.isNotEmpty == true ? data!.stats : _fallbackStats;
          final moduleSummaries = data?.moduleSummaries ?? const <ProDashboardModuleSummary>[];

          if (snapshot.connectionState == ConnectionState.waiting && data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data?.headline.isNotEmpty == true ? data!.headline : 'Store Operations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: activeModules.map((module) {
                    final color = ProModuleHelper.getModuleColor(module);
                    return Chip(
                      avatar: Icon(
                        ProModuleHelper.getModuleIcon(module),
                        size: 18,
                        color: color,
                      ),
                      label: Text(ProModuleHelper.getModuleName(module)),
                      backgroundColor: color.withValues(alpha: 0.10),
                    );
                  }).toList(),
                ),
                if (data?.scopeNote?.isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _ScopeNote(message: data!.scopeNote!),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats[0].title,
                        value: stats[0].value,
                        icon: Icons.dashboard_customize_outlined,
                        color: AppColors.shopping,
                        trend: stats[0].trend,
                        isUp: stats[0].isUp,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats[1].title,
                        value: stats[1].value,
                        icon: Icons.shopping_bag_outlined,
                        color: Colors.orange,
                        trend: stats[1].trend,
                        isUp: stats[1].isUp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats[2].title,
                        value: stats[2].value,
                        icon: Icons.storefront_outlined,
                        color: Colors.blue,
                        trend: stats[2].trend,
                        isUp: stats[2].isUp,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats[3].title,
                        value: stats[3].value,
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                        trend: stats[3].trend,
                        isUp: stats[3].isUp,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Module Workstreams',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (moduleSummaries.isNotEmpty)
                  ...moduleSummaries.map(_buildModuleCard)
                else
                  ..._fallbackCards().map(_buildFallbackCard),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
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
        },
        icon: const Icon(Icons.tune),
        label: const Text('Manage Availability'),
      ),
    );
  }

  Widget _buildModuleCard(ProDashboardModuleSummary summary) {
    final module = _moduleFromSummary(summary.module);
    final color = ProModuleHelper.getModuleColor(module);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(summary.subtitle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...summary.metrics.map(
              (metric) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(metric),
              ),
            ),
            if (summary.recentItems.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Recent activity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...summary.recentItems.take(2).map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(item.subtitle),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.status.replaceAll('_', ' '),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_nextShopStatus(item.status) != null)
                            ElevatedButton(
                              onPressed: _busyItemIds.contains(item.id)
                                  ? null
                                  : () => _advanceOrderStatus(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                _busyItemIds.contains(item.id)
                                    ? 'Updating...'
                                    : _statusActionLabel(item.status),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ShopOrdersQueueScreen(
                        userId: widget.profile.userId,
                        businessName: widget.profile.businessName,
                        initialModule: summary.module,
                      ),
                    ),
                  );
                },
                child: Text(summary.actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_FallbackCard> _fallbackCards() {
    return const [
      _FallbackCard(
        title: 'Shopping Store',
        subtitle: 'Manage retail catalog and customer orders.',
        metrics: [
          '124 live items',
          '8 low-stock products',
          '14 pending orders',
        ],
      ),
      _FallbackCard(
        title: 'Food Store',
        subtitle: 'Handle menu prep, kitchen queue, and delivery timing.',
        metrics: [
          '36 menu items',
          '9 orders in prep',
          '18 min average prep time',
        ],
      ),
      _FallbackCard(
        title: 'Pharmacy Store',
        subtitle: 'Review medicines, fulfillment, and prescription-sensitive orders.',
        metrics: [
          '82 listed medicines',
          '4 prescription reviews',
          '6 urgent orders',
        ],
      ),
    ];
  }

  Widget _buildFallbackCard(_FallbackCard card) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(card.subtitle),
            const SizedBox(height: 12),
            ...card.metrics.map(
              (metric) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(metric),
              ),
            ),
          ],
        ),
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

class _ScopeNote extends StatelessWidget {
  final String message;

  const _ScopeNote({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}

class _FallbackCard {
  final String title;
  final String subtitle;
  final List<String> metrics;

  const _FallbackCard({
    required this.title,
    required this.subtitle,
    required this.metrics,
  });
}
