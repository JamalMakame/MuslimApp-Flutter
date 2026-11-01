import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fquran_app/app/controllers/memorize_controller.dart';
import 'package:fquran_app/app/services/audio_cache_service.dart';
import 'package:fquran_app/app/services/quran_service.dart';
import 'package:fquran_app/app/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const edition = 'ar.alafasy';
  final mp3 = <int>[0x49, 0x44, 0x33, ...List.filled(1024, 0)];
  http.Response goodAudio() =>
      http.Response.bytes(mp3, 200, headers: {'content-type': 'audio/mpeg'});

  test('repeat, advance and final ayah stop decisions', () {
    ({MemorizeStep step, int index, int repetition}) decide(
      int repetition,
      int index,
      bool auto,
    ) => stepAfterAyah(
      repetition: repetition,
      repeat: 5,
      index: index,
      count: 7,
      autoAdvance: auto,
    );
    expect(decide(1, 0, true), (
      step: MemorizeStep.repeat,
      index: 0,
      repetition: 2,
    ));
    expect(decide(5, 0, true), (
      step: MemorizeStep.advance,
      index: 1,
      repetition: 1,
    ));
    expect(decide(5, 6, true), (
      step: MemorizeStep.stop,
      index: 6,
      repetition: 1,
    ));
    expect(decide(5, 0, false), (
      step: MemorizeStep.stop,
      index: 0,
      repetition: 1,
    ));
  });

  group('AudioCacheService (no network)', () {
    late Directory storageDir;
    late Directory audioDir;

    setUpAll(() async {
      storageDir = await Directory.systemTemp.createTemp('deen-audio-storage-');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => storageDir.path,
          );
      await StorageService.init();
    });

    setUp(() async {
      audioDir = await Directory.systemTemp.createTemp('deen-audio-cache-');
      await StorageService.instance.clearAll();
    });

    tearDown(() async => audioDir.delete(recursive: true));

    tearDownAll(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      await storageDir.delete(recursive: true);
    });

    test(
      'interrupted download resumes, but manifest is only complete at end',
      () async {
        var failSecond = true;
        final requests = <String>[];
        final cache = AudioCacheService(
          client: MockClient((request) async {
            requests.add(request.url.path);
            if (request.url.path.endsWith('/2.mp3') && failSecond) {
              return http.Response('unavailable', 503);
            }
            return goodAudio();
          }),
          documentsDirectory: () async => audioDir,
        );
        addTearDown(cache.close);

        await expectLater(
          cache.downloadSurah(edition, 1, [1, 2]),
          throwsStateError,
        );
        expect(await cache.cachedFile(edition, 1), isNotNull);
        expect(await cache.cachedFile(edition, 2), isNull);
        expect(QuranService.instance.isDownloaded(edition, 1), isFalse);

        failSecond = false;
        final bytes = await cache.downloadSurah(edition, 1, [1, 2]);
        expect(bytes, 2 * mp3.length);
        expect(requests.where((path) => path.endsWith('/1.mp3')).length, 1);
        expect(QuranService.instance.downloadedBytes(edition, 1), bytes);
        expect(await cache.verifiedBytes(edition, 1, [1, 2]), bytes);
      },
    );

    test(
      'rejects error pages returned as audio and leaves no partial file',
      () async {
        final cache = AudioCacheService(
          client: MockClient(
            (_) async => http.Response(
              '<html>not an mp3</html>',
              200,
              headers: {'content-type': 'text/html'},
            ),
          ),
          documentsDirectory: () async => audioDir,
        );
        addTearDown(cache.close);

        await expectLater(
          cache.downloadSurah(edition, 1, [1]),
          throwsStateError,
        );
        expect(await cache.cachedFile(edition, 1), isNull);
        expect(
          await File('${(await cache.fileFor(edition, 1)).path}.part').exists(),
          isFalse,
        );
        expect(QuranService.instance.isDownloaded(edition, 1), isFalse);
      },
    );

    test('rejects short MP3s and mismatched content lengths', () async {
      var attempt = 0;
      final cache = AudioCacheService(
        client: MockClient((_) async {
          attempt++;
          return attempt == 1
              ? http.Response.bytes(
                  [0x49, 0x44, 0x33],
                  200,
                  headers: {'content-type': 'audio/mpeg'},
                )
              : http.Response.bytes(
                  mp3,
                  200,
                  headers: {
                    'content-type': 'audio/mpeg',
                    'content-length': '${mp3.length + 1}',
                  },
                );
        }),
        documentsDirectory: () async => audioDir,
      );
      addTearDown(cache.close);

      await expectLater(cache.downloadSurah(edition, 1, [1]), throwsStateError);
      await expectLater(cache.downloadSurah(edition, 1, [1]), throwsStateError);
      expect(await cache.cachedFile(edition, 1), isNull);
      expect(QuranService.instance.isDownloaded(edition, 1), isFalse);
    });

    test(
      'missing file invalidates previously completed offline status',
      () async {
        final cache = AudioCacheService(
          client: MockClient((_) async => goodAudio()),
          documentsDirectory: () async => audioDir,
        );
        addTearDown(cache.close);
        await cache.downloadSurah(edition, 1, [1, 2]);
        await (await cache.fileFor(edition, 2)).delete();

        expect(await cache.verifiedBytes(edition, 1, [1, 2]), isNull);
        expect(QuranService.instance.isDownloaded(edition, 1), isFalse);
      },
    );

    test(
      'downloads are isolated by reciter and cancellation is resumable',
      () async {
        final urls = <Uri>[];
        final cache = AudioCacheService(
          client: MockClient((request) async {
            urls.add(request.url);
            return goodAudio();
          }),
          documentsDirectory: () async => audioDir,
        );
        addTearDown(cache.close);

        var cancelled = false;
        await expectLater(
          cache.downloadSurah(
            edition,
            1,
            [1, 2],
            isCancelled: () => cancelled,
            onProgress: (_) => cancelled = true,
          ),
          throwsStateError,
        );
        expect(QuranService.instance.isDownloaded(edition, 1), isFalse);
        await cache.downloadSurah('ar.husary', 1, [1]);
        await cache.downloadSurah(edition, 1, [1, 2]);
        expect(
          (await cache.fileFor(edition, 1)).path,
          isNot((await cache.fileFor('ar.husary', 1)).path),
        );
        expect(
          urls.any(
            (uri) =>
                uri.path.endsWith('/ar.husary/1.mp3') &&
                uri.host == 'cdn.islamic.network',
          ),
          isTrue,
        );
        expect(QuranService.instance.isDownloaded(edition, 1), isTrue);
        expect(QuranService.instance.isDownloaded('ar.husary', 1), isTrue);
      },
    );

    test('clearing local data removes downloaded files', () async {
      final cache = AudioCacheService(
        client: MockClient((_) async => goodAudio()),
        documentsDirectory: () async => audioDir,
      );
      addTearDown(cache.close);
      await cache.downloadSurah(edition, 1, [1]);
      expect(await cache.cachedFile(edition, 1), isNotNull);

      await AudioCacheService.clearAllAudio(
        documentsDirectory: () async => audioDir,
      );
      await StorageService.instance.clearAll();
      expect(await cache.cachedFile(edition, 1), isNull);
      expect(QuranService.instance.isDownloaded(edition, 1), isFalse);
    });
  });
}
