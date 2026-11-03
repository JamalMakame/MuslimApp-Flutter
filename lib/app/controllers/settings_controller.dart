import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/prayer_service.dart';
import '../services/storage_service.dart';

/// Central persisted preferences — locale, prayer calc, appearance, privacy.
class SettingsController extends GetxController {
  final _s = StorageService.instance;

  static const localeCodes = ['en', 'ar', 'sw'];
  static const methods = [
    'umm_al_qura',
    'mwl',
    'egypt',
    'karachi',
    'isna',
    'dubai',
    'kuwait',
    'qatar',
    'singapore',
    'turkey',
    'tehran',
    'moonsighting',
  ];
  static const highLatRules = ['middle', 'seventh', 'angle'];

  /// Reminder choices: -1 off, 0 at the time, else minutes before.
  static const reminderLeads = [-1, 0, 5, 10, 15, 30];
  static const madhabs = ['shafi', 'hanafi'];
  static const translationLangs = ['en', 'sw', 'ar'];

  // ---- Reactive state ------------------------------------------------------
  final localeCode = 'en'.obs;
  final calcMethod = 'umm_al_qura'.obs;
  final madhab = 'shafi'.obs;
  final themeMode = 'system'.obs; // light | system | dark
  final textScale = 1.obs; // 0 small, 1 medium, 2 large
  final notifyPrayers = false.obs;
  final highLatRule = 'middle'.obs;
  final prayerOffsets = <String, int>{}.obs;
  final prayerLeads = <String, int>{}.obs;
  final azkarReminders = false.obs;
  final adhanSound = false.obs;
  final prayerCheckIn = true.obs;
  final showTranslations = true.obs;
  final azkarTranslit = false.obs;
  final ayahAudio = false.obs;
  final translationLang = 'en'.obs;

  /// Reciter for ayah-by-ayah audio in the reader and Hifz.
  final reciter = 'ar.alafasy'.obs;

  final latitude = Rx<double?>(null);
  final longitude = Rx<double?>(null);
  final city = ''.obs;
  final country = ''.obs;
  final locationSource = ''.obs; // 'gps' | 'manual'

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  /// Re-reads every preference from storage (also after local data is
  /// cleared, so app-wide listeners see the defaults).
  void reload() {
    reciter.value = _s.readStr(StorageService.kReciter, 'ar.alafasy');
    localeCode.value = _s.readStr(StorageService.kLocale, 'en');
    calcMethod.value = _s.readStr(StorageService.kCalcMethod, 'umm_al_qura');
    madhab.value = _s.readStr(StorageService.kMadhab, 'shafi');
    themeMode.value = _s.readStr(StorageService.kThemeMode, 'system');
    textScale.value = _s.readInt(StorageService.kTextScale, 1);
    notifyPrayers.value = _s.readBool(StorageService.kNotifyPrayers, false);
    highLatRule.value = _s.readStr(StorageService.kHighLatRule, 'middle');
    prayerOffsets.assignAll(_s.readIntMap(StorageService.kPrayerOffsets));
    prayerLeads.assignAll(_s.readIntMap(StorageService.kPrayerLeads));
    azkarReminders.value = _s.readBool(StorageService.kAzkarReminders, false);
    adhanSound.value = _s.readBool(StorageService.kAdhanSound, false);
    prayerCheckIn.value = _s.readBool(StorageService.kPrayerCheckIn, true);
    showTranslations.value = _s.readBool(
      StorageService.kShowTranslations,
      true,
    );
    ayahAudio.value = _s.readBool(StorageService.kAyahAudio, false);
    azkarTranslit.value = _s.readBool(StorageService.kAzkarTranslit, false);
    translationLang.value = _s.readStr(StorageService.kTranslationLang, 'en');
    latitude.value = _s.readDouble(StorageService.kLat);
    longitude.value = _s.readDouble(StorageService.kLng);
    city.value = _s.readStr(StorageService.kCity);
    country.value = _s.readStr(StorageService.kCountry);
    locationSource.value = _s.readStr(StorageService.kLocSource);
  }

  Locale get locale => Locale(localeCode.value);
  bool get isRtl => localeCode.value == 'ar';
  bool get hasLocation => latitude.value != null && longitude.value != null;

  /// Font scale applied to Quran text: small 1.0, medium 1.15, large 1.35.
  double get quranScale => switch (textScale.value) {
    0 => 0.92,
    2 => 1.32,
    _ => 1.12,
  };

  String get placeLabel {
    if (city.value.isEmpty && country.value.isEmpty) {
      return 'unknownPlace'.tr;
    }
    return [city.value, country.value].where((e) => e.isNotEmpty).join(', ');
  }

  Future<void> setLocale(String code) async {
    localeCode.value = code;
    await _s.write(StorageService.kLocale, code);
    Get.updateLocale(Locale(code));
  }

  Future<void> setCalcMethod(String m) =>
      _persist(calcMethod, m, StorageService.kCalcMethod);
  Future<void> setMadhab(String m) =>
      _persist(madhab, m, StorageService.kMadhab);
  Future<void> setThemeMode(String m) =>
      _persist(themeMode, m, StorageService.kThemeMode);
  Future<void> setTextScale(int v) =>
      _persist(textScale, v, StorageService.kTextScale);
  Future<void> setNotifyPrayers(bool v) =>
      _persist(notifyPrayers, v, StorageService.kNotifyPrayers);
  Future<void> setHighLatRule(String v) =>
      _persist(highLatRule, v, StorageService.kHighLatRule);
  Future<void> setAzkarReminders(bool v) =>
      _persist(azkarReminders, v, StorageService.kAzkarReminders);
  Future<void> setAdhanSound(bool v) =>
      _persist(adhanSound, v, StorageService.kAdhanSound);

  Future<void> setPrayerCheckIn(bool v) =>
      _persist(prayerCheckIn, v, StorageService.kPrayerCheckIn);

  /// Minutes added to [prayer]'s computed time (-30..30).
  Future<void> setPrayerOffset(String prayer, int minutes) async {
    prayerOffsets[prayer] = minutes.clamp(-30, 30);
    await _s.write(StorageService.kPrayerOffsets, Map.of(prayerOffsets));
  }

  /// When [prayer]'s reminder fires: -1 off, 0 at the time, else minutes
  /// before.
  Future<void> setPrayerLead(String prayer, int minutes) async {
    prayerLeads[prayer] = minutes;
    await _s.write(StorageService.kPrayerLeads, Map.of(prayerLeads));
  }

  int leadFor(String prayer) => prayerLeads[prayer] ?? 0;

  PrayerTuning get tuning =>
      PrayerTuning(highLat: highLatRule.value, offsets: Map.of(prayerOffsets));

  Future<void> setShowTranslations(bool v) =>
      _persist(showTranslations, v, StorageService.kShowTranslations);
  Future<void> setAzkarTranslit(bool v) =>
      _persist(azkarTranslit, v, StorageService.kAzkarTranslit);
  Future<void> setAyahAudio(bool v) =>
      _persist(ayahAudio, v, StorageService.kAyahAudio);
  Future<void> setReciter(String v) =>
      _persist(reciter, v, StorageService.kReciter);
  Future<void> setTranslationLang(String v) =>
      _persist(translationLang, v, StorageService.kTranslationLang);

  Future<void> setLocation({
    required double lat,
    required double lng,
    required String city,
    required String country,
    required String source,
  }) async {
    latitude.value = lat;
    longitude.value = lng;
    this.city.value = city;
    this.country.value = country;
    locationSource.value = source;
    await _s.write(StorageService.kLat, lat);
    await _s.write(StorageService.kLng, lng);
    await _s.write(StorageService.kCity, city);
    await _s.write(StorageService.kCountry, country);
    await _s.write(StorageService.kLocSource, source);
  }

  Future<void> _persist<T>(Rx<T> rx, T v, String key) async {
    rx.value = v;
    await _s.write(key, v);
  }
}
