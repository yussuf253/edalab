import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/utils/pro_message_launcher.dart';

class ShopOrdersQueueScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final String initialModule;

  const ShopOrdersQueueScreen({
    super.key,
    required this.userId,
    required this.businessName,
    this.initialModule = 'all',
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

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialModule;
    _loadQueue();
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

  String _actionLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Confirm';
      case 'CONFIRMED':
        return 'Start Prep';
      case 'PROCESSING':
        return 'Dispatch';
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
          content: Text('Order updated to ${nextStatus.replaceAll('_', ' ')}.'),
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
    final filteredItems = _items
        .where((item) {
          final module = item['module']?.toString() ?? '';
          if (_selectedModule != 'all' && module != _selectedModule) {
            return false;
          }
          return _matchesStatus(item);
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.businessName} Queue'),
        backgroundColor: AppColors.shopping,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadQueue,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final module in ['all', 'shopping', 'food', 'pharmacy'])
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
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredItems.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No orders match the current queue filters.'),
                ),
              )
            else
              ...filteredItems.map(_buildOrderCard),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final status = item['status']?.toString() ?? '';
    final module = item['module']?.toString() ?? '';
    final address = item['address']?.toString() ?? '';
    final customerName = item['customerName']?.toString() ?? 'Customer';
    final customerPhone = item['customerPhone']?.toString() ?? '';
    final customerUserId = item['customerUserId']?.toString() ?? '';
    final amount = item['amount']?.toString() ?? '';
    final notes = item['notes']?.toString() ?? '';
    final createdAt = _formatDate(item['createdAt']);
    final isBusy = _busyIds.contains(id);
    final nextStatus = _nextStatus(status);

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
                    item['title']?.toString() ?? 'Order',
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
                      moduleType: _messageModuleType(module),
                      entityType: 'SHOP',
                      entityId: id,
                      title: widget.businessName,
                      subtitle: '${_moduleLabel(module)} order',
                      accentColor: '#039D55',
                      metadata: {
                        'orderId': id,
                        'merchantName': widget.businessName,
                        'customerPhone': customerPhone,
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
                    child: Text(isBusy ? 'Updating...' : _actionLabel(status)),
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
      case 'shopping':
        return 'Shopping';
      case 'food':
        return 'Food';
      case 'pharmacy':
        return 'Pharmacy';
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
      case 'food':
        return AppColors.food;
      case 'pharmacy':
        return AppColors.pharmacy;
      default:
        return AppColors.shopping;
    }
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return 'recently';
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
