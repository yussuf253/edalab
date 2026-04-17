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

  void _openHomeCareBooking() {
    context.push(
      '/doctor/home-care',
      extra: {'searchQuery': _searchQuery.trim()},
    );
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
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.35);
    final categoryAspectRatio = (0.84 - ((textScale - 1.0) * 0.16)).clamp(
      0.72,
      0.84,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: GestureDetector(
                  onTap: _openHomeCareBooking,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0E8E68),
                          AppColors.homeServices,
                          Color(0xFF57C49A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppSpacing.shadowSm,
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
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.t('doctor.home_care_banner_subtitle'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    height: 1.3,
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
                                              color: AppColors.homeServices,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: AppColors.homeServices,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
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
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: AppShimmer(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ShimmerBlock(
                                width: double.infinity,
                                height: 120,
                                radius: 16,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ShimmerBlock(
                                width: double.infinity,
                                height: 120,
                                radius: 16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ShimmerBlock(
                                width: double.infinity,
                                height: 120,
                                radius: 16,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: ShimmerBlock(
                                width: double.infinity,
                                height: 120,
                                radius: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
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
                    final count = _countForCategory(category);
                    return GestureDetector(
                      onTap: () => _openProfessionals(category),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: AppSpacing.shadowSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                category.icon,
                                size: 23,
                                color: category.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.t(category.labelKey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelLarge.copyWith(
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Text(
                                l10n.t(
                                  'doctor.available_count',
                                  params: {
                                    'subtitle': l10n.t(category.subtitleKey),
                                    'count': '$count',
                                  },
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.grey,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
