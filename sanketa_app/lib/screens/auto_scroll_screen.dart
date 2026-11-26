import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class AutoScrollScreen extends StatefulWidget {
  const AutoScrollScreen({super.key});

  @override
  State<AutoScrollScreen> createState() => _AutoScrollScreenState();
}

class _AutoScrollScreenState extends State<AutoScrollScreen> {
  bool _running = false;
  int _speedIndex = 1;
  int _directionIndex = 0;
  int _pauseMs = 0;
  Timer? _timer;
  int _elapsed = 0;

  static const _speeds = [
    ('Slow', 3000, Icons.speed),
    ('Medium', 1500, Icons.speed),
    ('Fast', 800, Icons.speed),
    ('Turbo', 400, Icons.flash_on),
  ];

  static const _directions = [
    ('Down', Icons.arrow_downward),
    ('Up', Icons.arrow_upward),
    ('Right', Icons.arrow_forward),
    ('Left', Icons.arrow_back),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/auto_scroll_settings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _speedIndex = j['speed'] as int? ?? 1;
        _directionIndex = j['direction'] as int? ?? 0;
        _pauseMs = j['pause'] as int? ?? 0;
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'speed': _speedIndex,
      'direction': _directionIndex,
      'pause': _pauseMs,
    }));
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      _timer = null;
      setState(() => _running = false);
    } else {
      _elapsed = 0;
      _timer = Timer.periodic(
        Duration(milliseconds: _speeds[_speedIndex].$2),
        (_) => setState(() => _elapsed++),
      );
      setState(() => _running = true);
    }
  }

  String _formatElapsed() {
    final secs = (_elapsed * _speeds[_speedIndex].$2 / 1000).round();
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Auto Scroll',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _statusCard(),
          const SizedBox(height: AppSpacing.md),
          _controlButton(),
          const SizedBox(height: AppSpacing.md),
          if (!_running) ...[
            _speedSelector(),
            const SizedBox(height: AppSpacing.md),
            _directionSelector(),
            const SizedBox(height: AppSpacing.md),
            _pauseControl(),
            const SizedBox(height: AppSpacing.md),
          ],
          _presetsSection(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _statusCard() => Container(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_running ? AppColors.signalEmerald : AppColors.surfaceContainerLow).withValues(alpha: _running ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(_running ? AppColors.signalEmerald : AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Icon(
          _running ? Icons.play_circle_filled : Icons.pause_circle_outline,
          size: 48,
          color: hex(_running ? AppColors.signalEmerald : AppColors.outline),
        ),
        const SizedBox(height: 8),
        Text(
          _running ? 'Scrolling ${_directions[_directionIndex].$1}' : 'Stopped',
          style: gfont(AppType.bodyMd,
              color: hex(_running ? AppColors.signalEmerald : AppColors.onSurface), weight: FontWeight.w600),
        ),
        if (_running) ...[
          const SizedBox(height: 4),
          Text('${_speeds[_speedIndex].$1} · ${_formatElapsed()}',
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 11)),
        ],
      ],
    ),
  );

  Widget _controlButton() => GestureDetector(
    onTap: _toggle,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: hex(_running ? AppColors.error : AppColors.signalEmerald).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(_running ? AppColors.error : AppColors.signalEmerald).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _running ? Icons.stop : Icons.play_arrow,
            size: 20,
            color: hex(_running ? AppColors.error : AppColors.signalEmerald),
          ),
          const SizedBox(width: 8),
          Text(
            _running ? 'Stop Scrolling' : 'Start Auto Scroll',
            style: gfont(AppType.bodyMd,
                color: hex(_running ? AppColors.error : AppColors.signalEmerald), weight: FontWeight.w600, size: 14),
          ),
        ],
      ),
    ),
  );

  Widget _speedSelector() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Speed', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_speeds.length, (i) {
            final active = i == _speedIndex;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _speeds.length - 1 ? 6 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _speedIndex = i);
                    _save();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(_speeds[i].$1,
                          style: gfont(AppType.bodySm,
                              color: hex(active ? AppColors.primary : AppColors.onSurface),
                              weight: active ? FontWeight.w600 : FontWeight.w400, size: 11)),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );

  Widget _directionSelector() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Direction', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(_directions.length, (i) {
            final active = i == _directionIndex;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < _directions.length - 1 ? 6 : 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _directionIndex = i);
                    _save();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.tertiary : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(active ? AppColors.tertiary : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_directions[i].$2, size: 14,
                            color: hex(active ? AppColors.tertiary : AppColors.outline)),
                        const SizedBox(width: 4),
                        Text(_directions[i].$1,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.tertiary : AppColors.onSurface),
                                weight: active ? FontWeight.w600 : FontWeight.w400, size: 10)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  );

  Widget _pauseControl() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Pause Between Scrolls',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('${_pauseMs}ms',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: hex(AppColors.alertAmber),
            inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            thumbColor: hex(AppColors.alertAmber),
            trackHeight: 4,
          ),
          child: Slider(
            value: _pauseMs.toDouble(),
            min: 0,
            max: 2000,
            divisions: 20,
            onChanged: (v) => setState(() => _pauseMs = v.round()),
            onChangeEnd: (_) => _save(),
          ),
        ),
      ],
    ),
  );

  Widget _presetsSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Presets', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _presetChip('Credits Roll', 0, 0, 0),
        const SizedBox(height: 4),
        _presetChip('News Ticker', 3, 2, 500),
        const SizedBox(height: 4),
        _presetChip('Photo Slideshow', 1, 2, 1500),
      ],
    ),
  );

  Widget _presetChip(String name, int speed, int dir, int pause) => GestureDetector(
    onTap: () {
      setState(() {
        _speedIndex = speed;
        _directionIndex = dir;
        _pauseMs = pause;
      });
      _save();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hex(AppColors.primary).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, size: 14, color: hex(AppColors.primary)),
          const SizedBox(width: 8),
          Text(name,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 12)),
          const Spacer(),
          Text('${_speeds[speed].$1} · ${_directions[dir].$1}',
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
        ],
      ),
    ),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.tertiary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Automatically scroll through content on your TV. Great for credits, news tickers, and photo slideshows. Sends D-pad key events at the chosen interval.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
