import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_dashboard_data.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/widgets/pro_drawer.dart';
import '../../../core/widgets/pro_stat_card.dart';
import 'doctor_availability_screen.dart';
import 'doctor_appointments_queue_screen.dart';
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

  Future<void> _updateAppointmentStatus(
    ProDashboardItem item,
    String status,
  ) async {
    setState(() => _busyAppointmentIds.add(item.id));
    try {
      await ApiClient.post('/pro/${widget.profile.userId}/doctor-appointment-status', {
        'appointmentId': item.id,
        'status': status,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment updated to ${status.replaceAll('_', ' ')}.')),
      );
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
      drawer: const ProDrawer(),
      appBar: AppBar(
        title: Text('Dr. ${widget.profile.businessName}'),
        elevation: 0,
        backgroundColor: AppColors.doctor,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: () async {
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
            },
            icon: const Icon(Icons.schedule_outlined),
          ),
          IconButton(
            onPressed: () async {
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
            },
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DoctorAppointmentsQueueScreen(
                    userId: widget.profile.userId,
                    businessName: widget.profile.businessName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.event_note_outlined),
          ),
        ],
      ),
      body: FutureBuilder<ProDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final stats = data?.stats ?? const <ProDashboardMetric>[];
          final summary = data?.moduleSummaries.firstOrNull;

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
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(0)?.title ?? 'Patients Today',
                        value: stats.elementAtOrNull(0)?.value ?? '12',
                        icon: Icons.people_outline,
                        color: AppColors.doctor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(1)?.title ?? 'Video Queue',
                        value: stats.elementAtOrNull(1)?.value ?? '4',
                        icon: Icons.video_camera_front_outlined,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(2)?.title ?? 'Available Doctors',
                        value: stats.elementAtOrNull(2)?.value ?? '8',
                        icon: Icons.local_hospital_outlined,
                        color: AppColors.doctor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ProStatCard(
                        title: stats.elementAtOrNull(3)?.title ?? 'Upcoming Consults',
                        value: stats.elementAtOrNull(3)?.value ?? '3',
                        icon: Icons.assignment_outlined,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  summary?.title ?? 'Upcoming Appointments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (summary?.subtitle.isNotEmpty == true)
                  Text(summary!.subtitle),
                const SizedBox(height: 16),
                if (summary?.recentItems.isNotEmpty == true)
                  ...summary!.recentItems.map((item) {
                    final isVideo = item.subtitle.toLowerCase().contains('video');
                    final status = item.status.toUpperCase();
                    final isBusy = _busyAppointmentIds.contains(item.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(item.subtitle),
                                      if ((item.meta ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          item.meta!,
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isVideo ? Icons.video_call : Icons.event_available,
                                    size: 24,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {
                                    if (isVideo &&
                                        (status == 'APPROVED' || status == 'UPCOMING')) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const DoctorTelemedicineScreen(),
                                        ),
                                      );
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
                                    status.replaceAll('_', ' '),
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
                                        : () => _updateAppointmentStatus(item, 'REJECTED'),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => _updateAppointmentStatus(item, 'APPROVED'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.doctor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(isBusy ? 'Updating...' : 'Approve'),
                                  ),
                                ] else if (status == 'APPROVED' || status == 'UPCOMING')
                                  ElevatedButton(
                                    onPressed: isBusy
                                        ? null
                                        : () => _updateAppointmentStatus(item, 'COMPLETED'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.doctor,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(isBusy ? 'Updating...' : 'Complete'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No live appointments available right now.'),
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
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DoctorAppointmentsQueueScreen(
                userId: widget.profile.userId,
                businessName: widget.profile.businessName,
              ),
            ),
          );
        },
        child: const Icon(Icons.medical_information_outlined),
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

  T? get firstOrNull => isEmpty ? null : this[0];
}
