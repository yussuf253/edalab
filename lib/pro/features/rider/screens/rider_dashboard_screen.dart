import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/utils/pro_module_helper.dart';
import 'rider_active_trip_screen.dart';
import 'rider_queue_screen.dart';

class RiderDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const RiderDashboardScreen({super.key, required this.profile});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  late Future<ProDashboardData> _dashboardFuture;
  bool _isClaiming = false;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant RiderDashboardScreen oldWidget) {
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
        builder: (_) => RiderQueueScreen(
          userId: widget.profile.userId,
          businessName: widget.profile.businessName,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _claimRide(ProDashboardHighlight highlight) async {
    if (_isClaiming || highlight.requestId.isEmpty) return;
    final isOnline =
        context.read<ProAuthProvider>().currentProfile?.isOnline ?? true;
    if (!isOnline) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.goOnlineBeforeClaimingRides)));
      return;
    }

    setState(() => _isClaiming = true);
    try {
      await ApiClient.post('/pro/${widget.profile.userId}/claim-ride', {
        'rideId': highlight.requestId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.rideRequestClaimedSuccessfully)),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RiderActiveTripScreen(
            rideId: highlight.requestId,
            userId: widget.profile.userId,
          ),
        ),
      );
      if (!mounted) return;
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotClaimRide(error.toString()))),
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

  int _summaryActiveCount(ProDashboardModuleSummary summary) {
    if (summary.recentItems.isNotEmpty) return summary.recentItems.length;
    for (final metric in summary.metrics) {
      final lower = metric.toLowerCase();
      if (!lower.contains('active') &&
          !lower.contains('pending') &&
          !lower.contains('in progress') &&
          !lower.contains('queued')) {
        continue;
      }
      final parsed = _numericValue(metric);
      if (parsed > 0) return parsed;
    }
    return 0;
  }

  int _liveTrips(List<ProDashboardModuleSummary> summaries) {
    return summaries.fold<int>(
      0,
      (sum, summary) => sum + _summaryActiveCount(summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline =
        context.watch<ProAuthProvider>().currentProfile?.isOnline ??
        widget.profile.isOnline;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.profile.businessName),
        elevation: 0,
        backgroundColor: AppColors.ride,
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

          final tripsToday = _numericValue(_metricAt(stats, 0)?.value ?? '');
          final liveRequests =
              _numericValue(_metricAt(stats, 1)?.value ?? '') > 0
              ? _numericValue(_metricAt(stats, 1)!.value)
              : _liveTrips(summaries);
          final completedToday = _numericValue(
            _metricAt(stats, 3)?.value ?? '',
          );

          if (snapshot.connectionState == ConnectionState.waiting &&
              data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _RiderShiftHero(
                  businessName: widget.profile.businessName,
                  headline: data?.headline,
                  isOnline: isOnline,
                  modules: widget.profile.activeModules,
                  onOpenQueue: _openQueue,
                  l10n: l10n,
                ),
                if (data?.scopeNote?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _ScopeNote(message: data!.scopeNote!),
                ],
                const SizedBox(height: 12),
                _RiderPerformanceStrip(
                  tripsToday: tripsToday,
                  liveRequests: liveRequests,
                  completedToday: completedToday,
                  l10n: l10n,
                ),
                if (highlight != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.nextBestTrip,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _UrgentTripCard(
                    highlight: highlight,
                    isBusy: _isClaiming || !isOnline,
                    onAccept: () => _claimRide(highlight),
                    buttonLabel: isOnline ? highlight.ctaLabel : l10n.offShift,
                    l10n: l10n,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  l10n.rideLanes,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (summaries.isNotEmpty)
                  ...summaries.map(
                    (summary) => _RiderLaneCard(summary: summary),
                  )
                else
                  _FallbackRideState(l10n: l10n),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openQueue,
                  icon: const Icon(Icons.list_alt_outlined),
                  label: Text(l10n.openFullQueueLabel),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RiderShiftHero extends StatelessWidget {
  final String businessName;
  final String? headline;
  final bool isOnline;
  final List<ProModule> modules;
  final VoidCallback onOpenQueue;
  final AppLocalizations l10n;

  const _RiderShiftHero({
    required this.businessName,
    required this.headline,
    required this.isOnline,
    required this.modules,
    required this.onOpenQueue,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.ride, AppColors.ride.withValues(alpha: 0.8)],
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
                  isOnline ? l10n.onShift : l10n.offShift,
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
                : l10n.riderDashboardSubtitle,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ProModuleHelper.getModuleIcon(module),
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ProModuleHelper.getModuleName(module),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onOpenQueue,
            icon: const Icon(Icons.alt_route),
            label: Text(l10n.openRiderQueue),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ride,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderPerformanceStrip extends StatelessWidget {
  final int tripsToday;
  final int liveRequests;
  final int completedToday;
  final AppLocalizations l10n;

  const _RiderPerformanceStrip({
    required this.tripsToday,
    required this.liveRequests,
    required this.completedToday,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PerformanceTile(
            label: l10n.trips,
            value: '$tripsToday',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PerformanceTile(
            label: l10n.live,
            value: '$liveRequests',
            color: AppColors.ride,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PerformanceTile(
            label: l10n.completedLabel,
            value: '$completedToday',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _PerformanceTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceTile({
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

class _UrgentTripCard extends StatelessWidget {
  final ProDashboardHighlight highlight;
  final bool isBusy;
  final VoidCallback onAccept;
  final String buttonLabel;
  final AppLocalizations l10n;

  const _UrgentTripCard({
    required this.highlight,
    required this.isBusy,
    required this.onAccept,
    required this.buttonLabel,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = buttonLabel == l10n.offShift;
    return Card(
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
                const Icon(Icons.local_taxi, color: AppColors.ride),
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
                          color: AppColors.ride,
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
                  backgroundColor: AppColors.ride,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: isBusy ? null : onAccept,
                child: Text(
                  isBusy && !isOffline ? l10n.claimingButtonLabel : buttonLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderLaneCard extends StatelessWidget {
  final ProDashboardModuleSummary summary;

  const _RiderLaneCard({required this.summary});

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
          ],
        ),
      ),
    );
  }
}

class _FallbackRideState extends StatelessWidget {
  final AppLocalizations l10n;

  const _FallbackRideState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.noLiveRideLanes),
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
