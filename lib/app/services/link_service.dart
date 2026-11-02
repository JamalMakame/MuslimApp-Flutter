import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:get/get.dart';

import '../routes/app_pages.dart';
import 'quran_service.dart';

/// Opens Quran links in the reader:
/// `deen://quran/2/255`, `deen://quran/2:255`, `deen://quran/36`,
/// `deen://quran?juz=30`, `deen://quran?hizb=12`, `deen://quran?page=300`.
/// A link that arrives before Home is up waits until [openPending].
class LinkService {
  LinkService._();
  static final LinkService instance = LinkService._();

  Uri? _pending;
  StreamSubscription<Uri>? _sub;

  static Uri linkTo(int surah, int ayah) =>
      Uri.parse('deen://quran/$surah/$ayah');

  /// The (surah, ayah) a link points at; null when it isn't a valid one.
  static (int surah, int ayah)? parse(Uri uri, QuranService quran) {
    if (uri.scheme != 'deen' || uri.host != 'quran') return null;
    int? query(String key) => int.tryParse(uri.queryParameters[key] ?? '');
    if (query('juz') case final n?) return quran.juzStart(n);
    if (query('hizb') case final n?) return quran.hizbStart(n);
    if (query('page') case final n?) return quran.pageStart(n);
    final parts = [
      for (final segment in uri.pathSegments)
        ...segment.split(':').where((p) => p.isNotEmpty),
    ];
    if (parts.isEmpty || parts.length > 2) return null;
    final surah = int.tryParse(parts[0]);
    final ayah = parts.length == 2 ? int.tryParse(parts[1]) : 1;
    if (surah == null || ayah == null || quran.ayahAt(surah, ayah) == null) {
      return null;
    }
    return (surah, ayah);
  }

  /// Listens for links; the stream also delivers the one that launched
  /// the app.
  void init() {
    try {
      _sub ??= AppLinks().uriLinkStream.listen(receive, onError: (_) {});
    } catch (_) {
      // No link plugin on this platform (e.g. widget tests).
    }
  }

  void receive(Uri uri) {
    _pending = uri;
    final route = Get.currentRoute;
    if (QuranService.instance.isLoaded &&
        route.isNotEmpty &&
        route != Routes.splash &&
        route != Routes.onboarding) {
      openPending();
    }
  }

  /// Opens a link that arrived while the app was starting.
  void openPending() {
    final uri = _pending;
    _pending = null;
    if (uri == null || !QuranService.instance.isLoaded) return;
    final at = parse(uri, QuranService.instance);
    if (at != null) openQuranAt(at.$1, at.$2);
  }
}
