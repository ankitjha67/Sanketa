import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class AudioVisualizerScreen extends StatefulWidget {
  const AudioVisualizerScreen({super.key});

  @override
  State<AudioVisualizerScreen> createState() => _AudioVisualizerScreenState();
}

class _AudioVisualizerScreenState extends State<AudioVisualizerScreen> {
  bool _active = false;
  int _styleIdx = 0;
  int _colorIdx = 0;
  double _sensitivity = 60;

  static const _styles = <(String, IconData, int)>[
    ('Bars', Icons.bar_chart, AppColors.primary),
    ('Wave', Icons.waves, AppColors.signalEmerald),
    ('Circle', Icons.circle_outlined, AppColors.alertAmber),
    ('Dots', Icons.blur_circular, AppColors.secondary),
  ];

  static const _colors = <(String, int)>[
    ('Neon Green', AppColors.signalEmerald),
    ('Electric Blue', AppColors.primary),
    ('Sunset Orange', AppColors.alertAmber),
    ('Purple Haze', AppColors.secondary),
    ('Fire Red', AppColors.error),
    ('Cool Teal', AppColors.tertiary),
  ];

  final _rng = Random();
  List<double> _bars = List.filled(16, 0.3);

  void _toggleVisualizer() {
    setState(() => _active = !_active);
    HapticFeedback.mediumImpact();
    if (_active) {
      _animateBars();
      final rc = RemoteScope.of(context);
      rc.key(core.Key.ok);
    }
  }

  void _animateBars() {
    if (!_active || !mounted) return;
    setState(() {
      _bars = List.generate(16, (_) => 0.1 + _rng.nextDouble() * 0.9);
    });
    Future.delayed(const Duration(milliseconds: 150), _animateBars);
  }

  void _castToTv() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Visualizer sent to TV'),
        duration: Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Audio Viz',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _visualizerPreview(),
          const SizedBox(height: AppSpacing.md),
          _toggleButton(),
          const SizedBox(height: AppSpacing.md),
          _styleChips(),
          const SizedBox(height: AppSpacing.md),
          _colorChips(),
          const SizedBox(height: AppSpacing.md),
          _sensitivitySlider(),
          const SizedBox(height: AppSpacing.md),
          _castButton(),
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
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.graphic_eq, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Audio Visualizer',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Display music visualizations on your TV screen',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _visualizerPreview() {
    final c = _colors[_colorIdx].$2;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(c).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _bars.asMap().entries.map((e) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: _active ? e.value : 0.1,
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: hex(c).withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _toggleButton() => GestureDetector(
        onTap: _toggleVisualizer,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_active ? AppColors.error : AppColors.signalEmerald)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(_active ? AppColors.error : AppColors.signalEmerald)
                    .withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_active ? Icons.stop : Icons.play_arrow,
                  size: 22,
                  color: hex(
                      _active ? AppColors.error : AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text(_active ? 'Stop' : 'Start Visualizer',
                  style: gfont(AppType.bodyMd,
                      color: hex(_active
                          ? AppColors.error
                          : AppColors.signalEmerald),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _styleChips() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Style',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w500,
                  size: 12)),
          const SizedBox(height: 6),
          Row(
            children: _styles.asMap().entries.map((e) {
              final active = e.key == _styleIdx;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: e.key == 0 ? 0 : 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _styleIdx = e.key);
                      HapticFeedback.selectionClick();
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
                                  weight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  size: 9)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _colorChips() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Color',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w500,
                  size: 12)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _colors.asMap().entries.map((e) {
                final active = e.key == _colorIdx;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _colorIdx = e.key);
                      HapticFeedback.selectionClick();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: hex(e.value.$2)
                            .withValues(alpha: active ? 0.2 : 0.06),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        border: Border.all(
                          color: hex(e.value.$2)
                              .withValues(alpha: active ? 0.5 : 0.15),
                        ),
                      ),
                      child: Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(e.value.$2),
                              weight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              size: 10)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );

  Widget _sensitivitySlider() => Container(
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
                Text('Sensitivity',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 12)),
                const Spacer(),
                Text('${_sensitivity.round()}%',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.secondary),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            Slider(
              value: _sensitivity,
              min: 10,
              max: 100,
              activeColor: hex(AppColors.secondary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.3),
              onChanged: (v) => setState(() => _sensitivity = v),
            ),
          ],
        ),
      );

  Widget _castButton() => GestureDetector(
        onTap: _castToTv,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cast, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Cast to TV',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
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
                'Music visualizer for your TV. Choose style and colour, '
                'then cast to TV. Simulated bars — no real audio input.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
