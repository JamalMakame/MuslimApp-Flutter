import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fquran_app/app/i18n/app_translations.dart';
import 'package:fquran_app/app/services/habit_service.dart';
import 'package:fquran_app/app/services/notification_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';
import 'package:fquran_app/app/ui/screens/habits_screen.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documents;

  void mockPaths() => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => documents.path,
      );

  setUpAll(() async {
    documents = await Directory.systemTemp.createTemp('deen-habits-test-');
    mockPaths();
    await StorageService.init();
  });

  setUp(() async {
    mockPaths();
    await StorageService.instance.clearAll();
  });

  test('every Khatmah plan covers pages 1–604 once, in order', () {
    for (final days in [...HabitService.planLengths, 1, 604]) {
      var next = 1;
      for (var d = 0; d < days; d++) {
        final (a, b) = Khatmah.portion(d, days);
        expect(a, next, reason: '$days days, day $d');
        expect(b, greaterThanOrEqualTo(a));
        next = b + 1;
      }
      expect(next, 605, reason: '$days days');
    }
  });

  test('streak counts days in a row meeting the goal', () {
    final today = DateTime(2026, 11, 2, 9);
    final log = {
      '2026-10-29': 2,
      '2026-10-30': 3,
      '2026-10-31': 1,
      '2026-11-01': 4,
    };
    expect(HabitService.streak(log, today, 0), 4);
    expect(HabitService.streak(log, today, 2), 1);
    expect(HabitService.streak({...log, '2026-11-02': 5}, today, 2), 2);
    expect(HabitService.streak({'2026-10-31': 3}, today, 1), 0);
  });

  test('pages read count once a day and feed the Khatmah', () async {
    final h = HabitService.instance;
    final day1 = DateTime(2026, 11, 2, 8);
    await h.startKhatmah(30, day1);
    await h.setGoal(2);
    for (final p in [1, 1, 2, 3]) {
      await h.recordPage(p, day1);
    }
    expect(h.pagesOn(day1), 3);
    expect(h.currentStreak(day1), 1);
    final plan = h.khatmah!;
    expect(plan.todayPortion(day1), (1, 20));
    expect(plan.nextPage(day1), 4);
    expect(plan.remainingToday(day1), 17);
    // A missed day: the next day's portion starts with yesterday's gap.
    final day2 = DateTime(2026, 11, 3, 8);
    expect(plan.dayIndex(day2), 1);
    expect(plan.nextPage(day2), 4);
    expect(plan.remainingToday(day2), 37);
    await h.recordPage(0, day1);
    await h.recordPage(605, day1);
    expect(h.pagesOn(day1), 3);
    await h.stopKhatmah();
    expect(h.khatmah, isNull);
  });

  test('self-test results follow the spaced-review intervals', () async {
    final h = HabitService.instance;
    final day = DateTime(2026, 11, 2);
    await h.markHifz(1, 1, true, day);
    expect(h.hifzOf(1, 1)!.next, DateTime(2026, 11, 3));
    await h.markHifz(1, 1, true, day);
    expect(h.hifzOf(1, 1)!.next, DateTime(2026, 11, 5));
    await h.markHifz(1, 2, false, day);
    expect(h.hifzOf(1, 2)!.memorised, isFalse);
    expect(h.memorisedTotal, 1);
    expect(h.memorisedPerSurah, {1: 1});
    expect(h.dueOn(day), isEmpty);
    expect(h.dueOn(DateTime(2026, 11, 3)), [(1, 2)]);
    expect(h.dueOn(DateTime(2026, 11, 5)), [(1, 2), (1, 1)]);
    for (var i = 0; i < 10; i++) {
      await h.markHifz(1, 1, true, day);
    }
    expect(h.hifzOf(1, 1)!.level, HabitService.intervals.length);
    await h.forgetHifz(1, 1);
    expect(h.hifzOf(1, 1), isNull);
  });

  test('clearing local data turns the reading reminder off', () async {
    final h = HabitService.instance;
    await h.setReadReminder(20 * 60);
    await StorageService.instance.clearAll();
    h.reset();
    expect(h.readReminder.value, -1);
  });

  test('the reading reminder is planned daily, with or without prayers', () {
    final now = DateTime(2026, 11, 2, 21);
    final plan = NotificationService.plan(
      (_) => const [],
      now,
      leads: {
        for (final k in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) k: -1,
      },
      readingAt: 20 * 60 + 30,
    );
    expect(plan, hasLength(NotificationService.days));
    expect(plan.every((r) => r.key == NotificationService.reading), isTrue);
    expect(plan.first.time, DateTime(2026, 11, 3, 20, 30));
    expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
  });

  test('every habit string exists in en, ar and sw', () {
    final keys = DeenTranslations().keys;
    for (final k in [
      'habits',
      'readingGoal',
      'todayPages',
      'streakDays',
      'khatmah',
      'khatmahDay',
      'portionPages',
      'readReminder',
      'readNotify',
      'readNotifyBody',
      'memorisation',
      'memorisedOfN',
      'selfTest',
      'revealWord',
      'memorised',
      'needsReview',
      'habitsSetup',
    ]) {
      for (final lang in ['en', 'ar', 'sw']) {
        expect(keys[lang]![k], isNotNull, reason: '$lang.$k');
      }
    }
  });

  testWidgets('habits screen sets a goal and starts a plan', (tester) async {
    Get.testMode = true;
    await tester.pumpWidget(
      GetMaterialApp(
        translations: DeenTranslations(),
        locale: const Locale('en'),
        home: const HabitsScreen(),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('goal-5')));
    await tester.pump();
    expect(HabitService.instance.goal, 5);
    expect(find.text('Today: 0 / 5 pages'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plan-30')));
    await tester.pump();
    expect(find.text('Day 1 of 30'), findsOneWidget);
    expect(find.byKey(const ValueKey('khatmah-start')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('khatmah-stop')));
    await tester.pump();
    expect(find.byKey(const ValueKey('plan-30')), findsOneWidget);
  });
}
