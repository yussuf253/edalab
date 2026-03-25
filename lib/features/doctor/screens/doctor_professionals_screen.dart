import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';

class DoctorProfessionalsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryLabel;
  final List<String> keywords;
  final String initialQuery;

  const DoctorProfessionalsScreen({
    super.key,
    required this.categoryId,
    required this.categoryLabel,
    this.keywords = const [],
    this.initialQuery = '',
  });

  @override
  State<DoctorProfessionalsScreen> createState() =>
      _DoctorProfessionalsScreenState();
}

class _DoctorProfessionalsScreenState extends State<DoctorProfessionalsScreen> {
  late final TextEditingController _searchController;
  List<DoctorModel> _providers = DoctorModel.sampleDoctors;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
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

  bool _matchesCategory(DoctorModel provider) {
    if (widget.categoryId == 'all') return true;
    switch (widget.categoryId) {
      case 'nursing':
        return provider.isNurse;
      case 'physio':
        return provider.isTherapist;
      case 'mental':
        return provider.specialty.toLowerCase().contains('mental') ||
            provider.services.any(
              (service) =>
                  service.toLowerCase().contains('mental') ||
                  service.toLowerCase().contains('counsel') ||
                  service.toLowerCase().contains('emotional'),
            );
      case 'child':
        return provider.specialty.toLowerCase().contains('pediatric') ||
            provider.services.any(
              (service) =>
                  service.toLowerCase().contains('child') ||
                  service.toLowerCase().contains('pediatric') ||
                  service.toLowerCase().contains('vaccination'),
            );
      case 'specialist':
        return provider.isDoctorProvider;
      case 'elderly':
        return provider.services.any(
          (service) =>
              service.toLowerCase().contains('elderly') ||
              service.toLowerCase().contains('monitor'),
        );
      case 'recovery':
        return provider.services.any(
          (service) =>
              service.toLowerCase().contains('rehab') ||
              service.toLowerCase().contains('wound') ||
              service.toLowerCase().contains('pain'),
        );
      default:
        final haystack = <String>[
          provider.name,
          provider.specialty,
          provider.providerType,
          provider.about ?? '',
          ...provider.services,
          ...provider.careModes,
        ].join(' ').toLowerCase();
        return widget.keywords.any(haystack.contains);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredProviders = _providers.where((provider) {
      final matchesCategory = _matchesCategory(provider);
      final matchesQuery =
          query.isEmpty ||
          provider.name.toLowerCase().contains(query) ||
          provider.specialty.toLowerCase().contains(query) ||
          provider.services.any(
            (service) => service.toLowerCase().contains(query),
          ) ||
          provider.about?.toLowerCase().contains(query) == true;
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.categoryLabel),
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
                hint: 'Search available professionals...',
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Available Professionals',
                      style: AppTextStyles.h3,
                    ),
                  ),
                  Text(
                    '${filteredProviders.length} found',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const SliverSectionListShimmer(itemCount: 5)
          else if (filteredProviders.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _ProfessionalsEmptyState(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final provider = filteredProviders[index];
                return GestureDetector(
                  onTap: () => context.push('/doctor/detail/${provider.id}'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.doctorBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            provider.isHomeCareProvider
                                ? Icons.health_and_safety_rounded
                                : Icons.local_hospital_rounded,
                            color: AppColors.doctor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                style: AppTextStyles.labelLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.specialty,
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _MiniPill(
                                    label: provider.professionLabel,
                                    color: provider.isDoctorProvider
                                        ? AppColors.doctor
                                        : AppColors.secondary,
                                  ),
                                  ...provider.careModes
                                      .take(2)
                                      .map(
                                        (mode) => _MiniPill(
                                          label: mode,
                                          color: AppColors.primary,
                                          subtle: true,
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
                                    '${provider.rating}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  Text(
                                    ' (${provider.reviewCount})',
                                    style: AppTextStyles.caption,
                                  ),
                                  if (!provider.usesDirectContactOnly) ...[
                                    const Spacer(),
                                    Text(
                                      '\$${provider.consultationFee.toInt()}',
                                      style: AppTextStyles.priceSmall.copyWith(
                                        color: AppColors.doctor,
                                      ),
                                    ),
                                    Text(
                                      provider.isDoctorProvider
                                          ? '/consult'
                                          : '/service',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: filteredProviders.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool subtle;

  const _MiniPill({
    required this.label,
    required this.color,
    this.subtle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: subtle
            ? color.withValues(alpha: 0.1)
            : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: color),
      ),
    );
  }
}

class _ProfessionalsEmptyState extends StatelessWidget {
  const _ProfessionalsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.doctorBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.doctor,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text('No professionals found', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'Try another service or search term.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
