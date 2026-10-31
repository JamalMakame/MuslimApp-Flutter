import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/theme/app_theme.dart';

void main() {
  test('app theme exposes design tokens', () {
    expect(AppColors.emerald, isNotNull);
    expect(AppColors.gold, isNotNull);
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.ivory);
  });
}
