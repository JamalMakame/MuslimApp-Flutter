import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/habit_service.dart';
import '../../controllers/memorize_controller.dart';
import '../../services/quran_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/floating_nav_pill.dart';

/// Memorization, playback and optional on-device Quran audio.
class MemorizeScreen extends StatefulWidget {
  const MemorizeScreen({super.key});

  @override
  State<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends State<MemorizeScreen> {
  final _controlsKey = GlobalKey();
  late final Future<void> _ready = QuranService.instance.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(body: Center(child: Text('quranLoadFailed'.tr)));
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return _content(context);
    },
  );

  Widget _content(BuildContext context) {
    final c = Get.find<MemorizeController>();
    return Scaffold(
      backgroundColor: AppColors.ivory,
      bottomNavigationBar: const FloatingNavPill(active: 'quran'),
      body: SafeArea(
        child: Obx(() {
          final selectedReciter = c.reciter.value;
          final repeatCount = c.repeat.value;
          final repeatIcon = Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.goldTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.repeat, size: 16, color: AppColors.gold),
          );
          final repeatDescription = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'repeatAyah'.tr,
                style: AppTheme.body(14, weight: FontWeight.w700),
              ),
              Text(
                'memRepetition'.tr,
                style: AppTheme.body(11, color: AppColors.sage),
              ),
            ],
          );
          final repeatStepper = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepBtn(
                icon: Icons.remove,
                tooltip: 'decreaseRepeat'.tr,
                onTap: repeatCount > 1
                    ? () => c.setRepeat(repeatCount - 1)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${repeatCount}x',
                  style: AppTheme.body(
                    15,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                tooltip: 'increaseRepeat'.tr,
                onTap: repeatCount < 10
                    ? () => c.setRepeat(repeatCount + 1)
                    : null,
                filled: true,
              ),
            ],
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
            children: [
              // ---- Header ----------------------------------------------------
              Row(
                children: [
                  _CircleBtn(
                    icon: Icons.arrow_back,
                    tooltip: 'back'.tr,
                    onTap: Get.back,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'memEyebrow'.tr,
                          style: AppTheme.body(
                            10,
                            weight: FontWeight.w700,
                            color: AppColors.gold,
                          ).copyWith(letterSpacing: 1.5),
                        ),
                        Text(
                          'memTitle'.trParams({'surah': c.surahName}),
                          style: AppTheme.headline(
                            MediaQuery.sizeOf(context).width < 360 ? 16 : 19,
                            weight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _CircleBtn(
                    icon: Icons.tune,
                    tooltip: 'audioSettings'.tr,
                    onTap: () {
                      final target = _controlsKey.currentContext;
                      if (target != null) {
                        Scrollable.ensureVisible(
                          target,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          alignment: 0.05,
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Ayah card --------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _SmallNavBtn(
                          icon: Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_right
                              : Icons.chevron_left,
                          tooltip: 'previousAyah'.tr,
                          onTap: c.ayahIndex.value == 0 ? null : c.prev,
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
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
                                    Icons.auto_awesome,
                                    size: 12,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    (MediaQuery.sizeOf(context).width < 360
                                            ? 'ayahOfCompact'
                                            : 'ayahOf')
                                        .trParams({
                                          'x': '${c.ayahIndex.value + 1}',
                                          'y': '${c.ayahs.length}',
                                        }),
                                    style: AppTheme.body(
                                      11,
                                      weight: FontWeight.w700,
                                      color: AppColors.goldInk,
                                    ).copyWith(letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _SmallNavBtn(
                          icon: Directionality.of(context) == TextDirection.rtl
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                          tooltip: 'nextAyah'.tr,
                          onTap: c.ayahIndex.value == c.ayahs.length - 1
                              ? null
                              : c.next,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        c.testMode.value ? c.maskedText : c.ayah.text,
                        key: const ValueKey('mem-ayah-text'),
                        textAlign: TextAlign.center,
                        style: AppTheme.quran(26, height: 2.0),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (c.ayahs.length <= 8)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < c.ayahs.length; i++)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 24,
                              height: 5,
                              decoration: BoxDecoration(
                                color: i <= c.ayahIndex.value
                                    ? AppColors.emerald
                                    : AppColors.hairline,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                        ],
                      )
                    else
                      SizedBox(
                        width: 150,
                        child: LinearProgressIndicator(
                          value: (c.ayahIndex.value + 1) / c.ayahs.length,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(99),
                          color: AppColors.emerald,
                          backgroundColor: AppColors.hairline,
                        ),
                      ),
                    const SizedBox(height: 8),
                    _SelfTest(c: c),
                    if (c.translation.isNotEmpty &&
                        (!c.testMode.value ||
                            c.revealed.value >= c.words.length)) ...[
                      const SizedBox(height: 10),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '"${c.translation}"',
                          textAlign: TextAlign.center,
                          style: AppTheme.body(
                            13,
                            weight: FontWeight.w500,
                            color: AppColors.ink,
                          ).copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ---- Reciter picker ----------------------------------------------
              Row(
                children: [
                  Text(
                    'reciter'.tr,
                    style: AppTheme.body(
                      11,
                      weight: FontWeight.w700,
                      color: AppColors.sage,
                    ).copyWith(letterSpacing: 1.1),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _showReciters(c),
                    child: Text(
                      'changeVoice'.tr,
                      style: AppTheme.body(
                        11,
                        weight: FontWeight.w600,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: QuranService.reciters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final e = QuranService.reciters.entries.elementAt(i);
                    final active = selectedReciter == e.key;
                    return InkWell(
                      onTap: () => c.setReciter(e.key),
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: active ? AppColors.emerald : AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: active
                                ? AppColors.emerald
                                : AppColors.hairline,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              active && c.downloadProgress.value == 1
                                  ? Icons.offline_pin
                                  : active
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 15,
                              color: active ? AppColors.gold : AppColors.sage,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              e.value,
                              style: AppTheme.body(
                                12,
                                weight: FontWeight.w600,
                                color: active ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // ---- Loop controls -------------------------------------------------
              Container(
                key: _controlsKey,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  children: [
                    if (MediaQuery.sizeOf(context).width < 375)
                      Column(
                        children: [
                          Row(
                            children: [
                              repeatIcon,
                              const SizedBox(width: 10),
                              Expanded(child: repeatDescription),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: repeatStepper,
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          repeatIcon,
                          const SizedBox(width: 10),
                          Expanded(child: repeatDescription),
                          repeatStepper,
                        ],
                      ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'autoAdvanceAyah'.tr,
                                style: AppTheme.body(
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'autoAdvanceDesc'.tr,
                                style: AppTheme.body(11, color: AppColors.sage),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: c.autoAdvance.value,
                          onChanged: c.setAutoAdvance,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.emerald,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    InkWell(
                      key: const ValueKey('hifz-range'),
                      onTap: () => Get.dialog<void>(_RangeDialog(c: c)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'hifzRange'.tr,
                                  style: AppTheme.body(
                                    14,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'hifzRangeValue'.trParams({
                                    'from': '${c.rangeFrom.value}',
                                    'to': '${c.rangeTo.value}',
                                    'm': '${c.rangeRepeat.value}',
                                  }),
                                  style: AppTheme.body(
                                    11,
                                    color: AppColors.sage,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.sage),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Text(
                          'playbackSpeed'.tr,
                          style: AppTheme.body(13, weight: FontWeight.w700),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.ivory,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Row(
                            children: [
                              for (final s in MemorizeController.speeds)
                                GestureDetector(
                                  onTap: () => c.setSpeed(s),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          MediaQuery.sizeOf(context).width < 360
                                          ? 2
                                          : 10,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: c.speed.value == s
                                          ? AppColors.emerald
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${s}x',
                                      style: AppTheme.body(
                                        11,
                                        weight: FontWeight.w700,
                                        color: c.speed.value == s
                                            ? Colors.white
                                            : AppColors.sage,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ---- Player ------------------------------------------------------
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircleBtn(
                          icon: Icons.replay_10,
                          tooltip: 'skipBack'.tr,
                          onTap: () => c.seekBy(-10),
                        ),
                        const SizedBox(width: 22),
                        SizedBox(
                          width: 74,
                          height: 74,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 74,
                                height: 74,
                                child: CircularProgressIndicator(
                                  value: c.duration.value.inMilliseconds == 0
                                      ? 0
                                      : (c.position.value.inMilliseconds /
                                                c.duration.value.inMilliseconds)
                                            .clamp(0.0, 1.0),
                                  strokeWidth: 3,
                                  color: AppColors.gold,
                                  backgroundColor: AppColors.goldTint,
                                ),
                              ),
                              IconButton(
                                tooltip: c.loadingAudio.value
                                    ? 'stopLoadingAudio'.tr
                                    : c.playing.value
                                    ? 'pauseAudio'.tr
                                    : 'playAudio'.tr,
                                onPressed: c.toggle,
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  minimumSize: const Size(58, 58),
                                  shape: const CircleBorder(),
                                ),
                                icon: c.loadingAudio.value
                                    ? const SizedBox(
                                        width: 26,
                                        height: 26,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        c.playing.value
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 22),
                        _CircleBtn(
                          icon: Icons.forward_10,
                          tooltip: 'skipForward'.tr,
                          onTap: () => c.seekBy(10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${c.fmt(c.position.value)} / ${c.fmt(c.duration.value)}',
                          style: AppTheme.body(
                            12,
                            weight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt,
                                size: 11,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'repetitionOf'.trParams({
                                  'n': '${c.repetition.value}',
                                  'm': '${c.repeat.value}',
                                }),
                                style: AppTheme.body(
                                  10,
                                  weight: FontWeight.w700,
                                  color: AppColors.goldInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.playError.value
                          ? 'audioPlaybackFailed'.tr
                          : c.currentAyahOffline.value
                          ? 'availableOffline'.tr
                          : 'audioNotCached'.tr,
                      textAlign: TextAlign.center,
                      style: AppTheme.body(
                        11,
                        color: c.playError.value
                            ? Theme.of(context).colorScheme.error
                            : AppColors.sage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ---- Offline audio ---------------------------------------------
              Text(
                'offlineAudio'.tr,
                style: AppTheme.body(
                  11,
                  weight: FontWeight.w700,
                  color: AppColors.sage,
                ).copyWith(letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.goldTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            c.downloadProgress.value == 1
                                ? Icons.check
                                : Icons.download_outlined,
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
                                c.downloadProgress.value == 1
                                    ? 'downloaded'.tr
                                    : 'downloadForOffline'.tr,
                                style: AppTheme.body(
                                  13,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${c.reciterName} · ${c.surahName}'
                                '${c.downloadedBytes.value > 0 ? ' · ${(c.downloadedBytes.value / 1048576).toStringAsFixed(1)} MB' : ''}',
                                style: AppTheme.body(11, color: AppColors.sage),
                              ),
                            ],
                          ),
                        ),
                        if (c.checkingOffline.value)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (c.downloadProgress.value == null)
                          OutlinedButton(
                            onPressed: c.downloadSurah,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.emerald,
                              side: BorderSide(color: AppColors.emerald),
                              minimumSize: const Size(76, 44),
                            ),
                            child: Text('downloadBtn'.tr),
                          )
                        else if (c.downloadProgress.value! < 1)
                          SizedBox(
                            width: 46,
                            child: Text(
                              '${(c.downloadProgress.value! * 100).round()}%',
                              textAlign: TextAlign.end,
                              style: AppTheme.body(
                                12,
                                weight: FontWeight.w700,
                                color: AppColors.emerald,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            tooltip: 'deleteOffline'.tr,
                            onPressed: () async {
                              final remove = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text('removeAudioTitle'.tr),
                                  content: Text(
                                    'removeAudioBody'.trParams({
                                      'surah': c.surahName,
                                      'reciter': c.reciterName,
                                    }),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: Text('cancel'.tr),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: Text('removeBtn'.tr),
                                    ),
                                  ],
                                ),
                              );
                              if (remove == true && !c.isClosed) {
                                await c.deleteDownload();
                              }
                            },
                            icon: Icon(
                              Icons.delete_outline,
                              size: 19,
                              color: AppColors.sage,
                            ),
                          ),
                      ],
                    ),
                    if (c.downloadProgress.value != null &&
                        c.downloadProgress.value! < 1) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: c.downloadProgress.value,
                          minHeight: 4,
                          color: AppColors.emerald,
                          backgroundColor: AppColors.hairline,
                        ),
                      ),
                    ],
                    if (c.downloadError.value) ...[
                      const SizedBox(height: 8),
                      Text(
                        'downloadFailed'.tr,
                        style: AppTheme.body(
                          11,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _showReciters(MemorizeController c) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.ivory,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'changeVoice'.tr,
                style: AppTheme.headline(18, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final entry in QuranService.reciters.entries)
                ListTile(
                  title: Text(entry.value, style: AppTheme.body(14)),
                  leading: Icon(
                    entry.key == c.reciter.value
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: AppColors.emerald,
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await c.setReciter(entry.key);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: AppColors.surface,
      minimumSize: const Size(44, 44),
      shape: CircleBorder(side: BorderSide(color: AppColors.hairline)),
    ),
    icon: Icon(icon, size: 18, color: AppColors.ink),
  );
}

class _SmallNavBtn extends StatelessWidget {
  const _SmallNavBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: AppColors.ivory,
      minimumSize: const Size(40, 40),
      shape: CircleBorder(side: BorderSide(color: AppColors.hairline)),
    ),
    icon: Icon(icon, size: 17, color: AppColors.sage),
  );
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: filled ? AppColors.emerald : AppColors.ivory,
      minimumSize: const Size(40, 40),
      shape: CircleBorder(
        side: BorderSide(
          color: filled ? AppColors.emerald : AppColors.hairline,
        ),
      ),
    ),
    icon: Icon(icon, size: 16, color: filled ? Colors.white : AppColors.sage),
  );
}

/// Pick the ayahs to practise and how many times to run through them.
class _RangeDialog extends StatefulWidget {
  const _RangeDialog({required this.c});

  final MemorizeController c;

  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  late final _from = TextEditingController(text: '${widget.c.rangeFrom.value}');
  late final _to = TextEditingController(text: '${widget.c.rangeTo.value}');
  late int _rounds = widget.c.rangeRepeat.value;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  int _read(TextEditingController t, int fallback) =>
      int.tryParse(QuranService.westernDigits(t.text.trim())) ?? fallback;

  Widget _field(String key, String label, TextEditingController t) => TextField(
    key: ValueKey(key),
    controller: t,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp('[0-9\u0660-\u0669\u06F0-\u06F9]'),
      ),
    ],
    decoration: InputDecoration(
      labelText: label,
      helperText: '1–${widget.c.ayahs.length}',
      border: const OutlineInputBorder(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('hifzRange'.tr, style: AppTheme.headline(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field('range-from', 'rangeFrom'.tr, _from),
          const SizedBox(height: 10),
          _field('range-to', 'rangeTo'.tr, _to),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('rangeRounds'.tr, style: AppTheme.body(13))),
              IconButton(
                key: const ValueKey('range-rounds-minus'),
                onPressed: _rounds > 1 ? () => setState(() => _rounds--) : null,
                icon: const Icon(Icons.remove),
              ),
              Text(
                '${_rounds}x',
                style: AppTheme.body(14, weight: FontWeight.w700),
              ),
              IconButton(
                key: const ValueKey('range-rounds-plus'),
                onPressed: _rounds < 10
                    ? () => setState(() => _rounds++)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text('cancel'.tr, style: AppTheme.body(13)),
        ),
        TextButton(
          key: const ValueKey('range-save'),
          onPressed: () {
            final c = widget.c;
            final from = _read(_from, 1);
            final to = _read(_to, c.ayahs.length);
            Get.back<void>();
            c.setRange(from, to, _rounds);
          },
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

class _SelfTest extends StatelessWidget {
  const _SelfTest({required this.c});
  final MemorizeController c;

  @override
  Widget build(BuildContext context) => Obx(() {
    final h = HabitService.instance;
    h.version.value;
    final entry = h.hifzOf(c.surahNumber, c.ayah.numberInSurah);
    final count = h.memorisedPerSurah[c.surahNumber] ?? 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (entry?.memorised ?? false)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Icon(
                  Icons.verified,
                  key: const ValueKey('mem-memorised'),
                  size: 16,
                  color: AppColors.emerald,
                ),
              ),
            Text(
              'memorisedOfN'.trParams({
                'n': '$count',
                't': '${c.ayahs.length}',
              }),
              style: AppTheme.body(11.5, color: AppColors.sage),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              key: const ValueKey('self-test'),
              onPressed: c.testMode.toggle,
              icon: Icon(
                c.testMode.value ? Icons.visibility : Icons.visibility_off,
                size: 18,
              ),
              label: Text('selfTest'.tr),
            ),
          ],
        ),
        if (c.testMode.value)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton(
                key: const ValueKey('reveal-word'),
                onPressed: c.revealWord,
                child: Text('revealWord'.tr),
              ),
              OutlinedButton(
                key: const ValueKey('reveal-all'),
                onPressed: c.revealAll,
                child: Text('revealAll'.tr),
              ),
              FilledButton(
                key: const ValueKey('hifz-ok'),
                onPressed: () => c.grade(true),
                child: Text('memorised'.tr),
              ),
              OutlinedButton(
                key: const ValueKey('hifz-again'),
                onPressed: () => c.grade(false),
                child: Text('needsReview'.tr),
              ),
            ],
          ),
      ],
    );
  });
}
