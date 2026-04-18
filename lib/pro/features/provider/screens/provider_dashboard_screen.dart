import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
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
  late Future<_ProviderDashboardViewData> _viewFuture;
  final Set<String> _busyItemIds = <String>{};
  bool _isUpdatingOnline = false;

  @override
  void initState() {
    super.initState();
    _viewFuture = _loadViewData();
  }

  @override
  void didUpdateWidget(covariant ProviderDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.userId != widget.profile.userId) {
      _viewFuture = _loadViewData();
    }
  }

  Future<_ProviderDashboardViewData> _loadViewData() async {
    final dashboardResponse = Map<String, dynamic>.from(
      await ApiClient.get(
            '/pro/${widget.profile.userId}/dashboard',
            forceRefresh: true,
          )
          as Map,
    );
    final settingsResponse = await ApiClient.get(
      '/pro/${widget.profile.userId}/provider-settings',
      forceRefresh: true,
    );
    final availabilityResponse = Map<String, dynamic>.from(
      await ApiClient.get(
            '/pro/${widget.profile.userId}/provider-availability',
            forceRefresh: true,
          )
          as Map,
    );
    return _ProviderDashboardViewData(
      dashboard: ProDashboardData.fromJson(dashboardResponse),
      setup: _ProviderSetupState.fromApi(
        settings: (settingsResponse as List<dynamic>)
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList(growable: false),
        availability: availabilityResponse,
        activeModules: widget.profile.activeModules,
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    final future = _loadViewData();
    setState(() {
      _viewFuture = future;
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

  Future<void> _setOnlineStatus(bool isOnline) async {
    if (_isUpdatingOnline) return;
    setState(() => _isUpdatingOnline = true);
    try {
      await context.read<ProAuthProvider>().updateOnlineStatus(isOnline);
      if (!mounted) return;
      await _refreshDashboard();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOnline
                ? 'You are now live and can receive nearby bookings.'
                : 'You are now offline.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingOnline = false);
      }
    }
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
    final normalizedStatus = status.toUpperCase();
    if (module == 'services') {
      switch (normalizedStatus) {
        case 'PENDING':
          return 'CONFIRMED';
        case 'CONFIRMED':
        case 'PROCESSING':
          return 'DISPATCHED';
        case 'DISPATCHED':
        case 'IN_PROGRESS':
          return 'COMPLETED';
        default:
          return null;
      }
    }
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'CONFIRMED';
      case 'CONFIRMED':
        return 'PROCESSING';
      case 'PROCESSING':
        return 'DISPATCHED';
      case 'DISPATCHED':
        return 'IN_PROGRESS';
      case 'IN_PROGRESS':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  String _providerActionLabel(String module, String status) {
    final normalizedStatus = status.toUpperCase();
    if (module == 'services') {
      switch (normalizedStatus) {
        case 'PENDING':
          return 'Confirm';
        case 'CONFIRMED':
        case 'PROCESSING':
          return 'On the way';
        case 'DISPATCHED':
        case 'IN_PROGRESS':
          return 'Work done';
        default:
          return 'Done';
      }
    }
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Accept';
      case 'CONFIRMED':
        return 'Start Cleaning';
      case 'PROCESSING':
        return 'Send Out';
      case 'DISPATCHED':
        return 'Start Delivery';
      case 'IN_PROGRESS':
        return 'Complete';
      default:
        return 'Done';
    }
  }

  String _providerStatusLabel(String module, String status) {
    final normalizedStatus = status.toUpperCase();
    if (module == 'services') {
      switch (normalizedStatus) {
        case 'PENDING':
          return 'Pending';
        case 'CONFIRMED':
          return 'Confirmed';
        case 'PROCESSING':
        case 'DISPATCHED':
          return 'On the way';
        case 'IN_PROGRESS':
          return 'Work in progress';
        case 'COMPLETED':
          return 'Work done';
        default:
          return normalizedStatus.replaceAll('_', ' ');
      }
    }
    return normalizedStatus.replaceAll('_', ' ');
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
    final onlineState =
        context.watch<ProAuthProvider>().currentProfile?.isOnline ??
        widget.profile.isOnline;
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
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSchedule,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push(ProRoutePaths.inbox),
          ),
        ],
      ),
      body: FutureBuilder<_ProviderDashboardViewData>(
        future: _viewFuture,
        builder: (context, snapshot) {
          final data = snapshot.data?.dashboard;
          final setup = snapshot.data?.setup;
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
                if (setup != null &&
                    !setup.isReadyForLiveOperations(onlineState))
                  _ProviderSetupOnboardingCard(
                    setup: setup,
                    onlineState: onlineState,
                    isUpdatingOnline: _isUpdatingOnline,
                    onOpenAvailability: _openAvailability,
                    onOpenSchedule: _openSchedule,
                    onSetOnline: () => _setOnlineStatus(true),
                    onRefresh: _refreshDashboard,
                  )
                else ...[
                  _ProviderPipelineHero(
                    businessName: widget.profile.businessName,
                    headline: data?.headline,
                    modules: activeModules,
                    onOpenSchedule: _openSchedule,
                    onOpenAvailability: _openAvailability,
                  ),
                  const SizedBox(height: ProDesignSystem.spacing16),
                  _ProviderSnapshotStrip(
                    totalRequests: totalRequests,
                    actionable: actionable,
                    activePipelines: activeModules.length,
                  ),
                  const SizedBox(height: ProDesignSystem.spacing20),
                  Text(
                    'Pipeline Workboard',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: ProDesignSystem.spacing12),
                  if (summaries.isNotEmpty)
                    ...summaries.map(_buildSummaryCard)
                  else
                    const _FallbackProviderState(),
                ],
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
    final isServicesSummary = summary.module == 'services';
    final pendingServiceItems = summary.recentItems
        .where((item) => item.status.toUpperCase() == 'PENDING')
        .toList(growable: false);
    final color = ProModuleHelper.getModuleColor(module);
    final visibleMetrics = summary.metrics.take(3).toList(growable: false);
    final hiddenMetricCount = summary.metrics.length - visibleMetrics.length;

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
            if (isServicesSummary) ...[
              const SizedBox(height: ProDesignSystem.spacing12),
              if (pendingServiceItems.isEmpty)
                const Text(
                  'No pending bookings to accept.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                )
              else
                ...pendingServiceItems
                    .take(3)
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
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Color(0xFF374151),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: ProDesignSystem.spacing4),
                              Text(
                                '${item.subtitle}${item.amount == null || item.amount!.isEmpty ? '' : ' • ${item.amount}'}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: ProDesignSystem.spacing8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                    ),
            ] else ...[
              const SizedBox(height: ProDesignSystem.spacing12),
              Wrap(
                spacing: ProDesignSystem.spacing8,
                runSpacing: ProDesignSystem.spacing8,
                children: [
                  ...visibleMetrics.map(
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
                  ),
                  if (hiddenMetricCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ProDesignSystem.spacing12,
                        vertical: ProDesignSystem.spacing6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(
                          ProDesignSystem.radiusMedium,
                        ),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        '+$hiddenMetricCount more',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (!isServicesSummary && summary.recentItems.isNotEmpty) ...[
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
                                    _providerStatusLabel(
                                      summary.module,
                                      item.status,
                                    ),
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
                  ),
            ],
            if (!isServicesSummary) ...[
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
          ],
        ),
      ),
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
                    minimumSize: const Size.fromHeight(40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenAvailability,
                  icon: const Icon(Icons.tune),
                  label: const Text('Services'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.homeServices,
                    minimumSize: const Size.fromHeight(40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
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

class _ProviderDashboardViewData {
  final ProDashboardData dashboard;
  final _ProviderSetupState setup;

  const _ProviderDashboardViewData({
    required this.dashboard,
    required this.setup,
  });
}

class _ProviderSetupState {
  final bool supportsServices;
  final bool supportsLaundry;
  final bool hasHouseHelpListing;
  final bool hasServiceListing;
  final bool hasOfferConfigured;
  final bool hasZoneConfigured;
  final bool hasScheduleConfigured;
  final bool hasEnabledService;
  final bool hasLaundryBinding;
  final bool hasEnabledLaundry;

  const _ProviderSetupState({
    required this.supportsServices,
    required this.supportsLaundry,
    required this.hasHouseHelpListing,
    required this.hasServiceListing,
    required this.hasOfferConfigured,
    required this.hasZoneConfigured,
    required this.hasScheduleConfigured,
    required this.hasEnabledService,
    required this.hasLaundryBinding,
    required this.hasEnabledLaundry,
  });

  factory _ProviderSetupState.fromApi({
    required List<Map<String, dynamic>> settings,
    required Map<String, dynamic> availability,
    required List<ProModule> activeModules,
  }) {
    final supportsServices =
        activeModules.isEmpty || activeModules.contains(ProModule.services);
    final supportsLaundry = activeModules.contains(ProModule.laundry);
    final hasServiceListing = settings.isNotEmpty;
    final hasHouseHelpListing = settings.any(
      (setting) => _isHouseHelpCategorySlug(setting['categorySlug']),
    );
    final hasOfferConfigured = !supportsServices
        ? true
        : settings.any((setting) => _isServiceOfferConfigured(setting));
    final hasZoneConfigured = !supportsServices
        ? true
        : !hasHouseHelpListing
        ? true
        : settings.any((setting) => _hasValidServiceZone(setting));
    final hasScheduleConfigured = !supportsServices
        ? true
        : settings.any((setting) => _hasCompleteSchedule(setting));
    final servicesAvailability =
        (availability['services'] as List<dynamic>? ?? const <dynamic>[])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList(growable: false);
    final laundryAvailability =
        (availability['laundry'] as List<dynamic>? ?? const <dynamic>[])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList(growable: false);
    final hasEnabledService = servicesAvailability.any(
      (item) => item['enabled'] as bool? ?? false,
    );
    final hasLaundryBinding = laundryAvailability.isNotEmpty;
    final hasEnabledLaundry = laundryAvailability.any(
      (item) => item['enabled'] as bool? ?? false,
    );

    return _ProviderSetupState(
      supportsServices: supportsServices,
      supportsLaundry: supportsLaundry,
      hasHouseHelpListing: hasHouseHelpListing,
      hasServiceListing: hasServiceListing,
      hasOfferConfigured: hasOfferConfigured,
      hasZoneConfigured: hasZoneConfigured,
      hasScheduleConfigured: hasScheduleConfigured,
      hasEnabledService: hasEnabledService,
      hasLaundryBinding: hasLaundryBinding,
      hasEnabledLaundry: hasEnabledLaundry,
    );
  }

  int completedStepCount(bool onlineState) {
    return steps(onlineState).where((step) => step.done).length;
  }

  bool isReadyForLiveOperations(bool onlineState) {
    final checklist = steps(onlineState);
    return checklist.isNotEmpty && checklist.every((step) => step.done);
  }

  List<_ProviderSetupStep> steps(bool onlineState) {
    final steps = <_ProviderSetupStep>[];

    if (supportsServices) {
      steps.add(
        _ProviderSetupStep(
          title: 'Create a service listing',
          subtitle:
              'Set up at least one service listing before receiving service requests.',
          done: hasServiceListing,
        ),
      );
      steps.add(
        _ProviderSetupStep(
          title: 'Configure service details',
          subtitle: hasHouseHelpListing
              ? 'Set offered services, booking types, shifts, home sizes, arrival, and supply modes.'
              : 'Set offered services and booking preferences.',
          done: hasOfferConfigured,
        ),
      );
      steps.add(
        _ProviderSetupStep(
          title: hasHouseHelpListing
              ? 'Configure zone and schedule'
              : 'Configure schedule',
          subtitle: hasHouseHelpListing
              ? 'Set your service-zone center/radius and weekly working schedule.'
              : 'Set your weekly working schedule for service requests.',
          done: hasZoneConfigured && hasScheduleConfigured,
        ),
      );
      steps.add(
        _ProviderSetupStep(
          title: 'Enable service intake',
          subtitle: 'Turn your service listing availability on.',
          done: hasEnabledService,
        ),
      );
    }

    if (supportsLaundry) {
      steps.add(
        _ProviderSetupStep(
          title: 'Link laundry services',
          subtitle:
              'Make sure your laundry services are linked to this provider profile.',
          done: hasLaundryBinding,
        ),
      );
      steps.add(
        _ProviderSetupStep(
          title: 'Enable laundry intake',
          subtitle: 'Turn on laundry availability to receive orders.',
          done: hasEnabledLaundry,
        ),
      );
    }

    steps.add(
      _ProviderSetupStep(
        title: 'Go online',
        subtitle: 'Switch your pro profile online to start receiving requests.',
        done: onlineState,
      ),
    );

    return steps;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

  static bool _isHouseHelpCategorySlug(dynamic slug) {
    final normalized = slug?.toString().toLowerCase().trim() ?? '';
    return normalized.contains('house-help') ||
        normalized.contains('house_help') ||
        normalized.contains('househelp') ||
        normalized == 'cleaning' ||
        normalized.contains('maid');
  }

  static bool _isServiceOfferConfigured(Map<String, dynamic> setting) {
    final services = _toStringList(setting['services']);
    if (services.isEmpty) {
      return false;
    }

    if (!_isHouseHelpCategorySlug(setting['categorySlug'])) {
      return true;
    }

    final houseHelpConfig = Map<String, dynamic>.from(
      (setting['houseHelpConfig'] as Map?) ?? const <String, dynamic>{},
    );
    return _toStringList(houseHelpConfig['bookingTypes']).isNotEmpty &&
        _toStringList(houseHelpConfig['shiftDurations']).isNotEmpty &&
        _toStringList(houseHelpConfig['homeSizes']).isNotEmpty &&
        _toStringList(houseHelpConfig['arrivalTargets']).isNotEmpty &&
        _toStringList(houseHelpConfig['supplyModes']).isNotEmpty;
  }

  static bool _hasValidServiceZone(Map<String, dynamic> setting) {
    final serviceZone = Map<String, dynamic>.from(
      (setting['serviceZone'] as Map?) ?? const <String, dynamic>{},
    );
    final zoneEnabled = serviceZone['enabled'] as bool? ?? false;
    final zoneLat = (serviceZone['centerLatitude'] as num?)?.toDouble();
    final zoneLng = (serviceZone['centerLongitude'] as num?)?.toDouble();
    final zoneRadius = (serviceZone['radiusKm'] as num?)?.toDouble();
    return zoneEnabled &&
        zoneLat != null &&
        zoneLng != null &&
        zoneRadius != null &&
        zoneRadius > 0;
  }

  static bool _hasCompleteSchedule(Map<String, dynamic> setting) {
    final availabilityHours = Map<String, dynamic>.from(
      (setting['availability'] as Map?) ?? const <String, dynamic>{},
    );
    return <String>['weekdays', 'saturday', 'sunday'].every(
      (key) => availabilityHours[key]?.toString().trim().isNotEmpty == true,
    );
  }
}

class _ProviderSetupStep {
  final String title;
  final String subtitle;
  final bool done;

  const _ProviderSetupStep({
    required this.title,
    required this.subtitle,
    required this.done,
  });
}

class _ProviderSetupOnboardingCard extends StatelessWidget {
  final _ProviderSetupState setup;
  final bool onlineState;
  final bool isUpdatingOnline;
  final Future<void> Function() onOpenAvailability;
  final Future<void> Function() onOpenSchedule;
  final Future<void> Function() onSetOnline;
  final Future<void> Function() onRefresh;

  const _ProviderSetupOnboardingCard({
    required this.setup,
    required this.onlineState,
    required this.isUpdatingOnline,
    required this.onOpenAvailability,
    required this.onOpenSchedule,
    required this.onSetOnline,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final steps = setup.steps(onlineState);
    final completed = setup.completedStepCount(onlineState);
    final total = steps.length;
    final progress = completed / total;
    final hasServicesOnly = setup.supportsServices && !setup.supportsLaundry;
    final hasLaundryOnly = setup.supportsLaundry && !setup.supportsServices;
    final cardColor = hasLaundryOnly
        ? AppColors.laundry
        : AppColors.homeServices;

    final cardTitle = hasLaundryOnly
        ? 'Complete setup before accepting laundry jobs'
        : hasServicesOnly
        ? 'Complete setup before accepting service requests'
        : 'Complete setup before accepting requests';
    final cardSubtitle = hasLaundryOnly
        ? 'Finish your laundry module setup so customers can discover and book your services.'
        : hasServicesOnly
        ? 'Finish your service module setup so nearby users can book you smoothly.'
        : 'Finish your provider modules setup so nearby users can book you smoothly.';

    VoidCallback? primaryAction;
    String primaryLabel;
    IconData primaryIcon;
    if (setup.supportsServices && !setup.hasServiceListing) {
      primaryAction = () => onOpenAvailability();
      primaryLabel = 'Create service listing';
      primaryIcon = Icons.add_business_rounded;
    } else if (setup.supportsLaundry && !setup.hasLaundryBinding) {
      primaryAction = () => onOpenAvailability();
      primaryLabel = 'Review laundry links';
      primaryIcon = Icons.local_laundry_service_rounded;
    } else if (setup.supportsServices &&
        (!setup.hasOfferConfigured ||
            !setup.hasZoneConfigured ||
            !setup.hasScheduleConfigured)) {
      primaryAction = () => onOpenSchedule();
      primaryLabel = setup.hasHouseHelpListing
          ? 'Configure service details'
          : 'Configure schedule';
      primaryIcon = Icons.tune;
    } else if ((setup.supportsServices && !setup.hasEnabledService) ||
        (setup.supportsLaundry && !setup.hasEnabledLaundry)) {
      primaryAction = () => onOpenAvailability();
      primaryLabel = 'Enable intake';
      primaryIcon = Icons.toggle_on_rounded;
    } else {
      primaryAction = isUpdatingOnline ? null : () => onSetOnline();
      primaryLabel = isUpdatingOnline ? 'Updating...' : 'Go online';
      primaryIcon = Icons.wifi_tethering_rounded;
    }

    return ModernCard(
      backgroundColor: Colors.white,
      borderRadius: ProDesignSystem.radiusLarge,
      shadows: ProDesignSystem.shadowElevation2,
      padding: const EdgeInsets.all(ProDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cardTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: ProDesignSystem.spacing6),
          Text(
            cardSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4B5563)),
          ),
          const SizedBox(height: ProDesignSystem.spacing12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                  color: cardColor,
                  backgroundColor: cardColor.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$completed/$total',
                style: TextStyle(fontWeight: FontWeight.w700, color: cardColor),
              ),
            ],
          ),
          const SizedBox(height: ProDesignSystem.spacing16),
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: ProDesignSystem.spacing8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    step.done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: step.done ? Colors.green : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ProDesignSystem.spacing8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: primaryAction,
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: cardColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => onRefresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
          if (setup.supportsServices && !setup.hasServiceListing) ...[
            const SizedBox(height: ProDesignSystem.spacing8),
            const Text(
              'Tip: open Availability, then tap the + button to create your first service listing.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
          if (setup.supportsLaundry && !setup.hasLaundryBinding) ...[
            const SizedBox(height: ProDesignSystem.spacing8),
            const Text(
              'Tip: if no laundry service appears, make sure your business name matches your laundry listing so it can be linked.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }
}
