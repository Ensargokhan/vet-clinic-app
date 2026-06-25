import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografi ölçeği (Inter). Renkler temadan (textPrimary/secondary) verilir,
/// hardcoded edilmez.
///
/// Material TextTheme rollerine eşleme:
/// - displayLarge   → display   28/700
/// - headlineMedium → headline  22/700
/// - titleLarge     → titleLg   18/600
/// - titleMedium    → titleMd   16/600
/// - bodyLarge      → body      15/400
/// - bodyMedium     → bodySm    13/400
/// - labelLarge     → label     12/500
/// - labelSmall     → caption   11/500
class AppTypography {
  AppTypography._();

  static TextTheme build({
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, height: 1.2),
      headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, height: 1.25),
      titleLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary, height: 1.4),
      bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400, color: textSecondary, height: 1.4),
      labelLarge: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
      labelSmall: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
    );
  }
}
