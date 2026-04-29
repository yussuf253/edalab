import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edalab/core/providers/app_version_provider.dart';
import 'package:edalab/core/utils/app_store_util.dart';
import 'package:edalab/core/constants/app_colors.dart';
import 'package:edalab/core/constants/app_spacing.dart';
import 'package:edalab/core/constants/app_text_styles.dart';

/// Reusable widget for displaying app update dialogs
/// Styled to match the app's card and dialog architecture
class AppUpdateDialog extends StatefulWidget {
  final bool isForceUpdate;
  final VoidCallback? onUpdatePressed;
  final VoidCallback? onSkipPressed;

  const AppUpdateDialog({
    Key? key,
    this.isForceUpdate = false,
    this.onUpdatePressed,
    this.onSkipPressed,
  }) : super(key: key);

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, check if update was completed
    if (state == AppLifecycleState.resumed && mounted) {
      // Re-check version to see if app was updated
      context.read<AppVersionProvider>().checkForUpdates(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppVersionProvider>(
      builder: (context, provider, _) {
        final versionInfo = provider.versionInfo;

        if (versionInfo == null) {
          return const SizedBox.shrink();
        }

        return WillPopScope(
          onWillPop: () async => !widget.isForceUpdate,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppSpacing.shadowSm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + Title row
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0E8E68),
                              AppColors.homeServices,
                              Color(0xFF57C49A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isForceUpdate
                                  ? 'Update Required'
                                  : 'Update Available',
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.isForceUpdate
                                  ? 'A critical update is required.'
                                  : 'A new version is available.',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Release notes
                  if (versionInfo.releaseNotes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "What's New",
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.homeServices,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            versionInfo.releaseNotes,
                            style: AppTextStyles.bodySmall.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Version info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.extraLightGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'v${provider.currentAppVersion}',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.mediumGrey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'v${versionInfo.latestVersion}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.homeServices,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Buttons
                  Row(
                    children: [
                      if (!widget.isForceUpdate &&
                          provider.isUpdateSkippable) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              provider.skipUpdate();
                              Navigator.of(context).pop();
                              widget.onSkipPressed?.call();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.grey,
                              side: const BorderSide(
                                color: AppColors.lightGrey,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Later',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            provider.confirmUpdate();
                            if (versionInfo.storeUrl.isNotEmpty) {
                              AppStoreUtil.openCustomUrl(versionInfo.storeUrl);
                            }
                            widget.onUpdatePressed?.call();
                            // Don't pop dialog for force updates until update is complete
                            if (!widget.isForceUpdate) {
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.homeServices,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Update Now',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Convenience method to show update dialog
Future<void> showAppUpdateDialog(
  BuildContext context, {
  bool isForceUpdate = false,
  VoidCallback? onUpdatePressed,
  VoidCallback? onSkipPressed,
}) {
  return showDialog(
    context: context,
    barrierDismissible: !isForceUpdate,
    builder: (context) => AppUpdateDialog(
      isForceUpdate: isForceUpdate,
      onUpdatePressed: onUpdatePressed,
      onSkipPressed: onSkipPressed,
    ),
  );
}
