import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_theme.dart';

/// Per-prayer minute adjustments and reminder timing.
class PrayerTuningScreen extends StatelessWidget {
  const PrayerTuningScreen({super.key});

  static String leadLabel(int m) => switch (m) {
    < 0 => 'reminderOff'.tr,
    0 => 'reminderAtTime'.tr,
    _ => 'reminderBefore'.trParams({'m': '$m'}),
  };

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: Text('prayerTuning'.tr)),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final key in PrayerService.keys)
              Card(
                key: ValueKey('tune-$key'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key.tr,
                        style: AppTheme.body(15, weight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'adjustMinutes'.tr,
                              style: AppTheme.body(12, color: AppColors.sage),
                            ),
                          ),
                          IconButton(
                            key: ValueKey('offset-$key-minus'),
                            icon: const Icon(Icons.remove),
                            onPressed: () => c.setPrayerOffset(
                              key,
                              (c.prayerOffsets[key] ?? 0) - 1,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              _signed(c.prayerOffsets[key] ?? 0),
                              key: ValueKey('offset-$key'),
                              textAlign: TextAlign.center,
                              style: AppTheme.body(14, weight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            key: ValueKey('offset-$key-plus'),
                            icon: const Icon(Icons.add),
                            onPressed: () => c.setPrayerOffset(
                              key,
                              (c.prayerOffsets[key] ?? 0) + 1,
                            ),
                          ),
                        ],
                      ),
                      if (key != 'sunrise')
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'reminder'.tr,
                                style: AppTheme.body(12, color: AppColors.sage),
                              ),
                            ),
                            DropdownButton<int>(
                              key: ValueKey('lead-$key'),
                              value: c.leadFor(key),
                              underline: const SizedBox.shrink(),
                              items: [
                                for (final m
                                    in SettingsController.reminderLeads)
                                  DropdownMenuItem(
                                    value: m,
                                    child: Text(
                                      leadLabel(m),
                                      style: AppTheme.body(13),
                                    ),
                                  ),
                              ],
                              onChanged: (m) {
                                if (m != null) c.setPrayerLead(key, m);
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
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

  static String _signed(int m) => m > 0 ? '+$m' : '$m';
}
