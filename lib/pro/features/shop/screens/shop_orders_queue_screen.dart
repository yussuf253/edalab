import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/utils/pro_message_launcher.dart';
import '../../../l10n/app_localizations.dart';

class ShopOrdersQueueScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final String initialModule;
  final List<ProModule> activeModules;

  const ShopOrdersQueueScreen({
    super.key,
    required this.userId,
    required this.businessName,
    this.initialModule = 'all',
    this.activeModules = const [],
  });

  @override
  State<ShopOrdersQueueScreen> createState() => _ShopOrdersQueueScreenState();
}

class _ShopOrdersQueueScreenState extends State<ShopOrdersQueueScreen> {
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
        case ProModule.shopping:
          modules.add('shopping');
          break;
        case ProModule.food:
          modules.add('food');
          break;
        case ProModule.pharmacy:
          modules.add('pharmacy');
          break;
        default:
          break;
      }
    }
    if (modules.isEmpty) {
      return const ['shopping'];
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

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get(
        '/pro/${widget.userId}/shop-queue',
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

  String? _nextStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'CONFIRMED';
      case 'CONFIRMED':
        return 'PROCESSING';
      case 'PROCESSING':
        return 'DISPATCHED';
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return 'COMPLETED';
      default:
        return null;
    }
  }

  String _actionLabel(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return l10n.confirmAction;
      case 'CONFIRMED':
        return l10n.startPrepAction;
      case 'PROCESSING':
        return l10n.dispatchAction;
      case 'DISPATCHED':
      case 'IN_PROGRESS':
        return l10n.completeLabel;
      default:
        return l10n.doneLabel;
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

  String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return l10n.pending;
      case 'CONFIRMED':
        return l10n.confirmedStatus;
      case 'PROCESSING':
        return l10n.processingStatus;
      case 'DISPATCHED':
        return l10n.dispatchedStatus;
      case 'IN_PROGRESS':
        return l10n.inProgress;
      case 'COMPLETED':
        return l10n.completedLabel;
      default:
        return status.replaceAll('_', ' ');
    }
  }

  Future<void> _advanceItem(Map<String, dynamic> item, AppLocalizations l10n) async {
    final nextStatus = _nextStatus(item['status']?.toString() ?? '');
    final id = item['id']?.toString() ?? '';
    if (nextStatus == null || id.isEmpty) return;

    setState(() => _busyIds.add(id));
    try {
      await ApiClient.post('/pro/${widget.userId}/shop-order-status', {
        'orderId': id,
        'status': nextStatus,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.orderUpdatedTo(_statusLabel(nextStatus, l10n))),
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

  Future<void> _openPrescription(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final moduleCount = _items
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
        title: Text(l10n.shopQueueTitle(widget.businessName)),
        backgroundColor: AppColors.shopping,
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
                color: AppColors.shopping.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _QueueMetric(label: l10n.active, value: '$activeCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: l10n.completedLabel, value: '$completedCount'),
                  const SizedBox(width: 8),
                  _QueueMetric(label: l10n.modules, value: '$moduleCount'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final module in [
                    if (_allowedModules.length > 1) 'all',
                    ..._allowedModules,
                  ])
                    ChoiceChip(
                      label: Text(
                        _moduleLabel(module, l10n),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _selectedModule == module
                              ? _moduleColor(module)
                              : Colors.black87,
                        ),
                      ),
                      selectedColor: _moduleColor(
                        module,
                      ).withValues(alpha: 0.16),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: _selectedModule == module
                            ? _moduleColor(module)
                            : Colors.black26,
                      ),
                      showCheckmark: false,
                      selected: _selectedModule == module,
                      onSelected: (_) =>
                          setState(() => _selectedModule = module),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in ['active', 'completed', 'all'])
                    ChoiceChip(
                      label: Text(
                        _filterStatusLabel(status, l10n),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _selectedStatus == status
                              ? AppColors.shopping
                              : Colors.black87,
                        ),
                      ),
                      selectedColor: AppColors.shopping.withValues(alpha: 0.16),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: _selectedStatus == status
                            ? AppColors.shopping
                            : Colors.black26,
                      ),
                      showCheckmark: false,
                      selected: _selectedStatus == status,
                      onSelected: (_) =>
                          setState(() => _selectedStatus = status),
                    ),
                ],
              ),
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
                    const Icon(Icons.inventory_2_outlined, size: 34),
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(l10n.loadingOrderQueue),
                  ],
                ),
              )
            else if (filteredItems.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noOrdersMatch),
                ),
              )
            else
              ...filteredItems.map((item) => _buildOrderCard(item, l10n)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> item, AppLocalizations l10n) {
    final id = item['id']?.toString() ?? '';
    final status = item['status']?.toString() ?? '';
    final module = item['module']?.toString() ?? '';
    final address = item['address']?.toString() ?? '';
    final customerName = item['customerName']?.toString() ?? l10n.customerLabel;
    final customerPhone = item['customerPhone']?.toString() ?? '';
    final customerUserId = item['customerUserId']?.toString() ?? '';
    final amount = item['amount']?.toString() ?? '';
    final notes = item['notes']?.toString() ?? '';
    final createdAt = _formatDate(item['createdAt'], l10n);
    final isBusy = _busyIds.contains(id);
    final nextStatus = _nextStatus(status);
    final isPrescriptionRequest = item['prescriptionRequest'] == true;
    final prescription = item['prescription'] is Map
        ? Map<String, dynamic>.from(item['prescription'] as Map)
        : const <String, dynamic>{};
    final prescriptionImageUrl = prescription['imageUrl']?.toString() ?? '';
    final prescriptionPharmacy = prescription['pharmacy']?.toString() ?? '';
    final prescriptionNote = prescription['note']?.toString() ?? '';

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
                    item['title']?.toString() ?? l10n.orderLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  _moduleLabel(module, l10n),
                  style: TextStyle(
                    color: _moduleColor(module),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isPrescriptionRequest) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.pharmacy.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.prescriptionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pharmacy,
                      ),
                    ),
                  ),
                ],
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
            if (isPrescriptionRequest &&
                (prescriptionPharmacy.isNotEmpty ||
                    prescriptionNote.isNotEmpty ||
                    prescriptionImageUrl.isNotEmpty)) ...[
              const SizedBox(height: 8),
              if (prescriptionPharmacy.isNotEmpty)
                Text(
                  '${l10n.pharmacyLabel}: $prescriptionPharmacy',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              if (prescriptionNote.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  '${l10n.noteLabel}: $prescriptionNote',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              '${_statusLabel(status, l10n)}${amount.isEmpty ? '' : ' • $amount'}',
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
                    label: Text(l10n.callAction),
                  ),
                if (customerUserId.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => openProConversation(
                      context,
                      customerUserId: customerUserId,
                      participantUserId: widget.userId,
                      moduleType: _messageModuleType(module),
                      entityType: 'SHOP',
                      entityId: id,
                      title: widget.businessName,
                      subtitle: l10n.moduleDeliverySubtitle(_moduleLabel(module, l10n)),
                      accentColor: '#039D55',
                      metadata: {
                        'orderId': id,
                        'merchantName': widget.businessName,
                        'customerPhone': customerPhone,
                      },
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(l10n.messageAction),
                  ),
                if (nextStatus != null)
                  ElevatedButton(
                    onPressed: isBusy ? null : () => _advanceItem(item, l10n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _moduleColor(module),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isBusy ? l10n.working : _actionLabel(status, l10n)),
                  ),
                if (prescriptionImageUrl.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _openPrescription(prescriptionImageUrl),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: Text(l10n.viewRxAction),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _moduleLabel(String module, AppLocalizations l10n) {
    switch (module) {
      case 'shopping':
        return l10n.shoppingLabel;
      case 'food':
        return l10n.foodLabel;
      case 'pharmacy':
        return l10n.pharmacyLabel;
      default:
        return l10n.allLabel;
    }
  }

  String _filterStatusLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'active':
        return l10n.active;
      case 'completed':
        return l10n.completedLabel;
      default:
        return l10n.allLabel;
    }
  }

  Color _moduleColor(String module) {
    switch (module) {
      case 'food':
        return AppColors.food;
      case 'pharmacy':
        return AppColors.pharmacy;
      default:
        return AppColors.shopping;
    }
  }

  String _formatDate(dynamic value, AppLocalizations l10n) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return l10n.recently;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, h:mm a').format(parsed.toLocal());
  }

  String _messageModuleType(String module) {
    switch (module) {
      case 'food':
        return 'FOOD';
      case 'pharmacy':
        return 'PHARMACY';
      default:
        return 'SHOPPING';
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
