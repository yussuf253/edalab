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

  Future<void> _claimRide(ProDashboardHighlight highlight) async {
    if (_isClaiming || highlight.requestId.isEmpty) return;
    final isOnline =
        context.read<ProAuthProvider>().currentProfile?.isOnline ?? true;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Go online before claiming rides.')),
      );
      return;
    }

    setState(() => _isClaiming = true);
    try {
      await ApiClient.post('/pro/${widget.profile.userId}/claim-ride', {
        'rideId': highlight.requestId,
      });
      if (!mounted) return;
      setState(() {
        _dashboardFuture = _loadDashboard();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride request claimed successfully.')),
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
      setState(() {
        _dashboardFuture = _loadDashboard();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not claim ride: $error')),
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
    return Scaffold(
      drawer: const ProDrawer(),
      appBar: AppBar(
        title: Text('Rider: ${widget.profile.businessName}'),
        elevation: 0,
        backgroundColor: AppColors.ride,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RiderQueueScreen(
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
                Wrap(
                  spacing: 8,
                  children: widget.profile.activeModules.map((module) {
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.ride, AppColors.ride.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_tethering, color: Colors.white, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? 'You are Online' : 'You are Offline',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isOnline
                                  ? 'Looking for nearby ride requests...'
                                  : 'Switch online to receive and claim new trips.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(0)?.title ?? 'Trips Today',
                        value: stats.elementAtOrNull(0)?.value ?? '3',
                        icon: Icons.account_balance_wallet,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(1)?.title ?? 'Active Requests',
                        value: stats.elementAtOrNull(1)?.value ?? '9',
                        icon: Icons.local_taxi_outlined,
                        color: AppColors.ride,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(2)?.title ?? 'Ride Categories',
                        value: stats.elementAtOrNull(2)?.value ?? '4',
                        icon: Icons.category_outlined,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(3)?.title ?? 'Completed Today',
                        value: stats.elementAtOrNull(3)?.value ?? '2',
                        icon: Icons.done_all_outlined,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'New Request!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 16),
                if (highlight != null)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                highlight.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                highlight.amount ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          ...highlight.lines.where((line) => line.isNotEmpty).map(
                            (line) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.arrow_right_alt, color: AppColors.ride),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text(line)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ride,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isClaiming
                                      || !isOnline
                                  ? null
                                  : () => _claimRide(highlight),
                              child: Text(
                                !isOnline
                                    ? 'Offline'
                                    : _isClaiming
                                        ? 'Claiming...'
                                        : highlight.ctaLabel,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RiderQueueScreen(
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
