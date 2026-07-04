import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/constants/pro_design_system.dart';

class ProSuperAdminScreen extends StatefulWidget {
  const ProSuperAdminScreen({super.key});

  @override
  State<ProSuperAdminScreen> createState() => _ProSuperAdminScreenState();
}

class _ProSuperAdminScreenState extends State<ProSuperAdminScreen> {
  late Future<_AdminOverview> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverview();
  }

  Future<_AdminOverview> _loadOverview() async {
    final response = Map<String, dynamic>.from(
      await ApiClient.get('/admin/overview', forceRefresh: true) as Map,
    );
    return _AdminOverview.fromJson(response);
  }

  Future<void> _refresh() async {
    final future = _loadOverview();
    setState(() => _overviewFuture = future);
    await future;
  }

  Future<void> _setBan({
    required _AdminAccount account,
    required bool isProAccount,
    required bool banned,
  }) async {
    final endpoint = isProAccount
        ? '/admin/pro-accounts/${account.id}/ban'
        : '/admin/users/${account.id}/ban';
    await ApiClient.patch(endpoint, {
      'banned': banned,
      'banReason': banned ? 'Account suspended by super admin.' : null,
    });
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_AdminOverview>(
          future: _overviewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(ProDesignSystem.spacing16),
                children: [
                  _Panel(
                    child: Text(
                      'Could not load system operations: ${snapshot.error}',
                    ),
                  ),
                ],
              );
            }

            final overview = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(ProDesignSystem.spacing16),
              children: [
                Text(
                  'System Operations',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing6),
                Text(
                  'Track marketplace activity, users, Pro accounts, fulfillment, rides, care, hotel, and laundry operations from one control center.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.mediumGrey),
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                _MetricsGrid(metrics: overview.metrics),
                const SizedBox(height: ProDesignSystem.spacing20),
                _Panel(
                  title: 'Status Breakdown',
                  child: _StatusBreakdowns(groups: overview.statusBreakdowns),
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                _Panel(
                  title: 'Recent Activity',
                  child: _ActivityList(items: overview.recentActivity),
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                _Panel(
                  title: 'Recent Users',
                  child: _AccountList(
                    accounts: overview.recentUsers,
                    isProAccount: false,
                    onSetBan: _setBan,
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing16),
                _Panel(
                  title: 'Recent Pro Accounts',
                  child: _AccountList(
                    accounts: overview.recentProAccounts,
                    isProAccount: true,
                    onSetBan: _setBan,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final _AdminMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _MetricData('Users', metrics.users, Icons.people_outline),
      _MetricData('Pro accounts', metrics.proAccounts, Icons.badge_outlined),
      _MetricData('Orders', metrics.orders, Icons.receipt_long_outlined),
      _MetricData('Rides', metrics.rides, Icons.local_taxi_outlined),
      _MetricData('Appointments', metrics.appointments, Icons.event_note),
      _MetricData(
        'Laundry',
        metrics.laundryOrders,
        Icons.local_laundry_service,
      ),
      _MetricData('Hotels', metrics.hotelBookings, Icons.hotel_outlined),
      _MetricData('Revenue', metrics.revenueTotal, Icons.payments_outlined),
      _MetricData('Today orders', metrics.todayOrders, Icons.today_outlined),
      _MetricData('Today rides', metrics.todayRides, Icons.route_outlined),
      _MetricData('Banned users', metrics.bannedUsers, Icons.block_outlined),
      _MetricData(
        'Banned Pro',
        metrics.bannedProAccounts,
        Icons.admin_panel_settings_outlined,
      ),
    ];

    return GridView.count(
      crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
      crossAxisSpacing: ProDesignSystem.spacing12,
      mainAxisSpacing: ProDesignSystem.spacing12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: tiles.map((tile) => _MetricTile(data: tile)).toList(),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: AppColors.primaryDark),
          const Spacer(),
          Text(
            data.value is double
                ? '\$${(data.value as double).toStringAsFixed(2)}'
                : '${data.value}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(data.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _StatusBreakdowns extends StatelessWidget {
  const _StatusBreakdowns({required this.groups});

  final Map<String, List<_StatusCount>> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: groups.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: ProDesignSystem.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: ProDesignSystem.spacing8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value
                    .map(
                      (item) => Chip(
                        label: Text('${item.status}: ${item.count}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items});

  final List<_ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('No recent activity yet.');
    return Column(
      children: items
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(child: Icon(_iconForType(item.type))),
              title: Text(item.title),
              subtitle: Text('${item.type} • ${item.subtitle}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.status, style: const TextStyle(fontSize: 12)),
                  if (item.amount != null)
                    Text(
                      '\$${item.amount!.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'ride':
        return Icons.local_taxi_outlined;
      case 'appointment':
        return Icons.event_note;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'hotel':
        return Icons.hotel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}

class _AccountList extends StatelessWidget {
  const _AccountList({
    required this.accounts,
    required this.isProAccount,
    required this.onSetBan,
  });

  final List<_AdminAccount> accounts;
  final bool isProAccount;
  final Future<void> Function({
    required _AdminAccount account,
    required bool isProAccount,
    required bool banned,
  })
  onSetBan;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) return const Text('No accounts found.');
    return Column(
      children: accounts
          .map(
            (account) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: account.banned
                    ? AppColors.error.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.12),
                child: Icon(
                  account.banned ? Icons.block : Icons.person_outline,
                  color: account.banned ? AppColors.error : AppColors.primary,
                ),
              ),
              title: Text(account.name),
              subtitle: Text(account.email),
              trailing: TextButton(
                onPressed: () => onSetBan(
                  account: account,
                  isProAccount: isProAccount,
                  banned: !account.banned,
                ),
                child: Text(account.banned ? 'Unban' : 'Ban'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ProDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: ProDesignSystem.spacing12),
          ],
          child,
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);

  final String label;
  final num value;
  final IconData icon;
}

class _AdminOverview {
  const _AdminOverview({
    required this.metrics,
    required this.statusBreakdowns,
    required this.recentActivity,
    required this.recentUsers,
    required this.recentProAccounts,
  });

  final _AdminMetrics metrics;
  final Map<String, List<_StatusCount>> statusBreakdowns;
  final List<_ActivityItem> recentActivity;
  final List<_AdminAccount> recentUsers;
  final List<_AdminAccount> recentProAccounts;

  factory _AdminOverview.fromJson(Map<String, dynamic> json) {
    final breakdowns = Map<String, dynamic>.from(
      json['statusBreakdowns'] as Map? ?? const {},
    );
    return _AdminOverview(
      metrics: _AdminMetrics.fromJson(
        Map<String, dynamic>.from(json['metrics'] as Map? ?? const {}),
      ),
      statusBreakdowns: breakdowns.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>? ?? const [])
              .map(
                (entry) => _StatusCount.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
        ),
      ),
      recentActivity: (json['recentActivity'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                _ActivityItem.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
      recentUsers: (json['recentUsers'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                _AdminAccount.fromJson(Map<String, dynamic>.from(entry as Map)),
          )
          .toList(),
      recentProAccounts:
          (json['recentProAccounts'] as List<dynamic>? ?? const [])
              .map(
                (entry) => _AdminAccount.fromJson(
                  Map<String, dynamic>.from(entry as Map),
                ),
              )
              .toList(),
    );
  }
}

class _AdminMetrics {
  const _AdminMetrics({
    required this.users,
    required this.bannedUsers,
    required this.proAccounts,
    required this.bannedProAccounts,
    required this.orders,
    required this.rides,
    required this.appointments,
    required this.laundryOrders,
    required this.hotelBookings,
    required this.todayOrders,
    required this.todayRides,
    required this.revenueTotal,
  });

  final int users;
  final int bannedUsers;
  final int proAccounts;
  final int bannedProAccounts;
  final int orders;
  final int rides;
  final int appointments;
  final int laundryOrders;
  final int hotelBookings;
  final int todayOrders;
  final int todayRides;
  final double revenueTotal;

  factory _AdminMetrics.fromJson(Map<String, dynamic> json) {
    return _AdminMetrics(
      users: _int(json['users']),
      bannedUsers: _int(json['bannedUsers']),
      proAccounts: _int(json['proAccounts']),
      bannedProAccounts: _int(json['bannedProAccounts']),
      orders: _int(json['orders']),
      rides: _int(json['rides']),
      appointments: _int(json['appointments']),
      laundryOrders: _int(json['laundryOrders']),
      hotelBookings: _int(json['hotelBookings']),
      todayOrders: _int(json['todayOrders']),
      todayRides: _int(json['todayRides']),
      revenueTotal: _double(json['revenueTotal']),
    );
  }
}

class _StatusCount {
  const _StatusCount({required this.status, required this.count});

  final String status;
  final int count;

  factory _StatusCount.fromJson(Map<String, dynamic> json) {
    return _StatusCount(
      status: json['status']?.toString() ?? 'unknown',
      count: _int(json['count']),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    this.amount,
  });

  final String type;
  final String title;
  final String subtitle;
  final String status;
  final double? amount;

  factory _ActivityItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return _ActivityItem(
      type: json['type']?.toString() ?? 'operation',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      amount: rawAmount == null ? null : _double(rawAmount),
    );
  }
}

class _AdminAccount {
  const _AdminAccount({
    required this.id,
    required this.email,
    required this.name,
    required this.banned,
  });

  final String id;
  final String email;
  final String name;
  final bool banned;

  factory _AdminAccount.fromJson(Map<String, dynamic> json) {
    final fullName = json['fullName']?.toString();
    final name = fullName?.trim().isNotEmpty == true
        ? fullName!
        : [
            json['firstName']?.toString() ?? '',
            json['lastName']?.toString() ?? '',
          ].where((part) => part.trim().isNotEmpty).join(' ');
    return _AdminAccount(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: name.trim().isEmpty ? 'Unnamed account' : name,
      banned: json['banned'] as bool? ?? false,
    );
  }
}

int _int(dynamic value) => (value as num?)?.toInt() ?? 0;
double _double(dynamic value) => (value as num?)?.toDouble() ?? 0;
