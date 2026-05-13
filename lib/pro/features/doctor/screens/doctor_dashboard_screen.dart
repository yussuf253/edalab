import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import 'doctor_availability_screen.dart';
import 'doctor_appointments_queue_screen.dart';
import 'doctor_home_care_queue_screen.dart';
import 'doctor_schedule_settings_screen.dart';
import 'doctor_telemedicine_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final ProProfile profile;

  const DoctorDashboardScreen({super.key, required this.profile});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  late Future<ProDashboardData> _dashboardFuture;
  final Set<String> _busyAppointmentIds = <String>{};

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void didUpdateWidget(covariant DoctorDashboardScreen oldWidget) {
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

  Future<void> _openSchedule() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorScheduleSettingsScreen(
          userId: widget.profile.userId,
          businessName: widget.profile.businessName,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _openAvailability() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorAvailabilityScreen(
          userId: widget.profile.userId,
          businessName: widget.profile.businessName,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _openAppointmentsQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorAppointmentsQueueScreen(
          userId: widget.profile.userId,
          businessName: widget.profile.businessName,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _openHomeCareQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorHomeCareQueueScreen(
          userId: widget.profile.userId,
          businessName: widget.profile.businessName,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshDashboard();
  }

  Future<void> _openTelemedicine() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DoctorTelemedicineScreen()));
    if (!mounted) return;
    await _refreshDashboard();
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return l10n.pending;
      case 'APPROVED':
        return l10n.approved;
      case 'REJECTED':
        return l10n.rejected;
      case 'COMPLETED':
        return l10n.complete;
      case 'UPCOMING':
        return l10n.upcoming;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Future<void> _updateAppointmentStatus(
    ProDashboardItem item,
    String status,
  ) async {
    setState(() => _busyAppointmentIds.add(item.id));
    try {
      await ApiClient.post(
        '/pro/${widget.profile.userId}/doctor-appointment-status',
        {'appointmentId': item.id, 'status': status},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.appointment} ${l10n.updatedTo} ${_statusLabel(status)}.',
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
        setState(() => _busyAppointmentIds.remove(item.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${l10n.dr} ${widget.profile.businessName}'),
        elevation: 0,
        backgroundColor: AppColors.doctor,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: _openSchedule,
            icon: const Icon(Icons.schedule_outlined),
          ),
          IconButton(
            onPressed: _openAvailability,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            onPressed: _openAppointmentsQueue,
            icon: const Icon(Icons.event_note_outlined),
          ),
          IconButton(
            onPressed: _openHomeCareQueue,
            icon: const Icon(Icons.home_repair_service_rounded),
          ),
        ],
      ),
      body: FutureBuilder<ProDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final stats = data?.stats ?? const <ProDashboardMetric>[];
          final summary = data?.moduleSummaries.firstOrNull;
          final recentItems =
              summary?.recentItems ?? const <ProDashboardItem>[];
          final pendingCount = recentItems
              .where((item) => item.status.toUpperCase() == 'PENDING')
              .length;
          final approvedCount = recentItems.where((item) {
            final status = item.status.toUpperCase();
            return status == 'APPROVED' || status == 'UPCOMING';
          }).length;
          final videoCount = recentItems
              .where((item) => item.subtitle.toLowerCase().contains('video'))
              .length;

          if (snapshot.connectionState == ConnectionState.waiting &&
              data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DoctorClinicalHero(
                  doctorName: widget.profile.businessName,
                  headline: data?.headline,
                  pendingCount: pendingCount,
                  videoCount: videoCount,
                  onOpenQueue: _openAppointmentsQueue,
                  l10n: l10n,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.quickActions,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _QuickActionCard(
                        icon: Icons.event_note_outlined,
                        label: l10n.appointments,
                        color: AppColors.doctor,
                        onTap: _openAppointmentsQueue,
                      ),
                      _QuickActionCard(
                        icon: Icons.video_call_outlined,
                        label: l10n.telemedicine,
                        color: Colors.purple,
                        onTap: _openTelemedicine,
                      ),
                      _QuickActionCard(
                        icon: Icons.home_repair_service_outlined,
                        label: l10n.homeCare,
                        color: AppColors.info,
                        onTap: _openHomeCareQueue,
                      ),
                      _QuickActionCard(
                        icon: Icons.tune,
                        label: l10n.availability,
                        color: Colors.orange,
                        onTap: _openAvailability,
                      ),
                      _QuickActionCard(
                        icon: Icons.schedule_outlined,
                        label: l10n.schedule,
                        color: Colors.teal,
                        onTap: _openSchedule,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _DoctorMetricsGrid(
                  stats: stats,
                  fallbackPatients: recentItems.length,
                  fallbackVideo: videoCount,
                  fallbackUpcoming: approvedCount,
                  l10n: l10n,
                ),
                const SizedBox(height: 16),
                _DoctorTriageStrip(
                  pendingCount: pendingCount,
                  approvedCount: approvedCount,
                  videoCount: videoCount,
                  l10n: l10n,
                ),
                const SizedBox(height: 24),
                Text(
                  summary?.title ?? l10n.clinicalQueue,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (summary?.subtitle.isNotEmpty == true)
                  Text(summary!.subtitle),
                const SizedBox(height: 12),
                if (recentItems.isNotEmpty)
                  ...recentItems.map((item) {
                    final isVideo = item.subtitle.toLowerCase().contains(
                      'video',
                    );
                    final status = item.status.toUpperCase();
                    final isBusy = _busyAppointmentIds.contains(item.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.teal.shade50,
                                  radius: 24,
                                  child: Text(
                                    item.title.characters.first.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item.subtitle),
                                      if ((item.meta ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item.meta!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isVideo
                                        ? Icons.video_call
                                        : Icons.event_available,
                                    size: 24,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {
                                    if (isVideo &&
                                        (status == 'APPROVED' ||
                                            status == 'UPCOMING')) {
                                      _openTelemedicine();
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: Colors.teal.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (status == 'PENDING') ...[
                                  TextButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => _updateAppointmentStatus(
                                            item,
                                            'REJECTED',
                                          ),
                                    child: Text(l10n.reject),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => _updateAppointmentStatus(
                                            item,
                                            'APPROVED',
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.doctor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      isBusy ? l10n.updating : l10n.approve,
                                    ),
                                  ),
                                ] else if (status == 'APPROVED' ||
                                    status == 'UPCOMING')
                                  ElevatedButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => _updateAppointmentStatus(
                                            item,
                                            'COMPLETED',
                                          ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.doctor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      isBusy ? l10n.updating : l10n.complete,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.noLiveAppointments),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.doctor,
        foregroundColor: AppColors.white,
        onPressed: _openAppointmentsQueue,
        child: const Icon(Icons.medical_information_outlined),
      ),
    );
  }
}

// ScopeNote removed by user request

class _DoctorClinicalHero extends StatelessWidget {
  final String doctorName;
  final String? headline;
  final int pendingCount;
  final int videoCount;
  final VoidCallback onOpenQueue;
  final AppLocalizations l10n;

  const _DoctorClinicalHero({
    required this.doctorName,
    required this.headline,
    required this.pendingCount,
    required this.videoCount,
    required this.onOpenQueue,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.doctor, AppColors.doctor.withValues(alpha: 0.82)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.dr} $doctorName',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline?.trim().isNotEmpty == true
                ? headline!
                : l10n.doctorDashboardSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroBadge(
                icon: Icons.priority_high_outlined,
                label: l10n.pendingCountLabel(pendingCount),
              ),
              const SizedBox(width: 10),
              _HeroBadge(
                icon: Icons.video_camera_front_outlined,
                label: l10n.videoConsultsLabel(videoCount),
              ),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: onOpenQueue,
                icon: const Icon(Icons.event_note_outlined),
                label: Text(l10n.openQueue),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.doctor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorTriageStrip extends StatelessWidget {
  final int pendingCount;
  final int approvedCount;
  final int videoCount;
  final AppLocalizations l10n;

  const _DoctorTriageStrip({
    required this.pendingCount,
    required this.approvedCount,
    required this.videoCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TriageTile(
            label: l10n.pending,
            value: '$pendingCount',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TriageTile(
            label: l10n.upcoming,
            value: '$approvedCount',
            color: AppColors.doctor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TriageTile(
            label: l10n.video,
            value: '$videoCount',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _TriageTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TriageTile({
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
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DoctorMetricsGrid extends StatelessWidget {
  final List<ProDashboardMetric> stats;
  final int fallbackPatients;
  final int fallbackVideo;
  final int fallbackUpcoming;
  final AppLocalizations l10n;

  const _DoctorMetricsGrid({
    required this.stats,
    required this.fallbackPatients,
    required this.fallbackVideo,
    required this.fallbackUpcoming,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DoctorMetricCard(
            title: stats.elementAtOrNull(0)?.title ?? l10n.patientsToday,
            value: stats.elementAtOrNull(0)?.value ?? '$fallbackPatients',
            icon: Icons.people_outline,
            color: AppColors.doctor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DoctorMetricCard(
            title: stats.elementAtOrNull(1)?.title ?? l10n.videoQueue,
            value: stats.elementAtOrNull(1)?.value ?? '$fallbackVideo',
            icon: Icons.video_camera_front_outlined,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _DoctorMetricCard(
            title: stats.elementAtOrNull(2)?.title ?? l10n.upcoming,
            value: stats.elementAtOrNull(2)?.value ?? '$fallbackUpcoming',
            icon: Icons.assignment_outlined,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _DoctorMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DoctorMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  T? get firstOrNull => isEmpty ? null : this[0];
}
