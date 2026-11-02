import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

import '../data/models.dart';
import '../services/habit_service.dart';
import '../services/audio_cache_service.dart';
import '../services/quran_service.dart';
import '../services/recitation_audio.dart';
import '../services/storage_service.dart';
import 'settings_controller.dart';

enum MemorizeStep { repeat, advance, loop, stop }

({MemorizeStep step, int index, int repetition}) stepAfterAyah({
  required int repetition,
  required int repeat,
  required int index,
  required int count,
  required bool autoAdvance,
  int rangeStart = 0,
  int? rangeEnd,
  int round = 1,
  int rounds = 1,
}) {
  final end = (rangeEnd ?? count - 1).clamp(0, count - 1);
  if (repetition < repeat) {
    return (
      step: MemorizeStep.repeat,
      index: index,
      repetition: repetition + 1,
    );
  }
  if (autoAdvance && index < end) {
    return (step: MemorizeStep.advance, index: index + 1, repetition: 1);
  }
  if (autoAdvance && round < rounds) {
    return (step: MemorizeStep.loop, index: rangeStart, repetition: 1);
  }
  return (step: MemorizeStep.stop, index: index, repetition: 1);
}

/// Local Hifz state, with optional per-ayah streaming or offline MP3 playback.
class MemorizeController extends GetxController {
  MemorizeController(
    this.surahNumber, {
    AudioCacheService? cache,
    this.initialAyah,
  }) : _cache = cache ?? AudioCacheService();

  final int surahNumber;

  /// Ayah to start on ("Memorise from here"); otherwise the saved one.
  final int? initialAyah;
  final _q = QuranService.instance;
  final _s = StorageService.instance;
  final AudioCacheService _cache;
  late final player = AudioPlayer();

  late final Surah surah = _q.surah(surahNumber);
  late final List<Ayah> ayahs = _q.ayahsFor(surahNumber);

  /// 0-based index into [ayahs].
  final ayahIndex = 0.obs;

  /// Practice range (ayah numbers, inclusive) and how many times to run it.
  final rangeFrom = 1.obs;
  final rangeTo = 1.obs;
  final rangeRepeat = 1.obs;
  final round = 1.obs;
  Ayah get ayah => ayahs[ayahIndex.value];

  /// Self-test: the ayah's words stay hidden until revealed one by one.
  final testMode = false.obs;
  final revealed = 0.obs;

  List<String> get words =>
      ayah.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  String get maskedText {
    final w = words;
    return [
      for (var i = 0; i < w.length; i++) i < revealed.value ? w[i] : '・・・',
    ].join(' ');
  }

  void revealWord() {
    if (revealed.value < words.length) revealed.value++;
  }

  void revealAll() => revealed.value = words.length;

  /// Records the self-test result and moves on to the next ayah.
  Future<void> grade(bool ok) async {
    await HabitService.instance.markHifz(surahNumber, ayah.numberInSurah, ok);
    revealed.value = 0;
    if (ayahIndex.value < ayahs.length - 1) await next();
  }

  final reciter = 'ar.alafasy'.obs;
  final repeat = 5.obs;
  final autoAdvance = true.obs;
  final speed = 1.0.obs;
  static const speeds = [0.75, 1.0, 1.25, 1.5];

  final playing = false.obs;
  final loadingAudio = false.obs;
  final playError = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;

  /// Current repetition of the active ayah (1-based for display).
  final repetition = 1.obs;

  /// Download state for (reciter, surah): null = not downloaded,
  /// 0..1 = in progress, 1 = done.
  final downloadProgress = Rxn<double>();
  final downloadedBytes = 0.obs;
  final checkingOffline = false.obs;
  final downloadError = false.obs;
  final currentAyahOffline = false.obs;
  final _activeDownloads = <String, double>{};
  String? _loadedTrack;
  int _generation = 0;
  bool _handlingCompletion = false;

  @override
  void onInit() {
    super.onInit();
    final savedReciter = _s.readStr(StorageService.kReciter, 'ar.alafasy');
    reciter.value = QuranService.reciters.containsKey(savedReciter)
        ? savedReciter
        : 'ar.alafasy';
    repeat.value = _s.readInt(StorageService.kMemRepeat, 5).clamp(1, 10);
    autoAdvance.value = _s.readBool(StorageService.kMemAutoAdvance, true);
    final savedSpeed = _s.readDouble(StorageService.kMemSpeed);
    speed.value = speeds.contains(savedSpeed) ? savedSpeed! : 1.0;
    final savedPosition = _s.read<Map>(StorageService.kMemPosition);
    final savedAyah = int.tryParse(
      '${savedPosition?[surahNumber.toString()] ?? ''}',
    );
    final restored = ayahs.indexWhere(
      (a) => a.numberInSurah == (initialAyah ?? savedAyah),
    );
    ayahIndex.value = restored < 0 ? 0 : restored;
    rangeFrom.value = ayahIndex.value + 1;
    rangeTo.value = ayahs.length;
    ever(ayahIndex, (_) => revealed.value = 0);

    unawaited(_refreshOfflineStatus());
    player.onPlayerComplete.listen((_) => unawaited(_onComplete()));
    player.onPositionChanged.listen((p) {
      if (!isClosed) position.value = p;
    });
    player.onDurationChanged.listen((d) {
      if (!isClosed) duration.value = d;
    });
    player.onPlayerStateChanged.listen((s) {
      if (isClosed) return;
      playing.value = s == PlayerState.playing;
      _reportAudio();
    });
  }

  @override
  void onClose() {
    _generation++;
    RecitationAudio.detach(this);
    _cache.close();
    player.dispose();
    super.onClose();
  }

  // ---- Playback --------------------------------------------------------------
  Future<void> play({bool restart = false}) async {
    final request = ++_generation;
    RecitationAudio.attach(
      this,
      play: play,
      pause: player.pause,
      stop: () async {
        _generation++;
        _loadedTrack = null;
        await player.stop();
      },
      next: next,
      prev: prev,
    );
    final edition = reciter.value;
    final id = ayah.number;
    final track = '$edition:$id';
    loadingAudio.value = true;
    playError.value = false;
    try {
      if (!restart &&
          _loadedTrack == track &&
          player.state == PlayerState.paused) {
        await player.resume();
      } else {
        final file = await _cache.cachedFile(edition, id);
        if (request != _generation || isClosed) return;
        await player.setPlaybackRate(speed.value);
        if (request != _generation || isClosed) return;
        await player.play(
          file == null
              ? UrlSource(_q.ayahAudioUrl(edition, id))
              : DeviceFileSource(file.path),
        );
        if (request == _generation && !isClosed) {
          _loadedTrack = track;
          currentAyahOffline.value = file != null;
        }
      }
    } catch (_) {
      if (request == _generation && !isClosed) {
        playError.value = true;
        playing.value = false;
        _loadedTrack = null;
      }
    } finally {
      if (request == _generation && !isClosed) loadingAudio.value = false;
    }
  }

  Future<void> toggle() async {
    if (loadingAudio.value) {
      _generation++;
      _loadedTrack = null;
      await player.stop();
      loadingAudio.value = false;
    } else if (playing.value) {
      await player.pause();
    } else {
      await play();
    }
  }

  Future<void> _onComplete() async {
    if (_handlingCompletion ||
        isClosed ||
        _loadedTrack != '${reciter.value}:${ayah.number}') {
      return;
    }
    _handlingCompletion = true;
    try {
      position.value = Duration.zero;
      final transition = stepAfterAyah(
        repetition: repetition.value,
        repeat: repeat.value,
        index: ayahIndex.value,
        count: ayahs.length,
        autoAdvance: autoAdvance.value,
        rangeStart: rangeFrom.value - 1,
        rangeEnd: rangeTo.value - 1,
        round: round.value,
        rounds: rangeRepeat.value,
      );
      if (transition.step == MemorizeStep.loop) round.value++;
      repetition.value = transition.repetition;
      ayahIndex.value = transition.index;
      switch (transition.step) {
        case MemorizeStep.repeat:
          await play(restart: true);
        case MemorizeStep.advance || MemorizeStep.loop:
          _loadedTrack = null;
          currentAyahOffline.value = false;
          unawaited(_refreshCurrentAyahOffline());
          await _persistPosition();
          await play(restart: true);
        case MemorizeStep.stop:
          playing.value = false;
          _loadedTrack = null;
      }
    } finally {
      _handlingCompletion = false;
    }
  }

  Future<void> goTo(int index) async {
    final nextIndex = index.clamp(0, ayahs.length - 1);
    if (nextIndex == ayahIndex.value) return;
    final wasPlaying = playing.value || loadingAudio.value;
    _generation++;
    _loadedTrack = null;
    await player.stop();
    ayahIndex.value = nextIndex;
    currentAyahOffline.value = false;
    repetition.value = 1;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    playError.value = false;
    loadingAudio.value = false;
    unawaited(_refreshCurrentAyahOffline());
    await _persistPosition();
    if (wasPlaying) await play(restart: true);
  }

  /// Practise ayahs [from]–[to], [rounds] times, starting at [from].
  Future<void> setRange(int from, int to, int rounds) async {
    final a = from.clamp(1, ayahs.length);
    final b = to.clamp(a, ayahs.length);
    rangeFrom.value = a;
    rangeTo.value = b;
    rangeRepeat.value = rounds.clamp(1, 10);
    round.value = 1;
    if (ayahIndex.value != a - 1) {
      await goTo(a - 1);
      return;
    }
    // Already on the first ayah: start its repetitions over.
    repetition.value = 1;
    if (playing.value || loadingAudio.value) await play(restart: true);
  }

  void _reportAudio() => RecitationAudio.report(
    this,
    title: '$surahName $surahNumber:${ayah.numberInSurah}',
    artist: reciterName,
    playing: playing.value,
    loading: loadingAudio.value,
  );

  Future<void> prev() => goTo(ayahIndex.value - 1);
  Future<void> next() => goTo(ayahIndex.value + 1);

  Future<void> seekBy(int seconds) async {
    if (duration.value == Duration.zero) return;
    final target = position.value + Duration(seconds: seconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration.value ? duration.value : target);
    await player.seek(clamped);
  }

  Future<void> setRepeat(int n) async {
    repeat.value = n.clamp(1, 10);
    if (repetition.value > repeat.value) repetition.value = repeat.value;
    await _s.write(StorageService.kMemRepeat, repeat.value);
  }

  Future<void> setAutoAdvance(bool v) async {
    autoAdvance.value = v;
    await _s.write(StorageService.kMemAutoAdvance, v);
  }

  Future<void> setSpeed(double v) async {
    if (!speeds.contains(v)) return;
    speed.value = v;
    await _s.write(StorageService.kMemSpeed, v);
    if (playing.value) await player.setPlaybackRate(v);
  }

  Future<void> setReciter(String edition) async {
    if (!QuranService.reciters.containsKey(edition) ||
        reciter.value == edition) {
      return;
    }
    final wasPlaying = playing.value || loadingAudio.value;
    _generation++;
    _loadedTrack = null;
    await player.stop();
    reciter.value = edition;
    if (Get.isRegistered<SettingsController>()) {
      await Get.find<SettingsController>().setReciter(edition);
    } else {
      await _s.write(StorageService.kReciter, edition);
    }
    repetition.value = 1;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    loadingAudio.value = false;
    await _refreshOfflineStatus();
    if (wasPlaying) await play(restart: true);
  }

  // ---- Offline download -------------------------------------------------------
  Future<void> _refreshCurrentAyahOffline() async {
    final edition = reciter.value;
    final id = ayah.number;
    try {
      final cached = await _cache.cachedFile(edition, id);
      if (!isClosed && reciter.value == edition && ayah.number == id) {
        currentAyahOffline.value = cached != null;
      }
    } catch (_) {
      if (!isClosed && reciter.value == edition) {
        currentAyahOffline.value = false;
      }
    }
  }

  Future<void> _refreshOfflineStatus() async {
    final edition = reciter.value;
    checkingOffline.value = true;
    downloadedBytes.value = 0;
    currentAyahOffline.value = false;
    downloadProgress.value = _activeDownloads[edition];
    try {
      await _refreshCurrentAyahOffline();
      final bytes = await _cache.verifiedBytes(
        edition,
        surahNumber,
        _q.globalAyahs(surahNumber),
      );
      if (!isClosed && reciter.value == edition) {
        downloadedBytes.value = bytes ?? 0;
        if (!_activeDownloads.containsKey(edition)) {
          downloadProgress.value = bytes == null ? null : 1;
        }
      }
    } catch (_) {
      if (!isClosed && reciter.value == edition) downloadError.value = true;
    } finally {
      if (!isClosed && reciter.value == edition) checkingOffline.value = false;
    }
  }

  Future<void> downloadSurah() async {
    final edition = reciter.value;
    if (_activeDownloads.containsKey(edition) || downloadProgress.value == 1) {
      return;
    }
    _activeDownloads[edition] = 0;
    downloadProgress.value = 0;
    downloadError.value = false;
    try {
      final bytes = await _cache.downloadSurah(
        edition,
        surahNumber,
        _q.globalAyahs(surahNumber),
        isCancelled: () => isClosed,
        onProgress: (p) {
          _activeDownloads[edition] = p.clamp(0, 0.99);
          if (!isClosed && reciter.value == edition) {
            downloadProgress.value = _activeDownloads[edition];
          }
        },
      );
      if (!isClosed && reciter.value == edition) {
        downloadedBytes.value = bytes;
        currentAyahOffline.value = true;
        downloadProgress.value = 1;
      }
    } catch (_) {
      if (!isClosed && reciter.value == edition) {
        downloadError.value = true;
        downloadProgress.value = null;
      }
    } finally {
      _activeDownloads.remove(edition);
    }
  }

  Future<void> deleteDownload() async {
    final edition = reciter.value;
    if (_activeDownloads.containsKey(edition)) return;
    _generation++;
    if (_loadedTrack?.startsWith('$edition:') ?? false) {
      _loadedTrack = null;
      await player.stop();
      playing.value = false;
    }
    try {
      await _cache.deleteSurah(
        edition,
        surahNumber,
        _q.globalAyahs(surahNumber),
      );
      if (!isClosed && reciter.value == edition) {
        downloadProgress.value = null;
        downloadedBytes.value = 0;
        currentAyahOffline.value = false;
        downloadError.value = false;
      }
    } catch (_) {
      if (!isClosed && reciter.value == edition) downloadError.value = true;
    }
  }

  Future<void> _persistPosition() async {
    final saved = Map<String, dynamic>.from(
      _s.read<Map>(StorageService.kMemPosition) ?? {},
    );
    saved[surahNumber.toString()] = ayah.numberInSurah;
    await _s.write(StorageService.kMemPosition, saved);
  }

  // ---- Display helpers ----------------------------------------------------
  String get surahName =>
      Get.locale?.languageCode == 'ar' ? surah.nameArabic : surah.nameSimple;

  String get translation {
    final settings = Get.find<SettingsController>();
    if (!settings.showTranslations.value) return '';
    final language = _s.has(StorageService.kTranslationLang)
        ? settings.translationLang.value
        : (settings.localeCode.value == 'sw' ? 'sw' : 'en');
    return language == 'ar'
        ? ''
        : _q.translation(surahNumber, ayah.numberInSurah, language);
  }

  String get reciterName =>
      QuranService.reciters[reciter.value] ?? reciter.value;

  String fmt(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
