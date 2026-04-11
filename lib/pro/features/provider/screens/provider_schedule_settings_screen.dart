import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/router/pro_route_paths.dart';

class ProviderScheduleSettingsScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const ProviderScheduleSettingsScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<ProviderScheduleSettingsScreen> createState() =>
      _ProviderScheduleSettingsScreenState();
}

class _ProviderScheduleSettingsScreenState
    extends State<ProviderScheduleSettingsScreen> {
  static const List<String> _modeOptions = <String>[
    'Home Visit',
    'Store Drop-off',
    'Phone Advice',
    'Video Consultation',
  ];

  late Future<List<Map<String, dynamic>>> _settingsFuture;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  Future<List<Map<String, dynamic>>> _loadSettings() async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/provider-settings',
      forceRefresh: true,
    );
    return (response as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    final future = _loadSettings();
    setState(() {
      _settingsFuture = future;
    });
    await future;
  }

  Future<void> _saveSettings({
    required String providerId,
    required String location,
    required String contactPhone,
    required String responseTime,
    required List<String> services,
    required List<String> bookingModes,
    required Map<String, String> availability,
  }) async {
    setState(() => _busyIds.add(providerId));
    try {
      await ApiClient.post('/pro/${widget.userId}/provider-settings', {
        'providerId': providerId,
        'location': location,
        'contactPhone': contactPhone,
        'responseTime': responseTime,
        'services': services,
        'bookingModes': bookingModes,
        'availability': availability,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider settings updated.')),
      );
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
    final locationController = TextEditingController(
      text: item['location']?.toString() ?? '',
    );
    final contactPhoneController = TextEditingController(
      text: item['contactPhone']?.toString() ?? '',
    );
    final responseTimeController = TextEditingController(
      text: item['responseTime']?.toString() ?? '',
    );
    final servicesController = TextEditingController(
      text: (item['services'] as List<dynamic>? ?? const <dynamic>[])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .join(', '),
    );
    final availability = Map<String, String>.from(
      (item['availability'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          ) ??
          const <String, String>{},
    );
    final selectedModes = <String>{
      ...(item['bookingModes'] as List<dynamic>? ?? const <dynamic>[]).map(
        (entry) => entry.toString(),
      ),
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
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
                20,
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
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Service area / activity zone',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactPhoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: responseTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Response time',
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: servicesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Services offered',
                        hintText:
                            'Room Cleaning, Floor Cleaning, Kitchen Cleaning',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SettingsSectionLabel('Booking modes'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _modeOptions.map((mode) {
                        return FilterChip(
                          label: Text(mode),
                          selected: selectedModes.contains(mode),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedModes.add(mode);
                              } else {
                                selectedModes.remove(mode);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const _SettingsSectionLabel('Weekly availability'),
                    const SizedBox(height: 8),
                    scheduleField(key: 'weekdays', label: 'Weekdays'),
                    const SizedBox(height: 12),
                    scheduleField(key: 'saturday', label: 'Saturday'),
                    const SizedBox(height: 12),
                    scheduleField(key: 'sunday', label: 'Sunday'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busyIds.contains(providerId)
                            ? null
                            : () async {
                                Navigator.of(sheetContext).pop();
                                await _saveSettings(
                                  providerId: providerId,
                                  location: locationController.text.trim(),
                                  contactPhone: contactPhoneController.text
                                      .trim(),
                                  responseTime: responseTimeController.text
                                      .trim(),
                                  services: servicesController.text
                                      .split(RegExp(r'[,\\n]'))
                                      .map((entry) => entry.trim())
                                      .where((entry) => entry.isNotEmpty)
                                      .toList(growable: false),
                                  bookingModes: selectedModes.toList(
                                    growable: false,
                                  ),
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
                          _busyIds.contains(providerId)
                              ? 'Saving...'
                              : 'Save settings',
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
        future: _settingsFuture,
        builder: (context, snapshot) {
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
                      'No service listing is configured yet for this provider account.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push(ProRoutePaths.providerAvailability),
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text('Create service listing'),
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
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final providerId = item['id']?.toString() ?? '';
              final availability = Map<String, dynamic>.from(
                (item['availability'] as Map?) ?? const <String, dynamic>{},
              );
              final bookingModes =
                  (item['bookingModes'] as List<dynamic>? ?? const <dynamic>[])
                      .map((entry) => entry.toString())
                      .toList(growable: false);
              final services =
                  (item['services'] as List<dynamic>? ?? const <dynamic>[])
                      .map((entry) => entry.toString())
                      .where((entry) => entry.trim().isNotEmpty)
                      .toList(growable: false);

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
                              Icons.home_repair_service_outlined,
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
                                if ((item['title']?.toString() ?? '')
                                    .isNotEmpty)
                                  Text(item['title']!.toString()),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _busyIds.contains(providerId)
                                ? null
                                : () => _openEditor(item),
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SettingsInfoRow(
                        label: 'Area',
                        value: item['location']?.toString() ?? 'Not set',
                      ),
                      _SettingsInfoRow(
                        label: 'Phone',
                        value: item['contactPhone']?.toString() ?? 'Not set',
                      ),
                      _SettingsInfoRow(
                        label: 'Response',
                        value: item['responseTime']?.toString() ?? 'Not set',
                      ),
                      _SettingsInfoRow(
                        label: 'Modes',
                        value: bookingModes.isEmpty
                            ? 'No booking modes configured'
                            : bookingModes.join(', '),
                      ),
                      _SettingsInfoRow(
                        label: 'Services',
                        value: services.isEmpty
                            ? 'No services configured'
                            : services.join(', '),
                      ),
                      _SettingsInfoRow(
                        label: 'Weekdays',
                        value:
                            availability['weekdays']?.toString() ?? 'Not set',
                      ),
                      _SettingsInfoRow(
                        label: 'Saturday',
                        value:
                            availability['saturday']?.toString() ?? 'Not set',
                      ),
                      _SettingsInfoRow(
                        label: 'Sunday',
                        value: availability['sunday']?.toString() ?? 'Not set',
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
