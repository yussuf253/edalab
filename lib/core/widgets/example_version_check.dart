// Example widget demonstrating version check UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edalab/core/providers/app_version_provider.dart';
import 'package:edalab/core/widgets/app_update_dialog.dart';

class ExampleVersionCheckWidget extends StatelessWidget {
  const ExampleVersionCheckWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Version Info')),
      body: Consumer<AppVersionProvider>(
        builder: (context, versionProvider, _) {
          if (versionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (versionProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${versionProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => versionProvider.checkForUpdates(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Current version card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Version',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        versionProvider.currentAppVersion,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (versionProvider.versionInfo != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Version Information',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Latest Version',
                          versionProvider.versionInfo!.latestVersion,
                        ),
                        _buildInfoRow(
                          'Min Required',
                          versionProvider.versionInfo!.minRequiredVersion,
                        ),
                        _buildInfoRow(
                          'Force Update',
                          versionProvider.versionInfo!.isForceUpdateRequired
                              ? 'Yes'
                              : 'No',
                        ),
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
                const SizedBox(height: 16),
                if (versionProvider.versionInfo!.releaseNotes.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Release Notes',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(versionProvider.versionInfo!.releaseNotes),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (versionProvider.isUpdateAvailable)
                  ElevatedButton.icon(
                    onPressed: () {
                      showAppUpdateDialog(
                        context,
                        isForceUpdate: versionProvider.isForceUpdateRequired,
                        onUpdatePressed: () => versionProvider.confirmUpdate(),
                        onSkipPressed: () => versionProvider.skipUpdate(),
                      );
                    },
                    icon: const Icon(Icons.system_update),
                    label: Text(
                      versionProvider.isForceUpdateRequired
                          ? 'Update Required'
                          : 'Update Available',
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    versionProvider.checkForUpdates(forceRefresh: true),
                child: const Text('Check for Updates'),
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
