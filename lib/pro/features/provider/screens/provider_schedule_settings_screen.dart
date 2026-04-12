import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  static const List<String> _modeOptions = <String>[
    'Home Visit',
    'Store Drop-off',
    'Phone Advice',
    'Video Consultation',
  ];

  late Future<List<Map<String, dynamic>>> _settingsFuture;
  final Set<String> _busyIds = <String>{};

  bool get _supportsServices =>
      widget.activeModules.isEmpty ||
      widget.activeModules.contains(ProModule.services);

  List<String> _splitValues(String value) {
    return value
        .split(RegExp(r'[,\\n]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }

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
    required String contactPhone,
    required List<String> services,
    required List<String> bookingModes,
    required Map<String, String> availability,
    required Map<String, dynamic> serviceZone,
    required Map<String, dynamic> houseHelpConfig,
  }) async {
    setState(() => _busyIds.add(providerId));
    try {
      await ApiClient.post('/pro/${widget.userId}/provider-settings', {
        'providerId': providerId,
        'contactPhone': contactPhone,
        'services': services,
        'bookingModes': bookingModes,
        'availability': availability,
        'serviceZone': serviceZone,
        'houseHelpConfig': houseHelpConfig,
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

  Future<LatLng?> _requestCurrentLocation({
    bool showFailureSnackBar = true,
  }) async {
    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) {
        if (showFailureSnackBar && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Turn on location services to continue.'),
            ),
          );
        }
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showFailureSnackBar && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required for service-zone matching.',
              ),
            ),
          );
        }
        return null;
      }

      Position? cachedPosition;
      try {
        cachedPosition = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      Position? position;
      for (var attempt = 0; attempt < 3 && position == null; attempt++) {
        final locationSettings = switch (attempt) {
          0 => const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 10),
          ),
          1 => const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 14),
          ),
          _ => const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 18),
          ),
        };
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: locationSettings,
          );
        } catch (_) {
          if (attempt < 2) {
            await Future<void>.delayed(const Duration(milliseconds: 750));
          }
        }
      }
      position ??= cachedPosition;
      if (position == null) {
        if (showFailureSnackBar && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not resolve your current location yet. Move the map pin manually and continue.',
              ),
            ),
          );
        }
        return null;
      }
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      if (showFailureSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access location permission right now.'),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _openEditor(Map<String, dynamic> item) async {
    final providerId = item['id']?.toString() ?? '';
    final contactPhoneController = TextEditingController(
      text: item['contactPhone']?.toString() ?? '',
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
    final serviceZone = Map<String, dynamic>.from(
      (item['serviceZone'] as Map?) ?? const <String, dynamic>{},
    );
    var zoneCenter = LatLng(
      (serviceZone['centerLatitude'] as num?)?.toDouble() ?? 11.5886,
      (serviceZone['centerLongitude'] as num?)?.toDouble() ?? 43.1457,
    );
    if (serviceZone['centerLatitude'] == null ||
        serviceZone['centerLongitude'] == null) {
      final current = await _requestCurrentLocation(showFailureSnackBar: false);
      if (current != null) {
        zoneCenter = current;
      }
    }
    if (!mounted) return;
    final zoneRadiusController = TextEditingController(
      text: ((serviceZone['radiusKm'] as num?)?.toDouble() ?? 1).toString(),
    );
    final houseHelpConfig = Map<String, dynamic>.from(
      (item['houseHelpConfig'] as Map?) ?? const <String, dynamic>{},
    );
    final bookingTypesController = TextEditingController(
      text: (houseHelpConfig['bookingTypes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .join(', '),
    );
    final shiftDurationsController = TextEditingController(
      text: (houseHelpConfig['shiftDurations'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .join(', '),
    );
    final homeSizesController = TextEditingController(
      text: (houseHelpConfig['homeSizes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .join(', '),
    );
    final arrivalTargetsController = TextEditingController(
      text: (houseHelpConfig['arrivalTargets'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .join(', '),
    );
    final supplyModesController = TextEditingController(
      text: (houseHelpConfig['supplyModes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .join(', '),
    );

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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactPhoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
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
                    SizedBox(
                      height: 170,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: zoneCenter,
                            zoom: 12.4,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('provider-zone-center'),
                              position: zoneCenter,
                            ),
                          },
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          liteModeEnabled: true,
                          onTap: (point) {
                            setModalState(() {
                              zoneCenter = point;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Zone center: ${zoneCenter.latitude.toStringAsFixed(5)}, ${zoneCenter.longitude.toStringAsFixed(5)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final current = await _requestCurrentLocation(
                              showFailureSnackBar: false,
                            );
                            if (current == null || !sheetContext.mounted) {
                              return;
                            }
                            setModalState(() => zoneCenter = current);
                          },
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('Use current'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: zoneRadiusController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Zone radius (km, max 1)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _SettingsSectionLabel('House-help booking criteria'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: bookingTypesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Booking types',
                        hintText: 'One-time job, Daily recurring',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: shiftDurationsController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Shift durations',
                        hintText: '2 hours, 4 hours, 8 hours',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: homeSizesController,
                      minLines: 1,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Home sizes',
                        hintText: 'F2, F3, F4',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: arrivalTargetsController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Arrival targets',
                        hintText: 'Within 30 min, Scheduled slot',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: supplyModesController,
                      minLines: 1,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Supply modes',
                        hintText: 'Provider supplies, Customer supplies',
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
                                final zoneRadius = double.tryParse(
                                  zoneRadiusController.text.trim(),
                                );
                                if (zoneRadius == null ||
                                    zoneRadius <= 0 ||
                                    zoneRadius > 1) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Set a valid zone center and radius (maximum 1 km) before saving.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(sheetContext).pop();
                                await _saveSettings(
                                  providerId: providerId,
                                  contactPhone: contactPhoneController.text
                                      .trim(),
                                  services: _splitValues(
                                    servicesController.text,
                                  ),
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
                                  serviceZone: {
                                    'enabled': true,
                                    'centerLatitude': zoneCenter.latitude,
                                    'centerLongitude': zoneCenter.longitude,
                                    'radiusKm': zoneRadius,
                                  },
                                  houseHelpConfig: {
                                    'bookingTypes': _splitValues(
                                      bookingTypesController.text,
                                    ),
                                    'shiftDurations': _splitValues(
                                      shiftDurationsController.text,
                                    ),
                                    'homeSizes': _splitValues(
                                      homeSizesController.text,
                                    ),
                                    'arrivalTargets': _splitValues(
                                      arrivalTargetsController.text,
                                    ),
                                    'supplyModes': _splitValues(
                                      supplyModesController.text,
                                    ),
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
              final serviceZone = Map<String, dynamic>.from(
                (item['serviceZone'] as Map?) ?? const <String, dynamic>{},
              );
              final houseHelpConfig = Map<String, dynamic>.from(
                (item['houseHelpConfig'] as Map?) ?? const <String, dynamic>{},
              );
              final zoneRadius =
                  (serviceZone['radiusKm'] as num?)?.toDouble() ?? 1;
              final zoneCenterLatitude = (serviceZone['centerLatitude'] as num?)
                  ?.toDouble();
              final zoneCenterLongitude =
                  (serviceZone['centerLongitude'] as num?)?.toDouble();
              final bookingTypes =
                  (houseHelpConfig['bookingTypes'] as List<dynamic>? ??
                          const [])
                      .map((entry) => entry.toString().trim())
                      .where((entry) => entry.isNotEmpty)
                      .toList(growable: false);
              final shiftDurations =
                  (houseHelpConfig['shiftDurations'] as List<dynamic>? ??
                          const [])
                      .map((entry) => entry.toString().trim())
                      .where((entry) => entry.isNotEmpty)
                      .toList(growable: false);
              final homeSizes =
                  (houseHelpConfig['homeSizes'] as List<dynamic>? ?? const [])
                      .map((entry) => entry.toString().trim())
                      .where((entry) => entry.isNotEmpty)
                      .toList(growable: false);
              final arrivalTargets =
                  (houseHelpConfig['arrivalTargets'] as List<dynamic>? ??
                          const [])
                      .map((entry) => entry.toString().trim())
                      .where((entry) => entry.isNotEmpty)
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
                        label: 'Phone',
                        value: item['contactPhone']?.toString() ?? 'Not set',
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
                        label: 'Zone',
                        value:
                            'Mandatory • ${zoneRadius.toStringAsFixed(1)} km',
                      ),
                      _SettingsInfoRow(
                        label: 'Zone center',
                        value:
                            zoneCenterLatitude == null ||
                                zoneCenterLongitude == null
                            ? 'Not set'
                            : '${zoneCenterLatitude.toStringAsFixed(5)}, ${zoneCenterLongitude.toStringAsFixed(5)}',
                      ),
                      _SettingsInfoRow(
                        label: 'Booking types',
                        value: bookingTypes.isEmpty
                            ? 'Not configured'
                            : bookingTypes.join(', '),
                      ),
                      _SettingsInfoRow(
                        label: 'Shifts',
                        value: shiftDurations.isEmpty
                            ? 'Not configured'
                            : shiftDurations.join(', '),
                      ),
                      _SettingsInfoRow(
                        label: 'Home sizes',
                        value: homeSizes.isEmpty
                            ? 'Not configured'
                            : homeSizes.join(', '),
                      ),
                      _SettingsInfoRow(
                        label: 'Arrival',
                        value: arrivalTargets.isEmpty
                            ? 'Not configured'
                            : arrivalTargets.join(', '),
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
