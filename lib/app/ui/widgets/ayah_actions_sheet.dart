import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/reader_controller.dart';
import '../../data/models.dart';
import '../../routes/app_pages.dart';
import '../../services/link_service.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';
import 'tafsir_sheet.dart';

/// Arabic, translation, reference and a `deen://` link, for copy / share.
String ayahShareText(Surah s, Ayah a, String translation) => [
  a.text,
  if (translation.isNotEmpty) translation,
  '— ${s.nameSimple} ${s.number}:${a.numberInSurah}',
  LinkService.linkTo(s.number, a.numberInSurah).toString(),
].join('\n\n');

void showReaderToast(String message) => Get.rawSnackbar(
  messageText: Text(message, style: AppTheme.body(12, color: Colors.white)),
  snackPosition: SnackPosition.BOTTOM,
  backgroundColor: AppColors.brandDeep,
  duration: const Duration(seconds: 2),
  borderRadius: 12,
  margin: const EdgeInsets.all(16),
);

/// Note editor; returns the note, or null when cancelled.
Future<String?> editNoteDialog(String initial) =>
    Get.dialog<String>(_NoteDialog(initial: initial));

/// Owns its text controller so it outlives the closing animation.
class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});

  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.initial.isEmpty ? 'addNote'.tr : 'editNote'.tr,
        style: AppTheme.headline(16),
      ),
      content: TextField(
        key: const ValueKey('note-field'),
        controller: _text,
        autofocus: true,
        maxLines: 4,
        minLines: 2,
        style: AppTheme.body(14),
        decoration: InputDecoration(
          hintText: 'notePlaceholder'.tr,
          hintStyle: AppTheme.body(13, color: AppColors.sage),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<String>(),
          child: Text('cancel'.tr, style: AppTheme.body(13)),
        ),
        TextButton(
          key: const ValueKey('note-save'),
          onPressed: () => Get.back<String>(result: _text.text.trim()),
          child: Text(
            'save'.tr,
            style: AppTheme.body(
              13,
              weight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ),
      ],
    );
  }
}

/// Long-press menu of an ayah in the reader.
Future<void> showAyahActions(ReaderController c, Ayah ayah) =>
    Get.bottomSheet<void>(
      _AyahActions(c: c, ayah: ayah),
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );

class _AyahActions extends StatelessWidget {
  const _AyahActions({required this.c, required this.ayah});

  final ReaderController c;
  final Ayah ayah;

  @override
  Widget build(BuildContext context) {
    final quran = QuranService.instance;
    final s = c.surah;
    final n = ayah.numberInSurah;
    final bookmark = quran.bookmarkAt(s.number, n);
    final translation = c.translationOf(n);
    final text = ayahShareText(s, ayah, translation);

    Widget action(String key, IconData icon, String label, VoidCallback f) =>
        ListTile(
          key: ValueKey(key),
          dense: true,
          leading: Icon(icon, color: AppColors.emerald, size: 22),
          title: Text(label, style: AppTheme.body(14)),
          onTap: () {
            Get.back<void>();
            f();
          },
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '${s.nameSimple} ${s.number}:$n',
                style: AppTheme.headline(15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                ayah.text,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.quran(17, color: AppColors.sage, height: 1.8),
              ),
            ),
            const SizedBox(height: 6),
            action(
              'action-play',
              Icons.play_circle_outline,
              'playFromHere'.tr,
              () => c.playFrom(n),
            ),
            action(
              'action-bookmark',
              bookmark == null
                  ? Icons.bookmark_add_outlined
                  : Icons.bookmark_remove_outlined,
              bookmark == null ? 'bookmarkAyah'.tr : 'removeBookmark'.tr,
              () async {
                if (bookmark == null) {
                  await quran.saveBookmark(s.number, n);
                  showReaderToast(
                    'bookmarkAdded'.trParams({
                      'ref': '${s.nameSimple} ${s.number}:$n',
                    }),
                  );
                } else {
                  await quran.removeBookmark(s.number, n);
                  showReaderToast('bookmarkRemoved'.tr);
                }
              },
            ),
            action(
              'action-note',
              Icons.edit_note,
              (bookmark?.note.isNotEmpty ?? false)
                  ? 'editNote'.tr
                  : 'addNote'.tr,
              () async {
                final note = await editNoteDialog(bookmark?.note ?? '');
                if (note != null) {
                  await quran.saveBookmark(s.number, n, note: note);
                }
              },
            ),
            action('action-copy', Icons.copy, 'copy'.tr, () async {
              await Clipboard.setData(ClipboardData(text: text));
              showReaderToast('copied'.tr);
            }),
            action(
              'action-share',
              Icons.share,
              'share'.tr,
              () => Share.share(text),
            ),
            action(
              'action-tafsir',
              Icons.menu_book_outlined,
              'tafsirKathir'.tr,
              () => showTafsirSheet(
                surahNumber: s.number,
                ayahNumber: n,
                ayahText: ayah.text,
              ),
            ),
            action(
              'action-memorize',
              Icons.graphic_eq,
              'memorizeFromHere'.tr,
              () async {
                await c.pauseAudio();
                Get.toNamed(Routes.memorize(s.number, ayah: n));
              },
            ),
          ],
        ),
      ),
    );
  }
}
