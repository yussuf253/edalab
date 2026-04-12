import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
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
  static const List<String> _servicesOptions = <String>[
    'Room Cleaning',
    'Floor Cleaning',
    'Kitchen Cleaning',
    'Bathroom Cleaning',
    'Dishes',
    'Laundry',
    'Dusting',
    'Ironing',
  ];
  static const List<String> _bookingTypeOptions = <String>[
    'One-time job',
    'Daily recurring',
    'Weekly recurring',
  ];
  static const List<String> _shiftOptions = <String>[
    '2 hours',
    '4 hours',
    '8 hours',
  ];
  static const List<String> _arrivalOptions = <String>[
    'Within 30 min',
    'Scheduled slot',
  ];
  static const List<String> _homeSizeOptions = <String>['F2', 'F3', 'F4'];
  static const List<String> _supplyModeOptions = <String>[
    'Provider supplies',
    'Customer supplies',
  ];

  late Future<Map<String, dynamic>> _availabilityFuture;
  final Set<String> _busyIds = <String>{};

  bool get _supportsServices =>
      widget.activeModules.isEmpty ||
      widget.activeModules.contains(ProModule.services);
  bool get _supportsLaundry => widget.activeModules.contains(ProModule.laundry);

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

    final nameController = TextEditingController(text: widget.businessName);
    final titleController = TextEditingController(
      text: 'House Help Specialist',
    );
    final startingPriceController = TextEditingController(text: '25');
    final phoneController = TextEditingController();
    final zoneRadiusController = TextEditingController(text: '1');

    final selectedServices = <String>{_servicesOptions.first};
    final selectedBookingTypes = <String>{_bookingTypeOptions.first};
    final selectedShifts = <String>{_shiftOptions.first};
    final selectedArrivals = <String>{_arrivalOptions.first};
    final selectedHomeSizes = <String>{_homeSizeOptions.first};
    final selectedSupplyModes = <String>{_supplyModeOptions.first};

    var draftService = _servicesOptions.first;
    var draftBookingType = _bookingTypeOptions.first;
    var draftShift = _shiftOptions.first;
    var draftArrival = _arrivalOptions.first;
    var draftHomeSize = _homeSizeOptions.first;
    var draftSupplyMode = _supplyModeOptions.first;

    var zoneCenter = initialZoneCenter;
    String selectedCategoryId =
        (categories
            .firstWhere(
              (entry) => entry['slug']?.toString() == 'house-help',
              orElse: () => categories.first,
            )['id']
            ?.toString() ??
        categories.first['id'].toString());

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var isSaving = false;
        String? errorText;
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            Widget multiSelectDropdown({
              required String label,
              required List<String> options,
              required String draftValue,
              required ValueChanged<String> onDraftChanged,
              required Set<String> selectedValues,
              required VoidCallback onAdd,
              required ValueChanged<String> onRemove,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: draftValue,
                          decoration: InputDecoration(labelText: label),
                          items: options
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry,
                                  child: Text(entry),
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
              final parsedPrice = double.tryParse(
                startingPriceController.text.trim(),
              );
              if (parsedPrice == null || parsedPrice <= 0) {
                setModalState(() {
                  errorText = 'Enter a valid starting price.';
                });
                return;
              }
              final parsedZoneRadius = double.tryParse(
                zoneRadiusController.text.trim(),
              );
              if (parsedZoneRadius == null ||
                  parsedZoneRadius <= 0 ||
                  parsedZoneRadius > 1) {
                setModalState(() {
                  errorText =
                      'Zone radius must be between 0.1 and 1 km for house-help matching.';
                });
                return;
              }
              if (selectedServices.isEmpty) {
                setModalState(() {
                  errorText = 'Select at least one service.';
                });
                return;
              }

              setModalState(() {
                isSaving = true;
                errorText = null;
              });

              try {
                await ApiClient.post(
                  '/pro/${widget.userId}/home-service-provider',
                  {
                    'name': nameController.text.trim(),
                    'title': titleController.text.trim(),
                    'categoryId': selectedCategoryId,
                    'startingPrice': parsedPrice,
                    'contactPhone': phoneController.text.trim(),
                    'services': selectedServices.toList(growable: false),
                    'serviceZone': {
                      'enabled': true,
                      'centerLatitude': zoneCenter.latitude,
                      'centerLongitude': zoneCenter.longitude,
                      'radiusKm': parsedZoneRadius,
                    },
                    'houseHelpConfig': {
                      'bookingTypes': selectedBookingTypes.toList(
                        growable: false,
                      ),
                      'shiftDurations': selectedShifts.toList(growable: false),
                      'homeSizes': selectedHomeSizes.toList(growable: false),
                      'arrivalTargets': selectedArrivals.toList(
                        growable: false,
                      ),
                      'supplyModes': selectedSupplyModes.toList(
                        growable: false,
                      ),
                    },
                  },
                );
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                await _refresh();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Home-service listing created and linked.'),
                  ),
                );
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
                      'Create Home-Service Listing',
                      style: Theme.of(modalContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: categories
                          .map((category) {
                            final id = category['id']?.toString() ?? '';
                            final label =
                                category['name']?.toString() ?? 'Category';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(label),
                            );
                          })
                          .toList(growable: false),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null || value.isEmpty) return;
                              setModalState(() => selectedCategoryId = value);
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
                    const SizedBox(height: 16),
                    multiSelectDropdown(
                      label: 'Services offered',
                      options: _servicesOptions,
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
                    const SizedBox(height: 12),
                    multiSelectDropdown(
                      label: 'Booking types',
                      options: _bookingTypeOptions,
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
                      options: _shiftOptions,
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
                      options: _arrivalOptions,
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
                      options: _homeSizeOptions,
                      draftValue: draftHomeSize,
                      onDraftChanged: (value) =>
                          setModalState(() => draftHomeSize = value),
                      selectedValues: selectedHomeSizes,
                      onAdd: () => setModalState(() {
                        selectedHomeSizes.add(draftHomeSize);
                      }),
                      onRemove: (value) =>
                          setModalState(() => selectedHomeSizes.remove(value)),
                    ),
                    const SizedBox(height: 12),
                    multiSelectDropdown(
                      label: 'Supply modes',
                      options: _supplyModeOptions,
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
                    TextFormField(
                      controller: zoneRadiusController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Zone radius (km, max 1)',
                      ),
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
  }

  List<_AvailabilityModuleTab> _resolveTabs(Map<String, dynamic> data) {
    final tabs = <_AvailabilityModuleTab>[];
    if (_supportsServices) {
      tabs.add(
        _AvailabilityModuleTab(
          module: 'services',
          label: 'Services',
          color: AppColors.homeServices,
          enabledLabel: 'Available for booking',
          disabledLabel: 'Temporarily unavailable',
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
          enabledLabel: 'Accepting laundry orders',
          disabledLabel: 'Laundry service paused',
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
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.businessName} Availability'),
        backgroundColor: AppColors.homeServices,
        foregroundColor: Colors.white,
        actions: [
          if (_supportsServices)
            IconButton(
              onPressed: _openCreateServiceListing,
              icon: const Icon(Icons.add_business_rounded),
              tooltip: 'Create listing',
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
              enabledLabel: tab.enabledLabel,
              disabledLabel: tab.disabledLabel,
              items: tab.items,
              busyIds: _busyIds,
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
                            enabledLabel: tab.enabledLabel,
                            disabledLabel: tab.disabledLabel,
                            items: tab.items,
                            busyIds: _busyIds,
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
  final String enabledLabel;
  final String disabledLabel;
  final List<Map<String, dynamic>> items;

  const _AvailabilityModuleTab({
    required this.module,
    required this.label,
    required this.color,
    required this.enabledLabel,
    required this.disabledLabel,
    required this.items,
  });
}

class _AvailabilityItemsList extends StatelessWidget {
  final Color color;
  final String enabledLabel;
  final String disabledLabel;
  final List<Map<String, dynamic>> items;
  final Set<String> busyIds;
  final Future<void> Function(String targetId, bool enabled) onToggle;

  const _AvailabilityItemsList({
    required this.color,
    required this.enabledLabel,
    required this.disabledLabel,
    required this.items,
    required this.busyIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No bound availability items found for this module.'),
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

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(Icons.tune, color: color),
          ),
          title: Text(
            item['name']?.toString() ?? 'Item',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(enabled ? enabledLabel : disabledLabel),
          trailing: Switch(
            value: enabled,
            onChanged: isBusy ? null : (value) => onToggle(id, value),
          ),
        );
      },
    );
  }
}
