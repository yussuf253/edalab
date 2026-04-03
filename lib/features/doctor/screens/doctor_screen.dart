import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';

class _CareCategory {
  final String id;
  final String labelKey;
  final String subtitleKey;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  const _CareCategory({
    required this.id,
    required this.labelKey,
    required this.subtitleKey,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});

  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_CareCategory> _categories = const [
    _CareCategory(
      id: 'all',
      labelKey: 'doctor.all_care',
      subtitleKey: 'doctor.all_care_subtitle',
      icon: Icons.favorite_border_rounded,
      color: AppColors.doctor,
      keywords: [],
    ),
    _CareCategory(
      id: 'nursing',
      labelKey: 'doctor.nursing',
      subtitleKey: 'doctor.nursing_subtitle',
      icon: Icons.medical_services_rounded,
      color: AppColors.primary,
      keywords: ['nursing', 'wound', 'injection', 'elderly'],
    ),
    _CareCategory(
      id: 'physio',
      labelKey: 'doctor.physio',
      subtitleKey: 'doctor.physio_subtitle',
      icon: Icons.accessibility_new_rounded,
      color: AppColors.secondary,
      keywords: ['physio', 'therapy', 'rehab', 'kine', 'back pain'],
    ),
    _CareCategory(
      id: 'mental',
      labelKey: 'doctor.mental',
      subtitleKey: 'doctor.mental_subtitle',
      icon: Icons.psychology_rounded,
      color: AppColors.homeServices,
      keywords: ['mental', 'stress', 'counseling', 'emotional'],
    ),
    _CareCategory(
      id: 'child',
      labelKey: 'doctor.child',
      subtitleKey: 'doctor.child_subtitle',
      icon: Icons.child_care_rounded,
      color: AppColors.shopping,
      keywords: ['pediatric', 'child', 'vaccination'],
    ),
    _CareCategory(
      id: 'specialist',
      labelKey: 'doctor.specialists',
      subtitleKey: 'doctor.specialists_subtitle',
      icon: Icons.local_hospital_rounded,
      color: AppColors.ride,
      keywords: ['cardio', 'derma', 'neuro', 'ortho', 'specialist'],
    ),
    _CareCategory(
      id: 'elderly',
      labelKey: 'doctor.elderly',
      subtitleKey: 'doctor.elderly_subtitle',
      icon: Icons.elderly_rounded,
      color: AppColors.hotel,
      keywords: ['elderly', 'home nursing', 'monitoring'],
    ),
    _CareCategory(
      id: 'recovery',
      labelKey: 'doctor.recovery',
      subtitleKey: 'doctor.recovery_subtitle',
      icon: Icons.healing_rounded,
      color: AppColors.food,
      keywords: ['rehab', 'recovery', 'wound', 'post', 'pain'],
    ),
  ];

  String _searchQuery = '';
  List<DoctorModel> _providers = DoctorModel.sampleDoctors;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      final response = await ApiClient.get(
        '/catalog/doctors',
        forceRefresh: true,
      );
      final items = (response as List)
          .map(
            (item) =>
                DoctorModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _providers = items.isEmpty ? DoctorModel.sampleDoctors : items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  bool _matchesCategory(DoctorModel provider, _CareCategory category) {
    if (category.id == 'all') return true;

    final haystack = <String>[
      provider.name,
      provider.specialty,
      provider.providerType,
      provider.about ?? '',
      ...provider.services,
      ...provider.careModes,
    ].join(' ').toLowerCase();

    if (category.id == 'specialist') {
      return provider.providerType == 'DOCTOR';
    }

    return category.keywords.any(haystack.contains);
  }

  int _countForCategory(_CareCategory category) {
    return _providers
        .where((provider) => _matchesCategory(provider, category))
        .length;
  }

  void _openProfessionals(_CareCategory category) {
    context.push(
      '/doctor/professionals/${category.id}',
      extra: {
        'label': context.l10n.t(category.labelKey),
        'keywords': category.keywords,
        'searchQuery': _searchQuery.trim(),
      },
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
        appBar: AppBar(
          title: Text(l10n.t('doctor.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: AppSearchBar(
                  hint: l10n.t('doctor.search_hint'),
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.doctor, AppColors.secondaryLight],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('doctor.hero_title'),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.white,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppColors.white,
                          size: 28,
                        ),
                      ),
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
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AppShimmer(
                    child: Column(
                      children: [
                        ShimmerBlock(
                          width: double.infinity,
                          height: 54,
                          radius: 16,
                        ),
                        SizedBox(height: 10),
                        ShimmerBlock(
                          width: double.infinity,
                          height: 54,
                          radius: 16,
                        ),
                        SizedBox(height: 10),
                        ShimmerBlock(
                          width: double.infinity,
                          height: 54,
                          radius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final count = _countForCategory(category);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: GestureDetector(
                      onTap: () => _openProfessionals(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppSpacing.shadowSm,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                category.icon,
                                size: 20,
                                color: category.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.t(category.labelKey),
                                    style: AppTextStyles.labelLarge,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    l10n.t(
                                      'doctor.available_count',
                                      params: {
                                        'subtitle': l10n.t(
                                          category.subtitleKey,
                                        ),
                                        'count': '$count',
                                      },
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox.shrink(),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Text(
                  l10n.t('doctor.tap_service'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _openProfessionals(_categories.first),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.doctor,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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
