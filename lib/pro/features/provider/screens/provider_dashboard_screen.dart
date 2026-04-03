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

class ProviderDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const ProviderDashboardScreen({super.key, required this.profile});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
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
      await ApiClient.post('/pro/${widget.profile.userId}/provider-order-status', {
        'orderId': item.id,
        'status': nextStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request updated to ${nextStatus.replaceAll('_', ' ')}.')),
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

  @override
  Widget build(BuildContext context) {
    final activeModules = widget.profile.activeModules
        .where((module) => {ProModule.services, ProModule.laundry}.contains(module))
        .toList(growable: false);

    return Scaffold(
      drawer: const ProDrawer(),
      appBar: AppBar(
        title: Text(widget.profile.businessName),
        elevation: 0,
        backgroundColor: AppColors.homeServices,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule_outlined),
            onPressed: () async {
              await context.push(ProRoutePaths.providerSchedule);
              if (!mounted) return;
              await _refreshDashboard();
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await context.push(ProRoutePaths.providerAvailability);
              if (!mounted) return;
              await _refreshDashboard();
            },
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
          final stats = data?.stats ?? const <ProDashboardMetric>[];

          if (snapshot.connectionState == ConnectionState.waiting && data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data?.headline.isNotEmpty == true ? data!.headline : 'Provider Operations',
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
                        title: stats.elementAtOrNull(0)?.title ?? 'Upcoming Jobs',
                        value: stats.elementAtOrNull(0)?.value ?? '8',
                        icon: Icons.event_available,
                        color: AppColors.homeServices,
                        trend: stats.elementAtOrNull(0)?.trend,
                        isUp: stats.elementAtOrNull(0)?.isUp ?? true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(1)?.title ?? 'Completed Today',
                        value: stats.elementAtOrNull(1)?.value ?? '5',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                        trend: stats.elementAtOrNull(1)?.trend,
                        isUp: stats.elementAtOrNull(1)?.isUp ?? true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(2)?.title ?? 'Active Pipelines',
                        value: stats.elementAtOrNull(2)?.value ?? '${activeModules.length}',
                        icon: Icons.groups_2_outlined,
                        color: AppColors.info,
                        trend: stats.elementAtOrNull(2)?.trend,
                        isUp: stats.elementAtOrNull(2)?.isUp ?? true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(3)?.title ?? 'Service Modules',
                        value: stats.elementAtOrNull(3)?.value ?? '${activeModules.length}',
                        icon: Icons.schedule_outlined,
                        color: AppColors.warning,
                        trend: stats.elementAtOrNull(3)?.trend,
                        isUp: stats.elementAtOrNull(3)?.isUp ?? true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Module Pipelines',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (data?.moduleSummaries.isNotEmpty == true)
                  ...data!.moduleSummaries.map(_buildSummaryCard)
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
    final module = summary.module == 'laundry' ? ProModule.laundry : ProModule.services;
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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      Text('${item.subtitle}${item.amount == null || item.amount!.isEmpty ? '' : ' • ${item.amount}'}'),
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
                          if (_nextProviderStatus(summary.module, item.status) != null)
                            ElevatedButton(
                              onPressed: _busyItemIds.contains(item.id)
                                  ? null
                                  : () => _advanceProviderOrder(summary, item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                _busyItemIds.contains(item.id)
                                    ? 'Updating...'
                                    : _providerActionLabel(summary.module, item.status),
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
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push(ProRoutePaths.inbox),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Inbox'),
                ),
                const SizedBox(width: 12),
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

class _FallbackProviderState extends StatelessWidget {
  const _FallbackProviderState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Live provider summaries will appear here when data is available.'),
      ),
    );
  }
}

extension<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
