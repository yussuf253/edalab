import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../constants/app_colors.dart';
import '../localization/app_localizations.dart';
import '../providers/auth_provider.dart';

Future<bool> requireLoggedIn(BuildContext context, {String? message}) async {
  final auth = context.read<AuthProvider>();
  if (auth.isLoggedIn && auth.user != null) {
    return true;
  }
  final l10n = context.l10n;

  final path = GoRouterState.of(context).uri.path;
  AnalyticsService.instance.track(
    AnalyticsEvents.checkoutValidationFailed,
    properties: {
      'reason': 'login_required',
      'route': path,
      'module_type':
          path.split('/').where((segment) => segment.isNotEmpty).isEmpty
          ? 'home'
          : path.split('/').where((segment) => segment.isNotEmpty).first,
    },
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message ?? l10n.t('common.login_required_continue')),
      backgroundColor: AppColors.dark,
      action: SnackBarAction(
        label: l10n.t('common.login'),
        textColor: AppColors.white,
        onPressed: () => context.push('/login'),
      ),
    ),
  );
  return false;
}

class LoginRequiredView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;

  const LoginRequiredView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel = 'Log In',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login_rounded),
              label: Text(
                actionLabel == 'Log In' ? l10n.t('common.log_in') : actionLabel,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
