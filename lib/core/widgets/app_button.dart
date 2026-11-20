import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isSmall;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final double? width;
  final EdgeInsets? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isSmall = false,
    this.color,
    this.textColor,
    this.icon,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    final foregroundColor = textColor ?? AppColors.white;
    final radius = BorderRadius.circular(isSmall ? 12 : 14);

    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: isSmall ? 42 : 52,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor, width: 1.2),
            padding: padding,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: _buildChild(buttonColor),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: isSmall ? 42 : 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: buttonColor.withValues(alpha: 0.45),
          padding: padding,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
        child: _buildChild(foregroundColor),
      ),
    );
  }

  Widget _buildChild(Color color) {
    final textStyle = TextStyle(
      fontSize: isSmall ? 13.5 : 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );

    if (isLoading) {
      return SizedBox(
        width: isSmall ? 18 : 20,
        height: isSmall ? 18 : 20,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: color),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isSmall ? 17 : 19),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: textStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}
