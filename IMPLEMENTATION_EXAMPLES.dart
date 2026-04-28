// Example Implementation Guide
// This file shows a complete, working example of how to integrate the version management system

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edalab/core/providers/app_version_provider.dart';
// import 'package:edalab/core/services/app_version_service.dart'; // Unused import removed
import 'package:edalab/core/widgets/app_update_dialog.dart';

// ============================================================================
// EXAMPLE 1: Basic Integration in main.dart
// ============================================================================

/*
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization code ...
  
  // Create version provider
  final appVersionProvider = AppVersionProvider();
  
  // ... existing provider initialization ...
  
  runApp(
    MultiProvider(
      providers: [
        // ... existing providers ...
        
        // ADD THIS:
        ChangeNotifierProvider.value(value: appVersionProvider),
        
        // ... other providers ...
      ],
      child: EdaLabApp(router: router),
    ),
  );
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      _bootstrapAppServices(
        // ... existing params ...
        appVersionProvider: appVersionProvider,
      ),
    );
  });
}

Future<void> _bootstrapAppServices({
  // ... existing params ...
  required AppVersionProvider appVersionProvider,
}) async {
  // ... existing code ...
  
  // Initialize version checking
  // The service will automatically check for updates periodically
  if (navigatorKey.currentContext != null) {
    AppVersionService().initialize(navigatorKey.currentContext!);
  }
  
  // ... rest of bootstrap code ...
}
*/

// ============================================================================
// EXAMPLE 2: Using Version Provider in a Widget
// ============================================================================

class ExampleVersionCheckWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Version Info')),
      body: Consumer<AppVersionProvider>(
        builder: (context, versionProvider, _) {
          // Show loading state
          if (versionProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          // Show error if any
          if (versionProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${versionProvider.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => versionProvider.checkForUpdates(),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show version info
          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Current version card
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Version',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        versionProvider.currentAppVersion,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Version info card
              if (versionProvider.versionInfo != null) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Version Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow(
                          'Latest Version',
                          versionProvider.versionInfo!.latestVersion,
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          'Min Required',
                          versionProvider.versionInfo!.minRequiredVersion,
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          'Force Update',
                          versionProvider.versionInfo!.isForceUpdateRequired
                              ? 'Yes'
                              : 'No',
                        ),
                        SizedBox(height: 8),
                        _buildInfoRow(
                          'Skippable',
                          versionProvider.versionInfo!.isSkippableUpdate
                              ? 'Yes'
                              : 'No',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Release notes
                if (versionProvider.versionInfo!.releaseNotes.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Release Notes',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          Text(versionProvider.versionInfo!.releaseNotes),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16),

                // Action buttons
                if (versionProvider.isUpdateAvailable)
                  ElevatedButton.icon(
                    onPressed: () {
                      showAppUpdateDialog(
                        context,
                        isForceUpdate: versionProvider.isForceUpdateRequired,
                        onUpdatePressed: () {
                          print('Update confirmed');
                        },
                        onSkipPressed: () {
                          print('Update skipped');
                        },
                      );
                    },
                    icon: Icon(Icons.system_update),
                    label: Text(
                      versionProvider.isForceUpdateRequired
                          ? 'Update Required'
                          : 'Update Available',
                    ),
                  ),
              ],

              // Refresh button
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    versionProvider.checkForUpdates(forceRefresh: true),
                child: Text('Check for Updates'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 3: Home Screen with Update Banner
// ============================================================================

class HomeScreenWithVersionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        ListView(
          children: [
            // ... your home screen content ...
          ],
        ),

        // Update banner at top
        Consumer<AppVersionProvider>(
          builder: (context, versionProvider, _) {
            // Only show if update is available and not dismissed
            if (!versionProvider.isUpdateAvailable ||
                versionProvider.updateDismissed) {
              return SizedBox.shrink();
            }

            return Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: versionProvider.isForceUpdateRequired
                    ? Colors.red[100]
                    : Colors.blue[100],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        versionProvider.isForceUpdateRequired
                            ? Icons.warning
                            : Icons.info,
                        color: versionProvider.isForceUpdateRequired
                            ? Colors.red
                            : Colors.blue,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              versionProvider.isForceUpdateRequired
                                  ? 'Update Required'
                                  : 'Update Available',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'v${versionProvider.versionInfo?.latestVersion}',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showAppUpdateDialog(
                            context,
                            isForceUpdate:
                                versionProvider.isForceUpdateRequired,
                          );
                        },
                        child: Text('View'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 4: Settings Page with Version Management
// ============================================================================

class SettingsPageWithVersionCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          // ... other settings items ...

          // Version section
          Consumer<AppVersionProvider>(
            builder: (context, versionProvider, _) {
              return ListTile(
                title: Text('App Version'),
                subtitle: Text(versionProvider.currentAppVersion),
                trailing: versionProvider.isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        versionProvider.isUpdateAvailable
                            ? Icons.update
                            : Icons.check_circle,
                        color: versionProvider.isUpdateAvailable
                            ? Colors.orange
                            : Colors.green,
                      ),
                onTap: () =>
                    versionProvider.checkForUpdates(forceRefresh: true),
              );
            },
          ),

          // ... other settings items ...
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Manual Version Check Dialog
// ============================================================================

void showManualVersionCheckDialog(BuildContext context) async {
  final provider = context.read<AppVersionProvider>();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return Consumer<AppVersionProvider>(
        builder: (context, versionProvider, _) {
          return AlertDialog(
            title: Text('Check for Updates'),
            content: versionProvider.isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Checking for updates...'),
                    ],
                  )
                : versionProvider.error != null
                ? Text('Error: ${versionProvider.error}')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (versionProvider.isUpdateAvailable)
                        Text(
                          'Update v${versionProvider.versionInfo?.latestVersion} is available!',
                        )
                      else
                        Text('You are on the latest version.'),
                      SizedBox(height: 16),
                      if (versionProvider.versionInfo != null)
                        Text(
                          'Release Notes:\n${versionProvider.versionInfo?.releaseNotes}',
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Close'),
              ),
              if (versionProvider.isUpdateAvailable &&
                  !versionProvider.isLoading)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    showAppUpdateDialog(context);
                  },
                  child: Text('Update'),
                ),
            ],
          );
        },
      );
    },
  );

  // Start the check
  await Future.delayed(Duration.zero);
  await provider.checkForUpdates(forceRefresh: true);
}

// ============================================================================
// EXAMPLE 6: Custom Styled Update Dialog
// ============================================================================

class CustomStyledUpdateDialog extends StatelessWidget {
  final bool isForceUpdate;

  const CustomStyledUpdateDialog({Key? key, this.isForceUpdate = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppVersionProvider>(
      builder: (context, versionProvider, _) {
        final versionInfo = versionProvider.versionInfo;

        if (versionInfo == null) {
          return SizedBox.shrink();
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                decoration: BoxDecoration(
                  color: isForceUpdate ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      isForceUpdate ? Icons.warning : Icons.system_update,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      isForceUpdate ? 'Update Required' : 'Update Available',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version ${versionInfo.latestVersion}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    if (versionInfo.releaseNotes.isNotEmpty)
                      Text(versionInfo.releaseNotes),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Current: ${versionProvider.currentAppVersion}'),
                          Text('Latest: ${versionInfo.latestVersion}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!isForceUpdate)
                      TextButton(
                        onPressed: () {
                          versionProvider.skipUpdate();
                          Navigator.pop(context);
                        },
                        child: Text('Skip'),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        versionProvider.confirmUpdate();
                        // Open store
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isForceUpdate
                            ? Colors.red
                            : Colors.blue,
                      ),
                      child: Text('Update Now'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// EXAMPLE 7: Integration with App Lifecycle
// ============================================================================

class AppLifecycleVersionCheck extends StatefulWidget {
  final Widget child;

  const AppLifecycleVersionCheck({Key? key, required this.child})
    : super(key: key);

  @override
  State<AppLifecycleVersionCheck> createState() =>
      _AppLifecycleVersionCheckState();
}

class _AppLifecycleVersionCheckState extends State<AppLifecycleVersionCheck>
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
    if (state == AppLifecycleState.resumed) {
      // App resumed to foreground - check for updates
      final provider = context.read<AppVersionProvider>();
      provider.checkForUpdates();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
