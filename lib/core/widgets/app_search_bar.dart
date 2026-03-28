import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool readOnly;
  final bool autofocus;
  final Widget? prefix;
  final Widget? suffix;

  const AppSearchBar({
    super.key,
    this.hint = 'Search...',
    this.onTap,
    this.onChanged,
    this.controller,
    this.readOnly = false,
    this.autofocus = false,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedHint =
        hint == 'Search...' ? context.l10n.t('common.search') : hint;
    return GestureDetector(
      onTap: readOnly ? onTap : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.extraLightGrey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          autofocus: autofocus,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: resolvedHint,
            prefixIcon: prefix ??
                const Icon(
                  Icons.search_rounded,
                  color: AppColors.mediumGrey,
                  size: 22,
                ),
            suffixIcon: suffix,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}
