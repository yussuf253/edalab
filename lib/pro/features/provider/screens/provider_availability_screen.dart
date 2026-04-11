import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';

class ProviderAvailabilityScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const ProviderAvailabilityScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<ProviderAvailabilityScreen> createState() =>
      _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState
    extends State<ProviderAvailabilityScreen> {
  late Future<Map<String, dynamic>> _availabilityFuture;
  final Set<String> _busyIds = <String>{};

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
                    'services': servicesController.text
                        .split(RegExp(r'[,\\n]'))
                        .map((entry) => entry.trim())
                        .where((entry) => entry.isNotEmpty)
                        .toList(growable: false),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.businessName} Availability'),
          backgroundColor: AppColors.homeServices,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _openCreateServiceListing,
              icon: const Icon(Icons.add_business_rounded),
              tooltip: 'Create listing',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Services'),
              Tab(text: 'Laundry'),
            ],
          ),
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
            return TabBarView(
              children: [
                _AvailabilityItemsList(
                  color: AppColors.homeServices,
                  enabledLabel: 'Available for booking',
                  disabledLabel: 'Temporarily unavailable',
                  items: (data['services'] as List<dynamic>? ?? const [])
                      .map((entry) => Map<String, dynamic>.from(entry as Map))
                      .toList(growable: false),
                  busyIds: _busyIds,
                  onToggle: (targetId, enabled) => _toggle(
                    module: 'services',
                    targetId: targetId,
                    enabled: enabled,
                  ),
                ),
                _AvailabilityItemsList(
                  color: AppColors.laundry,
                  enabledLabel: 'Accepting laundry orders',
                  disabledLabel: 'Laundry service paused',
                  items: (data['laundry'] as List<dynamic>? ?? const [])
                      .map((entry) => Map<String, dynamic>.from(entry as Map))
                      .toList(growable: false),
                  busyIds: _busyIds,
                  onToggle: (targetId, enabled) => _toggle(
                    module: 'laundry',
                    targetId: targetId,
                    enabled: enabled,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
