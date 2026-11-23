import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/connectivity_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Non-blocking alert shown above the app while [ConnectivityProvider] reports
/// no network.
///
/// The app keeps working underneath — the strip only states the problem and
/// offers a re-check, then disappears on its own when connectivity returns.
/// It sits in `app.dart` above every route so the message is never lost behind
/// a pushed page.
class NoInternetAlert extends StatelessWidget {
  const NoInternetAlert({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: AppColors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.wifiOff,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.t('no_internet.title'),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.dark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.t('no_internet.message'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: l10n.t('no_internet.retry_button'),
                  button: true,
                  child: IconButton(
                    onPressed: () =>
                        context.read<ConnectivityProvider>().checkNow(),
                    // No `tooltip` here: this alert lives above the Navigator
                    // (in MaterialApp.builder), so there is no Overlay ancestor
                    // and Tooltip throws — blowing the strip up to full-screen
                    // height. The Semantics label keeps it accessible.
                    icon: const Icon(
                      LucideIcons.refreshCw,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
