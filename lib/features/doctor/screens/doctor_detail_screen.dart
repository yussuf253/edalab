import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/auth_gate.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  late DoctorModel _doctor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _doctor = DoctorModel.sampleDoctors.firstWhere(
      (doc) => doc.id == widget.doctorId,
      orElse: () => DoctorModel.sampleDoctors.first,
    );
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    try {
      final response = await ApiClient.get(
        '/catalog/doctors/${widget.doctorId}',
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

  @override
  Widget build(BuildContext context) {
    final d = _doctor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: _isLoading
            ? const DetailContentShimmer(
                accentColor: AppColors.doctor,
                showHero: false,
              )
            : Column(
                children: [
                  // Doctor card
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.doctor, Color(0xFF5DADE2)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.doctor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          d.name,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.specialty} • ${d.experience} experience',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatCol('${d.reviewCount}+', 'Patients'),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white24,
                            ),
                            _StatCol('${d.rating}', 'Rating'),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white24,
                            ),
                            _StatCol(
                              d.experience.split(' ').first,
                              'Experience',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About', style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        Text(
                          d.about ?? 'No information available.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Working Hours', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        ...[
                          ('Mon - Fri', d.workingHours.weekdays),
                          ('Saturday', d.workingHours.saturday),
                          ('Sunday', d.workingHours.sunday),
                        ].map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(h.$1, style: AppTextStyles.bodyMedium),
                                Text(
                                  h.$2,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: h.$2 == 'Closed'
                                        ? AppColors.accent
                                        : AppColors.dark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Location', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.extraLightGrey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                if (d.location != null) ...[
                                  Text(
                                    d.location!.split(', ').first,
                                    style: AppTextStyles.labelMedium,
                                  ),
                                  if (d.location!.split(', ').length > 1)
                                    Text(
                                      d.location!
                                          .split(', ')
                                          .sublist(1)
                                          .join(', '),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (d.reviews.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Patient Reviews', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          ...d.reviews.map(
                            (r) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: AppSpacing.shadowSm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.doctorBg,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          color: AppColors.doctor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        r.name,
                                        style: AppTextStyles.labelMedium,
                                      ),
                                      const SizedBox(width: 8),
                                      ...List.generate(
                                        r.rating,
                                        (_) => const Icon(
                                          Icons.star_rounded,
                                          size: 14,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    r.comment,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.dark,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consultation Fee', style: AppTextStyles.caption),
                  Text(
                    '\$${d.consultationFee.toInt()}',
                    style: AppTextStyles.price.copyWith(
                      color: AppColors.doctor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: AppButton(
                  text: 'Book Appointment',
                  color: AppColors.doctor,
                  onPressed: () async {
                    final allowed = await requireLoggedIn(
                      context,
                      message: 'Please log in to book an appointment.',
                    );
                    if (!context.mounted || !allowed) return;
                    context.push('/doctor/book/${d.id}');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value, label;
  const _StatCol(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h4.copyWith(color: AppColors.white)),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white60),
        ),
      ],
    );
  }
}
