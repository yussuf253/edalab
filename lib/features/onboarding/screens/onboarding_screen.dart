import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await AppPreferences.setHasSeenOnboarding(true);
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      _OnboardingData(
        icon: Icons.all_inclusive_rounded,
        title: l10n.t('onboarding.page1_title'),
        subtitle: l10n.t('onboarding.page1_subtitle'),
        gradient: AppColors.primaryGradient,
        bgColor: const Color(0xFFF0EFFF),
      ),
      _OnboardingData(
        icon: Icons.flash_on_rounded,
        title: l10n.t('onboarding.page2_title'),
        subtitle: l10n.t('onboarding.page2_subtitle'),
        gradient: AppColors.secondaryGradient,
        bgColor: const Color(0xFFE6FAFF),
      ),
      _OnboardingData(
        icon: Icons.verified_user_rounded,
        title: l10n.t('onboarding.page3_title'),
        subtitle: l10n.t('onboarding.page3_subtitle'),
        gradient: AppColors.accentGradient,
        bgColor: const Color(0xFFFFF0F0),
      ),
    ];
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    l10n.t('onboarding.skip'),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ),
              ),
            ),
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon container
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: page.gradient,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Icon(
                              page.icon,
                              size: 80,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),
                        // Title
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 600),
                          child: Text(
                            page.title,
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 34,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle
                        FadeInUp(
                          delay: const Duration(milliseconds: 400),
                          duration: const Duration(milliseconds: 600),
                          child: Text(
                            page.subtitle,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.grey,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Indicators & Button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.lightGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Next / Get Started button
                  AppButton(
                    text: _currentPage == pages.length - 1
                        ? l10n.t('onboarding.get_started')
                        : l10n.t('onboarding.next'),
                    onPressed: () async {
                      if (_currentPage == pages.length - 1) {
                        await _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color bgColor;

  _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.bgColor,
  });
}
