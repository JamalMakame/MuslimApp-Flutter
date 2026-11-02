/// Approximate Latin transliteration of fully vowelled Arabic (azkar text),
/// generated from the harakat: no dictionary, so it is a reading aid only.
class Transliteration {
  Transliteration._();

  static const _letters = {
    'ب': 'b', 'ت': 't', 'ث': 'th', 'ج': 'j', 'ح': 'h', 'خ': 'kh', //
    'د': 'd', 'ذ': 'dh', 'ر': 'r', 'ز': 'z', 'س': 's', 'ش': 'sh',
    'ص': 's', 'ض': 'd', 'ط': 't', 'ظ': 'z', 'ع': "'", 'غ': 'gh',
    'ف': 'f', 'ق': 'q', 'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n',
    'ه': 'h', 'و': 'w', 'ي': 'y', 'ء': "'", 'أ': "'", 'إ': "'",
    'ؤ': "'", 'ئ': "'",
  };
  static const _vowels = {
    '\u064E': 'a', '\u0650': 'i', '\u064F': 'u', //
    '\u064B': 'an', '\u064D': 'in', '\u064C': 'un', '\u0670': 'a',
  };
  static const _shadda = '\u0651';
  static const _sukun = '\u0652';
  static const _sun = 'تثدذرزسشصضطظلن';
  static final _strip = RegExp('[\u0640\u06D6-\u06ED\u0653-\u065F]');
  static final _marks = RegExp('[\u064B-\u0652\u0670]');

  static const _allah = {
    'الله': 'Allāh', 'والله': 'wallāh', 'بالله': 'billāh', //
    'لله': 'lillāh', 'فالله': 'fallāh', 'تالله': 'tallāh',
    'اللهم': 'Allāhumma', 'ولله': 'walillāh',
  };

  static String of(String arabic) {
    final words = arabic
        .replaceAll(_strip, '')
        .replaceAll('ٱ', 'ا')
        .replaceAll('،', ',')
        .replaceAll('؛', ';')
        .replaceAll('؟', '?')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    return words.map(_word).where((w) => w.isNotEmpty).join(' ');
  }

  static String _word(String w) {
    final bare = w
        .replaceAll(_marks, '')
        .replaceAll(RegExp(r'[^\u0621-\u064A]'), '');
    final allah = _allah[bare];
    if (allah != null) {
      final last = w.replaceAll(RegExp(r'[^\u064B-\u0652]'), '');
      final end = last.isEmpty ? '' : (_vowels[last[last.length - 1]] ?? '');
      return allah.endsWith('a') ? allah : allah + end;
    }
    final chars = w.split('');
    final out = StringBuffer();
    var start = true;
    for (var i = 0; i < chars.length; i++) {
      final ch = chars[i];
      final next = i + 1 < chars.length ? chars[i + 1] : '';
      if (_vowels.containsKey(ch)) {
        final prev = out.toString();
        if (ch == '\u064B' && prev.endsWith('a')) continue;
        out.write(_vowels[ch]);
        continue;
      }
      if (ch == _sukun || ch == _shadda) continue;
      if (ch == 'ا' || ch == 'آ') {
        // The article: alif + unvowelled lam.
        if (next == 'ل' && !_vowels.containsKey(_after(chars, i + 1))) {
          final cons = _nextLetter(chars, i + 2);
          final sun = cons != null && _sun.contains(cons.$1) && cons.$2;
          final lam = sun ? _letters[cons.$1]! : 'l';
          out.write(start || !_endsVowel(out) ? 'a$lam-' : '$lam-');
          i++;
          if (sun) _skipShadda.add(cons.$3);
          start = false;
          continue;
        }
        if (ch == 'آ') {
          out.write(start ? 'ā' : "'ā");
        } else if (!start && !out.toString().endsWith('an')) {
          out.write(_endsVowel(out) ? 'a' : 'ā');
        } else if (start && !_vowels.containsKey(next)) {
          out.write('a');
        }
        start = false;
        continue;
      }
      if (ch == 'ى') {
        out.write('a');
        continue;
      }
      if (ch == 'ة') {
        out.write(_vowels.containsKey(next) ? 't' : 'h');
        continue;
      }
      final lat = _letters[ch];
      if (lat == null) {
        out.write(ch);
        continue;
      }
      final seat = 'أإؤئ'.contains(ch);
      if (seat && start) {
        if (!_vowels.containsKey(next)) out.write(ch == 'إ' ? 'i' : 'a');
        start = false;
        continue;
      }
      // Long vowels: و after u and ي after i with no vowel of their own.
      final own = _after(chars, i);
      final afterU = _endsWith(out, 'u'), afterI = _endsWith(out, 'i');
      final afterConsonant = !start && !_endsVowel(out) && own != _sukun;
      if ((ch == 'و' && (afterU || afterConsonant) ||
              ch == 'ي' && (afterI || afterConsonant)) &&
          !_vowels.containsKey(own) &&
          own != _shadda &&
          (own.isNotEmpty || afterU || afterI)) {
        out.write(ch == 'و' ? (afterU ? 'u' : 'ū') : (afterI ? 'i' : 'ī'));
        continue;
      }
      final doubled =
          own == _shadda ||
          _vowels.containsKey(own) && _after(chars, i + 1) == _shadda;
      if (doubled && !_skipShadda.remove(i)) out.write(lat);
      out.write(lat);
      start = false;
    }
    _skipShadda.clear();
    return out
        .toString()
        .replaceAll('aa', 'ā')
        .replaceAll('ii', 'ī')
        .replaceAll('uu', 'ū');
  }

  static final _skipShadda = <int>{};

  static String _after(List<String> c, int i) =>
      i + 1 < c.length ? c[i + 1] : '';
  static bool _endsWith(StringBuffer b, String s) => b.toString().endsWith(s);
  static bool _endsVowel(StringBuffer b) =>
      RegExp(r'[aiuā]$').hasMatch(b.toString());

  /// The next letter after [from], whether it carries a shadda, and its index.
  static (String, bool, int)? _nextLetter(List<String> c, int from) {
    for (var i = from; i < c.length; i++) {
      if (_letters.containsKey(c[i])) {
        var j = i + 1;
        var shadda = false;
        while (j < c.length &&
            (_vowels.containsKey(c[j]) || c[j] == _shadda || c[j] == _sukun)) {
          if (c[j] == _shadda) shadda = true;
          j++;
        }
        return (c[i], shadda, i);
      }
    }
    return null;
  }
}
