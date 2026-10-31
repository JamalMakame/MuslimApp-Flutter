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

  Future<void> _boot() async {
    // Parse bundled corpora — the only real startup work.
    await Future.wait([
      QuranService.instance.load(),
      AzkarService.instance.load(),
      NotificationService.instance.init(),
    ]);
    ready.value = true;
  }

  Future<void> completeOnboarding() =>
      _s.write(StorageService.kOnboarded, true);
}
