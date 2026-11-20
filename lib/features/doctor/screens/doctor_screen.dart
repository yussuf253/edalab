import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/module_screen_app_bar.dart';

class _HealthServiceCategory {
  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;

  const _HealthServiceCategory({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.color,
  });
}

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_HealthServiceCategory> _categories = const [
    _HealthServiceCategory(
      id: 'hsc-lab-tests',
      labelKey: 'doctor.lab_tests',
      icon: Icons.science_rounded,
      color: Color(0xFF3B82F6),
    ),
    _HealthServiceCategory(
      id: 'hsc-consultation',
      labelKey: 'doctor.consultation',
      icon: Icons.medical_services_rounded,
      color: AppColors.doctor,
    ),
    _HealthServiceCategory(
      id: 'hsc-physiotherapy',
      labelKey: 'doctor.physiotherapy',
      icon: Icons.accessibility_new_rounded,
      color: AppColors.secondary,
    ),
  ];

  String _searchQuery = '';

  void _openService(_HealthServiceCategory category) {
    if (category.id == 'hsc-lab-tests') {
      context.push(
        '/doctor/lab-tests',
        extra: {
          'categoryId': category.id,
          'label': context.l10n.t(category.labelKey),
        },
      );
    } else if (category.id == 'hsc-physiotherapy') {
      context.push(
        '/doctor/physiotherapy',
        extra: {
          'categoryId': category.id,
          'label': context.l10n.t(category.labelKey),
        },
      );
    } else {
      // For consultation and other services, navigate to professionals
      context.push(
        '/doctor/professionals/consultation',
        extra: {
          'label': context.l10n.t(category.labelKey),
          'keywords': ['doctor', 'consultation', 'medical', 'general'],
        },
      );
    }
  }

  void _openHomeCareBooking() {
    context.push(
      '/doctor/home-care',
      extra: {'searchQuery': _searchQuery.trim()},
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.35);
    final categoryAspectRatio = (1.25 - ((textScale - 1.0) * 0.1)).clamp(
      1.1,
      1.25,
    );

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: ModuleScreenAppBar(
          title: l10n.t('doctor.title'),
          search: AppSearchBar(
            hint: l10n.t('doctor.search_hint'),
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: GestureDetector(
                  onTap: _openHomeCareBooking,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.doctorBg,
                      image: const DecorationImage(
                        image: AssetImage(
                          'assets/images/headers/header_painreleaf.png',
                        ),
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('doctor.home_care_banner_title'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.h4.copyWith(
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.t('doctor.home_care_banner_subtitle'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.t('doctor.home_care_explore'),
                                        style: AppTextStyles.labelMedium
                                            .copyWith(
                                              color: AppColors.doctor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: AppColors.doctor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 84),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(
                  l10n.t('doctor.available_services'),
                  style: AppTextStyles.h3,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverGrid.builder(
                itemCount: _categories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: categoryAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return GestureDetector(
                    onTap: () => _openService(category),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              category.icon,
                              size: 20,
                              color: category.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.t(category.labelKey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => _openService(_categories.first),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.doctor,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.t('doctor.browse_all'),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
