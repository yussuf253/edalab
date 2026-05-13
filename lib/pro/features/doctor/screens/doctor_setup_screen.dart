import '/pro/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/app_button.dart';

import '../../../core/router/pro_route_paths.dart';
import '../../../core/constants/pro_design_system.dart';

class DoctorSetupScreen extends StatefulWidget {
  final String userId;
  final String businessName;

  const DoctorSetupScreen({
    super.key,
    required this.userId,
    required this.businessName,
  });

  @override
  State<DoctorSetupScreen> createState() => _DoctorSetupScreenState();
}

class _DoctorSetupScreenState extends State<DoctorSetupScreen> {
  List<String> get _specialtyOptions => [
    l10n.generalPractice,
    l10n.cardiology,
    l10n.dermatology,
    l10n.neurology,
    l10n.orthopedics,
    l10n.pediatrics,
    l10n.homeNursing,
    l10n.physiotherapy,
    l10n.mentalTherapy,
    l10n.dentalCare,
    l10n.optometry,
    l10n.other,
  ];

  List<String> get _serviceOptions => [
    l10n.generalCheckup,
    l10n.ecg,
    l10n.bloodTest,
    l10n.vaccination,
    l10n.woundDressing,
    l10n.injection,
    l10n.postSurgeryRehab,
    l10n.physicalTherapy,
    l10n.psychologicalCounseling,
    l10n.emergencyCare,
    l10n.routineMonitoring,
    l10n.prescriptionRefill,
  ];

  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedModes = {};
  final Set<String> _selectedServices = {};
  String? _selectedSpecialty;
  bool _isLoading = false;
  String? _errorMessage;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecialty == null) {
      setState(() => _errorMessage = l10n.pleaseSelectSpecialty);
      return;
    }
    if (_selectedServices.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseSelectService);
      return;
    }
    if (_selectedModes.isEmpty) {
      setState(() => _errorMessage = l10n.pleaseSelectCareMode);
      return;
    }

    final needsLocation =
        _selectedModes.contains(l10n.clinicVisit) ||
        _selectedModes.contains(l10n.homeVisit);
    if (needsLocation && _locationController.text.trim().isEmpty) {
      setState(() => _errorMessage = l10n.pleaseProvideLocation);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiClient.post('/pro/${widget.userId}/doctor-settings', {
        'doctorId': const Uuid().v4(),
        'name': widget.businessName,
        'imageUrl': '',
        'location': _locationController.text.trim(),
        'contactPhone': '',
        'contactWhatsApp': '',
        'specialty': _selectedSpecialty ?? 'General Practice',
        'services': _selectedServices.toList(growable: false),
        'careModes': _selectedModes.toList(growable: false),
        'workingHours': {
          'monday': '9:00 AM - 5:00 PM',
          'tuesday': '9:00 AM - 5:00 PM',
          'wednesday': '9:00 AM - 5:00 PM',
          'thursday': '9:00 AM - 5:00 PM',
          'friday': '9:00 AM - 5:00 PM',
          'saturday': l10n.closed,
          'sunday': l10n.closed,
        },
      });

      if (!mounted) return;
      context.go(ProRoutePaths.doctorHome);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildModeCheckbox(
    String title,
    String subtitle,
    String modeValue,
    IconData icon,
  ) {
    final isSelected = _selectedModes.contains(modeValue);
    return Card(
      margin: const EdgeInsets.only(bottom: ProDesignSystem.spacing12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusMedium),
        side: BorderSide(
          color: isSelected ? AppColors.doctor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: 0,
      child: CheckboxListTile(
        value: isSelected,
        activeColor: AppColors.doctor,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        secondary: Icon(
          icon,
          color: isSelected ? AppColors.doctor : Colors.grey.shade600,
          size: 32,
        ),
        onChanged: (val) {
          setState(() {
            if (val == true) {
              _selectedModes.add(modeValue);
            } else {
              _selectedModes.remove(modeValue);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.setupPractice),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ProDesignSystem.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.welcomeDoctor(widget.businessName),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.doctor,
                ),
              ),
              const SizedBox(height: ProDesignSystem.spacing8),
              Text(l10n.doctorOnboardingSubtitle),
              const SizedBox(height: ProDesignSystem.spacing24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.basicInfo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing12),
                    DropdownButtonFormField<String>(
                      value: _selectedSpecialty,
                      decoration: InputDecoration(
                        labelText: l10n.specialty,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            ProDesignSystem.radiusSmall,
                          ),
                        ),
                      ),
                      items: _specialtyOptions.map((specialty) {
                        return DropdownMenuItem(
                          value: specialty,
                          child: Text(specialty),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSpecialty = val),
                      validator: (val) =>
                          val == null ? l10n.requiredLabel : null,
                    ),
                    const SizedBox(height: ProDesignSystem.spacing16),
                    Text(
                      l10n.servicesOffered,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceOptions.map((service) {
                        final isSelected = _selectedServices.contains(service);
                        return FilterChip(
                          label: Text(service),
                          selected: isSelected,
                          selectedColor: AppColors.doctor.withValues(
                            alpha: 0.15,
                          ),
                          checkmarkColor: AppColors.doctor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.doctor
                                : Colors.grey.shade800,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.doctor
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServices.add(service);
                              } else {
                                _selectedServices.remove(service);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing24),
                    if (_errorMessage != null) ...[
                      ModernInfoBox(
                        message: _errorMessage!,
                        icon: Icons.error_outline,
                        backgroundColor: const Color(0xFFFFF5F5),
                        textColor: const Color(0xFFDC2626),
                        borderColor: const Color(0xFFF87171),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing20),
                    ],
                    Text(
                      l10n.careModes,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing12),
                    _buildModeCheckbox(
                      l10n.inPersonClinicVisit,
                      l10n.clinicVisitSubtitle,
                      l10n.clinicVisit,
                      Icons.local_hospital_outlined,
                    ),
                    _buildModeCheckbox(
                      l10n.videoConsultation,
                      l10n.videoConsultationSubtitle,
                      l10n.videoConsultation,
                      Icons.video_camera_front_outlined,
                    ),
                    _buildModeCheckbox(
                      l10n.chatPhoneAdvice,
                      l10n.chatPhoneSubtitle,
                      l10n.phoneAdvice,
                      Icons.chat_outlined,
                    ),
                    _buildModeCheckbox(
                      l10n.homeCareServices,
                      l10n.homeCareSubtitle,
                      l10n.homeVisit,
                      Icons.home_repair_service_outlined,
                    ),
                    const SizedBox(height: ProDesignSystem.spacing24),
                    if (_selectedModes.contains(l10n.clinicVisit) ||
                        _selectedModes.contains(l10n.homeVisit)) ...[
                      Text(
                        l10n.serviceAreaClinicLocation,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing12),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: l10n.clinicLocationHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              ProDesignSystem.radiusSmall,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing32),
                    ],
                    AppButton(
                      text: l10n.completeSetup,
                      isLoading: _isLoading,
                      onPressed: _submit,
                      color: AppColors.doctor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
