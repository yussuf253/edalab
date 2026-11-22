import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Module header shared by the module listing screens.
///
/// Clean white bar with an ink title, an optional row of actions, and the
/// search field sitting underneath inside a hairline-bordered block — the
/// quiet, product-grade treatment used throughout the app.
class ModuleScreenAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ModuleScreenAppBar({
    super.key,
    required this.title,
    this.search,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.searchHeight = 70,
  });

  final String title;
  final Widget? search;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  /// Shell tabs (orders, messages) sit at the root: no back affordance.
  final bool showBack;
  final double searchHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (search == null ? 1 : searchHeight));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.dark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: kToolbarHeight,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      titleSpacing: showBack ? null : 20,
      leadingWidth: showBack ? 52 : 20,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.tile,
                  foregroundColor: AppColors.dark,
                  shape: const CircleBorder(),
                ),
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
            )
          : null,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.h3.copyWith(fontSize: 18, letterSpacing: -0.3),
      ),
      actions: actions,
      bottom: search == null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            )
          : PreferredSize(
              preferredSize: Size.fromHeight(searchHeight),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: search,
              ),
            ),
    );
  }
}
