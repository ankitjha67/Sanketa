import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

/// Event-based channel auto-switcher.
///
/// Users schedule one-off viewing events ("IPL Final on Star Sports at 7:30 PM")
/// and the app auto-tunes to that channel at the scheduled time while connected.
class AutoChannelSwitchScreen extends StatefulWidget {
  const AutoChannelSwitchScreen({super.key});

  @override
  State<AutoChannelSwitchScreen> createState() =>
      _AutoChannelSwitchScreenState();
}

class _AutoChannelSwitchScreenState extends State<AutoChannelSwitchScreen> {
  bool _loading = true;
  bool _masterEnabled = true;
  List<_SwitchEvent> _events = [];

  final _nameCtrl = TextEditingController();
  final _channelCtrl = TextEditingController();
  int _pickedHour = 20;
  int _pickedMin = 0;
  int _categoryIdx = 0;

  static const _categories = <(String, IconData, int)>[
    ('Sports', Icons.sports_cricket, AppColors.signalEmerald),
    ('News', Icons.newspaper, AppColors.primary),
    ('Movie', Icons.movie, AppColors.alertAmber),
    ('Show', Icons.tv, AppColors.secondary),
    ('Music', Icons.music_note, AppColors.tertiary),
    ('Other', Icons.category, AppColors.outline),
  ];

  static final _sampleEvents = <_SwitchEvent>[
    _SwitchEvent(
      name: 'IPL Final — CSK vs MI',
      channel: 204,
      hour: 19,
      minute: 30,
      category: 0,
      enabled: true,
      fired: false,
    ),
    _SwitchEvent(
      name: 'Evening News Bulletin',
      channel: 7,
      hour: 21,
      minute: 0,
      category: 1,
      enabled: true,
      fired: false,
    ),
    _SwitchEvent(
      name: 'Saturday Night Movie',
      channel: 310,
      hour: 22,
      minute: 0,
      category: 2,
      enabled: false,
      fired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _channelCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/auto_channel_switch.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _masterEnabled = raw['enabled'] as bool? ?? true;
        final list = raw['events'] as List? ?? [];
        _events = list.map((e) {
          final j = e as Map<String, dynamic>;
          return _SwitchEvent(
            name: j['name'] as String? ?? '',
            channel: j['channel'] as int? ?? 0,
            hour: j['hour'] as int? ?? 0,
            minute: j['minute'] as int? ?? 0,
            category: j['category'] as int? ?? 5,
            enabled: j['enabled'] as bool? ?? true,
            fired: j['fired'] as bool? ?? false,
          );
        }).toList();
      } else {
        _events = List.of(_sampleEvents);
      }
    } catch (_) {
      _events = List.of(_sampleEvents);
    }
    if (mounted) setState(() => _loading = false);
    _startWatcher();
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _masterEnabled,
      'events': _events
          .map((e) => {
                'name': e.name,
                'channel': e.channel,
                'hour': e.hour,
                'minute': e.minute,
                'category': e.category,
                'enabled': e.enabled,
                'fired': e.fired,
              })
          .toList(),
    }));
  }

  void _startWatcher() {
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      _checkEvents();
      _startWatcher();
    });
  }

  void _checkEvents() {
    if (!_masterEnabled) return;
    final now = TimeOfDay.now();
    for (final event in _events) {
      if (!event.enabled || event.fired) continue;
      if (event.hour == now.hour && event.minute == now.minute) {
        _tuneToChannel(event, auto: true);
        setState(() => event.fired = true);
        _save();
      }
    }
  }

  String _fmtTime(int h, int m) {
    final ampm = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $ampm';
  }

  String _timeUntil(int h, int m) {
    final now = TimeOfDay.now();
    var mins = (h * 60 + m) - (now.hour * 60 + now.minute);
    if (mins < 0) mins += 24 * 60;
    if (mins == 0) return 'Now';
    final hours = mins ~/ 60;
    final rem = mins % 60;
    if (hours == 0) return '${rem}m';
    if (rem == 0) return '${hours}h';
    return '${hours}h ${rem}m';
  }

  void _tuneToChannel(_SwitchEvent event, {bool auto = false}) {
    final rc = RemoteScope.of(context);
    final digits = event.channel.toString().split('');
    for (final d in digits) {
      rc.type(d);
    }
    rc.key(core.Key.ok);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(auto
            ? 'Auto-switched to CH ${event.channel} — ${event.name}'
            : 'Tuning to CH ${event.channel}'),
        duration: const Duration(seconds: 3),
      ));
  }

  void _addEvent() {
    final name = _nameCtrl.text.trim();
    final chStr = _channelCtrl.text.trim();
    if (name.isEmpty || chStr.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Enter event name and channel number'),
          duration: Duration(seconds: 2),
        ));
      return;
    }
    final ch = int.tryParse(chStr);
    if (ch == null || ch <= 0) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Enter a valid channel number'),
          duration: Duration(seconds: 2),
        ));
      return;
    }
    setState(() {
      _events.insert(
        0,
        _SwitchEvent(
          name: name,
          channel: ch,
          hour: _pickedHour,
          minute: _pickedMin,
          category: _categoryIdx,
          enabled: true,
          fired: false,
        ),
      );
      _nameCtrl.clear();
      _channelCtrl.clear();
    });
    HapticFeedback.heavyImpact();
    _save();
  }

  void _toggleEvent(int idx) {
    setState(() {
      _events[idx].enabled = !_events[idx].enabled;
      if (_events[idx].enabled) _events[idx].fired = false;
    });
    HapticFeedback.selectionClick();
    _save();
  }

  void _removeEvent(int idx) {
    setState(() => _events.removeAt(idx));
    HapticFeedback.selectionClick();
    _save();
  }

  void _resetFired() {
    setState(() {
      for (final e in _events) {
        e.fired = false;
      }
    });
    HapticFeedback.mediumImpact();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final active = _events.where((e) => e.enabled && !e.fired).length;
    final upcoming = _events.where((e) => e.enabled && !e.fired).toList()
      ..sort((a, b) {
        final aMins = a.hour * 60 + a.minute;
        final bMins = b.hour * 60 + b.minute;
        return aMins.compareTo(bMins);
      });
    final nextUp = upcoming.isNotEmpty ? upcoming.first : null;

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Auto Switch',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: hex(AppColors.outline)),
            onPressed: _resetFired,
            tooltip: 'Reset all',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _heroCard(),
                const SizedBox(height: AppSpacing.md),
                _masterToggle(),
                const SizedBox(height: AppSpacing.md),
                if (nextUp != null) ...[
                  _nextUpCard(nextUp),
                  const SizedBox(height: AppSpacing.md),
                ],
                _statsRow(active),
                const SizedBox(height: AppSpacing.lg),
                _addSection(),
                const SizedBox(height: AppSpacing.lg),
                if (_events.isNotEmpty) ...[
                  Text('Scheduled Events',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  const SizedBox(height: AppSpacing.sm),
                  ..._events.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _eventCard(e.key, e.value),
                      )),
                ],
                const SizedBox(height: AppSpacing.lg),
                _infoCard(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.swap_horiz,
                size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Auto Channel Switch',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Never miss a match, show, or broadcast.\n'
              'Set what you want to watch and when — your TV switches automatically.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _masterToggle() => GestureDetector(
        onTap: () {
          setState(() => _masterEnabled = !_masterEnabled);
          HapticFeedback.selectionClick();
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_masterEnabled
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _masterEnabled ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_masterEnabled
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: _masterEnabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.power_settings_new,
                  size: 22,
                  color: hex(_masterEnabled
                      ? AppColors.signalEmerald
                      : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Auto-Switch',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(
                      _masterEnabled
                          ? 'Watching for scheduled events'
                          : 'Paused — no auto-switching',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_masterEnabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_masterEnabled ? 'ACTIVE' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_masterEnabled
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 10)),
              ),
            ],
          ),
        ),
      );

  Widget _nextUpCard(_SwitchEvent event) {
    final cat = _categories[event.category.clamp(0, _categories.length - 1)];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(cat.$3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(cat.$3).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hex(cat.$3).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Center(child: Icon(cat.$2, size: 24, color: hex(cat.$3))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UP NEXT',
                    style: gfont(AppType.bodySm,
                        color: hex(cat.$3),
                        weight: FontWeight.w700,
                        size: 9)),
                Text(event.name,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  'CH ${event.channel}  •  ${_fmtTime(event.hour, event.minute)}  •  in ${_timeUntil(event.hour, event.minute)}',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 10),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _tuneToChannel(event),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hex(cat.$3).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text('Watch Now',
                  style: gfont(AppType.bodySm,
                      color: hex(cat.$3),
                      weight: FontWeight.w700,
                      size: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(int active) => Row(
        children: [
          Expanded(
              child:
                  _statBadge('Total', '${_events.length}', AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge('Active', '$active', AppColors.signalEmerald)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Fired',
                  '${_events.where((e) => e.fired).length}',
                  AppColors.alertAmber)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 20, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _addSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Event',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 13)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameCtrl,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), size: 13),
              decoration: InputDecoration(
                hintText: 'e.g. IPL Final — CSK vs MI',
                hintStyle: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 12),
                filled: true,
                fillColor: hex(AppColors.surface),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                      color:
                          hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                      color:
                          hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _channelCtrl,
                    keyboardType: TextInputType.number,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface), size: 13),
                    decoration: InputDecoration(
                      hintText: 'CH #',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 12),
                      filled: true,
                      fillColor: hex(AppColors.surface),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _timePicker()),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _categoryChips(),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: _addEvent,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color:
                      hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.signalEmerald)
                          .withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_alarm,
                        size: 20, color: hex(AppColors.signalEmerald)),
                    const SizedBox(width: 8),
                    Text('Schedule Event',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.signalEmerald),
                            weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _timePicker() => GestureDetector(
        onTap: () {
          setState(() {
            _pickedMin = (_pickedMin + 15) % 60;
            if (_pickedMin == 0) {
              _pickedHour = (_pickedHour + 1) % 24;
            }
          });
          HapticFeedback.selectionClick();
        },
        onLongPress: () {
          setState(() {
            _pickedHour = (_pickedHour + 1) % 24;
          });
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time,
                  size: 16, color: hex(AppColors.primary)),
              const SizedBox(width: 6),
              Text(_fmtTime(_pickedHour, _pickedMin),
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600,
                      size: 13)),
              const Spacer(),
              Text('tap +15m',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
      );

  Widget _categoryChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.asMap().entries.map((e) {
            final active = e.key == _categoryIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _categoryIdx = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hex(e.value.$3)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(e.value.$3)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.$2,
                          size: 12, color: hex(e.value.$3)),
                      const SizedBox(width: 4),
                      Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(e.value.$3),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 10)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _eventCard(int idx, _SwitchEvent event) {
    final cat = _categories[event.category.clamp(0, _categories.length - 1)];
    final isFired = event.fired;
    return GestureDetector(
      onTap: () => _tuneToChannel(event),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(isFired
                  ? AppColors.outline
                  : event.enabled
                      ? cat.$3
                      : AppColors.surfaceContainerLow)
              .withValues(alpha: isFired
                  ? 0.05
                  : event.enabled
                      ? 0.08
                      : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(isFired
                    ? AppColors.outline
                    : event.enabled
                        ? cat.$3
                        : AppColors.outlineVariant)
                .withValues(alpha: isFired
                    ? 0.15
                    : event.enabled
                        ? 0.25
                        : 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hex(cat.$3).withValues(alpha: isFired ? 0.05 : 0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Center(
                child: Text('${event.channel}',
                    style: gfont(AppType.bodyMd,
                        color: hex(isFired ? AppColors.outline : cat.$3),
                        weight: FontWeight.w700,
                        size: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(event.name,
                            style: gfont(AppType.bodyMd,
                                color: hex(isFired
                                    ? AppColors.outline
                                    : AppColors.onSurface),
                                weight: FontWeight.w600,
                                size: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isFired) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: hex(AppColors.signalEmerald)
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadii.full),
                          ),
                          child: Text('DONE',
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.signalEmerald),
                                  weight: FontWeight.w700,
                                  size: 8)),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Icon(cat.$2,
                          size: 10,
                          color: hex(isFired ? AppColors.outline : cat.$3)),
                      const SizedBox(width: 4),
                      Text(
                        '${cat.$1}  •  ${_fmtTime(event.hour, event.minute)}',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10),
                      ),
                      if (!isFired && event.enabled) ...[
                        const SizedBox(width: 6),
                        Text(
                          'in ${_timeUntil(event.hour, event.minute)}',
                          style: gfont(AppType.bodySm,
                              color: hex(cat.$3),
                              weight: FontWeight.w600,
                              size: 9),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _toggleEvent(idx),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hex(event.enabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(event.enabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(event.enabled
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 9)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _removeEvent(idx),
              child:
                  Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
            ),
          ],
        ),
      ),
    );
  }

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
                'Schedule any broadcast — sports, news, movies, shows. '
                'Your TV switches to the right channel at the right time '
                'while your phone is connected. Tap any event to tune now. '
                'All data stored locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _SwitchEvent {
  String name;
  int channel;
  int hour;
  int minute;
  int category;
  bool enabled;
  bool fired;

  _SwitchEvent({
    required this.name,
    required this.channel,
    required this.hour,
    required this.minute,
    required this.category,
    required this.enabled,
    required this.fired,
  });
}
