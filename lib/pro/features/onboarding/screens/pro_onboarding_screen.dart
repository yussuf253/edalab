import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/app_button.dart';

class ProOnboardingScreen extends StatefulWidget {
  const ProOnboardingScreen({super.key});

  @override
  State<ProOnboardingScreen> createState() => _ProOnboardingScreenState();
}

class _ProOnboardingScreenState extends State<ProOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_ProOnboardingPageData> _pages = [
    _ProOnboardingPageData(
      icon: Icons.dashboard_customize_outlined,
      title: 'Your business workspace in EdaLab Pro',
      subtitle:
          'EdaLab Pro gives stores, providers, doctors, couriers, and riders one place to manage incoming work, customer requests, and day-to-day operations.',
      gradient: LinearGradient(
        colors: [AppColors.primaryDark, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _ProOnboardingPageData(
      icon: Icons.hub_outlined,
      title: 'Handle live work faster',
      subtitle:
          'Open queues, manage availability, update schedules, claim rides or deliveries, and respond to customers from tools built for pro workflows.',
      gradient: LinearGradient(
        colors: [AppColors.info, AppColors.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _ProOnboardingPageData(
      icon: Icons.insights_outlined,
      title: 'Stay on top of what matters',
      subtitle:
          'Track performance, spot urgent requests, and follow real-time status so you always know what needs action next in your pro app.',
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    await AppPreferences.setHasSeenProOnboarding(true);
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _complete, child: const Text('Skip')),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final compactHeight = constraints.maxHeight < 560;
                        final heroHeight = compactHeight ? 210.0 : 280.0;
                        final topSpacing = compactHeight ? 8.0 : 20.0;
                        final titleSpacing = compactHeight ? 20.0 : 32.0;
                        final bodySpacing = compactHeight ? 10.0 : 14.0;
                        final tagsSpacing = compactHeight ? 16.0 : 24.0;

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: topSpacing),
                                FadeInDown(
                                  duration: const Duration(milliseconds: 320),
                                  child: Container(
                                    height: heroHeight,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: item.gradient,
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.16,
                                          ),
                                          blurRadius: 28,
                                          offset: const Offset(0, 14),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: -10,
                                          right: -20,
                                          child: CircleAvatar(
                                            radius: compactHeight ? 56 : 70,
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.10),
                                          ),
                                        ),
                                        Positioned(
                                          left: -30,
                                          bottom: -30,
                                          child: CircleAvatar(
                                            radius: compactHeight ? 64 : 80,
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.08),
                                          ),
                                        ),
                                        Center(
                                          child: Container(
                                            width: compactHeight ? 96 : 112,
                                            height: compactHeight ? 96 : 112,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(32),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.20,
                                                ),
                                              ),
                                            ),
                                            child: Icon(
                                              item.icon,
                                              color: Colors.white,
                                              size: compactHeight ? 44 : 52,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: titleSpacing),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 320),
                                  child: Text(
                                    item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.dark,
                                        ),
                                  ),
                                ),
                                SizedBox(height: bodySpacing),
                                FadeInUp(
                                  delay: const Duration(milliseconds: 80),
                                  duration: const Duration(milliseconds: 320),
                                  child: Text(
                                    item.subtitle,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: AppColors.grey,
                                          height: 1.5,
                                        ),
                                  ),
                                ),
                                SizedBox(height: tagsSpacing),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _FeatureTag(
                                      label: _currentPage == 0
                                          ? 'Queues'
                                          : _currentPage == 1
                                          ? 'Scheduling'
                                          : 'Insights',
                                    ),
                                    _FeatureTag(
                                      label: _currentPage == 0
                                          ? 'Module controls'
                                          : _currentPage == 1
                                          ? 'Dispatch'
                                          : 'Highlighted requests',
                                    ),
                                    _FeatureTag(
                                      label: _currentPage == 0
                                          ? 'Operator tools'
                                          : _currentPage == 1
                                          ? 'Live actions'
                                          : 'Recent activity',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: _currentPage == _pages.length - 1
                    ? 'Enter Pro Workspace'
                    : 'Next',
                onPressed: () async {
                  if (_currentPage == _pages.length - 1) {
                    await _complete();
                    return;
                  }

                  await _pageController.nextPage(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeInOut,
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                page.title,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.mediumGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTag extends StatelessWidget {
  const _FeatureTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProOnboardingPageData {
  const _ProOnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
}
