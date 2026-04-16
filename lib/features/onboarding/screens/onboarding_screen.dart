import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
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
  static const String _brandLogoAsset = 'assets/images/logo/logo.png';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingComplete() async {
    await AppPreferences.setHasSeenOnboarding(true);
  }

  Future<void> _goToLogin() async {
    await _markOnboardingComplete();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _handlePrimaryAction(int pagesLength) async {
    if (_currentPage == pagesLength - 1) {
      await _goToLogin();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final pages = [
      _OnboardingData(
        heroType: _OnboardingHeroType.orbit,
        title: l10n.t('onboarding.page1_title'),
        subtitle: l10n.t('onboarding.page1_subtitle'),
        centerAssetPath: _brandLogoAsset,
        centerIcon: Icons.widgets_rounded,
        ctaColor: AppColors.primary,
        backgroundGradient: const LinearGradient(
          colors: [Color(0xFFF4FFF8), Color(0xFFE4FDE9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        ringColor: const Color(0xFFC4F0D4),
        nodes: [
          _OrbitNodeData(
            assetPath: 'assets/icons/food.png',
            alignment: Alignment(0.00, -0.92),
            size: 50,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            tintColor: AppColors.primary,
          ),
          _OrbitNodeData(
            assetPath: 'assets/icons/shopping.png',
            alignment: Alignment(0.64, -0.68),
            size: 50,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            tintColor: AppColors.primary,
          ),
          _OrbitNodeData(
            assetPath: 'assets/icons/doctor.png',
            alignment: Alignment(0.90, -0.12),
            size: 50,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            tintColor: AppColors.primary,
          ),
          _OrbitNodeData(
            assetPath: 'assets/icons/hotel.png',
            alignment: Alignment(0.72, 0.58),
            size: 50,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            tintColor: AppColors.primary,
          ),
          _OrbitNodeData(
            assetPath: 'assets/icons/car.png',
            alignment: Alignment(0.04, 0.92),
            size: 50,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            tintColor: AppColors.primary,
          ),
          _OrbitNodeData(
            assetPath: 'assets/icons/pharmacy.png',
            alignment: Alignment(-0.64, 0.70),
            size: 50,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            tintColor: AppColors.primary,
          ),
          _OrbitNodeData(
            assetPath: 'assets/icons/repair-service.png',
            alignment: Alignment(-0.90, 0.16),
            size: 50,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            tintColor: AppColors.primary,
          ),
          _OrbitNodeData(
            assetPath: 'assets/icons/laundry.png',
            alignment: Alignment(-0.70, -0.58),
            size: 50,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.14),
            tintColor: AppColors.primary,
          ),
        ],
      ),
      _OnboardingData(
        heroType: _OnboardingHeroType.speed,
        title: l10n.t('onboarding.page2_title'),
        subtitle: l10n.t('onboarding.page2_subtitle'),
        heroAssetPath: 'assets/images/onboarding/delivery.png',
        centerIcon: Icons.flash_on_rounded,
        ctaColor: AppColors.primary,
        backgroundGradient: const LinearGradient(
          colors: [Color(0xFFF2FFFB), Color(0xFFDBFCEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _OnboardingData(
        heroType: _OnboardingHeroType.trust,
        title: l10n.t('onboarding.page3_title'),
        subtitle: l10n.t('onboarding.page3_subtitle'),
        heroAssetPath: 'assets/images/onboarding/secure.png',
        centerIcon: Icons.verified_user_rounded,
        ctaColor: AppColors.primary,
        backgroundGradient: const LinearGradient(
          colors: [Color(0xFFF4FFF9), Color(0xFFE9FDF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ];

    final page = pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(gradient: page.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              children: [
                const _TopBar(),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _OnboardingPageContent(page: pages[index]);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 30 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? page.ctaColor
                            : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  text: _currentPage == pages.length - 1
                      ? l10n.t('onboarding.get_started')
                      : l10n.t('onboarding.next'),
                  color: page.ctaColor,
                  onPressed: () => _handlePrimaryAction(pages.length),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _goToLogin,
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.grey,
                      ),
                      children: [
                        TextSpan(text: l10n.t('auth.already_have_account')),
                        TextSpan(
                          text: l10n.t('auth.sign_in'),
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLanguage = languageProvider.currentLanguage;

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<SupportedLanguage>(
        initialValue: currentLanguage,
        onSelected: (language) {
          languageProvider.setLocale(language.locale);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        itemBuilder: (context) {
          return LanguageProvider.supportedLanguages.map((language) {
            final isSelected =
                language.locale.languageCode ==
                currentLanguage.locale.languageCode;
            return PopupMenuItem<SupportedLanguage>(
              value: language,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      language.nativeName,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                color: AppColors.primaryDark,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                currentLanguage.locale.languageCode.toUpperCase(),
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.mediumGrey,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageContent extends StatelessWidget {
  const _OnboardingPageContent({required this.page});

  final _OnboardingData page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 620;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: compact ? 8 : 18),
                switch (page.heroType) {
                  _OnboardingHeroType.orbit => _OrbitHero(
                    ringColor: page.ringColor!,
                    nodes: page.nodes!,
                    centerAssetPath: page.centerAssetPath!,
                    centerIcon: page.centerIcon,
                    compact: compact,
                  ),
                  _OnboardingHeroType.speed => _SpeedHero(
                    compact: compact,
                    icon: page.centerIcon,
                    imageAssetPath: page.heroAssetPath!,
                  ),
                  _OnboardingHeroType.trust => _TrustHero(
                    compact: compact,
                    icon: page.centerIcon,
                    imageAssetPath: page.heroAssetPath!,
                  ),
                },
                SizedBox(height: compact ? 24 : 30),
                Text(
                  page.title,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: compact ? 30 : 34,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  page.subtitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.grey,
                    height: 1.5,
                    fontSize: compact ? 15 : 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: compact ? 10 : 14),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrbitHero extends StatelessWidget {
  const _OrbitHero({
    required this.ringColor,
    required this.nodes,
    required this.centerAssetPath,
    required this.centerIcon,
    required this.compact,
  });

  final Color ringColor;
  final List<_OrbitNodeData> nodes;
  final String centerAssetPath;
  final IconData centerIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 290.0 : 330.0;
    final centerSize = compact ? 112.0 : 126.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  ringColor.withValues(alpha: 0.34),
                  ringColor.withValues(alpha: 0.11),
                  Colors.transparent,
                ],
                stops: const [0.22, 0.62, 1],
              ),
            ),
          ),
          _ring(size * 0.78, ringColor.withValues(alpha: 0.24)),
          _ring(size * 0.58, ringColor.withValues(alpha: 0.36)),
          _ring(size * 0.39, ringColor.withValues(alpha: 0.50)),
          Container(
            width: centerSize,
            height: centerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF4FAFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.dark.withValues(alpha: 0.09),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(compact ? 24 : 28),
              child: Image.asset(
                centerAssetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  centerIcon,
                  color: AppColors.dark,
                  size: compact ? 48 : 56,
                ),
              ),
            ),
          ),
          ...nodes.map(_nodeWidget),
        ],
      ),
    );
  }

  Widget _ring(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.2),
      ),
    );
  }

  Widget _nodeWidget(_OrbitNodeData node) {
    return Align(
      alignment: node.alignment,
      child: Container(
        width: node.size,
        height: node.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: node.backgroundColor,
          border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(node.size * 0.24),
          child: Image.asset(
            node.assetPath,
            fit: BoxFit.contain,
            color: node.tintColor,
            colorBlendMode: node.tintColor == null ? null : BlendMode.srcIn,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.image_not_supported_outlined, color: AppColors.grey),
          ),
        ),
      ),
    );
  }
}

class _SpeedHero extends StatelessWidget {
  const _SpeedHero({
    required this.compact,
    required this.icon,
    required this.imageAssetPath,
  });

  final bool compact;
  final IconData icon;
  final String imageAssetPath;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 290.0 : 330.0;

    return SizedBox(
      width: width,
      child: Image.asset(
        imageAssetPath,
        height: compact ? 198 : 232,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(icon, color: AppColors.primaryDark, size: compact ? 54 : 62),
      ),
    );
  }
}

class _TrustHero extends StatelessWidget {
  const _TrustHero({
    required this.compact,
    required this.icon,
    required this.imageAssetPath,
  });

  final bool compact;
  final IconData icon;
  final String imageAssetPath;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 290.0 : 330.0;

    return SizedBox(
      width: width,
      child: Image.asset(
        imageAssetPath,
        height: compact ? 198 : 232,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(icon, color: AppColors.primaryDark, size: compact ? 54 : 62),
      ),
    );
  }
}

class _OnboardingData {
  const _OnboardingData({
    required this.heroType,
    required this.title,
    required this.subtitle,
    this.heroAssetPath,
    required this.centerIcon,
    required this.ctaColor,
    required this.backgroundGradient,
    this.centerAssetPath,
    this.ringColor,
    this.nodes,
  });

  final _OnboardingHeroType heroType;
  final String title;
  final String subtitle;
  final String? heroAssetPath;
  final IconData centerIcon;
  final Color ctaColor;
  final LinearGradient backgroundGradient;
  final String? centerAssetPath;
  final Color? ringColor;
  final List<_OrbitNodeData>? nodes;
}

class _OrbitNodeData {
  const _OrbitNodeData({
    required this.assetPath,
    required this.alignment,
    required this.size,
    required this.backgroundColor,
    this.tintColor,
  });

  final String assetPath;
  final Alignment alignment;
  final double size;
  final Color backgroundColor;
  final Color? tintColor;
}

enum _OnboardingHeroType { orbit, speed, trust }
