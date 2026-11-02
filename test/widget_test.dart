import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/theme/app_theme.dart';

void main() {
  tearDown(() => AppColors.isDark = false);

  test('app theme exposes design tokens', () {
    expect(AppColors.emerald, isNotNull);
    expect(AppColors.gold, isNotNull);
    expect(AppTheme.current.scaffoldBackgroundColor, AppColors.ivory);
  });

  test('dark palette is true black with light text', () {
    AppColors.isDark = true;
    final theme = AppTheme.current;
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(AppColors.ink.computeLuminance(), greaterThan(0.7));
    expect(AppTheme.body(12).color, AppColors.ink);
    expect(appCardDecoration().color, AppColors.surface);
    expect(appCardDecoration().boxShadow, isNull);
  });

  test('brand hero colours do not change with the mode', () {
    const brand = [AppColors.brand, AppColors.brandDeep, AppColors.onBrand];
    AppColors.isDark = true;
    expect([AppColors.brand, AppColors.brandDeep, AppColors.onBrand], brand);
  });
}
