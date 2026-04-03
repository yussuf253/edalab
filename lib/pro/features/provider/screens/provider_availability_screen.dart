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
  State<ProviderAvailabilityScreen> createState() => _ProviderAvailabilityScreenState();
}

class _ProviderAvailabilityScreenState extends State<ProviderAvailabilityScreen> {
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
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(targetId));
      }
    }
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
                  child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')),
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
                  onToggle: (targetId, enabled) =>
                      _toggle(module: 'services', targetId: targetId, enabled: enabled),
                ),
                _AvailabilityItemsList(
                  color: AppColors.laundry,
                  enabledLabel: 'Accepting laundry orders',
                  disabledLabel: 'Laundry service paused',
                  items: (data['laundry'] as List<dynamic>? ?? const [])
                      .map((entry) => Map<String, dynamic>.from(entry as Map))
                      .toList(growable: false),
                  busyIds: _busyIds,
                  onToggle: (targetId, enabled) =>
                      _toggle(module: 'laundry', targetId: targetId, enabled: enabled),
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
