import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/app_colors.dart';

class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkCard : const Color(0xFFE8EBF5),
      highlightColor: isDark ? AppColors.darkSurface : AppColors.white,
      child: child,
    );
  }
}

class ShimmerBlock extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 14,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;
  final EdgeInsetsGeometry? margin;

  const ShimmerCircle({super.key, required this.size, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

class ModuleFeedShimmer extends StatelessWidget {
  final Color accentColor;
  final bool showSearch;
  final bool showBanner;
  final bool showRoundCategories;
  final bool showFilterChips;
  final bool isGrid;
  final int itemCount;

  const ModuleFeedShimmer({
    super.key,
    required this.accentColor,
    this.showSearch = false,
    this.showBanner = false,
    this.showRoundCategories = false,
    this.showFilterChips = false,
    this.isGrid = false,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          if (showSearch)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: ShimmerBlock(width: double.infinity, height: 56),
              ),
            ),
          if (showBanner)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  height: 132,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShimmerBlock(width: 150, height: 20),
                            SizedBox(height: 10),
                            ShimmerBlock(width: 210, height: 12, radius: 10),
                            SizedBox(height: 8),
                            ShimmerBlock(width: 170, height: 12, radius: 10),
                            SizedBox(height: 18),
                            ShimmerBlock(width: 100, height: 34, radius: 12),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      ShimmerBlock(width: 74, height: 74, radius: 22),
                    ],
                  ),
                ),
              ),
            ),
          if (showRoundCategories)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _ShimmerCategoryItem(),
                      _ShimmerCategoryItem(),
                      _ShimmerCategoryItem(),
                      _ShimmerCategoryItem(),
                      _ShimmerCategoryItem(),
                    ],
                  ),
                ),
              ),
            ),
          if (showFilterChips)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ShimmerBlock(width: 92, height: 38, radius: 999),
                      SizedBox(width: 10),
                      ShimmerBlock(width: 84, height: 38, radius: 999),
                      SizedBox(width: 10),
                      ShimmerBlock(width: 118, height: 38, radius: 999),
                      SizedBox(width: 10),
                      ShimmerBlock(width: 96, height: 38, radius: 999),
                    ],
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  ShimmerBlock(width: 140, height: 22),
                  Spacer(),
                  ShimmerBlock(width: 64, height: 14, radius: 10),
                ],
              ),
            ),
          ),
          if (isGrid)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const _ShimmerGridCard(),
                  childCount: itemCount,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.66,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const _ShimmerListCard(),
                childCount: itemCount,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class SliverSectionListShimmer extends StatelessWidget {
  final int itemCount;

  const SliverSectionListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => const AppShimmer(child: _ShimmerListCard()),
        childCount: itemCount,
      ),
    );
  }
}

class SliverSectionGridShimmer extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const SliverSectionGridShimmer({
    super.key,
    this.itemCount = 6,
    this.childAspectRatio = 0.66,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const AppShimmer(child: _ShimmerGridCard()),
          childCount: itemCount,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: childAspectRatio,
        ),
      ),
    );
  }
}

class InlineSectionListShimmer extends StatelessWidget {
  final int itemCount;

  const InlineSectionListShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(itemCount, (index) => const _ShimmerListCard()),
      ),
    );
  }
}

class InlineSectionGridShimmer extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;

  const InlineSectionGridShimmer({
    super.key,
    this.itemCount = 6,
    this.childAspectRatio = 0.66,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const _ShimmerGridCard(),
      ),
    );
  }
}

class DetailPageShimmer extends StatelessWidget {
  final Color accentColor;
  final bool showHero;

  const DetailPageShimmer({
    super.key,
    required this.accentColor,
    this.showHero = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        child: DetailContentShimmer(
          accentColor: accentColor,
          showHero: showHero,
        ),
      ),
    );
  }
}

class DetailContentShimmer extends StatelessWidget {
  final Color accentColor;
  final bool showHero;

  const DetailContentShimmer({
    super.key,
    required this.accentColor,
    this.showHero = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHero)
          Container(
            height: 250,
            width: double.infinity,
            color: accentColor.withValues(alpha: 0.12),
            child: const Center(
              child: ShimmerBlock(width: 120, height: 120, radius: 28),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: AppShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    Expanded(
                      child: ShimmerBlock(width: double.infinity, height: 28),
                    ),
                    SizedBox(width: 12),
                    ShimmerBlock(width: 86, height: 30, radius: 999),
                  ],
                ),
                SizedBox(height: 14),
                ShimmerBlock(width: 180, height: 14, radius: 10),
                SizedBox(height: 10),
                ShimmerBlock(width: 130, height: 18, radius: 10),
                SizedBox(height: 24),
                ShimmerBlock(width: 110, height: 20),
                SizedBox(height: 10),
                ShimmerBlock(width: double.infinity, height: 14, radius: 10),
                SizedBox(height: 8),
                ShimmerBlock(width: double.infinity, height: 14, radius: 10),
                SizedBox(height: 8),
                ShimmerBlock(width: 240, height: 14, radius: 10),
                SizedBox(height: 24),
                ShimmerBlock(width: 120, height: 20),
                SizedBox(height: 12),
                ShimmerBlock(width: double.infinity, height: 76, radius: 18),
                SizedBox(height: 12),
                ShimmerBlock(width: double.infinity, height: 76, radius: 18),
                SizedBox(height: 12),
                ShimmerBlock(width: double.infinity, height: 76, radius: 18),
                SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FormPageShimmer extends StatelessWidget {
  final Color accentColor;

  const FormPageShimmer({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  ShimmerBlock(width: 56, height: 56, radius: 16),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBlock(width: 180, height: 16),
                        SizedBox(height: 8),
                        ShimmerBlock(width: 120, height: 12, radius: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const ShimmerBlock(width: 140, height: 20),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 86,
                    radius: 18,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 86,
                    radius: 18,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 86,
                    radius: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const ShimmerBlock(width: 110, height: 20),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                ShimmerBlock(width: 92, height: 40, radius: 12),
                ShimmerBlock(width: 92, height: 40, radius: 12),
                ShimmerBlock(width: 92, height: 40, radius: 12),
                ShimmerBlock(width: 92, height: 40, radius: 12),
                ShimmerBlock(width: 92, height: 40, radius: 12),
                ShimmerBlock(width: 92, height: 40, radius: 12),
              ],
            ),
            const SizedBox(height: 24),
            const ShimmerBlock(width: 160, height: 20),
            const SizedBox(height: 12),
            const ShimmerBlock(width: double.infinity, height: 58, radius: 16),
            const SizedBox(height: 12),
            const ShimmerBlock(width: double.infinity, height: 58, radius: 16),
            const SizedBox(height: 12),
            const ShimmerBlock(width: double.infinity, height: 58, radius: 16),
            const SizedBox(height: 24),
            Container(
              height: 124,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: 120, height: 18),
                  SizedBox(height: 14),
                  ShimmerBlock(width: double.infinity, height: 14, radius: 10),
                  SizedBox(height: 8),
                  ShimmerBlock(width: double.infinity, height: 14, radius: 10),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ShimmerBlock(width: 110, height: 22, radius: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const ShimmerBlock(width: double.infinity, height: 56, radius: 16),
          ],
        ),
      ),
    );
  }
}

class SimpleListShimmer extends StatelessWidget {
  final int itemCount;
  final bool imageLeading;
  final bool trailingBadge;

  const SimpleListShimmer({
    super.key,
    this.itemCount = 6,
    this.imageLeading = false,
    this.trailingBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                if (imageLeading)
                  const ShimmerBlock(width: 78, height: 78, radius: 14)
                else
                  const ShimmerBlock(width: 46, height: 46, radius: 14),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBlock(width: double.infinity, height: 16),
                      SizedBox(height: 8),
                      ShimmerBlock(width: 170, height: 12, radius: 10),
                      SizedBox(height: 10),
                      ShimmerBlock(width: 110, height: 14, radius: 10),
                    ],
                  ),
                ),
                if (trailingBadge) ...[
                  const SizedBox(width: 10),
                  const ShimmerBlock(width: 64, height: 28, radius: 999),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class NotificationsShimmer extends StatelessWidget {
  const NotificationsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleListShimmer(itemCount: 7);
  }
}

class OrdersShimmer extends StatelessWidget {
  const OrdersShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          Container(
            height: 48,
            margin: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const Expanded(
            child: SimpleListShimmer(itemCount: 5, trailingBadge: true),
          ),
        ],
      ),
    );
  }
}

class PromotionsShimmer extends StatelessWidget {
  const PromotionsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ShimmerBlock(
                width: double.infinity,
                height: 76,
                radius: 18,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: ShimmerBlock(width: 120, height: 20),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 136,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    const ShimmerBlock(width: 280, height: 132, radius: 20),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: ShimmerBlock(width: 100, height: 20),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: ShimmerBlock(
                  width: double.infinity,
                  height: 108,
                  radius: 18,
                ),
              ),
              childCount: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodsShimmer extends StatelessWidget {
  const PaymentMethodsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          ShimmerBlock(width: 80, height: 20),
          SizedBox(height: 12),
          ShimmerBlock(width: double.infinity, height: 190, radius: 22),
          SizedBox(height: 14),
          ShimmerBlock(width: double.infinity, height: 190, radius: 22),
        ],
      ),
    );
  }
}

class SearchResultsShimmer extends StatelessWidget {
  const SearchResultsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimpleListShimmer(itemCount: 6);
  }
}

class _ShimmerCategoryItem extends StatelessWidget {
  const _ShimmerCategoryItem();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 14),
      child: Column(
        children: [
          ShimmerBlock(width: 60, height: 60, radius: 18),
          SizedBox(height: 10),
          ShimmerBlock(width: 56, height: 12, radius: 10),
        ],
      ),
    );
  }
}

class _ShimmerGridCard extends StatelessWidget {
  const _ShimmerGridCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              child: ColoredBox(
                color: AppColors.white,
                child: Center(
                  child: ShimmerBlock(width: 86, height: 86, radius: 22),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: double.infinity, height: 14),
                  SizedBox(height: 8),
                  ShimmerBlock(width: 110, height: 12, radius: 10),
                  Spacer(),
                  Row(
                    children: [
                      ShimmerBlock(width: 70, height: 14, radius: 10),
                      Spacer(),
                      ShimmerBlock(width: 34, height: 34, radius: 10),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerListCard extends StatelessWidget {
  const _ShimmerListCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            ShimmerBlock(width: 68, height: 68, radius: 18),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBlock(width: double.infinity, height: 16),
                  SizedBox(height: 8),
                  ShimmerBlock(width: 170, height: 12, radius: 10),
                  SizedBox(height: 12),
                  ShimmerBlock(width: 110, height: 14, radius: 10),
                ],
              ),
            ),
            SizedBox(width: 12),
            ShimmerBlock(width: 42, height: 42, radius: 12),
          ],
        ),
      ),
    );
  }
}
