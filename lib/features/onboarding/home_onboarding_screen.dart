import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/storage/app_preferences.dart';
import '../../../core/widgets/app_button.dart';

class HomeOnboardingScreen extends StatefulWidget {
  const HomeOnboardingScreen({super.key});

  @override
  State<HomeOnboardingScreen> createState() => _HomeOnboardingScreenState();
}

class _HomeOnboardingScreenState extends State<HomeOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _backgroundGradient = LinearGradient(
    colors: [Color(0xFFF2FFFB), Color(0xFFDBFCEB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<_HomeServiceData> _services = [
    _HomeServiceData(
      assetPath: 'assets/icons/home_services/cleaning.png',
      fallbackIcon: Icons.cleaning_services_rounded,
      label: 'Ménage',
    ),
    _HomeServiceData(
      assetPath: 'assets/icons/home_services/electrician.png',
      fallbackIcon: Icons.electrical_services_rounded,
      label: 'Électricien',
    ),
    _HomeServiceData(
      assetPath: 'assets/icons/home_services/plumber.png',
      fallbackIcon: Icons.plumbing_rounded,
      label: 'Plombier',
    ),
    _HomeServiceData(
      assetPath: 'assets/icons/home_services/ac.png',
      fallbackIcon: Icons.ac_unit_rounded,
      label: 'Climatisation',
    ),
    _HomeServiceData(
      assetPath: 'assets/icons/home_services/carpenter.png',
      fallbackIcon: Icons.handyman_rounded,
      label: 'Menuisier',
    ),
    _HomeServiceData(
      assetPath: 'assets/icons/home_services/beauty.png',
      fallbackIcon: Icons.spa_rounded,
      label: 'Beauté',
    ),
  ];

  // Page 2 — étapes de réservation
  static const List<_StepCardData> _bookingSteps = [
    _StepCardData(
      icon: Icons.touch_app_rounded,
      label: 'Choisis ton service',
      step: '1',
    ),
    _StepCardData(
      icon: Icons.calendar_month_rounded,
      label: 'Sélectionne une date',
      step: '2',
    ),
    _StepCardData(
      icon: Icons.check_circle_rounded,
      label: 'Un pro arrive chez toi',
      step: '3',
    ),
  ];

  // Page 3 — garanties
  static const List<_StepCardData> _trustItems = [
    _StepCardData(
      icon: Icons.verified_user_rounded,
      label: 'Prestataires vérifiés',
      step: '✓',
    ),
    _StepCardData(
      icon: Icons.price_check_rounded,
      label: 'Prix affichés avant',
      step: '✓',
    ),
    _StepCardData(
      icon: Icons.support_agent_rounded,
      label: 'Support 7j/7',
      step: '✓',
    ),
  ];

  Future<void> _markSeen() async =>
      AppPreferences.setHasSeenHomeOnboarding(true);

  Future<void> _goToHome() async {
    await _markSeen();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _handleNext(int total) async {
    if (_currentPage == total - 1) {
      await _goToHome();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final pages = [
      _HomeOnboardingData(
        heroType: _HomeHeroType.orbit,
        title: l10n.t('home_onboarding.page1_title'),
        subtitle: l10n.t('home_onboarding.page1_subtitle'),
      ),
      _HomeOnboardingData(
        heroType: _HomeHeroType.booking,
        title: l10n.t('home_onboarding.page2_title'),
        subtitle: l10n.t('home_onboarding.page2_subtitle'),
      ),
      _HomeOnboardingData(
        heroType: _HomeHeroType.trust,
        title: l10n.t('home_onboarding.page3_title'),
        subtitle: l10n.t('home_onboarding.page3_subtitle'),
      ),
    ];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(gradient: _backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              children: [
                // ── Top bar ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LanguagePicker(),
                    TextButton(
                      onPressed: _goToHome,
                      child: Text(
                        l10n.t('onboarding.skip'),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ── Pages ─────────────────────────────────────────────────
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) => _HomeOnboardingPageContent(
                      page: pages[index],
                      services: _services,
                      bookingSteps: _bookingSteps,
                      trustItems: _trustItems,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Dots ──────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 30 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.primary
                            : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── CTA ───────────────────────────────────────────────────
                AppButton(
                  text: _currentPage == pages.length - 1
                      ? l10n.t('home_onboarding.get_started')
                      : l10n.t('onboarding.next'),
                  color: AppColors.primary,
                  onPressed: () => _handleNext(pages.length),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LANGUAGE PICKER
// ─────────────────────────────────────────────────────────────────────────────

class _LanguagePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLanguage = languageProvider.currentLanguage;
    return PopupMenuButton<SupportedLanguage>(
      initialValue: currentLanguage,
      onSelected: (lang) => languageProvider.setLocale(lang.locale),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => LanguageProvider.supportedLanguages.map((lang) {
        final selected =
            lang.locale.languageCode == currentLanguage.locale.languageCode;
        return PopupMenuItem<SupportedLanguage>(
          value: lang,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lang.nativeName,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.dark,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
            ],
          ),
        );
      }).toList(),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE CONTENT
// ─────────────────────────────────────────────────────────────────────────────

class _HomeOnboardingPageContent extends StatelessWidget {
  const _HomeOnboardingPageContent({
    required this.page,
    required this.services,
    required this.bookingSteps,
    required this.trustItems,
  });

  final _HomeOnboardingData page;
  final List<_HomeServiceData> services;
  final List<_StepCardData> bookingSteps;
  final List<_StepCardData> trustItems;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 580;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: compact ? 8 : 20),

                switch (page.heroType) {
                  _HomeHeroType.orbit => _HomeOrbitHero(
                    services: services,
                    compact: compact,
                  ),
                  _HomeHeroType.booking => _StepsHero(
                    items: bookingSteps,
                    compact: compact,
                    accentColor: AppColors.primary,
                    heroIcon: Icons.calendar_month_rounded,
                  ),
                  _HomeHeroType.trust => _StepsHero(
                    items: trustItems,
                    compact: compact,
                    accentColor: const Color(0xFF2C7A4B),
                    heroIcon: Icons.verified_user_rounded,
                  ),
                },

                SizedBox(height: compact ? 24 : 32),

                Text(
                  page.title,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: compact ? 28 : 32,
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

                SizedBox(height: compact ? 10 : 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO ORBIT — page 1
// ─────────────────────────────────────────────────────────────────────────────

class _HomeOrbitHero extends StatelessWidget {
  const _HomeOrbitHero({required this.services, required this.compact});
  final List<_HomeServiceData> services;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final nodeSize = compact ? 50.0 : 56.0;
    final orbitRadius = compact ? 110.0 : 124.0;
    final totalSize = orbitRadius * 2 + nodeSize;
    final centerSize = compact ? 96.0 : 110.0;
    const ringColor = Color(0xFFC4F0D4);
    final count = services.length.clamp(1, 8);
    final angleStep = (2 * math.pi) / count;
    const startAngle = -math.pi / 2;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ringColor.withValues(alpha: 0.30),
                    ringColor.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.20, 0.55, 1.0],
                ),
              ),
            ),
          ),
          _ring(
            totalSize,
            orbitRadius * 1.80,
            ringColor.withValues(alpha: 0.20),
          ),
          _ring(
            totalSize,
            orbitRadius * 1.40,
            ringColor.withValues(alpha: 0.30),
          ),
          _ring(
            totalSize,
            orbitRadius * 1.00,
            ringColor.withValues(alpha: 0.45),
          ),
          ...List.generate(count, (i) {
            final angle = startAngle + i * angleStep;
            final cx = totalSize / 2 + orbitRadius * math.cos(angle);
            final cy = totalSize / 2 + orbitRadius * math.sin(angle);
            return Positioned(
              left: cx - nodeSize / 2,
              top: cy - nodeSize / 2,
              child: _ServiceNode(service: services[i], size: nodeSize),
            );
          }),
          Positioned(
            left: (totalSize - centerSize) / 2,
            top: (totalSize - centerSize) / 2,
            child: Container(
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
                    color: AppColors.dark.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.home_repair_service_rounded,
                color: AppColors.primary,
                size: compact ? 42 : 48,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _ring(double stackSize, double diameter, Color color) =>
      Positioned(
        left: (stackSize - diameter) / 2,
        top: (stackSize - diameter) / 2,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.2),
          ),
        ),
      );
}

class _ServiceNode extends StatelessWidget {
  const _ServiceNode({required this.service, required this.size});
  final _HomeServiceData service;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.15),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.dark.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: EdgeInsets.all(size * 0.22),
      child: Image.asset(
        service.assetPath,
        fit: BoxFit.contain,
        color: AppColors.primary,
        colorBlendMode: BlendMode.srcIn,
        errorBuilder: (_, __, ___) => Icon(
          service.fallbackIcon,
          color: AppColors.primary,
          size: size * 0.46,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO STEPS — pages 2 & 3
// Design : grande icône centrée en haut + liste de lignes icon+label en dessous
// ─────────────────────────────────────────────────────────────────────────────

class _StepsHero extends StatelessWidget {
  const _StepsHero({
    required this.items,
    required this.compact,
    required this.accentColor,
    required this.heroIcon,
  });

  final List<_StepCardData> items;
  final bool compact;
  final Color accentColor;
  final IconData heroIcon;

  @override
  Widget build(BuildContext context) {
    final heroBoxSize = compact ? 100.0 : 116.0;
    final gap = compact ? 10.0 : 12.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Grande icône centrale ──────────────────────────────────────
          Container(
            width: heroBoxSize,
            height: heroBoxSize,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(heroIcon, color: accentColor, size: compact ? 48 : 56),
          ),

          SizedBox(height: compact ? 20 : 24),

          // ── Séparateur ────────────────────────────────────────────────
          Divider(color: AppColors.lightGrey, height: 1),

          SizedBox(height: compact ? 16 : 18),

          // ── Lignes items ──────────────────────────────────────────────
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: i < items.length - 1 ? gap : 0),
              child: Row(
                children: [
                  // Icône dans un petit carré
                  Container(
                    width: compact ? 36 : 40,
                    height: compact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      color: accentColor,
                      size: compact ? 18 : 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Texte
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 14 : 15,
                      ),
                    ),
                  ),
                  // Pastille numéro/check
                  Text(
                    item.step,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 15 : 16,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum _HomeHeroType { orbit, booking, trust }

class _HomeOnboardingData {
  const _HomeOnboardingData({
    required this.heroType,
    required this.title,
    required this.subtitle,
  });
  final _HomeHeroType heroType;
  final String title;
  final String subtitle;
}

class _HomeServiceData {
  const _HomeServiceData({
    required this.assetPath,
    required this.fallbackIcon,
    required this.label,
  });
  final String assetPath;
  final IconData fallbackIcon;
  final String label;
}

class _StepCardData {
  const _StepCardData({
    required this.icon,
    required this.label,
    required this.step,
  });
  final IconData icon;
  final String label;
  final String step;
}
