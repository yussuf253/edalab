/// Model for app version information retrieved from the database
class AppVersionModel {
  final String currentVersion;
  final String minRequiredVersion;
  final String latestVersion;
  final String releaseNotes;
  final bool isForceUpdateRequired;
  final bool isSkippableUpdate;
  final String downloadUrl;
  final String storeUrl;
  final DateTime releasedAt;
  final bool isActive;

  AppVersionModel({
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.isForceUpdateRequired,
    required this.isSkippableUpdate,
    required this.downloadUrl,
    required this.storeUrl,
    required this.releasedAt,
    required this.isActive,
  });

  /// Parse JSON response from database
  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      currentVersion: json['currentVersion'] as String? ?? '1.0.0',
      minRequiredVersion: json['minRequiredVersion'] as String? ?? '1.0.0',
      latestVersion: json['latestVersion'] as String? ?? '1.0.0',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      isForceUpdateRequired: json['isForceUpdateRequired'] as bool? ?? false,
      isSkippableUpdate: json['isSkippableUpdate'] as bool? ?? true,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      storeUrl: json['storeUrl'] as String? ?? '',
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'currentVersion': currentVersion,
      'minRequiredVersion': minRequiredVersion,
      'latestVersion': latestVersion,
      'releaseNotes': releaseNotes,
      'isForceUpdateRequired': isForceUpdateRequired,
      'isSkippableUpdate': isSkippableUpdate,
      'downloadUrl': downloadUrl,
      'storeUrl': storeUrl,
      'releasedAt': releasedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Determines if an update is needed
  bool get isUpdateRequired {
    return compareVersions(latestVersion, currentVersion) > 0;
  }

  /// Determines if current version is below minimum required version
  bool get isBelowMinimumVersion {
    return compareVersions(currentVersion, minRequiredVersion) < 0;
  }

  /// Compare two semantic versions
  /// Returns: 1 if version1 > version2, -1 if version1 < version2, 0 if equal
  static int compareVersions(String version1, String version2) {
    // Strip any build metadata (e.g., "1.0.0+1" -> "1.0.0")
    final v1Clean = version1.split('+').first;
    final v2Clean = version2.split('+').first;

    final v1Parts = v1Clean
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final v2Parts = v2Clean
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();

    // Pad with zeros if lengths differ
    final maxLength = v1Parts.length > v2Parts.length
        ? v1Parts.length
        : v2Parts.length;
    while (v1Parts.length < maxLength) {
      v1Parts.add(0);
    }
    while (v2Parts.length < maxLength) {
      v2Parts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }
    return 0;
  }

  @override
  String toString() =>
      'AppVersionModel('
      'currentVersion: $currentVersion, '
      'latestVersion: $latestVersion, '
      'isForceUpdateRequired: $isForceUpdateRequired, '
      'isSkippableUpdate: $isSkippableUpdate)';
}
