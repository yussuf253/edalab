import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../core/router/pro_route_paths.dart';

class ProOnboardingScreen extends StatefulWidget {
  const ProOnboardingScreen({super.key});

  @override
  State<ProOnboardingScreen> createState() => _ProOnboardingScreenState();
}

class _ProOnboardingScreenState extends State<ProOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const String _brandLogoAsset = 'assets/images/logo/logo.png';

  static const List<_ProOnboardingPageData> _pages = [
    _ProOnboardingPageData(
      heroType: _ProOnboardingHeroType.orbit,
      title: 'All Your Pro Operations, In One Place',
      subtitle:
          'Manage appointments, service jobs, deliveries, and orders from one polished workspace built for fast teams.',
      centerAssetPath: _brandLogoAsset,
      centerIcon: Icons.health_and_safety_rounded,
      ctaColor: AppColors.primary,
      backgroundGradient: LinearGradient(
        colors: [Color(0xFFF6FFF9), Color(0xFFE8FEEB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      ringColor: Color(0xFFBFEFD0),
      nodes: [
        _OrbitNodeData(
          assetPath: 'assets/icons/doctor.png',
          alignment: Alignment(-0.82, -0.50),
          size: 58,
          backgroundColor: Color(0xFFE4F8EC),
        ),
        _OrbitNodeData(
          assetPath: 'assets/icons/pharmacy.png',
          alignment: Alignment(0.82, -0.56),
          size: 56,
          backgroundColor: Color(0xFFE6F1FF),
        ),
        _OrbitNodeData(
          assetPath: 'assets/icons/orders.png',
          alignment: Alignment(0.82, 0.54),
          size: 62,
          backgroundColor: Color(0xFFFFF3DD),
        ),
        _OrbitNodeData(
          assetPath: 'assets/icons/messages.png',
          alignment: Alignment(-0.82, 0.52),
          size: 60,
          backgroundColor: Color(0xFFEAEDFF),
        ),
      ],
    ),
    _ProOnboardingPageData(
      heroType: _ProOnboardingHeroType.flow,
      title: 'Accept Work Instantly And Keep Flowing',
      subtitle:
          'Update availability, claim requests, and move jobs from queue to completion with fewer taps and smarter context.',
      centerIcon: Icons.bolt_rounded,
      ctaColor: AppColors.primary,
      backgroundGradient: LinearGradient(
        colors: [Color(0xFFF4FFFC), Color(0xFFDDFBF0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    _ProOnboardingPageData(
      heroType: _ProOnboardingHeroType.insights,
      title: 'Insight, Control, And Clear Next Actions',
      subtitle:
          'See performance snapshots, urgent priorities, and customer activity in real time so nothing slips through.',
      centerIcon: Icons.insights_rounded,
      ctaColor: Color(0xFF3759C8),
      backgroundGradient: LinearGradient(
        colors: [Color(0xFFF5F9FF), Color(0xFFE6EEFF)],
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

  Future<void> _markOnboardingDone() async {
    await AppPreferences.setHasSeenProOnboarding(true);
  }

  Future<void> _finishOnboarding() async {
    await _markOnboardingDone();
    if (!mounted) return;
    context.go(ProRoutePaths.entry);
  }

  Future<void> _goToLogin() async {
    await _markOnboardingDone();
    if (!mounted) return;
    context.go(ProRoutePaths.login);
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentPage == _pages.length - 1) {
      await _finishOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(gradient: page.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              children: [
                _TopBar(onSkip: _finishOnboarding),
                const SizedBox(height: 8),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _OnboardingPageContent(page: _pages[index]);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
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
                  text: _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Continue',
                  color: page.ctaColor,
                  onPressed: _handlePrimaryAction,
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
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in',
                          style: TextStyle(
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
  const _TopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EdaLab Pro',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onSkip,
          child: Text(
            'Skip',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.mediumGrey,
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageContent extends StatelessWidget {
  const _OnboardingPageContent({required this.page});

  final _ProOnboardingPageData page;

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
                  _ProOnboardingHeroType.orbit => _OrbitHero(
                    ringColor: page.ringColor!,
                    nodes: page.nodes!,
                    centerAssetPath: page.centerAssetPath!,
                    centerIcon: page.centerIcon,
                    compact: compact,
                  ),
                  _ProOnboardingHeroType.flow => _FlowHero(
                    compact: compact,
                    icon: page.centerIcon,
                  ),
                  _ProOnboardingHeroType.insights => _InsightsHero(
                    compact: compact,
                    icon: page.centerIcon,
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
                SizedBox(height: compact ? 8 : 12),
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
                  ringColor.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.22, 0.62, 1],
              ),
            ),
          ),
          _ring(size * 0.78, ringColor.withValues(alpha: 0.26)),
          _ring(size * 0.58, ringColor.withValues(alpha: 0.38)),
          _ring(size * 0.39, ringColor.withValues(alpha: 0.52)),
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
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.image_not_supported_outlined, color: AppColors.grey),
          ),
        ),
      ),
    );
  }
}

class _FlowHero extends StatelessWidget {
  const _FlowHero({required this.compact, required this.icon});

  final bool compact;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 290.0 : 330.0;
    final padding = compact ? 16.0 : 20.0;

    return Container(
      width: width,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFEDFFF6), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFC8F2DD)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          _FlowStep(
            label: 'Queued',
            detail: '8 incoming requests',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF2A9E64),
          ),
          const _FlowConnector(),
          _FlowStep(
            label: 'Assigned',
            detail: 'Auto-routed by availability',
            icon: icon,
            color: const Color(0xFF2A7DD2),
          ),
          const _FlowConnector(),
          _FlowStep(
            label: 'Completed',
            detail: 'Customers notified instantly',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF19844D),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowConnector extends StatelessWidget {
  const _FlowConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.mediumGrey,
      ),
    );
  }
}

class _InsightsHero extends StatelessWidget {
  const _InsightsHero({required this.compact, required this.icon});

  final bool compact;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 290.0 : 330.0;
    final chartHeight = compact ? 96.0 : 112.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF2F7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD5E4FF)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F0FF),
                ),
                child: Icon(icon, color: Color(0xFF3A62C8), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Live Insights',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _InsightPill(label: 'Urgent 3'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _InsightBar(height: 0.42, color: Color(0xFFCEE0FF)),
                SizedBox(width: 8),
                _InsightBar(height: 0.68, color: Color(0xFFAEC9FF)),
                SizedBox(width: 8),
                _InsightBar(height: 0.90, color: Color(0xFF6E98F7)),
                SizedBox(width: 8),
                _InsightBar(height: 0.64, color: Color(0xFFAEC9FF)),
                SizedBox(width: 8),
                _InsightBar(height: 0.78, color: Color(0xFF88AEFF)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(
                child: _StatTile(label: 'Response', value: '4.2m'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatTile(label: 'SLA', value: '96%'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _StatTile(label: 'Resolved', value: '41'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InsightBar extends StatelessWidget {
  const _InsightBar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FractionallySizedBox(
        heightFactor: height,
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  const _InsightPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelMedium.copyWith(
          color: const Color(0xFF3D63C7),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class _ProOnboardingPageData {
  const _ProOnboardingPageData({
    required this.heroType,
    required this.title,
    required this.subtitle,
    required this.centerIcon,
    required this.ctaColor,
    required this.backgroundGradient,
    this.centerAssetPath,
    this.ringColor,
    this.nodes,
  });

  final _ProOnboardingHeroType heroType;
  final String title;
  final String subtitle;
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
  });

  final String assetPath;
  final Alignment alignment;
  final double size;
  final Color backgroundColor;
}

enum _ProOnboardingHeroType { orbit, flow, insights }
