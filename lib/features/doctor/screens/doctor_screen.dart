import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/module_screen_app_bar.dart';
import '../../home_services/utils/home_service_category_image.dart';
import '../../home_services/widgets/home_service_category_art.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _HealthServiceCategory {
  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;

  /// Main category artwork from `assets/images/doctor/main_category`.
  final String? imagePath;

  /// Share of the artwork canvas the figure covers, flush to its top-right
  /// corner. Measured per image so the figure fills its slot with no dead
  /// plate left between it and the label.
  final double artWidthFraction;
  final double artHeightFraction;

  const _HealthServiceCategory({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.color,
    this.imagePath,
    this.artWidthFraction = 0.54,
    this.artHeightFraction = 0.82,
  });
}

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Main categories in browsing order: medicine first, then lab tests and
  /// doctor consultations. Physiotherapy and home care have no artwork and
  /// keep their icon.
  final List<_HealthServiceCategory> _categories = const [
    _HealthServiceCategory(
      id: 'hsc-medicine',
      labelKey: 'doctor.medicine',
      icon: LucideIcons.pill,
      color: Color(0xFFF59E0B),
      imagePath: 'assets/images/doctor/main_category/med.png',
      artWidthFraction: 0.43,
      artHeightFraction: 0.70,
    ),
    _HealthServiceCategory(
      id: 'hsc-lab-tests',
      labelKey: 'doctor.lab_tests',
      icon: LucideIcons.flaskConical,
      color: Color(0xFF3B82F6),
      imagePath: 'assets/images/doctor/main_category/lab.png',
      artWidthFraction: 0.44,
      artHeightFraction: 0.74,
    ),
    _HealthServiceCategory(
      id: 'hsc-consultation',
      labelKey: 'doctor.consultation',
      icon: LucideIcons.briefcaseMedical,
      color: AppColors.doctor,
      imagePath: 'assets/images/doctor/main_category/doc.png',
      artWidthFraction: 0.24,
      artHeightFraction: 0.80,
    ),
    _HealthServiceCategory(
      id: 'hsc-physiotherapy',
      labelKey: 'doctor.physiotherapy',
      icon: LucideIcons.accessibility,
      color: AppColors.secondary,
    ),
    _HealthServiceCategory(
      id: 'hsc-home-care',
      labelKey: 'doctor.home_care_title',
      icon: LucideIcons.fileHeart,
      color: AppColors.doctor,
    ),
  ];

  String _searchQuery = '';

  void _openService(_HealthServiceCategory category) {
    if (category.id == 'hsc-medicine') {
      context.push('/pharmacy');
    } else if (category.id == 'hsc-lab-tests') {
      context.push(
        '/doctor/lab-tests',
        extra: {
          'categoryId': category.id,
          'label': context.l10n.t(category.labelKey),
        },
      );
    } else if (category.id == 'hsc-home-care') {
      _openHomeCareBooking();
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
                padding: const EdgeInsets.all(20),
                child: Container(
                  height: 132,
                  padding: const EdgeInsets.all(18),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.doctorBg,
                    image: const DecorationImage(
                      image: AssetImage(
                        'assets/images/headers/header_painreleaf.png',
                      ),
                      fit: BoxFit.cover,
                      // The figure sits in the lower right of the canvas, so
                      // anchoring the crop there keeps all of it in view.
                      alignment: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.t('doctor.hero_title'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.h4,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.t('doctor.hero_subtitle'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 96),
                    ],
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _MainCategoryCard(
                    category: category,
                    onTap: () => _openService(category),
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
              onPressed: () => _openService(
                _categories.firstWhere((c) => c.id == 'hsc-consultation'),
              ),
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

/// A main category tile: the illustration on the plate grey the artwork
/// ships with, and the label underneath it.
class _MainCategoryCard extends StatelessWidget {
  const _MainCategoryCard({required this.category, required this.onTap});

  final _HealthServiceCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final imagePath = category.imagePath;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
        decoration: BoxDecoration(
          color: homeServiceCategoryPlateColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: HomeServiceCategoryArt(
                imagePath: imagePath,
                fallbackIcon: category.icon,
                fallbackColor: category.color,
                // Main category artwork is a 340x220 canvas with the figure
                // flush to its top-right corner.
                sourceAspectRatio: 340 / 220,
                contentWidthFraction: category.artWidthFraction,
                contentHeightFraction: category.artHeightFraction,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.t(category.labelKey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: AppColors.dark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
