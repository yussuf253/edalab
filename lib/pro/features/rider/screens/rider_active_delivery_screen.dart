import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/utils/pro_message_launcher.dart';
import '../../../core/widgets/swipeable_button.dart';

class RiderActiveDeliveryScreen extends StatefulWidget {
  final String orderId;
  final String userId;

  const RiderActiveDeliveryScreen({
    super.key,
    required this.orderId,
    required this.userId,
  });

  @override
  State<RiderActiveDeliveryScreen> createState() =>
      _RiderActiveDeliveryScreenState();
}

class _RiderActiveDeliveryScreenState extends State<RiderActiveDeliveryScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final response = await ApiClient.get('/orders/detail/${widget.orderId}');
      if (!mounted) return;
      setState(() {
        _order = Map<String, dynamic>.from(response as Map);
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  String _actionLabel(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'Swipe to Complete Delivery';
      case 'COMPLETED':
        return 'Delivery Completed';
      default:
        return 'Swipe to Start Delivery';
    }
  }

  String _nextStatus(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'COMPLETED';
      case 'COMPLETED':
        return 'COMPLETED';
      default:
        return 'IN_PROGRESS';
    }
  }

  Future<void> _advanceStatus() async {
    final order = _order;
    if (_isUpdating || order == null) return;
    final currentStatus =
        order['status']?.toString().toUpperCase() ?? 'DISPATCHED';
    final nextStatus = _nextStatus(currentStatus);
    if (nextStatus == currentStatus) return;

    setState(() => _isUpdating = true);
    try {
      await ApiClient.post('/pro/${widget.userId}/delivery-status', {
        'orderId': widget.orderId,
        'status': nextStatus,
      });
      await _loadOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delivery status updated to ${nextStatus.replaceAll('_', ' ')}.',
          ),
        ),
      );
      if (nextStatus == 'COMPLETED') {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update delivery: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final items = (order?['items'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    final firstItem = items.isNotEmpty ? items.first : null;
    final status = order?['status']?.toString().toUpperCase() ?? 'DISPATCHED';
    final pickupTitle =
        order?['moduleName']?.toString() ??
        firstItem?['brand']?.toString() ??
        firstItem?['name']?.toString() ??
        'Order Pickup';
    final address =
        order?['address']?.toString() ??
        order?['deliveryLabel']?.toString() ??
        'Customer address not provided';
    final customerPhone =
        order?['customerPhone']?.toString() ??
        order?['userPhone']?.toString() ??
        '';
    final customerUserId = order?['userId']?.toString() ?? '';
    final lineCount = items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey.shade300,
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 100, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _error ?? 'Live delivery map',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pickup at:',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  pickupTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(Icons.notes, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Order #${widget.orderId.substring(widget.orderId.length > 6 ? widget.orderId.length - 6 : 0)} • $lineCount item(s)',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.food,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(address)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              color: AppColors.food,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Status: ${status.replaceAll('_', ' ')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: customerPhone.isEmpty
                                    ? null
                                    : () => launchPhoneCall(
                                        context,
                                        customerPhone,
                                      ),
                                icon: const Icon(Icons.call_outlined),
                                label: const Text('Call customer'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: customerUserId.isEmpty
                                    ? null
                                    : () => openProConversation(
                                        context,
                                        customerUserId: customerUserId,
                                        participantUserId: widget.userId,
                                        moduleType:
                                            (order?['moduleType']?.toString() ??
                                            'FOOD'),
                                        entityType: 'DELIVERY',
                                        entityId: widget.orderId,
                                        title: pickupTitle,
                                        subtitle: 'Delivery in progress',
                                        accentColor: '#3BAA5C',
                                        metadata: {
                                          'orderId': widget.orderId,
                                          'customerPhone': customerPhone,
                                        },
                                      ),
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Message'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        SwipeableButton(
                          label: _isUpdating
                              ? 'Updating...'
                              : _actionLabel(status),
                          baseColor: AppColors.ride,
                          onSwipe: _advanceStatus,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
