import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models.dart';
import '../../routes/app_pages.dart';
import '../../services/habit_service.dart';
import '../../services/mushaf_layout.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';

const _digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
String _ar(int n) =>
    n.toString().split('').map((d) => _digits[int.parse(d)]).join();

/// Page-by-page reading, one mushaf page (1–604) per screen, swiping right
/// for the next page as in a printed mushaf.
class MushafScreen extends StatefulWidget {
  const MushafScreen({super.key, this.initialPage = 1});
  final int initialPage;

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final _quran = QuranService.instance;
  late int _page = widget.initialPage.clamp(1, QuranService.pageCount);
  late final _controller = PageController(initialPage: _page - 1);
  MushafLayout? _layout = MushafLayout.loaded;

  @override
  void initState() {
    super.initState();
    _save();
    if (_layout == null) {
      MushafLayout.load().then((l) {
        if (mounted) setState(() => _layout = l);
      }, onError: (Object e) => debugPrint('Mushaf layout not loaded: $e'));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final on = _quran.ayahsOnPage(_page);
    if (on.isEmpty) return;
    _quran.saveLastRead(on.first.$1, on.first.$2.numberInSurah, _page);
  }

  void _changed(int i) {
    final p = i + 1;
    if (p == _page + 1) HabitService.instance.recordPage(_page);
    setState(() => _page = p);
    _save();
  }

  bool _finished = false;

  void _finish() {
    HabitService.instance.recordPage(QuranService.pageCount);
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final on = _quran.ayahsOnPage(_page);
    final first = on.isEmpty ? null : on.first;
    final surah = first == null ? null : _quran.surah(first.$1);
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.ink),
                    onPressed: Get.back,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah?.nameSimple ?? '',
                          style: AppTheme.headline(16),
                        ),
                        Text(
                          '${'juz'.tr} ${first?.$2.juz ?? ''} · ${'mushafPage'.trParams({'n': '$_page'})}',
                          style: AppTheme.body(11, color: AppColors.sage),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('mushaf-open-reader'),
                    tooltip: 'openInReader'.tr,
                    icon: Icon(
                      Icons.view_agenda_outlined,
                      color: AppColors.ink,
                    ),
                    onPressed: first == null
                        ? null
                        : () => openQuranAt(
                            first.$1,
                            first.$2.numberInSurah,
                            fromSurah: first.$1,
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: PageView.builder(
                  key: const ValueKey('mushaf-pages'),
                  controller: _controller,
                  reverse: true,
                  itemCount: QuranService.pageCount,
                  onPageChanged: _changed,
                  itemBuilder: (_, i) => _MushafPage(
                    page: i + 1,
                    layout: _layout,
                    finished: _finished,
                    onFinish: _finish,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                _ar(_page),
                style: AppTheme.body(13, color: AppColors.sage),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  const _MushafPage({
    required this.page,
    required this.layout,
    required this.finished,
    required this.onFinish,
  });
  final int page;
  final MushafLayout? layout;
  final bool finished;
  final VoidCallback onFinish;

  Widget get _done => FilledButton.icon(
    key: const ValueKey('mushaf-finish'),
    onPressed: finished ? null : onFinish,
    icon: Icon(finished ? Icons.check_circle : Icons.check),
    label: Text('done'.tr),
  );

  @override
  Widget build(BuildContext context) {
    final layout = this.layout;
    if (layout != null) {
      return Column(
        children: [
          Expanded(
            child: _PrintedPage(page: page, lines: layout.page(page)),
          ),
          if (page == QuranService.pageCount)
            Padding(padding: const EdgeInsets.only(top: 8), child: _done),
        ],
      );
    }
    return _flowing();
  }

  /// Plain flowing text, shown only if the bundled layout can't be read.
  Widget _flowing() {
    final quran = QuranService.instance;
    final groups = <(int, List<Ayah>)>[];
    for (final (s, a) in quran.ayahsOnPage(page)) {
      if (groups.isEmpty || groups.last.$1 != s) groups.add((s, []));
      groups.last.$2.add(a);
    }
    final style = AppTheme.quran(21, height: 2.1, color: AppColors.ink);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      children: [
        for (final (s, ayahs) in groups) ...[
          if (ayahs.first.numberInSurah == 1)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.emeraldTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Text(
                quran.surah(s).nameArabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: AppTheme.quran(20, color: AppColors.emeraldDeep),
              ),
            ),
          Text.rich(
            TextSpan(
              children: [
                for (final a in ayahs) ...[
                  TextSpan(text: '${a.text} '),
                  TextSpan(
                    text: '﴿${_ar(a.numberInSurah)}﴾ ',
                    style: style.copyWith(color: AppColors.goldInk),
                  ),
                ],
              ],
            ),
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            style: style,
          ),
        ],
        if (page == QuranService.pageCount)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(child: _done),
          ),
      ],
    );
  }
}

/// One page laid out as the printed Madinah mushaf: 15 lines of equal
/// height (8, centred, on pages 1 and 2), each stretched to the full width
/// like the printed line, inside a framed page.
class _PrintedPage extends StatelessWidget {
  const _PrintedPage({required this.page, required this.lines});
  final int page;
  final List<MushafLine> lines;

  @override
  Widget build(BuildContext context) {
    final opening = page <= 2;
    final byLine = {for (final l in lines) l.line: l};
    return Container(
      key: ValueKey('mushaf-printed-$page'),
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.goldInk, width: 1.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.goldInk.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: LayoutBuilder(
          builder: (_, box) {
            final slot = box.maxHeight / 15;
            final width = opening ? box.maxWidth * 0.78 : box.maxWidth;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= MushafLayout.linesOn(page); i++)
                  SizedBox(
                    key: ValueKey('mushaf-line-$page-$i'),
                    height: slot,
                    width: width,
                    child: switch (byLine[i]) {
                      null => const SizedBox.shrink(),
                      final l => _PrintedLine(
                        line: l,
                        height: slot,
                        justify: !opening,
                      ),
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PrintedLine extends StatelessWidget {
  const _PrintedLine({
    required this.line,
    required this.height,
    required this.justify,
  });
  final MushafLine line;
  final double height;
  final bool justify;

  static TextStyle _style(double size, {String? font, Color? color}) =>
      TextStyle(
        fontFamily: font ?? AppFonts.mushaf,
        fontSize: size,
        color: color ?? AppColors.ink,
        height: 1.0,
      );

  /// The largest font size up to 60% of the slot whose line box still fits.
  static double _fit(double height, String font) {
    final probe = TextPainter(
      text: TextSpan(
        text: 'بِسۡمِ',
        style: _style(100, font: font),
      ),
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout();
    final size = (100 * height * 0.92 / probe.height).clamp(6.0, height * 0.6);
    probe.dispose();
    return size;
  }

  Widget _centred(String text, TextStyle style) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textScaler: TextScaler.noScaling,
        maxLines: 1,
        softWrap: false,
        style: style,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    switch (line.kind) {
      case MushafLineKind.surahWithBasmala:
        return Column(
          children: [
            SizedBox(height: height * 0.6, child: _header(height * 0.6)),
            Expanded(
              child: _centred(
                line.text,
                _style(_fit(height * 0.4, AppFonts.mushaf)),
              ),
            ),
          ],
        );
      case MushafLineKind.surah:
        return _header(height);
      case MushafLineKind.basmala:
        return _centred(line.text, _style(_fit(height, AppFonts.mushaf)));
      case MushafLineKind.text:
        return _text();
    }
  }

  Widget _header(double height) {
    final name = QuranService.instance.surah(line.surah).nameArabic;
    return Container(
      margin: EdgeInsets.symmetric(vertical: height * 0.08),
      decoration: BoxDecoration(
        color: AppColors.emeraldTint,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: AppColors.goldInk, width: 1.2),
      ),
      child: _centred(
        'سُورَةُ $name',
        _style(
          _fit(height * 0.84, AppFonts.quran),
          font: AppFonts.quran,
          color: AppColors.emeraldDeep,
        ),
      ),
    );
  }

  Widget _text() => LayoutBuilder(
    builder: (_, box) {
      final style = _style(_fit(height, AppFonts.mushaf));
      final painter = TextPainter(
        text: TextSpan(text: line.text, style: style),
        textDirection: TextDirection.rtl,
        textScaler: TextScaler.noScaling,
        maxLines: 1,
      )..layout();
      final natural = painter.width;
      painter.dispose();
      final gaps = ' '.allMatches(line.text).length;
      final spare = box.maxWidth - natural;
      final spacing = justify && gaps > 0 && spare > 0 ? spare / gaps : 0.0;
      return _centred(line.text, style.copyWith(wordSpacing: spacing));
    },
  );
}
