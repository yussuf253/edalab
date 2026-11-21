import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/home_service_category_image.dart';

/// A category illustration drawn on the plate grey the artwork ships with.
///
/// Each source PNG is a square canvas whose figure sits flush to the top and
/// right of the canvas, with wide empty margins on the left and below. Both of
/// those margins are clipped here, so the figure reads centred and fills the
/// box its caller gives it, whatever the size or aspect of that box.
class HomeServiceCategoryArt extends StatelessWidget {
  const HomeServiceCategoryArt({
    super.key,
    required this.imagePath,
    this.borderRadius = BorderRadius.zero,
    this.fallbackIcon,
    this.fallbackColor,
    this.sourceAspectRatio = 1,
    this.contentWidthFraction = _contentWidth,
    this.contentHeightFraction = _contentHeight,
  });

  /// Resolved asset path, or null when the category has no artwork.
  final String? imagePath;
  final BorderRadius borderRadius;
  final IconData? fallbackIcon;
  final Color? fallbackColor;

  /// Width divided by height of the source canvas. Square by default, which is
  /// what the handyman set uses.
  final double sourceAspectRatio;

  /// Share of the canvas width and height the figure covers, flush to the
  /// canvas' right and top edges.
  final double contentWidthFraction;
  final double contentHeightFraction;

  /// Share of the source canvas reserved for the figure. The measured figures
  /// cover at most 0.77 x 0.85 of their canvas; keeping a little more on both
  /// axes leaves a few percent of plate around them whichever size is asked for.
  static const double _contentWidth = 0.80;
  static const double _contentHeight = 0.87;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    return ClipRRect(
      borderRadius: borderRadius,
      child: ColoredBox(
        color: homeServiceCategoryPlateColor,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = constraints.maxWidth;
            if (path == null) {
              return Center(
                child: Icon(
                  fallbackIcon,
                  color: fallbackColor,
                  size: boxWidth * 0.5,
                ),
              );
            }
            final boxHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : boxWidth;
            // Largest canvas whose figure still fits inside the box.
            final canvasHeight = math.min(
              boxHeight / contentHeightFraction,
              (boxWidth / contentWidthFraction) / sourceAspectRatio,
            );
            final canvas = canvasHeight * sourceAspectRatio;
            final contentWidth = canvas * contentWidthFraction;
            final contentHeight = canvasHeight * contentHeightFraction;
            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    // The figure is flush to the canvas' right edge, so the
                    // canvas starts left of the box to centre the figure.
                    left:
                        (boxWidth - contentWidth) / 2 -
                        canvas * (1 - contentWidthFraction),
                    top: (boxHeight - contentHeight) / 2,
                    width: canvas,
                    height: canvasHeight,
                    child: Image.asset(path, fit: BoxFit.fill),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
