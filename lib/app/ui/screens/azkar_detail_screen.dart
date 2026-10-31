import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../controllers/azkar_controller.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Category detail — sticky header w/ progress, recitation-mode strip,
/// stacked dhikr cards with tap-to-count.
class AzkarDetailScreen extends StatefulWidget {
  const AzkarDetailScreen({super.key, required this.bucket});

  final String bucket;

  @override
  State<AzkarDetailScreen> createState() => _AzkarDetailScreenState();
}

class _AzkarDetailScreenState extends State<AzkarDetailScreen> {
  late final AzkarDetailController c = Get.find<AzkarDetailController>(
    tag: 'azkar_${widget.bucket}',
  );

  @override
  void initState() {
    super.initState();
    c.initCounters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'azkar'),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundIconBtn(icon: Icons.arrow_back, onTap: Get.back),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              widget.bucket.tr,
                              style: AppTheme.headline(
                                17,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Obx(
                              () => Text(
                                'ofCompleted'.trParams({
                                  'done': '${c.completedItems}',
                                  'total': '${c.totalItems}',
                                  'left': '${c.totalItems - c.completedItems}',
                                }),
                                style: AppTheme.body(
                                  10.5,
                                  color: AppColors.sage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RoundIconBtn(
                        icon: Icons.volume_up_outlined,
                        onTap: () {},
                      ),
                      const SizedBox(width: 8),
                      _RoundIconBtn(icon: Icons.tune, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Gold-tipped progress bar
                  Obx(() {
                    final pct = c.totalItems == 0
                        ? 0.0
                        : c.completedItems / c.totalItems;
                    return SizedBox(
                      height: 4,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.hairline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: pct.clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.emerald,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Recitation-mode strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: appCardDecoration(radius: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_stories,
                      size: 16,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'recitationMode'.tr,
                      style: AppTheme.body(12, weight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ivory,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Text(
                        'SUNNAH',
                        style: AppTheme.body(
                          9,
                          weight: FontWeight.w700,
                          color: AppColors.sage,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'autoAdvance'.tr,
                      style: AppTheme.body(11, color: AppColors.sage),
                    ),
                    const SizedBox(width: 6),
                    Obx(
                      () => SizedBox(
                        height: 22,
                        child: Switch(
                          value: c.autoAdvance.value,
                          onChanged: (v) => c.autoAdvance.value = v,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Cards
            Expanded(
              child: Obx(() {
                // register dep
                c.remaining.length;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                  itemCount: c.items.length,
                  itemBuilder: (_, i) => _DhikrCard(
                    item: c.items[i],
                    index: i,
                    total: c.totalItems,
                    left: c.remaining[i] ?? c.items[i].count,
                    onTap: () => c.tap(i),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({
    required this.item,
    required this.index,
    required this.total,
    required this.left,
    required this.onTap,
  });

  final DhikrItem item;
  final int index;
  final int total;
  final int left;
  final VoidCallback onTap;

  bool get done => left <= 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: appCardDecoration(radius: 18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldTint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  '${(index + 1).toString().padLeft(2, '0')} / $total',
                  style: AppTheme.body(
                    10.5,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (item.count > 1)
                Row(
                  children: [
                    const Icon(Icons.repeat, size: 13, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Text(
                      'repeatNx'.trParams({'n': '${item.count}'}),
                      style: AppTheme.body(
                        10.5,
                        weight: FontWeight.w600,
                        color: AppColors.sage,
                      ),
                    ),
                  ],
                ),
              if (item.reference.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text('·', style: AppTheme.body(11, color: AppColors.hairline)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.reference,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body(10.5, color: AppColors.sage),
                  ),
                ),
              ],
              const Spacer(),
              const Icon(
                Icons.bookmark_border,
                size: 17,
                color: AppColors.sage,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Share.share(item.zekr),
                child: const Icon(
                  Icons.share_outlined,
                  size: 17,
                  color: AppColors.sage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Arabic
          Text(
            item.zekr,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTheme.quran(17, height: 2.0),
          ),

          // Description / virtue note
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.gold, width: 3),
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Text(
                item.description,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTheme.body(11.5, color: AppColors.sage, height: 1.5),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Counter CTA
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: done ? AppColors.ivory : AppColors.emerald,
                borderRadius: BorderRadius.circular(999),
                border: done ? Border.all(color: AppColors.hairline) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (done)
                    const Icon(
                      Icons.check_circle,
                      size: 17,
                      color: AppColors.emerald,
                    )
                  else
                    const Icon(
                      Icons.fingerprint,
                      size: 17,
                      color: Colors.white70,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    done
                        ? 'doneCount'.trParams({
                            'n': '${item.count}',
                            'total': '${item.count}',
                          })
                        : (item.count > 1
                              ? 'tapToCount'.tr
                              : 'tapToComplete'.tr),
                    style: AppTheme.body(
                      12.5,
                      weight: FontWeight.w700,
                      color: done ? AppColors.emerald : Colors.white,
                    ),
                  ),
                  if (!done) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$left ${'remaining'.tr}',
                        style: AppTheme.body(
                          11,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Icon(icon, size: 17, color: AppColors.ink),
      ),
    );
  }
}
