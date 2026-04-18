import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../core/models/pro_profile.dart';

class ProviderAvailabilityScreen extends StatefulWidget {
  final String userId;
  final String businessName;
  final List<ProModule> activeModules;

  const ProviderAvailabilityScreen({
    super.key,
    required this.userId,
    required this.businessName,
    this.activeModules = const [],
  });

  @override
  State<ProviderAvailabilityScreen> createState() =>
      _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState
    extends State<ProviderAvailabilityScreen> {
  static const List<String> _houseHelpServiceOptions = <String>[
    'Room Cleaning',
    'Floor Cleaning',
    'Kitchen Cleaning',
    'Bathroom Cleaning',
    'Dishes',
    'Laundry',
  ];
  static const List<String> _houseHelpBookingTypeOptions = <String>[
    'One-time job',
    'Daily recurring',
    'Weekly recurring',
  ];
  static const List<String> _houseHelpShiftOptions = <String>[
    '2 hours',
    '4 hours',
    '8 hours',
  ];
  static const List<String> _houseHelpArrivalOptions = <String>[
    'Within 30 min',
    'Scheduled slot',
  ];
  static const List<String> _houseHelpHomeSizeOptions = <String>[
    'F2',
    'F3',
    'F4',
  ];
  static const List<String> _houseHelpSupplyModeOptions = <String>[
    'Provider supplies',
    'Customer supplies',
  ];
  static const List<double> _zoneRadiusOptionsKm = <double>[0.25, 0.5, 0.75, 1];

  late Future<Map<String, dynamic>> _availabilityFuture;
  final Set<String> _busyIds = <String>{};

  bool get _supportsServices =>
      widget.activeModules.isEmpty ||
      widget.activeModules.contains(ProModule.services);
  bool get _supportsLaundry => widget.activeModules.contains(ProModule.laundry);

  bool _isHouseHelpLikeCategorySlug(String slug) {
    final normalized = slug.toLowerCase().trim();
    return normalized.contains('house-help') ||
        normalized.contains('house_help') ||
        normalized.contains('househelp') ||
        normalized == 'cleaning' ||
        normalized.contains('maid');
  }

  String _zoneRadiusLabel(double radiusKm) {
    if (radiusKm == 1) return '1 km';
    if ((radiusKm * 10).roundToDouble() == radiusKm * 10) {
      return '${radiusKm.toStringAsFixed(1)} km';
    }
    return '${radiusKm.toStringAsFixed(2)} km';
  }

  double _normalizeZoneRadius(double radiusKm) {
    final sorted = [..._zoneRadiusOptionsKm]..sort();
    var best = sorted.first;
    var smallestDistance = (radiusKm - best).abs();
    for (final candidate in sorted.skip(1)) {
      final distance = (radiusKm - candidate).abs();
      if (distance < smallestDistance) {
        best = candidate;
        smallestDistance = distance;
      }
    }
    return best;
  }

  String _priceLabel(num value) {
    final normalized = value.toDouble();
    return normalized % 1 == 0
        ? normalized.toStringAsFixed(0)
        : normalized.toStringAsFixed(2);
  }

  _CategoryListingPreset _presetForCategorySlug(String slug) {
    final normalized = slug.toLowerCase().trim();
    if (_isHouseHelpLikeCategorySlug(normalized)) {
      return const _CategoryListingPreset(
        defaultTitle: 'House Help Specialist',
        serviceOptions: _houseHelpServiceOptions,
        bookingTypeOptions: _houseHelpBookingTypeOptions,
        shiftOptions: _houseHelpShiftOptions,
        arrivalOptions: _houseHelpArrivalOptions,
        homeSizeOptions: _houseHelpHomeSizeOptions,
        supplyModeOptions: _houseHelpSupplyModeOptions,
      );
    }
    if (normalized.contains('plumb')) {
      return const _CategoryListingPreset(
        defaultTitle: 'Plumbing Specialist',
        serviceOptions: <String>[
          'Leak Repair',
          'Pipe Installation',
          'Drain Unclogging',
          'Faucet & Sink Repair',
          'Toilet Repair',
          'Water Heater Service',
        ],
      );
    }
    if (normalized.contains('elect')) {
      return const _CategoryListingPreset(
        defaultTitle: 'Electrical Technician',
        serviceOptions: <String>[
          'Socket & Switch Repair',
          'Lighting Installation',
          'Wiring Inspection',
          'Circuit Breaker Service',
          'Fan Installation',
          'Power Fault Diagnosis',
        ],
      );
    }
    if (normalized.contains('ac') || normalized.contains('cool')) {
      return const _CategoryListingPreset(
        defaultTitle: 'AC & Cooling Technician',
        serviceOptions: <String>[
          'AC Maintenance',
          'AC Gas Refill',
          'Cooling Fault Diagnosis',
          'AC Installation',
          'Filter Cleaning',
          'Emergency Cooling Repair',
        ],
      );
    }
    if (normalized.contains('beauty')) {
      return const _CategoryListingPreset(
        defaultTitle: 'Beauty at Home Specialist',
        serviceOptions: <String>[
          'Hair Styling',
          'Makeup Service',
          'Nail Care',
          'Facial Treatment',
          'Henna Service',
          'Bridal Beauty',
        ],
      );
    }
    if (normalized.contains('handyman')) {
      return const _CategoryListingPreset(
        defaultTitle: 'Handyman Specialist',
        serviceOptions: <String>[
          'Furniture Assembly',
          'Curtain & Wall Mounting',
          'Minor Repairs',
          'Door & Lock Fix',
          'Shelf Installation',
          'General Home Tasks',
        ],
      );
    }
    return const _CategoryListingPreset(
      defaultTitle: 'Home Service Specialist',
      serviceOptions: <String>[
        'General Home Service',
        'Inspection Visit',
        'Maintenance Support',
      ],
    );
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

  @override
  void initState() {
    super.initState();
    _availabilityFuture = _loadAvailability();
  }

  Future<Map<String, dynamic>> _loadAvailability() async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/provider-availability',
      forceRefresh: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> _refresh() async {
    final future = _loadAvailability();
    setState(() {
      _availabilityFuture = future;
    });
    await future;
  }

  Future<void> _toggle({
    required String module,
    required String targetId,
    required bool enabled,
  }) async {
    setState(() => _busyIds.add(targetId));
    try {
      await ApiClient.post('/pro/${widget.userId}/provider-availability', {
        'module': module,
        'targetId': targetId,
        'enabled': enabled,
      });
      if (!mounted) return;
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
        setState(() => _busyIds.remove(targetId));
      }
    }
  }

  Future<Map<String, dynamic>?> _loadProviderSettingById(
    String providerId,
  ) async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/provider-settings',
      forceRefresh: true,
    );
    final items = (response as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
    for (final item in items) {
      if (item['id']?.toString() == providerId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _openEditServiceListing(String providerId) async {
    if (providerId.isEmpty) return;
    Map<String, dynamic>? item;
    try {
      item = await _loadProviderSettingById(providerId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load this service listing.')),
      );
      return;
    }

    final contactPhoneController = TextEditingController(
      text: item['contactPhone']?.toString() ?? '',
    );
    List<String> mergeOptions(List<String> defaults, List<String> selected) {
      return <String>{
        ...defaults.map((entry) => entry.trim()).where((e) => e.isNotEmpty),
        ...selected.map((entry) => entry.trim()).where((e) => e.isNotEmpty),
      }.toList(growable: false);
    }

    final categorySlug = item['categorySlug']?.toString() ?? '';
    final isHouseHelpCategory = _isHouseHelpLikeCategorySlug(categorySlug);
    final preset = _presetForCategorySlug(categorySlug);
    final existingServices =
        (item['services'] as List<dynamic>? ?? const <dynamic>[])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final serviceOptions = mergeOptions(
      preset.serviceOptions,
      existingServices,
    );
    final selectedServices = <String>{
      ...existingServices.where((entry) => serviceOptions.contains(entry)),
    };
    if (selectedServices.isEmpty && serviceOptions.isNotEmpty) {
      selectedServices.add(serviceOptions.first);
    }
    var draftService = selectedServices.isNotEmpty
        ? selectedServices.first
        : serviceOptions.first;
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
    var selectedZoneRadius = _normalizeZoneRadius(
      (serviceZone['radiusKm'] as num?)?.toDouble() ?? 1,
    );
    final houseHelpConfig = Map<String, dynamic>.from(
      (item['houseHelpConfig'] as Map?) ?? const <String, dynamic>{},
    );
    final existingBookingTypes =
        (houseHelpConfig['bookingTypes'] as List<dynamic>? ?? const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final bookingTypeOptions = mergeOptions(
      preset.bookingTypeOptions,
      existingBookingTypes,
    );
    final selectedBookingTypes = <String>{...existingBookingTypes};
    if (isHouseHelpCategory &&
        selectedBookingTypes.isEmpty &&
        bookingTypeOptions.isNotEmpty) {
      selectedBookingTypes.add(bookingTypeOptions.first);
    }
    var draftBookingType = selectedBookingTypes.isNotEmpty
        ? selectedBookingTypes.first
        : (bookingTypeOptions.isNotEmpty ? bookingTypeOptions.first : '');

    final existingShifts =
        (houseHelpConfig['shiftDurations'] as List<dynamic>? ?? const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final shiftOptions = mergeOptions(preset.shiftOptions, existingShifts);
    final selectedShifts = <String>{...existingShifts};
    if (isHouseHelpCategory &&
        selectedShifts.isEmpty &&
        shiftOptions.isNotEmpty) {
      selectedShifts.add(shiftOptions.first);
    }
    var draftShift = selectedShifts.isNotEmpty
        ? selectedShifts.first
        : (shiftOptions.isNotEmpty ? shiftOptions.first : '');

    final existingHomeSizes =
        (houseHelpConfig['homeSizes'] as List<dynamic>? ?? const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final homeSizeOptions = mergeOptions(
      preset.homeSizeOptions,
      existingHomeSizes,
    );
    final selectedHomeSizes = <String>{...existingHomeSizes};
    if (isHouseHelpCategory &&
        selectedHomeSizes.isEmpty &&
        homeSizeOptions.isNotEmpty) {
      selectedHomeSizes.add(homeSizeOptions.first);
    }
    var draftHomeSize = selectedHomeSizes.isNotEmpty
        ? selectedHomeSizes.first
        : (homeSizeOptions.isNotEmpty ? homeSizeOptions.first : '');

    final existingArrivals =
        (houseHelpConfig['arrivalTargets'] as List<dynamic>? ?? const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final arrivalOptions = mergeOptions(
      preset.arrivalOptions,
      existingArrivals,
    );
    final selectedArrivals = <String>{...existingArrivals};
    if (isHouseHelpCategory &&
        selectedArrivals.isEmpty &&
        arrivalOptions.isNotEmpty) {
      selectedArrivals.add(arrivalOptions.last);
    }
    var draftArrival = selectedArrivals.isNotEmpty
        ? selectedArrivals.first
        : (arrivalOptions.isNotEmpty ? arrivalOptions.last : '');

    final existingSupplyModes =
        (houseHelpConfig['supplyModes'] as List<dynamic>? ?? const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final supplyModeOptions = mergeOptions(
      preset.supplyModeOptions,
      existingSupplyModes,
    );
    final selectedSupplyModes = <String>{...existingSupplyModes};
    if (isHouseHelpCategory &&
        selectedSupplyModes.isEmpty &&
        supplyModeOptions.isNotEmpty) {
      selectedSupplyModes.add(supplyModeOptions.last);
    }
    var draftSupplyMode = selectedSupplyModes.isNotEmpty
        ? selectedSupplyModes.first
        : (supplyModeOptions.isNotEmpty ? supplyModeOptions.last : '');

    if (!mounted) return;
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      builder: (sheetContext) {
        var isSaving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget multiSelectDropdown({
              required String label,
              required List<String> options,
              required String draftValue,
              required ValueChanged<String> onDraftChanged,
              required Set<String> selectedValues,
              required VoidCallback onAdd,
              required ValueChanged<String> onRemove,
            }) {
              if (options.isEmpty) {
                return const SizedBox.shrink();
              }
              final safeDraft = options.contains(draftValue)
                  ? draftValue
                  : options.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            '$label|$safeDraft|${options.join('|')}',
                          ),
                          isExpanded: true,
                          initialValue: safeDraft,
                          decoration: InputDecoration(labelText: label),
                          items: options
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry,
                                  child: Text(
                                    entry,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  onDraftChanged(value);
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: isSaving ? null : onAdd,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        tooltip: 'Add',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedValues
                        .map(
                          (value) => Chip(
                            label: Text(value),
                            onDeleted: isSaving ? null : () => onRemove(value),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              );
            }

            Future<void> save() async {
              if (selectedServices.isEmpty) {
                setModalState(() {
                  errorText = 'Add at least one offered service.';
                });
                return;
              }
              if (isHouseHelpCategory &&
                  (selectedBookingTypes.isEmpty ||
                      selectedShifts.isEmpty ||
                      selectedArrivals.isEmpty ||
                      selectedHomeSizes.isEmpty ||
                      selectedSupplyModes.isEmpty)) {
                setModalState(() {
                  errorText =
                      'Complete house-help criteria using the dedicated fields.';
                });
                return;
              }
              setModalState(() {
                isSaving = true;
                errorText = null;
              });

              try {
                final payload = <String, dynamic>{
                  'providerId': providerId,
                  'contactPhone': contactPhoneController.text.trim(),
                  'services': selectedServices.toList(growable: false),
                  'serviceZone': {
                    'enabled': true,
                    'centerLatitude': zoneCenter.latitude,
                    'centerLongitude': zoneCenter.longitude,
                    'radiusKm': selectedZoneRadius,
                  },
                };
                if (isHouseHelpCategory) {
                  payload['houseHelpConfig'] = {
                    'bookingTypes': selectedBookingTypes.toList(
                      growable: false,
                    ),
                    'shiftDurations': selectedShifts.toList(growable: false),
                    'homeSizes': selectedHomeSizes.toList(growable: false),
                    'arrivalTargets': selectedArrivals.toList(growable: false),
                    'supplyModes': selectedSupplyModes.toList(growable: false),
                  };
                }
                await ApiClient.post(
                  '/pro/${widget.userId}/provider-settings',
                  payload,
                );
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop(true);
              } catch (error) {
                if (!sheetContext.mounted) return;
                setModalState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                });
              } finally {
                if (sheetContext.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
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
                      item?['name']?.toString() ?? 'Edit listing',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactPhoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    multiSelectDropdown(
                      label: 'Offered services',
                      options: serviceOptions,
                      draftValue: draftService,
                      onDraftChanged: (value) =>
                          setModalState(() => draftService = value),
                      selectedValues: selectedServices,
                      onAdd: () => setModalState(() {
                        selectedServices.add(draftService);
                      }),
                      onRemove: (value) =>
                          setModalState(() => selectedServices.remove(value)),
                    ),
                    if (isHouseHelpCategory) ...[
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Booking types',
                        options: bookingTypeOptions,
                        draftValue: draftBookingType,
                        onDraftChanged: (value) =>
                            setModalState(() => draftBookingType = value),
                        selectedValues: selectedBookingTypes,
                        onAdd: () => setModalState(() {
                          selectedBookingTypes.add(draftBookingType);
                        }),
                        onRemove: (value) => setModalState(
                          () => selectedBookingTypes.remove(value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Shift durations',
                        options: shiftOptions,
                        draftValue: draftShift,
                        onDraftChanged: (value) =>
                            setModalState(() => draftShift = value),
                        selectedValues: selectedShifts,
                        onAdd: () => setModalState(() {
                          selectedShifts.add(draftShift);
                        }),
                        onRemove: (value) =>
                            setModalState(() => selectedShifts.remove(value)),
                      ),
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Home sizes',
                        options: homeSizeOptions,
                        draftValue: draftHomeSize,
                        onDraftChanged: (value) =>
                            setModalState(() => draftHomeSize = value),
                        selectedValues: selectedHomeSizes,
                        onAdd: () => setModalState(() {
                          selectedHomeSizes.add(draftHomeSize);
                        }),
                        onRemove: (value) => setModalState(
                          () => selectedHomeSizes.remove(value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Arrival targets',
                        options: arrivalOptions,
                        draftValue: draftArrival,
                        onDraftChanged: (value) =>
                            setModalState(() => draftArrival = value),
                        selectedValues: selectedArrivals,
                        onAdd: () => setModalState(() {
                          selectedArrivals.add(draftArrival);
                        }),
                        onRemove: (value) =>
                            setModalState(() => selectedArrivals.remove(value)),
                      ),
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Supply modes',
                        options: supplyModeOptions,
                        draftValue: draftSupplyMode,
                        onDraftChanged: (value) =>
                            setModalState(() => draftSupplyMode = value),
                        selectedValues: selectedSupplyModes,
                        onAdd: () => setModalState(() {
                          selectedSupplyModes.add(draftSupplyMode);
                        }),
                        onRemove: (value) => setModalState(
                          () => selectedSupplyModes.remove(value),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
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
                            if (isSaving) return;
                            setModalState(() => zoneCenter = point);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final location = await _requestCurrentLocation(
                                  showFailureSnackBar: false,
                                );
                                if (location == null || !sheetContext.mounted) {
                                  return;
                                }
                                setModalState(() => zoneCenter = location);
                              },
                        icon: const Icon(Icons.my_location_rounded),
                        label: const Text('Use current location'),
                      ),
                    ),
                    DropdownButtonFormField<double>(
                      key: ValueKey('zone-radius-edit|$selectedZoneRadius'),
                      isExpanded: true,
                      initialValue: selectedZoneRadius,
                      decoration: const InputDecoration(
                        labelText: 'Zone radius',
                      ),
                      items: _zoneRadiusOptionsKm
                          .map(
                            (radius) => DropdownMenuItem<double>(
                              value: radius,
                              child: Text(_zoneRadiusLabel(radius)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setModalState(() => selectedZoneRadius = value);
                            },
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.homeServices,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isSaving ? 'Saving...' : 'Save changes'),
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

    if (didSave != true || !mounted) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Service listing updated.')));
  }

  Future<void> _openCreateServiceListing() async {
    final resolvedLocation = await _requestCurrentLocation(
      showFailureSnackBar: false,
    );
    if (!mounted) return;
    final initialZoneCenter =
        resolvedLocation ?? const LatLng(11.5886, 43.1457);
    if (resolvedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Live location is taking longer than expected. Move the zone pin manually to continue.',
          ),
        ),
      );
    }

    List<Map<String, dynamic>> categories;
    try {
      final response = await ApiClient.get(
        '/catalog/home-service-categories',
        forceRefresh: true,
      );
      categories = (response as List<dynamic>)
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList(growable: false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return;
    }

    if (categories.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No service categories are available yet.'),
        ),
      );
      return;
    }

    String categorySlugForId(String categoryId) {
      return categories
              .firstWhere(
                (entry) => entry['id']?.toString() == categoryId,
                orElse: () => categories.first,
              )['slug']
              ?.toString()
              .trim() ??
          '';
    }

    String categoryNameForId(String categoryId) {
      return categories
              .firstWhere(
                (entry) => entry['id']?.toString() == categoryId,
                orElse: () => categories.first,
              )['name']
              ?.toString()
              .trim() ??
          'Service';
    }

    String selectedCategoryId =
        (categories
            .firstWhere(
              (entry) => entry['slug']?.toString() == 'house-help',
              orElse: () => categories.first,
            )['id']
            ?.toString() ??
        categories.first['id'].toString());
    final selectedPreset = _presetForCategorySlug(
      categorySlugForId(selectedCategoryId),
    );

    final nameController = TextEditingController(text: widget.businessName);
    final titleController = TextEditingController(
      text: selectedPreset.defaultTitle,
    );
    final startingPriceController = TextEditingController(text: '25');
    final phoneController = TextEditingController();
    String? listingImageUrl;
    Uint8List? listingImageBytes;
    var isUploadingListingImage = false;
    var selectedZoneRadius = _zoneRadiusOptionsKm.last;
    final selectedServices = <String>{
      if (selectedPreset.serviceOptions.isNotEmpty)
        selectedPreset.serviceOptions.first,
    };
    final selectedBookingTypes = <String>{
      if (selectedPreset.bookingTypeOptions.isNotEmpty)
        selectedPreset.bookingTypeOptions.first,
    };
    final selectedShifts = <String>{
      if (selectedPreset.shiftOptions.isNotEmpty)
        selectedPreset.shiftOptions.first,
    };
    final selectedArrivals = <String>{
      if (selectedPreset.arrivalOptions.isNotEmpty)
        selectedPreset.arrivalOptions.last,
    };
    final selectedHomeSizes = <String>{
      if (selectedPreset.homeSizeOptions.isNotEmpty)
        selectedPreset.homeSizeOptions.first,
    };
    final selectedSupplyModes = <String>{
      if (selectedPreset.supplyModeOptions.isNotEmpty)
        selectedPreset.supplyModeOptions.last,
    };

    var draftService = selectedPreset.serviceOptions.first;
    var draftBookingType = selectedPreset.bookingTypeOptions.isNotEmpty
        ? selectedPreset.bookingTypeOptions.first
        : '';
    var draftShift = selectedPreset.shiftOptions.isNotEmpty
        ? selectedPreset.shiftOptions.first
        : '';
    var draftArrival = selectedPreset.arrivalOptions.isNotEmpty
        ? selectedPreset.arrivalOptions.last
        : '';
    var draftHomeSize = selectedPreset.homeSizeOptions.isNotEmpty
        ? selectedPreset.homeSizeOptions.first
        : '';
    var draftSupplyMode = selectedPreset.supplyModeOptions.isNotEmpty
        ? selectedPreset.supplyModeOptions.last
        : '';

    var zoneCenter = initialZoneCenter;

    if (!mounted) return;
    final didCreate = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      builder: (sheetContext) {
        var isSaving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final selectedCategorySlug = categorySlugForId(selectedCategoryId);
            final isHouseHelpCategory = _isHouseHelpLikeCategorySlug(
              selectedCategorySlug,
            );
            final categoryPreset = _presetForCategorySlug(selectedCategorySlug);

            Widget multiSelectDropdown({
              required String label,
              required List<String> options,
              required String draftValue,
              required ValueChanged<String> onDraftChanged,
              required Set<String> selectedValues,
              required VoidCallback onAdd,
              required ValueChanged<String> onRemove,
            }) {
              final safeDraft = options.contains(draftValue)
                  ? draftValue
                  : options.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            '$label|$safeDraft|${options.join('|')}',
                          ),
                          isExpanded: true,
                          initialValue: safeDraft,
                          decoration: InputDecoration(labelText: label),
                          items: options
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry,
                                  child: Text(
                                    entry,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  onDraftChanged(value);
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: isSaving ? null : onAdd,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        tooltip: 'Add',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedValues
                        .map(
                          (value) => Chip(
                            label: Text(value),
                            onDeleted: isSaving ? null : () => onRemove(value),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              );
            }

            Future<void> save() async {
              if (isUploadingListingImage) {
                setModalState(() {
                  errorText = 'Wait for the listing image upload to finish.';
                });
                return;
              }
              final parsedPrice = double.tryParse(
                startingPriceController.text.trim(),
              );
              if (parsedPrice == null || parsedPrice <= 0) {
                setModalState(() {
                  errorText = 'Enter a valid starting price.';
                });
                return;
              }
              if (selectedServices.isEmpty) {
                setModalState(() {
                  errorText = 'Select at least one service.';
                });
                return;
              }
              if (isHouseHelpCategory &&
                  (selectedBookingTypes.isEmpty ||
                      selectedShifts.isEmpty ||
                      selectedArrivals.isEmpty ||
                      selectedHomeSizes.isEmpty ||
                      selectedSupplyModes.isEmpty)) {
                setModalState(() {
                  errorText =
                      'Complete the house-help booking criteria before saving.';
                });
                return;
              }

              setModalState(() {
                isSaving = true;
                errorText = null;
              });

              try {
                final payload = <String, dynamic>{
                  'name': nameController.text.trim(),
                  'title': titleController.text.trim(),
                  'categoryId': selectedCategoryId,
                  'startingPrice': parsedPrice,
                  'contactPhone': phoneController.text.trim(),
                  if (listingImageUrl != null && listingImageUrl!.isNotEmpty)
                    'imageUrl': listingImageUrl,
                  'services': selectedServices.toList(growable: false),
                  'serviceZone': {
                    'enabled': true,
                    'centerLatitude': zoneCenter.latitude,
                    'centerLongitude': zoneCenter.longitude,
                    'radiusKm': selectedZoneRadius,
                  },
                };
                if (isHouseHelpCategory) {
                  payload['houseHelpConfig'] = {
                    'bookingTypes': selectedBookingTypes.toList(
                      growable: false,
                    ),
                    'shiftDurations': selectedShifts.toList(growable: false),
                    'homeSizes': selectedHomeSizes.toList(growable: false),
                    'arrivalTargets': selectedArrivals.toList(growable: false),
                    'supplyModes': selectedSupplyModes.toList(growable: false),
                  };
                }

                await ApiClient.post(
                  '/pro/${widget.userId}/home-service-provider',
                  payload,
                );
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop(true);
              } catch (error) {
                if (!mounted) return;
                setModalState(() {
                  errorText = error.toString().replaceFirst('Exception: ', '');
                });
              } finally {
                if (sheetContext.mounted) {
                  setModalState(() => isSaving = false);
                }
              }
            }

            Future<void> pickAndUploadListingImage() async {
              if (isUploadingListingImage) return;
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1800,
                imageQuality: 88,
              );
              if (file == null) return;

              final bytes = await file.readAsBytes();
              if (!sheetContext.mounted) return;
              setModalState(() {
                listingImageBytes = bytes;
                isUploadingListingImage = true;
                errorText = null;
              });

              try {
                final uploaded = await MediaUploadService.uploadImage(
                  scope: MediaUploadScope.provider,
                  ownerId: widget.userId,
                  fileName: file.name,
                  mimeType: file.mimeType,
                  bytes: bytes,
                );
                if (!sheetContext.mounted) return;
                setModalState(() {
                  listingImageUrl = uploaded.url;
                });
              } catch (error) {
                if (!sheetContext.mounted) return;
                setModalState(() {
                  errorText = ApiClient.userFacingError(error);
                });
              } finally {
                if (sheetContext.mounted) {
                  setModalState(() => isUploadingListingImage = false);
                }
              }
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
                      'Create Home-Service Listing',
                      style: Theme.of(modalContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choose a service category first. The rest of the setup adapts automatically.',
                      style: Theme.of(
                        modalContext,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('category|$selectedCategoryId'),
                      isExpanded: true,
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map((category) {
                            final id = category['id']?.toString() ?? '';
                            final label =
                                category['name']?.toString() ?? 'Category';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          })
                          .toList(growable: false),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null || value.isEmpty) return;
                              setModalState(() {
                                selectedCategoryId = value;
                                final nextPreset = _presetForCategorySlug(
                                  categorySlugForId(value),
                                );
                                selectedServices
                                  ..clear()
                                  ..add(nextPreset.serviceOptions.first);
                                draftService = nextPreset.serviceOptions.first;
                                titleController.text =
                                    '${categoryNameForId(value)} Specialist';

                                selectedBookingTypes
                                  ..clear()
                                  ..addAll(
                                    nextPreset.bookingTypeOptions.isNotEmpty
                                        ? [nextPreset.bookingTypeOptions.first]
                                        : const <String>[],
                                  );
                                selectedShifts
                                  ..clear()
                                  ..addAll(
                                    nextPreset.shiftOptions.isNotEmpty
                                        ? [nextPreset.shiftOptions.first]
                                        : const <String>[],
                                  );
                                selectedArrivals
                                  ..clear()
                                  ..addAll(
                                    nextPreset.arrivalOptions.isNotEmpty
                                        ? [nextPreset.arrivalOptions.last]
                                        : const <String>[],
                                  );
                                selectedHomeSizes
                                  ..clear()
                                  ..addAll(
                                    nextPreset.homeSizeOptions.isNotEmpty
                                        ? [nextPreset.homeSizeOptions.first]
                                        : const <String>[],
                                  );
                                selectedSupplyModes
                                  ..clear()
                                  ..addAll(
                                    nextPreset.supplyModeOptions.isNotEmpty
                                        ? [nextPreset.supplyModeOptions.last]
                                        : const <String>[],
                                  );
                                draftBookingType =
                                    nextPreset.bookingTypeOptions.isNotEmpty
                                    ? nextPreset.bookingTypeOptions.first
                                    : '';
                                draftShift = nextPreset.shiftOptions.isNotEmpty
                                    ? nextPreset.shiftOptions.first
                                    : '';
                                draftArrival =
                                    nextPreset.arrivalOptions.isNotEmpty
                                    ? nextPreset.arrivalOptions.last
                                    : '';
                                draftHomeSize =
                                    nextPreset.homeSizeOptions.isNotEmpty
                                    ? nextPreset.homeSizeOptions.first
                                    : '';
                                draftSupplyMode =
                                    nextPreset.supplyModeOptions.isNotEmpty
                                    ? nextPreset.supplyModeOptions.last
                                    : '';
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Listing title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: startingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Starting price',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          modalContext,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: listingImageBytes != null
                          ? Image.memory(listingImageBytes!, fit: BoxFit.cover)
                          : ((listingImageUrl?.isNotEmpty ?? false)
                                ? Image.network(
                                    listingImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (
                                          context,
                                          error,
                                          stackTrace,
                                        ) => const Center(
                                          child: Icon(
                                            Icons.home_repair_service_outlined,
                                            size: 42,
                                          ),
                                        ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.home_repair_service_outlined,
                                      size: 42,
                                    ),
                                  )),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isSaving || isUploadingListingImage
                          ? null
                          : pickAndUploadListingImage,
                      icon: isUploadingListingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        isUploadingListingImage
                            ? 'Uploading listing image...'
                            : 'Upload Listing Image',
                      ),
                    ),
                    const SizedBox(height: 16),
                    multiSelectDropdown(
                      label: 'Services offered',
                      options: categoryPreset.serviceOptions,
                      draftValue: draftService,
                      onDraftChanged: (value) =>
                          setModalState(() => draftService = value),
                      selectedValues: selectedServices,
                      onAdd: () => setModalState(() {
                        selectedServices.add(draftService);
                      }),
                      onRemove: (value) =>
                          setModalState(() => selectedServices.remove(value)),
                    ),
                    if (isHouseHelpCategory) ...[
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Booking types',
                        options: categoryPreset.bookingTypeOptions,
                        draftValue: draftBookingType,
                        onDraftChanged: (value) =>
                            setModalState(() => draftBookingType = value),
                        selectedValues: selectedBookingTypes,
                        onAdd: () => setModalState(() {
                          selectedBookingTypes.add(draftBookingType);
                        }),
                        onRemove: (value) => setModalState(
                          () => selectedBookingTypes.remove(value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Shift durations',
                        options: categoryPreset.shiftOptions,
                        draftValue: draftShift,
                        onDraftChanged: (value) =>
                            setModalState(() => draftShift = value),
                        selectedValues: selectedShifts,
                        onAdd: () => setModalState(() {
                          selectedShifts.add(draftShift);
                        }),
                        onRemove: (value) =>
                            setModalState(() => selectedShifts.remove(value)),
                      ),
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Arrival targets',
                        options: categoryPreset.arrivalOptions,
                        draftValue: draftArrival,
                        onDraftChanged: (value) =>
                            setModalState(() => draftArrival = value),
                        selectedValues: selectedArrivals,
                        onAdd: () => setModalState(() {
                          selectedArrivals.add(draftArrival);
                        }),
                        onRemove: (value) =>
                            setModalState(() => selectedArrivals.remove(value)),
                      ),
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Home sizes',
                        options: categoryPreset.homeSizeOptions,
                        draftValue: draftHomeSize,
                        onDraftChanged: (value) =>
                            setModalState(() => draftHomeSize = value),
                        selectedValues: selectedHomeSizes,
                        onAdd: () => setModalState(() {
                          selectedHomeSizes.add(draftHomeSize);
                        }),
                        onRemove: (value) => setModalState(
                          () => selectedHomeSizes.remove(value),
                        ),
                      ),
                      const SizedBox(height: 12),
                      multiSelectDropdown(
                        label: 'Supply modes',
                        options: categoryPreset.supplyModeOptions,
                        draftValue: draftSupplyMode,
                        onDraftChanged: (value) =>
                            setModalState(() => draftSupplyMode = value),
                        selectedValues: selectedSupplyModes,
                        onAdd: () => setModalState(() {
                          selectedSupplyModes.add(draftSupplyMode);
                        }),
                        onRemove: (value) => setModalState(
                          () => selectedSupplyModes.remove(value),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
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
                            if (isSaving) return;
                            setModalState(() => zoneCenter = point);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final location = await _requestCurrentLocation(
                                  showFailureSnackBar: false,
                                );
                                if (location == null) return;
                                if (!sheetContext.mounted) return;
                                setModalState(() => zoneCenter = location);
                              },
                        icon: const Icon(Icons.my_location_rounded),
                        label: const Text('Use current location'),
                      ),
                    ),
                    DropdownButtonFormField<double>(
                      key: ValueKey('zone-radius-create|$selectedZoneRadius'),
                      isExpanded: true,
                      initialValue: selectedZoneRadius,
                      decoration: const InputDecoration(
                        labelText: 'Zone radius',
                      ),
                      items: _zoneRadiusOptionsKm
                          .map(
                            (radius) => DropdownMenuItem<double>(
                              value: radius,
                              child: Text(_zoneRadiusLabel(radius)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setModalState(() => selectedZoneRadius = value);
                            },
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.homeServices,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isSaving ? 'Creating...' : 'Create listing',
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

    if (didCreate != true || !mounted) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service listing created and linked.')),
    );
  }

  Future<void> _openCreateLaundryService() async {
    await _openLaundryServiceSheet();
  }

  Future<void> _openEditLaundryService(Map<String, dynamic> item) async {
    await _openLaundryServiceSheet(item: item);
  }

  Future<void> _openLaundryServiceSheet({Map<String, dynamic>? item}) async {
    final isEdit = item != null;
    final serviceId = item?['id']?.toString() ?? '';
    final fallbackPrice = ((item?['price'] as num?)?.toDouble() ?? 6000).clamp(
      1,
      100000,
    );
    final rawBookingConfig = item?['bookingConfig'] is Map
        ? Map<String, dynamic>.from(item!['bookingConfig'] as Map)
        : const <String, dynamic>{};

    final rawCatalog =
        (rawBookingConfig['itemCatalog'] as List<dynamic>? ?? const [])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList(growable: false);
    String resolveLaundryItemCategory(Map<String, dynamic> entry) {
      final rawCategory = entry['category']?.toString().trim().toLowerCase();
      if (rawCategory == 'group' || rawCategory == 'unit') {
        return rawCategory!;
      }
      final id = entry['id']?.toString().trim().toLowerCase() ?? '';
      final label = entry['label']?.toString().trim().toLowerCase() ?? '';
      if (id.contains('wash_fold_') || label.contains('wash & fold')) {
        return 'group';
      }
      return 'unit';
    }

    final draftCatalog = rawCatalog.isNotEmpty
        ? rawCatalog
              .map(
                (entry) => _LaundryItemDraft(
                  draftId: entry['id']?.toString().trim().isNotEmpty == true
                      ? entry['id']!.toString().trim()
                      : DateTime.now().microsecondsSinceEpoch.toString(),
                  itemId: entry['id']?.toString().trim() ?? '',
                  label: entry['label']?.toString().trim() ?? '',
                  priceText: _priceLabel(
                    (entry['price'] as num?) ?? fallbackPrice,
                  ),
                  category: resolveLaundryItemCategory(entry),
                  spec: entry['spec']?.toString().trim() ?? '',
                ),
              )
              .toList(growable: true)
        : <_LaundryItemDraft>[
            _LaundryItemDraft(
              draftId: 'shirts',
              itemId: 'shirts',
              label: 'Shirt',
              priceText: _priceLabel(700),
              category: 'unit',
              spec: '',
            ),
            _LaundryItemDraft(
              draftId: 'trouser',
              itemId: 'trouser',
              label: 'Trouser',
              priceText: _priceLabel(800),
              category: 'unit',
              spec: '',
            ),
            _LaundryItemDraft(
              draftId: 'wash_fold_10_20',
              itemId: 'wash_fold_10_20',
              label: 'Wash & Fold 10-20 pieces',
              priceText: _priceLabel(6000),
              category: 'group',
              spec: '10 to 20 pieces',
            ),
          ];
    final pickupSlots =
        (rawBookingConfig['pickupSlots'] as List<dynamic>? ?? const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toSet()
            .toList(growable: true);
    if (pickupSlots.isEmpty) {
      pickupSlots.addAll(const [
        '08:00 - 10:00',
        '10:00 - 12:00',
        '14:00 - 16:00',
        '16:00 - 18:00',
      ]);
    }

    final priceController = TextEditingController(
      text: _priceLabel((item?['price'] as num?) ?? 6000),
    );
    final unitController = TextEditingController(
      text: item?['unit']?.toString() ?? 'per order',
    );
    final turnaroundHours =
        (rawBookingConfig['turnaroundHours'] as num?)?.toInt() ?? 26;
    final minNoticeHours =
        (rawBookingConfig['minNoticeHours'] as num?)?.toInt() ?? 0;
    final maxAdvanceDays =
        (rawBookingConfig['maxAdvanceDays'] as num?)?.toInt() ?? 5;
    final taxRatePercentController = TextEditingController(
      text: _priceLabel((rawBookingConfig['taxRatePercent'] as num?) ?? 8),
    );
    final deliveryFeeController = TextEditingController(
      text: _priceLabel((rawBookingConfig['deliveryFee'] as num?) ?? 0),
    );
    final slotInputController = TextEditingController();
    var enabled = item?['enabled'] as bool? ?? true;
    var isSaving = false;
    String? errorText;

    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Future<void> save() async {
              const name = 'Wash & Fold';
              final unit = unitController.text.trim();
              final price = double.tryParse(priceController.text.trim());
              final taxRatePercent = double.tryParse(
                taxRatePercentController.text.trim(),
              );
              final deliveryFee = double.tryParse(
                deliveryFeeController.text.trim(),
              );

              final itemCatalog = draftCatalog
                  .map((draft) {
                    final label = draft.label.trim();
                    final spec = draft.spec.trim();
                    final parsedPrice = double.tryParse(draft.priceText.trim());
                    final normalizedId =
                        (draft.itemId.trim().isNotEmpty
                                ? draft.itemId.trim()
                                : label)
                            .toLowerCase()
                            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                            .replaceAll(RegExp(r'^_+|_+$'), '');
                    final category = draft.category.trim().toLowerCase();
                    return (
                      id: normalizedId,
                      label: label,
                      price: parsedPrice,
                      category: category,
                      spec: spec,
                    );
                  })
                  .where((item) => item.label.isNotEmpty)
                  .toList(growable: false);
              final hasInvalidCatalog = itemCatalog.any(
                (entry) =>
                    entry.id.isEmpty ||
                    entry.price == null ||
                    entry.price! <= 0 ||
                    (entry.category != 'unit' && entry.category != 'group') ||
                    (entry.category == 'group' && entry.spec.isEmpty),
              );
              final normalizedSlots = pickupSlots
                  .map((slot) => slot.trim())
                  .where((slot) => slot.isNotEmpty)
                  .toSet()
                  .toList(growable: false);

              if (price == null || price <= 0) {
                setModalState(
                  () => errorText = 'Price must be greater than zero.',
                );
                return;
              }
              if (unit.length < 2) {
                setModalState(
                  () => errorText = 'Unit must be at least 2 characters.',
                );
                return;
              }
              if (itemCatalog.isEmpty || hasInvalidCatalog) {
                setModalState(
                  () => errorText =
                      'Add at least one valid bookable item with a price.',
                );
                return;
              }
              if (normalizedSlots.isEmpty) {
                setModalState(
                  () => errorText = 'Add at least one pickup time slot.',
                );
                return;
              }
              if (taxRatePercent == null ||
                  taxRatePercent < 0 ||
                  taxRatePercent > 40) {
                setModalState(
                  () => errorText = 'Tax rate must be between 0% and 40%.',
                );
                return;
              }
              if (deliveryFee == null ||
                  deliveryFee < 0 ||
                  deliveryFee > 100000) {
                setModalState(
                  () =>
                      errorText = 'Delivery fee must be between 0 and 100000.',
                );
                return;
              }

              setModalState(() {
                errorText = null;
                isSaving = true;
              });
              try {
                final payload = <String, dynamic>{
                  'name': name,
                  'price': price,
                  'unit': unit,
                  'bookingConfig': {
                    'itemCatalog': itemCatalog
                        .map(
                          (entry) => {
                            'id': entry.id,
                            'label': entry.label,
                            'price': entry.price,
                            'category': entry.category,
                            if (entry.category == 'group') 'spec': entry.spec,
                          },
                        )
                        .toList(growable: false),
                    'pickupSlots': normalizedSlots,
                    'turnaroundHours': turnaroundHours,
                    'minNoticeHours': minNoticeHours,
                    'maxAdvanceDays': maxAdvanceDays,
                    'taxRatePercent': taxRatePercent,
                    'deliveryFee': deliveryFee,
                  },
                  if (isEdit) 'active': enabled,
                };
                if (isEdit) {
                  await ApiClient.post(
                    '/pro/${widget.userId}/laundry-services/$serviceId',
                    payload,
                  );
                } else {
                  await ApiClient.post(
                    '/pro/${widget.userId}/laundry-services',
                    payload,
                  );
                }
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop(true);
              } catch (error) {
                if (!sheetContext.mounted) return;
                setModalState(() {
                  isSaving = false;
                  errorText = error.toString().replaceFirst('Exception: ', '');
                });
              }
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
                      isEdit ? 'Edit laundry service' : 'Add laundry service',
                      style: Theme.of(modalContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Service: Wash & Fold',
                      style: Theme.of(modalContext).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            enabled: !isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              hintText: '25',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            enabled: !isSaving,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              hintText: 'per bag',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Unit items',
                      style: Theme.of(modalContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...draftCatalog
                        .where((draft) => draft.category == 'unit')
                        .map(
                          (draft) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    key: ValueKey(
                                      'laundry-item-${draft.draftId}',
                                    ),
                                    enabled: !isSaving,
                                    initialValue: draft.label,
                                    decoration: const InputDecoration(
                                      labelText: 'Item',
                                      hintText: 'Shirts',
                                    ),
                                    onChanged: (value) => draft.label = value,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    key: ValueKey(
                                      'laundry-price-${draft.draftId}',
                                    ),
                                    enabled: !isSaving,
                                    initialValue: draft.priceText,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Price',
                                      hintText: '5',
                                    ),
                                    onChanged: (value) =>
                                        draft.priceText = value,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed:
                                      isSaving || draftCatalog.length <= 1
                                      ? null
                                      : () => setModalState(
                                          () => draftCatalog.remove(draft),
                                        ),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                  tooltip: 'Remove item',
                                ),
                              ],
                            ),
                          ),
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () => setModalState(
                                () => draftCatalog.add(
                                  _LaundryItemDraft(
                                    draftId: DateTime.now()
                                        .microsecondsSinceEpoch
                                        .toString(),
                                    itemId: '',
                                    label: '',
                                    priceText: _priceLabel(fallbackPrice),
                                    category: 'unit',
                                    spec: '',
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add unit item'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wash & Fold groups (10+)',
                      style: Theme.of(modalContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...draftCatalog
                        .where((draft) => draft.category == 'group')
                        .map(
                          (draft) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        key: ValueKey(
                                          'laundry-group-item-${draft.draftId}',
                                        ),
                                        enabled: !isSaving,
                                        initialValue: draft.label,
                                        decoration: const InputDecoration(
                                          labelText: 'Group',
                                          hintText: 'Wash & Fold 10-20 pieces',
                                        ),
                                        onChanged: (value) =>
                                            draft.label = value,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey(
                                          'laundry-group-price-${draft.draftId}',
                                        ),
                                        enabled: !isSaving,
                                        initialValue: draft.priceText,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Price',
                                          hintText: '6000',
                                        ),
                                        onChanged: (value) =>
                                            draft.priceText = value,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      onPressed:
                                          isSaving || draftCatalog.length <= 1
                                          ? null
                                          : () => setModalState(
                                              () => draftCatalog.remove(draft),
                                            ),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      tooltip: 'Remove group',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  key: ValueKey(
                                    'laundry-group-spec-${draft.draftId}',
                                  ),
                                  enabled: !isSaving,
                                  initialValue: draft.spec,
                                  decoration: const InputDecoration(
                                    labelText: 'Spec',
                                    hintText: '10 to 20 pieces',
                                  ),
                                  onChanged: (value) => draft.spec = value,
                                ),
                              ],
                            ),
                          ),
                        ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: isSaving
                            ? null
                            : () => setModalState(
                                () => draftCatalog.add(
                                  _LaundryItemDraft(
                                    draftId: DateTime.now()
                                        .microsecondsSinceEpoch
                                        .toString(),
                                    itemId: '',
                                    label: '',
                                    priceText: _priceLabel(fallbackPrice),
                                    category: 'group',
                                    spec: '',
                                  ),
                                ),
                              ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add group'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pickup slots',
                      style: Theme.of(modalContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: pickupSlots
                          .map(
                            (slot) => Chip(
                              backgroundColor: AppColors.extraLightGrey,
                              labelStyle: const TextStyle(
                                color: AppColors.dark,
                                fontWeight: FontWeight.w600,
                              ),
                              deleteIconColor: AppColors.dark,
                              label: Text(slot),
                              onDeleted: isSaving
                                  ? null
                                  : () => setModalState(
                                      () => pickupSlots.remove(slot),
                                    ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: slotInputController,
                            enabled: !isSaving,
                            decoration: const InputDecoration(
                              labelText: 'New slot',
                              hintText: '18:00 - 20:00',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: isSaving
                              ? null
                              : () {
                                  final next = slotInputController.text.trim();
                                  if (next.isEmpty) return;
                                  if (pickupSlots.contains(next)) {
                                    slotInputController.clear();
                                    return;
                                  }
                                  setModalState(() {
                                    pickupSlots.add(next);
                                  });
                                  slotInputController.clear();
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.laundry,
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Checkout pricing',
                      style: Theme.of(modalContext).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: taxRatePercentController,
                            enabled: !isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Tax rate (%)',
                              hintText: '8',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: deliveryFeeController,
                            enabled: !isSaving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Delivery fee',
                              hintText: '0',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: enabled,
                        onChanged: isSaving
                            ? null
                            : (value) => setModalState(() => enabled = value),
                        title: const Text('Accept bookings'),
                        subtitle: Text(
                          enabled ? 'Visible and bookable' : 'Paused',
                        ),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorText!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.laundry,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          isSaving
                              ? (isEdit ? 'Saving...' : 'Creating...')
                              : (isEdit ? 'Save changes' : 'Create service'),
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

    if (didSave != true || !mounted) return;
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? 'Laundry service updated.'
              : 'Laundry service created and linked.',
        ),
      ),
    );
  }

  List<_AvailabilityModuleTab> _resolveTabs(Map<String, dynamic> data) {
    final tabs = <_AvailabilityModuleTab>[];
    if (_supportsServices) {
      tabs.add(
        _AvailabilityModuleTab(
          module: 'services',
          label: 'Services',
          color: AppColors.homeServices,
          icon: Icons.home_repair_service_outlined,
          enabledLabel: 'Active',
          disabledLabel: 'Paused',
          emptyMessage: 'No service listings found yet. Tap + to add one.',
          items: (data['services'] as List<dynamic>? ?? const [])
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList(growable: false),
        ),
      );
    }
    if (_supportsLaundry) {
      tabs.add(
        _AvailabilityModuleTab(
          module: 'laundry',
          label: 'Laundry',
          color: AppColors.laundry,
          icon: Icons.local_laundry_service_outlined,
          enabledLabel: 'Accepting laundry orders',
          disabledLabel: 'Laundry service paused',
          emptyMessage: 'No laundry services found yet. Tap + to add one.',
          items: (data['laundry'] as List<dynamic>? ?? const [])
              .map((entry) => Map<String, dynamic>.from(entry as Map))
              .toList(growable: false),
        ),
      );
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final hasServicesOnly = _supportsServices && !_supportsLaundry;
    final hasLaundryOnly = _supportsLaundry && !_supportsServices;
    final appBarTitle = hasLaundryOnly
        ? 'Laundry Availability'
        : hasServicesOnly
        ? 'Service Availability'
        : 'Provider Availability';
    final appBarColor = hasLaundryOnly
        ? AppColors.laundry
        : AppColors.homeServices;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          if (_supportsServices && !_supportsLaundry)
            IconButton(
              onPressed: _openCreateServiceListing,
              icon: const Icon(Icons.add_business_rounded),
              tooltip: 'Add service listing',
            ),
          if (_supportsLaundry && !_supportsServices)
            IconButton(
              onPressed: _openCreateLaundryService,
              icon: const Icon(Icons.local_laundry_service_outlined),
              tooltip: 'Add laundry service',
            ),
          if (_supportsServices && _supportsLaundry)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'services') {
                  _openCreateServiceListing();
                  return;
                }
                if (value == 'laundry') {
                  _openCreateLaundryService();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'services',
                  child: Text('Add service listing'),
                ),
                PopupMenuItem<String>(
                  value: 'laundry',
                  child: Text('Add laundry service'),
                ),
              ],
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add listing',
            ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _availabilityFuture,
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

          final data = snapshot.data ?? const <String, dynamic>{};
          final tabs = _resolveTabs(data);
          if (tabs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No provider modules are enabled for this pro profile.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (tabs.length == 1) {
            final tab = tabs.first;
            return _AvailabilityItemsList(
              color: tab.color,
              icon: tab.icon,
              enabledLabel: tab.enabledLabel,
              disabledLabel: tab.disabledLabel,
              emptyMessage: tab.emptyMessage,
              items: tab.items,
              busyIds: _busyIds,
              onEdit: tab.module == 'services'
                  ? (item) =>
                        _openEditServiceListing(item['id']?.toString() ?? '')
                  : tab.module == 'laundry'
                  ? _openEditLaundryService
                  : null,
              onToggle: (targetId, enabled) => _toggle(
                module: tab.module,
                targetId: targetId,
                enabled: enabled,
              ),
            );
          }

          return DefaultTabController(
            length: tabs.length,
            child: Column(
              children: [
                Material(
                  color: AppColors.homeServices,
                  child: TabBar(
                    tabs: tabs
                        .map((entry) => Tab(text: entry.label))
                        .toList(growable: false),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: tabs
                        .map(
                          (tab) => _AvailabilityItemsList(
                            color: tab.color,
                            icon: tab.icon,
                            enabledLabel: tab.enabledLabel,
                            disabledLabel: tab.disabledLabel,
                            emptyMessage: tab.emptyMessage,
                            items: tab.items,
                            busyIds: _busyIds,
                            onEdit: tab.module == 'services'
                                ? (item) => _openEditServiceListing(
                                    item['id']?.toString() ?? '',
                                  )
                                : tab.module == 'laundry'
                                ? _openEditLaundryService
                                : null,
                            onToggle: (targetId, enabled) => _toggle(
                              module: tab.module,
                              targetId: targetId,
                              enabled: enabled,
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvailabilityModuleTab {
  final String module;
  final String label;
  final Color color;
  final IconData icon;
  final String enabledLabel;
  final String disabledLabel;
  final String emptyMessage;
  final List<Map<String, dynamic>> items;

  const _AvailabilityModuleTab({
    required this.module,
    required this.label,
    required this.color,
    required this.icon,
    required this.enabledLabel,
    required this.disabledLabel,
    required this.emptyMessage,
    required this.items,
  });
}

class _CategoryListingPreset {
  final String defaultTitle;
  final List<String> serviceOptions;
  final List<String> bookingTypeOptions;
  final List<String> shiftOptions;
  final List<String> arrivalOptions;
  final List<String> homeSizeOptions;
  final List<String> supplyModeOptions;

  const _CategoryListingPreset({
    required this.defaultTitle,
    required this.serviceOptions,
    this.bookingTypeOptions = const <String>[],
    this.shiftOptions = const <String>[],
    this.arrivalOptions = const <String>[],
    this.homeSizeOptions = const <String>[],
    this.supplyModeOptions = const <String>[],
  });
}

class _LaundryItemDraft {
  final String draftId;
  String itemId;
  String label;
  String priceText;
  String category;
  String spec;

  _LaundryItemDraft({
    required this.draftId,
    required this.itemId,
    required this.label,
    required this.priceText,
    required this.category,
    required this.spec,
  });
}

class _AvailabilityItemsList extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String enabledLabel;
  final String disabledLabel;
  final String emptyMessage;
  final List<Map<String, dynamic>> items;
  final Set<String> busyIds;
  final Future<void> Function(Map<String, dynamic> item)? onEdit;
  final Future<void> Function(String targetId, bool enabled) onToggle;

  const _AvailabilityItemsList({
    required this.color,
    required this.icon,
    required this.enabledLabel,
    required this.disabledLabel,
    required this.emptyMessage,
    required this.items,
    required this.busyIds,
    this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id']?.toString() ?? '';
        final enabled = item['enabled'] as bool? ?? false;
        final isBusy = busyIds.contains(id);
        final details = item['details']?.toString().trim() ?? '';
        final statusLabel = enabled ? enabledLabel : disabledLabel;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          title: Text(
            item['name']?.toString() ?? 'Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            details.isNotEmpty ? details : statusLabel,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: SizedBox(
            width: onEdit == null ? 56 : 104,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    onPressed: isBusy ? null : () => onEdit!(item),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit listing',
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                Switch(
                  value: enabled,
                  onChanged: isBusy ? null : (value) => onToggle(id, value),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
