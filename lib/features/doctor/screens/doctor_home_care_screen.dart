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

class _HomeCareCategory {
  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  const _HomeCareCategory({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}

class DoctorHomeCareScreen extends StatefulWidget {
  final String initialQuery;

  const DoctorHomeCareScreen({super.key, this.initialQuery = ''});

  @override
  State<DoctorHomeCareScreen> createState() => _DoctorHomeCareScreenState();
}

class _DoctorHomeCareScreenState extends State<DoctorHomeCareScreen> {
  static const List<_HomeCareCategory> _categories = [
    _HomeCareCategory(
      id: 'all',
      labelKey: 'doctor.all_care',
      icon: Icons.favorite_border_rounded,
      color: AppColors.doctor,
      keywords: [],
    ),
    _HomeCareCategory(
      id: 'nursing',
      labelKey: 'doctor.nursing',
      icon: Icons.medical_services_rounded,
      color: AppColors.primary,
      keywords: ['nursing', 'wound', 'injection'],
    ),
    _HomeCareCategory(
      id: 'physio',
      labelKey: 'doctor.physio',
      icon: Icons.accessibility_new_rounded,
      color: AppColors.secondary,
      keywords: ['physio', 'therapy', 'rehab', 'kine'],
    ),
    _HomeCareCategory(
      id: 'elderly',
      labelKey: 'doctor.elderly',
      icon: Icons.elderly_rounded,
      color: AppColors.hotel,
      keywords: ['elderly', 'senior', 'monitoring'],
    ),
    _HomeCareCategory(
      id: 'recovery',
      labelKey: 'doctor.recovery',
      icon: Icons.healing_rounded,
      color: AppColors.food,
      keywords: ['recovery', 'post-op', 'post op', 'pain'],
    ),
    _HomeCareCategory(
      id: 'mental',
      labelKey: 'doctor.mental',
      icon: Icons.psychology_rounded,
      color: AppColors.homeServices,
      keywords: ['mental', 'counseling', 'emotional', 'stress'],
    ),
  ];

  late final TextEditingController _searchController;
  List<DoctorModel> _providers = DoctorModel.sampleDoctors;
  bool _isLoading = true;
  String _selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _loadProviders();
  }

  bool _isHomeCareProvider(DoctorModel provider) {
    if (provider.isHomeCareProvider) return true;
    if (provider.providerType.toUpperCase() == 'HOME_CARE') return true;
    return provider.careModes.any(
      (mode) =>
          mode.toLowerCase().contains('home') ||
          mode.toLowerCase().contains('visit'),
    );
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
          .where(_isHomeCareProvider)
          .toList();

      if (!mounted) return;
      setState(() {
        _providers = items.isEmpty
            ? DoctorModel.sampleDoctors.where(_isHomeCareProvider).toList()
            : items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _providers = DoctorModel.sampleDoctors
            .where(_isHomeCareProvider)
            .toList();
        _isLoading = false;
      });
    }
  }

  bool _matchesCategory(DoctorModel provider, _HomeCareCategory category) {
    if (category.id == 'all') return true;
    final haystack = <String>[
      provider.name,
      provider.specialty,
      provider.about ?? '',
      ...provider.services,
      ...provider.careModes,
    ].join(' ').toLowerCase();
    return category.keywords.any(haystack.contains);
  }

  List<DoctorModel> get _filteredProviders {
    final selectedCategory = _categories.firstWhere(
      (category) => category.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );
    final query = _searchController.text.trim().toLowerCase();

    return _providers
        .where((provider) {
          final matchesCategory = _matchesCategory(provider, selectedCategory);
          final matchesQuery =
              query.isEmpty ||
              provider.name.toLowerCase().contains(query) ||
              provider.specialty.toLowerCase().contains(query) ||
              provider.services.any(
                (service) => service.toLowerCase().contains(query),
              ) ||
              provider.about?.toLowerCase().contains(query) == true;
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);
  }

  int _countForCategory(_HomeCareCategory category) {
    return _providers
        .where((provider) => _matchesCategory(provider, category))
        .length;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredProviders = _filteredProviders;
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.35);
    final categoryAspectRatio = (1.42 - ((textScale - 1.0) * 0.16)).clamp(
      1.2,
      1.42,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.t('doctor.home_care_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppSearchBar(
                hint: l10n.t('doctor.home_care_search_hint'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0B7F66),
                      AppColors.homeServices,
                      Color(0xFF5AC29A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppSpacing.shadowSm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('doctor.home_care_banner_title'),
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.t('doctor.home_care_banner_subtitle'),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
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
                            child: Text(
                              l10n.t(
                                'doctor.home_care_available_count',
                                params: {'count': _providers.length.toString()},
                              ),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.homeServices,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.white,
                        size: 30,
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
                l10n.t('doctor.home_care_categories'),
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
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: categoryAspectRatio,
              ),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = _selectedCategoryId == category.id;
                final count = _countForCategory(category);
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategoryId = category.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? category.color.withValues(alpha: 0.16)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? category.color.withValues(alpha: 0.45)
                            : AppColors.lightGrey,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(category.icon, color: category.color, size: 22),
                        const SizedBox(height: 8),
                        Text(
                          l10n.t(category.labelKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: selected ? category.color : AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.t(
                            'doctor.home_care_available_count',
                            params: {'count': count.toString()},
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
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.t('doctor.home_care_available_professionals'),
                      style: AppTextStyles.h3,
                    ),
                  ),
                  Text(
                    l10n.t(
                      'doctor.home_care_found_count',
                      params: {'count': filteredProviders.length.toString()},
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
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
                        height: 122,
                        radius: 16,
                      ),
                      SizedBox(height: 10),
                      ShimmerBlock(
                        width: double.infinity,
                        height: 122,
                        radius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filteredProviders.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: AppColors.doctorBg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.search_off_rounded,
                          color: AppColors.doctor,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.t('doctor.home_care_empty_title'),
                        style: AppTextStyles.h3,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.t('doctor.home_care_empty_subtitle'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: filteredProviders.length,
              itemBuilder: (context, index) {
                final provider = filteredProviders[index];
                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: AppColors.doctorBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child:
                                provider.imageUrl != null &&
                                    provider.imageUrl!.trim().isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      provider.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.health_and_safety_rounded,
                                        color: AppColors.doctor,
                                        size: 30,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.health_and_safety_rounded,
                                    color: AppColors.doctor,
                                    size: 30,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.name,
                                  style: AppTextStyles.labelLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  provider.specialty,
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: provider.careModes
                                      .take(2)
                                      .map((mode) => _ModeTag(label: mode))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${provider.rating} (${provider.reviewCount})',
                            style: AppTextStyles.labelSmall,
                          ),
                          const Spacer(),
                          Text(
                            'DJF${provider.consultationFee.toInt()}',
                            style: AppTextStyles.priceSmall.copyWith(
                              color: AppColors.doctor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  context.push('/doctor/detail/${provider.id}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.doctor,
                                side: const BorderSide(color: AppColors.doctor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                l10n.t('doctor.home_care_open_details'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  context.push('/doctor/book/${provider.id}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.doctor,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(l10n.t('doctor.home_care_book_now')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ModeTag extends StatelessWidget {
  final String label;

  const _ModeTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
      ),
    );
  }
}
