import 'dart:convert';

import 'package:flutter/services.dart';

/// [surahWithBasmala]: a header with the basmala beneath it in one line.
enum MushafLineKind { text, surah, basmala, surahWithBasmala }

/// One of the 15 lines of a printed Madinah mushaf page.
class MushafLine {
  const MushafLine(this.line, this.kind, {this.text = '', this.surah = 0});
  final int line;
  final MushafLineKind kind;
  final String text;
  final int surah;
}

/// The line-by-line layout of the 604 pages, bundled in
/// `assets/json/mushaf_lines.json` (built by `tool/build_mushaf.py`).
class MushafLayout {
  MushafLayout._(this._pages);

  static const asset = 'assets/json/mushaf_lines.json';
  static Future<MushafLayout>? _loading;
  static MushafLayout? _loaded;

  /// The layout once [load] has finished, so a page can be drawn at once.
  static MushafLayout? get loaded => _loaded;

  final List<List<MushafLine>> _pages;

  int get pageCount => _pages.length;

  /// Pages 1 and 2 hold 8 lines inside their ornament; every other page 15.
  static int linesOn(int page) => page <= 2 ? 8 : 15;

  List<MushafLine> page(int p) => _pages[p - 1];

  static Future<MushafLayout> load([AssetBundle? bundle]) =>
      _loading ??= (bundle ?? rootBundle)
          .loadString(asset, cache: false)
          .then((json) => _loaded = parse(json))
          .catchError((Object e) {
            _loading = null;
            throw e;
          });

  static MushafLayout parse(String json) {
    final pages = jsonDecode(json) as List;
    final basmala = [
      for (final page in pages)
        for (final l in page as List)
          if (l case [_, 2, final String text]) text,
    ].first;
    return MushafLayout._(_lines(pages, basmala));
  }

  static List<List<MushafLine>> _lines(List pages, String basmala) => [
    for (final page in pages)
      [
        for (final l in page as List)
          switch (l as List) {
            [final int line, 0, final String text] => MushafLine(
              line,
              MushafLineKind.text,
              text: text,
            ),
            [final int line, 1, final int surah] => MushafLine(
              line,
              MushafLineKind.surah,
              surah: surah,
            ),
            [final int line, 3, final int surah] => MushafLine(
              line,
              MushafLineKind.surahWithBasmala,
              text: basmala,
              surah: surah,
            ),
            [final int line, 2, final String text] => MushafLine(
              line,
              MushafLineKind.basmala,
              text: text,
            ),
            _ => throw FormatException('Bad mushaf line: $l'),
          },
      ],
  ];
}
