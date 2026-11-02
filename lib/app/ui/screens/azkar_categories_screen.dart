import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/azkar_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../routes/app_pages.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Azkar & Duas — daily progress card, 2-col category grid, instant
/// dhikr card. Tab 2 of the floating nav.
class AzkarCategoriesScreen extends GetView<AzkarController> {
  const AzkarCategoriesScreen({super.key});

  static const _icons = <String, IconData>{
    'catMorning': Icons.wb_sunny_outlined,
    'catEvening': Icons.nightlight_outlined,
    'catAfterPrayer': Icons.favorite_border,
    'catSleep': Icons.bedtime_outlined,
    'catWaking': Icons.alarm,
    'catAdhan': Icons.campaign_outlined,
    'catTravel': Icons.flight_outlined,
    'catRuqyahQuran': Icons.shield_outlined,
    'catRuqyahSunnah': Icons.shield_moon_outlined,
    'catGratitude': Icons.favorite_outline,
    'catOther': Icons.auto_stories,
  };

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'azkar'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
          children: [
            // Top row: location chip + action icons
            Row(
              children: [
                Icon(Icons.location_on, size: 15, color: AppColors.emerald),
                const SizedBox(width: 4),
                Text(
                  settings.placeLabel,
                  style: AppTheme.body(
                    11.5,
                    weight: FontWeight.w600,
                    color: AppColors.emeraldDeep,
                  ),
                ),
                const Spacer(),
                const _TopIcon(icon: Icons.search),
                const SizedBox(width: 8),
                const _TopIcon(icon: Icons.notifications_none),
              ],
            ),
            const SizedBox(height: 16),

            // Title + saved pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'azkarDuas'.tr,
                        style: AppTheme.headline(22, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'remembrance'.tr,
                        style: AppTheme.body(12.5, color: AppColors.sage),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldTint,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'saved'.tr,
                        style: AppTheme.body(11, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Daily progress card
            GetBuilder<AzkarController>(
              builder: (c) => Container(
                decoration: appCardDecoration(),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.goldTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wb_twilight,
                            size: 17,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'dailyProgress'.tr,
                                style: AppTheme.body(
                                  9.5,
                                  weight: FontWeight.w700,
                                  color: AppColors.sage,
                                  letterSpacing: 0.9,
                                ),
                              ),
                              Text(
                                'catMorning'.tr,
                                style: AppTheme.headline(
                                  13.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Text(
                            '${c.featuredDone} / ${c.featuredTotal}',
                            style: AppTheme.body(
                              11.5,
                              weight: FontWeight.w700,
                              color: AppColors.emerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c.featuredTotal == 0
                            ? 0
                            : c.featuredDone / c.featuredTotal,
                        minHeight: 7,
                        backgroundColor: AppColors.ivory,
                        valueColor: AlwaysStoppedAnimation(AppColors.emerald),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 13,
                          color: AppColors.emerald,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'pctCompleted'.trParams({'pct': '${c.featuredPct}'}),
                          style: AppTheme.body(11, color: AppColors.sage),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Get.toNamed(
                            Routes.azkarDetail(c.featuredBucket),
                          )?.then((_) => c.update()),
                          child: Row(
                            children: [
                              Text(
                                'continueRecitation'.tr,
                                style: AppTheme.body(
                                  11,
                                  weight: FontWeight.w600,
                                  color: AppColors.emerald,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 15,
                                color: AppColors.emerald,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categories header
            Row(
              children: [
                Text(
                  'categories'.tr,
                  style: AppTheme.body(
                    10.5,
                    weight: FontWeight.w700,
                    color: AppColors.sage,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  'collections'.trParams({
                    'count': '${controller.categories.length}',
                  }),
                  style: AppTheme.body(10.5, color: AppColors.sage),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 2-col grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.28,
              ),
              itemCount: controller.categories.length,
              itemBuilder: (_, i) {
                final bucket = controller.categories[i];
                return _CategoryTile(
                  icon: _icons[bucket] ?? Icons.auto_stories,
                  name: bucket.tr,
                  count: controller.totalOf(bucket),
                  onTap: () => Get.toNamed(
                    Routes.azkarDetail(bucket),
                  )?.then((_) => controller.update()),
                );
              },
            ),
            const SizedBox(height: 16),

            // Instant dhikr
            GestureDetector(
              onTap: () => Get.toNamed(Routes.tasbeeh),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.brandDeep,
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [AppColors.brand, AppColors.brandDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'instantDhikr'.tr,
                            style: AppTheme.body(
                              9.5,
                              weight: FontWeight.w700,
                              color: AppColors.gold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'سبحان الله وبحمده',
                            textDirection: TextDirection.rtl,
                            style: AppTheme.quran(
                              16,
                              weight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'openCounter'.tr,
                            style: AppTheme.body(
                              10.5,
                              color: AppColors.onBrand.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fingerprint,
                        color: AppColors.emeraldDeep,
                        size: 21,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Icon(icon, size: 17, color: AppColors.sage),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.name,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String name;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: appCardDecoration(),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 21, color: AppColors.gold),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.headline(13, weight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ${'supplications'.tr}',
                style: AppTheme.body(10.5, color: AppColors.sage),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
