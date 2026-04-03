import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/widgets/pro_drawer.dart';
import '../../../core/widgets/pro_stat_card.dart';
import 'delivery_queue_screen.dart';
import '../../rider/screens/rider_active_delivery_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const DeliveryDashboardScreen({super.key, required this.profile});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
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
      setState(() {
        _dashboardFuture = _loadDashboard();
      });
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
      setState(() {
        _dashboardFuture = _loadDashboard();
      });
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

  @override
  Widget build(BuildContext context) {
    final isOnline =
        context.watch<ProAuthProvider>().currentProfile?.isOnline ??
        widget.profile.isOnline;
    final activeModules = widget.profile.activeModules
        .where((module) => {
              ProModule.shoppingDelivery,
              ProModule.foodDelivery,
              ProModule.pharmacyDelivery,
            }.contains(module))
        .toList(growable: false);

    return Scaffold(
      drawer: const ProDrawer(),
      appBar: AppBar(
        title: Text('Delivery: ${widget.profile.businessName}'),
        elevation: 0,
        backgroundColor: AppColors.food,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DeliveryQueueScreen(
                    userId: widget.profile.userId,
                    businessName: widget.profile.businessName,
                  ),
                ),
              );
            },
          ),
          Switch(
            value: isOnline,
            activeThumbColor: Colors.greenAccent,
            onChanged: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              final proAuth = context.read<ProAuthProvider>();
              try {
                await proAuth.updateOnlineStatus(value);
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
          final highlight = data?.highlightedRequest;

          if (snapshot.connectionState == ConnectionState.waiting && data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.food, AppColors.food.withValues(alpha: 0.78)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.route_rounded, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline
                                  ? 'Delivery dispatch is live'
                                  : 'Delivery is offline',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isOnline
                                  ? 'Shopping, food, and pharmacy requests arrive in one queue.'
                                  : 'Switch back online to claim shopping, food, and pharmacy jobs.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(0)?.title ?? 'Active Requests',
                        value: stats.elementAtOrNull(0)?.value ?? '7',
                        icon: Icons.local_shipping_outlined,
                        color: AppColors.food,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(1)?.title ?? 'Modules Enabled',
                        value: stats.elementAtOrNull(1)?.value ?? '${activeModules.length}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(2)?.title ?? 'Dispatch Lanes',
                        value: stats.elementAtOrNull(2)?.value ?? '${activeModules.length}',
                        icon: Icons.account_tree_outlined,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(3)?.title ?? 'Coverage Zones',
                        value: stats.elementAtOrNull(3)?.value ?? '3',
                        icon: Icons.map_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Dispatch Queue',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (highlight != null)
                  _HighlightCard(
                    highlight: highlight,
                    isBusy: _isClaiming || !isOnline,
                    onAccept: () => _claimDelivery(highlight),
                    buttonLabel: isOnline ? highlight.ctaLabel : 'Offline',
                  ),
                if (data?.moduleSummaries.isNotEmpty == true)
                  ...data!.moduleSummaries.map(
                    (summary) => _SummaryCard(summary: summary),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DeliveryQueueScreen(
                          userId: widget.profile.userId,
                          businessName: widget.profile.businessName,
                        ),
                      ),
                    );
                  },
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

class _SummaryCard extends StatelessWidget {
  final ProDashboardModuleSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(summary.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(summary.subtitle),
            const SizedBox(height: 12),
            ...summary.metrics.map(
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
}

class _HighlightCard extends StatelessWidget {
  final ProDashboardHighlight highlight;
  final bool isBusy;
  final VoidCallback onAccept;
  final String buttonLabel;

  const _HighlightCard({
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(highlight.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  highlight.amount ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            ...highlight.lines.where((line) => line.isNotEmpty).map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right_alt, color: AppColors.food),
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
                child: Text(
                  isBusy && !isOffline ? 'Claiming...' : buttonLabel,
                ),
              ),
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

extension<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
