import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class InputSwitchScreen extends StatefulWidget {
  const InputSwitchScreen({super.key});

  @override
  State<InputSwitchScreen> createState() => _InputSwitchScreenState();
}

class _InputSwitchScreenState extends State<InputSwitchScreen> {
  int _active = 0;

  static const _inputs = <(String, IconData, String, int)>[
    ('HDMI 1', Icons.settings_input_hdmi, 'Main TV / Cable Box', AppColors.primary),
    ('HDMI 2', Icons.settings_input_hdmi, 'Game Console', AppColors.signalEmerald),
    ('HDMI 3', Icons.settings_input_hdmi, 'Streaming Stick', AppColors.secondary),
    ('HDMI 4', Icons.settings_input_hdmi, 'Blu-ray Player', AppColors.tertiary),
    ('AV', Icons.settings_input_component, 'Composite / Component', AppColors.alertAmber),
    ('USB', Icons.usb, 'Media Player', AppColors.error),
    ('Tuner', Icons.tv, 'Antenna / Cable', AppColors.primary),
    ('Screen Mirror', Icons.cast, 'Wireless Display', AppColors.secondary),
  ];

  void _switchTo(int idx) {
    HapticFeedback.mediumImpact();
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    setState(() => _active = idx);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Switched to ${_inputs[idx].$1}'),
        duration: const Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final cur = _inputs[_active];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Input Switch',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _currentCard(cur),
          const SizedBox(height: AppSpacing.md),
          _inputGrid(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _currentCard((String, IconData, String, int) inp) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(inp.$4).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(inp.$4).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hex(inp.$4).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(inp.$2, size: 28, color: hex(inp.$4)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Input',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                  Text(inp.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(inp.$4),
                          weight: FontWeight.w700,
                          size: 16)),
                  Text(inp.$3,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text('ACTIVE',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.signalEmerald),
                      weight: FontWeight.w700,
                      size: 8)),
            ),
          ],
        ),
      );

  Widget _inputGrid() => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.8,
        children: _inputs.asMap().entries.map((e) {
          final inp = e.value;
          final active = e.key == _active;
          return GestureDetector(
            onTap: () => _switchTo(e.key),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hex(active ? inp.$4 : AppColors.surfaceContainerLow)
                    .withValues(alpha: active ? 0.12 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color: hex(active ? inp.$4 : AppColors.outlineVariant)
                      .withValues(alpha: active ? 0.4 : 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(inp.$2,
                      size: 22,
                      color: hex(active ? inp.$4 : AppColors.outline)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inp.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? inp.$4 : AppColors.onSurface),
                                weight: FontWeight.w600,
                                size: 11)),
                        Text(inp.$3,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 8)),
                      ],
                    ),
                  ),
                  if (active)
                    Icon(Icons.check_circle,
                        size: 16, color: hex(inp.$4)),
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
                'Quickly switch between HDMI, AV, USB, Tuner, and Screen Mirror inputs. Tap any input to switch. The active input is highlighted. All commands sent locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
