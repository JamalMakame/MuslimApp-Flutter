import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/hadith_service.dart';
import '../../theme/app_theme.dart';

/// An-Nawawi's 40 Hadith: a list that expands into Arabic + English.
class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showEnglish = Get.locale?.languageCode != 'ar';
    return Scaffold(
      backgroundColor: AppColors.ivory,
      appBar: AppBar(title: Text('hadithLibrary'.tr)),
      body: FutureBuilder<List<Hadith>>(
        future: HadithService.instance.load(),
        builder: (_, snap) {
          final list = snap.data;
          if (list == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            key: const ValueKey('hadith-list'),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final h = list[i];
              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  key: ValueKey('hadith-${h.number}'),
                  title: Text(
                    'hadithN'.trParams({'n': '${h.number}'}),
                    style: AppTheme.body(14, weight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    h.arabic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: AppTheme.body(12, color: AppColors.sage),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    Text(
                      h.arabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: AppTheme.quran(17, height: 2.0),
                    ),
                    if (showEnglish) ...[
                      const SizedBox(height: 10),
                      Text(h.english, style: AppTheme.body(13.5, height: 1.6)),
                    ],
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        icon: const Icon(Icons.share_outlined, size: 18),
                        onPressed: () => Share.share(
                          '${h.arabic}\n\n${h.english}\n— ${'hadithLibrary'.tr} ${h.number}',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
