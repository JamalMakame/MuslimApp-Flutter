import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/services/quran_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final quran = QuranService.instance;
  setUpAll(quran.load);

  test('plain spellings find Uthmani waw + dagger alef words', () {
    for (final (query, key) in [
      ('الصلاة', '2:43'),
      ('الزكاة', '2:43'),
      ('الحياة الدنيا', '2:85'),
    ]) {
      final keys = quran
          .searchAyahs(query, locale: 'ar')
          .map((r) => r.verseKey);
      expect(keys, contains(key), reason: query);
    }
  });
}
