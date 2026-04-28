import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edalab/core/providers/app_version_provider.dart';
import 'package:edalab/core/utils/app_store_util.dart';

/// Reusable widget for displaying app update dialogs
class AppUpdateDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Consumer<AppVersionProvider>(
      builder: (context, provider, _) {
        final versionInfo = provider.versionInfo;

        if (versionInfo == null) {
          return const SizedBox.shrink();
        }

        return AlertDialog(
          title: Text(
            isForceUpdate ? 'Update Required' : 'Update Available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  isForceUpdate
                      ? 'A critical update is required to continue using this app.'
                      : 'A new version of the app is available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Release Notes
                if (versionInfo.releaseNotes.isNotEmpty) ...[
                  Text(
                    'What\'s New:',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      versionInfo.releaseNotes,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Version Information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVersionRow(
                        context,
                        'Current Version',
                        provider.currentAppVersion,
                      ),
                      const SizedBox(height: 4),
                      _buildVersionRow(
                        context,
                        'Latest Version',
                        versionInfo.latestVersion,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Skip button (only for optional updates)
            if (!isForceUpdate && provider.isUpdateSkippable)
              TextButton(
                onPressed: () {
                  provider.skipUpdate();
                  Navigator.of(context).pop();
                  onSkipPressed?.call();
                },
                child: const Text('Skip'),
              ),

            // Update button
            ElevatedButton(
              onPressed: () {
                provider.confirmUpdate();
                Navigator.of(context).pop();

                if (versionInfo.storeUrl.isNotEmpty) {
                  AppStoreUtil.openCustomUrl(versionInfo.storeUrl);
                }

                onUpdatePressed?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  /// Build version info row
  Widget _buildVersionRow(BuildContext context, String label, String version) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(
          version,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
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
    builder: (context) => AppUpdateDialog(
      isForceUpdate: isForceUpdate,
      onUpdatePressed: onUpdatePressed,
      onSkipPressed: onSkipPressed,
    ),
  );
}
