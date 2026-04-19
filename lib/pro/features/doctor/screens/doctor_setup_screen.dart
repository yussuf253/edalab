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
  final _locationController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _servicesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _selectedModes = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _locationController.dispose();
    _specialtyController.dispose();
    _servicesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedModes.isEmpty) {
      setState(() => _errorMessage = 'Please select at least one care mode.');
      return;
    }

    final needsLocation = _selectedModes.contains('Clinic Visit') || _selectedModes.contains('Home Visit');
    if (needsLocation && _locationController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide your base clinic or service area location.');
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
        'specialty': _specialtyController.text.trim(),
        'services': _servicesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'careModes': _selectedModes.toList(growable: false),
        'workingHours': {
          'monday': '9:00 AM - 5:00 PM',
          'tuesday': '9:00 AM - 5:00 PM',
          'wednesday': '9:00 AM - 5:00 PM',
          'thursday': '9:00 AM - 5:00 PM',
          'friday': '9:00 AM - 5:00 PM',
          'saturday': 'Closed',
          'sunday': 'Closed',
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

  Widget _buildModeCheckbox(String title, String subtitle, String modeValue, IconData icon) {
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
        secondary: Icon(icon, color: isSelected ? AppColors.doctor : Colors.grey.shade600, size: 32),
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
        title: const Text('Setup Practice'),
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
                'Welcome, Dr. ${widget.businessName}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.doctor,
                ),
              ),
              const SizedBox(height: ProDesignSystem.spacing8),
              const Text(
                "Let's configure how you will provide care and consult with patients on EdaLab.",
              ),
              const SizedBox(height: ProDesignSystem.spacing24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Basic Info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing12),
                    TextFormField(
                      controller: _specialtyController,
                      decoration: InputDecoration(
                        labelText: 'Specialty (e.g. General Practice, Cardiology)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ProDesignSystem.radiusSmall),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: ProDesignSystem.spacing16),
                    TextFormField(
                      controller: _servicesController,
                      decoration: InputDecoration(
                        labelText: 'Services Offered (comma-separated)',
                        hintText: 'e.g. Consultations, Checkups, ECG',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ProDesignSystem.radiusSmall),
                        ),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
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
                'Care Modes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: ProDesignSystem.spacing12),
              _buildModeCheckbox(
                'In-Person Clinic Visit',
                'Patients book appointments and visit your physical clinic.',
                'Clinic Visit',
                Icons.local_hospital_outlined,
              ),
              _buildModeCheckbox(
                'Video Consultation',
                'Consult with patients remotely via in-app video calls.',
                'Video Consultation',
                Icons.video_camera_front_outlined,
              ),
              _buildModeCheckbox(
                'Chat & Phone Advice',
                'Provide medical advice through secure messaging and calls.',
                'Phone Advice',
                Icons.chat_outlined,
              ),
              _buildModeCheckbox(
                'Home Care Services',
                'You or your staff will visit the patient at their home.',
                'Home Visit',
                Icons.home_repair_service_outlined,
              ),
              const SizedBox(height: ProDesignSystem.spacing24),
              if (_selectedModes.contains('Clinic Visit') || _selectedModes.contains('Home Visit')) ...[
                Text(
                  'Service Area / Clinic Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing12),
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Downtown Medical Center, Nairobi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ProDesignSystem.radiusSmall),
                    ),
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing32),
              ],
              AppButton(
                text: 'Complete Setup',
                isLoading: _isLoading,
                onPressed: _submit,
                color: AppColors.doctor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
