import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  Future<List<dynamic>> _fetchAppointments(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.user == null) return [];
    return await ApiClient.get('/appointments/${auth.user!.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Appointments'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchAppointments(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading appointments: ${snapshot.error}'));
          }

          final appointments = snapshot.data ?? [];
          if (appointments.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.calendar_today_rounded,
                title: 'No Appointments',
                subtitle: 'You have no scheduled appointments yet.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final apiAppt = appointments[index];
              // Try to map to local doctor for extended details
              final dId = apiAppt['doctorId'];
              final docMatch = DoctorModel.sampleDoctors.where((d) => d.id == dId).toList();
              final String name = docMatch.isNotEmpty ? docMatch.first.name : 'Doctor $dId';
              final String specialty = docMatch.isNotEmpty ? docMatch.first.specialty : 'Specialist';
              final String status = apiAppt['status'] ?? 'Unknown';
              final dateObj = DateTime.tryParse(apiAppt['date'] ?? '');
              final dateStr = dateObj != null ? '${dateObj.month}/${dateObj.day}/${dateObj.year}' : 'Unknown Date';
              final timeStr = apiAppt['timeSlot'] ?? '00:00';

              Color statusColor = AppColors.primary;
              if (status.toLowerCase().contains('cancel')) statusColor = AppColors.error;
              if (status.toLowerCase().contains('complet')) statusColor = AppColors.success;

              return Container(
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
                          width: 50, height: 50,
                          decoration: BoxDecoration(color: AppColors.doctorBg, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.person_rounded, color: AppColors.doctor, size: 26),
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
                        StatusBadge(text: status.toUpperCase(), color: statusColor),
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
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('$dateStr, $timeStr', style: AppTextStyles.labelMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
