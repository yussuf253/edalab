import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      _Notif('Order Delivered! 🎉', 'Your food order from Burger Palace has been delivered', '2 min ago', Icons.check_circle_rounded, AppColors.success, false),
      _Notif('Appointment Reminder', 'Your appointment with Dr. Sarah is tomorrow at 10:00 AM', '1 hour ago', Icons.medical_services_rounded, AppColors.doctor, false),
      _Notif('Promo Alert 🔥', 'Get 30% off on your next grocery order! Code: FRESH30', '3 hours ago', Icons.local_offer_rounded, AppColors.primary, false),
      _Notif('Laundry Ready', 'Your laundry order #1234 is ready for delivery', 'Yesterday', Icons.local_laundry_service_rounded, AppColors.laundry, true),
      _Notif('Ride Completed', 'Your ride from Home to City Mall has been completed', '2 days ago', Icons.directions_car_rounded, AppColors.ride, true),
      _Notif('New Feature!', 'Try our new hotel booking feature with exclusive deals', '3 days ago', Icons.hotel_rounded, AppColors.hotel, true),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: n.read ? AppColors.white : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppSpacing.shadowSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: n.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(n.icon, color: n.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: AppTextStyles.labelMedium),
                      const SizedBox(height: 4),
                      Text(n.body, style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey)),
                      const SizedBox(height: 6),
                      Text(n.time, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (!n.read)
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Notif {
  final String title, body, time;
  final IconData icon;
  final Color color;
  final bool read;
  _Notif(this.title, this.body, this.time, this.icon, this.color, this.read);
}
