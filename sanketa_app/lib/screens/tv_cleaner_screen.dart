import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvCleanerScreen extends StatefulWidget {
  const TvCleanerScreen({super.key});

  @override
  State<TvCleanerScreen> createState() => _TvCleanerScreenState();
}

class _TvCleanerScreenState extends State<TvCleanerScreen> {
  bool _cleaning = false;
  int _secondsLeft = 0;
  int _selectedDuration = 60;
  Timer? _timer;

  static const _durations = [30, 60, 120, 180, 300];
  static const _tips = [
    'Use a soft microfiber cloth — no paper towels',
    'Spray cleaner on the cloth, not the screen',
    'Wipe gently in one direction, top to bottom',
    'Never use ammonia or alcohol-based cleaners',
    'Wait for the screen to cool before cleaning',
    'Clean the bezel and remote while waiting',
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCleaning() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() {
      _cleaning = true;
      _secondsLeft = _selectedDuration;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _stopCleaning();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _stopCleaning() {
    _timer?.cancel();
    setState(() {
      _cleaning = false;
      _secondsLeft = 0;
    });
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Cleaning complete! Screen brightness restored.'),
        duration: Duration(seconds: 2),
      ));
  }

  String _fmtTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Cleaner',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_cleaning) _cleaningView() else ...[
            _heroCard(),
            const SizedBox(height: AppSpacing.md),
            _durationPicker(),
            const SizedBox(height: AppSpacing.md),
            _startButton(),
            const SizedBox(height: AppSpacing.md),
            _tipsSection(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.cleaning_services, size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Screen Cleaning Mode',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Dims your TV screen and starts a timer so you can safely clean',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _cleaningView() => Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.cleaning_services, size: 60, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 16),
            Text('Cleaning in Progress',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald), weight: FontWeight.w600, size: 16)),
            const SizedBox(height: 20),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: 1 - (_secondsLeft / _selectedDuration),
                      strokeWidth: 8,
                      backgroundColor: hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                      color: hex(AppColors.signalEmerald),
                    ),
                  ),
                  Text(_fmtTime(_secondsLeft),
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.signalEmerald), size: 28, weight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('TV screen is dimmed. Clean gently!',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _stopCleaning,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text('Stop & Restore',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.error), weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );

  Widget _durationPicker() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cleaning Duration',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) {
                final active = d == _selectedDuration;
                final label = d < 60 ? '${d}s' : '${d ~/ 60}m';
                return GestureDetector(
                  onTap: () => setState(() => _selectedDuration = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.signalEmerald : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: hex(active ? AppColors.signalEmerald : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Text(label,
                        style: gfont(AppType.bodyMd,
                            color: hex(active ? AppColors.signalEmerald : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400, size: 12)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _startButton() => GestureDetector(
        onTap: _startCleaning,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cleaning_services, size: 18, color: hex(AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text('Start Cleaning Mode',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.signalEmerald), weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _tipsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cleaning Tips',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, size: 14,
                        color: hex(AppColors.signalEmerald)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface), size: 11)),
                    ),
                  ],
                ),
              )),
        ],
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
                'Dims your TV screen for safe cleaning. The timer helps track your cleaning time. Screen brightness is restored when done.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
