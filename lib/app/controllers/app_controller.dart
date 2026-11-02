import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../services/azkar_service.dart';
import '../services/notification_service.dart';
import '../services/quran_service.dart';
import '../services/storage_service.dart';

/// Boot orchestration — decides splash → onboarding vs. splash → home.
class AppController extends GetxController {
  final _s = StorageService.instance;

  /// True once bundled corpora are parsed. Splash watches this.
  final ready = false.obs;
  final progressLabel = 'preparing'.obs;

  bool get onboarded => _s.readBool(StorageService.kOnboarded);

  @override
  void onInit() {
    super.onInit();
    _boot();
  }

  /// Boot steps that failed or timed out on the last attempt.
  final bootFailures = <String>[];

  /// An essential corpus could not be loaded; splash offers a retry.
  final bootFailed = false.obs;

  /// Steps the app can't work without; the rest (notifications) are optional.
  static const essential = {'quran', 'azkar'};

  Future<void> _boot() => boot({
    'quran': QuranService.instance.load,
    'azkar': AzkarService.instance.load,
    'notifications': NotificationService.instance.init,
  });

  Future<void> retryBoot() => _boot();

  /// Runs every step at once, each bounded by [timeout], so splash can never
  /// hang. The app opens when every [essential] step succeeded; otherwise
  /// [bootFailed] is set and splash shows a retry.
  @visibleForTesting
  Future<void> boot(
    Map<String, Future<void> Function()> steps, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    bootFailed.value = false;
    bootFailures.clear();
    await Future.wait([
      for (final e in steps.entries)
        e.value().timeout(timeout).catchError((Object error) {
          bootFailures.add(e.key);
          debugPrint('Boot step ${e.key} failed: $error');
        }),
    ]);
    if (bootFailures.any(essential.contains)) {
      bootFailed.value = true;
    } else {
      ready.value = true;
    }
  }

  Future<void> completeOnboarding() =>
      _s.write(StorageService.kOnboarded, true);
}
