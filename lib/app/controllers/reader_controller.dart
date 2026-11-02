import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../data/models.dart';
import '../services/quran_service.dart';
import 'settings_controller.dart';

/// Mushaf reader state: ayahs, audio playback, bookmark/last-read.
class ReaderController extends GetxController {
  ReaderController(this.surahNumber, {this.initialAyah});

  final int surahNumber;

  /// Ayah (in surah) to scroll to and highlight on open, e.g. from search.
  final int? initialAyah;
  final _quran = QuranService.instance;
  final settings = Get.find<SettingsController>();

  AudioPlayer? _player;

  /// Created on first use so opening the reader never touches native audio.
  AudioPlayer get player => _player ??= _createPlayer();

  final highlightAyah = RxnInt();
  final _ayahKeys = <int, GlobalKey>{};

  GlobalKey ayahKey(int ayahInSurah) =>
      _ayahKeys.putIfAbsent(ayahInSurah, GlobalKey.new);

  final _translationKeys = <int, GlobalKey>{};

  GlobalKey translationKey(int ayahInSurah) =>
      _translationKeys.putIfAbsent(ayahInSurah, GlobalKey.new);

  Surah get surah => _quran.surah(surahNumber);
  List<Ayah> get ayahs => _quran.ayahsFor(surahNumber);

  final playing = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final audioLoading = false.obs;
  final speed = 1.0.obs;
  final bookmarked = false.obs;
  final showTrans = true.obs;
  final tafsirLoading = false.obs;

  static const speeds = [0.75, 1.0, 1.25, 1.5];

  @override
  void onInit() {
    super.onInit();
    showTrans.value = settings.showTranslations.value;
    bookmarked.value = _quran.bookmarks.contains(surahNumber);
    final target = initialAyah;
    final valid = target != null && target >= 1 && target <= ayahs.length;
    highlightAyah.value = valid ? target : null;
    _savePosition(ayahs[valid ? target - 1 : 0]);
  }

  @override
  void onReady() {
    super.onReady();
    final target = highlightAyah.value;
    if (target != null) scrollToAyah(target);
  }

  Future<void> scrollToAyah(int ayahInSurah) async {
    final ctx = _ayahKeys[ayahInSurah]?.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      alignment: 0.25,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  AudioPlayer _createPlayer() {
    final p = AudioPlayer();
    p.onPlayerStateChanged.listen(
      (s) => playing.value = s == PlayerState.playing,
    );
    p.onDurationChanged.listen((d) => duration.value = d);
    p.onPositionChanged.listen((pos) => position.value = pos);
    p.onPlayerComplete.listen((_) {
      playing.value = false;
      position.value = Duration.zero;
    });
    return p;
  }

  int? _savedAyah;

  void _savePosition(Ayah a) {
    if (_savedAyah == a.numberInSurah) return;
    _savedAyah = a.numberInSurah;
    _quran.saveLastRead(surahNumber, a.numberInSurah, a.page);
  }

  /// Saves the ayah at the reading line (global y) once the reader's own
  /// scrolling settles.
  void saveVisiblePosition(double readingLine) {
    List<(int, double)> anchors(Map<int, GlobalKey> keys) => [
      for (final e in keys.entries)
        if (e.value.currentContext?.findRenderObject() case final RenderBox box
            when box.attached && box.hasSize)
          (e.key, box.localToGlobal(Offset.zero).dy),
    ];
    final ayah = ayahForReadingLine(
      anchors(_ayahKeys),
      anchors(_translationKeys),
      readingLine,
    );
    if (ayah != null && ayah >= 1 && ayah <= ayahs.length) {
      _savePosition(ayahs[ayah - 1]);
    }
  }

  /// The translations follow the whole Arabic text, so once the reading
  /// line is inside them, the translation being read decides.
  static int? ayahForReadingLine(
    List<(int, double)> arabic,
    List<(int, double)> translation,
    double line,
  ) {
    final inTranslation =
        translation.any((a) => a.$2 <= line) || arabic.isEmpty;
    return ayahAtLine(inTranslation ? translation : arabic, line);
  }

  /// The last ayah whose start is at or above [line]; the first ayah when
  /// none has reached it yet.
  static int? ayahAtLine(Iterable<(int, double)> anchors, double line) {
    int? best;
    int? first;
    for (final (ayah, y) in anchors) {
      if (first == null || ayah < first) first = ayah;
      if (y <= line && (best == null || ayah > best)) best = ayah;
    }
    return best ?? first;
  }

  String translationOf(int ayahInSurah) => _quran.translation(
    surahNumber,
    ayahInSurah,
    settings.translationLang.value,
  );

  Future<void> toggleAudio() async {
    if (playing.value) {
      await player.pause();
      return;
    }
    audioLoading.value = true;
    try {
      await player.setPlaybackRate(speed.value);
      await player.play(UrlSource(_quran.audioUrl(surahNumber)));
    } catch (_) {
      audioLoading.value = false;
    }
    audioLoading.value = false;
  }

  Future<void> seekTo(double seconds) async {
    await _player?.seek(Duration(seconds: seconds.toInt()));
  }

  Future<void> cycleSpeed() async {
    final i = speeds.indexOf(speed.value);
    speed.value = speeds[(i + 1) % speeds.length];
    await _player?.setPlaybackRate(speed.value);
  }

  Future<void> toggleBookmark() async {
    await _quran.toggleBookmark(surahNumber);
    bookmarked.value = _quran.bookmarks.contains(surahNumber);
  }

  Future<String?> tafsirFor(int ayahInSurah) async {
    tafsirLoading.value = true;
    final key = '$surahNumber:$ayahInSurah';
    final t = await _quran.tafsir(key, lang: Get.locale?.languageCode ?? 'en');
    tafsirLoading.value = false;
    return t;
  }

  static String fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void onClose() {
    _player?.dispose();
    super.onClose();
  }
}
