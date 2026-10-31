import 'package:get/get.dart';

import '../data/models.dart';
import '../services/azkar_service.dart';

/// Azkar grid + per-category counter state.
class AzkarController extends GetxController {
  final _azkar = AzkarService.instance;

  /// Display order bucket keys.
  List<String> get categories => _azkar.categories;

  int totalOf(String bucket) => _azkar.totalCount(bucket);
  int doneOf(String bucket) => _azkar.doneToday(bucket);
  int repeatsOf(String bucket) => _azkar.totalRepeats(bucket);

  /// Featured daily progress — morning bucket.
  String get featuredBucket => 'catMorning';

  int get featuredDone => doneOf(featuredBucket);
  int get featuredTotal => repeatsOf(featuredBucket);
  int get featuredPct =>
      featuredTotal == 0 ? 0 : ((featuredDone / featuredTotal) * 100).round();
}

/// Detail screen — per-item remaining counters for one bucket.
class AzkarDetailController extends GetxController {
  AzkarDetailController(this.bucket);
  final String bucket;
  final _azkar = AzkarService.instance;

  /// Index -> remaining repetitions.
  final remaining = <int, int>{}.obs;
  final autoAdvance = true.obs;

  List<DhikrItem> get items => _azkar.items(bucket);
  int get totalItems => items.length;

  /// Completed items count.
  int get completedItems => remaining.entries.where((e) => e.value <= 0).length;

  /// Persisted "done repeats" snapshot for the category tile.
  Future<void> _persist() async {
    final done = items.asMap().entries.fold<int>(
      0,
      (s, e) => s + (e.value.count - (remaining[e.key] ?? e.value.count)),
    );
    await _azkar.setDoneToday(bucket, done);
  }

  void initCounters() {
    remaining.value = {
      for (var i = 0; i < items.length; i++) i: items[i].count,
    };
  }

  /// Tap-to-count on one card.
  Future<void> tap(int index) async {
    final left = remaining[index] ?? 0;
    if (left <= 0) return;
    remaining[index] = left - 1;
    remaining.refresh();
    await _persist();
  }
}
