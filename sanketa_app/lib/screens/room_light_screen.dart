import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class RoomLightScreen extends StatefulWidget {
  const RoomLightScreen({super.key});

  @override
  State<RoomLightScreen> createState() => _RoomLightScreenState();
}

class _RoomLightScreenState extends State<RoomLightScreen> {
  bool _masterOn = true;
  int _activePreset = -1;

  static const _presetColors = <(String, int)>[
    ('Warm White', 0xFFFFF3E0),
    ('Cool White', 0xFFE3F2FD),
    ('Sunset', 0xFFFFCCBC),
    ('Ocean', 0xFF80DEEA),
    ('Forest', 0xFFC8E6C9),
    ('Lavender', 0xFFE1BEE7),
    ('Ruby', 0xFFEF9A9A),
    ('Amber', 0xFFFFE082),
  ];

  static const _modePresets = <(String, IconData, int, List<double>)>[
    ('Movie Mode', Icons.movie, AppColors.primary, [0.3, 0.1, 0.1, 0.4, 0.2]),
    ('Gaming Mode', Icons.sports_esports, AppColors.signalEmerald, [0.8, 0.9, 0.9, 0.7, 0.8]),
    ('Party Mode', Icons.celebration, AppColors.alertAmber, [1.0, 1.0, 1.0, 1.0, 1.0]),
  ];

  final _zones = <({String name, IconData icon, bool on, double brightness, int colorIdx})>[
    (name: 'Behind TV', icon: Icons.tv, on: true, brightness: 0.7, colorIdx: 0),
    (name: 'Ceiling', icon: Icons.lightbulb, on: true, brightness: 0.5, colorIdx: 1),
    (name: 'Left Wall', icon: Icons.arrow_back, on: false, brightness: 0.4, colorIdx: 2),
    (name: 'Right Wall', icon: Icons.arrow_forward, on: false, brightness: 0.4, colorIdx: 3),
    (name: 'Floor Strip', icon: Icons.horizontal_rule, on: true, brightness: 0.6, colorIdx: 4),
  ];

  void _toggleZone(int idx) {
    setState(() {
      final z = _zones[idx];
      _zones[idx] = (
        name: z.name,
        icon: z.icon,
        on: !z.on,
        brightness: z.brightness,
        colorIdx: z.colorIdx,
      );
    });
    HapticFeedback.selectionClick();
  }

  void _setBrightness(int idx, double val) {
    setState(() {
      final z = _zones[idx];
      _zones[idx] = (
        name: z.name,
        icon: z.icon,
        on: z.on,
        brightness: val,
        colorIdx: z.colorIdx,
      );
    });
  }

  void _setColor(int zoneIdx, int colorIdx) {
    setState(() {
      final z = _zones[zoneIdx];
      _zones[zoneIdx] = (
        name: z.name,
        icon: z.icon,
        on: z.on,
        brightness: z.brightness,
        colorIdx: colorIdx,
      );
    });
    HapticFeedback.selectionClick();
  }

  void _applyMode(int modeIdx) {
    final mode = _modePresets[modeIdx];
    setState(() {
      _activePreset = modeIdx;
      for (var i = 0; i < _zones.length; i++) {
        final z = _zones[i];
        _zones[i] = (
          name: z.name,
          icon: z.icon,
          on: mode.$4[i] > 0.1,
          brightness: mode.$4[i],
          colorIdx: z.colorIdx,
        );
      }
    });
    HapticFeedback.mediumImpact();
  }

  void _apply() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Light settings applied'),
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
        title: Text('Room Light',
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
          _masterToggle(),
          const SizedBox(height: AppSpacing.lg),
          Text('Scene Presets',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _modeGrid(),
          const SizedBox(height: AppSpacing.lg),
          Text('Light Zones',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_zones.length, _zoneCard),
          const SizedBox(height: AppSpacing.lg),
          _applyButton(),
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
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.light_mode, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Ambient Lighting',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Sync your room lights with TV content for an immersive experience',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _masterToggle() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.power_settings_new,
                color: hex(_masterOn ? AppColors.signalEmerald : AppColors.outline),
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Master Power',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
            ),
            Switch(
              value: _masterOn,
              activeColor: hex(AppColors.signalEmerald),
              onChanged: (v) {
                setState(() => _masterOn = v);
                HapticFeedback.selectionClick();
              },
            ),
          ],
        ),
      );

  Widget _modeGrid() => Row(
        children: List.generate(_modePresets.length, (i) {
          final m = _modePresets[i];
          final active = _activePreset == i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: GestureDetector(
                onTap: _masterOn ? () => _applyMode(i) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: hex(m.$3).withValues(alpha: active ? 0.15 : 0.06),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                        color: hex(m.$3)
                            .withValues(alpha: active ? 0.4 : 0.1)),
                  ),
                  child: Column(
                    children: [
                      Icon(m.$2, color: hex(m.$3), size: 22),
                      const SizedBox(height: 4),
                      Text(m.$1,
                          textAlign: TextAlign.center,
                          style: gfont(AppType.bodySm,
                              color: hex(m.$3),
                              weight: FontWeight.w600,
                              size: 10)),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      );

  Widget _zoneCard(int idx) {
    final z = _zones[idx];
    final pc = _presetColors[z.colorIdx];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: _masterOn ? 1.0 : 0.4,
        child: Container(
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
                  Icon(z.icon,
                      color: hex(z.on ? AppColors.primary : AppColors.outline),
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(z.name,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                  ),
                  GestureDetector(
                    onTap: _masterOn ? () => _toggleZone(idx) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: hex(z.on
                                ? AppColors.signalEmerald
                                : AppColors.outline)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.full),
                      ),
                      child: Text(z.on ? 'ON' : 'OFF',
                          style: gfont(AppType.bodySm,
                              color: hex(z.on
                                  ? AppColors.signalEmerald
                                  : AppColors.outline),
                              weight: FontWeight.w600,
                              size: 10)),
                    ),
                  ),
                ],
              ),
              if (z.on) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Brightness',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                    const Spacer(),
                    Text('${(z.brightness * 100).round()}%',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 10)),
                  ],
                ),
                Slider(
                  value: z.brightness,
                  min: 0.05,
                  max: 1.0,
                  divisions: 19,
                  activeColor: hex(AppColors.primary),
                  inactiveColor:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                  onChanged:
                      _masterOn ? (v) => _setBrightness(idx, v) : null,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetColors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, ci) {
                      final c = _presetColors[ci];
                      final sel = ci == z.colorIdx;
                      return GestureDetector(
                        onTap: _masterOn ? () => _setColor(idx, ci) : null,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(c.$2),
                            shape: BoxShape.circle,
                            border: sel
                                ? Border.all(
                                    color: hex(AppColors.onSurface), width: 2)
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(pc.$1,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _applyButton() => GestureDetector(
        onTap: _masterOn ? _apply : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_masterOn ? AppColors.primary : AppColors.outline)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Text('Apply to TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodyMd,
                  color: hex(_masterOn ? AppColors.primary : AppColors.outline),
                  weight: FontWeight.w600)),
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: hex(AppColors.outline), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Configure smart light zones to match your TV content. Requires compatible smart lights.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11),
              ),
            ),
          ],
        ),
      );
}
