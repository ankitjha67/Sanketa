import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class GamePadScreen extends StatefulWidget {
  const GamePadScreen({super.key});

  @override
  State<GamePadScreen> createState() => _GamePadScreenState();
}

class _GamePadScreenState extends State<GamePadScreen> {
  bool _haptic = true;

  void _send(core.Key key) {
    RemoteScope.of(context).key(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Game Pad',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _haptic = !_haptic),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _haptic ? Icons.vibration : Icons.do_not_disturb,
                size: 20,
                color: hex(_haptic ? AppColors.primary : AppColors.outlineVariant),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _topButtons(),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: _mainControls()),
              const SizedBox(height: AppSpacing.lg),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topButtons() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _pillButton('HOME', Icons.home, () => _send(core.Key.home)),
      _pillButton('MENU', Icons.menu, () => _send(core.Key.menu)),
      _pillButton('BACK', Icons.arrow_back, () => _send(core.Key.back)),
    ],
  );

  Widget _pillButton(String label, IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: hex(AppColors.onSurface)),
          const SizedBox(width: 6),
          Text(label,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 10)),
        ],
      ),
    ),
  );

  Widget _mainControls() => Row(
    children: [
      Expanded(child: _dpadCluster()),
      const SizedBox(width: AppSpacing.lg),
      Expanded(child: _actionButtons()),
    ],
  );

  Widget _dpadCluster() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.lg, borderOpacity: 0.15),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('D-PAD',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
        const SizedBox(height: 10),
        _dpadButton(Icons.keyboard_arrow_up, () => _send(core.Key.up)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dpadButton(Icons.keyboard_arrow_left, () => _send(core.Key.left)),
            _centerButton(() => _send(core.Key.ok)),
            _dpadButton(Icons.keyboard_arrow_right, () => _send(core.Key.right)),
          ],
        ),
        _dpadButton(Icons.keyboard_arrow_down, () => _send(core.Key.down)),
      ],
    ),
  );

  Widget _dpadButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52,
      height: 52,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
      ),
      child: Icon(icon, size: 24, color: hex(AppColors.onSurface)),
    ),
  );

  Widget _centerButton(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52,
      height: 52,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: hex(AppColors.primaryContainer).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text('OK',
            style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w700, size: 13)),
      ),
    ),
  );

  Widget _actionButtons() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.lg, borderOpacity: 0.15),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('ACTION',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
        const SizedBox(height: 10),
        _colorButton('Y', 0xFFFDD835, () => _send(core.Key.yellow)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _colorButton('X', 0xFF1E88E5, () => _send(core.Key.blue)),
            const SizedBox(width: 10),
            _colorButton('B', 0xFFE53935, () => _send(core.Key.red)),
          ],
        ),
        _colorButton('A', 0xFF43A047, () => _send(core.Key.green)),
      ],
    ),
  );

  Widget _colorButton(String label, int color, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Color(color).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: Color(color).withValues(alpha: 0.5), width: 2),
        ),
        child: Center(
          child: Text(label,
              style: gfont(AppType.headlineMd, color: Color(color), size: 18, weight: FontWeight.w700)),
        ),
      ),
    ),
  );

  Widget _bottomBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _smallButton(Icons.play_arrow, 'Play', () => _send(core.Key.play)),
        _smallButton(Icons.fast_rewind, 'Rew', () => _send(core.Key.rewind)),
        _smallButton(Icons.fast_forward, 'FF', () => _send(core.Key.fastForward)),
        _smallButton(Icons.stop, 'Stop', () => _send(core.Key.stop)),
        _smallButton(Icons.volume_up, 'Vol+', () => _send(core.Key.volumeUp)),
        _smallButton(Icons.volume_down, 'Vol-', () => _send(core.Key.volumeDown)),
        _smallButton(Icons.volume_off, 'Mute', () => _send(core.Key.mute)),
      ],
    ),
  );

  Widget _smallButton(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(icon, size: 16, color: hex(AppColors.onSurface)),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 8)),
      ],
    ),
  );
}
