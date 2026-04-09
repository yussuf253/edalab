import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../rider/screens/rider_active_delivery_screen.dart';
import 'delivery_queue_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const DeliveryDashboardScreen({super.key, required this.profile});

  @override
  State<DeliveryDashboardScreen> createState() =>
      _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  late Future<ProDashboardData> _dashboardFuture;
  bool _isClaiming = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant DeliveryDashboardScreen oldWidget) {
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

  Future<void> _openQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeliveryQueueScreen(
          userId: widget.profile.userId,
          businessName: widget.profile.businessName,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _claimDelivery(ProDashboardHighlight highlight) async {
    if (_isClaiming || highlight.requestId.isEmpty) return;
    final isOnline =
        context.read<ProAuthProvider>().currentProfile?.isOnline ?? true;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Go online before claiming deliveries.')),
      );
      return;
    }

    setState(() => _isClaiming = true);
    try {
      await ApiClient.post('/pro/${widget.profile.userId}/claim-delivery', {
        'orderId': highlight.requestId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery request claimed successfully.')),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RiderActiveDeliveryScreen(
            orderId: highlight.requestId,
            userId: widget.profile.userId,
          ),
        ),
      );
      if (!mounted) return;
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not claim delivery: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  int _numericValue(String input) {
    final match = RegExp(r'\d+').firstMatch(input.replaceAll(',', ''));
    return int.tryParse(match?.group(0) ?? '') ?? 0;
  }

  ProDashboardMetric? _metricAt(List<ProDashboardMetric> stats, int index) {
    if (index < 0 || index >= stats.length) return null;
    return stats[index];
  }

  int _laneItemCount(ProDashboardModuleSummary summary) {
    if (summary.recentItems.isNotEmpty) return summary.recentItems.length;
    for (final metric in summary.metrics) {
      final lower = metric.toLowerCase();
      if (!lower.contains('pending') &&
          !lower.contains('active') &&
          !lower.contains('queued') &&
          !lower.contains('in progress')) {
        continue;
      }
      final parsed = _numericValue(metric);
      if (parsed > 0) return parsed;
    }
    return 0;
  }

  int _totalLaneItems(List<ProDashboardModuleSummary> summaries) {
    return summaries.fold<int>(
      0,
      (sum, summary) => sum + _laneItemCount(summary),
    );
  }

  int _urgentItems(List<ProDashboardModuleSummary> summaries) {
    return summaries.fold<int>(0, (sum, summary) {
      final urgent = summary.recentItems.where(
        (item) => item.status.toUpperCase().contains('PENDING'),
      );
      return sum + urgent.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnline =
        context.watch<ProAuthProvider>().currentProfile?.isOnline ??
        widget.profile.isOnline;
    final activeModules = widget.profile.activeModules
        .where(
          (module) => {
            ProModule.shoppingDelivery,
            ProModule.foodDelivery,
            ProModule.pharmacyDelivery,
          }.contains(module),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.profile.businessName),
        elevation: 0,
        backgroundColor: AppColors.food,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: _openQueue,
          ),
          Switch(
            value: isOnline,
            activeThumbColor: Colors.greenAccent,
            onChanged: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              final proAuth = context.read<ProAuthProvider>();
              try {
                await proAuth.updateOnlineStatus(value);
                if (!mounted) return;
                await _refreshDashboard();
              } catch (error) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<ProDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final stats = data?.stats ?? const <ProDashboardMetric>[];
          final summaries =
              data?.moduleSummaries ?? const <ProDashboardModuleSummary>[];
          final highlight = data?.highlightedRequest;

          final activeRequests =
              _numericValue(_metricAt(stats, 0)?.value ?? '') > 0
              ? _numericValue(_metricAt(stats, 0)!.value)
              : _totalLaneItems(summaries);
          final hotJobs = _numericValue(_metricAt(stats, 1)?.value ?? '') > 0
              ? _numericValue(_metricAt(stats, 1)!.value)
              : _urgentItems(summaries);
          final coverage = _numericValue(_metricAt(stats, 2)?.value ?? '') > 0
              ? _numericValue(_metricAt(stats, 2)!.value)
              : activeModules.length;

          if (snapshot.connectionState == ConnectionState.waiting &&
              data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DeliveryDispatchHero(
                  businessName: widget.profile.businessName,
                  headline: data?.headline,
                  isOnline: isOnline,
                  modules: activeModules,
                  onOpenQueue: _openQueue,
                ),
                if (data?.scopeNote?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _ScopeNote(message: data!.scopeNote!),
                ],
                const SizedBox(height: 12),
                _DeliverySnapshotStrip(
                  activeRequests: activeRequests,
                  hotJobs: hotJobs,
                  coverageZones: coverage,
                ),
                if (highlight != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Priority Dispatch',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PriorityDispatchCard(
                    highlight: highlight,
                    isBusy: _isClaiming || !isOnline,
                    onAccept: () => _claimDelivery(highlight),
                    buttonLabel: isOnline ? highlight.ctaLabel : 'Offline',
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Dispatch Lanes',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (summaries.isNotEmpty)
                  ...summaries.map(
                    (summary) => _DeliveryLaneCard(
                      summary: summary,
                      onOpenLane: _openQueue,
                    ),
                  )
                else
                  const _FallbackDispatchState(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openQueue,
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('Open Full Queue'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeliveryDispatchHero extends StatelessWidget {
  final String businessName;
  final String? headline;
  final bool isOnline;
  final List<ProModule> modules;
  final VoidCallback onOpenQueue;

  const _DeliveryDispatchHero({
    required this.businessName,
    required this.headline,
    required this.isOnline,
    required this.modules,
    required this.onOpenQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.food, AppColors.food.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  businessName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.greenAccent.withValues(alpha: 0.2)
                      : Colors.black26,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            headline?.trim().isNotEmpty == true
                ? headline!
                : 'Run shopping, food, and pharmacy dispatch from one board.',
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
                      color: Colors.white.withValues(alpha: 0.16),
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
          FilledButton.icon(
            onPressed: onOpenQueue,
            icon: const Icon(Icons.route_outlined),
            label: const Text('Open Dispatch Queue'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.food,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverySnapshotStrip extends StatelessWidget {
  final int activeRequests;
  final int hotJobs;
  final int coverageZones;

  const _DeliverySnapshotStrip({
    required this.activeRequests,
    required this.hotJobs,
    required this.coverageZones,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SnapshotPill(
            label: 'Active',
            value: '$activeRequests',
            color: AppColors.food,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SnapshotPill(
            label: 'Urgent',
            value: '$hotJobs',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SnapshotPill(
            label: 'Zones',
            value: '$coverageZones',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _SnapshotPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SnapshotPill({
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
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DeliveryLaneCard extends StatelessWidget {
  final ProDashboardModuleSummary summary;
  final VoidCallback onOpenLane;

  const _DeliveryLaneCard({required this.summary, required this.onOpenLane});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(summary.subtitle),
            if (summary.metrics.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...summary.metrics
                  .take(3)
                  .map(
                    (metric) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(metric),
                    ),
                  ),
            ],
            if (summary.recentItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.recentItems
                    .take(2)
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.food.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${item.title} • ${item.status.replaceAll('_', ' ')}',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onOpenLane,
              icon: const Icon(Icons.arrow_forward),
              label: Text(summary.actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.food,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityDispatchCard extends StatelessWidget {
  final ProDashboardHighlight highlight;
  final bool isBusy;
  final VoidCallback onAccept;
  final String buttonLabel;

  const _PriorityDispatchCard({
    required this.highlight,
    required this.isBusy,
    required this.onAccept,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = buttonLabel == 'Offline';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    highlight.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  highlight.amount ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...highlight.lines
                .where((line) => line.isNotEmpty)
                .map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_right_alt,
                          color: AppColors.food,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(line)),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.food,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isBusy ? null : onAccept,
                child: Text(isBusy && !isOffline ? 'Claiming...' : buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackDispatchState extends StatelessWidget {
  const _FallbackDispatchState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No active dispatch lanes yet. New requests will appear here.',
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
