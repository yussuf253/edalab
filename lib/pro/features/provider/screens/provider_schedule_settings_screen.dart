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

  String _formatTimeOfDay(TimeOfDay value) {
    final hour12 = ((value.hour + 11) % 12) + 1;
    final minutes = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:$minutes $period';
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
    var weekdaysSlot = _EditableDaySlot.fromRaw(
      availability['weekdays'],
      defaultStart: const TimeOfDay(hour: 8, minute: 0),
      defaultEnd: const TimeOfDay(hour: 18, minute: 0),
    );
    var saturdaySlot = _EditableDaySlot.fromRaw(
      availability['saturday'],
      defaultStart: const TimeOfDay(hour: 9, minute: 0),
      defaultEnd: const TimeOfDay(hour: 14, minute: 0),
    );
    var sundaySlot = _EditableDaySlot.fromRaw(
      availability['sunday'],
      defaultStart: const TimeOfDay(hour: 9, minute: 0),
      defaultEnd: const TimeOfDay(hour: 14, minute: 0),
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
            Future<void> pickSlotTime({
              required _EditableDaySlot slot,
              required bool pickStart,
            }) async {
              final selected = await showTimePicker(
                context: context,
                initialTime: pickStart ? slot.start : slot.end,
              );
              if (selected == null || !sheetContext.mounted) return;
              setModalState(() {
                if (pickStart) {
                  slot.start = selected;
                } else {
                  slot.end = selected;
                }
              });
            }

            Widget slotEditor({
              required String title,
              required _EditableDaySlot slot,
            }) {
              final startLabel = _formatTimeOfDay(slot.start);
              final endLabel = _formatTimeOfDay(slot.end);
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Switch.adaptive(
                          value: !slot.closed,
                          onChanged: _busyIds.contains(providerId)
                              ? null
                              : (value) {
                                  setModalState(() => slot.closed = !value);
                                },
                        ),
                      ],
                    ),
                    Text(
                      slot.closed ? 'Closed' : 'Open',
                      style: TextStyle(
                        color: slot.closed ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                slot.closed || _busyIds.contains(providerId)
                                ? null
                                : () =>
                                      pickSlotTime(slot: slot, pickStart: true),
                            icon: const Icon(Icons.schedule_outlined, size: 18),
                            label: Text(startLabel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('to'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                slot.closed || _busyIds.contains(providerId)
                                ? null
                                : () => pickSlotTime(
                                    slot: slot,
                                    pickStart: false,
                                  ),
                            icon: const Icon(Icons.schedule, size: 18),
                            label: Text(endLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                    slotEditor(title: 'Weekdays', slot: weekdaysSlot),
                    const SizedBox(height: 12),
                    slotEditor(title: 'Saturday', slot: saturdaySlot),
                    const SizedBox(height: 12),
                    slotEditor(title: 'Sunday', slot: sundaySlot),
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
                                    'weekdays': weekdaysSlot.serialize(),
                                    'saturday': saturdaySlot.serialize(),
                                    'sunday': sundaySlot.serialize(),
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

class _EditableDaySlot {
  bool closed;
  TimeOfDay start;
  TimeOfDay end;

  _EditableDaySlot({
    required this.closed,
    required this.start,
    required this.end,
  });

  factory _EditableDaySlot.fromRaw(
    String? raw, {
    required TimeOfDay defaultStart,
    required TimeOfDay defaultEnd,
  }) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value.toLowerCase() == 'closed') {
      return _EditableDaySlot(
        closed: true,
        start: defaultStart,
        end: defaultEnd,
      );
    }
    final parts = value.split('-');
    if (parts.length != 2) {
      return _EditableDaySlot(
        closed: false,
        start: defaultStart,
        end: defaultEnd,
      );
    }
    final parsedStart = _parse12h(parts.first.trim()) ?? defaultStart;
    final parsedEnd = _parse12h(parts.last.trim()) ?? defaultEnd;
    return _EditableDaySlot(closed: false, start: parsedStart, end: parsedEnd);
  }

  static TimeOfDay? _parse12h(String input) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(input);
    if (match == null) return null;
    final rawHour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = (match.group(3) ?? '').toUpperCase();
    if (rawHour == null || minute == null) return null;
    if (rawHour < 1 || rawHour > 12 || minute < 0 || minute > 59) return null;
    var hour = rawHour % 12;
    if (period == 'PM') hour += 12;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String serialize() {
    if (closed) return 'Closed';
    String format(TimeOfDay value) {
      final hour12 = ((value.hour + 11) % 12) + 1;
      final minutes = value.minute.toString().padLeft(2, '0');
      final period = value.hour >= 12 ? 'PM' : 'AM';
      return '${hour12.toString().padLeft(2, '0')}:$minutes $period';
    }

    return '${format(start)} - ${format(end)}';
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
