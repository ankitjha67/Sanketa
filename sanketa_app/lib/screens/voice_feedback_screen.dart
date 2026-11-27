import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class VoiceFeedbackScreen extends StatefulWidget {
  const VoiceFeedbackScreen({super.key});

  @override
  State<VoiceFeedbackScreen> createState() => _VoiceFeedbackScreenState();
}

class _VoiceFeedbackScreenState extends State<VoiceFeedbackScreen> {
  bool _loading = true;
  bool _enabled = true;
  int _voiceIdx = 0;
  double _volume = 70;
  double _speed = 1.0;

  static const _voices = <(String, IconData, int)>[
    ('Default', Icons.record_voice_over, AppColors.primary),
    ('Soft', Icons.spa, AppColors.signalEmerald),
    ('Clear', Icons.surround_sound, AppColors.alertAmber),
    ('Deep', Icons.graphic_eq, AppColors.secondary),
  ];

  static const _events = <(String, IconData, String, int)>[
    ('Key Press', Icons.touch_app, '"OK pressed"', AppColors.primary),
    ('Volume Change', Icons.volume_up, '"Volume 50"', AppColors.signalEmerald),
    ('Channel Switch', Icons.tv, '"Channel 7"', AppColors.alertAmber),
    ('Power', Icons.power_settings_new, '"TV off"', AppColors.error),
    ('Input Switch', Icons.input, '"HDMI 2"', AppColors.secondary),
    ('Menu Open', Icons.menu, '"Menu opened"', AppColors.tertiary),
  ];

  final _disabledEvents = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/voice_feedback.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _enabled = j['enabled'] as bool? ?? true;
        _voiceIdx = j['voiceIdx'] as int? ?? 0;
        _volume = (j['volume'] as num?)?.toDouble() ?? 70;
        _speed = (j['speed'] as num?)?.toDouble() ?? 1.0;
        final disabled = j['disabledEvents'] as List?;
        if (disabled != null) {
          _disabledEvents
            ..clear()
            ..addAll(disabled.cast<int>());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'enabled': _enabled,
      'voiceIdx': _voiceIdx,
      'volume': _volume,
      'speed': _speed,
      'disabledEvents': _disabledEvents.toList(),
    }));
  }

  void _testVoice() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Testing: "${_voices[_voiceIdx].$1}" voice'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _toggleEvent(int idx) {
    setState(() {
      if (_disabledEvents.contains(idx)) {
        _disabledEvents.remove(idx);
      } else {
        _disabledEvents.add(idx);
      }
    });
    HapticFeedback.selectionClick();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final activeEvents = _events.length - _disabledEvents.length;
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Voice Feedback',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _heroCard(),
                const SizedBox(height: AppSpacing.md),
                _enableToggle(),
                const SizedBox(height: AppSpacing.md),
                _statsRow(activeEvents),
                const SizedBox(height: AppSpacing.lg),
                Text('Voice Style',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: AppSpacing.sm),
                _voiceChips(),
                const SizedBox(height: AppSpacing.md),
                _volumeSlider(),
                const SizedBox(height: AppSpacing.md),
                _speedSlider(),
                const SizedBox(height: AppSpacing.md),
                _testButton(),
                const SizedBox(height: AppSpacing.lg),
                Text('Announce Events',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                const SizedBox(height: AppSpacing.sm),
                ..._events.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _eventCard(e.key, e.value),
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
            Icon(Icons.record_voice_over,
                size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Audio Announcements',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Hear spoken feedback for TV remote actions',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _enableToggle() => GestureDetector(
        onTap: () {
          setState(() => _enabled = !_enabled);
          HapticFeedback.selectionClick();
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_enabled
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _enabled ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_enabled
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: _enabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.volume_up,
                  size: 22,
                  color: hex(
                      _enabled ? AppColors.signalEmerald : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Voice Feedback',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex(_enabled
                          ? AppColors.signalEmerald
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_enabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(_enabled
                            ? AppColors.signalEmerald
                            : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _statsRow(int activeEvents) => Row(
        children: [
          Expanded(
              child: _statBadge('Events', '$activeEvents/${_events.length}',
                  AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Voice', _voices[_voiceIdx].$1, AppColors.secondary)),
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
                    color: hex(c), size: 16, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _voiceChips() => Row(
        children: _voices.asMap().entries.map((e) {
          final active = e.key == _voiceIdx;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: e.key == 0 ? 0 : 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _voiceIdx = e.key);
                  HapticFeedback.selectionClick();
                  _save();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(e.value.$3)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(e.value.$3)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(e.value.$2,
                          size: 18, color: hex(e.value.$3)),
                      const SizedBox(height: 2),
                      Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(e.value.$3),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 9)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _volumeSlider() => Container(
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
            Row(
              children: [
                Text('Volume',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
                const Spacer(),
                Text('${_volume.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _volume,
              min: 10,
              max: 100,
              activeColor: hex(AppColors.primary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3),
              onChanged: (v) {
                setState(() => _volume = v);
                _save();
              },
            ),
          ],
        ),
      );

  Widget _speedSlider() => Container(
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
            Row(
              children: [
                Text('Speed',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
                const Spacer(),
                Text('${_speed.toStringAsFixed(1)}x',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.secondary),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _speed,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              activeColor: hex(AppColors.secondary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3),
              onChanged: (v) {
                setState(() => _speed = v);
                _save();
              },
            ),
          ],
        ),
      );

  Widget _testButton() => GestureDetector(
        onTap: _testVoice,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle,
                  size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Test Voice',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _eventCard(int idx, (String, IconData, String, int) event) {
    final active = !_disabledEvents.contains(idx);
    return GestureDetector(
      onTap: () => _toggleEvent(idx),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(active ? event.$4 : AppColors.surfaceContainerLow)
              .withValues(alpha: active ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(active ? event.$4 : AppColors.outlineVariant)
                .withValues(alpha: active ? 0.25 : 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(event.$2,
                size: 20,
                color: hex(active ? event.$4 : AppColors.outline)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text('Announces: ${event.$3}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hex(active
                        ? AppColors.signalEmerald
                        : AppColors.outline)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(active ? 'ON' : 'OFF',
                  style: gfont(AppType.bodySm,
                      color: hex(active
                          ? AppColors.signalEmerald
                          : AppColors.outline),
                      weight: FontWeight.w700,
                      size: 10)),
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
                'Hear spoken feedback when pressing remote buttons. '
                'Choose voice, volume, speed, and which events to announce.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
