import 'package:flutter/material.dart';

/// Design tokens from design/DESIGN.md — "Deen" Emerald & Gold system.
///
/// Surfaces and text follow [isDark]: the dark palette is true black for
/// OLED night reading. [brand], [brandDeep] and [onBrand] are the fixed
/// emerald hero colours and stay the same in both modes.
abstract class AppColors {
  static bool isDark = false;

  static Color _pick(int light, int dark) => Color(isDark ? dark : light);

  static const brand = Color(0xFF0E6B5C);
  static const brandDeep = Color(0xFF0A4A3F);
  static const onBrand = Color(0xFFF8F6F1);
  static const gold = Color(0xFFC9A24B);

  static Color get emerald => _pick(0xFF0E6B5C, 0xFF1F8A76);
  static Color get emeraldDeep => _pick(0xFF0A4A3F, 0xFF8ED3C1);
  static Color get emeraldTint => _pick(0xFFE7F2F0, 0xFF12302A);
  static Color get goldTint => _pick(0xFFF4EBD7, 0xFF33291A);
  static Color get goldInk => _pick(0xFF8A6B1F, 0xFFE5C378);
  static Color get ivory => _pick(0xFFF8F6F1, 0xFF000000);
  static Color get surface => _pick(0xFFFFFFFF, 0xFF111614);
  static Color get ink => _pick(0xFF12211D, 0xFFECE8DF);
  static Color get sage => _pick(0xFF5F7169, 0xFF9FB2A9);
  static Color get hairline => _pick(0xFFE4E0D5, 0xFF26302C);
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
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: AppFonts.headline,
    fontFamilyFallback: const [AppFonts.quran],
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.ink,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: AppFonts.body,
    fontFamilyFallback: const [AppFonts.quran],
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.ink,
    height: height,
    fontStyle: fontStyle,
    letterSpacing: letterSpacing,
  );

  static TextStyle quran(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 2.0,
  }) => TextStyle(
    fontFamily: AppFonts.quran,
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.ink,
    height: height,
  );

  /// The theme for the current [AppColors.isDark] palette.
  static ThemeData get current {
    final dark = AppColors.isDark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.ivory,
      fontFamily: AppFonts.body,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: AppColors.emerald,
        secondary: AppColors.gold,
        surface: AppColors.ivory,
        onSurface: AppColors.ink,
      ),
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: true,
      ),
      dividerTheme: DividerThemeData(color: AppColors.hairline, thickness: 1),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
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
  boxShadow: AppColors.isDark
      ? null
      : const [
          BoxShadow(
            color: Color(0x0D0A4A3F),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
);
