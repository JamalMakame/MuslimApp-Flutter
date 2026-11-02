import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../routes/app_pages.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';

/// "Go to" sheet: surah + ayah, juz, hizb or mushaf page.
Future<void> showGoToSheet({int? fromSurah}) => Get.bottomSheet<void>(
  GoToSheet(
    initialSurah: fromSurah ?? 1,
    onPick: (surah, ayah) {
      Get.back<void>();
      openQuranAt(surah, ayah, fromSurah: fromSurah);
    },
  ),
  backgroundColor: AppColors.surface,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
);

class GoToSheet extends StatefulWidget {
  const GoToSheet({super.key, required this.onPick, this.initialSurah = 1});

  final void Function(int surah, int ayah) onPick;
  final int initialSurah;

  @override
  State<GoToSheet> createState() => _GoToSheetState();
}

class _GoToSheetState extends State<GoToSheet> {
  final _quran = QuranService.instance;
  final _ayah = TextEditingController();
  final _page = TextEditingController();
  late int _surah = widget.initialSurah;
  int _mode = 0; // surah · juz · hizb · page
  String? _error;

  @override
  void dispose() {
    _ayah.dispose();
    _page.dispose();
    super.dispose();
  }

  void _goSurah() {
    final max = _quran.surah(_surah).ayahs;
    final text = QuranService.westernDigits(_ayah.text.trim());
    final n = text.isEmpty ? 1 : int.tryParse(text);
    if (n == null || n < 1 || n > max) {
      setState(() => _error = 'invalidNumber'.trParams({'max': '$max'}));
      return;
    }
    widget.onPick(_surah, n);
  }

  void _goPage() {
    final at = _quran.pageStart(
      int.tryParse(QuranService.westernDigits(_page.text.trim())) ?? 0,
    );
    if (at == null) {
      setState(
        () => _error = 'invalidNumber'.trParams({
          'max': '${QuranService.pageCount}',
        }),
      );
      return;
    }
    widget.onPick(at.$1, at.$2);
  }

  InputDecoration _field(String hint, {bool showError = true}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: AppTheme.body(13, color: AppColors.sage),
        errorText: showError ? _error : null,
        filled: true,
        fillColor: AppColors.ivory,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _goButton(VoidCallback onTap) => FilledButton(
    key: const ValueKey('goto-go'),
    onPressed: onTap,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.emerald,
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    child: Text(
      'go'.tr,
      style: AppTheme.body(14, weight: FontWeight.w700, color: Colors.white),
    ),
  );

  Widget _grid(String kind, int count, (int, int)? Function(int) startOf) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (var n = 1; n <= count; n++)
            InkWell(
              key: ValueKey('goto-$kind-$n'),
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                final at = startOf(n);
                if (at != null) widget.onPick(at.$1, at.$2);
              },
              child: Container(
                width: 46,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.goldTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$n',
                  style: AppTheme.headline(
                    13,
                    weight: FontWeight.w700,
                    color: AppColors.emeraldDeep,
                  ),
                ),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final modes = ['goToSurah'.tr, 'juz'.tr, 'hizb'.tr, 'page'.tr];
    final digits = [
      FilteringTextInputFormatter.allow(
        RegExp('[0-9\u0660-\u0669\u06F0-\u06F9]'),
      ),
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('goTo'.tr, style: AppTheme.headline(17)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < modes.length; i++)
                    ChoiceChip(
                      key: ValueKey('goto-mode-$i'),
                      label: Text(modes[i], style: AppTheme.body(12.5)),
                      selected: _mode == i,
                      selectedColor: AppColors.goldTint,
                      onSelected: (_) => setState(() {
                        _mode = i;
                        _error = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              ...switch (_mode) {
                0 => [
                  DropdownButtonFormField<int>(
                    key: const ValueKey('goto-surah'),
                    initialValue: _surah,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    decoration: _field('', showError: false),
                    items: [
                      for (final s in _quran.surahs)
                        DropdownMenuItem(
                          value: s.number,
                          child: Text(
                            '${s.number}. ${s.nameSimple} · ${s.nameArabic}',
                            style: AppTheme.body(13.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _surah = v ?? _surah;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('goto-ayah'),
                    controller: _ayah,
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    decoration: _field(
                      'ayahRange'.trParams({
                        'max': '${_quran.surah(_surah).ayahs}',
                      }),
                    ),
                    onSubmitted: (_) => _goSurah(),
                  ),
                  const SizedBox(height: 12),
                  _goButton(_goSurah),
                ],
                1 => [_grid('juz', QuranService.juzCount, _quran.juzStart)],
                2 => [_grid('hizb', QuranService.hizbCount, _quran.hizbStart)],
                _ => [
                  TextField(
                    key: const ValueKey('goto-page'),
                    controller: _page,
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    decoration: _field(
                      'pageRange'.trParams({
                        'max': '${QuranService.pageCount}',
                      }),
                    ),
                    onSubmitted: (_) => _goPage(),
                  ),
                  const SizedBox(height: 12),
                  _goButton(_goPage),
                ],
              },
            ],
          ),
        ),
      ),
    );
  }
}
