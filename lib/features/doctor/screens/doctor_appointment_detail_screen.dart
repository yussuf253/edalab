import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/message_launcher.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class DoctorAppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic>? initialAppointment;

  const DoctorAppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.initialAppointment,
  });

  @override
  State<DoctorAppointmentDetailScreen> createState() =>
      _DoctorAppointmentDetailScreenState();
}

class _DoctorAppointmentDetailScreenState
    extends State<DoctorAppointmentDetailScreen> {
  Map<String, dynamic>? _appointment;
  DoctorModel? _doctor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _appointment = widget.initialAppointment;
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      Map<String, dynamic>? appointment = _appointment;
      if (appointment == null || appointment.isEmpty) {
        final response = await ApiClient.get('/appointments/$userId');
        final items = response is List ? response : const [];
        for (final entry in items) {
          final candidate = Map<String, dynamic>.from(entry as Map);
          if (candidate['id']?.toString() == widget.appointmentId) {
            appointment = candidate;
            break;
          }
        }
      }

      DoctorModel? doctor;
      final doctorId = appointment?['doctorId']?.toString();
      if (doctorId != null && doctorId.isNotEmpty) {
        try {
          final response = await ApiClient.get(
            '/catalog/doctors/$doctorId',
            forceRefresh: true,
          );
          doctor = DoctorModel.fromApi(
            Map<String, dynamic>.from(response as Map),
          );
        } catch (_) {
          for (final item in DoctorModel.sampleDoctors) {
            if (item.id == doctorId) {
              doctor = item;
              break;
            }
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _appointment = appointment;
        _doctor = doctor;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  bool get _canMessageDoctor {
    final status = _appointment?['status']?.toString().toLowerCase() ?? '';
    final approved = status == 'approved';
    return approved && (_doctor?.canBookThroughApp ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appointment = _appointment;
    final doctor = _doctor;
    final doctorName =
        doctor?.name ??
        l10n.t(
          'appointments.doctor_fallback',
          params: {'id': appointment?['doctorId']?.toString() ?? ''},
        );
    final specialty = doctor?.specialty ?? l10n.t('appointments.specialist');
    final status =
        appointment?['status']?.toString() ?? l10n.t('appointments.unknown');
    final date =
        appointment?['date']?.toString() ?? l10n.t('appointments.unknown_date');
    final time = appointment?['timeSlot']?.toString() ?? '--:--';
    final type =
        appointment?['appointmentType']?.toString() ??
        appointment?['type']?.toString() ??
        specialty;
    final notes = appointment?['notes']?.toString();
    final fee =
        ((appointment?['consultationFee'] as num?)?.toDouble() ??
                (doctor?.consultationFee ?? 0))
            .toStringAsFixed(0);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/doctor/appointments');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('appointments.detail_title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/doctor/appointments');
              }
            },
          ),
        ),
        body: _isLoading
            ? const DetailContentShimmer(
                accentColor: AppColors.doctor,
                showHero: false,
              )
            : appointment == null
            ? Center(
                child: Text(
                  l10n.t('appointments.empty_subtitle'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.doctor, AppColors.secondaryLight],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctorName,
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  specialty,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DetailCard(
                      title: l10n.t('appointments.summary'),
                      children: [
                        _DetailRow(
                          l10n.t('appointments.booking_id'),
                          '#${appointment['id']}',
                        ),
                        _DetailRow(l10n.t('appointments.doctor'), doctorName),
                        _DetailRow(l10n.t('appointments.status'), status),
                        _DetailRow(l10n.t('appointments.date'), date),
                        _DetailRow(l10n.t('appointments.time'), time),
                        _DetailRow(l10n.t('appointments.type'), type),
                        _DetailRow(l10n.t('appointments.fee'), 'DJF$fee'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailCard(
                      title: l10n.t('appointments.notes'),
                      children: [
                        Text(
                          notes == null || notes.trim().isEmpty
                              ? l10n.t('appointments.no_notes')
                              : notes,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_canMessageDoctor && doctor != null)
                      AppButton(
                        text: l10n.t('appointments.message_doctor'),
                        color: AppColors.doctor,
                        onPressed: () => openConversation(
                          context,
                          moduleType: 'DOCTOR',
                          entityType: 'DOCTOR',
                          entityId: doctor.id,
                          title: doctor.name,
                          subtitle: doctor.specialty,
                          avatarUrl: doctor.imageUrl,
                          accentColor: '#3498DB',
                          metadata: {
                            'doctorId': doctor.id,
                            'appointmentId': appointment['id'],
                            'specialty': doctor.specialty,
                          },
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppSpacing.shadowSm,
                        ),
                        child: Text(
                          l10n.t('appointments.chat_available'),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.grey,
                            height: 1.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppSpacing.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.h4),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}
