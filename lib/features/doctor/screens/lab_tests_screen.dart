import 'package:edalab/core/widgets/app_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/cart_model.dart';
import '../../../core/models/lab_test_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_button.dart';

class LabTestsScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryLabel;
  const LabTestsScreen({super.key, this.categoryId, this.categoryLabel});

  @override
  State<LabTestsScreen> createState() => _LabTestsScreenState();
}

class _LabTestsScreenState extends State<LabTestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<LabTestModel> _tests = [];
  bool _isLoading = true;
  late String? _categoryId;
  late String? _categoryLabel;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId;
    _categoryLabel = widget.categoryLabel;
    _loadTests();
  }

  Future<void> _loadTests() async {
    try {
      final response = await ApiClient.get(
        '/catalog/health-services/tests?categoryId=$_categoryId',
        forceRefresh: true,
      );

      final items = (response as List)
          .map(
            (item) =>
                LabTestModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _tests = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<LabTestModel> get _filteredTests {
    if (_searchQuery.isEmpty) return _tests;
    return _tests.where((test) {
      return test.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          test.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showTestDetails(LabTestModel test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TestDetailsBottomSheet(test: test),
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
    final filteredTests = _filteredTests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_categoryLabel ?? l10n.t('doctor.lab_tests')),
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
                hint: l10n.t('doctor.search_tests_hint'),
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
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
                        height: 120,
                        radius: 16,
                      ),
                      SizedBox(height: 12),
                      ShimmerBlock(
                        width: double.infinity,
                        height: 120,
                        radius: 16,
                      ),
                      SizedBox(height: 12),
                      ShimmerBlock(
                        width: double.infinity,
                        height: 120,
                        radius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (filteredTests.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    l10n.t('doctor.no_tests_found'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final test = filteredTests[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TestCard(
                      test: test,
                      onTap: () => _showTestDetails(test),
                    ),
                  );
                }, childCount: filteredTests.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final LabTestModel test;
  final VoidCallback onTap;

  const _TestCard({required this.test, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        test.originalPrice != null && test.originalPrice! > test.price;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.science_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    test.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    test.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                      height: 1.4,
                    ),
                  ),
                  if (test.durationLabel != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          test.durationLabel!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${test.price.toStringAsFixed(0)} DZD',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${test.originalPrice!.toStringAsFixed(0)} DZD',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TestDetailsBottomSheet extends StatelessWidget {
  final LabTestModel test;

  const _TestDetailsBottomSheet({required this.test});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasDiscount =
        test.originalPrice != null && test.originalPrice! > test.price;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.science_rounded,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  test.name,
                                  style: AppTextStyles.h3.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  test.description,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (test.fullDescription != null) ...[
                        Text(
                          l10n.t('doctor.about_test'),
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          test.fullDescription!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.6,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (test.preparationInstructions != null) ...[
                        Text(
                          l10n.t('doctor.preparation_instructions'),
                          style: AppTextStyles.h4.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          test.preparationInstructions!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.6,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (test.sampleType != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.medical_services_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.t('doctor.sample_type'),
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          test.sampleType!,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('doctor.price'),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${test.price.toStringAsFixed(0)} DZD',
                                      style: AppTextStyles.h4.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    if (hasDiscount) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${test.originalPrice!.toStringAsFixed(0)} DZD',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (test.durationLabel != null)
                            Column(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: AppColors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  test.durationLabel!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Add to Cart bottom bar
              Container(
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
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('doctor.price'),
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'DJF ${test.price.toStringAsFixed(0)}',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          text: 'Add to Cart',
                          icon: Icons.shopping_cart_outlined,
                          color: AppColors.primary,
                          onPressed: () {
                            final cart = context.read<CartProvider>();
                            cart.addItem(
                              CartItem(
                                id: test.id,
                                name: test.name,
                                price: test.price,
                                moduleType: 'doctor',
                                description: test.description,
                                imageUrl: test.imageUrl,
                              ),
                            );
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${test.name} added to cart'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
