import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:edalab/core/models/app_version_model.dart';
import 'package:edalab/core/repositories/app_version_repository.dart';

/// Provider for managing app version and update checks
class AppVersionProvider extends ChangeNotifier {
  AppVersionModel? _versionInfo;
  bool _isLoading = false;
  String? _error;
  String _currentAppVersion = '1.0.0';

  // Track if user has already dismissed update dialog
  bool _updateDismissed = false;
  bool _updateSkipped = false;

  AppVersionModel? get versionInfo => _versionInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentAppVersion => _currentAppVersion;
  bool get updateDismissed => _updateDismissed;
  bool get updateSkipped => _updateSkipped;

  /// Check if an update is available
  bool get isUpdateAvailable =>
      _versionInfo != null && _versionInfo!.isUpdateRequired;

  /// Check if update is mandatory (force update)
  bool get isForceUpdateRequired =>
      _versionInfo != null &&
      (_versionInfo!.isForceUpdateRequired ||
          _versionInfo!.isBelowMinimumVersion);

  /// Check if update can be skipped
  bool get isUpdateSkippable =>
      _versionInfo != null &&
      _versionInfo!.isSkippableUpdate &&
      !isForceUpdateRequired;

  AppVersionProvider() {
    _initializeAppVersion();
  }

  /// Initialize with current app version from package info
  Future<void> _initializeAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _currentAppVersion = packageInfo.version;
      notifyListeners();
    } catch (e) {
      print('Failed to get package info: $e');
    }
  }

  /// Check for app updates from the backend
  Future<void> checkForUpdates({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final versionInfo = await AppVersionRepository.checkForUpdates();
      _versionInfo = versionInfo;
      _error = null;
    } catch (e) {
      _error = 'Failed to check for updates: ${e.toString()}';
      print('Error checking for updates: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check for updates specific to a platform
  Future<void> checkForUpdatesByPlatform(String platform) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final versionInfo = await AppVersionRepository.checkForUpdatesByPlatform(
        platform,
      );
      _versionInfo = versionInfo;
      _error = null;
    } catch (e) {
      _error = 'Failed to check for updates: ${e.toString()}';
      print('Error checking for updates: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark that user has dismissed the update dialog
  void dismissUpdateDialog() {
    _updateDismissed = true;
    notifyListeners();
  }

  /// Reset update dialog dismissal
  void resetUpdateDismissal() {
    _updateDismissed = false;
    _updateSkipped = false;
    notifyListeners();
  }

  /// Mark that user has skipped the update
  void skipUpdate() {
    _updateSkipped = true;
    if (_versionInfo != null) {
      AppVersionRepository.reportUpdateAction('skipped', _currentAppVersion);
    }
    notifyListeners();
  }

  /// Mark that user has confirmed update
  void confirmUpdate() {
    if (_versionInfo != null) {
      AppVersionRepository.reportUpdateAction(
        'update_confirmed',
        _currentAppVersion,
      );
    }
  }

  /// Mark that forced update was triggered
  void markForcedUpdate() {
    if (_versionInfo != null) {
      AppVersionRepository.reportUpdateAction(
        'forced_update',
        _currentAppVersion,
      );
    }
  }

  /// Get the download or store URL for the app update
  String? getUpdateUrl({bool useStore = true}) {
    if (_versionInfo == null) return null;
    return useStore ? _versionInfo!.storeUrl : _versionInfo!.downloadUrl;
  }

  /// Reset the version provider
  void reset() {
    _versionInfo = null;
    _isLoading = false;
    _error = null;
    _updateDismissed = false;
    _updateSkipped = false;
    notifyListeners();
  }

  @override
  String toString() =>
      'AppVersionProvider('
      'currentAppVersion: $_currentAppVersion, '
      'updateAvailable: $isUpdateAvailable, '
      'forceUpdateRequired: $isForceUpdateRequired, '
      'isLoading: $_isLoading)';
}
