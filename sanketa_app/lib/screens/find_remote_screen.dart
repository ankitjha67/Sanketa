import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class FindRemoteScreen extends StatefulWidget {
  const FindRemoteScreen({super.key});

  @override
  State<FindRemoteScreen> createState() => _FindRemoteScreenState();
}

class _FindRemoteScreenState extends State<FindRemoteScreen>
    with SingleTickerProviderStateMixin {
  bool _ringing = false;
  int _ringCount = 0;
  int _durationIndex = 1;
  late AnimationController _pulseCtrl;

  static const _durations = [
    ('5 sec', 5),
    ('15 sec', 15),
    ('30 sec', 30),
    ('1 min', 60),
  ];

  static const _history = [
    ('Living Room TV', '2 min ago', true),
    ('Bedroom TV', '1 hour ago', false),
    ('Living Room TV', 'Yesterday', true),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startRinging() {
    if (_ringing) return;
    setState(() {
      _ringing = true;
      _ringCount++;
    });
    HapticFeedback.heavyImpact();
    _pulseCtrl.repeat(reverse: true);

    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);

    final seconds = _durations[_durationIndex].$2;
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) _stopRinging();
    });
  }

  void _stopRinging() {
    setState(() => _ringing = false);
    _pulseCtrl.stop();
    _pulseCtrl.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Find Remote',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroSection(),
          const SizedBox(height: AppSpacing.lg),
          _durationSelector(),
          const SizedBox(height: AppSpacing.lg),
          _ringButton(),
          const SizedBox(height: AppSpacing.lg),
          _statsRow(),
          const SizedBox(height: AppSpacing.md),
          _historySection(),
          const SizedBox(height: AppSpacing.lg),
          _tipsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroSection() => AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          final scale = _ringing ? 1.0 + _pulseCtrl.value * 0.08 : 1.0;
          final glowAlpha = _ringing ? 0.1 + _pulseCtrl.value * 0.2 : 0.08;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: hex(_ringing ? AppColors.error : AppColors.primary)
                  .withValues(alpha: glowAlpha),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: hex(_ringing ? AppColors.error : AppColors.primary)
                    .withValues(alpha: _ringing ? 0.4 : 0.2),
                width: _ringing ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Transform.scale(
                  scale: scale,
                  child: Icon(
                    _ringing ? Icons.volume_up : Icons.search,
                    size: 56,
                    color: hex(_ringing ? AppColors.error : AppColors.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _ringing ? 'Ringing TV Speaker...' : 'Lost Your Remote?',
                  style: gfont(AppType.bodyMd,
                      color: hex(_ringing ? AppColors.error : AppColors.primary),
                      weight: FontWeight.w600,
                      size: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _ringing
                      ? 'The TV will play a sound. Listen and follow it!'
                      : 'Make your TV play a loud sound to locate the physical remote nearby',
                  textAlign: TextAlign.center,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11),
                ),
              ],
            ),
          );
        },
      );

  Widget _durationSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ring Duration',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _durations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = i == _durationIndex;
                return GestureDetector(
                  onTap: _ringing ? null : () => setState(() => _durationIndex = i),
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
                      child: Text(_durations[i].$1,
                          style: gfont(AppType.bodySm,
                              color: hex(active ? AppColors.primary : AppColors.onSurface),
                              weight: active ? FontWeight.w600 : FontWeight.w400,
                              size: 12)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _ringButton() => GestureDetector(
        onTap: _ringing ? _stopRinging : _startRinging,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: hex(_ringing ? AppColors.error : AppColors.signalEmerald)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_ringing ? AppColors.error : AppColors.signalEmerald)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _ringing ? Icons.stop : Icons.notifications_active,
                size: 22,
                color: hex(_ringing ? AppColors.error : AppColors.signalEmerald),
              ),
              const SizedBox(width: 10),
              Text(
                _ringing ? 'Stop Ringing' : 'Ring TV Speaker',
                style: gfont(AppType.bodyMd,
                    color: hex(_ringing ? AppColors.error : AppColors.signalEmerald),
                    weight: FontWeight.w700,
                    size: 15),
              ),
            ],
          ),
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(child: _statCard('Times Used', '$_ringCount', Icons.history)),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard(
                  'Duration', _durations[_durationIndex].$1, Icons.timer)),
          const SizedBox(width: 8),
          Expanded(
              child: _statCard(
                  'Status', _ringing ? 'Ringing' : 'Ready', Icons.circle)),
        ],
      );

  Widget _statCard(String label, String value, IconData icon) => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: hex(AppColors.primary)),
            const SizedBox(height: 4),
            Text(value,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w700,
                    size: 13)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _historySection() => Container(
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
            Text('Recent Finds',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._history.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        h.$3 ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: hex(h.$3 ? AppColors.signalEmerald : AppColors.error),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(h.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 11)),
                      ),
                      Text(h.$2,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                    ],
                  ),
                )),
          ],
        ),
      );

  Widget _tipsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, size: 14, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 6),
                Text('Finding Tips',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.alertAmber),
                        weight: FontWeight.w600,
                        size: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ...[
              'Check between couch cushions first',
              'Look under blankets and pillows',
              'The TV speaker sound helps narrow the area',
              'Use a longer ring duration in larger rooms',
            ].map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('  •  ',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                      Expanded(
                        child: Text(tip,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 10)),
                      ),
                    ],
                  ),
                )),
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
                "Can't find your physical remote? Make the TV play a loud sound through its speakers so you can follow the noise to find the remote nearby.",
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
