import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/models/models.dart';

class DoctorScreen extends StatefulWidget {
  const DoctorScreen({super.key});
  @override
  State<DoctorScreen> createState() => _DoctorScreenState();
}

class _DoctorScreenState extends State<DoctorScreen> {
  int _selectedSpecialty = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<DoctorModel> _doctors = DoctorModel.sampleDoctors;
  bool _isLoading = true;
  final _specialties = [
    'All',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Orthopedic',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final response = await ApiClient.get('/catalog/doctors');
      final items = (response as List)
          .map(
            (item) =>
                DoctorModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _doctors = items.isEmpty ? DoctorModel.sampleDoctors : items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final allDoctors = _doctors;
    final filteredDoctors = allDoctors.where((doctor) {
      final matchesSpecialty =
          _selectedSpecialty == 0 ||
          doctor.specialty == _specialties[_selectedSpecialty];
      final matchesQuery =
          query.isEmpty ||
          doctor.name.toLowerCase().contains(query) ||
          doctor.specialty.toLowerCase().contains(query) ||
          doctor.services.any(
            (service) => service.toLowerCase().contains(query),
          );
      return matchesSpecialty && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find a Doctor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 22),
            onPressed: () => context.push('/doctor/appointments'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppSearchBar(
                hint: 'Search doctors, specialties...',
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          // Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.doctor, Color(0xFF5DADE2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book an Appointment',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'With top specialists near you',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Book Now',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.doctor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: AppColors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Specialties
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: const [
                  _SpecIcon(Icons.favorite_rounded, 'Heart', AppColors.accent),
                  _SpecIcon(
                    Icons.remove_red_eye_rounded,
                    'Eye',
                    AppColors.secondary,
                  ),
                  _SpecIcon(
                    Icons.psychology_rounded,
                    'Brain',
                    AppColors.primary,
                  ),
                  _SpecIcon(Icons.child_care_rounded, 'Child', AppColors.food),
                  _SpecIcon(
                    Icons.accessibility_new_rounded,
                    'Bone',
                    AppColors.pharmacy,
                  ),
                  _SpecIcon(Icons.face_rounded, 'Skin', AppColors.laundry),
                ],
              ),
            ),
          ),
          // Category filter
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _specialties.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sel = _selectedSpecialty == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSpecialty = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.doctor : AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: sel
                            ? null
                            : Border.all(color: AppColors.lightGrey),
                      ),
                      child: Text(
                        _specialties[index],
                        style: AppTextStyles.labelMedium.copyWith(
                          color: sel ? AppColors.white : AppColors.dark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Doctors list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Top Doctors', style: AppTextStyles.h3),
            ),
          ),
          if (_isLoading)
            const SliverSectionListShimmer(itemCount: 5)
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final d = filteredDoctors[index];
                return GestureDetector(
                  onTap: () => context.push('/doctor/detail/${d.id}'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: AppColors.doctorBg,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.doctor,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      d.name,
                                      style: AppTextStyles.labelLarge,
                                    ),
                                  ),
                                  if (d.isAvailable)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${d.specialty} • ${d.experience}',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${d.rating}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.dark,
                                    ),
                                  ),
                                  Text(
                                    ' (${d.reviewCount})',
                                    style: AppTextStyles.caption,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '\$${d.consultationFee.toInt()}',
                                    style: AppTextStyles.priceSmall.copyWith(
                                      color: AppColors.doctor,
                                    ),
                                  ),
                                  Text('/visit', style: AppTextStyles.caption),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: filteredDoctors.length),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SpecIcon extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;
  const _SpecIcon(this.icon, this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.dark),
          ),
        ],
      ),
    );
  }
}
