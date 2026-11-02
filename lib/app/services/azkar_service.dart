import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../data/models.dart';
import 'storage_service.dart';

/// Bundled Hisnul-Muslim corpus. The JSON ships 39 Arabic categories;
/// we group them into the 10 design buckets (plus an "Other" bucket so
/// nothing is dropped).
class AzkarService {
  AzkarService._();
  static final AzkarService instance = AzkarService._();

  final _s = StorageService.instance;

  /// Display bucket -> source category titles in azkar.json.
  static const mapping = <String, List<String>>{
    'catMorning': ['أذكار الصباح'],
    'catEvening': ['أذكار المساء'],
    'catAfterPrayer': [
      'التسبيح، التحميد، التهليل، التكبير',
      'كيف كان النبي يسبح؟',
    ],
    'catSleep': ['أذكار النوم'],
    'catWaking': [' الاستيقاظ من النوم'],
    'catAdhan': ['أذكار الآذان'],
    'catTravel': [
      'دعاء المسافر',
      'الدعاء إذا نزل مترلا في سفر أو غيره',
      'ذكر الرجوع من السفر',
    ],
    'catRuqyahQuran': ['الرُّقية بالقران'],
    'catRuqyahSunnah': ['الرُّقية بالسنه'],
    'catGratitude': [
      'ما يقول من أتاه أمر يسره أو يكرهه',
      'دعاء التعجب والأمر السار',
      'ما يفعل من أتاه أمر يسره',
    ],
  };

  /// Grid order (Other appended after the 10 mapped tiles).
  static const order = [
    'catMorning',
    'catEvening',
    'catAfterPrayer',
    'catSleep',
    'catWaking',
    'catAdhan',
    'catTravel',
    'catRuqyahQuran',
    'catRuqyahSunnah',
    'catGratitude',
    'catOther',
  ];

  final Map<String, List<DhikrItem>> _byBucket = {};
  bool _loaded = false;

  List<String> get categories => order;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/json/azkar.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    final used = <String>{};
    for (final titles in mapping.values) {
      used.addAll(titles.map((t) => t.trim()));
    }

    for (final entry in mapping.entries) {
      _byBucket[entry.key] = [
        for (final t in entry.value)
          ...?((data[t] ?? data[t.trim()]) as List?)?.map(
            (e) => DhikrItem.fromJson(e),
          ),
      ];
    }

    final other = <DhikrItem>[];
    for (final e in data.entries) {
      if (!used.contains(e.key.trim()) && e.value is List) {
        other.addAll((e.value as List).map((x) => DhikrItem.fromJson(x)));
      }
    }
    _byBucket['catOther'] = other;
    _loaded = true;
  }

  List<DhikrItem> items(String bucket) => _byBucket[bucket] ?? [];

  /// Supplications short enough for the Home "Dua of the Day" card: entries
  /// that address Allah (اللهم / رب… / أعوذ), not instructions or verses.
  List<DhikrItem> get dailyDuaPool {
    final seen = <String>{};
    return [
      for (final e in _byBucket.entries)
        if (e.key != 'catRuqyahQuran')
          for (final d in e.value)
            if (d.zekr.length <= 220 &&
                isSupplication(d.zekr) &&
                seen.add(d.zekr))
              d,
    ];
  }

  static final _marks = RegExp('[\u064B-\u0652\u0670\u06D6-\u06ED\u0640]');

  static bool isSupplication(String zekr) {
    final t = zekr.replaceAll(_marks, '').trim();
    return t.contains('اللهم') || t.startsWith('رب') || t.contains('أعوذ');
  }

  int totalCount(String bucket) => items(bucket).length;
  int totalRepeats(String bucket) =>
      items(bucket).fold(0, (sum, e) => sum + e.count);

  // ---- Daily progress (persisted per date) --------------------------------
  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  Map<String, int> _progressForToday() {
    final all = (_s.read<Map>(StorageService.kAzkarProgress) ?? {})
        .cast<String, dynamic>();
    final today = (all[_today] as Map?)?.cast<String, dynamic>() ?? {};
    return today.map((k, v) => MapEntry(k, v as int));
  }

  /// Completed repetitions so far today for [bucket].
  int doneToday(String bucket) => _progressForToday()[bucket] ?? 0;

  Future<void> setDoneToday(String bucket, int done) async {
    final all = (_s.read<Map>(StorageService.kAzkarProgress) ?? {})
        .cast<String, dynamic>();
    final today = (all[_today] as Map?)?.cast<String, dynamic>() ?? {};
    today[bucket] = done;
    all[_today] = today;
    await _s.write(StorageService.kAzkarProgress, all);
  }
}
