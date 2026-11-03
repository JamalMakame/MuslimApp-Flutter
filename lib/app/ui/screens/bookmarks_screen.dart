import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models.dart';
import '../../routes/app_pages.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/ayah_actions_sheet.dart';
import '../widgets/floating_nav_pill.dart';
import '../widgets/motion.dart';

/// Bookmarked ayahs, newest first, with their notes.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quran = QuranService.instance;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'quran'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: Icon(Icons.arrow_back, color: AppColors.ink),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'bookmarksTitle'.tr,
                    style: AppTheme.headline(20, weight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final list = quran.bookmarksRx.toList();
                if (list.isEmpty) {
                  return Center(
                    key: const ValueKey('bookmarks-empty'),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 120,
                            child: DeenRive(
                              'empty',
                              fallback: PopInIcon(
                                Icons.bookmark_add_outlined,
                                color: AppColors.emerald,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'noBookmarks'.tr,
                            textAlign: TextAlign.center,
                            style: AppTheme.body(13.5, color: AppColors.sage),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _BookmarkTile(bookmark: list[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.bookmark});

  final AyahBookmark bookmark;

  @override
  Widget build(BuildContext context) {
    final quran = QuranService.instance;
    final s = quran.surah(bookmark.surah);
    final ayah = quran.ayahAt(bookmark.surah, bookmark.ayah);
    final key = bookmark.verseKey;
    return InkWell(
      key: ValueKey('bookmark-$key'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => openQuranAt(bookmark.surah, bookmark.ayah),
      child: Container(
        decoration: appCardDecoration(),
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        child: Row(
          children: [
            const Icon(Icons.bookmark, color: AppColors.gold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.nameSimple} $key',
                    style: AppTheme.body(13.5, weight: FontWeight.w700),
                  ),
                  if (ayah != null)
                    Text(
                      ayah.text,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.quran(
                        15,
                        color: AppColors.sage,
                        height: 1.7,
                      ),
                    ),
                  if (bookmark.note.isNotEmpty)
                    Text(
                      bookmark.note,
                      style: AppTheme.body(
                        12.5,
                        color: AppColors.ink,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              key: ValueKey('bookmark-note-$key'),
              tooltip: bookmark.note.isEmpty ? 'addNote'.tr : 'editNote'.tr,
              icon: Icon(Icons.edit_note, color: AppColors.sage),
              onPressed: () async {
                final note = await editNoteDialog(bookmark.note);
                if (note != null) {
                  await quran.saveBookmark(
                    bookmark.surah,
                    bookmark.ayah,
                    note: note,
                  );
                }
              },
            ),
            IconButton(
              key: ValueKey('bookmark-delete-$key'),
              tooltip: 'removeBookmark'.tr,
              icon: Icon(Icons.delete_outline, color: AppColors.sage),
              onPressed: () =>
                  quran.removeBookmark(bookmark.surah, bookmark.ayah),
            ),
          ],
        ),
      ),
    );
  }
}
