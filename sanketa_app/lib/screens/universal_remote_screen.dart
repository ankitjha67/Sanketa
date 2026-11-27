import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class UniversalRemoteScreen extends StatefulWidget {
  const UniversalRemoteScreen({super.key});

  @override
  State<UniversalRemoteScreen> createState() => _UniversalRemoteScreenState();
}

class _UniversalRemoteScreenState extends State<UniversalRemoteScreen> {
  int _device = 0;

  static const _devices = <(String, IconData, int, List<(String, IconData, core.Key)>)>[
    ('TV', Icons.tv, AppColors.primary, [
      ('Power', Icons.power_settings_new, core.Key.power),
      ('Vol +', Icons.volume_up, core.Key.volumeUp),
      ('Vol -', Icons.volume_down, core.Key.volumeDown),
      ('Mute', Icons.volume_off, core.Key.mute),
      ('Ch +', Icons.keyboard_arrow_up, core.Key.up),
      ('Ch -', Icons.keyboard_arrow_down, core.Key.down),
      ('Home', Icons.home, core.Key.home),
      ('Menu', Icons.menu, core.Key.menu),
    ]),
    ('Soundbar', Icons.speaker, AppColors.secondary, [
      ('Power', Icons.power_settings_new, core.Key.power),
      ('Vol +', Icons.volume_up, core.Key.volumeUp),
      ('Vol -', Icons.volume_down, core.Key.volumeDown),
      ('Mute', Icons.volume_off, core.Key.mute),
      ('Bass +', Icons.graphic_eq, core.Key.up),
      ('Bass -', Icons.graphic_eq, core.Key.down),
      ('Input', Icons.input, core.Key.menu),
      ('BT Pair', Icons.bluetooth, core.Key.ok),
    ]),
    ('STB', Icons.settings_input_hdmi, AppColors.signalEmerald, [
      ('Power', Icons.power_settings_new, core.Key.power),
      ('Vol +', Icons.volume_up, core.Key.volumeUp),
      ('Vol -', Icons.volume_down, core.Key.volumeDown),
      ('Guide', Icons.list, core.Key.menu),
      ('Ch +', Icons.keyboard_arrow_up, core.Key.up),
      ('Ch -', Icons.keyboard_arrow_down, core.Key.down),
      ('OK', Icons.check_circle, core.Key.ok),
      ('Back', Icons.arrow_back, core.Key.back),
    ]),
    ('Blu-ray', Icons.album, AppColors.tertiary, [
      ('Power', Icons.power_settings_new, core.Key.power),
      ('Play', Icons.play_arrow, core.Key.ok),
      ('Pause', Icons.pause, core.Key.ok),
      ('Stop', Icons.stop, core.Key.back),
      ('Prev', Icons.skip_previous, core.Key.left),
      ('Next', Icons.skip_next, core.Key.right),
      ('Menu', Icons.menu, core.Key.menu),
      ('Eject', Icons.eject, core.Key.home),
    ]),
    ('Projector', Icons.videocam, AppColors.alertAmber, [
      ('Power', Icons.power_settings_new, core.Key.power),
      ('Input', Icons.input, core.Key.menu),
      ('Zoom +', Icons.zoom_in, core.Key.up),
      ('Zoom -', Icons.zoom_out, core.Key.down),
      ('Focus +', Icons.center_focus_strong, core.Key.right),
      ('Focus -', Icons.center_focus_weak, core.Key.left),
      ('Blank', Icons.visibility_off, core.Key.mute),
      ('Menu', Icons.menu, core.Key.menu),
    ]),
  ];

  void _sendKey(core.Key key) {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.key(key);
  }

  @override
  Widget build(BuildContext context) {
    final dev = _devices[_device];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Universal Remote',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _deviceSelector(),
          const SizedBox(height: AppSpacing.md),
          _deviceHero(dev),
          const SizedBox(height: AppSpacing.md),
          _buttonGrid(dev),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _deviceSelector() => Row(
        children: _devices.asMap().entries.map((e) {
          final d = e.value;
          final active = e.key == _device;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _device = e.key),
              child: Container(
                margin: EdgeInsets.only(right: e.key < 4 ? 4 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active ? d.$3 : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: hex(active ? d.$3 : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(d.$2,
                        size: 18,
                        color: hex(active ? d.$3 : AppColors.outline)),
                    const SizedBox(height: 2),
                    Text(d.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(active ? d.$3 : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 8)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _deviceHero((String, IconData, int, List<(String, IconData, core.Key)>) dev) =>
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(dev.$3).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(dev.$3).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(dev.$2, size: 36, color: hex(dev.$3)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dev.$1,
                    style: gfont(AppType.bodyMd,
                        color: hex(dev.$3),
                        weight: FontWeight.w700,
                        size: 16)),
                Text('${dev.$4.length} buttons',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 11)),
              ],
            ),
          ],
        ),
      );

  Widget _buttonGrid(
          (String, IconData, int, List<(String, IconData, core.Key)>) dev) =>
      GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
        children: dev.$4.map((btn) {
          return GestureDetector(
            onTap: () => _sendKey(btn.$3),
            child: Container(
              decoration: BoxDecoration(
                color: hex(dev.$3).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                    color: hex(dev.$3).withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(btn.$2, size: 22, color: hex(dev.$3)),
                  const SizedBox(height: 4),
                  Text(btn.$1,
                      textAlign: TextAlign.center,
                      style: gfont(AppType.bodySm,
                          color: hex(dev.$3),
                          weight: FontWeight.w500,
                          size: 9)),
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
                'Control multiple devices from one screen. Switch between TV, Soundbar, Set-Top Box, Blu-ray, and Projector. Each device has its own button layout. All commands sent locally via IR/IP.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
