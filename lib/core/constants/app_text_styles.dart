import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle h1 = GoogleFonts.plusJakartaSans(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
    height: 1.2,
    letterSpacing: -0.9,
  );

  static TextStyle h2 = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
    height: 1.25,
    letterSpacing: -0.7,
  );

  static TextStyle h3 = GoogleFonts.plusJakartaSans(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
    height: 1.3,
    letterSpacing: -0.4,
  );

  static TextStyle h4 = GoogleFonts.plusJakartaSans(
    fontSize: 16.5,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
    height: 1.35,
    letterSpacing: -0.25,
  );

  // Body
  static TextStyle bodyLarge = GoogleFonts.plusJakartaSans(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    color: AppColors.dark,
    height: 1.55,
  );

  static TextStyle bodyMedium = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.dark,
    height: 1.55,
  );

  static TextStyle bodySmall = GoogleFonts.plusJakartaSans(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.grey,
    height: 1.5,
  );

  // Labels
  static TextStyle labelLarge = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.dark,
    height: 1.4,
  );

  static TextStyle labelMedium = GoogleFonts.plusJakartaSans(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: AppColors.dark,
    height: 1.4,
  );

  static TextStyle labelSmall = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.grey,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // Special
  static TextStyle price = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
    height: 1.2,
    letterSpacing: -0.2,
  );

  static TextStyle priceSmall = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.dark,
    height: 1.2,
  );

  static TextStyle priceOld = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGrey,
    decoration: TextDecoration.lineThrough,
    height: 1.2,
  );

  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
    letterSpacing: 0,
  );

  static TextStyle buttonSmall = GoogleFonts.plusJakartaSans(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    height: 1.2,
  );

  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.mediumGrey,
    height: 1.4,
  );

  static TextStyle badge = GoogleFonts.plusJakartaSans(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.0,
  );
}
