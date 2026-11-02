import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'prayer_service.dart';

/// Feeds the Android home-screen widget: the next few days of prayer times,
/// so the widget can pick the next one itself while the app is closed.
class PrayerWidget {
  PrayerWidget._();

  static const androidName = 'NextPrayerWidget';
  static String? _last;

  /// `[[epoch ms, name], …]` for prayers after [now], sunrise excluded.
  static String payload(
    Iterable<PrayerSlot> slots,
    DateTime now,
    String Function(String key) name,
  ) => jsonEncode([
    for (final s in slots)
      if (s.key != 'sunrise' && s.time.isAfter(now))
        [s.time.millisecondsSinceEpoch, name(s.key)],
  ]);

  static Future<void> update({
    required String prayers,
    required String label,
    required String city,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final sig = '$prayers|$label|$city';
    if (sig == _last) return;
    try {
      await HomeWidget.saveWidgetData<String>('prayers', prayers);
      await HomeWidget.saveWidgetData<String>('label', label);
      await HomeWidget.saveWidgetData<String>('city', city);
      await HomeWidget.updateWidget(androidName: androidName);
      _last = sig;
    } catch (e) {
      debugPrint('Prayer widget not updated: $e');
    }
  }
}
