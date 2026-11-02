import 'package:get_storage/get_storage.dart';

/// Thin wrapper over GetStorage — all local persistence for Deen.
///
/// Everything the user does (settings, bookmarks, counters, location)
/// lives here on-device. Designed so a future Supabase layer can mirror
/// these keys without touching the UI.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _box = GetStorage();

  static Future<void> init() => GetStorage.init();

  // ---- Keys ---------------------------------------------------------------
  static const kOnboarded = 'onboarded';
  static const kLocale = 'locale'; // 'en' | 'ar' | 'sw'
  static const kCalcMethod = 'calc_method';
  static const kMadhab = 'madhab';
  static const kThemeMode = 'theme_mode';
  static const kTextScale = 'text_scale'; // 0 | 1 | 2
  static const kNotifyPrayers = 'notify_prayers';
  static const kHighLatRule = 'high_lat_rule'; // middle | seventh | angle
  static const kPrayerOffsets = 'prayer_offsets'; // {prayer: minutes}
  static const kPrayerLeads = 'prayer_leads'; // {prayer: min before, -1 off}
  static const kAzkarReminders = 'azkar_reminders';
  static const kShowTranslations = 'show_translations';
  static const kAyahAudio = 'ayah_audio';
  static const kTranslationLang = 'translation_lang'; // 'en' | 'sw' | 'ar'
  static const kLat = 'loc_lat';
  static const kLng = 'loc_lng';
  static const kCity = 'loc_city';
  static const kCountry = 'loc_country';
  static const kLocSource = 'loc_source'; // 'gps' | 'manual'
  static const kLastReadSurah = 'last_surah';
  static const kLastReadAyah = 'last_ayah';
  static const kLastReadPage = 'last_page';
  static const kBookmarks = 'bookmarks'; // Set<surah>, before ayah bookmarks
  static const kAyahBookmarks = 'ayah_bookmarks'; // [{s, a, n, t}]
  static const kTafsirCache = 'tafsir_cache';
  static const kTasbeehPhrase = 'tasbeeh_phrase';
  static const kTasbeehCount = 'tasbeeh_count';
  static const kTasbeehLap = 'tasbeeh_lap';
  static const kTasbeehTarget = 'tasbeeh_target';
  static const kTasbeehTotal = 'tasbeeh_total';
  static const kTasbeehDate = 'tasbeeh_date';
  static const kTasbeehStreak = 'tasbeeh_streak';
  static const kTasbeehHaptics = 'tasbeeh_haptics';
  static const kAzkarProgress = 'azkar_progress'; // {date: {catKey: doneCount}}
  static const kMoonOffset = 'moon_offset'; // -2..+2 days
  static const kCalPrimary = 'cal_primary'; // 'hijri' | 'gregorian'
  static const kReciter = 'reciter'; // islamic.network edition id
  static const kMemRepeat = 'mem_repeat';
  static const kMemAutoAdvance = 'mem_auto_advance';
  static const kMemSpeed = 'mem_speed';
  static const kMemPosition = 'mem_position'; // {surah: last selected ayah}
  static const kDownloadedAudio =
      'downloaded_audio'; // {edition: {surah: bytes}}

  // ---- Generic helpers ----------------------------------------------------
  T? read<T>(String key) => _box.read<T>(key);
  Future<void> write(String key, dynamic value) => _box.write(key, value);
  Future<void> remove(String key) => _box.remove(key);
  bool has(String key) => _box.hasData(key);

  String readStr(String key, [String fallback = '']) =>
      _box.read<String>(key) ?? fallback;
  int readInt(String key, [int fallback = 0]) =>
      _box.read<int>(key) ?? fallback;
  bool readBool(String key, [bool fallback = false]) =>
      _box.read<bool>(key) ?? fallback;
  double? readDouble(String key) => _box.read<double>(key);
  Map<String, int> readIntMap(String key) {
    final raw = _box.read<Map>(key) ?? const {};
    return {
      for (final e in raw.entries)
        if (e.value is num) '${e.key}': (e.value as num).toInt(),
    };
  }

  /// Wipe user content + prefs (keeps the install itself).
  Future<void> clearAll() => _box.erase();
}
