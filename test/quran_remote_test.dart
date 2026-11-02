import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/services/quran_service.dart';

void main() {
  final quran = QuranService.instance;

  group('tafsir', () {
    test('uses the by_ayah endpoint with Ibn Kathir per locale', () {
      expect(
        QuranService.tafsirUrl('2:152'),
        'https://api.quran.com/api/v4/tafsirs/169/by_ayah/2:152',
      );
      expect(
        QuranService.tafsirUrl('2:152', lang: 'ar'),
        'https://api.quran.com/api/v4/tafsirs/14/by_ayah/2:152',
      );
      expect(QuranService.tafsirEdition('sw'), 169);
    });

    test('parses the response into readable plain text', () {
      const body =
          '{"tafsir":{"resource_id":169,"text":"<h2>Muhammad&#39;s Prophecy</h2>'
          '<p>Allah says, <b>&quot;So remember Me&quot;</b></p><p>A&amp;B<br/>C</p>"}}';
      expect(
        QuranService.parseTafsir(body),
        "Muhammad's Prophecy\n\nAllah says, \"So remember Me\"\n\nA&B\nC",
      );
    });

    test('returns null for an empty or missing tafsir', () {
      expect(
        QuranService.parseTafsir('{"tafsir":{"text":"<p> </p>"}}'),
        isNull,
      );
      expect(QuranService.parseTafsir('{"tafsir":{}}'), isNull);
      expect(QuranService.parseTafsir('{}'), isNull);
    });
  });

  group('per-ayah audio', () {
    test('Abdul Basit is served at 192 kbps, the others at 128', () {
      expect(
        quran.ayahAudioUrl('ar.abdulbasitmurattal', 159),
        'https://cdn.islamic.network/quran/audio/192/ar.abdulbasitmurattal/159.mp3',
      );
      for (final e in ['ar.alafasy', 'ar.husary', 'ar.minshawi']) {
        expect(
          quran.ayahAudioUrl(e, 1),
          'https://cdn.islamic.network/quran/audio/128/$e/1.mp3',
        );
      }
    });
  });
}
