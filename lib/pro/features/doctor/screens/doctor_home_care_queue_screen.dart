import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/utils/pro_message_launcher.dart';

class DoctorHomeCareQueueScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const DoctorHomeCareQueueScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<DoctorHomeCareQueueScreen> createState() =>
      _DoctorHomeCareQueueScreenState();
}

class _DoctorHomeCareQueueScreenState extends State<DoctorHomeCareQueueScreen> {
  final Set<String> _busyIds = <String>{};
  List<Map<String, dynamic>> _items = const [];
  bool _isLoading = true;
  String _selectedStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get(
        '/pro/${widget.userId}/doctor-home-care-appointments',
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
          content: Text(
            'Home care booking updated to ${status.replaceAll('_', ' ')}.',
          ),
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
        title: Text('Dr. ${widget.businessName} Home Care'),
        backgroundColor: AppColors.homeServices,
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
                color: AppColors.homeServices.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _QueueMetric(label: 'Pending', value: '$pendingCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: 'Approved', value: '$approvedCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: 'Done', value: '$completedCount'),
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
                child: const Column(
                  children: [
                    Icon(Icons.home_repair_service_outlined, size: 34),
                    SizedBox(height: 10),
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Loading home care bookings...'),
                  ],
                ),
              )
            else if (filteredItems.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No home care bookings match the current filters.',
                  ),
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
    final title = item['title']?.toString() ?? 'Patient';
    final subtitle = item['subtitle']?.toString() ?? '';
    final doctorName = item['doctorName']?.toString() ?? '';
    final phone = item['customerPhone']?.toString() ?? '';
    final customerUserId = item['customerUserId']?.toString() ?? '';
    final notes = item['notes']?.toString() ?? '';
    final appointmentAt = _formatDate(item['appointmentAt']);
    final isBusy = _busyIds.contains(id);

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
                  status.replaceAll('_', ' '),
                  style: const TextStyle(
                    color: AppColors.homeServices,
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
                    label: const Text('Call'),
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
                      subtitle: 'Home care booking support',
                      accentColor: '#188E68',
                      metadata: {
                        'appointmentId': id,
                        'customerPhone': phone,
                        'specialty': doctorName,
                        'queue': 'home-care',
                      },
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                  ),
                if (status == 'PENDING') ...[
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () => _updateStatus(item, 'REJECTED'),
                    child: const Text('Reject'),
                  ),
                  ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : () => _updateStatus(item, 'APPROVED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.homeServices,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isBusy ? 'Updating...' : 'Approve'),
                  ),
                ] else if (status == 'APPROVED' || status == 'UPCOMING')
                  ElevatedButton(
                    onPressed: isBusy
                        ? null
                        : () => _updateStatus(item, 'COMPLETED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.homeServices,
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
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'completed':
        return 'Completed';
      default:
        return 'All';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Unknown date';
    try {
      final parsed = DateTime.parse(value.toString()).toLocal();
      return DateFormat('EEE, d MMM · HH:mm').format(parsed);
    } catch (_) {
      return value.toString();
    }
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.homeServices,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
