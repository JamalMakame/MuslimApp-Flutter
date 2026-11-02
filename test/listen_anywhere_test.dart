import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/controllers/memorize_controller.dart';
import 'package:fquran_app/app/services/recitation_audio.dart';

void main() {
  group('range practice', () {
    ({MemorizeStep step, int index, int repetition}) decide(
      int index, {
      int repetition = 3,
      int round = 1,
      int rounds = 2,
      bool auto = true,
    }) => stepAfterAyah(
      repetition: repetition,
      repeat: 3,
      index: index,
      count: 286,
      autoAdvance: auto,
      rangeStart: 254,
      rangeEnd: 256,
      round: round,
      rounds: rounds,
    );

    test('each ayah repeats before moving on', () {
      expect(decide(254, repetition: 1).step, MemorizeStep.repeat);
    });

    test('advances inside the range, loops at its end, then stops', () {
      expect(decide(255), (
        step: MemorizeStep.advance,
        index: 256,
        repetition: 1,
      ));
      expect(decide(256), (step: MemorizeStep.loop, index: 254, repetition: 1));
      expect(decide(256, round: 2).step, MemorizeStep.stop);
    });

    test('without auto-advance the range does not loop', () {
      expect(decide(256, auto: false).step, MemorizeStep.stop);
    });

    test('defaults keep the old whole-surah behaviour', () {
      final r = stepAfterAyah(
        repetition: 1,
        repeat: 1,
        index: 6,
        count: 7,
        autoAdvance: true,
      );
      expect(r.step, MemorizeStep.stop);
    });
  });

  test('lock-screen controls are a no-op without the audio service', () {
    final owner = Object();
    RecitationAudio.attach(
      owner,
      play: () async {},
      pause: () async {},
      stop: () async {},
    );
    RecitationAudio.report(
      owner,
      title: 'Al-Baqarah 2:255',
      artist: 'Al-Husary',
      playing: true,
    );
    RecitationAudio.detach(owner);
    expect(RecitationAudio.instance, isNull);
  });
}
