import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/app_notification_model.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;
  NotificationModule? _selectedModule;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<NotificationProvider>();
    final allNotifications = provider.notifications;
    final filteredNotifications = allNotifications.where((notification) {
      final matchesUnread = _filter == _NotificationFilter.unread
          ? !notification.isRead
          : true;
      final matchesModule = _selectedModule == null
          ? true
          : notification.module == _selectedModule;
      return matchesUnread && matchesModule;
    }).toList();

    final availableModules = {
      for (final item in allNotifications) item.module,
    }.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('notifications.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllRead,
              child: Text(
                l10n.t('notifications.mark_all_read'),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: provider.isLoading
          ? const NotificationsShimmer()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppSpacing.shadowSm,
                        ),
                        child: Row(
                          children: [
                            _StatCard(
                              label: l10n.t('common.unread'),
                              value: '${provider.unreadCount}',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: l10n.t('common.total'),
                              value: '${allNotifications.length}',
                              color: AppColors.doctor,
                            ),
                            const SizedBox(width: 10),
                            _StatCard(
                              label: l10n.t('common.modules'),
                              value: '${availableModules.length}',
                              color: AppColors.warning,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: l10n.t('common.all'),
                              selected: _filter == _NotificationFilter.all,
                              onTap: () {
                                setState(() => _filter = _NotificationFilter.all);
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: l10n.t('common.unread'),
                              selected: _filter == _NotificationFilter.unread,
                              onTap: () {
                                setState(
                                  () => _filter = _NotificationFilter.unread,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: availableModules.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _ModuleChip(
                                label: l10n.t('common.everything'),
                                selected: _selectedModule == null,
                                color: AppColors.dark,
                                onTap: () {
                                  setState(() => _selectedModule = null);
                                },
                              );
                            }
                            final module = availableModules[index - 1];
                            final sample = allNotifications.firstWhere(
                              (item) => item.module == module,
                            );
                            return _ModuleChip(
                              label: l10n.moduleLabel(module),
                              selected: _selectedModule == module,
                              color: sample.color,
                              onTap: () {
                                setState(() => _selectedModule = module);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filteredNotifications.isEmpty
                      ? const _EmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: filteredNotifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notification = filteredNotifications[index];
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await provider.markAsRead(notification.id);
                                if (!context.mounted || notification.route == null) {
                                  return;
                                }
                                context.push(notification.route!);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: notification.isRead
                                      ? AppColors.white
                                      : notification.color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: notification.isRead
                                        ? AppColors.extraLightGrey
                                        : notification.color.withValues(alpha: 0.18),
                                  ),
                                  boxShadow: AppSpacing.shadowSm,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: notification.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notification.title,
                                                  style: AppTextStyles.labelMedium,
                                                ),
                                              ),
                                              if (!notification.isRead)
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: notification.color,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            notification.body,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.grey,
                                              height: 1.45,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              _Pill(
                                                label: l10n.moduleLabel(
                                                  notification.module,
                                                ),
                                                color: notification.color,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatTime(notification.createdAt),
                                                style: AppTextStyles.caption,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatTime(DateTime date) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.t('common.just_now');
    if (diff.inHours < 1) {
      return l10n.t('common.min_ago', params: {'count': '${diff.inMinutes}'});
    }
    if (diff.inDays < 1) {
      return l10n.t('common.hour_ago', params: {'count': '${diff.inHours}'});
    }
    if (diff.inDays == 1) return l10n.t('common.yesterday');
    if (diff.inDays < 7) {
      return l10n.t('common.days_ago', params: {'count': '${diff.inDays}'});
    }
    return DateFormat('MMM d').format(date);
  }
}

enum _NotificationFilter { all, unread }

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.h4.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: AppColors.lightGrey),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.white : AppColors.dark,
          ),
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.white,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: AppColors.lightGrey),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.white : AppColors.dark,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(l10n.t('notifications.empty_title'), style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(
              l10n.t('notifications.empty_subtitle'),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
