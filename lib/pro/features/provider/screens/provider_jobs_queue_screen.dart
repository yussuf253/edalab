import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/utils/pro_message_launcher.dart';

class ProviderJobsQueueScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final String initialModule;
  final List<ProModule> activeModules;

  const ProviderJobsQueueScreen({
    super.key,
    required this.userId,
    required this.businessName,
    this.initialModule = 'all',
    this.activeModules = const [],
  });

  @override
  State<ProviderJobsQueueScreen> createState() =>
      _ProviderJobsQueueScreenState();
}

class _ProviderJobsQueueScreenState extends State<ProviderJobsQueueScreen> {
  final Set<String> _busyIds = <String>{};
  List<Map<String, dynamic>> _items = const [];
  bool _isLoading = true;
  String _selectedModule = 'all';
  String _selectedStatus = 'active';

  late final List<String> _allowedModules = _resolveAllowedModules();
  late final Set<String> _allowedModuleSet = _allowedModules.toSet();

  @override
  void initState() {
    super.initState();
    _selectedModule = _normalizeSelectedModule(widget.initialModule);
    _loadQueue();
  }

  List<String> _resolveAllowedModules() {
    final modules = <String>[];
    for (final module in widget.activeModules) {
      switch (module) {
        case ProModule.services:
          modules.add('services');
          break;
        case ProModule.laundry:
          modules.add('laundry');
          break;
        default:
          break;
      }
    }
    if (modules.isEmpty) {
      return const ['services'];
    }
    return modules.toSet().toList(growable: false);
  }

  String _normalizeSelectedModule(String requested) {
    if (requested == 'all') {
      return _allowedModules.length > 1 ? 'all' : _allowedModules.first;
    }
    if (_allowedModuleSet.contains(requested)) {
      return requested;
    }
    return _allowedModules.length > 1 ? 'all' : _allowedModules.first;
  }

  String _canonicalModule(String module) {
    switch (module) {
      case 'home_services':
      case 'house_help':
      case 'services':
        return 'services';
      default:
        return module;
    }
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get(
        '/pro/${widget.userId}/provider-queue',
        forceRefresh: true,
      );
      final items = (response as List)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .map((entry) {
            final normalized = Map<String, dynamic>.from(entry);
            normalized['module'] = _canonicalModule(
              normalized['module']?.toString() ?? '',
            );
            return normalized;
          })
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

  String? _nextStatus(String module, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'CONFIRMED';
      case 'CONFIRMED':
        return module == 'laundry' ? 'PROCESSING' : 'IN_PROGRESS';
      case 'PROCESSING':
        return module == 'laundry' ? 'DISPATCHED' : 'COMPLETED';
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  String _actionLabel(String module, String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Accept';
      case 'CONFIRMED':
        return module == 'laundry' ? 'Start Cleaning' : 'Start Job';
      case 'PROCESSING':
        return module == 'laundry' ? 'Send Out' : 'Complete';
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return 'Complete';
      default:
        return 'Done';
    }
  }

  bool _matchesStatus(Map<String, dynamic> item) {
    final status = item['status']?.toString().toUpperCase() ?? '';
    switch (_selectedStatus) {
      case 'all':
        return true;
      case 'active':
        return !{'COMPLETED', 'CANCELLED', 'REFUNDED'}.contains(status);
      case 'completed':
        return status == 'COMPLETED';
      default:
        return status == _selectedStatus.toUpperCase();
    }
  }

  Future<void> _advanceItem(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    final module = item['module']?.toString() ?? '';
    final nextStatus = _nextStatus(module, item['status']?.toString() ?? '');
    if (nextStatus == null || id.isEmpty) return;

    setState(() => _busyIds.add(id));
    try {
      await ApiClient.post('/pro/${widget.userId}/provider-order-status', {
        'orderId': id,
        'status': nextStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Job updated to ${nextStatus.replaceAll('_', ' ')}.'),
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
    final activeCount = _items.where((item) {
      final status = item['status']?.toString().toUpperCase() ?? '';
      return !{'COMPLETED', 'CANCELLED', 'REFUNDED'}.contains(status);
    }).length;
    final completedCount = _items
        .where(
          (item) =>
              (item['status']?.toString().toUpperCase() ?? '') == 'COMPLETED',
        )
        .length;
    final pipelineCount = _items
        .map((item) => item['module']?.toString() ?? '')
        .where((module) => _allowedModuleSet.contains(module))
        .where((module) => module.isNotEmpty)
        .toSet()
        .length;
    final filteredItems = _items
        .where((item) {
          final module = item['module']?.toString() ?? '';
          if (!_allowedModuleSet.contains(module)) {
            return false;
          }
          if (_selectedModule != 'all' && module != _selectedModule) {
            return false;
          }
          return _matchesStatus(item);
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.businessName} Jobs'),
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
                  _QueueMetric(label: 'Active', value: '$activeCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: 'Completed', value: '$completedCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: 'Pipelines', value: '$pipelineCount'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final module in [
                  if (_allowedModules.length > 1) 'all',
                  ..._allowedModules,
                ])
                  ChoiceChip(
                    label: Text(_moduleLabel(module)),
                    selected: _selectedModule == module,
                    onSelected: (_) => setState(() => _selectedModule = module),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in ['active', 'completed', 'all'])
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
                    Icon(Icons.handyman_outlined, size: 34),
                    SizedBox(height: 10),
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Loading provider jobs...'),
                  ],
                ),
              )
            else if (filteredItems.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No jobs match the current queue filters.'),
                ),
              )
            else
              ...filteredItems.map(_buildJobCard),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final status = item['status']?.toString() ?? '';
    final module = item['module']?.toString() ?? '';
    final rawModuleType = item['moduleType']?.toString().toUpperCase() ?? '';
    final address = item['address']?.toString() ?? '';
    final customerName = item['customerName']?.toString() ?? 'Customer';
    final customerPhone = item['customerPhone']?.toString() ?? '';
    final customerUserId = item['customerUserId']?.toString() ?? '';
    final providerId = item['providerId']?.toString() ?? '';
    final categorySlug = item['categorySlug']?.toString().trim() ?? '';
    final amount = item['amount']?.toString() ?? '';
    final notes = item['notes']?.toString() ?? '';
    final createdAt = _formatDate(item['createdAt']);
    final isBusy = _busyIds.contains(id);
    final nextStatus = _nextStatus(module, status);
    final conversationModuleType = module == 'laundry'
        ? 'LAUNDRY'
        : (rawModuleType == 'HOUSE_HELP' ? 'HOUSE_HELP' : 'HOME_SERVICES');
    final conversationCategorySlug = categorySlug.isNotEmpty
        ? categorySlug
        : (rawModuleType == 'HOUSE_HELP' ? 'house-help' : module);

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
                    item['title']?.toString() ?? 'Job',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  _moduleLabel(module),
                  style: TextStyle(
                    color: _moduleColor(module),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item['subtitle']?.toString() ?? ''),
            const SizedBox(height: 8),
            Text(
              '$customerName${customerPhone.isEmpty ? '' : ' • $customerPhone'}',
            ),
            const SizedBox(height: 4),
            Text(
              'Created $createdAt',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(address, style: TextStyle(color: Colors.grey.shade700)),
            ],
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(notes, style: TextStyle(color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 12),
            Text(
              '${status.replaceAll('_', ' ')}${amount.isEmpty ? '' : ' • $amount'}',
              style: TextStyle(
                color: _moduleColor(module),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (customerPhone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => launchPhoneCall(context, customerPhone),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Call'),
                  ),
                if (customerUserId.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openProConversation(
                      context,
                      customerUserId: customerUserId,
                      participantUserId: widget.userId,
                      moduleType: conversationModuleType,
                      entityType: 'HOME_SERVICE_PROVIDER',
                      entityId: module == 'laundry'
                          ? id
                          : (providerId.isNotEmpty ? providerId : id),
                      title: widget.businessName,
                      subtitle: '${_moduleLabel(module)} request',
                      accentColor: '#1A9A77',
                      metadata: {
                        'orderId': id,
                        if (providerId.isNotEmpty) 'providerId': providerId,
                        'customerPhone': customerPhone,
                        'categorySlug': conversationCategorySlug,
                        'moduleType': conversationModuleType,
                      },
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                  ),
                if (nextStatus != null)
                  ElevatedButton(
                    onPressed: isBusy ? null : () => _advanceItem(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _moduleColor(module),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isBusy ? 'Updating...' : _actionLabel(module, status),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _moduleLabel(String module) {
    switch (module) {
      case 'services':
        return 'Services';
      case 'laundry':
        return 'Laundry';
      default:
        return 'All';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      default:
        return 'All';
    }
  }

  Color _moduleColor(String module) {
    switch (module) {
      case 'laundry':
        return AppColors.laundry;
      default:
        return AppColors.homeServices;
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
