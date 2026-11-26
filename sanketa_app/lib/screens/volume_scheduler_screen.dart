import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _VolumeRule {
  _VolumeRule({
    required this.label,
    required this.startHour,
    required this.endHour,
    required this.volume,
    this.enabled = true,
  });

  factory _VolumeRule.fromJson(Map<String, dynamic> j) => _VolumeRule(
        label: j['label'] as String,
        startHour: j['startHour'] as int,
        endHour: j['endHour'] as int,
        volume: j['volume'] as int,
        enabled: j['enabled'] as bool? ?? true,
      );

  final String label;
  final int startHour;
  final int endHour;
  final int volume;
  bool enabled;

  Map<String, dynamic> toJson() => {
        'label': label,
        'startHour': startHour,
        'endHour': endHour,
        'volume': volume,
        'enabled': enabled,
      };
}

class VolumeSchedulerScreen extends StatefulWidget {
  const VolumeSchedulerScreen({super.key});

  @override
  State<VolumeSchedulerScreen> createState() => _VolumeSchedulerScreenState();
}

class _VolumeSchedulerScreenState extends State<VolumeSchedulerScreen> {
  List<_VolumeRule> _rules = [];
  bool _loading = true;
  bool _masterEnabled = true;

  static const _presets = <(String, int, int, int)>[
    ('Morning Quiet', 6, 9, 15),
    ('Daytime Normal', 9, 18, 40),
    ('Evening Comfort', 18, 22, 30),
    ('Night Whisper', 22, 6, 10),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/volume_schedule.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _masterEnabled = data['masterEnabled'] as bool? ?? true;
        final list = data['rules'] as List? ?? [];
        _rules = list
            .map((j) => _VolumeRule.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'masterEnabled': _masterEnabled,
      'rules': _rules.map((r) => r.toJson()).toList(),
    }));
  }

  void _addPreset(int idx) {
    final p = _presets[idx];
    setState(() => _rules.add(_VolumeRule(
          label: p.$1,
          startHour: p.$2,
          endHour: p.$3,
          volume: p.$4,
        )));
    _save();
  }

  void _toggleRule(int idx) {
    setState(() => _rules[idx].enabled = !_rules[idx].enabled);
    _save();
  }

  void _deleteRule(int idx) {
    setState(() => _rules.removeAt(idx));
    _save();
  }

  void _applyNow(int volume) {
    final rc = RemoteScope.of(context);
    for (var i = 0; i < (volume ~/ 5); i++) {
      rc.key(core.Key.volumeUp);
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Volume set to ~$volume'),
        duration: const Duration(seconds: 2),
      ));
  }

  String _formatHour(int h) {
    final amPm = h >= 12 ? 'PM' : 'AM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour $amPm';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(
            child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Volume Scheduler',
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
          _masterToggle(),
          const SizedBox(height: AppSpacing.md),
          if (_rules.isNotEmpty) ...[
            Text('Active Rules (${_rules.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._rules.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ruleCard(e.value, e.key),
                )),
            const SizedBox(height: AppSpacing.md),
          ],
          Text('Quick Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._presets.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _presetCard(e.value, e.key),
              )),
          const SizedBox(height: AppSpacing.lg),
          _timelineCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
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
            Text('Smart Volume',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Set different volume levels for different times of day',
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
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_masterEnabled
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _masterEnabled ? 0.08 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_masterEnabled
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: _masterEnabled ? 0.3 : 0.15),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _masterEnabled ? Icons.check_circle : Icons.radio_button_off,
                size: 20,
                color: hex(_masterEnabled
                    ? AppColors.signalEmerald
                    : AppColors.outline),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume Schedule',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text(
                      _masterEnabled
                          ? 'Active — volume changes automatically'
                          : 'Paused — tap to resume',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _ruleCard(_VolumeRule rule, int idx) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleRule(idx),
              child: Icon(
                rule.enabled ? Icons.check_circle : Icons.radio_button_off,
                size: 18,
                color: hex(rule.enabled
                    ? AppColors.signalEmerald
                    : AppColors.outline),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.label,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 12)),
                  Text(
                    '${_formatHour(rule.startHour)} – ${_formatHour(rule.endHour)}',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _applyNow(rule.volume),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Vol ${rule.volume}',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 11)),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _deleteRule(idx),
              child: Icon(Icons.close, size: 16, color: hex(AppColors.outline)),
            ),
          ],
        ),
      );

  Widget _presetCard((String, int, int, int) preset, int idx) =>
      GestureDetector(
        onTap: () => _addPreset(idx),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.volume_up, size: 18, color: hex(AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(preset.$1,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                    Text(
                      '${_formatHour(preset.$2)} – ${_formatHour(preset.$3)} · Volume ${preset.$4}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline,
                  size: 20, color: hex(AppColors.primary)),
            ],
          ),
        ),
      );

  Widget _timelineCard() => Container(
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
            Text('24h Timeline',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                    size: 12)),
            const SizedBox(height: 8),
            SizedBox(
              height: 24,
              child: Row(
                children: List.generate(24, (h) {
                  final rule = _rules.cast<_VolumeRule?>().firstWhere(
                        (r) => r != null && r.enabled && _hourInRange(h, r.startHour, r.endHour),
                        orElse: () => null,
                      );
                  final vol = rule?.volume ?? 0;
                  final c = vol > 30
                      ? AppColors.signalEmerald
                      : vol > 15
                          ? AppColors.alertAmber
                          : vol > 0
                              ? AppColors.primary
                              : AppColors.outlineVariant;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                      decoration: BoxDecoration(
                        color: hex(c).withValues(alpha: vol > 0 ? 0.4 : 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('12 AM',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 8)),
                Text('12 PM',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 8)),
                Text('12 AM',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 8)),
              ],
            ),
          ],
        ),
      );

  bool _hourInRange(int h, int start, int end) {
    if (start <= end) return h >= start && h < end;
    return h >= start || h < end;
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
                'Schedule automatic volume changes throughout the day. Great for keeping things quiet at night and comfortable during the day.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
