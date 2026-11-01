import 'package:flutter/material.dart';

/// Design tokens from design/DESIGN.md — "Deen" Emerald & Gold system.
abstract class AppColors {
  static const emerald = Color(0xFF0E6B5C);
  static const emeraldDeep = Color(0xFF0A4A3F);
  static const gold = Color(0xFFC9A24B);
  static const goldTint = Color(0xFFF4EBD7);
  static const ivory = Color(0xFFF8F6F1);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF12211D);
  static const sage = Color(0xFF5F7169);
  static const hairline = Color(0xFFE4E0D5);
}

abstract class AppFonts {
  static const headline = 'Plus Jakarta Sans';
  static const body = 'Manrope';
  static const quran = 'Amiri';
}

abstract class AppTheme {
  static TextStyle headline(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: AppFonts.headline,
    fontFamilyFallback: const [AppFonts.quran],
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: const [AppFonts.quran],
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );

  static TextStyle quran(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double height = 2.0,
  }) => TextStyle(
    fontFamily: AppFonts.quran,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ivory,
      fontFamily: AppFonts.body,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.emerald,
        primary: AppColors.emerald,
        secondary: AppColors.gold,
        surface: AppColors.ivory,
      ),
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.emerald
              : AppColors.hairline,
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: AppColors.emerald,
        inactiveTrackColor: AppColors.hairline,
        thumbColor: AppColors.gold,
      ),
    );
  }
}

/// Shared card chrome: white rounded card with hairline border.
BoxDecoration appCardDecoration({double radius = 16}) => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.hairline),
  boxShadow: const [
    BoxShadow(color: Color(0x0D0A4A3F), blurRadius: 10, offset: Offset(0, 2)),
  ],
);
