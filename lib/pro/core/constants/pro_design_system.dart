import 'package:flutter/material.dart';

/// Modern Design System for Pro App
/// Ensures consistent UI/UX across all pro app screens

class ProDesignSystem {
  ProDesignSystem._();

  // ============== SPACING ==============
  static const double spacing2 = 2.0;
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // ============== BORDER RADIUS ==============
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusCircle = 999.0;

  // ============== ELEVATION & SHADOWS ==============
  static const List<BoxShadow> shadowElevation1 = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> shadowElevation2 = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowElevation3 = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowElevation4 = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6)),
  ];

  // ============== CARD DECORATION ==============
  static BoxDecoration cardDecoration({
    Color? backgroundColor,
    List<BoxShadow>? shadows,
    double? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusMedium),
      boxShadow: shadows ?? shadowElevation1,
      border: border,
    );
  }

  static BoxDecoration surfaceDecoration({
    Color? backgroundColor,
    double? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius ?? radiusMedium),
    );
  }

  // ============== INPUT DECORATION ==============
  static InputDecoration inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: Color(0xFF039D55), width: 2),
      ),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon != null
          ? GestureDetector(onTap: onSuffixTap, child: Icon(suffixIcon))
          : null,
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }

  // ============== BUTTON STYLES ==============
  static ButtonStyle primaryButtonStyle({double? width, double? height}) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF039D55),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      elevation: 2,
    );
  }

  static ButtonStyle secondaryButtonStyle({double? width, double? height}) {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF0F9F4),
      foregroundColor: const Color(0xFF039D55),
      padding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      side: const BorderSide(color: Color(0xFF039D55), width: 1.5),
    );
  }

  static ButtonStyle outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      side: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
    );
  }

  // ============== CHIP STYLE ==============
  static ChipThemeData chipTheme() {
    return ChipThemeData(
      padding: const EdgeInsets.symmetric(
        horizontal: spacing8,
        vertical: spacing4,
      ),
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCircle),
      ),
    );
  }

  // ============== DIVIDER ==============
  static const Divider modernDivider = Divider(
    height: spacing12,
    thickness: 1,
    color: Color(0xFFE5E7EB),
  );

  // ============== APPBAR STYLE ==============
  static AppBarTheme appBarTheme({Color? backgroundColor, double? elevation}) {
    return AppBarTheme(
      backgroundColor: backgroundColor,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}

/// Modern Card Widget - Reusable across the app
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final List<BoxShadow>? shadows;
  final double borderRadius;
  final Border? border;
  final Alignment alignment;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ProDesignSystem.spacing16),
    this.onTap,
    this.backgroundColor = Colors.white,
    this.shadows = ProDesignSystem.shadowElevation1,
    this.borderRadius = ProDesignSystem.radiusMedium,
    this.border,
    this.alignment = Alignment.topLeft,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: alignment,
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
          border: border,
        ),
        child: child,
      ),
    );
  }
}

/// Modern Stat Card - For displaying metrics
class ModernStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const ModernStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.backgroundColor = const Color(0xFFF0F9F4),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ModernCard(
        backgroundColor: backgroundColor,
        shadows: ProDesignSystem.shadowElevation1,
        padding: const EdgeInsets.all(ProDesignSystem.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(ProDesignSystem.spacing8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? const Color(0xFF039D55)).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusSmall,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: iconColor ?? const Color(0xFF039D55),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: ProDesignSystem.spacing8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern Tile - For list items
class ModernTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool dense;

  const ModernTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = dense
        ? ProDesignSystem.spacing12
        : ProDesignSystem.spacing16;

    return GestureDetector(
      onTap: onTap,
      child: ModernCard(
        backgroundColor: backgroundColor ?? Colors.white,
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                padding: const EdgeInsets.all(ProDesignSystem.spacing8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9F4),
                  borderRadius: BorderRadius.circular(
                    ProDesignSystem.radiusSmall,
                  ),
                ),
                child: Icon(
                  leadingIcon,
                  size: 20,
                  color: const Color(0xFF039D55),
                ),
              ),
              const SizedBox(width: ProDesignSystem.spacing12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: ProDesignSystem.spacing4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: ProDesignSystem.spacing12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Modern Header - For section headers with action
class ModernHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final TextStyle? titleStyle;

  const ModernHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ProDesignSystem.spacing16,
        vertical: ProDesignSystem.spacing12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style:
                titleStyle ??
                Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
          ),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF039D55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Modern Info Box - For displaying information
class ModernInfoBox extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const ModernInfoBox({
    super.key,
    required this.message,
    this.icon,
    this.backgroundColor = const Color(0xFFF0F9F4),
    this.textColor = const Color(0xFF027A42),
    this.borderColor = const Color(0xFF039D55),
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      backgroundColor: backgroundColor,
      border: Border.all(color: borderColor),
      padding: const EdgeInsets.all(ProDesignSystem.spacing12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: ProDesignSystem.spacing12),
          ],
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
