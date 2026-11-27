import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ChannelSchedulerScreen extends StatefulWidget {
  const ChannelSchedulerScreen({super.key});

  @override
  State<ChannelSchedulerScreen> createState() => _ChannelSchedulerScreenState();
}

class _ChannelSchedulerScreenState extends State<ChannelSchedulerScreen> {
  bool _loading = true;

  List<_ScheduledChannel> _items = [];

  static final _defaults = <_ScheduledChannel>[
    _ScheduledChannel(channel: 7, name: 'Morning News', time: '06:00', days: {0, 1, 2, 3, 4}, enabled: true),
    _ScheduledChannel(channel: 205, name: 'ESPN Sports', time: '18:00', days: {0, 1, 2, 3, 4, 5, 6}, enabled: true),
    _ScheduledChannel(channel: 310, name: 'Movie Channel', time: '20:00', days: {5, 6}, enabled: false),
    _ScheduledChannel(channel: 401, name: 'Kids Cartoon', time: '08:00', days: {5, 6}, enabled: true),
    _ScheduledChannel(channel: 150, name: 'Late Night', time: '23:00', days: {0, 1, 2, 3, 4}, enabled: false),
  ];

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_scheduler.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _items = list.map((e) {
          final j = e as Map<String, dynamic>;
          return _ScheduledChannel(
            channel: j['channel'] as int? ?? 0,
            name: j['name'] as String? ?? '',
            time: j['time'] as String? ?? '00:00',
            days: ((j['days'] as List?) ?? []).map((d) => d as int).toSet(),
            enabled: j['enabled'] as bool? ?? true,
          );
        }).toList();
      } else {
        _items = List.of(_defaults);
      }
    } catch (_) {
      _items = List.of(_defaults);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    final data = _items.map((s) => {
      'channel': s.channel,
      'name': s.name,
      'time': s.time,
      'days': s.days.toList(),
      'enabled': s.enabled,
    }).toList();
    await f.writeAsString(jsonEncode(data));
  }

  void _tuneNow(_ScheduledChannel item) {
    final rc = RemoteScope.of(context);
    final digits = item.channel.toString().split('');
    for (final d in digits) {
      switch (d) {
        case '0': rc.key(core.Key.ok); break;
        case '1': rc.key(core.Key.up); break;
        case '2': rc.key(core.Key.down); break;
        case '3': rc.key(core.Key.left); break;
        case '4': rc.key(core.Key.right); break;
        case '5': rc.key(core.Key.menu); break;
        default: rc.key(core.Key.ok);
      }
    }
    rc.key(core.Key.ok);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Tuning to CH ${item.channel}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _toggleEnabled(int idx) {
    setState(() => _items[idx].enabled = !_items[idx].enabled);
    HapticFeedback.selectionClick();
    _save();
  }

  void _removeItem(int idx) {
    setState(() => _items.removeAt(idx));
    HapticFeedback.selectionClick();
    _save();
  }

  void _resetAll() {
    setState(() => _items = List.of(_defaults));
    HapticFeedback.mediumImpact();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final active = _items.where((i) => i.enabled).length;
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Channel Schedule',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: hex(AppColors.outline)),
            onPressed: _resetAll,
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
                _statsRow(active),
                const SizedBox(height: AppSpacing.md),
                ..._items.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _scheduleCard(e.key, e.value),
                    )),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Auto-Tune Schedule',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Schedule your TV to switch channels at set times',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow(int active) => Row(
        children: [
          Expanded(
              child: _statBadge(
                  'Total', '${_items.length}', AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge('Active', '$active', AppColors.signalEmerald)),
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

  Widget _scheduleCard(int idx, _ScheduledChannel item) => GestureDetector(
        onTap: () => _tuneNow(item),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(item.enabled
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: item.enabled ? 0.08 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(item.enabled
                      ? AppColors.primary
                      : AppColors.outlineVariant)
                  .withValues(alpha: item.enabled ? 0.25 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('${item.channel}',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w700,
                          size: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 12, color: hex(AppColors.outline)),
                        const SizedBox(width: 4),
                        Text(item.time,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 11)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.days.map((d) => _dayLabels[d]).join(', '),
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleEnabled(idx),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hex(item.enabled
                            ? AppColors.signalEmerald
                            : AppColors.outline)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                  ),
                  child: Text(item.enabled ? 'ON' : 'OFF',
                      style: gfont(AppType.bodySm,
                          color: hex(item.enabled
                              ? AppColors.signalEmerald
                              : AppColors.outline),
                          weight: FontWeight.w700,
                          size: 10)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeItem(idx),
                child: Icon(Icons.close,
                    size: 18, color: hex(AppColors.outline)),
              ),
            ],
          ),
        ),
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
                'Schedule channels to auto-tune at set times. '
                'Tap a schedule to tune now. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _ScheduledChannel {
  int channel;
  String name;
  String time;
  Set<int> days;
  bool enabled;
  _ScheduledChannel({
    required this.channel,
    required this.name,
    required this.time,
    required this.days,
    required this.enabled,
  });
}
