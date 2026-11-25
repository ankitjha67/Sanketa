import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/haptic_service.dart';
import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'common.dart';
import 'honesty_banner.dart';

/// The grounded tactile remote: power/source/mute, D-pad, functions, rockers,
/// and app shortcuts. Capability-driven — each control maps to a contract call.
class RemotePad extends StatelessWidget {
  const RemotePad({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(fill: AppColors.surfaceContainerLow, radius: AppRadii.lg),
      child: Column(children: [
        _topRow(c),
        const SizedBox(height: AppSpacing.md),
        _dpad(c),
        const SizedBox(height: AppSpacing.md),
        _functions(c),
        const SizedBox(height: AppSpacing.md),
        _rockers(c),
        HonestyBanner(
          label: 'Volume and mute are best-effort — this TV does not confirm changes.',
          reportsState: c.caps.volumeReadback,
        ),
        const SizedBox(height: AppSpacing.sm),
        _apps(c),
      ]),
    );
  }

  Widget _topRow(RemoteController c) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _roundButton(
            icon: Icons.power_settings_new,
            color: c.isPoweredOn ? hex(AppColors.signalEmerald) : hex(AppColors.error),
            borderColor: c.isPoweredOn
                ? hex(AppColors.signalEmerald).withValues(alpha: 0.4)
                : hex(AppColors.error).withValues(alpha: 0.4),
            onTap: () => c.power(!c.isPoweredOn),
            semanticLabel: c.isPoweredOn ? 'Power off' : 'Power on',
          ),
          if (c.caps.inputList) _sourceToggle(c),
          _roundButton(
            icon: c.isMuted ? Icons.volume_off : Icons.volume_up,
            color: c.isMuted ? hex(AppColors.error) : hex(AppColors.onSurfaceVariant),
            borderColor: c.isMuted
                ? hex(AppColors.error).withValues(alpha: 0.4)
                : hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            onTap: () => c.key(core.Key.mute),
            semanticLabel: c.isMuted ? 'Unmute' : 'Mute',
          ),
        ],
      );

  Widget _sourceToggle(RemoteController c) {
    Widget seg(String label) {
      final active = c.currentSource == label;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => c.setSource(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: active
              ? BoxDecoration(
                  color: hex(AppColors.surfaceContainer),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: hex(AppColors.primaryContainer).withValues(alpha: 0.3)),
                )
              : null,
          child: Text(label,
              style: gfont(AppType.bodySm,
                  color: active ? hex(AppColors.primaryContainer) : hex(AppColors.outline),
                  weight: FontWeight.w500)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: panel(fill: AppColors.surfaceContainerLowest, radius: AppRadii.md, borderOpacity: 0.3),
      child: Row(mainAxisSize: MainAxisSize.min, children: [seg('HDMI 1'), seg('HDMI 2'), seg('TV')]),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
    String? semanticLabel,
  }) =>
      Semantics(
        label: semanticLabel,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.instance.confirm();
            onTap();
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      );

  Widget _dpad(RemoteController c) {
    Widget arrow(IconData icon, Alignment align, VoidCallback onTap, String label) => Align(
          alignment: align,
          child: Semantics(
            label: label,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.instance.tap();
                onTap();
              },
              child: Container(
                width: align == Alignment.topCenter || align == Alignment.bottomCenter ? 56 : 48,
                height: align == Alignment.topCenter || align == Alignment.bottomCenter ? 48 : 56,
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainer),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Icon(icon, size: 22, color: hex(AppColors.onSurface)),
              ),
            ),
          ),
        );

    return SizedBox(
      width: 224,
      height: 224,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerLowest),
              shape: BoxShape.circle,
              border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Stack(children: [
              arrow(Icons.keyboard_arrow_up, Alignment.topCenter, () => c.key(core.Key.up), 'Up'),
              arrow(Icons.keyboard_arrow_down, Alignment.bottomCenter, () => c.key(core.Key.down), 'Down'),
              arrow(Icons.keyboard_arrow_left, Alignment.centerLeft, () => c.key(core.Key.left), 'Left'),
              arrow(Icons.keyboard_arrow_right, Alignment.centerRight, () => c.key(core.Key.right), 'Right'),
            ]),
          ),
          Semantics(
            label: 'OK',
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.instance.confirm();
                c.key(core.Key.ok);
              },
              child: Container(
                width: 80,
                height: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  shape: BoxShape.circle,
                  border: Border.all(color: hex(AppColors.primaryContainer).withValues(alpha: 0.6)),
                  boxShadow: outerShadows(AppElevation.dpadCenterGlow),
                ),
                child: Text('OK',
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.primaryContainer), size: 14, weight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _functions(RemoteController c) => Row(
        children: [
          _funcButton(Icons.arrow_back, 'Back', () => c.key(core.Key.back)),
          const SizedBox(width: AppSpacing.sm),
          _funcButton(Icons.dialpad, '123', c.toggleNumbers),
          const SizedBox(width: AppSpacing.sm),
          _funcButton(Icons.home, 'Home', () => c.key(core.Key.home)),
        ],
      );

  Widget _funcButton(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: Semantics(
          label: label,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.instance.tap();
              onTap();
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: panel(fill: AppColors.surfaceContainer, radius: AppRadii.md),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 16, color: hex(AppColors.onSurfaceVariant)),
                const SizedBox(width: 4),
                Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500)),
              ]),
            ),
          ),
        ),
      );

  Widget _rockers(RemoteController c) {
    final volLabel = c.tvVolume >= 0 ? 'VOL ${c.tvVolume}' : 'VOL';
    return Row(children: [
      Expanded(child: _rocker(volLabel, () => c.key(core.Key.volumeUp), () => c.key(core.Key.volumeDown))),
      const SizedBox(width: AppSpacing.md),
      Expanded(child: _rocker('CH', () => c.key(core.Key.channelUp), () => c.key(core.Key.channelDown))),
    ]);
  }

  Widget _rocker(String label, VoidCallback onUp, VoidCallback onDown) {
    Widget half(IconData icon, VoidCallback onTap, {required bool top}) => Semantics(
          label: '${top ? "Increase" : "Decrease"} $label',
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.instance.tap();
              onTap();
            },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainer),
                borderRadius: BorderRadius.vertical(
                  top: top ? const Radius.circular(AppRadii.base) : Radius.zero,
                  bottom: top ? Radius.zero : const Radius.circular(AppRadii.base),
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (!top) Text(label, style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
                Icon(icon, size: 18, color: hex(AppColors.onSurface)),
                if (top) Text(label, style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
              ]),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: panel(fill: AppColors.surfaceContainerLowest, radius: AppRadii.md),
      child: Column(children: [
        half(Icons.add, onUp, top: true),
        Container(height: 1, width: 24, color: hex(AppColors.outlineVariant).withValues(alpha: 0.4)),
        half(Icons.remove, onDown, top: false),
      ]),
    );
  }

  Widget _apps(RemoteController c) {
    Widget app(String label, int color) => Expanded(
          child: Semantics(
            label: 'Launch $label',
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => c.launch(label),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: panel(fill: AppColors.surfaceContainer, radius: AppRadii.base),
                child: Text(label,
                    style: gfont(AppType.bodySm, color: hex(color), weight: FontWeight.w800, size: 11)),
              ),
            ),
          ),
        );

    if (!c.caps.appLaunch) return const SizedBox.shrink();
    return Row(children: [
      app('NETFLIX', AppColors.netflix),
      const SizedBox(width: AppSpacing.xs),
      app('YouTube', AppColors.youTube),
      const SizedBox(width: AppSpacing.xs),
      app('prime', AppColors.prime),
      const SizedBox(width: AppSpacing.xs),
      app('Disney+', AppColors.disney),
    ]);
  }
}
