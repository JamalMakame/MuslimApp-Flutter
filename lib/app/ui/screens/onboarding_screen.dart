import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../routes/app_pages.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

/// First-run setup — language, location (GPS or manual), calc method.
/// No accounts; everything stays on-device.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _settings = Get.find<SettingsController>();
  final _locations = LocationService();
  final _cityCtrl = TextEditingController();

  bool _locating = false;
  bool _manual = false;
  String? _error;

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    final place = await _locations.current();
    _locating = false;
    if (!mounted) return;
    if (place == null) {
      setState(() {
        _error = 'locationFailed'.tr;
        _manual = true;
      });
      return;
    }
    await _settings.setLocation(
      lat: place.lat,
      lng: place.lng,
      city: place.city,
      country: place.country,
      source: 'gps',
    );
    setState(() {});
  }

  Future<void> _applyManual() async {
    final name = _cityCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _locating = true;
      _error = null;
    });
    final place = await _locations.fromCityName(name);
    _locating = false;
    if (!mounted) return;
    if (place == null) {
      setState(() => _error = 'locationFailed'.tr);
      return;
    }
    await _settings.setLocation(
      lat: place.lat,
      lng: place.lng,
      city: place.city,
      country: place.country,
      source: 'manual',
    );
    setState(() => _manual = false);
  }

  Future<void> _finish() async {
    await Get.find<AppController>().completeOnboarding();
    Get.offAllNamed(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 28),
            // Emblem
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.goldTint,
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(Icons.mosque, color: AppColors.gold, size: 34),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'appName'.tr,
                  style: AppTheme.headline(32, weight: FontWeight.w800),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.mosque_outlined,
                  color: AppColors.gold,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'onboardTitle'.tr,
              textAlign: TextAlign.center,
              style: AppTheme.body(14, color: AppColors.sage, height: 1.5),
            ),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldTint,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'onboardBadge'.tr,
                      style: AppTheme.body(
                        11,
                        weight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ---- Language ----
            _SectionCard(
              eyebrow: 'languageLocale'.tr,
              title: 'selectLanguage'.tr,
              trailingIcon: Icons.translate,
              child: Obx(
                () => Row(
                  children: [
                    for (final code in SettingsController.localeCodes)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _LangPill(
                            label: switch (code) {
                              'ar' => 'arabic'.tr,
                              'sw' => 'swahili'.tr,
                              _ => 'english'.tr,
                            },
                            selected: _settings.localeCode.value == code,
                            onTap: () => _settings.setLocale(code),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ---- Location ----
            _SectionCard(
              eyebrow: 'accuracyPrivacy'.tr,
              eyebrowBadge: 'offlineGps'.tr,
              title: 'prayerLocation'.tr,
              trailingIcon: Icons.explore_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'locationDesc'.tr,
                    style: AppTheme.body(
                      12.5,
                      color: AppColors.sage,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => _settings.hasLocation
                        ? _LocationSetRow(
                            label: _settings.placeLabel,
                            source: _settings.locationSource.value == 'gps'
                                ? 'gpsTag'.tr
                                : 'manualTag'.tr,
                            onChange: () {
                              setState(() {
                                _manual = true;
                                _error = null;
                              });
                            },
                          )
                        : Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(color: AppColors.hairline),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  onPressed: _locating
                                      ? null
                                      : _useCurrentLocation,
                                  icon: Icon(
                                    Icons.my_location,
                                    size: 17,
                                    color: AppColors.emerald,
                                  ),
                                  label: Text(
                                    'useCurrentLocation'.tr,
                                    style: AppTheme.body(
                                      13,
                                      weight: FontWeight.w600,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => setState(() {
                                      _manual = !_manual;
                                      _error = null;
                                    }),
                                    icon: Icon(
                                      Icons.edit_location_alt_outlined,
                                      size: 16,
                                      color: AppColors.emerald,
                                    ),
                                    label: Text(
                                      'setManualLocation'.tr,
                                      style: AppTheme.body(
                                        12.5,
                                        weight: FontWeight.w600,
                                        color: AppColors.emerald,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  _MiniBadge(
                                    icon: Icons.lock_outline,
                                    label: 'zeroCloudLogs'.tr,
                                  ),
                                ],
                              ),
                              if (_manual) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _cityCtrl,
                                        onSubmitted: (_) => _applyManual(),
                                        decoration: InputDecoration(
                                          hintText: 'manualLocationHint'.tr,
                                          hintStyle: AppTheme.body(
                                            13,
                                            color: AppColors.sage,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.ivory,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 12,
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.hairline,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.hairline,
                                            ),
                                          ),
                                        ),
                                        style: AppTheme.body(13),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton.filled(
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.emerald,
                                      ),
                                      onPressed: _locating
                                          ? null
                                          : _applyManual,
                                      icon: const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                  ),
                  if (_locating)
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.emerald,
                          ),
                        ),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: AppTheme.body(12, color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---- Calculation method ----
            _SectionCard(
              eyebrow: 'astroCalc'.tr,
              title: 'calcMethod'.tr,
              trailingIcon: Icons.calculate_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => _MethodPicker(
                      value: _settings.calcMethod.value,
                      onChanged: _settings.setCalcMethod,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'recommended'.tr,
                    style: AppTheme.body(
                      11.5,
                      color: AppColors.sage,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: _finish,
                icon: const SizedBox.shrink(),
                label: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'continueBtn'.tr,
                      style: AppTheme.body(
                        15,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'localConsent'.tr,
              textAlign: TextAlign.center,
              style: AppTheme.body(11, color: AppColors.sage),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.trailingIcon,
    this.eyebrowBadge,
  });

  final String eyebrow;
  final String title;
  final Widget child;
  final IconData? trailingIcon;
  final String? eyebrowBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appCardDecoration(radius: 18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, size: 13, color: AppColors.emerald),
              const SizedBox(width: 4),
              Text(
                eyebrow,
                style: AppTheme.body(
                  10.5,
                  weight: FontWeight.w700,
                  color: AppColors.sage,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (eyebrowBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    eyebrowBadge!,
                    style: AppTheme.body(
                      10,
                      weight: FontWeight.w600,
                      color: AppColors.emerald,
                    ),
                  ),
                )
              else if (trailingIcon != null)
                Icon(trailingIcon, size: 18, color: AppColors.gold),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: AppTheme.headline(16, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.emerald : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.emerald : AppColors.hairline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTheme.body(
            12.5,
            weight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _LocationSetRow extends StatelessWidget {
  const _LocationSetRow({
    required this.label,
    required this.source,
    required this.onChange,
  });

  final String label;
  final String source;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.body(13, weight: FontWeight.w600)),
                Text(source, style: AppTheme.body(10.5, color: AppColors.sage)),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            child: Text(
              'setManualLocation'.tr,
              style: AppTheme.body(
                11.5,
                weight: FontWeight.w600,
                color: AppColors.emerald,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.ivory,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.sage),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.body(
              10,
              weight: FontWeight.w500,
              color: AppColors.sage,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodPicker extends StatelessWidget {
  const _MethodPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  static const _methods = {
    'umm_al_qura': ('ummAlQura', 'ummAlQuraDesc'),
    'mwl': ('mwl', 'mwlDesc'),
    'egypt': ('egypt', 'egyptDesc'),
    'karachi': ('karachi', 'karachiDesc'),
    'isna': ('isna', 'isnaDesc'),
  };

  @override
  Widget build(BuildContext context) {
    final (nameKey, descKey) = _methods[value] ?? _methods['umm_al_qura']!;
    return GestureDetector(
      onTap: () => Get.bottomSheet(
        _MethodSheet(value: value, onChanged: onChanged),
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairline),
        ),
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
                Icons.calculate,
                size: 16,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameKey.tr,
                    style: AppTheme.body(13, weight: FontWeight.w700),
                  ),
                  Text(
                    descKey.tr,
                    style: AppTheme.body(10.5, color: AppColors.sage),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: AppColors.sage, size: 20),
          ],
        ),
      ),
    );
  }
}

class _MethodSheet extends StatelessWidget {
  const _MethodSheet({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            for (final e in _MethodPicker._methods.entries)
              ListTile(
                title: Text(
                  e.value.$1.tr,
                  style: AppTheme.body(13.5, weight: FontWeight.w600),
                ),
                subtitle: Text(
                  e.value.$2.tr,
                  style: AppTheme.body(11, color: AppColors.sage),
                ),
                trailing: e.key == value
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
                  onChanged(e.key);
                  Get.back();
                },
              ),
          ],
        ),
      ),
    );
  }
}
