import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';

int _orderCountFromSummary(ProDashboardModuleSummary summary) {
  for (final metric in summary.metrics) {
    final lower = metric.toLowerCase();
    if (!lower.contains('order')) continue;
    final match = RegExp(r'\d+').firstMatch(metric);
    final parsed = int.tryParse(match?.group(0) ?? '');
    if (parsed != null) return parsed;
  }
  return summary.recentItems.length;
}

class ShopDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const ShopDashboardScreen({super.key, required this.profile});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  late Future<ProDashboardData> _dashboardFuture;

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
    await context.push(ProRoutePaths.shopCatalog);
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _openQueue({String initialModule = 'all'}) async {
    final path = initialModule == 'all'
        ? ProRoutePaths.shopQueue
        : '${ProRoutePaths.shopQueue}?module=$initialModule';
    await context.push(path);
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _openProducts() async {
    await context.push(ProRoutePaths.shopProducts);
    if (!mounted) return;
    await _refreshDashboard();
  }

  int _extractCount(
    ProDashboardModuleSummary summary, {
    bool preferAttention = false,
  }) {
    for (final metric in summary.metrics) {
      final lower = metric.toLowerCase();
      if (preferAttention && !lower.contains('attention')) continue;
      if (!preferAttention &&
          !lower.contains('order') &&
          !lower.contains('progress')) {
        continue;
      }
      final match = RegExp(r'\d+').firstMatch(metric);
      final parsed = int.tryParse(match?.group(0) ?? '');
      if (parsed != null) return parsed;
    }
    if (preferAttention) return 0;
    return summary.recentItems.length;
  }

  int _liveOrdersTotal(List<ProDashboardModuleSummary> summaries) {
    return summaries.fold<int>(
      0,
      (sum, summary) => sum + _extractCount(summary),
    );
  }

  int _attentionTotal(List<ProDashboardModuleSummary> summaries) {
    return summaries.fold<int>(
      0,
      (sum, summary) => sum + _extractCount(summary, preferAttention: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
          final summaries =
              data?.moduleSummaries ?? const <ProDashboardModuleSummary>[];
          final liveOrders = _liveOrdersTotal(summaries);
          final attention = _attentionTotal(summaries);
          final activeLanes = summaries.where((entry) {
            return _extractCount(entry) > 0 || entry.recentItems.isNotEmpty;
          }).length;

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
                const SizedBox(height: 16),
                _ShopPulseRow(
                  liveOrders: liveOrders,
                  activeLanes: activeLanes,
                  attentionCount: attention,
                ),
                const SizedBox(height: 16),
                _StoreLaneBoard(
                  summaries: summaries,
                  onOpenModule: (module) => _openQueue(initialModule: module),
                ),
                const SizedBox(height: 16),
                _RecentOrdersChipsCard(
                  summaries: summaries,
                  onOpenAll: () => _openQueue(),
                  onOpenModule: (module) => _openQueue(initialModule: module),
                  onOpenProducts: _openProducts,
                ),
                const SizedBox(height: 4),
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

class _ShopPulseRow extends StatelessWidget {
  final int liveOrders;
  final int activeLanes;
  final int attentionCount;

  const _ShopPulseRow({
    required this.liveOrders,
    required this.activeLanes,
    required this.attentionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PulseTile(
            label: 'Live',
            value: '$liveOrders',
            color: AppColors.shopping,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PulseTile(
            label: 'Lanes',
            value: '$activeLanes',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PulseTile(
            label: 'Attention',
            value: '$attentionCount',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _PulseTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PulseTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StoreLaneBoard extends StatelessWidget {
  final List<ProDashboardModuleSummary> summaries;
  final ValueChanged<String> onOpenModule;

  const _StoreLaneBoard({required this.summaries, required this.onOpenModule});

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Store Lanes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...summaries.map(
            (summary) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LaneTile(
                title: summary.title,
                subtitle: summary.subtitle,
                count: _orderCountFromSummary(summary),
                onTap: () => onOpenModule(summary.module),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaneTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  const _LaneTile({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.shopping.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.shopping.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.shopping,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersChipsCard extends StatelessWidget {
  final List<ProDashboardModuleSummary> summaries;
  final VoidCallback onOpenAll;
  final VoidCallback onOpenProducts;
  final ValueChanged<String> onOpenModule;

  const _RecentOrdersChipsCard({
    required this.summaries,
    required this.onOpenAll,
    required this.onOpenProducts,
    required this.onOpenModule,
  });

  @override
  Widget build(BuildContext context) {
    final moduleChips = summaries
        .map(
          (summary) => (
            module: summary.module,
            title: summary.title,
            count: _extractOrderCount(summary),
          ),
        )
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
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
              Text(
                'Recent Orders',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenProducts,
                child: const Text('Products'),
              ),
              TextButton(onPressed: onOpenAll, child: const Text('Open all')),
            ],
          ),
          const SizedBox(height: 8),
          if (moduleChips.isEmpty)
            const Text(
              'No active order lanes right now.',
              style: TextStyle(color: Colors.black54),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: moduleChips
                  .map(
                    (chip) => ActionChip(
                      onPressed: () => onOpenModule(chip.module),
                      avatar: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text('${chip.title} (${chip.count})'),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  int _extractOrderCount(ProDashboardModuleSummary summary) {
    return _orderCountFromSummary(summary);
  }
}
