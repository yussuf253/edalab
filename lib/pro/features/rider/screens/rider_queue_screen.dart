import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/utils/pro_message_launcher.dart';
import 'rider_active_trip_screen.dart';

class RiderQueueScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const RiderQueueScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<RiderQueueScreen> createState() => _RiderQueueScreenState();
}

class _RiderQueueScreenState extends State<RiderQueueScreen> {
  final Set<String> _busyIds = <String>{};
  List<Map<String, dynamic>> _items = const [];
  bool _isLoading = true;
  String _selectedLane = 'open';

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get(
        '/pro/${widget.userId}/ride-queue',
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

  Future<void> _claimRide(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() => _busyIds.add(id));
    try {
      await ApiClient.post('/pro/${widget.userId}/claim-ride', {'rideId': id});
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              RiderActiveTripScreen(rideId: id, userId: widget.userId),
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

  Future<void> _openRide(String id) async {
    if (id.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RiderActiveTripScreen(rideId: id, userId: widget.userId),
      ),
    );
    if (!mounted) return;
    await _loadQueue();
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _items
        .where((item) => (item['queueType']?.toString() ?? '') == 'open')
        .length;
    final assignedCount = _items
        .where((item) => (item['queueType']?.toString() ?? '') == 'assigned')
        .length;
    final liveCount = _items.where((item) {
      final status = item['status']?.toString().toUpperCase() ?? '';
      return status != 'COMPLETED' && status != 'CANCELLED';
    }).length;
    final filteredItems = _items
        .where((item) {
          final lane = item['queueType']?.toString() ?? '';
          if (_selectedLane != 'all' && lane != _selectedLane) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.businessName} Ride Queue'),
        backgroundColor: AppColors.ride,
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
                color: AppColors.ride.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _QueueMetric(label: 'Open', value: '$openCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: 'Assigned', value: '$assignedCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: 'Live', value: '$liveCount'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final lane in ['open', 'assigned', 'all'])
                  ChoiceChip(
                    label: Text(_laneLabel(lane)),
                    selected: _selectedLane == lane,
                    onSelected: (_) => setState(() => _selectedLane = lane),
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
                    Icon(Icons.local_taxi_outlined, size: 34),
                    SizedBox(height: 10),
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Loading ride queue...'),
                  ],
                ),
              )
            else if (filteredItems.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No ride requests match the current queue filter.',
                  ),
                ),
              )
            else
              ...filteredItems.map(_buildRideCard),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final queueType = item['queueType']?.toString() ?? 'open';
    final phone = item['customerPhone']?.toString() ?? '';
    final customerUserId = item['customerUserId']?.toString() ?? '';
    final createdAt = _formatDate(item['createdAt']);
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
                    item['title']?.toString() ?? 'Ride',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  item['status']?.toString().replaceAll('_', ' ') ?? '',
                  style: const TextStyle(
                    color: AppColors.ride,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item['subtitle']?.toString() ?? ''),
            const SizedBox(height: 8),
            Text(item['customerName']?.toString() ?? 'Passenger'),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(phone, style: TextStyle(color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 4),
            Text(
              'Requested $createdAt',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['amount']?.toString() ?? '',
                    style: const TextStyle(
                      color: AppColors.ride,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => launchPhoneCall(context, phone),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                ],
                if (customerUserId.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => openProConversation(
                      context,
                      customerUserId: customerUserId,
                      participantUserId: widget.userId,
                      moduleType: 'RIDE',
                      entityType: 'RIDE',
                      entityId: id,
                      title: widget.businessName,
                      subtitle: 'Ride support',
                      accentColor: '#1D9070',
                      metadata: {'rideId': id, 'customerPhone': phone},
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                  ),
                ],
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : () => queueType == 'assigned'
                            ? _openRide(id)
                            : _claimRide(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ride,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isBusy
                        ? 'Working...'
                        : queueType == 'assigned'
                        ? 'Open Trip'
                        : 'Claim',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _laneLabel(String lane) {
    switch (lane) {
      case 'open':
        return 'Open Requests';
      case 'assigned':
        return 'Assigned To Me';
      default:
        return 'All';
    }
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return 'recently';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, h:mm a').format(parsed.toLocal());
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
