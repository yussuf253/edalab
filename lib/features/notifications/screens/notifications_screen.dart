import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<_Notif> _notifications = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() {
        _notifications = _fallbackNotifications;
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await ApiClient.get('/notifications/$userId');
      final notifications = (response as List)
          .map((item) => _Notif.fromApi(Map<String, dynamic>.from(item as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _notifications = notifications.isEmpty
            ? _fallbackNotifications
            : notifications;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _notifications = _fallbackNotifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    final unread = _notifications
        .where((item) => !item.read && item.id != null)
        .toList();
    for (final notification in unread) {
      try {
        await ApiClient.patch('/notifications/${notification.id}/read', {});
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _notifications = _notifications
          .map((item) => item.copyWith(read: true))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _notifications.any((item) => !item.read)
                ? _markAllRead
                : null,
            child: Text(
              'Mark all read',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notification.read
                        ? AppColors.white
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: notification.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          notification.icon,
                          color: notification.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: AppTextStyles.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.body,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notification.timeLabel,
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _Notif {
  final String? id;
  final String title;
  final String body;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final bool read;

  const _Notif({
    required this.id,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.icon,
    required this.color,
    required this.read,
  });

  factory _Notif.fromApi(Map<String, dynamic> json) {
    final type = json['type']?.toString().toUpperCase() ?? 'SYSTEM';
    return _Notif(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      timeLabel: _timeAgo(json['createdAt']?.toString()),
      icon: _iconForType(type),
      color: _colorForType(type),
      read: json['readAt'] != null,
    );
  }

  _Notif copyWith({bool? read}) {
    return _Notif(
      id: id,
      title: title,
      body: body,
      timeLabel: timeLabel,
      icon: icon,
      color: color,
      read: read ?? this.read,
    );
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'ORDER':
        return Icons.shopping_bag_rounded;
      case 'APPOINTMENT':
        return Icons.medical_services_rounded;
      case 'PROMOTION':
        return Icons.local_offer_rounded;
      case 'RIDE':
        return Icons.directions_car_rounded;
      case 'LAUNDRY':
        return Icons.local_laundry_service_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static Color _colorForType(String type) {
    switch (type) {
      case 'ORDER':
        return AppColors.success;
      case 'APPOINTMENT':
        return AppColors.doctor;
      case 'PROMOTION':
        return AppColors.primary;
      case 'RIDE':
        return AppColors.ride;
      case 'LAUNDRY':
        return AppColors.laundry;
      default:
        return AppColors.mediumGrey;
    }
  }

  static String _timeAgo(String? value) {
    final date = value == null ? null : DateTime.tryParse(value);
    if (date == null) {
      return 'Recently';
    }
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${diff.inDays} days ago';
  }
}

const _fallbackNotifications = [
  _Notif(
    id: null,
    title: 'Order Delivered!',
    body: 'Your food order from Burger Palace has been delivered',
    timeLabel: '2 min ago',
    icon: Icons.check_circle_rounded,
    color: AppColors.success,
    read: false,
  ),
  _Notif(
    id: null,
    title: 'Appointment Reminder',
    body: 'Your appointment is tomorrow at 10:00 AM',
    timeLabel: '1 hour ago',
    icon: Icons.medical_services_rounded,
    color: AppColors.doctor,
    read: false,
  ),
  _Notif(
    id: null,
    title: 'Promo Alert',
    body: 'Fresh discounts are available across grocery and pharmacy.',
    timeLabel: '3 hours ago',
    icon: Icons.local_offer_rounded,
    color: AppColors.primary,
    read: true,
  ),
];
