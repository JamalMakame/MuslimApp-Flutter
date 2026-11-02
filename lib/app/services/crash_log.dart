import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Uncaught errors, kept on the device (no crash service, no network). The
/// user can share them from Settings → Problem reports.
class CrashLog {
  CrashLog._();

  static const max = 20;

  static List<Map<String, dynamic>> get entries {
    final raw = StorageService.instance.readStr(StorageService.kCrashLog);
    if (raw.isEmpty) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          Map<String, dynamic>.from(e as Map),
      ];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> record(Object error, StackTrace? stack) async {
    try {
      final lines = (stack?.toString() ?? '').split('\n').take(12).join('\n');
      final list = [
        {
          't': DateTime.now().toIso8601String(),
          'e': error.toString(),
          's': lines,
        },
        ...entries,
      ].take(max).toList();
      await StorageService.instance.write(
        StorageService.kCrashLog,
        jsonEncode(list),
      );
    } catch (_) {}
  }

  static Future<void> clear() =>
      StorageService.instance.remove(StorageService.kCrashLog);

  /// Plain text for sharing, newest first.
  static String report() => [
    'Deen · ${defaultTargetPlatform.name}',
    for (final e in entries) '\n[${e['t']}]\n${e['e']}\n${e['s']}',
  ].join('\n');

  /// Hooks Flutter and platform errors into the log.
  static void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exception, details.stack);
      (previous ?? FlutterError.presentError)(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack);
      return false;
    };
  }
}
