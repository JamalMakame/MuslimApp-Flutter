import 'package:get/get.dart';

import '../controllers/app_controller.dart';
import '../controllers/azkar_controller.dart';
import '../controllers/calendar_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/prayer_reminder_controller.dart';
import '../controllers/memorize_controller.dart';
import '../controllers/qibla_controller.dart';
import '../controllers/quran_controller.dart';
import '../controllers/reader_controller.dart';
import '../controllers/settings_controller.dart';
import '../controllers/tasbeeh_controller.dart';
import '../ui/screens/azkar_categories_screen.dart';
import '../ui/screens/azkar_detail_screen.dart';
import '../ui/screens/bookmarks_screen.dart';
import '../ui/screens/dedication_screen.dart';
import '../ui/screens/prayer_tracker_screen.dart';
import '../ui/screens/prayer_tuning_screen.dart';
import '../ui/screens/timetable_screen.dart';
import '../ui/screens/habits_screen.dart';
import '../ui/screens/hadith_screen.dart';
import '../ui/screens/calendar_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/memorize_screen.dart';
import '../ui/screens/mushaf_screen.dart';
import '../ui/screens/onboarding_screen.dart';
import '../ui/screens/qibla_screen.dart';
import '../ui/screens/quran_index_screen.dart';
import '../ui/screens/quran_reader_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/tasbeeh_screen.dart';

abstract class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const quran = '/quran';
  static const qibla = '/qibla';
  static const azkar = '/azkar';
  static const tasbeeh = '/tasbeeh';
  static const settings = '/settings';
  static const calendar = '/calendar';
  // Dynamic: '/reader/1?ayah=5', '/azkar-detail/catMorning', '/memorize/1'
  static String reader(int surah, {int? ayah}) =>
      ayah == null ? '/reader/$surah' : '/reader/$surah?ayah=$ayah';
  static String azkarDetail(String bucket) => '/azkar-detail/$bucket';
  static String memorize(int surah, {int? ayah}) =>
      ayah == null ? '/memorize/$surah' : '/memorize/$surah?ayah=$ayah';
  static const bookmarks = '/bookmarks';
  static const prayerTuning = '/prayer-tuning';
  static const timetable = '/timetable';
  static const habits = '/habits';
  static const prayerTracker = '/prayer-tracker';
  static const hadith = '/hadith';
  static const dedication = '/dedication';
  static String mushaf(int page) => '/mushaf?page=$page';
}

/// Everything the app needs up-front (storage-backed prefs, boot
/// orchestrator) is bound once at app level.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SettingsController(), permanent: true);
    Get.put(AppController(), permanent: true);
    Get.put(PrayerReminderController(), permanent: true);
  }
}

class AppPages {
  static final pages = <GetPage>[
    GetPage(name: Routes.splash, page: () => const SplashScreen()),
    GetPage(name: Routes.onboarding, page: () => const OnboardingScreen()),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => HomeController())),
    ),
    GetPage(
      name: Routes.quran,
      page: () => const QuranIndexScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => QuranController())),
    ),
    GetPage(
      name: Routes.azkar,
      page: () => const AzkarCategoriesScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => AzkarController())),
    ),
    GetPage(name: Routes.settings, page: () => const SettingsScreen()),
    GetPage(
      name: Routes.qibla,
      page: () => const QiblaScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => QiblaController())),
    ),
    GetPage(
      name: Routes.tasbeeh,
      page: () => const TasbeehScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => TasbeehController())),
    ),
    GetPage(
      name: '/reader/:surah',
      page: () => QuranReaderScreen(surah: int.parse(Get.parameters['surah']!)),
      binding: BindingsBuilder(() {
        final n = int.parse(Get.parameters['surah']!);
        final ayah = int.tryParse(Get.parameters['ayah'] ?? '');
        Get.lazyPut(
          () => ReaderController(n, initialAyah: ayah),
          tag: 'reader_$n',
        );
      }),
    ),
    GetPage(
      name: '/azkar-detail/:bucket',
      page: () => AzkarDetailScreen(bucket: Get.parameters['bucket']!),
      binding: BindingsBuilder(() {
        Get.lazyPut(
          () => AzkarDetailController(Get.parameters['bucket']!),
          tag: 'azkar_${Get.parameters['bucket']}',
        );
      }),
    ),
    GetPage(name: Routes.bookmarks, page: () => const BookmarksScreen()),
    GetPage(name: Routes.prayerTuning, page: () => const PrayerTuningScreen()),
    GetPage(name: Routes.timetable, page: () => const TimetableScreen()),
    GetPage(name: Routes.habits, page: () => const HabitsScreen()),
    GetPage(
      name: Routes.prayerTracker,
      page: () => const PrayerTrackerScreen(),
    ),
    GetPage(name: Routes.hadith, page: () => const HadithScreen()),
    GetPage(name: Routes.dedication, page: () => const DedicationScreen()),
    GetPage(
      name: '/mushaf',
      page: () => MushafScreen(
        initialPage: int.tryParse(Get.parameters['page'] ?? '') ?? 1,
      ),
    ),
    GetPage(
      name: Routes.calendar,
      page: () => const CalendarScreen(),
      binding: BindingsBuilder(() => Get.lazyPut(() => CalendarController())),
    ),
    GetPage(
      name: '/memorize/:surah',
      page: () => const MemorizeScreen(),
      binding: BindingsBuilder(() {
        final n = int.parse(Get.parameters['surah']!);
        final ayah = int.tryParse(Get.parameters['ayah'] ?? '');
        Get.lazyPut(() => MemorizeController(n, initialAyah: ayah));
      }),
    ),
  ];
}

/// Opens the reader at [surah]:[ayah]. A reader of that surah already on
/// the stack (its controller is tagged per surah, so a second route would
/// reuse it) is popped back to and scrolled. From inside another reader
/// ([fromSurah]), the new surah replaces it instead of stacking.
void openQuranAt(int surah, int ayah, {int? fromSurah}) {
  final tag = 'reader_$surah';
  if (Get.isRegistered<ReaderController>(tag: tag)) {
    final name = RegExp('^/reader/$surah(\\?|\$)');
    Get.until((route) => name.hasMatch(route.settings.name ?? ''));
    Get.find<ReaderController>(tag: tag).jumpTo(ayah);
    return;
  }
  final route = Routes.reader(surah, ayah: ayah);
  fromSurah == null ? Get.toNamed(route) : Get.offNamed(route);
}
