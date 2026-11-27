import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class RemoteFinderScreen extends StatefulWidget {
  const RemoteFinderScreen({super.key});

  @override
  State<RemoteFinderScreen> createState() => _RemoteFinderScreenState();
}

class _RemoteFinderScreenState extends State<RemoteFinderScreen> {
  bool _ringing = false;
  int _strength = 0;
  Timer? _timer;

  static const _tips = <(String, IconData)>[
    ('Check between couch cushions', Icons.weekend),
    ('Look under blankets and pillows', Icons.bed),
    ('Try the coffee table or side table', Icons.table_bar),
    ('Check the kitchen counter', Icons.countertops),
    ('Look in the bedroom', Icons.bedroom_parent),
    ('Try the bathroom', Icons.bathtub),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ring() {
    HapticFeedback.heavyImpact();
    setState(() {
      _ringing = true;
      _strength = 0;
    });
    var step = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      step++;
      if (step <= 10) {
        HapticFeedback.lightImpact();
        setState(() => _strength = (step * 10).clamp(0, 100));
      } else {
        t.cancel();
        setState(() => _ringing = false);
      }
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() {
      _ringing = false;
      _strength = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Remote Finder',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _radarCard(),
          const SizedBox(height: AppSpacing.md),
          _ringButton(),
          const SizedBox(height: AppSpacing.md),
          _signalBar(),
          const SizedBox(height: AppSpacing.md),
          _tipsSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _radarCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(_ringing ? AppColors.signalEmerald : AppColors.surfaceContainerHigh)
              .withValues(alpha: _ringing ? 0.08 : 1),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: hex(_ringing ? AppColors.signalEmerald : AppColors.outlineVariant)
                .withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: _ringing ? null : 0,
                      strokeWidth: 4,
                      color: hex(AppColors.signalEmerald),
                      backgroundColor:
                          hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                    ),
                  ),
                  Icon(
                    _ringing ? Icons.volume_up : Icons.settings_remote,
                    size: 36,
                    color: hex(_ringing
                        ? AppColors.signalEmerald
                        : AppColors.outline),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _ringing ? 'Ringing remote...' : 'Tap Ring to find your remote',
              style: gfont(AppType.bodyMd,
                  color: hex(_ringing ? AppColors.signalEmerald : AppColors.outline),
                  weight: FontWeight.w600),
            ),
            if (_ringing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('The remote will beep and flash its LED',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ),
          ],
        ),
      );

  Widget _ringButton() => GestureDetector(
        onTap: _ringing ? _stop : _ring,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_ringing ? AppColors.error : AppColors.signalEmerald)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_ringing ? AppColors.error : AppColors.signalEmerald)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_ringing ? Icons.stop : Icons.notifications_active,
                  size: 20,
                  color: hex(_ringing ? AppColors.error : AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text(_ringing ? 'Stop Ringing' : 'Ring Remote',
                  style: gfont(AppType.bodyMd,
                      color: hex(_ringing ? AppColors.error : AppColors.signalEmerald),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _signalBar() => Container(
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
            Row(
              children: [
                Text('Signal Strength',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
                const Spacer(),
                Text('$_strength%',
                    style: gfont(AppType.bodySm,
                        color: hex(_strength > 70
                            ? AppColors.signalEmerald
                            : _strength > 30
                                ? AppColors.alertAmber
                                : AppColors.error),
                        weight: FontWeight.w700,
                        size: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _strength / 100,
                minHeight: 8,
                color: hex(_strength > 70
                    ? AppColors.signalEmerald
                    : _strength > 30
                        ? AppColors.alertAmber
                        : AppColors.error),
                backgroundColor:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _strength == 0
                  ? 'Start ringing to detect signal'
                  : _strength > 70
                      ? 'Getting close — keep looking nearby'
                      : _strength > 30
                          ? 'Moderate signal — check nearby rooms'
                          : 'Weak signal — may be far away',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10),
            ),
          ],
        ),
      );

  Widget _tipsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where to Look',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                        color: hex(AppColors.outlineVariant)
                            .withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(t.$2,
                          size: 18, color: hex(AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(t.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 11)),
                      ),
                    ],
                  ),
                ),
              )),
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
                'Find your lost TV remote. Tap Ring to make the remote beep and flash. Signal strength shows proximity. For remotes without built-in speakers, use the tips below.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
