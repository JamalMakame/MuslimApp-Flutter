import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class Hadith {
  const Hadith(this.number, this.arabic, this.english);
  final int number;
  final String arabic;
  final String english;
}

/// An-Nawawi's 40 Hadith (42 with the two he added), Arabic and English,
/// bundled from fawazahmed0/hadith-api (The Unlicense).
class HadithService {
  HadithService._();
  static final HadithService instance = HadithService._();

  List<Hadith> _all = const [];
  List<Hadith> get all => _all;

  Future<List<Hadith>> load() async {
    if (_all.isNotEmpty) return _all;
    final raw = await rootBundle.loadString('assets/json/nawawi40.json');
    _all = [
      for (final h in (jsonDecode(raw) as Map)['hadiths'] as List)
        Hadith(h['n'] as int, h['ar'] as String, h['en'] as String),
    ];
    return _all;
  }
}
