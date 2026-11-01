import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'quran_service.dart';

/// Per-ayah Quran audio cache. A surah is marked offline only when every ayah
/// has a valid local MP3; interrupted downloads can resume from saved ayahs.
class AudioCacheService {
  static const _minimumMp3Bytes = 512;

  AudioCacheService({
    http.Client? client,
    Future<Directory> Function()? documentsDirectory,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  final http.Client _client;
  final bool _ownsClient;
  final Future<Directory> Function() _documentsDirectory;
  final _quran = QuranService.instance;

  /// Called only after the user confirms clearing all locally stored data.
  static Future<void> clearAllAudio({
    Future<Directory> Function()? documentsDirectory,
  }) async {
    final documents =
        await (documentsDirectory ?? getApplicationDocumentsDirectory)();
    final audio = Directory('${documents.path}/audio');
    if (await audio.exists()) await audio.delete(recursive: true);
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  Future<File> fileFor(String edition, int globalAyah) async {
    if (!QuranService.reciters.containsKey(edition) || globalAyah < 1) {
      throw ArgumentError('Invalid Quran audio edition or ayah');
    }
    final documents = await _documentsDirectory();
    return File('${documents.path}/audio/$edition/$globalAyah.mp3');
  }

  static bool _isMp3(List<int> bytes) =>
      bytes.length >= 3 &&
      ((bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) ||
          (bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0));

  Future<File?> cachedFile(String edition, int globalAyah) async {
    final file = await fileFor(edition, globalAyah);
    if (!await file.exists() || await file.length() < _minimumMp3Bytes) {
      return null;
    }
    final header = await file.openRead(0, 3).first;
    return _isMp3(header) ? file : null;
  }

  /// Reconcile the manifest with actual files, including a completed download
  /// whose manifest write was interrupted. Returns null for an incomplete set.
  Future<int?> verifiedBytes(String edition, int surah, List<int> ayahs) async {
    if (ayahs.isEmpty) return null;
    var total = 0;
    for (final id in ayahs) {
      final file = await cachedFile(edition, id);
      if (file == null) {
        if (_quran.isDownloaded(edition, surah)) {
          await _quran.unmarkDownloaded(edition, surah);
        }
        return null;
      }
      total += await file.length();
    }
    if (_quran.downloadedBytes(edition, surah) != total) {
      await _quran.markDownloaded(edition, surah, total);
    }
    return total;
  }

  Future<int> downloadSurah(
    String edition,
    int surah,
    List<int> ayahs, {
    void Function(double)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (ayahs.isEmpty) throw StateError('No ayahs to download');
    var total = 0;
    for (var i = 0; i < ayahs.length; i++) {
      if (isCancelled?.call() ?? false) {
        throw StateError('Download stopped');
      }
      final id = ayahs[i];
      var file = await cachedFile(edition, id);
      if (file == null) {
        final response = await _client
            .get(Uri.parse(_quran.ayahAudioUrl(edition, id)))
            .timeout(const Duration(seconds: 20));
        final contentType = response.headers['content-type'] ?? '';
        final expectedLength = int.tryParse(
          response.headers['content-length'] ?? '',
        );
        if (response.statusCode != 200 ||
            contentType.startsWith('text/') ||
            response.bodyBytes.length < _minimumMp3Bytes ||
            response.bodyBytes.length > 15 * 1024 * 1024 ||
            (expectedLength != null &&
                expectedLength != response.bodyBytes.length) ||
            !_isMp3(response.bodyBytes)) {
          throw StateError('Invalid Quran audio response');
        }
        file = await fileFor(edition, id);
        final partial = File('${file.path}.part');
        try {
          await partial.create(recursive: true);
          await partial.writeAsBytes(response.bodyBytes, flush: true);
          if (isCancelled?.call() ?? false) {
            throw StateError('Download stopped');
          }
          if (await file.exists()) await file.delete();
          await partial.rename(file.path);
        } finally {
          if (await partial.exists()) await partial.delete();
        }
      }
      total += await file.length();
      onProgress?.call((i + 1) / ayahs.length);
    }
    if (isCancelled?.call() ?? false) throw StateError('Download stopped');
    await _quran.markDownloaded(edition, surah, total);
    return total;
  }

  Future<void> deleteSurah(String edition, int surah, List<int> ayahs) async {
    await _quran.unmarkDownloaded(edition, surah);
    for (final id in ayahs) {
      final file = await fileFor(edition, id);
      if (await file.exists()) await file.delete();
      final partial = File('${file.path}.part');
      if (await partial.exists()) await partial.delete();
    }
  }
}
