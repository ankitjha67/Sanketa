import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'common.dart';

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
            color: hex(AppColors.error),
            borderColor: hex(AppColors.error).withValues(alpha: 0.4),
            onTap: () => c.key(core.Key.power),
          ),
          _sourceToggle(c),
          _roundButton(
            icon: Icons.volume_off,
            color: hex(AppColors.onSurfaceVariant),
            borderColor: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            onTap: () => c.key(core.Key.mute),
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
  }) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      );

  Widget _dpad(RemoteController c) {
    Widget arrow(IconData icon, Alignment align, VoidCallback onTap) => Align(
          alignment: align,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              width: align == Alignment.topCenter || align == Alignment.bottomCenter ? 56 : 46,
              height: align == Alignment.topCenter || align == Alignment.bottomCenter ? 46 : 56,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainer),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Icon(icon, size: 22, color: hex(AppColors.onSurface)),
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
              arrow(Icons.keyboard_arrow_up, Alignment.topCenter, () => c.key(core.Key.up)),
              arrow(Icons.keyboard_arrow_down, Alignment.bottomCenter, () => c.key(core.Key.down)),
              arrow(Icons.keyboard_arrow_left, Alignment.centerLeft, () => c.key(core.Key.left)),
              arrow(Icons.keyboard_arrow_right, Alignment.centerRight, () => c.key(core.Key.right)),
            ]),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => c.key(core.Key.ok),
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
        ],
      ),
    );
  }

  Widget _functions(RemoteController c) => Row(
        children: [
          _funcButton(Icons.arrow_back, 'Back', () => c.key(core.Key.back)),
          const SizedBox(width: AppSpacing.sm),
          _funcButton(Icons.dialpad, '123', () {}),
          const SizedBox(width: AppSpacing.sm),
          _funcButton(Icons.home, 'Home', () => c.key(core.Key.home)),
        ],
      );

  Widget _funcButton(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: panel(fill: AppColors.surfaceContainer, radius: AppRadii.md),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: hex(AppColors.onSurfaceVariant)),
              const SizedBox(width: 4),
              Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500)),
            ]),
          ),
        ),
      );

  Widget _rockers(RemoteController c) => Row(children: [
        Expanded(child: _rocker('VOL', () => c.key(core.Key.volumeUp), () => c.key(core.Key.volumeDown))),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: _rocker('CH', () => c.key(core.Key.channelUp), () => c.key(core.Key.channelDown))),
      ]);

  Widget _rocker(String label, VoidCallback onUp, VoidCallback onDown) {
    Widget half(IconData icon, VoidCallback onTap, {required bool top}) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => c.launch(label),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: panel(fill: AppColors.surfaceContainer, radius: AppRadii.base),
              child: Text(label,
                  style: gfont(AppType.bodySm, color: hex(color), weight: FontWeight.w800, size: 11)),
            ),
          ),
        );

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
