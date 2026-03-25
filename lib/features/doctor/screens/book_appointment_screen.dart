import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/auth_gate.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String doctorId;
  const BookAppointmentScreen({super.key, required this.doctorId});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  int _selectedDate = 1;
  int _selectedTime = 2;
  int _selectedType = 0;
  DoctorModel? _doctor;
  bool _isLoading = true;

  final _dates = [
    ('Mon', '22'),
    ('Tue', '23'),
    ('Wed', '24'),
    ('Thu', '25'),
    ('Fri', '26'),
    ('Sat', '27'),
  ];
  final _times = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '02:00',
    '02:30',
    '03:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    try {
      final response = await ApiClient.get(
        '/catalog/doctors/${widget.doctorId}',
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() {
        _doctor = DoctorModel.fromApi(
          Map<String, dynamic>.from(response as Map),
        );
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _contactProvider() async {
    final doctor = _doctor;
    if (doctor == null) return;
    final whatsApp = doctor.contactWhatsApp?.replaceAll(RegExp(r'[^0-9+]'), '');
    final phone = doctor.contactPhone?.replaceAll(RegExp(r'[^0-9+]'), '');

    Uri? uri;
    if (whatsApp != null && whatsApp.isNotEmpty) {
      uri = Uri.parse('https://wa.me/${whatsApp.replaceFirst('+', '')}');
    } else if (phone != null && phone.isNotEmpty) {
      uri = Uri(scheme: 'tel', path: phone);
    }

    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No contact information available.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the contact action.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = _doctor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          doctor == null || _isLoading
              ? 'Loading Profile'
              : doctor.usesDirectContactOnly
              ? 'Contact Doctor'
              : doctor.isDoctorProvider
              ? 'Book Appointment'
              : 'Book Care Service',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading || doctor == null)
              const AppShimmer(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 84,
                    radius: 16,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.doctorBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        doctor.isHomeCareProvider
                            ? Icons.health_and_safety_rounded
                            : Icons.person_rounded,
                        color: AppColors.doctor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctor.name, style: AppTextStyles.labelLarge),
                          Text(doctor.specialty, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (!_isLoading && doctor != null) const SizedBox(height: 24),
            if (!_isLoading &&
                doctor != null &&
                doctor.usesDirectContactOnly) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Direct Doctor Contact', style: AppTextStyles.h4),
                    const SizedBox(height: 8),
                    Text(
                      'This doctor is not signed up in the app yet. Contact them directly to agree on consultation time and details.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: doctor.services
                          .map(
                            (service) => _ServiceTag(
                              label: service,
                              color: AppColors.doctor,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    _ContactInfoRow(
                      icon: Icons.call_rounded,
                      label: 'Phone',
                      value: doctor.contactPhone ?? 'Not available',
                    ),
                    const SizedBox(height: 10),
                    _ContactInfoRow(
                      icon: Icons.chat_rounded,
                      label: 'WhatsApp',
                      value: doctor.contactWhatsApp ?? 'Not available',
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: 'Contact Directly',
                      color: AppColors.doctor,
                      onPressed: _contactProvider,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.doctorBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _Row('Provider', doctor.name),
                    _Row('Service', doctor.specialty),
                    _Row(
                      'Mode',
                      doctor.careModes.isNotEmpty
                          ? doctor.careModes.first
                          : 'Home Visit',
                    ),
                    _Row(
                      'Consultation Fee',
                      '\$${doctor.consultationFee.toInt()}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else if (!_isLoading && doctor != null) ...[
              Text(
                doctor.isDoctorProvider ? 'Appointment Type' : 'Service Mode',
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TypeCard(
                    doctor.isDoctorProvider
                        ? Icons.videocam_rounded
                        : Icons.home_rounded,
                    doctor.isDoctorProvider ? 'Video Call' : 'Home Visit',
                    _selectedType == 0,
                    () => setState(() => _selectedType = 0),
                  ),
                  const SizedBox(width: 12),
                  _TypeCard(
                    Icons.chat_rounded,
                    doctor.isDoctorProvider ? 'Chat' : 'Phone Advice',
                    _selectedType == 1,
                    () => setState(() => _selectedType = 1),
                  ),
                  const SizedBox(width: 12),
                  _TypeCard(
                    doctor.isDoctorProvider
                        ? Icons.location_on_rounded
                        : Icons.videocam_rounded,
                    doctor.isDoctorProvider ? 'In Person' : 'Video Support',
                    _selectedType == 2,
                    () => setState(() => _selectedType = 2),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Select Date', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final selected = _selectedDate == index;
                    final date = _dates[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.doctor : AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? null
                              : Border.all(color: AppColors.lightGrey),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              date.$1,
                              style: AppTextStyles.caption.copyWith(
                                color: selected
                                    ? Colors.white60
                                    : AppColors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.$2,
                              style: AppTextStyles.h4.copyWith(
                                color: selected
                                    ? AppColors.white
                                    : AppColors.dark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text('Select Time', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_times.length, (index) {
                  final selected = _selectedTime == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTime = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.doctor : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? null
                            : Border.all(color: AppColors.lightGrey),
                      ),
                      child: Text(
                        _times[index],
                        style: AppTextStyles.labelMedium.copyWith(
                          color: selected ? AppColors.white : AppColors.dark,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Text('Notes (optional)', style: AppTextStyles.h4),
              const SizedBox(height: 12),
              TextFormField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe your symptoms or reason for visit...',
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.doctorBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _Row(
                      doctor.isDoctorProvider ? 'Doctor' : 'Professional',
                      doctor.name,
                    ),
                    _Row(
                      'Date',
                      '${_dates[_selectedDate].$1}, Mar ${_dates[_selectedDate].$2}, 2026',
                    ),
                    _Row('Time', '${_times[_selectedTime]} AM'),
                    _Row(
                      doctor.isDoctorProvider ? 'Type' : 'Service',
                      doctor.isDoctorProvider
                          ? ['Video Call', 'Chat', 'In Person'][_selectedType]
                          : [
                              'Home Visit',
                              'Phone Advice',
                              'Video Support',
                            ][_selectedType],
                    ),
                    const Divider(height: 20),
                    _Row(
                      'Fee',
                      '\$${doctor.consultationFee.toInt()}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: doctor.isDoctorProvider
                    ? 'Confirm Booking'
                    : 'Book Care Service',
                color: AppColors.doctor,
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final allowed = await requireLoggedIn(
                    context,
                    message: 'Please log in to confirm your appointment.',
                  );
                  if (!context.mounted || !allowed) return;
                  try {
                    final selectedDate = DateTime.utc(
                      2026,
                      3,
                      int.parse(_dates[_selectedDate].$2),
                    );
                    await ApiClient.post('/appointments', {
                      'userId': auth.user!.id,
                      'doctorId': doctor.id,
                      'date': selectedDate.toIso8601String(),
                      'timeSlot': '${_times[_selectedTime]} AM',
                      'type': doctor.isDoctorProvider
                          ? ['video', 'chat', 'in_person'][_selectedType]
                          : [
                              'home_visit',
                              'phone_advice',
                              'video_support',
                            ][_selectedType],
                      'notes': doctor.isDoctorProvider
                          ? 'Doctor appointment booked via EdaLab Super App'
                          : 'Care service booked via EdaLab Super App',
                    });
                    if (!context.mounted) return;

                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: AppColors.successLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.success,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              doctor.isDoctorProvider
                                  ? 'Booking Confirmed!'
                                  : 'Care Service Booked!',
                              style: AppTextStyles.h3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your appointment has been scheduled successfully.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            AppButton(
                              text: 'Done',
                              color: AppColors.doctor,
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                context.go('/');
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to book: $error'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard(this.icon, this.label, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.doctor : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: selected ? null : Border.all(color: AppColors.lightGrey),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.white : AppColors.doctor,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: selected ? AppColors.white : AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? AppTextStyles.labelLarge
                : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
          Text(
            value,
            style: bold
                ? AppTextStyles.priceSmall.copyWith(color: AppColors.doctor)
                : AppTextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ServiceTag extends StatelessWidget {
  final String label;
  final Color color;

  const _ServiceTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(color: color),
      ),
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.doctorBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppColors.doctor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      ],
    );
  }
}
