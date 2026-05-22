import '/pro/l10n/app_localizations.dart';

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

class ProOperationsScreen extends StatefulWidget {
  const ProOperationsScreen({super.key, required this.profile});

  final ProProfile profile;

  @override
  State<ProOperationsScreen> createState() => _ProOperationsScreenState();
}

class _ProOperationsScreenState extends State<ProOperationsScreen> {
  late Future<ProDashboardData> _dashboardFuture;

  // Convenient getter for localized strings
  AppLocalizations get l10n => AppLocalizations.of(context)!;

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

  bool _providerHasModule(ProProfile profile, ProModule module) {
    return profile.activeModules.contains(module);
  }

  List<_OperationAction> _buildActions(
    ProProfile profile,
    AppLocalizations l10n,
  ) {
    switch (profile.type) {
      case ProProfileType.shop:
        return [
          _OperationAction(
            title: l10n.ordersQueue,
            subtitle: l10n.ordersQueueSubtitle,
            icon: Icons.receipt_long_outlined,
            color: AppColors.shopping,
            onTap: () => _open(ProRoutePaths.shopQueue),
          ),
          _OperationAction(
            title: l10n.storeSetup,
            subtitle: l10n.editStoreNameTaglineDescription,
            icon: Icons.store_mall_directory_outlined,
            color: AppColors.primary,
            onTap: () => _open(ProRoutePaths.shopProducts),
          ),
          _OperationAction(
            title: l10n.productsManager,
            subtitle: l10n.productsManagerSubtitle,
            icon: Icons.inventory_2_outlined,
            color: AppColors.shopping,
            onTap: () => _open(ProRoutePaths.shopProducts),
          ),
          _OperationAction(
            title: l10n.shoppingLane,
            subtitle: l10n.shoppingLaneSubtitle,
            icon: Icons.shopping_bag_outlined,
            color: AppColors.shopping,
            onTap: () => _open('${ProRoutePaths.shopQueue}?module=shopping'),
          ),
          _OperationAction(
            title: l10n.foodLane,
            subtitle: l10n.foodLaneSubtitle,
            icon: Icons.restaurant_menu,
            color: AppColors.food,
            onTap: () => _open('${ProRoutePaths.shopQueue}?module=food'),
          ),
          _OperationAction(
            title: l10n.pharmacyLane,
            subtitle: l10n.pharmacyLaneSubtitle,
            icon: Icons.local_pharmacy_outlined,
            color: AppColors.pharmacy,
            onTap: () => _open('${ProRoutePaths.shopQueue}?module=pharmacy'),
          ),
        ];
      case ProProfileType.provider:
        final hasServices = _providerHasModule(profile, ProModule.services);
        final hasLaundry = _providerHasModule(profile, ProModule.laundry);
        final queueSubtitle = hasServices && hasLaundry
            ? l10n.jobsQueueSubtitleFull
            : hasLaundry
            ? l10n.jobsQueueSubtitleLaundry
            : l10n.jobsQueueSubtitleServices;
        final availabilitySubtitle = hasServices && hasLaundry
            ? l10n.availabilitySubtitleFull
            : hasLaundry
            ? l10n.availabilitySubtitleLaundry
            : l10n.availabilitySubtitleServices;
        final actions = <_OperationAction>[
          _OperationAction(
            title: l10n.jobsQueue,
            subtitle: queueSubtitle,
            icon: Icons.work_outline,
            color: AppColors.homeServices,
            onTap: () => _open(ProRoutePaths.providerQueue),
          ),
          _OperationAction(
            title: l10n.availability,
            subtitle: availabilitySubtitle,
            icon: Icons.toggle_on_outlined,
            color: AppColors.info,
            onTap: () => _open(ProRoutePaths.providerAvailability),
          ),
          _OperationAction(
            title: l10n.schedulingSettings,
            subtitle: l10n.schedulingSettingsSubtitle,
            icon: Icons.schedule_outlined,
            color: AppColors.warning,
            onTap: () => _open(ProRoutePaths.providerSchedule),
          ),
        ];
        if (hasServices) {
          actions.add(
            _OperationAction(
              title: l10n.servicesOnly,
              subtitle: l10n.servicesOnlySubtitle,
              icon: Icons.home_repair_service_outlined,
              color: AppColors.homeServices,
              onTap: () =>
                  _open('${ProRoutePaths.providerQueue}?module=services'),
            ),
          );
        }
        if (hasLaundry) {
          actions.add(
            _OperationAction(
              title: l10n.laundryOnly,
              subtitle: l10n.laundryOnlySubtitle,
              icon: Icons.local_laundry_service_outlined,
              color: AppColors.laundry,
              onTap: () =>
                  _open('${ProRoutePaths.providerQueue}?module=laundry'),
            ),
          );
        }
        return actions;
      case ProProfileType.doctor:
        return [
          _OperationAction(
            title: l10n.appointmentsQueue,
            subtitle: l10n.appointmentsQueueSubtitle,
            icon: Icons.event_note_outlined,
            color: AppColors.doctor,
            onTap: () => _open(ProRoutePaths.doctorAppointments),
          ),
          _OperationAction(
            title: l10n.doctorAvailability,
            subtitle: l10n.doctorAvailabilitySubtitle,
            icon: Icons.toggle_on_outlined,
            color: AppColors.info,
            onTap: () => _open(ProRoutePaths.doctorAvailability),
          ),
          _OperationAction(
            title: l10n.scheduleSettings,
            subtitle: l10n.scheduleSettingsSubtitle,
            icon: Icons.schedule_outlined,
            color: AppColors.warning,
            onTap: () => _open(ProRoutePaths.doctorSchedule),
          ),
        ];
      case ProProfileType.delivery:
        return [
          _OperationAction(
            title: l10n.dispatchQueue,
            subtitle: l10n.dispatchQueueSubtitle,
            icon: Icons.local_shipping_outlined,
            color: AppColors.food,
            onTap: () => _open(ProRoutePaths.deliveryQueue),
          ),
        ];
      case ProProfileType.rider:
        return [
          _OperationAction(
            title: l10n.rideQueue,
            subtitle: l10n.rideQueueSubtitle,
            icon: Icons.local_taxi_outlined,
            color: AppColors.ride,
            onTap: () => _open(ProRoutePaths.riderQueue),
          ),
        ];
    }
  }

  String _quickActionsTitle(ProProfileType type, AppLocalizations l10n) {
    switch (type) {
      case ProProfileType.shop:
        return l10n.storeControls;
      case ProProfileType.provider:
        return l10n.serviceControls;
      case ProProfileType.doctor:
        return l10n.clinicalControls;
      case ProProfileType.delivery:
        return l10n.dispatchControls;
      case ProProfileType.rider:
        return l10n.tripControls;
    }
  }

  String _workstreamTitle(ProProfileType type, AppLocalizations l10n) {
    switch (type) {
      case ProProfileType.shop:
        return l10n.storeModules;
      case ProProfileType.provider:
        return l10n.serviceWorkstreams;
      case ProProfileType.doctor:
        return l10n.consultationWorkstreams;
      case ProProfileType.delivery:
        return l10n.dispatchWorkstreams;
      case ProProfileType.rider:
        return l10n.rideWorkstreams;
    }
  }

  String _laneShortcutsTitle(ProProfileType type, AppLocalizations l10n) {
    switch (type) {
      case ProProfileType.shop:
        return l10n.laneShortcuts;
      case ProProfileType.provider:
        return l10n.pipelineShortcuts;
      case ProProfileType.doctor:
      case ProProfileType.delivery:
      case ProProfileType.rider:
        return l10n.shortcuts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileColor = ProModuleHelper.getProfileColor(widget.profile.type);
    final onlineState =
        context.watch<ProAuthProvider>().currentProfile?.isOnline ??
        widget.profile.isOnline;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          widget.profile.type == ProProfileType.shop
              ? l10n.storeTools
              : l10n.operations,
        ),
        backgroundColor: profileColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ProDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final actions = _buildActions(widget.profile, l10n);
          final type = widget.profile.type;
          final coreActions = switch (type) {
            ProProfileType.shop => actions.take(3).toList(growable: false),
            ProProfileType.provider => actions.take(3).toList(growable: false),
            ProProfileType.doctor => actions,
            ProProfileType.delivery => actions,
            ProProfileType.rider => actions,
          };
          // For providers we hide lane shortcuts (pipeline shortcuts).
          final laneActions = switch (type) {
            ProProfileType.provider => const <_OperationAction>[],
            ProProfileType.shop => actions.skip(3).toList(growable: false),
            ProProfileType.doctor => const <_OperationAction>[],
            ProProfileType.delivery => const <_OperationAction>[],
            ProProfileType.rider => const <_OperationAction>[],
          };

          final allowedProviderModules =
              widget.profile.type != ProProfileType.provider
              ? const <String>{}
              : <String>{
                  if (_providerHasModule(widget.profile, ProModule.services))
                    'services',
                  if (_providerHasModule(widget.profile, ProModule.laundry))
                    'laundry',
                };
          final visibleSummaries = data == null
              ? const <ProDashboardModuleSummary>[]
              : widget.profile.type == ProProfileType.provider
              ? data.moduleSummaries
                    .where(
                      (summary) =>
                          allowedProviderModules.contains(summary.module),
                    )
                    .toList(growable: false)
              : data.moduleSummaries;

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
                  _quickActionsTitle(type, l10n),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...coreActions.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OperationCard(action: action),
                  ),
                ),
                // Lane shortcuts are omitted for providers.
                if (laneActions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _laneShortcutsTitle(type, l10n),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...laneActions.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OperationCard(action: action),
                    ),
                  ),
                ],
                // Service workstreams are omitted for providers.
                if (type != ProProfileType.provider &&
                    visibleSummaries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _workstreamTitle(type, l10n),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...visibleSummaries.map(
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
    final l10n = AppLocalizations.of(context)!;
    final color = ProModuleHelper.getProfileColor(profile.type);
    final fallbackHeadline = switch (profile.type) {
      ProProfileType.shop => l10n.shopHeroFallback,
      ProProfileType.provider => l10n.providerHeroFallback,
      ProProfileType.doctor => l10n.doctorHeroFallback,
      ProProfileType.delivery => l10n.deliveryHeroFallback,
      ProProfileType.rider => l10n.riderHeroFallback,
    };

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
                    onlineState ? l10n.online : l10n.offline,
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
            headline?.isNotEmpty == true ? headline! : fallbackHeadline,
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
