import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/utils/pro_message_launcher.dart';

class ProviderJobDetailScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final Map<String, dynamic> queueItem;

  const ProviderJobDetailScreen({
    super.key,
    required this.userId,
    required this.businessName,
    required this.queueItem,
  });

  @override
  State<ProviderJobDetailScreen> createState() =>
      _ProviderJobDetailScreenState();
}

class _ProviderJobDetailScreenState extends State<ProviderJobDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  bool _updating = false;

  String get _orderId => widget.queueItem['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (_orderId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await ApiClient.get(
        '/orders/detail/$_orderId',
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _detail = response is Map ? Map<String, dynamic>.from(response) : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _module() {
    final module = widget.queueItem['module']?.toString().trim();
    if (module != null && module.isNotEmpty) return module;
    final moduleType = _detail?['moduleType']?.toString().toUpperCase() ?? '';
    if (moduleType == 'LAUNDRY') return 'laundry';
    return 'services';
  }

  String _status() {
    return _detail?['status']?.toString().toUpperCase() ??
        widget.queueItem['status']?.toString().toUpperCase() ??
        'PENDING';
  }

  String? _nextStatus(String module, String status) {
    final normalizedStatus = status.toUpperCase();
    if (module == 'services') {
      switch (normalizedStatus) {
        case 'PENDING':
          return 'CONFIRMED';
        case 'CONFIRMED':
        case 'PROCESSING':
          return 'DISPATCHED';
        case 'DISPATCHED':
        case 'IN_PROGRESS':
          return 'COMPLETED';
        default:
          return null;
      }
    }
    switch (normalizedStatus) {
      case 'PENDING':
        return 'CONFIRMED';
      case 'CONFIRMED':
        return 'PROCESSING';
      case 'PROCESSING':
        return 'DISPATCHED';
      case 'DISPATCHED':
        return 'IN_PROGRESS';
      case 'IN_PROGRESS':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  String _actionLabel(String module, String status) {
    final normalizedStatus = status.toUpperCase();
    if (module == 'services') {
      switch (normalizedStatus) {
        case 'PENDING':
          return 'Confirm';
        case 'CONFIRMED':
        case 'PROCESSING':
          return 'Mark on the way';
        case 'DISPATCHED':
        case 'IN_PROGRESS':
          return 'Mark work done';
        default:
          return 'Done';
      }
    }
    switch (normalizedStatus) {
      case 'PENDING':
        return 'Accept';
      case 'CONFIRMED':
        return 'Start Cleaning';
      case 'PROCESSING':
        return 'Send Out';
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return 'Complete';
      default:
        return 'Done';
    }
  }

  String _statusLabel(String module, String status) {
    final normalizedStatus = status.toUpperCase();
    if (module == 'services') {
      switch (normalizedStatus) {
        case 'PENDING':
          return 'Pending';
        case 'CONFIRMED':
          return 'Confirmed';
        case 'PROCESSING':
          return 'On the way';
        case 'DISPATCHED':
          return 'On the way';
        case 'IN_PROGRESS':
          return 'Work in progress';
        case 'COMPLETED':
          return 'Work done';
        default:
          return normalizedStatus.replaceAll('_', ' ');
      }
    }
    return normalizedStatus.replaceAll('_', ' ');
  }

  Future<void> _advanceStatus() async {
    final module = _module();
    final currentStatus = _status();
    final next = _nextStatus(module, currentStatus);
    if (next == null || _updating || _orderId.isEmpty) return;

    setState(() => _updating = true);
    try {
      await ApiClient.post('/pro/${widget.userId}/provider-order-status', {
        'orderId': _orderId,
        'status': next,
      });
      await _loadDetail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking updated to ${_statusLabel(module, next)}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  Map<String, dynamic> _firstItemMetadata() {
    final items = (_detail?['items'] as List<dynamic>? ?? const <dynamic>[]);
    if (items.isEmpty) return const <String, dynamic>{};
    final first = Map<String, dynamic>.from(items.first as Map);
    final metadata = first['metadata'];
    if (metadata is Map) {
      return Map<String, dynamic>.from(metadata);
    }
    return const <String, dynamic>{};
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
  }

  String _listLabel(dynamic value) {
    if (value is! List) return '';
    final items = value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (items.isEmpty) return '';
    return items.join(', ');
  }

  List<String> _statusSteps(String module) {
    if (module == 'services') {
      return const ['PENDING', 'CONFIRMED', 'DISPATCHED', 'COMPLETED'];
    }
    return const [
      'PENDING',
      'CONFIRMED',
      'PROCESSING',
      'DISPATCHED',
      'IN_PROGRESS',
      'COMPLETED',
    ];
  }

  int _statusIndex(List<String> steps, String status) {
    final direct = steps.indexOf(status.toUpperCase());
    if (direct >= 0) return direct;
    if (status.toUpperCase() == 'IN_PROGRESS' && steps.contains('DISPATCHED')) {
      return steps.indexOf('DISPATCHED');
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final module = _module();
    final status = _status();
    final nextStatus = _nextStatus(module, status);
    final metadata = _firstItemMetadata();
    final bookingFormat = metadata['bookingFormat'] is Map
        ? Map<String, dynamic>.from(metadata['bookingFormat'] as Map)
        : const <String, dynamic>{};
    final detailItems =
        (_detail?['items'] as List<dynamic>? ?? const <dynamic>[]);
    final firstDetailItem = detailItems.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(detailItems.first as Map);
    final serviceName =
        metadata['serviceName']?.toString().trim().isNotEmpty == true
        ? metadata['serviceName'].toString().trim()
        : firstDetailItem['name']?.toString().trim().isNotEmpty == true
        ? firstDetailItem['name'].toString().trim()
        : '';
    final bookingMode = metadata['bookingMode']?.toString().trim() ?? '';
    final scheduledDate = metadata['scheduledDate']?.toString().trim() ?? '';
    final timeSlot = metadata['timeSlot']?.toString().trim() ?? '';
    final queueType = widget.queueItem['queueType']?.toString().trim() ?? '';
    final distanceKm = widget.queueItem['distanceKm'] as num?;
    final dispatchMode = metadata['dispatchMode']?.toString().trim() ?? '';
    final serviceList = _listLabel(bookingFormat['services']);
    final supplyMode = bookingFormat['supplyMode']?.toString().trim() ?? '';
    final bringSupplies = bookingFormat['bringSupplies'] == true;
    final amount = widget.queueItem['amount']?.toString().trim() ?? '';
    final customerName =
        _detail?['customerName']?.toString().trim().isNotEmpty == true
        ? _detail!['customerName'].toString().trim()
        : widget.queueItem['customerName']?.toString().trim().isNotEmpty == true
        ? widget.queueItem['customerName'].toString().trim()
        : 'Customer';
    final customerPhone =
        _detail?['customerPhone']?.toString().trim().isNotEmpty == true
        ? _detail!['customerPhone'].toString().trim()
        : widget.queueItem['customerPhone']?.toString().trim() ?? '';
    final customerUserId =
        _detail?['userId']?.toString().trim().isNotEmpty == true
        ? _detail!['userId'].toString().trim()
        : widget.queueItem['customerUserId']?.toString().trim() ?? '';
    final providerId =
        widget.queueItem['providerId']?.toString().trim() ??
        metadata['assignedProviderId']?.toString().trim() ??
        metadata['providerId']?.toString().trim() ??
        '';
    final rawModuleType =
        widget.queueItem['moduleType']
                ?.toString()
                .toUpperCase()
                .trim()
                .isNotEmpty ==
            true
        ? widget.queueItem['moduleType'].toString().toUpperCase().trim()
        : (_detail?['moduleType']?.toString().toUpperCase().trim() ?? '');
    final title =
        widget.queueItem['title']?.toString().trim().isNotEmpty == true
        ? widget.queueItem['title'].toString().trim()
        : 'Service booking';
    final subtitle =
        widget.queueItem['subtitle']?.toString().trim() ??
        _detail?['moduleName']?.toString().trim() ??
        '';
    final address = metadata['address']?.toString().trim().isNotEmpty == true
        ? metadata['address'].toString().trim()
        : widget.queueItem['address']?.toString().trim() ?? '';
    final notes = _detail?['notes']?.toString().trim().isNotEmpty == true
        ? _detail!['notes'].toString().trim()
        : widget.queueItem['notes']?.toString().trim() ?? '';

    final steps = _statusSteps(module);
    final currentStepIndex = _statusIndex(steps, status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppColors.homeServices,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.homeServices.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(subtitle),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          _statusLabel(module, status),
                          style: TextStyle(
                            color: AppColors.homeServices,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(
                            _detail?['createdAt'] ??
                                widget.queueItem['createdAt'],
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request details',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          if (serviceName.isNotEmpty)
                            Text('Service: $serviceName'),
                          if (amount.isNotEmpty) Text('Amount: $amount'),
                          if (bookingMode.isNotEmpty)
                            Text('Mode: $bookingMode'),
                          if (scheduledDate.isNotEmpty)
                            Text('Date: $scheduledDate'),
                          if (timeSlot.isNotEmpty) Text('Time slot: $timeSlot'),
                          if (queueType.isNotEmpty)
                            Text(
                              'Queue: ${queueType == 'open' ? 'Open nearby requests' : 'Assigned to you'}',
                            ),
                          if (distanceKm != null)
                            Text(
                              'Distance: ${distanceKm.toStringAsFixed(1)} km from your zone center',
                            ),
                          if (dispatchMode.isNotEmpty)
                            Text('Dispatch: $dispatchMode'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(customerName),
                          if (customerPhone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(customerPhone),
                          ],
                          if (address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(address),
                          ],
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(notes),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (bookingFormat.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'House-help booking format',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            if ((bookingFormat['type']?.toString() ?? '')
                                .isNotEmpty)
                              Text('Type: ${bookingFormat['type']}'),
                            if ((bookingFormat['shift']?.toString() ?? '')
                                .isNotEmpty)
                              Text('Shift: ${bookingFormat['shift']}'),
                            if ((bookingFormat['homeSize']?.toString() ?? '')
                                .isNotEmpty)
                              Text('Home size: ${bookingFormat['homeSize']}'),
                            if ((bookingFormat['arrivalTarget']?.toString() ??
                                    '')
                                .isNotEmpty)
                              Text(
                                'Arrival: ${bookingFormat['arrivalTarget']}',
                              ),
                            if (serviceList.isNotEmpty)
                              Text('Services: $serviceList'),
                            if (supplyMode.isNotEmpty)
                              Text('Supplies mode: $supplyMode'),
                            if (bookingFormat.containsKey('bringSupplies'))
                              Text(
                                'Bring supplies: ${bringSupplies ? 'Yes' : 'No'}',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status timeline',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 10),
                          ...steps.asMap().entries.map((entry) {
                            final index = entry.key;
                            final step = entry.value;
                            final reached = index <= currentStepIndex;
                            final isCurrent = status.toUpperCase() == step;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    reached
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: reached
                                        ? AppColors.homeServices
                                        : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _statusLabel(module, step),
                                      style: TextStyle(
                                        fontWeight: isCurrent
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: reached
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (customerPhone.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () =>
                              launchPhoneCall(context, customerPhone),
                          icon: const Icon(Icons.call_outlined, size: 18),
                          label: const Text('Call'),
                        ),
                      if (customerUserId.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => openProConversation(
                            context,
                            customerUserId: customerUserId,
                            participantUserId: widget.userId,
                            moduleType: module == 'laundry'
                                ? 'LAUNDRY'
                                : (rawModuleType == 'HOUSE_HELP'
                                      ? 'HOUSE_HELP'
                                      : 'HOME_SERVICES'),
                            entityType: 'HOME_SERVICE_PROVIDER',
                            entityId: providerId.isNotEmpty
                                ? providerId
                                : _orderId,
                            title: widget.businessName,
                            subtitle: 'Service request',
                            accentColor: '#1A9A77',
                            metadata: {
                              'orderId': _orderId,
                              if (providerId.isNotEmpty)
                                'providerId': providerId,
                              if ((metadata['categorySlug']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ??
                                  false))
                                'categorySlug': metadata['categorySlug'],
                            },
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Message'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (nextStatus != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updating ? null : _advanceStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.homeServices,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _updating
                              ? 'Updating...'
                              : _actionLabel(module, status),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
