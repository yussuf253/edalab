import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  Future<Map<String, dynamic>> _fetchAppointments(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) {
      return {'appointments': <dynamic>[], 'doctors': <String, DoctorModel>{}};
    }

    final appointments = await ApiClient.get('/appointments/${auth.user!.id}');
    Map<String, DoctorModel> doctorsById = {
      for (final doctor in DoctorModel.sampleDoctors) doctor.id: doctor,
    };

    try {
      final doctorsResponse = await ApiClient.get('/catalog/doctors');
      final doctors = (doctorsResponse as List)
          .map(
            (entry) =>
                DoctorModel.fromApi(Map<String, dynamic>.from(entry as Map)),
          )
          .toList();
      doctorsById = {for (final doctor in doctors) doctor.id: doctor};
    } catch (_) {}

    return {'appointments': appointments, 'doctors': doctorsById};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/doctor');
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('appointments.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/doctor');
            }
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAppointments(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SimpleListShimmer(itemCount: 4, trailingBadge: true);
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                l10n.t(
                  'appointments.error',
                  params: {'error': snapshot.error.toString()},
                ),
              ),
            );
          }

          final payload = snapshot.data ?? const {};
          final appointments = (payload['appointments'] as List?) ?? const [];
          final doctorsById =
              (payload['doctors'] as Map<String, DoctorModel>?) ??
              const <String, DoctorModel>{};
          if (appointments.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.calendar_today_rounded,
                title: l10n.t('appointments.empty_title'),
                subtitle: l10n.t('appointments.empty_subtitle'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: appointments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final apiAppt = appointments[index];
              final dId = apiAppt['doctorId'];
              final doctor = doctorsById[dId];
              final String name = doctor?.name ??
                  l10n.t(
                    'appointments.doctor_fallback',
                    params: {'id': dId.toString()},
                  );
              final String specialty =
                  doctor?.specialty ?? l10n.t('appointments.specialist');
              final String status =
                  apiAppt['status'] ?? l10n.t('appointments.unknown');
              final dateObj = DateTime.tryParse(apiAppt['date'] ?? '');
              final dateStr = dateObj != null
                  ? '${dateObj.month}/${dateObj.day}/${dateObj.year}'
                  : l10n.t('appointments.unknown_date');
              final timeStr = apiAppt['timeSlot'] ?? '00:00';

              Color statusColor = AppColors.primary;
              if (status.toLowerCase().contains('cancel')) {
                statusColor = AppColors.error;
              }
              if (status.toLowerCase().contains('complet')) {
                statusColor = AppColors.success;
              }

              return GestureDetector(
                onTap: () => context.push(
                  '/doctor/appointments/${apiAppt['id']}',
                  extra: Map<String, dynamic>.from(apiAppt as Map),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.doctorBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.doctor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: AppTextStyles.labelLarge),
                                const SizedBox(height: 2),
                                Text(specialty, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          StatusBadge(
                            text: status.toUpperCase(),
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.extraLightGrey,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$dateStr, $timeStr',
                              style: AppTextStyles.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}
