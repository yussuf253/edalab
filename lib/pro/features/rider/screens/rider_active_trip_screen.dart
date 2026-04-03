import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../core/utils/pro_message_launcher.dart';
import '../../../core/widgets/swipeable_button.dart';

class RiderActiveTripScreen extends StatefulWidget {
  final String rideId;
  final String userId;

  const RiderActiveTripScreen({
    super.key,
    required this.rideId,
    required this.userId,
  });

  @override
  State<RiderActiveTripScreen> createState() => _RiderActiveTripScreenState();
}

class _RiderActiveTripScreenState extends State<RiderActiveTripScreen> {
  Map<String, dynamic>? _ride;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRide();
  }

  Future<void> _loadRide() async {
    try {
      final response = await ApiClient.get('/rides/${widget.rideId}');
      if (!mounted) return;
      setState(() {
        _ride = Map<String, dynamic>.from(response as Map);
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
      case 'DRIVER_ARRIVING':
        return 'Swipe to Start Trip';
      case 'IN_PROGRESS':
        return 'Swipe to Complete Trip';
      case 'COMPLETED':
        return 'Trip Completed';
      default:
        return 'Swipe to Arrive';
    }
  }

  String _nextStatus(String status) {
    switch (status) {
      case 'DRIVER_ARRIVING':
        return 'IN_PROGRESS';
      case 'IN_PROGRESS':
        return 'COMPLETED';
      case 'COMPLETED':
        return 'COMPLETED';
      default:
        return 'DRIVER_ARRIVING';
    }
  }

  Future<void> _advanceStatus() async {
    final ride = _ride;
    if (_isUpdating || ride == null) return;
    final currentStatus =
        ride['status']?.toString().toUpperCase() ?? 'ACCEPTED';
    final nextStatus = _nextStatus(currentStatus);
    if (nextStatus == currentStatus) return;

    setState(() => _isUpdating = true);
    try {
      await ApiClient.post('/pro/${widget.userId}/ride-status', {
        'rideId': widget.rideId,
        'status': nextStatus,
      });
      await _loadRide();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ride status updated to ${nextStatus.replaceAll('_', ' ')}.',
          ),
        ),
      );
      if (nextStatus == 'COMPLETED') {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update ride: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final pickup = ride?['pickup']?.toString() ?? 'Pickup location';
    final destination = ride?['destination']?.toString() ?? 'Dropoff location';
    final driverName = ride?['driverName']?.toString() ?? 'Driver';
    final vehicle = ride?['vehicle']?.toString() ?? 'Vehicle';
    final status = ride?['status']?.toString().toUpperCase() ?? 'ACCEPTED';
    final customerPhone =
        ride?['userPhone']?.toString() ??
        ride?['customerPhone']?.toString() ??
        '';
    final customerUserId = ride?['userId']?.toString() ?? '';

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
                          _error ?? 'Live rider map',
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
                                  'Pickup',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  pickup,
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
                                color: AppColors.ride.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_car_outlined,
                                color: AppColors.ride,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(Icons.flag_outlined, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dropoff: $destination',
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
                              Icons.person_outline,
                              color: AppColors.ride,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text('$driverName • $vehicle')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.wifi_tethering,
                              color: AppColors.ride,
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
                                label: const Text('Call rider'),
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
                                        moduleType: 'RIDE',
                                        entityType: 'RIDE',
                                        entityId: widget.rideId,
                                        title: driverName,
                                        subtitle: 'Ride in progress',
                                        accentColor: '#1D9070',
                                        metadata: {
                                          'rideId': widget.rideId,
                                          'driverPhone': ride?['driverPhone']
                                              ?.toString(),
                                          'destination': destination,
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
