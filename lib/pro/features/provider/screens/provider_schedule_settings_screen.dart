import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/router/pro_route_paths.dart';

class ProviderScheduleSettingsScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final List<ProModule> activeModules;

  const ProviderScheduleSettingsScreen({
    super.key,
    required this.userId,
    required this.businessName,
    this.activeModules = const [],
  });

  @override
  State<ProviderScheduleSettingsScreen> createState() =>
      _ProviderScheduleSettingsScreenState();
}

class _ProviderScheduleSettingsScreenState
    extends State<ProviderScheduleSettingsScreen> {
  late Future<List<Map<String, dynamic>>> _scheduleFuture;
  final Set<String> _busyIds = <String>{};

  bool get _supportsServices =>
      widget.activeModules.isEmpty ||
      widget.activeModules.contains(ProModule.services);

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _loadScheduleData();
  }

  Future<List<Map<String, dynamic>>> _loadScheduleData() async {
    final responses = await Future.wait([
      ApiClient.get(
        '/pro/${widget.userId}/provider-settings',
        forceRefresh: true,
      ),
      ApiClient.get(
        '/pro/${widget.userId}/provider-availability',
        forceRefresh: true,
      ),
    ]);
    final settings = (responses[0] as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
    final availability = Map<String, dynamic>.from(responses[1] as Map);
    final servicesAvailability =
        (availability['services'] as List<dynamic>? ?? const <dynamic>[])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList(growable: false);
    final enabledById = <String, bool>{
      for (final entry in servicesAvailability)
        entry['id']?.toString() ?? '': entry['enabled'] as bool? ?? false,
    };

    return settings
        .map((item) {
          final providerId = item['id']?.toString() ?? '';
          return {...item, 'enabled': enabledById[providerId] ?? false};
        })
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    final future = _loadScheduleData();
    setState(() => _scheduleFuture = future);
    await future;
  }

  Future<void> _saveOperationalSettings({
    required String providerId,
    required bool enabled,
    required Map<String, String> availability,
    bool showSuccess = true,
  }) async {
    setState(() => _busyIds.add(providerId));
    try {
      await ApiClient.post('/pro/${widget.userId}/provider-settings', {
        'providerId': providerId,
        'availability': availability,
      });
      await ApiClient.post('/pro/${widget.userId}/provider-availability', {
        'module': 'services',
        'targetId': providerId,
        'enabled': enabled,
      });
      if (!mounted) return;
      if (showSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule and active status updated.')),
        );
      }
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(providerId));
      }
    }
  }

  Future<void> _openEditor(Map<String, dynamic> item) async {
    final providerId = item['id']?.toString() ?? '';
    var enabled = item['enabled'] as bool? ?? false;
    final availability = Map<String, String>.from(
      (item['availability'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          ) ??
          const <String, String>{},
    );

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget scheduleField({required String key, required String label}) {
              return TextFormField(
                initialValue: availability[key] ?? '',
                decoration: InputDecoration(labelText: label),
                onChanged: (value) => availability[key] = value,
              );
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']?.toString() ?? 'Provider',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((item['title']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item['title']!.toString()),
                    ],
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: enabled,
                      onChanged: _busyIds.contains(providerId)
                          ? null
                          : (value) => setModalState(() => enabled = value),
                      title: const Text('Accept bookings now'),
                      subtitle: Text(
                        enabled ? 'Active and visible to users' : 'Paused',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _SettingsSectionLabel('Weekly time slots'),
                    const SizedBox(height: 8),
                    scheduleField(
                      key: 'weekdays',
                      label: 'Weekdays (e.g. 08:00 AM - 06:00 PM)',
                    ),
                    const SizedBox(height: 12),
                    scheduleField(
                      key: 'saturday',
                      label: 'Saturday (e.g. 09:00 AM - 02:00 PM)',
                    ),
                    const SizedBox(height: 12),
                    scheduleField(key: 'sunday', label: 'Sunday (e.g. Closed)'),
                    const SizedBox(height: 10),
                    const Text(
                      'Use this screen for operations only: active status and time slots.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busyIds.contains(providerId)
                            ? null
                            : () async {
                                Navigator.of(sheetContext).pop();
                                await _saveOperationalSettings(
                                  providerId: providerId,
                                  enabled: enabled,
                                  availability: {
                                    'weekdays': (availability['weekdays'] ?? '')
                                        .trim(),
                                    'saturday': (availability['saturday'] ?? '')
                                        .trim(),
                                    'sunday': (availability['sunday'] ?? '')
                                        .trim(),
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.homeServices,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _busyIds.contains(providerId) ? 'Saving...' : 'Save',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.businessName} Scheduling'),
        backgroundColor: AppColors.homeServices,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (!_supportsServices) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Services module is not enabled for this provider profile.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No offered service listing found yet for this provider account.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push(ProRoutePaths.providerAvailability),
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Open Offered Services'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.homeServices,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Manage offered services and profile'),
                    subtitle: const Text(
                      'Use Offered Services for listing/profile configuration. Scheduling is only for active status and time slots.',
                    ),
                    trailing: TextButton(
                      onPressed: () =>
                          context.push(ProRoutePaths.providerAvailability),
                      child: const Text('Open'),
                    ),
                  ),
                );
              }

              final item = items[index - 1];
              final providerId = item['id']?.toString() ?? '';
              final isBusy = _busyIds.contains(providerId);
              final enabled = item['enabled'] as bool? ?? false;
              final availability = Map<String, dynamic>.from(
                (item['availability'] as Map?) ?? const <String, dynamic>{},
              );
              final currentAvailability = {
                'weekdays': availability['weekdays']?.toString().trim() ?? '',
                'saturday': availability['saturday']?.toString().trim() ?? '',
                'sunday': availability['sunday']?.toString().trim() ?? '',
              };

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.homeServices.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.schedule_outlined,
                              color: AppColors.homeServices,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name']?.toString() ?? 'Provider',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  enabled ? 'Active' : 'Paused',
                                  style: TextStyle(
                                    color: enabled
                                        ? Colors.green
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: enabled,
                            onChanged: isBusy
                                ? null
                                : (value) => _saveOperationalSettings(
                                    providerId: providerId,
                                    enabled: value,
                                    availability: currentAvailability,
                                    showSuccess: false,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SettingsInfoRow(
                        label: 'Weekdays',
                        value: currentAvailability['weekdays']!.isEmpty
                            ? 'Not set'
                            : currentAvailability['weekdays']!,
                      ),
                      _SettingsInfoRow(
                        label: 'Saturday',
                        value: currentAvailability['saturday']!.isEmpty
                            ? 'Not set'
                            : currentAvailability['saturday']!,
                      ),
                      _SettingsInfoRow(
                        label: 'Sunday',
                        value: currentAvailability['sunday']!.isEmpty
                            ? 'Not set'
                            : currentAvailability['sunday']!,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: isBusy ? null : () => _openEditor(item),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit time slots'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String text;

  const _SettingsSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SettingsInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
