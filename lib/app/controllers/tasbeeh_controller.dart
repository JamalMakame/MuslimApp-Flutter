import 'package:flutter/services.dart' show HapticFeedback;
import 'package:get/get.dart';

import '../ui/widgets/celebration.dart';
import '../data/models.dart';
import '../services/storage_service.dart';

/// Digital tasbeeh — phrase picker, tap dial, target laps, daily total,
/// streak, haptics. All persisted locally.
class TasbeehController extends GetxController {
  final _s = StorageService.instance;

  static const phrases = <TasbeehPhrase>[
    TasbeehPhrase(
      key: 'phraseSubhanallah',
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: 'Subḥān Allāh',
      meaningKey: 'meaningSubhanallah',
    ),
    TasbeehPhrase(
      key: 'phraseAlhamdulillah',
      arabic: 'ٱلْحَمْدُ لِلَّٰهِ',
      transliteration: 'Alḥamdu lillāh',
      meaningKey: 'meaningAlhamdulillah',
    ),
    TasbeehPhrase(
      key: 'phraseAllahuAkbar',
      arabic: 'ٱللَّهُ أَكْبَرُ',
      transliteration: 'Allāhu akbar',
      meaningKey: 'meaningAllahuAkbar',
    ),
    TasbeehPhrase(
      key: 'phraseLaIlaha',
      arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
      transliteration: 'Lā ilāha illallāh',
      meaningKey: 'meaningLaIlaha',
    ),
    TasbeehPhrase(
      key: 'phraseAstaghfirullah',
      arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ',
      transliteration: 'Astaghfirullāh',
      meaningKey: 'meaningAstaghfirullah',
    ),
  ];

  static const targets = [33, 100];

  final phraseIndex = 0.obs;
  final count = 0.obs; // current lap count
  final lap = 1.obs;
  final target = 33.obs;
  final totalToday = 0.obs;
  final streak = 1.obs;
  final haptics = true.obs;

  TasbeehPhrase get phrase => phrases[phraseIndex.value];
  double get progress => target.value == 0 ? 0 : count.value / target.value;

  @override
  void onInit() {
    super.onInit();
    phraseIndex.value = _s.readInt(StorageService.kTasbeehPhrase);
    target.value = _s.readInt(StorageService.kTasbeehTarget, 33);
    haptics.value = _s.readBool(StorageService.kTasbeehHaptics, true);
    streak.value = _s.readInt(StorageService.kTasbeehStreak, 1);
    _loadDaily();
  }

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  void _loadDaily() {
    final savedDate = _s.readStr(StorageService.kTasbeehDate);
    if (savedDate == _today) {
      count.value = _s.readInt(StorageService.kTasbeehCount);
      lap.value = _s.readInt(StorageService.kTasbeehLap, 1);
      totalToday.value = _s.readInt(StorageService.kTasbeehTotal);
    } else {
      // New day — bump streak if yesterday had activity, else reset to 1.
      final yesterday = DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
      if (savedDate == yesterday &&
          _s.readInt(StorageService.kTasbeehTotal) > 0) {
        streak.value = streak.value + 1;
      } else if (savedDate.isNotEmpty) {
        streak.value = 1;
      }
      count.value = 0;
      lap.value = 1;
      totalToday.value = 0;
      _persist();
    }
  }

  Future<void> tap() async {
    count.value++;
    totalToday.value++;
    if (haptics.value) {
      if (count.value >= target.value) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.selectionClick();
      }
    }
    if (count.value >= target.value) {
      count.value = 0;
      lap.value++;
      // The tap above already gave the round's haptic when haptics are on.
      celebrateIf(
        true,
        'tasbeehLapDone'.trParams({'n': '${lap.value - 1}'}),
        haptic: false,
      );
    }
    await _persist();
  }

  Future<void> reset() async {
    count.value = 0;
    await _persist();
  }

  Future<void> selectPhrase(int i) async {
    phraseIndex.value = i;
    count.value = 0;
    lap.value = 1;
    await _s.write(StorageService.kTasbeehPhrase, i);
    await _persist();
  }

  Future<void> cycleTarget() async {
    final i = targets.indexOf(target.value);
    target.value = targets[(i + 1) % targets.length];
    count.value = 0;
    lap.value = 1;
    await _s.write(StorageService.kTasbeehTarget, target.value);
    await _persist();
  }

  Future<void> toggleHaptics() async {
    haptics.toggle();
    await _s.write(StorageService.kTasbeehHaptics, haptics.value);
  }

  Future<void> _persist() async {
    await _s.write(StorageService.kTasbeehDate, _today);
    await _s.write(StorageService.kTasbeehCount, count.value);
    await _s.write(StorageService.kTasbeehLap, lap.value);
    await _s.write(StorageService.kTasbeehTotal, totalToday.value);
    await _s.write(StorageService.kTasbeehStreak, streak.value);
  }
}
