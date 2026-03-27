import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/message_launcher.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_shimmer.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  DoctorModel? _doctor;
  bool _isLoading = true;

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
        const SnackBar(content: Text('No contact number available yet.')),
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
        child: _isLoading || doctor == null
            ? const DetailContentShimmer(
                accentColor: AppColors.doctor,
                showHero: false,
              )
            : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.doctor, AppColors.secondaryLight],
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
                          child: Icon(
                            doctor.isHomeCareProvider
                                ? Icons.health_and_safety_rounded
                                : Icons.person_rounded,
                            color: AppColors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          doctor.name,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${doctor.specialty} • ${doctor.experience} experience',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _ProfileChip(
                              label: doctor.professionLabel,
                              foregroundColor: AppColors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.14,
                              ),
                            ),
                            ...doctor.careModes
                                .take(2)
                                .map(
                                  (mode) => _ProfileChip(
                                    label: mode,
                                    foregroundColor: AppColors.white,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.14,
                                    ),
                                  ),
                                ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatCol('${doctor.reviewCount}+', 'Patients'),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white24,
                            ),
                            _StatCol('${doctor.rating}', 'Rating'),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white24,
                            ),
                            _StatCol(
                              doctor.experience.split(' ').first,
                              'Experience',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About', style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        Text(
                          doctor.about ?? 'No information available.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Services Offered', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: doctor.services
                              .map(
                                (service) => _DetailTag(
                                  label: service,
                                  color: AppColors.doctor,
                                ),
                              )
                              .toList(),
                        ),
                        if (doctor.languages.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Languages', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: doctor.languages
                                .map(
                                  (language) => _DetailTag(
                                    label: language,
                                    color: AppColors.primary,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text('Care Modes', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: doctor.careModes
                              .map(
                                (mode) => _DetailTag(
                                  label: mode,
                                  color: AppColors.secondary,
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        Text('Working Hours', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        ...[
                          ('Mon - Fri', doctor.workingHours.weekdays),
                          ('Saturday', doctor.workingHours.saturday),
                          ('Sunday', doctor.workingHours.sunday),
                        ].map(
                          (hours) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(hours.$1, style: AppTextStyles.bodyMedium),
                                Text(
                                  hours.$2,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: hours.$2 == 'Closed'
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
                                if (doctor.location != null) ...[
                                  Text(
                                    doctor.location!.split(', ').first,
                                    style: AppTextStyles.labelMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  if (doctor.location!.split(', ').length > 1)
                                    Text(
                                      doctor.location!
                                          .split(', ')
                                          .sublist(1)
                                          .join(', '),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (doctor.contactPhone != null ||
                            doctor.contactWhatsApp != null) ...[
                          const SizedBox(height: 20),
                          Text('Direct Contact', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppSpacing.shadowSm,
                            ),
                            child: Column(
                              children: [
                                _ContactRow(
                                  icon: Icons.call_rounded,
                                  label: 'Phone',
                                  value:
                                      doctor.contactPhone ??
                                      'Not available yet',
                                ),
                                const SizedBox(height: 12),
                                _ContactRow(
                                  icon: Icons.chat_rounded,
                                  label: 'WhatsApp',
                                  value:
                                      doctor.contactWhatsApp ??
                                      'Not available yet',
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (doctor.reviews.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text('Patient Reviews', style: AppTextStyles.h4),
                          const SizedBox(height: 12),
                          ...doctor.reviews.map(
                            (review) => Container(
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
                                      Expanded(
                                        child: Text(
                                          review.name,
                                          style: AppTextStyles.labelMedium,
                                        ),
                                      ),
                                      ...List.generate(
                                        review.rating,
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
                                    review.comment,
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
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomSheet: _isLoading || doctor == null
          ? null
          : Container(
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
                        if (!doctor.usesDirectContactOnly) ...[
                          Text(
                            doctor.isDoctorProvider
                                ? 'Consultation Fee'
                                : 'Service Fee',
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            '\$${doctor.consultationFee.toInt()}',
                            style: AppTextStyles.price.copyWith(
                              color: AppColors.doctor,
                            ),
                          ),
                        ] else
                          Text(
                            doctor.professionLabel,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.doctor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 112,
                      child: AppButton(
                        text: 'Message',
                        isSmall: true,
                        isOutlined: true,
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
                            'specialty': doctor.specialty,
                            'professionLabel': doctor.professionLabel,
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: doctor.primaryActionLabel,
                        color: AppColors.doctor,
                        onPressed: () {
                          if (doctor.usesDirectContactOnly) {
                            _contactProvider();
                            return;
                          }

                          context.push('/doctor/book/${doctor.id}');
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
  final String value;
  final String label;

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

class _DetailTag extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailTag({required this.label, required this.color});

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

class _ProfileChip extends StatelessWidget {
  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  const _ProfileChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: foregroundColor),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactRow({
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
