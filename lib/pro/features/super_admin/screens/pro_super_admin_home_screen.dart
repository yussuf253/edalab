import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../../core/utils/money_format.dart';

/// Entry experience for super admins who have no pro profile. Shows
/// platform-wide stats and links to admin tools without ever requiring a
/// pro profile.
class ProSuperAdminHomeScreen extends StatefulWidget {
  const ProSuperAdminHomeScreen({super.key});

  @override
  State<ProSuperAdminHomeScreen> createState() =>
      _ProSuperAdminHomeScreenState();
}

class _ProSuperAdminHomeScreenState extends State<ProSuperAdminHomeScreen> {
  late Future<_PlatformStats> _statsFuture;
  late Future<List<_PendingProProfile>> _pendingFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
    _pendingFuture = _loadPendingProfiles();
  }

  Future<_PlatformStats> _loadStats() async {
    final response = Map<String, dynamic>.from(
      await ApiClient.get('/admin/overview', forceRefresh: true) as Map,
    );
    return _PlatformStats.fromJson(
      Map<String, dynamic>.from(response['metrics'] as Map? ?? const {}),
    );
  }

  Future<List<_PendingProProfile>> _loadPendingProfiles() async {
    final response = Map<String, dynamic>.from(
      await ApiClient.get('/admin/pro-profiles/pending', forceRefresh: true)
          as Map,
    );
    return ((response['profiles'] as List<dynamic>?) ?? const [])
        .map((entry) => _PendingProProfile.fromJson(entry as Map))
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    final statsFuture = _loadStats();
    final pendingFuture = _loadPendingProfiles();
    setState(() {
      _statsFuture = statsFuture;
      _pendingFuture = pendingFuture;
    });
    await Future.wait([statsFuture, pendingFuture]);
  }

  Future<void> _verifyProfile(_PendingProProfile profile) async {
    await ApiClient.post('/admin/pro-profiles/${profile.id}/verify', {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${profile.businessName} approved.')),
    );
    await _refresh();
  }

  Future<void> _rejectProfile(_PendingProProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject profile?'),
        content: Text(
          'This permanently deletes "${profile.businessName}" and its pro '
          'account. The owner would need to sign up again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiClient.post('/admin/pro-profiles/${profile.id}/reject', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${profile.businessName} rejected.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiClient.userFacingError(error))),
      );
    }
    await _refresh();
  }

  Future<void> _signOut() async {
    await context.read<ProAuthProvider>().logout();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final proAuth = context.watch<ProAuthProvider>();
    final adminName =
        proAuth.currentAccount?.fullName.trim().isNotEmpty == true
        ? proAuth.currentAccount!.fullName
        : 'Super Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(ProDesignSystem.spacing16),
          children: [
            Text(
              'Welcome, $adminName',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: ProDesignSystem.spacing6),
            Text(
              'Platform-wide overview and admin tools. This space is '
              'independent of any pro profile.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.mediumGrey),
            ),
            const SizedBox(height: ProDesignSystem.spacing20),
            _AdminToolsPanel(onSignOut: _signOut),
            const SizedBox(height: ProDesignSystem.spacing20),
            _PendingApprovalsPanel(
              pendingFuture: _pendingFuture,
              onVerify: _verifyProfile,
              onReject: _rejectProfile,
            ),
            const SizedBox(height: ProDesignSystem.spacing20),
            _StatsPanel(statsFuture: _statsFuture),
          ],
        ),
      ),
    );
  }
}

class _AdminToolsPanel extends StatelessWidget {
  const _AdminToolsPanel({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ProDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusLarge),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Admin Tools',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: ProDesignSystem.spacing12),
          _AdminToolTile(
            icon: Icons.monitor_heart_outlined,
            title: 'Operations Control Center',
            subtitle:
                'Fulfillment, rides, care, hotel, laundry, and account '
                'management with ban controls.',
            onTap: () => context.push(ProRoutePaths.superAdmin),
          ),
          const SizedBox(height: ProDesignSystem.spacing12),
          _AdminToolTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'End the super admin session on this device.',
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _AdminToolTile extends StatelessWidget {
  const _AdminToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _PendingApprovalsPanel extends StatelessWidget {
  const _PendingApprovalsPanel({
    required this.pendingFuture,
    required this.onVerify,
    required this.onReject,
  });

  final Future<List<_PendingProProfile>> pendingFuture;
  final Future<void> Function(_PendingProProfile) onVerify;
  final Future<void> Function(_PendingProProfile) onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ProDesignSystem.spacing16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusLarge),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pending Verifications',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: ProDesignSystem.spacing12),
          FutureBuilder<List<_PendingProProfile>>(
            future: pendingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Could not load pending profiles: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                );
              }

              final profiles = snapshot.data ?? const <_PendingProProfile>[];
              if (profiles.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No profiles awaiting verification.'),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: profiles
                    .map(
                      (profile) => _PendingProfileTile(
                        profile: profile,
                        onVerify: onVerify,
                        onReject: onReject,
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PendingProfileTile extends StatelessWidget {
  const _PendingProfileTile({
    required this.profile,
    required this.onVerify,
    required this.onReject,
  });

  final _PendingProProfile profile;
  final Future<void> Function(_PendingProProfile) onVerify;
  final Future<void> Function(_PendingProProfile) onReject;

  Future<void> _openDetails(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _PendingProfileDetailsSheet(
        profile: profile,
        onVerify: onVerify,
        onReject: onReject,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moduleNames = profile.modules.join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: ProDesignSystem.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.warning.withValues(alpha: 0.15),
            child: const Icon(Icons.hourglass_top, color: AppColors.warning),
          ),
          const SizedBox(width: ProDesignSystem.spacing12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(ProDesignSystem.radiusSmall),
              onTap: () => _openDetails(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: ProDesignSystem.spacing4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.businessName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${profile.typeLabel} • ${profile.email}'
                      '${moduleNames.isNotEmpty ? ' • $moduleNames' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: ProDesignSystem.spacing8),
          IconButton(
            tooltip: 'Details',
            icon: const Icon(Icons.info_outline, size: 22),
            onPressed: () => _openDetails(context),
          ),
          IconButton(
            tooltip: 'Approve',
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 26,
            ),
            onPressed: () => onVerify(profile),
          ),
          IconButton(
            tooltip: 'Reject',
            icon: const Icon(
              Icons.cancel_outlined,
              color: AppColors.error,
              size: 26,
            ),
            onPressed: () => onReject(profile),
          ),
        ],
      ),
    );
  }
}

/// Thrown internally when the admin cancels the reject confirmation — lets
/// `_run` skip the sheet-close path without treating it as a failure.
class _DecisionCancelled implements Exception {
  const _DecisionCancelled();
}

class _PendingProfileDetailsSheet extends StatefulWidget {
  const _PendingProfileDetailsSheet({
    required this.profile,
    required this.onVerify,
    required this.onReject,
  });

  final _PendingProProfile profile;
  final Future<void> Function(_PendingProProfile) onVerify;
  final Future<void> Function(_PendingProProfile) onReject;

  @override
  State<_PendingProfileDetailsSheet> createState() =>
      _PendingProfileDetailsSheetState();
}

class _PendingProfileDetailsSheetState
    extends State<_PendingProfileDetailsSheet> {
  bool _isBusy = false;
  late Future<Map<String, List<({String id, String name})>>> _namesFuture;

  @override
  void initState() {
    super.initState();
    _namesFuture = _loadBindingNames();
  }

  /// Resolves binding IDs to real business names via the admin API. IDs the
  /// backend can't match (e.g. deleted businesses) are absent from the
  /// result and fall back to showing the raw ID.
  Future<Map<String, List<({String id, String name})>>> _loadBindingNames()
      async {
    final response = Map<String, dynamic>.from(
      await ApiClient.get(
        '/admin/pro-profiles/${widget.profile.id}/binding-names',
        forceRefresh: true,
      )
          as Map,
    );
    final rawNames = response['names'] as Map? ?? const {};
    final resolved = <String, List<({String id, String name})>>{};
    rawNames.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        resolved[key.toString()] = value
            .map(
              (entry) => (
                id: (entry as Map)['id']?.toString() ?? '',
                name: entry['name']?.toString() ?? '',
              ),
            )
            .where((entry) => entry.name.isNotEmpty)
            .toList(growable: false);
      }
    });
    return resolved;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    var cancelled = false;
    try {
      await action();
      // The parent handler refreshes the list; close the sheet on success.
      if (mounted) Navigator.of(context).pop();
    } on _DecisionCancelled {
      cancelled = true;
    } catch (_) {
      // Errors are surfaced by the parent handler via snackbar; keep the
      // sheet open so the admin can retry.
    } finally {
      if (!cancelled && mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _rejectWithConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject profile?'),
        content: Text(
          'This permanently deletes "${widget.profile.businessName}" and its '
          'pro account. The owner would need to sign up again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.onReject(widget.profile);
    // Success: the parent refreshed the list, so close the sheet.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ProDesignSystem.spacing16,
          ProDesignSystem.spacing20,
          ProDesignSystem.spacing16,
          ProDesignSystem.spacing16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.businessName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: ProDesignSystem.spacing4),
              Wrap(
                spacing: ProDesignSystem.spacing8,
                runSpacing: ProDesignSystem.spacing8,
                children: [
                  Chip(
                    label: Text(profile.typeLabel),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    label: const Text('Pending verification'),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                  ),
                ],
              ),
              const SizedBox(height: ProDesignSystem.spacing16),
              _DetailSection(
                title: 'Owner',
                children: [
                  _DetailRow(label: 'Name', value: profile.fullName),
                  _DetailRow(label: 'Email', value: profile.email),
                  _DetailRow(label: 'Phone', value: profile.phone),
                ],
              ),
              _DetailSection(
                title: 'Signup date',
                children: [
                  _DetailRow(
                    label: 'Requested',
                    value: _formatDate(profile.createdAt),
                  ),
                ],
              ),
              _DetailSection(
                title: 'Active modules',
                children: profile.modules.isEmpty
                    ? [const _DetailRow(label: 'None', value: '')]
                    : profile.modules
                          .map(
                            (module) => _DetailRow(label: '•', value: module),
                          )
                          .toList(growable: false),
              ),
              _DetailSection(
                title: 'Bindings',
                children: profile.bindings.isEmpty
                    ? [
                        const _DetailRow(
                          label: 'None yet',
                          value: 'No businesses matched at signup.',
                        ),
                      ]
                    : profile.bindings.entries
                          .map(
                            (entry) => _BindingDetailRow(
                              label: _bindingLabels[entry.key] ?? entry.key,
                              ids: entry.value,
                              namesFuture: _namesFuture,
                              bindingKey: entry.key,
                            ),
                          )
                          .toList(growable: false),
              ),
              const SizedBox(height: ProDesignSystem.spacing8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      // Reject is destructive and permanent — gate it behind
                      // the same confirmation dialog as the row action.
                      onPressed: _isBusy ? null : _rejectWithConfirmation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: _isBusy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: ProDesignSystem.spacing12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isBusy
                          ? null
                          : () => _run(() => widget.onVerify(profile)),
                      icon: _isBusy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _bindingLabels = <String, String>{
    'shoppingStoreIds': 'Shopping stores',
    'restaurantIds': 'Restaurant IDs',
    'restaurantNames': 'Restaurants',
    'pharmacyBusinesses': 'Pharmacies',
    'providerIds': 'Providers',
    'doctorIds': 'Doctors',
    'laundryServiceIds': 'Laundry services',
  };

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year}, $hh:$mm';
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: ProDesignSystem.spacing6),
          ...children,
        ],
      ),
    );
  }
}

/// A bindings detail row that resolves its IDs to business names via the
/// admin API. Falls back to the raw ID for anything the backend couldn't
/// match (e.g. a business deleted after signup).
class _BindingDetailRow extends StatelessWidget {
  const _BindingDetailRow({
    required this.label,
    required this.ids,
    required this.namesFuture,
    required this.bindingKey,
  });

  final String label;
  final List<String> ids;
  final Future<Map<String, List<({String id, String name})>>> namesFuture;
  final String bindingKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: FutureBuilder<Map<String, List<({String id, String name})>>>(
        future: namesFuture,
        builder: (context, snapshot) {
          final resolvedById = <String, String>{};
          if (snapshot.hasData) {
            for (final entry in snapshot.data![bindingKey] ?? const []) {
              resolvedById[entry.id] = entry.name;
            }
          }

          final displayValues = ids
              .map((id) => resolvedById[id] ?? 'ID: $id')
              .toList(growable: false);
          final showSpinner =
              snapshot.connectionState == ConnectionState.waiting;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayValues.join(', '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    if (showSpinner) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _PendingProProfile {
  const _PendingProProfile({
    required this.id,
    required this.businessName,
    required this.typeLabel,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.modules,
    required this.bindings,
    required this.createdAt,
  });

  final String id;
  final String businessName;
  final String typeLabel;
  final String email;
  final String fullName;
  final String phone;
  final List<String> modules;
  final Map<String, List<String>> bindings;
  final DateTime createdAt;

  factory _PendingProProfile.fromJson(Map<dynamic, dynamic> json) {
    final rawType = (json['type'] as String? ?? '').toLowerCase();
    final typeLabel = rawType.isEmpty
        ? 'Pro'
        : rawType[0].toUpperCase() + rawType.substring(1);
    final account = json['account'] as Map? ?? const {};
    final rawBindings = json['bindings'] as Map? ?? const {};
    final bindings = <String, List<String>>{};
    rawBindings.forEach((key, value) {
      if (value is List && value.isNotEmpty) {
        bindings[key.toString()] = value
            .map((entry) => entry.toString())
            .toList(growable: false);
      }
    });
    return _PendingProProfile(
      id: json['id'] as String? ?? '',
      businessName: json['businessName'] as String? ?? 'Unnamed business',
      typeLabel: typeLabel,
      email: account['email'] as String? ?? '—',
      fullName: account['fullName'] as String? ?? '',
      phone: account['phone'] as String? ?? '',
      modules: ((json['activeModules'] as List<dynamic>?) ?? const [])
          .map((module) => module.toString().toLowerCase())
          .toList(growable: false),
      bindings: bindings,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.statsFuture});

  final Future<_PlatformStats> statsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_PlatformStats>(
      future: statsFuture,
      builder: (context, snapshot) {
        Widget body;
        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          body = Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Could not load platform stats: ${snapshot.error}',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        } else {
          final stats = snapshot.data!;
          body = GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
            crossAxisSpacing: ProDesignSystem.spacing12,
            mainAxisSpacing: ProDesignSystem.spacing12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: [
              _StatTile(
                label: 'Users',
                value: '${stats.users}',
                icon: Icons.people_outline,
              ),
              _StatTile(
                label: 'Pro accounts',
                value: '${stats.proAccounts}',
                icon: Icons.badge_outlined,
              ),
              _StatTile(
                label: 'Orders',
                value: '${stats.orders}',
                icon: Icons.receipt_long_outlined,
              ),
              _StatTile(
                label: 'Rides',
                value: '${stats.rides}',
                icon: Icons.local_taxi_outlined,
              ),
              _StatTile(
                label: 'Revenue',
                value: 'DJF ${money(stats.revenueTotal)}',
                icon: Icons.payments_outlined,
              ),
              _StatTile(
                label: 'Today orders',
                value: '${stats.todayOrders}',
                icon: Icons.today_outlined,
              ),
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(ProDesignSystem.spacing16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(ProDesignSystem.radiusLarge),
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Platform Stats',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: ProDesignSystem.spacing12),
              // GridView uses shrinkWrap inside this Column, so every child
              // here must stay non-flexible to avoid unbounded-height flex
              // crashes.
              body,
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ProDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusMedium),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryDark, size: 22),
          // Fixed spacing, not a Spacer(): this column has unbounded height
          // from its parent grid cell context.
          const SizedBox(height: ProDesignSystem.spacing8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PlatformStats {
  const _PlatformStats({
    required this.users,
    required this.proAccounts,
    required this.orders,
    required this.rides,
    required this.revenueTotal,
    required this.todayOrders,
  });

  final num users;
  final num proAccounts;
  final num orders;
  final num rides;
  final double revenueTotal;
  final num todayOrders;

  factory _PlatformStats.fromJson(Map<String, dynamic> json) {
    return _PlatformStats(
      users: (json['users'] as num?) ?? 0,
      proAccounts: (json['proAccounts'] as num?) ?? 0,
      orders: (json['orders'] as num?) ?? 0,
      rides: (json['rides'] as num?) ?? 0,
      revenueTotal: (json['revenueTotal'] as num?)?.toDouble() ?? 0.0,
      todayOrders: (json['todayOrders'] as num?) ?? 0,
    );
  }
}
