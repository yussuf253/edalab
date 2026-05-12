import 'dart:typed_data';

import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/media_upload_service.dart';

class DoctorScheduleSettingsScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const DoctorScheduleSettingsScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<DoctorScheduleSettingsScreen> createState() =>
      _DoctorScheduleSettingsScreenState();
}

class _DoctorScheduleSettingsScreenState
    extends State<DoctorScheduleSettingsScreen> {
  List<String> get _modeOptions => <String>[
    l10n.clinicVisit,
    l10n.videoConsultation,
    l10n.phoneAdvice,
    l10n.homeVisit,
  ];

  late Future<List<Map<String, dynamic>>> _settingsFuture;
  final Set<String> _busyIds = <String>{};

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  Future<List<Map<String, dynamic>>> _loadSettings() async {
    final response = await ApiClient.get(
      '/pro/${widget.userId}/doctor-settings',
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
    required String doctorId,
    required String imageUrl,
    required String location,
    required String contactPhone,
    required String contactWhatsApp,
    required List<String> careModes,
    required Map<String, String> workingHours,
  }) async {
    setState(() => _busyIds.add(doctorId));
    try {
      await ApiClient.post('/pro/${widget.userId}/doctor-settings', {
        'doctorId': doctorId,
        'imageUrl': imageUrl,
        'location': location,
        'contactPhone': contactPhone,
        'contactWhatsApp': contactWhatsApp,
        'careModes': careModes,
        'workingHours': workingHours,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.doctorSettingsUpdated)));
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

  Future<void> _openEditor(Map<String, dynamic> item) async {
    final doctorId = item['id']?.toString() ?? '';
    final locationController = TextEditingController(
      text: item['location']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: item['contactPhone']?.toString() ?? '',
    );
    final whatsappController = TextEditingController(
      text: item['contactWhatsApp']?.toString() ?? '',
    );
    final workingHours = Map<String, String>.from(
      (item['workingHours'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          ) ??
          const <String, String>{},
    );
    final selectedModes = <String>{
      ...(item['careModes'] as List<dynamic>? ?? const <dynamic>[]).map(
        (entry) => entry.toString(),
      ),
    };
    var selectedImageUrl = item['imageUrl']?.toString().trim() ?? '';
    Uint8List? selectedImageBytes;
    var isUploadingImage = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget scheduleField({required String key, required String label}) {
              return TextFormField(
                initialValue: workingHours[key] ?? '',
                decoration: InputDecoration(labelText: label),
                onChanged: (value) => workingHours[key] = value,
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
                      item['name']?.toString() ?? l10n.doctorLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((item['specialty']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item['specialty']!.toString()),
                    ],
                    const SizedBox(height: 14),
                    Center(
                      child: Column(
                        children: [
                          _DoctorAvatar(
                            imageUrl: selectedImageUrl,
                            pickedImageBytes: selectedImageBytes,
                            size: 88,
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: isUploadingImage
                                ? null
                                : () async {
                                    final picker = ImagePicker();
                                    final file = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1800,
                                      imageQuality: 88,
                                    );
                                    if (file == null) return;

                                    final bytes = await file.readAsBytes();
                                    if (!mounted) return;
                                    setModalState(() {
                                      selectedImageBytes = bytes;
                                      isUploadingImage = true;
                                    });

                                    try {
                                      final uploaded =
                                          await MediaUploadService.uploadImage(
                                            scope: MediaUploadScope.doctor,
                                            ownerId: widget.userId,
                                            fileName: file.name,
                                            mimeType: file.mimeType,
                                            bytes: bytes,
                                          );
                                      if (!mounted) return;
                                      setModalState(() {
                                        selectedImageUrl = uploaded.url;
                                      });
                                    } catch (error) {
                                      if (!mounted || !sheetContext.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(
                                        sheetContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ApiClient.userFacingError(error),
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setModalState(
                                          () => isUploadingImage = false,
                                        );
                                      }
                                    }
                                  },
                            icon: isUploadingImage
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.photo_library_outlined),
                            label: Text(
                              isUploadingImage
                                  ? l10n.uploadingImage
                                  : l10n.uploadDoctorPhoto,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(labelText: l10n.clinicArea),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: l10n.phone),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: whatsappController,
                      decoration: InputDecoration(labelText: l10n.whatsapp),
                    ),
                    const SizedBox(height: 20),
                    _DoctorSettingsSectionLabel(l10n.consultationModes),
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
                    _DoctorSettingsSectionLabel(l10n.workingHours),
                    const SizedBox(height: 8),
                    scheduleField(key: 'monday', label: l10n.monday),
                    const SizedBox(height: 12),
                    scheduleField(key: 'tuesday', label: l10n.tuesday),
                    const SizedBox(height: 12),
                    scheduleField(key: 'wednesday', label: l10n.wednesday),
                    const SizedBox(height: 12),
                    scheduleField(key: 'thursday', label: l10n.thursday),
                    const SizedBox(height: 12),
                    scheduleField(key: 'friday', label: l10n.friday),
                    const SizedBox(height: 12),
                    scheduleField(key: 'saturday', label: l10n.saturday),
                    const SizedBox(height: 12),
                    scheduleField(key: 'sunday', label: l10n.sunday),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busyIds.contains(doctorId)
                            ? null
                            : () async {
                                if (isUploadingImage) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.waitForImageUpload),
                                    ),
                                  );
                                  return;
                                }
                                Navigator.of(sheetContext).pop();
                                await _saveSettings(
                                  doctorId: doctorId,
                                  imageUrl: selectedImageUrl,
                                  location: locationController.text.trim(),
                                  contactPhone: phoneController.text.trim(),
                                  contactWhatsApp: whatsappController.text
                                      .trim(),
                                  careModes: selectedModes.toList(
                                    growable: false,
                                  ),
                                  workingHours: {
                                    'monday': (workingHours['monday'] ?? '')
                                        .trim(),
                                    'tuesday': (workingHours['tuesday'] ?? '')
                                        .trim(),
                                    'wednesday':
                                        (workingHours['wednesday'] ?? '')
                                            .trim(),
                                    'thursday': (workingHours['thursday'] ?? '')
                                        .trim(),
                                    'friday': (workingHours['friday'] ?? '')
                                        .trim(),
                                    'saturday': (workingHours['saturday'] ?? '')
                                        .trim(),
                                    'sunday': (workingHours['sunday'] ?? '')
                                        .trim(),
                                  },
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.doctor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _busyIds.contains(doctorId)
                              ? l10n.saving
                              : l10n.saveSettings,
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
        title: Text(l10n.doctorSchedulingTitle(widget.businessName)),
        backgroundColor: AppColors.doctor,
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
                child: Text(l10n.noDoctorsFound),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final doctorId = item['id']?.toString() ?? '';
              final workingHours = Map<String, dynamic>.from(
                (item['workingHours'] as Map?) ?? const <String, dynamic>{},
              );
              final careModes =
                  (item['careModes'] as List<dynamic>? ?? const <dynamic>[])
                      .map((entry) => entry.toString())
                      .toList(growable: false);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _DoctorAvatar(
                            imageUrl: item['imageUrl']?.toString().trim() ?? '',
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name']?.toString() ?? l10n.doctorLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if ((item['specialty']?.toString() ?? '')
                                    .isNotEmpty)
                                  Text(item['specialty']!.toString()),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _busyIds.contains(doctorId)
                                ? null
                                : () => _openEditor(item),
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l10n.edit),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _DoctorSettingsInfoRow(
                        label: l10n.location,
                        value: item['location']?.toString() ?? l10n.notSet,
                      ),
                      _DoctorSettingsInfoRow(
                        label: l10n.phone,
                        value: item['contactPhone']?.toString() ?? l10n.notSet,
                      ),
                      _DoctorSettingsInfoRow(
                        label: l10n.whatsapp,
                        value:
                            item['contactWhatsApp']?.toString() ?? l10n.notSet,
                      ),
                      _DoctorSettingsInfoRow(
                        label: l10n.modes,
                        value: careModes.isEmpty
                            ? l10n.noModesConfigured
                            : careModes.join(', '),
                      ),
                      _DoctorSettingsInfoRow(
                        label: l10n.monFri,
                        value:
                            workingHours['monday']?.toString() ?? l10n.notSet,
                      ),
                      _DoctorSettingsInfoRow(
                        label: l10n.saturday,
                        value:
                            workingHours['saturday']?.toString() ?? l10n.notSet,
                      ),
                      _DoctorSettingsInfoRow(
                        label: l10n.sunday,
                        value:
                            workingHours['sunday']?.toString() ?? l10n.notSet,
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

class _DoctorAvatar extends StatelessWidget {
  final String imageUrl;
  final Uint8List? pickedImageBytes;
  final double size;

  const _DoctorAvatar({
    required this.imageUrl,
    this.pickedImageBytes,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final hasImageUrl = imageUrl.trim().isNotEmpty;
    final radius = size / 2;
    if (pickedImageBytes != null) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(pickedImageBytes!),
      );
    }
    if (hasImageUrl) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.doctor.withValues(alpha: 0.1),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackIcon(radius),
          ),
        ),
      );
    }
    return _fallbackIcon(radius);
  }

  Widget _fallbackIcon(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.doctor.withValues(alpha: 0.12),
      child: Icon(
        Icons.local_hospital_outlined,
        color: AppColors.doctor,
        size: radius,
      ),
    );
  }
}

class _DoctorSettingsSectionLabel extends StatelessWidget {
  final String text;

  const _DoctorSettingsSectionLabel(this.text);

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

class _DoctorSettingsInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DoctorSettingsInfoRow({required this.label, required this.value});

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
