import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const ProviderDashboardScreen({super.key, required this.profile});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  late Future<ProDashboardData> _dashboardFuture;
  final Set<String> _busyItemIds = <String>{};

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant ProviderDashboardScreen oldWidget) {
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

  Future<void> _openSchedule() async {
    await context.push(ProRoutePaths.providerSchedule);
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _openAvailability() async {
    await context.push(ProRoutePaths.providerAvailability);
    if (!mounted) return;
    await _refreshDashboard();
  }

  int _moduleRequestCount(ProDashboardModuleSummary summary) {
    for (final metric in summary.metrics) {
      final lower = metric.toLowerCase();
      if (!lower.contains('order') &&
          !lower.contains('job') &&
          !lower.contains('request')) {
        continue;
      }
      final match = RegExp(r'\d+').firstMatch(metric);
      final parsed = int.tryParse(match?.group(0) ?? '');
      if (parsed != null) return parsed;
    }
    return summary.recentItems.length;
  }

  int _totalRequests(List<ProDashboardModuleSummary> summaries) {
    return summaries.fold<int>(
      0,
      (sum, summary) => sum + _moduleRequestCount(summary),
    );
  }

  int _actionableRequests(List<ProDashboardModuleSummary> summaries) {
    return summaries.fold<int>(0, (sum, summary) {
      final actionable = summary.recentItems.where(
        (item) => _nextProviderStatus(summary.module, item.status) != null,
      );
      return sum + actionable.length;
    });
  }

  String? _nextProviderStatus(String module, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'CONFIRMED';
      case 'CONFIRMED':
        return module == 'laundry' ? 'PROCESSING' : 'IN_PROGRESS';
      case 'PROCESSING':
        return module == 'laundry' ? 'DISPATCHED' : 'COMPLETED';
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  String _providerActionLabel(String module, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Accept';
      case 'CONFIRMED':
        return module == 'laundry' ? 'Start Cleaning' : 'Start Job';
      case 'PROCESSING':
        return module == 'laundry' ? 'Send Out' : 'Complete';
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return 'Complete';
      default:
        return 'Done';
    }
  }

  Future<void> _advanceProviderOrder(
    ProDashboardModuleSummary summary,
    ProDashboardItem item,
  ) async {
    final nextStatus = _nextProviderStatus(summary.module, item.status);
    if (nextStatus == null) return;

    setState(() => _busyItemIds.add(item.id));
    try {
      await ApiClient.post(
        '/pro/${widget.profile.userId}/provider-order-status',
        {'orderId': item.id, 'status': nextStatus},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request updated to ${nextStatus.replaceAll('_', ' ')}.',
          ),
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
        setState(() => _busyItemIds.remove(item.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeModules = widget.profile.activeModules
        .where(
          (module) => {ProModule.services, ProModule.laundry}.contains(module),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.profile.businessName),
        elevation: 0,
        backgroundColor: AppColors.homeServices,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule_outlined),
            onPressed: _openSchedule,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openAvailability,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
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
          final totalRequests = _totalRequests(summaries);
          final actionable = _actionableRequests(summaries);

          if (snapshot.connectionState == ConnectionState.waiting &&
              data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.all(ProDesignSystem.spacing16),
              children: [
                _ProviderPipelineHero(
                  businessName: widget.profile.businessName,
                  headline: data?.headline,
                  modules: activeModules,
                  onOpenSchedule: _openSchedule,
                  onOpenAvailability: _openAvailability,
                ),
                if (data?.scopeNote?.isNotEmpty == true) ...[
                  const SizedBox(height: ProDesignSystem.spacing16),
                  _ScopeNote(message: data!.scopeNote!),
                ],
                const SizedBox(height: ProDesignSystem.spacing16),
                _ProviderSnapshotStrip(
                  totalRequests: totalRequests,
                  actionable: actionable,
                  activePipelines: activeModules.length,
                ),
                const SizedBox(height: ProDesignSystem.spacing20),
                Text(
                  'Pipeline Workboard',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: ProDesignSystem.spacing12),
                if (summaries.isNotEmpty)
                  ...summaries.map(_buildSummaryCard)
                else
                  const _FallbackProviderState(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ProDashboardModuleSummary summary) {
    final module = summary.module == 'laundry'
        ? ProModule.laundry
        : ProModule.services;
    final color = ProModuleHelper.getModuleColor(module);

    return Padding(
      padding: const EdgeInsets.only(bottom: ProDesignSystem.spacing12),
      child: ModernCard(
        backgroundColor: Colors.white,
        borderRadius: ProDesignSystem.radiusLarge,
        shadows: ProDesignSystem.shadowElevation2,
        padding: const EdgeInsets.all(ProDesignSystem.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ProDesignSystem.spacing8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(
                      ProDesignSystem.radiusSmall,
                    ),
                  ),
                  child: Icon(
                    ProModuleHelper.getModuleIcon(module),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: ProDesignSystem.spacing12),
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
                      const SizedBox(height: ProDesignSystem.spacing4),
                      Text(
                        summary.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: ProDesignSystem.spacing12),
            Wrap(
              spacing: ProDesignSystem.spacing8,
              runSpacing: ProDesignSystem.spacing8,
              children: summary.metrics
                  .map(
                    (metric) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ProDesignSystem.spacing12,
                        vertical: ProDesignSystem.spacing6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          ProDesignSystem.radiusMedium,
                        ),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        metric,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (summary.recentItems.isNotEmpty) ...[
              const SizedBox(height: ProDesignSystem.spacing12),
              ...summary.recentItems
                  .take(2)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: ProDesignSystem.spacing8,
                      ),
                      child: ModernCard(
                        backgroundColor: color.withValues(alpha: 0.06),
                        borderRadius: ProDesignSystem.radiusMedium,
                        padding: const EdgeInsets.all(
                          ProDesignSystem.spacing12,
                        ),
                        shadows: const [],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: ProDesignSystem.spacing4,
                                      ),
                                      Text(
                                        '${item.subtitle}${item.amount == null || item.amount!.isEmpty ? '' : ' • ${item.amount}'}',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: ProDesignSystem.spacing8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ProDesignSystem.spacing8,
                                    vertical: ProDesignSystem.spacing4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      ProDesignSystem.radiusSmall,
                                    ),
                                  ),
                                  child: Text(
                                    item.status.replaceAll('_', ' '),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (_nextProviderStatus(
                                      summary.module,
                                      item.status,
                                    ) !=
                                    null)
                                  ElevatedButton(
                                    onPressed: _busyItemIds.contains(item.id)
                                        ? null
                                        : () => _advanceProviderOrder(
                                            summary,
                                            item,
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          ProDesignSystem.radiusSmall,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: ProDesignSystem.spacing12,
                                        vertical: ProDesignSystem.spacing6,
                                      ),
                                    ),
                                    child: Text(
                                      _busyItemIds.contains(item.id)
                                          ? 'Updating...'
                                          : _providerActionLabel(
                                              summary.module,
                                              item.status,
                                            ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
            const SizedBox(height: ProDesignSystem.spacing16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push(ProRoutePaths.inbox),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Inbox'),
                ),
                const SizedBox(width: ProDesignSystem.spacing12),
                ElevatedButton(
                  onPressed: () {
                    context.push(
                      '${ProRoutePaths.providerQueue}?module=${summary.module}',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(summary.actionLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

class _ProviderPipelineHero extends StatelessWidget {
  final String businessName;
  final String? headline;
  final List<ProModule> modules;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenAvailability;

  const _ProviderPipelineHero({
    required this.businessName,
    required this.headline,
    required this.modules,
    required this.onOpenSchedule,
    required this.onOpenAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.homeServices,
            AppColors.homeServices.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            businessName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline?.trim().isNotEmpty == true
                ? headline!
                : 'Coordinate live service and laundry pipelines.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modules
                .map(
                  (module) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ProModuleHelper.getModuleName(module),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenSchedule,
                  icon: const Icon(Icons.schedule_outlined),
                  label: const Text('Schedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenAvailability,
                  icon: const Icon(Icons.tune),
                  label: const Text('Availability'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.homeServices,
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

class _ProviderSnapshotStrip extends StatelessWidget {
  final int totalRequests;
  final int actionable;
  final int activePipelines;

  const _ProviderSnapshotStrip({
    required this.totalRequests,
    required this.actionable,
    required this.activePipelines,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SnapshotTile(
            label: 'Requests',
            value: '$totalRequests',
            color: AppColors.homeServices,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SnapshotTile(
            label: 'Actionable',
            value: '$actionable',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SnapshotTile(
            label: 'Pipelines',
            value: '$activePipelines',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SnapshotTile({
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
        borderRadius: BorderRadius.circular(12),
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

class _FallbackProviderState extends StatelessWidget {
  const _FallbackProviderState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Live provider summaries will appear here when data is available.',
        ),
      ),
    );
  }
}
