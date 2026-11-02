import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../data/models.dart';
import '../services/audio_cache_service.dart';
import '../services/quran_service.dart';
import '../services/recitation_audio.dart';
import '../services/habit_service.dart';
import '../services/storage_service.dart';
import 'settings_controller.dart';

/// Reader state: one list item per ayah (built lazily), the reading
/// position, surah or ayah-by-ayah audio, bookmarks.
///
/// List items: 0 is the surah header, 1…n are the ayahs (index = ayah
/// number), n + 1 is the previous / next surah footer.
class ReaderController extends GetxController {
  ReaderController(this.surahNumber, {this.initialAyah});

  final int surahNumber;

  /// Ayah (in surah) to open at and highlight, e.g. from search or Go to.
  final int? initialAyah;
  final _quran = QuranService.instance;
  final settings = Get.find<SettingsController>();

  AudioPlayer? _player;

  /// Created on first use so opening the reader never touches native audio.
  AudioPlayer get player => _player ??= _createPlayer();
  AudioCacheService? _cache;

  final itemScroll = ItemScrollController();
  final positions = ItemPositionsListener.create();

  /// Where the reader opens: the target ayah, or the header.
  late final int initialIndex;

  final highlightAyah = RxnInt();

  /// The ayah at the reading line: drives the Juz / Hizb / Page chips.
  final current = Rxn<Ayah>();

  final _ayahKeys = <int, GlobalKey>{};

  /// Key of an ayah's block (exists only while it is built).
  GlobalKey ayahKey(int ayahInSurah) =>
      _ayahKeys.putIfAbsent(ayahInSurah, GlobalKey.new);

  Surah get surah => _quran.surah(surahNumber);
  List<Ayah> get ayahs => _quran.ayahsFor(surahNumber);

  final playing = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final audioLoading = false.obs;
  final speed = 1.0.obs;
  final showTrans = true.obs;
  final tafsirLoading = false.obs;

  /// The ayah being recited in ayah-by-ayah mode; null for the full surah.
  final playingAyah = RxnInt();

  /// Bumped on each play so a late completion of an old track is ignored.
  int _generation = 0;

  static const speeds = [0.75, 1.0, 1.25, 1.5];

  String get reciter {
    final saved = StorageService.instance.readStr(
      StorageService.kReciter,
      'ar.alafasy',
    );
    return QuranService.reciters.containsKey(saved) ? saved : 'ar.alafasy';
  }

  @override
  void onInit() {
    super.onInit();
    showTrans.value = settings.showTranslations.value;
    final target = initialAyah;
    final valid = target != null && target >= 1 && target <= ayahs.length;
    highlightAyah.value = valid ? target : null;
    initialIndex = valid ? target : 0;
    current.value = ayahs[valid ? target - 1 : 0];
  }

  /// Saving waits for the first frame: the controller is created while the
  /// route builds, and Home / the index rebuild on a new last-read.
  @override
  void onReady() {
    super.onReady();
    _savePosition(current.value!);
  }

  bool isBookmarked(int ayahInSurah) =>
      _quran.bookmarkAt(surahNumber, ayahInSurah) != null;

  Future<void> scrollToAyah(int ayahInSurah) async {
    if (!itemScroll.isAttached) return;
    await itemScroll.scrollTo(
      index: ayahInSurah,
      alignment: 0.08,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  /// Highlights and scrolls to [ayahInSurah] in this surah (Go to, links).
  Future<void> jumpTo(int ayahInSurah) async {
    if (ayahInSurah < 1 || ayahInSurah > ayahs.length) return;
    highlightAyah.value = ayahInSurah;
    _savePosition(ayahs[ayahInSurah - 1]);
    await scrollToAyah(ayahInSurah);
  }

  AudioPlayer _createPlayer() {
    final p = AudioPlayer();
    p.onPlayerStateChanged.listen((s) {
      if (isClosed) return;
      playing.value = s == PlayerState.playing;
      _reportAudio();
    });
    p.onDurationChanged.listen((d) {
      if (!isClosed) duration.value = d;
    });
    p.onPositionChanged.listen((pos) {
      if (!isClosed) position.value = pos;
    });
    p.onPlayerComplete.listen((_) => unawaited(_onComplete()));
    return p;
  }

  Future<void> _onComplete() async {
    if (isClosed) return;
    final gen = _generation;
    final ayah = playingAyah.value;
    if (ayah != null && ayah < ayahs.length) {
      await playFrom(ayah + 1);
      return;
    }
    if (gen != _generation) return;
    playing.value = false;
    playingAyah.value = null;
    position.value = Duration.zero;
  }

  int? _savedAyah;

  void _savePosition(Ayah a) {
    current.value = a;
    if (_savedAyah == a.numberInSurah) return;
    _savedAyah = a.numberInSurah;
    _quran.saveLastRead(surahNumber, a.numberInSurah, a.page);
    HabitService.instance.recordPage(a.page);
  }

  /// Saves the ayah at the reading line (a quarter down the list) once the
  /// reader's own scrolling settles.
  void saveVisiblePosition() {
    final ayah = ayahAtLine([
      for (final p in positions.itemPositions.value)
        if (p.index >= 1 && p.index <= ayahs.length)
          (p.index, p.itemLeadingEdge),
    ], 0.25);
    if (ayah != null) _savePosition(ayahs[ayah - 1]);
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

  /// The chosen translation; empty when the reader is set to Arabic only.
  String translationOf(int ayahInSurah) {
    final lang = settings.translationLang.value;
    return lang == 'ar'
        ? ''
        : _quran.translation(surahNumber, ayahInSurah, lang);
  }

  /// Recites from [ayahInSurah] to the end of the surah, one ayah at a
  /// time (downloaded Hifz audio when present), following along.
  Future<void> playFrom(int ayahInSurah) async {
    if (ayahInSurah < 1 || ayahInSurah > ayahs.length) return;
    final gen = ++_generation;
    _attachAudio(ayahMode: true);
    playingAyah.value = ayahInSurah;
    _reportAudio();
    highlightAyah.value = ayahInSurah;
    _savePosition(ayahs[ayahInSurah - 1]);
    unawaited(scrollToAyah(ayahInSurah));
    audioLoading.value = true;
    try {
      final edition = reciter;
      final id = ayahs[ayahInSurah - 1].number;
      final file = await (_cache ??= AudioCacheService()).cachedFile(
        edition,
        id,
      );
      if (gen != _generation || isClosed) return;
      await player.stop();
      await player.setPlaybackRate(speed.value);
      await player.play(
        file == null
            ? UrlSource(_quran.ayahAudioUrl(edition, id))
            : DeviceFileSource(file.path),
      );
    } catch (_) {
      if (gen == _generation) playingAyah.value = null;
    } finally {
      if (gen == _generation) audioLoading.value = false;
    }
  }

  Future<void> toggleAudio() async {
    if (playing.value) {
      await player.pause();
      return;
    }
    if (playingAyah.value != null && position.value > Duration.zero) {
      // Hifz may have taken the lock-screen controls meanwhile.
      _attachAudio(ayahMode: true);
      await player.resume();
      return;
    }
    // The full-surah stream is Alafasy; other reciters play ayah by ayah.
    if (reciter != 'ar.alafasy') {
      await playFrom(current.value?.numberInSurah ?? 1);
      return;
    }
    _generation++;
    _attachAudio(ayahMode: false);
    playingAyah.value = null;
    audioLoading.value = true;
    try {
      await player.setPlaybackRate(speed.value);
      await player.play(UrlSource(_quran.audioUrl(surahNumber)));
    } catch (_) {
      // Shown as not playing; the user can retry.
    } finally {
      audioLoading.value = false;
    }
  }

  /// Hands the lock-screen / notification controls to this reader.
  /// Previous / next ayah only exist in ayah-by-ayah mode.
  void _attachAudio({required bool ayahMode}) => RecitationAudio.attach(
    this,
    play: () async {
      if (!playing.value) await toggleAudio();
    },
    pause: pauseAudio,
    stop: () async {
      _generation++;
      playingAyah.value = null;
      await _player?.stop();
    },
    next: ayahMode
        ? () async {
            final n = playingAyah.value;
            if (n != null) await playFrom(n + 1);
          }
        : null,
    prev: ayahMode
        ? () async {
            final n = playingAyah.value;
            if (n != null) await playFrom(n - 1);
          }
        : null,
  );

  void _reportAudio() {
    final n = playingAyah.value;
    RecitationAudio.report(
      this,
      title: n == null
          ? 'fullSurah'.trParams({'name': surah.nameSimple})
          : 'playingAyah'.trParams({'name': surah.nameSimple, 'n': '$n'}),
      artist: n == null
          ? 'misharyAlafasy'.tr
          : QuranService.reciters[reciter] ?? '',
      playing: playing.value,
      loading: audioLoading.value,
    );
  }

  Future<void> pauseAudio() async {
    if (playing.value) await _player?.pause();
  }

  Future<void> seekTo(double seconds) async {
    await _player?.seek(Duration(seconds: seconds.toInt()));
  }

  Future<void> cycleSpeed() async {
    final i = speeds.indexOf(speed.value);
    speed.value = speeds[(i + 1) % speeds.length];
    await _player?.setPlaybackRate(speed.value);
  }

  /// Bookmarks the ayah being read, or removes its bookmark.
  Future<bool> toggleCurrentBookmark() async {
    final a = current.value?.numberInSurah ?? 1;
    if (isBookmarked(a)) {
      await _quran.removeBookmark(surahNumber, a);
      return false;
    }
    await _quran.saveBookmark(surahNumber, a);
    return true;
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
    _generation++;
    RecitationAudio.detach(this);
    _player?.dispose();
    _cache?.close();
    super.onClose();
  }
}
