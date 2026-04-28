import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edalab/core/providers/app_version_provider.dart';

/// Service for managing version checks and update prompts
/// This service handles the logic for when to check for updates and how to handle them
class AppVersionService {
  static const Duration _checkIntervalMinutes = Duration(minutes: 30);

  Timer? _checkTimer;
  bool _isInitialized = false;

  /// Initialize the version check service
  /// This will set up periodic checks for app updates
  void initialize(BuildContext context) {
    if (_isInitialized) return;

    _isInitialized = true;

    // Perform initial check
    _performVersionCheck(context);

    // Set up periodic checks every 30 minutes
    _checkTimer = Timer.periodic(_checkIntervalMinutes, (_) {
      _performVersionCheck(context);
    });
  }

  /// Perform a version check
  Future<void> _performVersionCheck(BuildContext context) async {
    try {
      if (!context.mounted) return;

      final provider = context.read<AppVersionProvider>();
      await provider.checkForUpdates();

      if (!context.mounted) return;

      // If update is required or available, show appropriate dialog
      if (provider.isForceUpdateRequired && !provider.updateDismissed) {
        _showForceUpdateDialog(context);
      } else if (provider.isUpdateAvailable &&
          !provider.updateDismissed &&
          !provider.updateSkipped) {
        _showOptionalUpdateDialog(context);
      }
    } catch (e) {
      print('Error during version check: $e');
    }
  }

  /// Show force update dialog (cannot be dismissed)
  void _showForceUpdateDialog(BuildContext context) {
    final provider = context.read<AppVersionProvider>();
    final versionInfo = provider.versionInfo;

    if (versionInfo == null || !context.mounted) return;

    provider.markForcedUpdate();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('App Update Required'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                'A critical update is required to continue using this app.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (versionInfo.releaseNotes.isNotEmpty) ...[
                Text(
                  'What\'s New:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  versionInfo.releaseNotes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Current Version: ${provider.currentAppVersion}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                'Latest Version: ${versionInfo.latestVersion}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                provider.confirmUpdate();
                _openAppStore(context, versionInfo.storeUrl);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Update Now'),
            ),
          ),
        ],
      ),
    );
  }

  /// Show optional update dialog (can be skipped)
  void _showOptionalUpdateDialog(BuildContext context) {
    final provider = context.read<AppVersionProvider>();
    final versionInfo = provider.versionInfo;

    if (versionInfo == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Update Available'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                'A new version of the app is available.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (versionInfo.releaseNotes.isNotEmpty) ...[
                Text(
                  'What\'s New:',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  versionInfo.releaseNotes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Current Version: ${provider.currentAppVersion}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                'Latest Version: ${versionInfo.latestVersion}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.skipUpdate();
              provider.dismissUpdateDialog();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.confirmUpdate();
              _openAppStore(context, versionInfo.storeUrl);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  /// Open the app store for updating
  Future<void> _openAppStore(BuildContext context, String storeUrl) async {
    try {
      // This will be implemented in a separate utility file
      await _launchURL(storeUrl);
    } catch (e) {
      print('Error opening app store: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open app store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Launch URL helper (requires url_launcher package)
  Future<void> _launchURL(String url) async {
    try {
      // Import url_launcher in actual implementation
      // await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      print('Opening URL: $url');
    } catch (e) {
      rethrow;
    }
  }

  /// Dispose and cleanup
  void dispose() {
    _checkTimer?.cancel();
    _isInitialized = false;
  }

  /// Manually trigger a version check
  Future<void> manualCheck(BuildContext context) async {
    final provider = context.read<AppVersionProvider>();
    await provider.checkForUpdates(forceRefresh: true);
  }
}
