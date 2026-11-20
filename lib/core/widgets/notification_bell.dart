import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../providers/notification_provider.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    this.size = 48,
    this.backgroundColor = AppColors.white,
    this.iconColor = AppColors.dark,
    this.useShadow = false,
    this.compact = false,
    this.showBorder = true,
  });

  final double size;
  final Color backgroundColor;
  final Color iconColor;
  final bool useShadow;
  final bool compact;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: showBorder ? Border.all(color: AppColors.border) : null,
          boxShadow: useShadow ? AppSpacing.shadowSm : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: iconColor,
              size: compact ? 20 : 22,
            ),
            if (unreadCount > 0)
              Positioned(
                top: compact ? 5 : 8,
                right: compact ? 3 : 5,
                child: Container(
                  constraints: BoxConstraints(
                    minWidth: compact ? 16 : 18,
                    minHeight: compact ? 16 : 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: backgroundColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
