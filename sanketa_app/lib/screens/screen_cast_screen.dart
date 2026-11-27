import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ScreenCastScreen extends StatefulWidget {
  const ScreenCastScreen({super.key});

  @override
  State<ScreenCastScreen> createState() => _ScreenCastScreenState();
}

class _ScreenCastScreenState extends State<ScreenCastScreen> {
  int _protocolIndex = 0;
  int _resolutionIndex = 1;
  bool _orientationLock = false;
  bool _audioRoute = true;
  bool _casting = false;
  int _latencyMs = 0;

  static const _protocols = [
    ('Miracast', Icons.cast, AppColors.primary),
    ('Chromecast', Icons.cast_connected, AppColors.secondary),
    ('AirPlay', Icons.airplay, AppColors.tertiary),
  ];

  static const _resolutions = ['720p', '1080p', '4K'];

  void _toggleCasting() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
    setState(() {
      _casting = !_casting;
      _latencyMs = _casting ? 12 : 0;
    });
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(_casting ? 'Casting started' : 'Casting stopped'),
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
        title: Text('Screen Cast',
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
          _statusCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('Protocol',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _protocolSelector(),
          const SizedBox(height: AppSpacing.lg),
          Text('Resolution',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _resolutionPicker(),
          const SizedBox(height: AppSpacing.lg),
          _toggleRow('Orientation Lock', Icons.screen_lock_rotation,
              _orientationLock, (v) => setState(() => _orientationLock = v)),
          const SizedBox(height: AppSpacing.sm),
          _toggleRow('Route Audio to TV', Icons.volume_up, _audioRoute,
              (v) => setState(() => _audioRoute = v)),
          const SizedBox(height: AppSpacing.lg),
          _castButton(),
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
          border:
              Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.cast, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('Cast Your Screen',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Mirror your phone display to the TV wirelessly',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statusCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hex(_casting
                    ? AppColors.signalEmerald
                    : AppColors.outlineVariant),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_casting ? 'Casting Active' : 'Not Casting',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(
                    _casting
                        ? '${_protocols[_protocolIndex].$1} · ${_resolutions[_resolutionIndex]}'
                        : 'Select protocol and tap Start',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 11),
                  ),
                ],
              ),
            ),
            if (_casting)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('${_latencyMs}ms',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
          ],
        ),
      );

  Widget _protocolSelector() => Row(
        children: _protocols.asMap().entries.map((e) {
          final p = e.value;
          final active = e.key == _protocolIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: e.key == 0 ? 0 : 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _protocolIndex = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hex(active ? p.$3 : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active ? p.$3 : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(p.$2, size: 22, color: hex(p.$3)),
                      const SizedBox(height: 4),
                      Text(p.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 10)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _resolutionPicker() => Row(
        children: _resolutions.asMap().entries.map((e) {
          final active = e.key == _resolutionIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: e.key == 0 ? 0 : 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _resolutionIndex = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.12 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Center(
                    child: Text(e.value,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            weight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            size: 12)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _toggleRow(
          String label, IconData icon, bool value, ValueChanged<bool> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: hex(AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface), size: 13)),
            ),
            Switch(
              value: value,
              onChanged: (v) {
                onChanged(v);
                HapticFeedback.selectionClick();
              },
              activeColor: hex(AppColors.primary),
            ),
          ],
        ),
      );

  Widget _castButton() => GestureDetector(
        onTap: _toggleCasting,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_casting ? AppColors.error : AppColors.signalEmerald)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_casting ? AppColors.error : AppColors.signalEmerald)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_casting ? Icons.stop : Icons.play_arrow,
                  size: 20,
                  color:
                      hex(_casting ? AppColors.error : AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text(_casting ? 'Stop Casting' : 'Start Casting',
                  style: gfont(AppType.bodyMd,
                      color: hex(
                          _casting ? AppColors.error : AppColors.signalEmerald),
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
          border:
              Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cast your phone screen to the TV via Miracast, Chromecast, or AirPlay. Choose resolution and toggle audio routing.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
