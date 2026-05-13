import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/utils/pro_message_launcher.dart';
import 'doctor_telemedicine_screen.dart';

class DoctorAppointmentsQueueScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const DoctorAppointmentsQueueScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<DoctorAppointmentsQueueScreen> createState() =>
      _DoctorAppointmentsQueueScreenState();
}

class _DoctorAppointmentsQueueScreenState
    extends State<DoctorAppointmentsQueueScreen> {
  final Set<String> _busyIds = <String>{};
  List<Map<String, dynamic>> _items = const [];
  bool _isLoading = true;
  String _selectedStatus = 'pending';

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get(
        '/pro/${widget.userId}/doctor-appointments',
        forceRefresh: true,
      );
      final items = (response as List)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  bool _matchesStatus(Map<String, dynamic> item) {
    final status = item['status']?.toString().toUpperCase() ?? '';
    switch (_selectedStatus) {
      case 'all':
        return true;
      case 'pending':
        return status == 'PENDING';
      case 'approved':
        return status == 'APPROVED' || status == 'UPCOMING';
      case 'completed':
        return status == 'COMPLETED';
      default:
        return true;
    }
  }

  Future<void> _updateStatus(Map<String, dynamic> item, String status) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() => _busyIds.add(id));
    try {
      await ApiClient.post('/pro/${widget.userId}/doctor-appointment-status', {
        'appointmentId': id,
        'status': status,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.appointmentUpdatedTo(_statusLabel(status))),
        ),
      );
      await _loadQueue();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _items
        .where(
          (item) =>
              (item['status']?.toString().toUpperCase() ?? '') == 'PENDING',
        )
        .length;
    final approvedCount = _items.where((item) {
      final status = item['status']?.toString().toUpperCase() ?? '';
      return status == 'APPROVED' || status == 'UPCOMING';
    }).length;
    final completedCount = _items
        .where(
          (item) =>
              (item['status']?.toString().toUpperCase() ?? '') == 'COMPLETED',
        )
        .length;
    final filteredItems = _items.where(_matchesStatus).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorAppointmentsTitle(widget.businessName)),
        backgroundColor: AppColors.doctor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadQueue,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.doctor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _QueueMetric(label: l10n.pending, value: '$pendingCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: l10n.approved, value: '$approvedCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: l10n.done, value: '$completedCount'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in [
                  'pending',
                  'approved',
                  'completed',
                  'all',
                ])
                  ChoiceChip(
                    label: Text(_statusLabel(status)),
                    selected: _selectedStatus == status,
                    onSelected: (_) => setState(() => _selectedStatus = status),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.white,
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.medical_information_outlined, size: 34),
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(l10n.loadingAppointments),
                  ],
                ),
              )
            else if (filteredItems.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noAppointmentsMatch),
                ),
              )
            else
              ...filteredItems.map(_buildAppointmentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final status = item['status']?.toString().toUpperCase() ?? '';
    final title = item['title']?.toString() ?? l10n.patientLabel;
    final subtitle = item['subtitle']?.toString() ?? '';
    final doctorName = item['doctorName']?.toString() ?? '';
    final phone = item['customerPhone']?.toString() ?? '';
    final customerUserId = item['customerUserId']?.toString() ?? '';
    final notes = item['notes']?.toString() ?? '';
    final appointmentAt = _formatDate(item['appointmentAt']);
    final isBusy = _busyIds.contains(id);
    final isVideo = subtitle.toLowerCase().contains('video');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    color: AppColors.doctor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(subtitle),
            if (doctorName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(doctorName),
            ],
            if (phone.isNotEmpty) ...[const SizedBox(height: 4), Text(phone)],
            const SizedBox(height: 4),
            Text(appointmentAt, style: TextStyle(color: Colors.grey.shade700)),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(notes, style: TextStyle(color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (phone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => launchPhoneCall(context, phone),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(l10n.callAction),
                  ),
                if (customerUserId.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openProConversation(
                      context,
                      customerUserId: customerUserId,
                      participantUserId: widget.userId,
                      moduleType: 'DOCTOR',
                      entityType: 'DOCTOR',
                      entityId: id,
                      title: widget.businessName,
                      subtitle: l10n.appointmentSupport,
                      accentColor: '#188E68',
                      metadata: {
                        'appointmentId': id,
                        'customerPhone': phone,
                        'specialty': doctorName,
                      },
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(l10n.messageAction),
                  ),
                if (status == 'PENDING') ...[
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => _updateStatus(item, 'REJECTED'),
                    child: Text(l10n.reject),
                  ),
                  ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : () => _updateStatus(item, 'APPROVED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.doctor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isBusy ? l10n.updating : l10n.approve),
                  ),
                ] else if (status == 'APPROVED' || status == 'UPCOMING') ...[
                  ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : () => _updateStatus(item, 'COMPLETED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.doctor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isBusy ? l10n.updating : l10n.complete),
                  ),
                  if (isVideo)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DoctorTelemedicineScreen(),
                          ),
                        );
                      },
                      child: Text(l10n.openVideoAction),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pending;
      case 'approved':
        return l10n.approved;
      case 'upcoming':
        return l10n.upcoming;
      case 'completed':
        return l10n.completedLabel;
      case 'rejected':
        return l10n.rejected;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return l10n.schedulePending;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('EEE, MMM d • h:mm a').format(parsed.toLocal());
  }
}

class _QueueMetric extends StatelessWidget {
  final String label;
  final String value;

  const _QueueMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
