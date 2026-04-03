import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/widgets/pro_drawer.dart';

class ProOperationsScreen extends StatefulWidget {
  const ProOperationsScreen({super.key, required this.profile});

  final ProProfile profile;

  @override
  State<ProOperationsScreen> createState() => _ProOperationsScreenState();
}

class _ProOperationsScreenState extends State<ProOperationsScreen> {
  late Future<ProDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant ProOperationsScreen oldWidget) {
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

  Future<void> _refresh() async {
    final future = _loadDashboard();
    setState(() => _dashboardFuture = future);
    await future;
  }

  Future<void> _open(String route) {
    return context.push(route);
  }

  List<_OperationAction> _buildActions(ProProfile profile) {
    switch (profile.type) {
      case ProProfileType.shop:
        return [
          _OperationAction(
            title: 'Orders Queue',
            subtitle: 'Manage shopping, food, and pharmacy fulfillment.',
            icon: Icons.receipt_long_outlined,
            color: AppColors.shopping,
            onTap: () => _open(ProRoutePaths.shopQueue),
          ),
          _OperationAction(
            title: 'Catalog & Availability',
            subtitle: 'Pause stores, restaurant lanes, and pharmacy inventory.',
            icon: Icons.storefront_outlined,
            color: AppColors.primary,
            onTap: () => _open(ProRoutePaths.shopCatalog),
          ),
          _OperationAction(
            title: 'Shopping Lane',
            subtitle: 'Focus only on retail orders and store operations.',
            icon: Icons.shopping_bag_outlined,
            color: AppColors.shopping,
            onTap: () => _open('${ProRoutePaths.shopQueue}?module=shopping'),
          ),
          _OperationAction(
            title: 'Food Lane',
            subtitle: 'Open the kitchen queue and prep flow.',
            icon: Icons.restaurant_menu,
            color: AppColors.food,
            onTap: () => _open('${ProRoutePaths.shopQueue}?module=food'),
          ),
          _OperationAction(
            title: 'Pharmacy Lane',
            subtitle: 'Handle medicine orders separately from other sales.',
            icon: Icons.local_pharmacy_outlined,
            color: AppColors.pharmacy,
            onTap: () => _open('${ProRoutePaths.shopQueue}?module=pharmacy'),
          ),
        ];
      case ProProfileType.provider:
        return [
          _OperationAction(
            title: 'Jobs Queue',
            subtitle: 'Review service bookings and laundry jobs.',
            icon: Icons.work_outline,
            color: AppColors.homeServices,
            onTap: () => _open(ProRoutePaths.providerQueue),
          ),
          _OperationAction(
            title: 'Availability',
            subtitle: 'Control which provider and laundry lanes are open.',
            icon: Icons.toggle_on_outlined,
            color: AppColors.info,
            onTap: () => _open(ProRoutePaths.providerAvailability),
          ),
          _OperationAction(
            title: 'Scheduling',
            subtitle: 'Edit response times, booking modes, and weekly hours.',
            icon: Icons.schedule_outlined,
            color: AppColors.warning,
            onTap: () => _open(ProRoutePaths.providerSchedule),
          ),
          _OperationAction(
            title: 'Services Only',
            subtitle: 'Open the home services queue directly.',
            icon: Icons.home_repair_service_outlined,
            color: AppColors.homeServices,
            onTap: () => _open('${ProRoutePaths.providerQueue}?module=services'),
          ),
          _OperationAction(
            title: 'Laundry Only',
            subtitle: 'Open the laundry pipeline directly.',
            icon: Icons.local_laundry_service_outlined,
            color: AppColors.laundry,
            onTap: () => _open('${ProRoutePaths.providerQueue}?module=laundry'),
          ),
        ];
      case ProProfileType.doctor:
        return [
          _OperationAction(
            title: 'Appointments',
            subtitle: 'Approve, complete, and review patient visits.',
            icon: Icons.event_note_outlined,
            color: AppColors.doctor,
            onTap: () => _open(ProRoutePaths.doctorAppointments),
          ),
          _OperationAction(
            title: 'Availability',
            subtitle: 'Set which doctor profiles are currently available.',
            icon: Icons.toggle_on_outlined,
            color: AppColors.info,
            onTap: () => _open(ProRoutePaths.doctorAvailability),
          ),
          _OperationAction(
            title: 'Scheduling',
            subtitle: 'Configure clinic details, hours, and care modes.',
            icon: Icons.schedule_outlined,
            color: AppColors.warning,
            onTap: () => _open(ProRoutePaths.doctorSchedule),
          ),
        ];
      case ProProfileType.delivery:
        return [
          _OperationAction(
            title: 'Dispatch Queue',
            subtitle: 'Claim shopping, food, and pharmacy deliveries.',
            icon: Icons.local_shipping_outlined,
            color: AppColors.food,
            onTap: () => _open(ProRoutePaths.deliveryQueue),
          ),
        ];
      case ProProfileType.rider:
        return [
          _OperationAction(
            title: 'Ride Queue',
            subtitle: 'Claim new trips and reopen assigned rides.',
            icon: Icons.local_taxi_outlined,
            color: AppColors.ride,
            onTap: () => _open(ProRoutePaths.riderQueue),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileColor = ProModuleHelper.getProfileColor(widget.profile.type);
    final onlineState =
        context.watch<ProAuthProvider>().currentProfile?.isOnline ??
        widget.profile.isOnline;

    return Scaffold(
      drawer: const ProDrawer(),
      appBar: AppBar(
        title: const Text('Operations'),
        backgroundColor: profileColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ProDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final actions = _buildActions(widget.profile);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _OperationsHero(
                  profile: widget.profile,
                  headline: data?.headline,
                  scopeNote: data?.scopeNote,
                  onlineState: onlineState,
                ),
                const SizedBox(height: 20),
                Text(
                  'Quick Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...actions.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OperationCard(action: action),
                  ),
                ),
                if (data?.moduleSummaries.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Module Workstreams',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...data!.moduleSummaries.map(
                    (summary) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ModuleSummaryCard(summary: summary),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OperationsHero extends StatelessWidget {
  const _OperationsHero({
    required this.profile,
    required this.headline,
    required this.scopeNote,
    required this.onlineState,
  });

  final ProProfile profile;
  final String? headline;
  final String? scopeNote;
  final bool onlineState;

  @override
  Widget build(BuildContext context) {
    final color = ProModuleHelper.getProfileColor(profile.type);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Icon(
                  ProModuleHelper.getProfileIcon(profile.type),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.businessName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ProModuleHelper.getProfileName(profile.type),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (profile.type == ProProfileType.delivery ||
                  profile.type == ProProfileType.rider)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    onlineState ? 'Online' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            headline?.isNotEmpty == true
                ? headline!
                : 'Operate your live workload from here.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (scopeNote?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              scopeNote!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.action});

  final _OperationAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: action.color.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: action.color,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleSummaryCard extends StatelessWidget {
  const _ModuleSummaryCard({required this.summary});

  final ProDashboardModuleSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              summary.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
            ),
            if (summary.metrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.metrics
                    .map(
                      (metric) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(metric),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OperationAction {
  const _OperationAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
