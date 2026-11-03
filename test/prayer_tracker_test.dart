import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/services/notification_service.dart';
import 'package:fquran_app/app/services/prayer_log_service.dart';
import 'package:fquran_app/app/services/prayer_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/ui/screens/prayer_tracker_screen.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;
  late PrayerLogService log;
  const all = PrayerLogService.prayers;

  void mockPaths() => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => documents.path,
      );

  Future<void> mark(
    DateTime day,
    Iterable<String> prayers,
    DateTime now,
  ) async {
    for (final p in prayers) {
      await log.toggle(day, p, now);
    }
  }

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('deen-tracker-test-');
    mockPaths();
    await StorageService.init();
    log = PrayerLogService.instance;
    await initializeDateFormatting('en');
  });

  setUp(() async {
    mockPaths();
    await StorageService.instance.clearAll();
  });

  tearDownAll(() async {
    await documents.delete(recursive: true).catchError((_) => documents);
  });

  test('marking all five completes the day; future days are refused', () async {
    final now = DateTime(2026, 11, 2, 21);
    expect(await log.toggle(DateTime(2026, 11, 3), 'fajr', now), isFalse);
    expect(log.prayedOn(DateTime(2026, 11, 3)), isEmpty);
    for (final p in all.take(4)) {
      expect(await log.toggle(now, p, now), isFalse);
    }
    expect(log.isComplete(now), isFalse);
    expect(await log.toggle(now, 'isha', now), isTrue);
    expect(log.isComplete(now), isTrue);
    await log.toggle(now, 'asr', now);
    expect(log.prayedOn(now), {'fajr', 'dhuhr', 'maghrib', 'isha'});
  });

  test('streaks count full days, and today only once complete', () async {
    final now = DateTime(2026, 11, 10, 9);
    for (final d in [1, 2, 3, 6, 7, 8, 9]) {
      await mark(DateTime(2026, 11, d), all, now);
    }
    await mark(DateTime(2026, 11, 10), ['fajr'], now);
    expect(log.streak(now), 4);
    expect(log.bestStreak(), 4);
    await mark(DateTime(2026, 11, 10), all.skip(1), now);
    expect(log.streak(now), 5);
    expect(log.bestStreak(), 5);
  });

  test('stats find the weakest prayer and the standing', () async {
    final now = DateTime(2026, 11, 10, 9);
    expect(log.stats(7, now).standing, PrayerStanding.none);
    for (var d = 3; d <= 9; d++) {
      await mark(DateTime(2026, 11, d), all.skip(d.isEven ? 1 : 0), now);
    }
    await mark(now, ['fajr', 'dhuhr'], now);
    final week = log.stats(7, now);
    expect(week.days, 7, reason: 'today is still open: Nov 3–9');
    expect(week.perPrayer['fajr'], 4);
    expect(week.weakest, 'fajr');
    expect(week.standing, PrayerStanding.strong);
    expect(week.missed, 3);

    await StorageService.instance.clearAll();
    for (var d = 3; d <= 9; d++) {
      await mark(DateTime(2026, 11, d), ['dhuhr', 'asr'], now);
    }
    expect(log.stats(7, now).standing, PrayerStanding.slipping);
    expect(log.stats(7, now).weakest, 'fajr');
  });

  test('stats start from the first marked day', () async {
    final now = DateTime(2026, 11, 10, 9);
    await mark(DateTime(2026, 11, 9), all, now);
    final s = log.stats(30, now);
    expect(s.days, 1);
    expect(s.standing, PrayerStanding.strong);
  });

  test('the evening check-in comes an hour after Isha on open days', () {
    final now = DateTime(2026, 11, 2, 8);
    List<PrayerSlot> slots(DateTime d) => [
      PrayerSlot('fajr', DateTime(d.year, d.month, d.day, 5)),
      PrayerSlot('isha', DateTime(d.year, d.month, d.day, 19, 30)),
    ];
    final off = {'fajr': -1, 'isha': -1};
    final plan = NotificationService.plan(
      slots,
      now,
      leads: off,
      checkIn: true,
      checkedIn: (d) => d.day == 3,
    );
    expect(plan.every((r) => r.key == NotificationService.prayerCheck), isTrue);
    expect(plan.first.time, DateTime(2026, 11, 2, 20, 30));
    expect(plan.any((r) => r.time.day == 3), isFalse);
    expect(plan.length, NotificationService.days);
    expect(
      NotificationService.usesAdhan(plan.first, adhan: true),
      isFalse,
      reason: 'the check-in never plays the adhan',
    );
    expect(
      NotificationService.plan(slots, now, leads: off),
      isEmpty,
      reason: 'off when the setting is off',
    );
  });

  Widget app() => GetMaterialApp(
    translations: DeenTranslations(),
    locale: const Locale('en'),
    home: const PrayerTrackerScreen(),
  );

  testWidgets('checking off all five today celebrates', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.text('0/5'), findsWidgets);
    expect(find.text('standingNone'.tr), findsOneWidget);
    for (final p in all) {
      await t.tap(find.byKey(ValueKey('track-$p')));
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(find.byKey(const ValueKey('celebration')), findsOneWidget);
    expect(find.text('allFiveDone'.tr), findsOneWidget);
    expect(
      (t.widget(find.byKey(const ValueKey('tracker-count'))) as Text).data,
      '5/5',
    );
    await t.pump(const Duration(seconds: 5));
    expect(find.byKey(const ValueKey('celebration')), findsNothing);
    expect(log.isComplete(DateTime.now()), isTrue);
    expect(log.streak(), 1);
  });

  testWidgets('a slipping week warns and suggests tips for that prayer', (
    t,
  ) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    final now = DateTime.now();
    for (var i = 1; i <= 7; i++) {
      await mark(DateTime(now.year, now.month, now.day - i), [
        'dhuhr',
        'asr',
        'maghrib',
      ], now);
    }
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.text('standingWarnTitle'.tr), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-tipFajr1')), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-tipGeneral2')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('tracker-day-1')));
    await t.pumpAndSettle();
    expect(
      (t.widget(find.byKey(const ValueKey('tracker-count'))) as Text).data,
      '3/5',
    );

    final old = find.byKey(const ValueKey('tracker-history-20'));
    final page = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    await t.scrollUntilVisible(old, 200, scrollable: page);
    await t.ensureVisible(old);
    await t.pumpAndSettle();
    final handle = t.ensureSemantics();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final node = t.getSemantics(
      find.bySemanticsLabel(
        RegExp('^${DateFormat('d MMM', 'en').format(yesterday)}:'),
      ),
    );
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.label, endsWith(': 3/5'));
    handle.dispose();

    await t.tap(old);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('track-asr')),
      -200,
      scrollable: page,
    );
    expect(
      (t.widget(find.byKey(const ValueKey('tracker-count'))) as Text).data,
      '0/5',
    );
    await t.drag(page, const Offset(0, 3000));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('track-asr')));
    await t.pumpAndSettle();
    expect(log.prayedOn(DateTime(now.year, now.month, now.day - 20)), {'asr'});
  });
}
