import '/pro/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/utils/pro_message_launcher.dart';
import 'provider_job_detail_screen.dart';

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

  AppLocalizations get l10n => AppLocalizations.of(context)!;

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
        case ProModule.ecologicalCleaning:
          modules.add('services');
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
      }).toList(growable: false);
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
    final normalizedStatus = status.toUpperCase();
    if (module == 'services') {
      switch (normalizedStatus) {
        case 'PENDING':
          return l10n.confirmAction;
        case 'CONFIRMED':
        case 'PROCESSING':
          return l10n.onTheWay;
        case 'DISPATCHED':
        case 'IN_PROGRESS':
          return l10n.workDone;
        default:
          return l10n.done;
      }
    }
    switch (status.toUpperCase()) {
      case 'PENDING':
        return l10n.accept;
      case 'CONFIRMED':
        return module == 'laundry' ? l10n.startCleaning : l10n.startJob;
      case 'PROCESSING':
        return module == 'laundry' ? l10n.sendOut : l10n.complete;
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return l10n.complete;
      default:
        return l10n.done;
    }
  }

  String _statusLabel(String module, String status) {
    final normalizedStatus = status.toUpperCase();
    if (module == 'services') {
      switch (normalizedStatus) {
        case 'PENDING':
          return l10n.pending;
        case 'CONFIRMED':
          return l10n.confirmed;
        case 'PROCESSING':
          return l10n.onTheWay;
        case 'DISPATCHED':
          return l10n.onTheWay;
        case 'IN_PROGRESS':
          return l10n.workInProgress;
        case 'COMPLETED':
          return l10n.workDone;
        default:
          return normalizedStatus.replaceAll('_', ' ');
      }
    }
    return normalizedStatus.replaceAll('_', ' ');
  }

  Future<void> _openDetails(Map<String, dynamic> item) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProviderJobDetailScreen(
          userId: widget.userId,
          businessName: widget.businessName,
          queueItem: item,
        ),
      ),
    );
    if (mounted) {
      await _loadQueue();
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
          content: Text(
            '${l10n.job} ${l10n.updatedTo} ${nextStatus.replaceAll('_', ' ')}.',
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
    final filteredItems = _items.where((item) {
      final module = item['module']?.toString() ?? '';
      if (!_allowedModuleSet.contains(module)) {
        return false;
      }
      if (_selectedModule != 'all' && module != _selectedModule) {
        return false;
      }
      final rawModuleType = item['moduleType']?.toString().toUpperCase() ?? '';
      if (rawModuleType == 'HOUSE_HELP') {
        final hasHouseHelpModule =
            widget.activeModules.any((m) => m == ProModule.services);
        if (!hasHouseHelpModule) return false;
      }
      return _matchesStatus(item);
    }).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moduleJobsTitle(widget.businessName)),
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
                  _QueueMetric(label: l10n.active, value: '$activeCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: l10n.completed, value: '$completedCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: l10n.pipelines, value: '$pipelineCount'),
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
                  _buildFilterChip(
                    label: _moduleLabel(module),
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
                  _buildFilterChip(
                    label: _queueFilterLabel(status),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noJobsMatchFilters),
                ),
              )
            else
              ...filteredItems.map(_buildJobCard),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      backgroundColor: AppColors.white,
      selectedColor: AppColors.homeServices.withValues(alpha: 0.14),
      side: BorderSide(
        color: selected ? AppColors.homeServices : AppColors.lightGrey,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.homeServices : AppColors.darkGrey,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
                    item['title']?.toString() ?? l10n.jobLabel,
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
              l10n.createdDate(createdAt),
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
              '${_statusLabel(module, status)}${amount.isEmpty ? '' : ' • $amount'}',
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
                OutlinedButton.icon(
                  onPressed: () => _openDetails(item),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(l10n.detailsAction),
                ),
                if (customerPhone.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => launchPhoneCall(context, customerPhone),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: Text(l10n.callAction),
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
                    label: Text(l10n.messageAction),
                  ),
                if (nextStatus != null)
                  ElevatedButton(
                    onPressed: isBusy ? null : () => _advanceItem(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _moduleColor(module),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isBusy ? l10n.updating : _actionLabel(module, status),
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
        return l10n.servicesLabel;
      case 'laundry':
        return l10n.laundryLabel;
      default:
        return l10n.allLabel;
    }
  }

  String _queueFilterLabel(String status) {
    switch (status) {
      case 'active':
        return l10n.active;
      case 'completed':
        return l10n.completed;
      default:
        return l10n.allLabel;
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
    if (raw == null || raw.isEmpty) return l10n.recently;
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
