import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
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
  int _selectedCarePlan = 0;
  int _selectedCareGoal = 0;
  int _selectedArrival = 0;
  DoctorModel? _doctor;
  bool _isLoading = true;
  final TextEditingController _notesController = TextEditingController();

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
    final l10n = context.l10n;
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
        SnackBar(content: Text(l10n.t('doctor_booking.no_contact'))),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('doctor_booking.cannot_open_contact'))),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final doctor = _doctor;
    final homeCarePlanOptions = [
      l10n.t('doctor_booking.home_care_plan_one_time'),
      l10n.t('doctor_booking.home_care_plan_daily'),
      l10n.t('doctor_booking.home_care_plan_weekly'),
    ];
    final homeCareGoalOptions = [
      l10n.t('doctor_booking.home_care_goal_general'),
      l10n.t('doctor_booking.home_care_goal_elderly'),
      l10n.t('doctor_booking.home_care_goal_recovery'),
    ];
    final homeCareArrivalOptions = [
      l10n.t('doctor_booking.home_care_arrival_urgent'),
      l10n.t('doctor_booking.home_care_arrival_today'),
      l10n.t('doctor_booking.home_care_arrival_scheduled'),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          doctor == null || _isLoading
              ? l10n.t('doctor_booking.loading')
              : doctor.usesDirectContactOnly
              ? l10n.t('doctor_booking.contact_doctor')
              : doctor.isDoctorProvider
              ? l10n.t('doctor_booking.book_appointment')
              : l10n.t('doctor_booking.book_care_service'),
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
                    Text(
                      l10n.t('doctor_booking.direct_contact'),
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.t('doctor_booking.direct_contact_subtitle'),
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
                      label: l10n.t('doctor_booking.phone'),
                      value:
                          doctor.contactPhone ??
                          l10n.t('doctor_booking.not_available'),
                    ),
                    const SizedBox(height: 10),
                    _ContactInfoRow(
                      icon: Icons.chat_rounded,
                      label: l10n.t('doctor_booking.whatsapp'),
                      value:
                          doctor.contactWhatsApp ??
                          l10n.t('doctor_booking.not_available'),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      text: l10n.t('doctor_booking.contact_directly'),
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
                    _Row(l10n.t('doctor_booking.provider'), doctor.name),
                    _Row(l10n.t('doctor_booking.service'), doctor.specialty),
                    _Row(
                      l10n.t('doctor_booking.mode'),
                      doctor.careModes.isNotEmpty
                          ? doctor.careModes.first
                          : l10n.t('doctor_booking.home_visit'),
                    ),
                    _Row(
                      l10n.t('doctor_booking.consultation_fee'),
                      '\$${doctor.consultationFee.toInt()}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else if (!_isLoading && doctor != null) ...[
              Text(
                doctor.isDoctorProvider
                    ? l10n.t('doctor_booking.appointment_type')
                    : l10n.t('doctor_booking.service_mode'),
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _TypeCard(
                    doctor.isDoctorProvider
                        ? Icons.videocam_rounded
                        : Icons.home_rounded,
                    doctor.isDoctorProvider
                        ? l10n.t('doctor_booking.video_call')
                        : l10n.t('doctor_booking.home_visit'),
                    _selectedType == 0,
                    () => setState(() => _selectedType = 0),
                  ),
                  const SizedBox(width: 12),
                  _TypeCard(
                    Icons.chat_rounded,
                    doctor.isDoctorProvider
                        ? l10n.t('doctor_booking.chat')
                        : l10n.t('doctor_booking.phone_advice'),
                    _selectedType == 1,
                    () => setState(() => _selectedType = 1),
                  ),
                  const SizedBox(width: 12),
                  _TypeCard(
                    doctor.isDoctorProvider
                        ? Icons.location_on_rounded
                        : Icons.videocam_rounded,
                    doctor.isDoctorProvider
                        ? l10n.t('doctor_booking.in_person')
                        : l10n.t('doctor_booking.video_support'),
                    _selectedType == 2,
                    () => setState(() => _selectedType = 2),
                  ),
                ],
              ),
              if (!doctor.isDoctorProvider) ...[
                const SizedBox(height: 24),
                Text(
                  l10n.t('doctor_booking.home_care_specifics'),
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('doctor_booking.home_care_plan_label'),
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(homeCarePlanOptions.length, (index) {
                    return _OptionChip(
                      label: homeCarePlanOptions[index],
                      selected: _selectedCarePlan == index,
                      onTap: () => setState(() => _selectedCarePlan = index),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('doctor_booking.home_care_goal_label'),
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(homeCareGoalOptions.length, (index) {
                    return _OptionChip(
                      label: homeCareGoalOptions[index],
                      selected: _selectedCareGoal == index,
                      onTap: () => setState(() => _selectedCareGoal = index),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('doctor_booking.home_care_arrival_label'),
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(homeCareArrivalOptions.length, (
                    index,
                  ) {
                    return _OptionChip(
                      label: homeCareArrivalOptions[index],
                      selected: _selectedArrival == index,
                      onTap: () => setState(() => _selectedArrival = index),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                l10n.t('doctor_booking.select_date'),
                style: AppTextStyles.h4,
              ),
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
              Text(
                l10n.t('doctor_booking.select_time'),
                style: AppTextStyles.h4,
              ),
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
              Text(
                l10n.t('doctor_booking.notes_optional'),
                style: AppTextStyles.h4,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.t('doctor_booking.notes_hint'),
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
                      doctor.isDoctorProvider
                          ? l10n.t('doctor_booking.doctor')
                          : l10n.t('doctor_booking.professional'),
                      doctor.name,
                    ),
                    _Row(
                      l10n.t('doctor_booking.date'),
                      '${_dates[_selectedDate].$1}, Mar ${_dates[_selectedDate].$2}, 2026',
                    ),
                    _Row(
                      l10n.t('doctor_booking.time'),
                      '${_times[_selectedTime]} AM',
                    ),
                    _Row(
                      doctor.isDoctorProvider
                          ? l10n.t('doctor_booking.type')
                          : l10n.t('doctor_booking.service'),
                      doctor.isDoctorProvider
                          ? [
                              l10n.t('doctor_booking.video_call'),
                              l10n.t('doctor_booking.chat'),
                              l10n.t('doctor_booking.in_person'),
                            ][_selectedType]
                          : [
                              l10n.t('doctor_booking.home_visit'),
                              l10n.t('doctor_booking.phone_advice'),
                              l10n.t('doctor_booking.video_support'),
                            ][_selectedType],
                    ),
                    if (!doctor.isDoctorProvider) ...[
                      _Row(
                        l10n.t('doctor_booking.home_care_plan_label'),
                        homeCarePlanOptions[_selectedCarePlan],
                      ),
                      _Row(
                        l10n.t('doctor_booking.home_care_goal_label'),
                        homeCareGoalOptions[_selectedCareGoal],
                      ),
                      _Row(
                        l10n.t('doctor_booking.home_care_arrival_label'),
                        homeCareArrivalOptions[_selectedArrival],
                      ),
                    ],
                    const Divider(height: 20),
                    _Row(
                      l10n.t('doctor_booking.fee'),
                      '\$${doctor.consultationFee.toInt()}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: doctor.isDoctorProvider
                    ? l10n.t('doctor_booking.confirm_booking')
                    : l10n.t('doctor_booking.book_care_service'),
                color: AppColors.doctor,
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final allowed = await requireLoggedIn(
                    context,
                    message: l10n.t('doctor_booking.login_required'),
                  );
                  if (!context.mounted || !allowed) return;
                  try {
                    final selectedDate = DateTime.utc(
                      2026,
                      3,
                      int.parse(_dates[_selectedDate].$2),
                    );
                    final endpoint = doctor.isDoctorProvider
                        ? '/appointments'
                        : '/appointments/home-care';
                    final manualNotes = _notesController.text.trim();
                    final requestNotes = doctor.isDoctorProvider
                        ? (manualNotes.isEmpty
                              ? 'Doctor appointment booked via EdaLab Super App'
                              : manualNotes)
                        : [
                            'Home care booking via EdaLab Super App',
                            'Plan: ${homeCarePlanOptions[_selectedCarePlan]}',
                            'Goal: ${homeCareGoalOptions[_selectedCareGoal]}',
                            'Arrival: ${homeCareArrivalOptions[_selectedArrival]}',
                            if (manualNotes.isNotEmpty)
                              'Patient notes: $manualNotes',
                          ].join(' • ');
                    final appointment = await ApiClient.post(endpoint, {
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
                      'notes': requestNotes,
                    });
                    if (!context.mounted) return;
                    context.push(
                      '/checkout/success',
                      extra: {
                        'orderId': appointment is Map
                            ? appointment['id']
                            : null,
                        'amount': doctor.consultationFee,
                        'payment': l10n.t(
                          'home_service_booking.pay_on_confirmation',
                        ),
                        'delivery': doctor.isDoctorProvider
                            ? l10n.t('doctor_booking.appointment_scheduled')
                            : l10n.t('doctor_booking.care_service_scheduled'),
                        'moduleName': doctor.isDoctorProvider
                            ? doctor.name
                            : (doctor.services.isNotEmpty
                                  ? doctor.services.first
                                  : doctor.name),
                        'itemCount': 1,
                        'trackingRoute': '/doctor/appointments',
                      },
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.t(
                            'doctor_booking.failed',
                            params: {'error': '$error'},
                          ),
                        ),
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

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.doctor : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: selected ? null : Border.all(color: AppColors.lightGrey),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.white : AppColors.dark,
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
