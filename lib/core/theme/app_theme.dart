import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// One theme for the whole product.
///
/// Light and dark are built by the same code path so a control can never look
/// different depending on which screen or module it lives in: one radius scale
/// (14 for controls, 16 for cards, 18 for dialogs, 20 for sheets), one icon
/// size, one set of text styles and one hairline border colour.
class AppTheme {
  AppTheme._();

  /// Shared geometry for the app's controls: one 14px radius and 52px height
  /// for every primary control, so buttons never look improvised.
  static const BorderRadius _controlRadius = BorderRadius.all(
    Radius.circular(14),
  );
  static const BorderRadius _cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius _dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );
  static const BorderRadius _sheetRadius = BorderRadius.vertical(
    top: Radius.circular(20),
  );

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.white;
    final card = isDark ? AppColors.darkCard : AppColors.white;
    final border = isDark ? const Color(0xFF232C26) : AppColors.border;
    final tile = isDark ? AppColors.darkCard : AppColors.tile;
    final ink = isDark ? AppColors.white : AppColors.dark;
    final muted = isDark ? AppColors.mediumGrey : AppColors.grey;
    final soft = isDark ? const Color(0xFF1E2A23) : AppColors.primarySurface;

    final textTheme = _textTheme(ink: ink, muted: muted);

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            secondary: AppColors.secondary,
            onSecondary: AppColors.white,
            error: AppColors.error,
            onError: AppColors.white,
            surface: AppColors.darkSurface,
            onSurface: AppColors.white,
            outline: Color(0xFF232C26),
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            secondary: AppColors.secondary,
            onSecondary: AppColors.white,
            error: AppColors.error,
            onError: AppColors.white,
            surface: AppColors.surface,
            onSurface: AppColors.dark,
            outline: AppColors.border,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: background,
      canvasColor: surface,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: colorScheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      /// Every icon defaults to the same weight/size/ink; screens only override
      /// size when a glyph needs optical balance.
      iconTheme: IconThemeData(color: ink, size: 22),
      primaryIconTheme: IconThemeData(color: ink, size: 22),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: surface,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        centerTitle: false,
        iconTheme: IconThemeData(color: ink, size: 22),
        actionsIconTheme: IconThemeData(color: ink, size: 22),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: ink,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: soft,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : muted,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.85),
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ink,
          highlightColor: tile,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tile,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: muted),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: muted),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.error,
        ),
        prefixIconColor: muted,
        suffixIconColor: muted,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.22),
        selectionHandleColor: AppColors.primary,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: _cardRadius,
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: ink,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        subtitleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: muted,
        ),
        leadingAndTrailingTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          color: muted,
        ),
        minLeadingWidth: 20,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: const RoundedRectangleBorder(borderRadius: _controlRadius),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tile,
        selectedColor: soft,
        disabledColor: tile,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(),
        side: BorderSide(color: border, width: 1),
        showCheckmark: false,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(borderRadius: _sheetRadius),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: _dialogRadius,
          side: BorderSide(color: border),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.55,
          color: muted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.dark,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: muted,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: border,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: tile,
        circularTrackColor: tile,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: isDark ? muted : AppColors.lightGrey, width: 1.6),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : muted,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : tile,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.primary : border,
        ),
        thumbColor: const WidgetStatePropertyAll(AppColors.white),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.dark,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: tile,
        thumbColor: AppColors.white,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          (isDark ? AppColors.mediumGrey : AppColors.lightGrey),
        ),
        thickness: const WidgetStatePropertyAll(3),
        radius: const Radius.circular(3),
      ),
    );
  }

  /// One type ramp: 28 / 22 / 18 / 16 for headings, 15.5 / 14 / 12.5 for body
  /// copy, 14 / 12.5 / 11 for labels. Screens should use these via
  /// `Theme.of(context).textTheme` instead of ad-hoc sizes.
  static TextTheme _textTheme({required Color ink, required Color muted}) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.7,
        color: ink,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.4,
        color: ink,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.3,
        color: ink,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        letterSpacing: -0.2,
        color: ink,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 1.4,
        letterSpacing: -0.1,
        color: ink,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: ink,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: ink,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.55,
        color: ink,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: muted,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: ink,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: ink,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.2,
        color: muted,
      ),
    );
  }
}
