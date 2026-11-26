import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _Reminder {
  _Reminder({
    required this.title,
    required this.channel,
    required this.dateTime,
    this.autoTurnOn = false,
    this.repeat = 'None',
  });

  factory _Reminder.fromJson(Map<String, dynamic> j) => _Reminder(
        title: j['title'] as String,
        channel: j['channel'] as String,
        dateTime:
            DateTime.tryParse(j['dateTime'] as String? ?? '') ?? DateTime.now(),
        autoTurnOn: j['autoTurnOn'] as bool? ?? false,
        repeat: j['repeat'] as String? ?? 'None',
      );

  final String title;
  final String channel;
  final DateTime dateTime;
  final bool autoTurnOn;
  final String repeat;

  Map<String, dynamic> toJson() => {
        'title': title,
        'channel': channel,
        'dateTime': dateTime.toIso8601String(),
        'autoTurnOn': autoTurnOn,
        'repeat': repeat,
      };

  String get dateStr {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String get timeStr {
    final h = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $ampm';
  }
}

class TvCalendarScreen extends StatefulWidget {
  const TvCalendarScreen({super.key});

  @override
  State<TvCalendarScreen> createState() => _TvCalendarScreenState();
}

class _TvCalendarScreenState extends State<TvCalendarScreen> {
  List<_Reminder> _reminders = [];
  bool _loading = true;
  final _titleCtrl = TextEditingController();
  final _channelCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _autoTurnOn = false;
  int _repeatIndex = 0;

  static const _repeatOptions = [
    'None',
    'Daily',
    'Weekly',
    'Weekdays',
    'Weekends',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _channelCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_calendar.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _reminders = list
            .map((j) => _Reminder.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(
        jsonEncode(_reminders.map((r) => r.toJson()).toList()));
  }

  void _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) setState(() => _selectedDate = d);
  }

  void _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (t != null && mounted) setState(() => _selectedTime = t);
  }

  void _addReminder() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    setState(() {
      _reminders.insert(
        0,
        _Reminder(
          title: title,
          channel: _channelCtrl.text.trim(),
          dateTime: dt,
          autoTurnOn: _autoTurnOn,
          repeat: _repeatOptions[_repeatIndex],
        ),
      );
      if (_reminders.length > 50) _reminders = _reminders.sublist(0, 50);
    });
    _titleCtrl.clear();
    _channelCtrl.clear();
    _save();
  }

  void _delete(int index) {
    setState(() => _reminders.removeAt(index));
    _save();
  }

  void _triggerReminder(_Reminder r) {
    final rc = RemoteScope.of(context);
    if (r.autoTurnOn) rc.key(core.Key.power);
    if (r.channel.isNotEmpty) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          for (final ch in r.channel.characters) {
            rc.type(ch);
          }
        }
      });
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Triggered: ${r.title}'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(
            child:
                CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Calendar',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _addSection(),
          const SizedBox(height: AppSpacing.md),
          if (_reminders.isEmpty)
            _emptyState()
          else ...[
            Text('Reminders (${_reminders.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._reminders.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _reminderCard(e.value, e.key),
                )),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_month, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('TV Viewing Calendar',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Set reminders for shows, sports events, or premieres with auto TV turn-on',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _addSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Reminder',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Show or event name',
                hintStyle: gfont(AppType.bodySm,
                    color: hex(AppColors.outline).withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                      color: hex(AppColors.outlineVariant)
                          .withValues(alpha: 0.3)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _channelCtrl,
              keyboardType: TextInputType.number,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Channel number (optional)',
                hintStyle: gfont(AppType.bodySm,
                    color: hex(AppColors.outline).withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                      color: hex(AppColors.outlineVariant)
                          .withValues(alpha: 0.3)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: hex(AppColors.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: hex(AppColors.primary)),
                          const SizedBox(width: 6),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: hex(AppColors.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: hex(AppColors.primary)),
                          const SizedBox(width: 6),
                          Text(
                            _selectedTime.format(context),
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _autoTurnOn = !_autoTurnOn),
                  child: Row(
                    children: [
                      Icon(
                        _autoTurnOn
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                        color: hex(
                            _autoTurnOn ? AppColors.primary : AppColors.outline),
                      ),
                      const SizedBox(width: 6),
                      Text('Auto turn on TV',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface), size: 11)),
                    ],
                  ),
                ),
                const Spacer(),
                _repeatChip(),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _addReminder,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('Add Reminder',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _repeatChip() => GestureDetector(
        onTap: () => setState(
            () => _repeatIndex = (_repeatIndex + 1) % _repeatOptions.length),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hex(AppColors.tertiary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.repeat, size: 12, color: hex(AppColors.tertiary)),
              const SizedBox(width: 4),
              Text(_repeatOptions[_repeatIndex],
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.tertiary),
                      size: 10,
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _reminderCard(_Reminder r, int index) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('${r.dateStr} · ${r.timeStr}',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      if (r.channel.isNotEmpty)
                        Text(' · Ch ${r.channel}',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.primary), size: 10)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (r.autoTurnOn)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: hex(AppColors.signalEmerald)
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text('Auto ON',
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.signalEmerald),
                                  size: 8,
                                  weight: FontWeight.w600)),
                        ),
                      if (r.repeat != 'None') ...[
                        const SizedBox(width: 4),
                        Text(r.repeat,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.tertiary),
                                size: 9)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _triggerReminder(r),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(Icons.play_arrow,
                    size: 16, color: hex(AppColors.primary)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _delete(index),
              child:
                  Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
            ),
          ],
        ),
      );

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.event_busy, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No reminders set',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add a reminder for your favourite shows or live events.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
        ],
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'TV Calendar sets viewing reminders with optional auto-turn-on. Your phone sends the power and channel commands at the scheduled time. All reminders are stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
