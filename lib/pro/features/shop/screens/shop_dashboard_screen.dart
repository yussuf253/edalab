import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../l10n/app_localizations.dart';

int _parseMetricCount(String value) {
  final match = RegExp(r'\d+').firstMatch(value);
  return int.tryParse(match?.group(0) ?? '') ?? 0;
}

int _orderCountFromSummary(ProDashboardModuleSummary summary) {
  for (final metric in summary.metrics) {
    final lower = metric.toLowerCase();
    if (!lower.contains('order')) continue;
    return _parseMetricCount(metric);
  }
  return summary.recentItems.length;
}

int _completedCountFromSummary(ProDashboardModuleSummary summary) {
  for (final metric in summary.metrics) {
    if (metric.toLowerCase().contains('completed')) {
      return _parseMetricCount(metric);
    }
  }
  return 0;
}

int _attentionCountFromSummary(ProDashboardModuleSummary summary) {
  for (final metric in summary.metrics) {
    final lower = metric.toLowerCase();
    if (lower.contains('out of stock') || lower.contains('prescription-only')) {
      return _parseMetricCount(metric);
    }
  }
  return 0;
}

String _moduleLabel(String module, AppLocalizations l10n) {
  switch (module) {
    case 'food':
      return l10n.foodLabel;
    case 'pharmacy':
      return l10n.pharmacyLabel;
    default:
      return l10n.shoppingLabel;
  }
}

Color _moduleColor(String module) {
  switch (module) {
    case 'food':
      return AppColors.food;
    case 'pharmacy':
      return AppColors.pharmacy;
    default:
      return AppColors.shopping;
  }
}

String _statusLabel(String status, AppLocalizations l10n) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return l10n.pending;
    case 'CONFIRMED':
      return l10n.confirmedStatus;
    case 'PROCESSING':
      return l10n.processingStatus;
    case 'DISPATCHED':
      return l10n.dispatchedStatus;
    case 'IN_PROGRESS':
      return l10n.inProgress;
    case 'COMPLETED':
      return l10n.completedLabel;
    default:
      return status.replaceAll('_', ' ');
  }
}

DateTime _recentItemDate(ProDashboardItem item) {
  final raw = item.meta;
  if (raw == null || raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

class _ShopRecentOrderEntry {
  final String module;
  final String moduleTitle;
  final ProDashboardItem item;

  const _ShopRecentOrderEntry({
    required this.module,
    required this.moduleTitle,
    required this.item,
  });
}

class ShopDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const ShopDashboardScreen({super.key, required this.profile});

  @override
  State<ShopDashboardScreen> createState() => _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends State<ShopDashboardScreen> {
  late Future<ProDashboardData> _dashboardFuture;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

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
    setState(() => _dashboardFuture = future);
    await future;
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

  List<_ShopRecentOrderEntry> _buildRecentOrders(
    List<ProDashboardModuleSummary> summaries,
  ) {
    final entries = <_ShopRecentOrderEntry>[];
    for (final summary in summaries) {
      for (final item in summary.recentItems) {
        entries.add(
          _ShopRecentOrderEntry(
            module: summary.module,
            moduleTitle: summary.title,
            item: item,
          ),
        );
      }
    }
    entries.sort(
      (a, b) => _recentItemDate(b.item).compareTo(_recentItemDate(a.item)),
    );
    return entries.take(6).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          final liveOrders = summaries.fold<int>(
            0,
            (sum, summary) => sum + _orderCountFromSummary(summary),
          );
          final completedToday = summaries.fold<int>(
            0,
            (sum, summary) => sum + _completedCountFromSummary(summary),
          );
          final attention = summaries.fold<int>(
            0,
            (sum, summary) => sum + _attentionCountFromSummary(summary),
          );
          final recentOrders = _buildRecentOrders(summaries);

          if (snapshot.connectionState == ConnectionState.waiting &&
              data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.all(ProDesignSystem.spacing16),
              children: [
                _DashboardHero(
                  businessName: widget.profile.businessName,
                  scopeNote: data?.scopeNote,
                  onOpenOrders: () => _openQueue(),
                  onOpenProducts: _openProducts,
                  l10n: l10n,
                ),
                const SizedBox(height: ProDesignSystem.spacing20),
                _ShopPulseRow(
                  liveOrders: liveOrders,
                  completedToday: completedToday,
                  attentionCount: attention,
                  l10n: l10n,
                ),
                const SizedBox(height: ProDesignSystem.spacing20),
                _StoreManagementPanel(
                  moduleSummaries: summaries,
                  onOpenOrders: () => _openQueue(),
                  onOpenProducts: _openProducts,
                  onOpenModuleQueue: (module) =>
                      _openQueue(initialModule: module),
                  l10n: l10n,
                ),
                const SizedBox(height: ProDesignSystem.spacing20),
                _RecentOrdersListCard(
                  entries: recentOrders,
                  onOpenAll: () => _openQueue(),
                  onOpenModule: (module) => _openQueue(initialModule: module),
                  l10n: l10n,
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
  final VoidCallback onOpenProducts;
  final AppLocalizations l10n;

  const _DashboardHero({
    required this.businessName,
    required this.scopeNote,
    required this.onOpenOrders,
    required this.onOpenProducts,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      backgroundColor: AppColors.shopping,
      borderRadius: ProDesignSystem.radiusLarge,
      shadows: ProDesignSystem.shadowElevation2,
      padding: const EdgeInsets.all(ProDesignSystem.spacing20),
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
          const SizedBox(height: ProDesignSystem.spacing8),
          Text(
            l10n.shopDashboardSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          if (scopeNote?.trim().isNotEmpty == true) ...[
            const SizedBox(height: ProDesignSystem.spacing12),
            Text(
              scopeNote!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: ProDesignSystem.spacing16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onOpenOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.shopping,
                    padding: const EdgeInsets.symmetric(
                      vertical: ProDesignSystem.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusMedium,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(
                    l10n.orderQueue,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: ProDesignSystem.spacing12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenProducts,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                      vertical: ProDesignSystem.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusMedium,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: Text(
                    l10n.products,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
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
  final int completedToday;
  final int attentionCount;
  final AppLocalizations l10n;

  const _ShopPulseRow({
    required this.liveOrders,
    required this.completedToday,
    required this.attentionCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PulseTile(
            label: l10n.liveOrdersLabel,
            value: '$liveOrders',
            color: AppColors.shopping,
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: ProDesignSystem.spacing12),
        Expanded(
          child: _PulseTile(
            label: l10n.completedLabel,
            value: '$completedToday',
            color: AppColors.info,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: ProDesignSystem.spacing12),
        Expanded(
          child: _PulseTile(
            label: l10n.stockAlertsLabel,
            value: '$attentionCount',
            color: AppColors.warning,
            icon: Icons.warning_outlined,
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
  final IconData icon;

  const _PulseTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ModernStatCard(
      label: label,
      value: value,
      icon: icon,
      iconColor: color,
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

class _StoreManagementPanel extends StatelessWidget {
  final List<ProDashboardModuleSummary> moduleSummaries;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenProducts;
  final ValueChanged<String> onOpenModuleQueue;
  final AppLocalizations l10n;

  const _StoreManagementPanel({
    required this.moduleSummaries,
    required this.onOpenOrders,
    required this.onOpenProducts,
    required this.onOpenModuleQueue,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(ProDesignSystem.spacing16),
      shadows: ProDesignSystem.shadowElevation1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shopManagementTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: ProDesignSystem.spacing6),
          Text(
            l10n.shopManagementSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: ProDesignSystem.spacing16),
          Row(
            children: [
              Expanded(
                child: _ManagementActionTile(
                  title: l10n.orderQueue,
                  subtitle: l10n.handleActiveOrders,
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.shopping,
                  onTap: onOpenOrders,
                ),
              ),
              const SizedBox(width: ProDesignSystem.spacing12),
              Expanded(
                child: _ManagementActionTile(
                  title: l10n.products,
                  subtitle: l10n.updateCatalog,
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.success,
                  onTap: onOpenProducts,
                ),
              ),
            ],
          ),
          if (moduleSummaries.isNotEmpty) ...[
            const SizedBox(height: ProDesignSystem.spacing16),
            Wrap(
              spacing: ProDesignSystem.spacing8,
              runSpacing: ProDesignSystem.spacing8,
              children: moduleSummaries
                  .map(
                    (summary) => Chip(
                      avatar: Container(
                        padding: const EdgeInsets.all(ProDesignSystem.spacing4),
                        decoration: BoxDecoration(
                          color: _moduleColor(
                            summary.module,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            ProDesignSystem.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.local_offer_outlined,
                          size: 14,
                          color: _moduleColor(summary.module),
                        ),
                      ),
                      label: Text(
                        '${_moduleLabel(summary.module, l10n)} ${_orderCountFromSummary(summary)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: _moduleColor(
                        summary.module,
                      ).withValues(alpha: 0.08),
                      side: BorderSide(
                        color: _moduleColor(
                          summary.module,
                        ).withValues(alpha: 0.2),
                      ),
                      onDeleted: () => onOpenModuleQueue(summary.module),
                      deleteIcon: const SizedBox.shrink(),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManagementActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ManagementActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ModernCard(
        backgroundColor: color.withValues(alpha: 0.08),
        borderRadius: ProDesignSystem.radiusMedium,
        shadows: ProDesignSystem.shadowElevation1,
        padding: const EdgeInsets.all(ProDesignSystem.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(ProDesignSystem.spacing8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  ProDesignSystem.radiusSmall,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: ProDesignSystem.spacing8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: ProDesignSystem.spacing4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersListCard extends StatelessWidget {
  final List<_ShopRecentOrderEntry> entries;
  final VoidCallback onOpenAll;
  final ValueChanged<String> onOpenModule;
  final AppLocalizations l10n;

  const _RecentOrdersListCard({
    required this.entries,
    required this.onOpenAll,
    required this.onOpenModule,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(ProDesignSystem.spacing16),
      shadows: ProDesignSystem.shadowElevation1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.recentOrders,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenAll,
                child: Text(
                  l10n.openQueue,
                  style: const TextStyle(
                    color: Color(0xFF039D55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ProDesignSystem.spacing12),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: ProDesignSystem.spacing8,
              ),
              child: Text(
                l10n.noRecentOrders,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(
                  bottom: ProDesignSystem.spacing12,
                ),
                child: _RecentOrderTile(
                  entry: entry,
                  onTap: () => onOpenModule(entry.module),
                  l10n: l10n,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final _ShopRecentOrderEntry entry;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _RecentOrderTile({
    required this.entry,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final moduleColor = _moduleColor(entry.module);
    final statusLabel = _statusLabel(entry.item.status, l10n);
    return ModernCard(
      onTap: onTap,
      backgroundColor: const Color(0xFFFAFAFA),
      borderRadius: ProDesignSystem.radiusMedium,
      shadows: ProDesignSystem.shadowElevation1,
      padding: const EdgeInsets.all(ProDesignSystem.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: moduleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(ProDesignSystem.radiusSmall),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: moduleColor,
              size: 20,
            ),
          ),
          const SizedBox(width: ProDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing4),
                Text(
                  '${entry.moduleTitle} • ${entry.item.subtitle}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ProDesignSystem.spacing8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if ((entry.item.amount ?? '').isNotEmpty)
                Text(
                  entry.item.amount!,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              const SizedBox(height: ProDesignSystem.spacing4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ProDesignSystem.spacing8,
                  vertical: ProDesignSystem.spacing4,
                ),
                decoration: BoxDecoration(
                  color: moduleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    ProDesignSystem.radiusCircle,
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: moduleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
