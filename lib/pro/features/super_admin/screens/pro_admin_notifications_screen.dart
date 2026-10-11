import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../core/models/app_notification_model.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/pro_auth_provider.dart';

/// In-app activity feed for super admins. Every platform-wide operation
/// (user/pro signups, orders, bookings, cancellations, failed payments)
/// lands here from the backend's admin notification fan-out, and the same
/// rows back the push notifications the admin device receives.
class ProAdminNotificationsScreen extends StatefulWidget {
  const ProAdminNotificationsScreen({super.key});

  @override
  State<ProAdminNotificationsScreen> createState() =>
      _ProAdminNotificationsScreenState();
}

class _ProAdminNotificationsScreenState
    extends State<ProAdminNotificationsScreen> {
  Future<void> _refresh() async {
    final notifications = context.read<NotificationProvider>();
    final userId = context.read<ProAuthProvider>().notificationUserId;
    if (userId == null) return;
    await notifications.refreshFromServer(userId);
  }

  Future<void> _openItem(AppNotificationModel item) async {
    final notifications = context.read<NotificationProvider>();
    if (!item.isRead) {
      await notifications.markAsRead(item.id);
    }

    final route = item.route;
    if (!mounted || route == null || route.isEmpty) return;
    // This router only knows pro-app routes; admin events deep-link into the
    // matching admin screen, anything else is just read state.
    if (route.startsWith('/pro/')) {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    final items = notifications.notifications;
    final unread = notifications.unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(unread > 0 ? 'Activity · $unread new' : 'Activity'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: unread == 0 ? null : notifications.markAllRead,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: items.isEmpty
            ? const _EmptyFeed()
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(ProDesignSystem.spacing16),
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: ProDesignSystem.spacing12),
                itemBuilder: (context, index) =>
                    _FeedTile(item: items[index], onTap: () => _openItem(items[index])),
              ),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.item, required this.onTap});

  final AppNotificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusLarge),
        border: Border.all(
          color: item.isRead ? AppColors.lightGrey : AppColors.primary,
          width: item.isRead ? 1 : 1.4,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusLarge),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(ProDesignSystem.spacing12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(ProDesignSystem.spacing8),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: ProDesignSystem.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.moduleLabel.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: item.color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(width: ProDesignSystem.spacing8),
                        Text(
                          _timeAgo(item.createdAt),
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.mediumGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.mediumGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.isRead)
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 6),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Icon(
          Icons.notifications_none_rounded,
          size: 64,
          color: AppColors.mediumGrey,
        ),
        const SizedBox(height: ProDesignSystem.spacing12),
        Text(
          'No operations yet',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: ProDesignSystem.spacing6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Signups, orders, bookings, and cancellations from across the '
            'platform will appear here in real time.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
          ),
        ),
      ],
    );
  }
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${time.day}/${time.month}/${time.year}';
}
