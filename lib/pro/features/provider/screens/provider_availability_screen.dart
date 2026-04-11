import 'package:flutter/material.dart';
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
  late Future<Map<String, dynamic>> _availabilityFuture;
  final Set<String> _busyIds = <String>{};

  bool get _supportsServices =>
      widget.activeModules.isEmpty ||
      widget.activeModules.contains(ProModule.services);
  bool get _supportsLaundry => widget.activeModules.contains(ProModule.laundry);

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
    final locationController = TextEditingController();
    final phoneController = TextEditingController();
    final responseTimeController = TextEditingController(text: '15 mins');
    final servicesController = TextEditingController(
      text: 'Room Cleaning, Floor Cleaning',
    );
    final bookingTypesController = TextEditingController(
      text: 'One-time job, Daily recurring, Weekly recurring',
    );
    final shiftDurationsController = TextEditingController(
      text: '2 hours, 4 hours, 8 hours',
    );
    final homeSizesController = TextEditingController(text: 'F2, F3, F4');
    final arrivalTargetsController = TextEditingController(
      text: 'Within 30 min, Scheduled slot',
    );
    final supplyModesController = TextEditingController(
      text: 'Provider supplies, Customer supplies',
    );
    final zoneLatitudeController = TextEditingController(text: '11.5886');
    final zoneLongitudeController = TextEditingController(text: '43.1457');
    final zoneRadiusController = TextEditingController(text: '8');
    var zoneEnabled = true;
    var zoneCenter = const LatLng(11.5886, 43.1457);
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
              final parsedZoneLatitude = double.tryParse(
                zoneLatitudeController.text.trim(),
              );
              final parsedZoneLongitude = double.tryParse(
                zoneLongitudeController.text.trim(),
              );
              final parsedZoneRadius = double.tryParse(
                zoneRadiusController.text.trim(),
              );
              if (zoneEnabled &&
                  (parsedZoneLatitude == null ||
                      parsedZoneLongitude == null ||
                      parsedZoneRadius == null ||
                      parsedZoneRadius <= 0)) {
                setModalState(() {
                  errorText =
                      'Set a valid zone center (latitude/longitude) and radius.';
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
                    'location': locationController.text.trim(),
                    'contactPhone': phoneController.text.trim(),
                    'responseTime': responseTimeController.text.trim(),
                    'services': _splitValues(servicesController.text),
                    'serviceZone': {
                      'enabled': zoneEnabled,
                      'centerLatitude': zoneEnabled ? parsedZoneLatitude : null,
                      'centerLongitude': zoneEnabled
                          ? parsedZoneLongitude
                          : null,
                      'radiusKm': zoneEnabled ? parsedZoneRadius : 8,
                    },
                    'houseHelpConfig': {
                      'bookingTypes': _splitValues(bookingTypesController.text),
                      'shiftDurations': _splitValues(
                        shiftDurationsController.text,
                      ),
                      'homeSizes': _splitValues(homeSizesController.text),
                      'arrivalTargets': _splitValues(
                        arrivalTargetsController.text,
                      ),
                      'supplyModes': _splitValues(supplyModesController.text),
                    },
                  },
                );
                if (!mounted) return;
                if (!sheetContext.mounted) return;
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
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Service area / activity zone',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: responseTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Response time',
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: zoneEnabled,
                      title: const Text('Enable activity zone matching'),
                      subtitle: const Text(
                        'Only requests inside this zone appear for acceptance.',
                      ),
                      onChanged: isSaving
                          ? null
                          : (value) => setModalState(() => zoneEnabled = value),
                    ),
                    const SizedBox(height: 8),
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
                            setModalState(() {
                              zoneCenter = point;
                              zoneLatitudeController.text = point.latitude
                                  .toStringAsFixed(6);
                              zoneLongitudeController.text = point.longitude
                                  .toStringAsFixed(6);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: zoneLatitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Zone latitude',
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null) return;
                              setModalState(() {
                                zoneCenter = LatLng(
                                  parsed,
                                  zoneCenter.longitude,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: zoneLongitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Zone longitude',
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null) return;
                              setModalState(() {
                                zoneCenter = LatLng(
                                  zoneCenter.latitude,
                                  parsed,
                                );
                              });
                            },
                          ),
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
                        labelText: 'Zone radius (km)',
                      ),
                    ),
                    const SizedBox(height: 20),
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
