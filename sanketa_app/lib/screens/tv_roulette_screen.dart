import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvRouletteScreen extends StatefulWidget {
  const TvRouletteScreen({super.key});

  @override
  State<TvRouletteScreen> createState() => _TvRouletteScreenState();
}

class _TvRouletteScreenState extends State<TvRouletteScreen>
    with SingleTickerProviderStateMixin {
  bool _spinning = false;
  String _result = '';
  int _resultIndex = -1;
  late AnimationController _spinCtrl;
  final _rng = Random();

  static const _modes = ['Channel', 'App', 'Input'];
  int _modeIndex = 0;

  static const _channels = [
    'Ch 1', 'Ch 2', 'Ch 3', 'Ch 5', 'Ch 7',
    'Ch 9', 'Ch 11', 'Ch 13', 'Ch 20', 'Ch 25',
    'Ch 30', 'Ch 42', 'Ch 50', 'Ch 75', 'Ch 100',
  ];

  static const _apps = [
    'Netflix', 'YouTube', 'Prime Video', 'Disney+', 'Hulu',
    'HBO Max', 'Apple TV+', 'Peacock', 'Paramount+', 'Tubi',
  ];

  static const _inputs = [
    'HDMI 1', 'HDMI 2', 'HDMI 3', 'AV', 'Component',
  ];

  List<String> get _currentPool {
    switch (_modeIndex) {
      case 0:
        return _channels;
      case 1:
        return _apps;
      case 2:
        return _inputs;
      default:
        return _channels;
    }
  }

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _result = '';
      _resultIndex = -1;
    });
    HapticFeedback.mediumImpact();
    _spinCtrl.forward(from: 0);

    final pool = _currentPool;
    int ticks = 0;
    final totalTicks = 15 + _rng.nextInt(10);

    void tick() {
      if (!mounted) return;
      ticks++;
      setState(() {
        _resultIndex = _rng.nextInt(pool.length);
        _result = pool[_resultIndex];
      });
      HapticFeedback.selectionClick();

      if (ticks < totalTicks) {
        final delay = 60 + (ticks * 20);
        Future.delayed(Duration(milliseconds: delay), tick);
      } else {
        setState(() => _spinning = false);
        HapticFeedback.heavyImpact();
      }
    }

    Future.delayed(const Duration(milliseconds: 100), tick);
  }

  void _goToResult() {
    if (_result.isEmpty) return;
    final rc = RemoteScope.of(context);
    if (_modeIndex == 1) {
      rc.launch(_result);
    } else {
      rc.key(core.Key.ok);
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Switching to $_result'),
        duration: const Duration(seconds: 2),
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
        title: Text('TV Roulette',
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
          _modeSelector(),
          const SizedBox(height: AppSpacing.lg),
          _resultDisplay(),
          const SizedBox(height: AppSpacing.lg),
          _spinButton(),
          if (_result.isNotEmpty && !_spinning) ...[
            const SizedBox(height: AppSpacing.md),
            _goButton(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _poolPreview(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.casino, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text("Can't Decide?",
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Spin the wheel and let fate pick what to watch',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _modeSelector() => SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _modes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == _modeIndex;
            return GestureDetector(
              onTap: () => setState(() {
                _modeIndex = i;
                _result = '';
                _resultIndex = -1;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Text(_modes[i],
                      style: gfont(AppType.bodyMd,
                          color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 12)),
                ),
              ),
            );
          },
        ),
      );

  Widget _resultDisplay() => AnimatedBuilder(
        animation: _spinCtrl,
        builder: (_, __) {
          final glow = _spinning ? (0.1 + _spinCtrl.value * 0.4) : 0.0;
          return Container(
            height: 120,
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerLow),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: hex(_spinning ? AppColors.alertAmber : AppColors.outlineVariant)
                    .withValues(alpha: _spinning ? 0.5 + glow : 0.2),
                width: _spinning ? 2 : 1,
              ),
            ),
            child: Center(
              child: _result.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tv,
                            size: 32,
                            color: hex(AppColors.outline).withValues(alpha: 0.3)),
                        const SizedBox(height: 6),
                        Text('Spin to pick',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 11)),
                      ],
                    )
                  : Text(_result,
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.onSurface),
                          size: 28,
                          weight: FontWeight.w700)),
            ),
          );
        },
      );

  Widget _spinButton() => GestureDetector(
        onTap: _spin,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_spinning ? AppColors.outline : AppColors.alertAmber)
                .withValues(alpha: _spinning ? 0.1 : 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_spinning ? AppColors.outline : AppColors.alertAmber)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_spinning ? Icons.hourglass_top : Icons.casino,
                  size: 20,
                  color: hex(_spinning ? AppColors.outline : AppColors.alertAmber)),
              const SizedBox(width: 8),
              Text(_spinning ? 'Spinning...' : 'Spin!',
                  style: gfont(AppType.bodyMd,
                      color: hex(_spinning ? AppColors.outline : AppColors.alertAmber),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _goButton() => GestureDetector(
        onTap: _goToResult,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow,
                  size: 20, color: hex(AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text('Go to $_result',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.signalEmerald),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _poolPreview() => Container(
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
            Text('${_modes[_modeIndex]} Pool (${_currentPool.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _currentPool.asMap().entries.map((e) {
                final highlight = e.key == _resultIndex && !_spinning;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hex(highlight ? AppColors.signalEmerald : AppColors.surfaceContainerHigh)
                        .withValues(alpha: highlight ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(highlight ? AppColors.signalEmerald : AppColors.outlineVariant)
                          .withValues(alpha: highlight ? 0.5 : 0.2),
                    ),
                  ),
                  child: Text(e.value,
                      style: gfont(AppType.bodySm,
                          color: hex(highlight ? AppColors.signalEmerald : AppColors.onSurface),
                          weight: highlight ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                );
              }).toList(),
            ),
          ],
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
                "Can't decide what to watch? Spin the roulette for a random pick from channels, apps, or inputs. Tap Go to switch instantly.",
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
