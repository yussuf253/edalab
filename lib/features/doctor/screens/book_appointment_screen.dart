import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/models/models.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

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

  final _dates = [
    ('Mon', '22'), ('Tue', '23'), ('Wed', '24'), ('Thu', '25'), ('Fri', '26'), ('Sat', '27'),
  ];
  final _times = ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '02:00', '02:30', '03:00'];

  @override
  Widget build(BuildContext context) {
    final d = DoctorModel.sampleDoctors.firstWhere((doc) => doc.id == widget.doctorId, orElse: () => DoctorModel.sampleDoctors.first);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Appointment'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor mini card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: AppColors.doctorBg, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.person_rounded, color: AppColors.doctor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: AppTextStyles.labelLarge),
                      Text(d.specialty, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Appointment type
            Text('Appointment Type', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Row(
              children: [
                _TypeCard(Icons.videocam_rounded, 'Video Call', _selectedType == 0, () => setState(() => _selectedType = 0)),
                const SizedBox(width: 12),
                _TypeCard(Icons.chat_rounded, 'Chat', _selectedType == 1, () => setState(() => _selectedType = 1)),
                const SizedBox(width: 12),
                _TypeCard(Icons.location_on_rounded, 'In Person', _selectedType == 2, () => setState(() => _selectedType = 2)),
              ],
            ),
            const SizedBox(height: 24),
            // Date
            Text('Select Date', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final sel = _selectedDate == i;
                  final dt = _dates[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.doctor : AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: sel ? null : Border.all(color: AppColors.lightGrey),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(dt.$1, style: AppTextStyles.caption.copyWith(color: sel ? Colors.white60 : AppColors.grey)),
                          const SizedBox(height: 4),
                          Text(dt.$2, style: AppTextStyles.h4.copyWith(color: sel ? AppColors.white : AppColors.dark)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Time
            Text('Select Time', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_times.length, (i) {
                final sel = _selectedTime == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.doctor : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: sel ? null : Border.all(color: AppColors.lightGrey),
                    ),
                    child: Text(_times[i], style: AppTextStyles.labelMedium.copyWith(color: sel ? AppColors.white : AppColors.dark)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Notes
            Text('Notes (optional)', style: AppTextStyles.h4),
            const SizedBox(height: 12),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Describe your symptoms or reason for visit...'),
            ),
            const SizedBox(height: 24),
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.doctorBg, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _Row('Doctor', d.name),
                  _Row('Date', '${_dates[_selectedDate].$1}, Mar ${_dates[_selectedDate].$2}, 2026'),
                  _Row('Time', '${_times[_selectedTime]} AM'),
                  _Row('Type', ['Video Call', 'Chat', 'In Person'][_selectedType]),
                  const Divider(height: 20),
                  _Row('Fee', '\$${d.consultationFee.toInt()}', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Confirm Booking',
              color: AppColors.doctor,
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                try {
                  await ApiClient.post('/appointments', {
                    'userId': auth.user?.id ?? 'guest',
                    'doctorId': d.id,
                    'date': '2026-03-${_dates[_selectedDate].$2}T00:00:00.000Z',
                    'timeSlot': '${_times[_selectedTime]} AM',
                    'type': ['video', 'chat', 'in_person'][_selectedType],
                    'notes': 'Booked via EdaLab Super App',
                  });

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 70, height: 70,
                            decoration: const BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
                            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
                          ),
                          const SizedBox(height: 20),
                          Text('Booking Confirmed!', style: AppTextStyles.h3),
                          const SizedBox(height: 8),
                          Text('Your appointment has been scheduled successfully.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          AppButton(text: 'Done', color: AppColors.doctor, onPressed: () { Navigator.pop(ctx); context.go('/'); }),
                        ],
                      ),
                    ),
                  );
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Failed to book: \$e'), backgroundColor: AppColors.error),
                   );
                }
              },
            ),
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
              Icon(icon, color: selected ? AppColors.white : AppColors.doctor, size: 28),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.labelSmall.copyWith(color: selected ? AppColors.white : AppColors.dark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: bold ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium.copyWith(color: AppColors.grey)),
          Text(value, style: bold ? AppTextStyles.priceSmall.copyWith(color: AppColors.doctor) : AppTextStyles.labelMedium),
        ],
      ),
    );
  }
}
