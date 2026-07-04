import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edalab/core/providers/app_version_provider.dart';
import 'package:edalab/core/widgets/app_update_dialog.dart';

/// Service for managing version checks and update prompts
/// This service handles the logic for when to check for updates and how to handle them
class AppVersionService {
  static const Duration _checkIntervalMinutes = Duration(minutes: 30);

  Timer? _checkTimer;
  bool _isInitialized = false;
  bool _isDialogVisible = false;

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
      } else if (_isDialogVisible && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        _isDialogVisible = false;
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

    if (_isDialogVisible) return;
    _isDialogVisible = true;
    showAppUpdateDialog(
      context,
      isForceUpdate: true,
      onUpdatePressed: () => _openAppStore(context, versionInfo.storeUrl),
    ).whenComplete(() => _isDialogVisible = false);
  }

  /// Show optional update dialog (can be skipped)
  void _showOptionalUpdateDialog(BuildContext context) {
    final provider = context.read<AppVersionProvider>();
    final versionInfo = provider.versionInfo;

    if (versionInfo == null || !context.mounted) return;

    if (_isDialogVisible) return;
    _isDialogVisible = true;
    showAppUpdateDialog(
      context,
      isForceUpdate: false,
      onUpdatePressed: () => _openAppStore(context, versionInfo.storeUrl),
      onSkipPressed: () {
        provider.skipUpdate();
        provider.dismissUpdateDialog();
      },
    ).whenComplete(() => _isDialogVisible = false);
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
