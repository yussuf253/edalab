import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Green module header shared by the module listing screens.
///
/// White title and back arrow on the brand green, an optional row of actions,
/// and the search pill sitting inside the green block — the header treatment
/// used by the food listing screen.
class ModuleScreenAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ModuleScreenAppBar({
    super.key,
    required this.title,
    this.search,
    this.actions,
    this.onBack,
    this.searchHeight = 72,
  });

  final String title;
  final Widget? search;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final double searchHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (search == null ? 0 : searchHeight));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: kToolbarHeight,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 22),
        onPressed:
            onBack ??
            () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.h4.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
      bottom: search == null
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(searchHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: search,
              ),
            ),
    );
  }
}
