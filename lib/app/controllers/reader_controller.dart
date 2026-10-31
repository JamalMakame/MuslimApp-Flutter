import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

import '../data/models.dart';
import '../services/quran_service.dart';
import 'settings_controller.dart';

/// Mushaf reader state: ayahs, audio playback, bookmark/last-read.
class ReaderController extends GetxController {
  ReaderController(this.surahNumber);

  final int surahNumber;
  final _quran = QuranService.instance;
  final settings = Get.find<SettingsController>();

  final player = AudioPlayer();

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
    player.onPlayerStateChanged.listen(
      (s) => playing.value = s == PlayerState.playing,
    );
    player.onDurationChanged.listen((d) => duration.value = d);
    player.onPositionChanged.listen((p) => position.value = p);
    player.onPlayerComplete.listen((_) {
      playing.value = false;
      position.value = Duration.zero;
    });
    _savePosition();
  }

  void _savePosition() {
    final first = ayahs.first;
    _quran.saveLastRead(surahNumber, first.numberInSurah, first.page);
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

  Future<void> seekTo(double seconds) =>
      player.seek(Duration(seconds: seconds.toInt()));

  Future<void> cycleSpeed() async {
    final i = speeds.indexOf(speed.value);
    speed.value = speeds[(i + 1) % speeds.length];
    await player.setPlaybackRate(speed.value);
  }

  Future<void> toggleBookmark() async {
    await _quran.toggleBookmark(surahNumber);
    bookmarked.value = _quran.bookmarks.contains(surahNumber);
  }

  Future<String?> tafsirFor(int ayahInSurah) async {
    tafsirLoading.value = true;
    final key = '$surahNumber:$ayahInSurah';
    final t = await _quran.tafsir(key);
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
    player.dispose();
    super.onClose();
  }
}
