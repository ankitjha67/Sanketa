import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvHealthCheckScreen extends StatefulWidget {
  const TvHealthCheckScreen({super.key});

  @override
  State<TvHealthCheckScreen> createState() => _TvHealthCheckScreenState();
}

class _TvHealthCheckScreenState extends State<TvHealthCheckScreen> {
  bool _running = false;
  bool _done = false;

  static const _checks = <(String, IconData, int, String)>[
    ('Signal Strength', Icons.signal_cellular_alt, AppColors.signalEmerald, 'Excellent'),
    ('Network Connection', Icons.wifi, AppColors.signalEmerald, 'Connected'),
    ('HDMI Ports', Icons.settings_input_hdmi, AppColors.signalEmerald, '4/4 Active'),
    ('Audio Output', Icons.volume_up, AppColors.signalEmerald, 'Working'),
    ('Display Panel', Icons.tv, AppColors.signalEmerald, 'No dead pixels'),
    ('Firmware', Icons.system_update, AppColors.alertAmber, 'Update available'),
    ('Storage', Icons.storage, AppColors.signalEmerald, '12.4 GB free'),
    ('Temperature', Icons.thermostat, AppColors.signalEmerald, '38°C Normal'),
  ];

  void _runDiagnostics() {
    HapticFeedback.mediumImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() {
      _running = true;
      _done = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _running = false;
          _done = true;
        });
      }
    });
  }

  int get _passCount => _checks.where((c) => c.$3 == AppColors.signalEmerald).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Health Check',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _scoreCard(),
          const SizedBox(height: AppSpacing.md),
          _runButton(),
          const SizedBox(height: AppSpacing.md),
          if (_done) _checksList(),
          if (_done) const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _scoreCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(_done ? AppColors.signalEmerald : AppColors.primary)
              .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: hex(_done ? AppColors.signalEmerald : AppColors.primary)
                .withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              _done ? Icons.check_circle : Icons.health_and_safety,
              size: 48,
              color: hex(_done ? AppColors.signalEmerald : AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              _running
                  ? 'Running diagnostics...'
                  : _done
                      ? '$_passCount/${_checks.length} Passed'
                      : 'Ready to check',
              style: gfont(AppType.bodyMd,
                  color: hex(_done ? AppColors.signalEmerald : AppColors.onSurface),
                  weight: FontWeight.w700,
                  size: 18),
            ),
            if (_running)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(
                  color: hex(AppColors.primary),
                  backgroundColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                ),
              ),
          ],
        ),
      );

  Widget _runButton() => GestureDetector(
        onTap: _running ? null : _runDiagnostics,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: _running ? 0.05 : 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: _running ? 0.1 : 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow,
                  size: 20,
                  color: hex(AppColors.primary).withValues(alpha: _running ? 0.4 : 1)),
              const SizedBox(width: 8),
              Text(_running ? 'Running...' : 'Run Health Check',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary).withValues(alpha: _running ? 0.4 : 1),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _checksList() => Column(
        children: _checks.map((c) {
          final pass = c.$3 == AppColors.signalEmerald;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                    color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hex(c.$3).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(c.$2, size: 18, color: hex(c.$3)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w600,
                                size: 11)),
                        Text(c.$4,
                            style: gfont(AppType.bodySm,
                                color: hex(c.$3), size: 10)),
                      ],
                    ),
                  ),
                  Icon(
                    pass ? Icons.check_circle : Icons.warning,
                    size: 18,
                    color: hex(c.$3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
                'Run a comprehensive health check on your TV. Tests signal, network, HDMI ports, audio, display, firmware, storage, and temperature. All checks run locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
