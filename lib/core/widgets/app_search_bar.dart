import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import '../constants/app_colors.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Search field used across the product.
///
/// One shape everywhere: 50px tall, 14px radius, soft filled surface and a
/// hairline border — the quiet treatment from the reference screens.
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
          color: AppColors.tile,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          readOnly: readOnly,
          autofocus: autofocus,
          onTap: onTap,
          cursorColor: AppColors.primary,
          cursorWidth: 1.6,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.dark,
          ),
          decoration: InputDecoration(
            hintText: resolvedHint,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.mediumGrey,
            ),
            prefixIcon: prefix ??
                const Icon(
                  LucideIcons.search,
                  color: AppColors.mediumGrey,
                  size: 21,
                ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 46,
              minHeight: 46,
            ),
            suffixIcon: suffix,
            filled: false,
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }
}
