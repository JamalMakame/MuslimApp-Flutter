import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/settings_controller.dart';
import '../../services/audio_cache_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/quran_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Settings — all local. Sections: Prayer / Appearance / Quran & Audio /
/// Data & Privacy, per the Stitch mockup.
class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'settings'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
          children: [
            // Top row: back + private badge
            Row(
              children: [
                _RoundIconBtn(icon: Icons.arrow_back, onTap: () => Get.back()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user,
                        size: 13,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'privateOffline'.tr,
                        style: AppTheme.body(
                          11,
                          weight: FontWeight.w600,
                          color: AppColors.sage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'settings'.tr,
              style: AppTheme.headline(22, weight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: AppColors.sage),
                const SizedBox(width: 5),
                Text(
                  'prefsLocal'.tr,
                  style: AppTheme.body(13, color: AppColors.sage),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---- PRAYER ----
            _Group(
              title: 'prayerSection'.tr,
              children: [
                _SettingsRow(
                  title: 'calcMethod'.tr,
                  subtitleFn: () => _methodLabel(controller.calcMethod.value),
                  onTap: () => _pickSheet(
                    options: const [
                      'umm_al_qura',
                      'mwl',
                      'egypt',
                      'karachi',
                      'isna',
                    ],
                    selected: controller.calcMethod.value,
                    labelFor: _methodLabel,
                    onPick: controller.setCalcMethod,
                  ),
                  rebuildKeys: [controller.calcMethod],
                ),
                _SettingsRow(
                  title: 'madhabAsr'.tr,
                  subtitleFn: () => controller.madhab.value.tr,
                  onTap: () => _pickSheet(
                    options: SettingsController.madhabs,
                    selected: controller.madhab.value,
                    labelFor: (m) => m.tr,
                    onPick: controller.setMadhab,
                  ),
                  rebuildKeys: [controller.madhab],
                ),
                Obx(
                  () => _SettingsSwitch(
                    title: 'prayerNotifications'.tr,
                    subtitle: 'adhanReminders'.tr,
                    value: controller.notifyPrayers.value,
                    onChanged: controller.setNotifyPrayers,
                  ),
                ),
                _SettingsRow(
                  title: 'locationRow'.tr,
                  trailingBadgeFn: () =>
                      controller.locationSource.value == 'gps'
                      ? 'gpsTag'.tr
                      : (controller.locationSource.value.isEmpty
                            ? null
                            : 'manualTag'.tr),
                  subtitleFn: () => controller.placeLabel,
                  footer: 'calcOnDevice'.tr,
                  onTap: () => _pickLocation(context),
                  rebuildKeys: [
                    controller.city,
                    controller.country,
                    controller.locationSource,
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---- APPEARANCE ----
            _Group(
              title: 'appearanceSection'.tr,
              children: [
                _SettingsRow(
                  title: 'language'.tr,
                  trailingTextFn: () => switch (controller.localeCode.value) {
                    'ar' => 'arabic'.tr,
                    'sw' => 'swahili'.tr,
                    _ => 'english'.tr,
                  },
                  subtitle: 'العربية · Kiswahili',
                  onTap: () => _pickSheet(
                    options: SettingsController.localeCodes,
                    selected: controller.localeCode.value,
                    labelFor: (l) => switch (l) {
                      'ar' => 'arabic'.tr,
                      'sw' => 'swahili'.tr,
                      _ => 'english'.tr,
                    },
                    onPick: controller.setLocale,
                  ),
                  rebuildKeys: [controller.localeCode],
                ),
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'theme'.tr,
                          style: AppTheme.body(14, weight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        _ThemeSegment(
                          value: controller.themeMode.value,
                          onChanged: controller.setThemeMode,
                        ),
                      ],
                    ),
                  ),
                ),
                _SettingsRow(
                  title: 'textSize'.tr,
                  subtitle: 'textSizeDesc'.tr,
                  trailingTextFn: () => switch (controller.textScale.value) {
                    0 => 'sizeSmall'.tr,
                    2 => 'sizeLarge'.tr,
                    _ => 'sizeMedium'.tr,
                  },
                  onTap: () => _pickSheet(
                    options: const ['0', '1', '2'],
                    selected: '${controller.textScale.value}',
                    labelFor: (s) => switch (s) {
                      '0' => 'sizeSmall'.tr,
                      '2' => 'sizeLarge'.tr,
                      _ => 'sizeMedium'.tr,
                    },
                    onPick: (s) => controller.setTextScale(int.parse(s)),
                  ),
                  rebuildKeys: [controller.textScale],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---- QURAN & AUDIO ----
            _Group(
              title: 'quranAudioSection'.tr,
              children: [
                _SettingsRow(
                  title: 'defaultReciter'.tr,
                  subtitle: 'reciterDesc'.tr,
                  trailingText: 'misharyAlafasy'.tr,
                  onTap: () {},
                ),
                Obx(
                  () => _SettingsSwitch(
                    title: 'ayahAudio'.tr,
                    subtitle: 'ayahAudioDesc'.tr,
                    value: controller.ayahAudio.value,
                    onChanged: controller.setAyahAudio,
                  ),
                ),
                Obx(
                  () => _SettingsSwitch(
                    title: 'showTranslations'.tr,
                    subtitle: 'showTranslationsDesc'.tr,
                    value: controller.showTranslations.value,
                    onChanged: controller.setShowTranslations,
                  ),
                ),
                _SettingsRow(
                  title: 'translationLang'.tr,
                  trailingTextFn: () =>
                      switch (controller.translationLang.value) {
                        'sw' => 'swahili'.tr,
                        'ar' => 'arabic'.tr,
                        _ => 'english'.tr,
                      },
                  onTap: () => _pickSheet(
                    options: SettingsController.translationLangs,
                    selected: controller.translationLang.value,
                    labelFor: (l) => switch (l) {
                      'ar' => 'arabic'.tr,
                      'sw' => 'swahili'.tr,
                      _ => 'english'.tr,
                    },
                    onPick: controller.setTranslationLang,
                  ),
                  rebuildKeys: [controller.translationLang],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ---- DATA & PRIVACY ----
            _Group(
              title: 'dataPrivacySection'.tr,
              children: [
                _SettingsRow(
                  title: 'clearLocalData'.tr,
                  subtitle: 'clearLocalDesc'.tr,
                  danger: true,
                  onTap: _confirmClear,
                ),
                _SettingsRow(
                  title: 'privacyPolicy'.tr,
                  subtitle: 'privacyBody'.tr,
                  onTap: () => Get.bottomSheet(
                    _InfoSheet(
                      title: 'privacyPolicy'.tr,
                      body: 'privacyBody'.tr,
                    ),
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Privacy banner + footer
            Container(
              decoration: appCardDecoration(radius: 16),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.goldTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'privacyBody'.tr,
                      style: AppTheme.body(
                        12,
                        color: AppColors.sage,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    '· ${'appName'.tr} v1.0.0 ·',
                    style: AppTheme.body(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.sage,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'madeReverence'.tr,
                    style: AppTheme.body(
                      11,
                      color: AppColors.sage,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _methodLabel(String m) => switch (m) {
    'mwl' => 'mwl'.tr,
    'egypt' => 'egypt'.tr,
    'karachi' => 'karachi'.tr,
    'isna' => 'isna'.tr,
    _ => 'ummAlQura'.tr,
  };

  void _pickSheet({
    required List<String> options,
    required String selected,
    required String Function(String) labelFor,
    required ValueChanged<String> onPick,
  }) {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              for (final o in options)
                ListTile(
                  title: Text(
                    labelFor(o),
                    style: AppTheme.body(13.5, weight: FontWeight.w600),
                  ),
                  trailing: o == selected
                      ? Icon(
                          Icons.check_circle,
                          color: AppColors.emerald,
                          size: 20,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    onPick(o);
                    Get.back();
                  },
                ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void _pickLocation(BuildContext context) {
    final ctrl = TextEditingController();
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'locationRow'.tr,
                style: AppTheme.headline(16, weight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'manualLocationHint'.tr,
                  filled: true,
                  fillColor: AppColors.ivory,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.hairline),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                  ),
                  onPressed: () async {
                    final place = await LocationService().fromCityName(
                      ctrl.text.trim(),
                    );
                    if (place != null) {
                      await controller.setLocation(
                        lat: place.lat,
                        lng: place.lng,
                        city: place.city,
                        country: place.country,
                        source: 'manual',
                      );
                      Get.back();
                    }
                  },
                  child: Text(
                    'continueBtn'.tr,
                    style: AppTheme.body(
                      13,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void _confirmClear() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'confirmClear'.tr,
          style: AppTheme.headline(16, weight: FontWeight.w700),
        ),
        content: Text(
          'confirmClearBody'.tr,
          style: AppTheme.body(13, color: AppColors.sage, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'cancel'.tr,
              style: AppTheme.body(13, color: AppColors.sage),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await AudioCacheService.clearAllAudio();
                await StorageService.instance.clearAll();
                QuranService.instance.resetUserState();
                controller.reload();
                Get.updateLocale(controller.locale);
                await NotificationService.instance.cancelAll();
                Get.back();
                Get.offAllNamed('/onboarding');
              } catch (_) {
                Get.back();
                Get.snackbar('clearLocalData'.tr, 'clearFailed'.tr);
              }
            },
            child: Text(
              'clear'.tr,
              style: AppTheme.body(13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTheme.body(
              11,
              weight: FontWeight.w700,
              color: AppColors.sage,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: appCardDecoration(radius: 14),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.subtitle,
    this.subtitleFn,
    this.footer,
    this.trailingText,
    this.trailingTextFn,
    this.trailingBadgeFn,
    this.danger = false,
    this.onTap,
    this.rebuildKeys,
  });

  final String title;
  final String? subtitle;
  final String? Function()? subtitleFn;
  final String? footer;
  final String? trailingText;
  final String? Function()? trailingTextFn;
  final String? Function()? trailingBadgeFn;
  final bool danger;
  final VoidCallback? onTap;

  /// Reactive deps — when supplied, the *Fn builders are resolved
  /// inside an Obx so they refresh when prefs change.
  final List<Rx<dynamic>>? rebuildKeys;

  @override
  Widget build(BuildContext context) {
    Widget content() => Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: AppTheme.body(
                        14,
                        weight: FontWeight.w600,
                        color: danger ? Colors.redAccent : AppColors.ink,
                      ),
                    ),
                  ),
                  if (trailingBadgeFn?.call() != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trailingBadgeFn!()!,
                        style: AppTheme.body(
                          10,
                          weight: FontWeight.w600,
                          color: AppColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if ((subtitleFn?.call() ?? subtitle) != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitleFn?.call() ?? subtitle!,
                  style: AppTheme.body(12, color: AppColors.sage),
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        footer!,
                        style: AppTheme.body(10.5, color: AppColors.sage),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if ((trailingTextFn?.call() ?? trailingText) != null) ...[
          const SizedBox(width: 8),
          Text(
            trailingTextFn?.call() ?? trailingText!,
            style: AppTheme.body(
              12,
              weight: FontWeight.w600,
              color: AppColors.sage,
            ),
          ),
        ],
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right,
          size: 20,
          color: danger ? Colors.redAccent : AppColors.sage,
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: rebuildKeys == null
            ? content()
            : Obx(() {
                // Touching the Rx registers the dep; values are
                // re-resolved because build() re-invokes content().
                for (final k in rebuildKeys!) {
                  k.value;
                }
                return content();
              }),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.body(14, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTheme.body(12, color: AppColors.sage)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          for (final (mode, label) in [
            ('light', 'light'.tr),
            ('system', 'system'.tr),
            ('dark', 'dark'.tr),
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: mode == value
                        ? AppColors.emerald
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: AppTheme.body(
                      12,
                      weight: FontWeight.w600,
                      color: mode == value ? Colors.white : AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(title, style: AppTheme.headline(17, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              body,
              style: AppTheme.body(13.5, color: AppColors.sage, height: 1.6),
            ),
          ],
        ),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        child: Icon(icon, size: 19, color: AppColors.ink),
      ),
    );
  }
}
