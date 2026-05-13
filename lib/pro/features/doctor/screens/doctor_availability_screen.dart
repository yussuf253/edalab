import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const DoctorAvailabilityScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  late Future<List<Map<String, dynamic>>> _availabilityFuture;
  final Set<String> _busyIds = <String>{};

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _availabilityFuture = _loadAvailability();
  }

  Future<List<Map<String, dynamic>>> _loadAvailability() async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/doctor-availability',
      forceRefresh: true,
    );
    return (response as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    final future = _loadAvailability();
    setState(() {
      _availabilityFuture = future;
    });
    await future;
  }

  Future<void> _toggleDoctor({
    required String doctorId,
    required bool enabled,
  }) async {
    setState(() => _busyIds.add(doctorId));
    try {
      await ApiClient.post('/pro/${widget.userId}/doctor-availability', {
        'doctorId': doctorId,
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
        setState(() => _busyIds.remove(doctorId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.doctorAvailabilityTitle(widget.businessName)),
        backgroundColor: AppColors.doctor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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

          final items = snapshot.data ?? const <Map<String, dynamic>>[];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noDoctorProfilesFound),
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
              final isBusy = _busyIds.contains(id);

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.doctor.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.local_hospital,
                    color: AppColors.doctor,
                  ),
                ),
                title: Text(
                  item['name']?.toString() ?? l10n.doctorLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${item['specialty']?.toString() ?? ''}${(item['specialty']?.toString() ?? '').isEmpty ? '' : ' • '}${enabled ? l10n.availableNow : l10n.unavailable}',
                ),
                trailing: Switch(
                  value: enabled,
                  onChanged: isBusy
                      ? null
                      : (value) => _toggleDoctor(doctorId: id, enabled: value),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
