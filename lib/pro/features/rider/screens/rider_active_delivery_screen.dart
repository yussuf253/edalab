import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../features/ride/services/ride_route_service.dart';
import '../../../../features/ride/utils/ride_map_launcher.dart';
import '../../../../features/ride/widgets/ride_route_preview.dart';
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

  double _progressForStatus(String status) {
    switch (status) {
      case 'COMPLETED':
        return 1;
      case 'IN_PROGRESS':
        return 0.66;
      case 'DISPATCHED':
        return 0.24;
      default:
        return 0.12;
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

  Map<String, dynamic>? _firstItemMetadata() {
    final items = _order?['items'] as List<dynamic>? ?? const [];
    if (items.isEmpty) return null;
    final first = items.first;
    if (first is! Map) return null;
    final metadata = first['metadata'];
    if (metadata is! Map) return null;
    return Map<String, dynamic>.from(metadata);
  }

  RideMapPoint? _mapPointFrom(
    dynamic raw, {
    required String fallbackLabel,
    required Color color,
    required IconData icon,
  }) {
    return rideMapPointFromJson(
      raw,
      fallbackLabel: fallbackLabel,
      color: color,
      icon: icon,
    );
  }

  double _distanceKm(Map<String, dynamic>? metadata) {
    final raw = metadata?['distanceKm'] ?? _order?['distanceKm'];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 4.5;
    return 4.5;
  }

  RideMapPoint _defaultPickup(String label) {
    return RideMapPoint(
      label: label,
      latitude: 11.5886,
      longitude: 43.1457,
      color: AppColors.success,
      icon: Icons.storefront_rounded,
    );
  }

  RideMapPoint _pickupPoint({
    required String label,
    Map<String, dynamic>? metadata,
  }) {
    final fromMetadata = _mapPointFrom(
      metadata?['pickup'] ?? metadata?['pickupLocation'] ?? metadata?['store'],
      fallbackLabel: label,
      color: AppColors.success,
      icon: Icons.storefront_rounded,
    );
    if (fromMetadata != null) return fromMetadata;
    final flattenedMetadata = _mapPointFrom(
      metadata,
      fallbackLabel: label,
      color: AppColors.success,
      icon: Icons.storefront_rounded,
    );
    if (flattenedMetadata != null) return flattenedMetadata;
    return _defaultPickup(label);
  }

  RideMapPoint _destinationPoint({
    required RideMapPoint pickup,
    required String label,
    Map<String, dynamic>? metadata,
  }) {
    final fromMetadata = _mapPointFrom(
      metadata?['destination'] ??
          metadata?['deliveryLocation'] ??
          metadata?['dropoff'],
      fallbackLabel: label,
      color: AppColors.accent,
      icon: Icons.location_on_rounded,
    );
    if (fromMetadata != null) return fromMetadata;
    return estimateRideDestinationPoint(
      origin: pickup,
      distanceKm: _distanceKm(metadata),
      label: label,
      color: AppColors.accent,
      icon: Icons.location_on_rounded,
      bearingDegrees: 132,
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final metadata = _firstItemMetadata();
    final items = (order?['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final firstItem = items.isNotEmpty ? items.first : null;

    final status = order?['status']?.toString().toUpperCase() ?? 'DISPATCHED';
    final pickupTitle =
        order?['moduleName']?.toString() ??
        firstItem?['brand']?.toString() ??
        firstItem?['name']?.toString() ??
        'Pickup point';
    final destinationLabel =
        order?['deliveryLabel']?.toString() ??
        order?['address']?.toString() ??
        'Customer destination';
    final customerName =
        order?['customerName']?.toString() ??
        metadata?['customerName']?.toString() ??
        'Customer';
    final customerPhone =
        order?['customerPhone']?.toString() ??
        metadata?['customerPhone']?.toString() ??
        '';
    final customerUserId =
        order?['userId']?.toString() ??
        metadata?['customerUserId']?.toString() ??
        '';
    final lineCount = items.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity'] as num?)?.toInt() ?? 0),
    );

    final pickupPoint = _pickupPoint(label: pickupTitle, metadata: metadata);
    final destinationPoint = _destinationPoint(
      pickup: pickupPoint,
      label: destinationLabel,
      metadata: metadata,
    );
    final driverPoint = interpolateRideMapPoint(
      from: pickupPoint,
      to: destinationPoint,
      progress: _progressForStatus(status),
      label: order?['deliveryAssignee'] is Map
          ? (order!['deliveryAssignee'] as Map)['name']?.toString() ?? 'Courier'
          : 'Courier',
      color: AppColors.ride,
      icon: Icons.delivery_dining_rounded,
    );
    final routeDetails = metadata?['routeDetails'] is Map
        ? RideRouteDetails.fromJson(
            Map<String, dynamic>.from(metadata!['routeDetails'] as Map),
          )
        : null;
    final eta =
        order?['deliveryEta']?.toString() ??
        metadata?['durationLabel']?.toString() ??
        routeDetails?.durationLabel ??
        'ETA unavailable';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.46,
                width: double.infinity,
                child: RideRoutePreview(
                  title: 'Delivery route',
                  pickup: pickupPoint,
                  destination: destinationPoint,
                  driver: _isLoading ? null : driverPoint,
                  badgeLabel: _isLoading ? null : eta,
                  routePolyline: routeDetails?.polylinePoints,
                  overlayStatusIcon: _isLoading
                      ? Icons.local_shipping_outlined
                      : _error != null
                      ? Icons.error_outline_rounded
                      : null,
                  overlayStatusMessage: _isLoading
                      ? 'Loading assigned delivery...'
                      : _error,
                  actionLabel: 'Open map',
                  onActionTap: () => openRideRouteInMaps(
                    context,
                    pickupLabel: pickupTitle,
                    destinationLabel: destinationLabel,
                    pickupPoint: pickupPoint,
                    destinationPoint: destinationPoint,
                  ),
                  height: MediaQuery.of(context).size.height * 0.46,
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.lightGrey,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(customerName, style: AppTextStyles.h4),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.food.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' '),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.food,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.extraLightGrey,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.storefront_rounded,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              pickupTitle,
                                              style: AppTextStyles.labelMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            color: AppColors.accent,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              destinationLabel,
                                              style: AppTextStyles.labelMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.extraLightGrey,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.food.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.inventory_2_outlined,
                                          color: AppColors.food,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order #${widget.orderId.substring(widget.orderId.length > 6 ? widget.orderId.length - 6 : 0)}',
                                              style: AppTextStyles.labelLarge,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$lineCount item(s) • $eta',
                                              style: AppTextStyles.caption,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
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
                                                participantUserId:
                                                    widget.userId,
                                                moduleType:
                                                    (order?['moduleType']
                                                                ?.toString() ??
                                                            'FOOD')
                                                        .toUpperCase(),
                                                entityType: 'DELIVERY',
                                                entityId: widget.orderId,
                                                title: pickupTitle,
                                                subtitle:
                                                    'Delivery in progress',
                                                accentColor: '#3BAA5C',
                                                metadata: {
                                                  'orderId': widget.orderId,
                                                  'customerPhone':
                                                      customerPhone,
                                                },
                                              ),
                                        icon: const Icon(
                                          Icons.chat_bubble_outline,
                                        ),
                                        label: const Text('Message'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
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
                ),
              ),
            ],
          ),
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
