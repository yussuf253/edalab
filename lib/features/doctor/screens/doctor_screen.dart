import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';

class _CareCategory {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  const _CareCategory({
    required this.id,
    required this.label,
    required this.subtitle,
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
      label: 'All Care',
      subtitle: 'Doctors and visits',
      icon: Icons.favorite_border_rounded,
      color: Color(0xFF2563EB),
      keywords: [],
    ),
    _CareCategory(
      id: 'nursing',
      label: 'Nursing',
      subtitle: 'Wound care',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFF97316),
      keywords: ['nursing', 'wound', 'injection', 'elderly'],
    ),
    _CareCategory(
      id: 'physio',
      label: 'Physiotherapy',
      subtitle: 'Mobility rehab',
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFF10B981),
      keywords: ['physio', 'therapy', 'rehab', 'kine', 'back pain'],
    ),
    _CareCategory(
      id: 'mental',
      label: 'Mental Care',
      subtitle: 'Stress support',
      icon: Icons.psychology_rounded,
      color: Color(0xFF8B5CF6),
      keywords: ['mental', 'stress', 'counseling', 'emotional'],
    ),
    _CareCategory(
      id: 'child',
      label: 'Child Care',
      subtitle: 'Pediatric follow-up',
      icon: Icons.child_care_rounded,
      color: Color(0xFFEF4444),
      keywords: ['pediatric', 'child', 'vaccination'],
    ),
    _CareCategory(
      id: 'specialist',
      label: 'Specialists',
      subtitle: 'Heart and skin',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFF0EA5E9),
      keywords: ['cardio', 'derma', 'neuro', 'ortho', 'specialist'],
    ),
    _CareCategory(
      id: 'elderly',
      label: 'Elderly Care',
      subtitle: 'Home monitoring',
      icon: Icons.elderly_rounded,
      color: Color(0xFF14B8A6),
      keywords: ['elderly', 'home nursing', 'monitoring'],
    ),
    _CareCategory(
      id: 'recovery',
      label: 'Recovery',
      subtitle: 'Post-op support',
      icon: Icons.healing_rounded,
      color: Color(0xFFF59E0B),
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
        'label': category.label,
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
    final homeCareCount = _providers
        .where((provider) => provider.isHomeCareProvider)
        .length;
    final doctorCount = _providers
        .where((provider) => !provider.isHomeCareProvider)
        .length;

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
        title: const Text('Home Care & Doctors'),
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
                hint: 'Search services or professionals...',
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
                    colors: [AppColors.doctor, Color(0xFF4F86F7)],
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
                            'Pick a care service, then browse available professionals.',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$homeCareCount home care providers • $doctorCount doctors',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white70,
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
              child: Text('Available Care Services', style: AppTextStyles.h3),
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
                                  category.label,
                                  style: AppTextStyles.labelLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${category.subtitle} • $count available',
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
                'Tap a service to open the professionals screen and see contact details.',
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
              'Browse All Professionals',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.white),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
