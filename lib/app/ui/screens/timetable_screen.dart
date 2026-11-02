import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:share_plus/share_plus.dart';

import '../../controllers/settings_controller.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_theme.dart';

/// One month of prayer times for the saved location, shareable as text.
List<(DateTime, List<PrayerSlot>)> monthTimetable(
  DateTime month,
  SettingsController s,
) {
  final prayers = PrayerService();
  final days = DateTime(month.year, month.month + 1, 0).day;
  return [
    for (var d = 1; d <= days; d++)
      (
        DateTime(month.year, month.month, d),
        prayers.slotsOn(
          DateTime(month.year, month.month, d),
          lat: s.latitude.value!,
          lng: s.longitude.value!,
          method: s.calcMethod.value,
          madhab: s.madhab.value,
          tuning: s.tuning,
        ),
      ),
  ];
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final s = Get.find<SettingsController>();
  var _month = DateTime(DateTime.now().year, DateTime.now().month);

  String get _locale => s.localeCode.value;

  String _shareText(List<(DateTime, List<PrayerSlot>)> rows) {
    final hm = DateFormat('HH:mm');
    final b = StringBuffer()
      ..writeln(
        '${'monthlyTimetable'.tr} — ${DateFormat('MMMM y', _locale).format(_month)}',
      )
      ..writeln(s.placeLabel)
      ..writeln(
        ['dateCol'.tr, for (final k in PrayerService.keys) k.tr].join(' | '),
      );
    for (final (day, slots) in rows) {
      b.writeln(
        [
          DateFormat('d MMM', _locale).format(day),
          for (final slot in slots) hm.format(slot.time),
        ].join(' | '),
      );
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final rows = s.hasLocation
        ? monthTimetable(_month, s)
        : <(DateTime, List<PrayerSlot>)>[];
    final hm = DateFormat('HH:mm');
    final today = DateUtils.dateOnly(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: Text('monthlyTimetable'.tr),
        actions: [
          if (rows.isNotEmpty)
            IconButton(
              key: const ValueKey('timetable-share'),
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.share(_shareText(rows)),
            ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: const ValueKey('timetable-prev'),
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
              ),
              Text(
                DateFormat('MMMM y', _locale).format(_month),
                key: const ValueKey('timetable-month'),
                style: AppTheme.body(15, weight: FontWeight.w700),
              ),
              IconButton(
                key: const ValueKey('timetable-next'),
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1),
                ),
              ),
            ],
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('unknownPlace'.tr, style: AppTheme.body(13)),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 14,
                    headingTextStyle: AppTheme.body(
                      12,
                      weight: FontWeight.w700,
                    ),
                    dataTextStyle: AppTheme.body(12),
                    columns: [
                      DataColumn(label: Text('dateCol'.tr)),
                      for (final k in PrayerService.keys)
                        DataColumn(label: Text(k.tr)),
                    ],
                    rows: [
                      for (final (day, slots) in rows)
                        DataRow(
                          selected: day == today,
                          cells: [
                            DataCell(
                              Text(DateFormat('EEE d', _locale).format(day)),
                            ),
                            for (final slot in slots)
                              DataCell(Text(hm.format(slot.time))),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
