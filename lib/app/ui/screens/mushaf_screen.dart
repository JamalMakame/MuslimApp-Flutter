import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models.dart';
import '../../routes/app_pages.dart';
import '../../services/habit_service.dart';
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

  @override
  void initState() {
    super.initState();
    _save();
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
    required this.finished,
    required this.onFinish,
  });
  final int page;
  final bool finished;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              child: FilledButton.icon(
                key: const ValueKey('mushaf-finish'),
                onPressed: finished ? null : onFinish,
                icon: Icon(finished ? Icons.check_circle : Icons.check),
                label: Text('done'.tr),
              ),
            ),
          ),
      ],
    );
  }
}
