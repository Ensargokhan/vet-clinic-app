import 'package:flutter/material.dart';

/// Renk token'ları — açık ve koyu tema için tek kaynak.
///
/// Ekranlar doğrudan `Theme.of(context).colorScheme` ve
/// `Theme.of(context).extension<AppSemanticColors>()!` üzerinden okumalı;
/// böylece dark mode otomatik uyum sağlar.
class AppColors {
  AppColors._();

  // ---- Ortak anlamsal renkler (tema bağımsız) ----
  static const Color success = Color(0xFF2BA84A);
  static const Color warning = Color(0xFFE8A53D);
  static const Color danger = Color(0xFFE5544B);

  // ---- LIGHT ----
  static const Color lightPrimary = Color(0xFF0E9F8E);
  static const Color lightAccent = Color(0xFF4FA8C7);
  static const Color lightBackground = Color(0xFFF5F8F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEFF4F4);
  static const Color lightTextPrimary = Color(0xFF1B2A2A);
  static const Color lightTextSecondary = Color(0xFF5E6E6E);
  static const Color lightOutline = Color(0xFFE2E8E8);

  // ---- DARK ----
  static const Color darkPrimary = Color(0xFF2BC4B0);
  static const Color darkAccent = Color(0xFF6FBFD8);
  static const Color darkBackground = Color(0xFF0E1717);
  static const Color darkSurface = Color(0xFF162222);
  static const Color darkSurfaceAlt = Color(0xFF1C2B2B);
  static const Color darkTextPrimary = Color(0xFFE7EEEE);
  static const Color darkTextSecondary = Color(0xFF9FB0B0);
  static const Color darkOutline = Color(0xFF2A3A3A);
  static const Color darkDanger = Color(0xFFFF6B61);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    onPrimary: Colors.white,
    secondary: lightAccent,
    onSecondary: Colors.white,
    error: danger,
    onError: Colors.white,
    surface: lightSurface,
    onSurface: lightTextPrimary,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: Color(0xFF07221F),
    secondary: darkAccent,
    onSecondary: Color(0xFF07221F),
    error: darkDanger,
    onError: Color(0xFF2A0E0C),
    surface: darkSurface,
    onSurface: darkTextPrimary,
  );
}

/// Material ColorScheme'in karşılamadığı uygulamaya özel renk token'ları.
/// `Theme.of(context).extension<AppSemanticColors>()!` ile okunur.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color textSecondary;
  final Color outline;
  final Color surfaceAlt;
  final Color success;
  final Color warning;
  final Color info; // accent ile aynı; bilgi/onay vurgusu

  const AppSemanticColors({
    required this.textSecondary,
    required this.outline,
    required this.surfaceAlt,
    required this.success,
    required this.warning,
    required this.info,
  });

  static const light = AppSemanticColors(
    textSecondary: AppColors.lightTextSecondary,
    outline: AppColors.lightOutline,
    surfaceAlt: AppColors.lightSurfaceAlt,
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.lightAccent,
  );

  static const dark = AppSemanticColors(
    textSecondary: AppColors.darkTextSecondary,
    outline: AppColors.darkOutline,
    surfaceAlt: AppColors.darkSurfaceAlt,
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.darkAccent,
  );

  @override
  AppSemanticColors copyWith({
    Color? textSecondary,
    Color? outline,
    Color? surfaceAlt,
    Color? success,
    Color? warning,
    Color? info,
  }) {
    return AppSemanticColors(
      textSecondary: textSecondary ?? this.textSecondary,
      outline: outline ?? this.outline,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}

/// Kısa erişim: `context.colors.textSecondary` gibi.
extension AppColorsX on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  AppSemanticColors get colors => Theme.of(this).extension<AppSemanticColors>()!;
}
