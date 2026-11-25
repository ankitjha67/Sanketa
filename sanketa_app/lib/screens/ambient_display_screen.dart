import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class AmbientDisplayScreen extends StatefulWidget {
  const AmbientDisplayScreen({super.key});

  @override
  State<AmbientDisplayScreen> createState() => _AmbientDisplayScreenState();
}

class _AmbientDisplayScreenState extends State<AmbientDisplayScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  bool _dockMode = false;
  double _brightness = 0.4;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _send(core.Key key) {
    RemoteScope.of(context).key(key);
  }

  String get _timeString {
    final h = _now.hour;
    final m = _now.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:$m $period';
  }

  String get _dateString {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[_now.weekday - 1]}, ${months[_now.month - 1]} ${_now.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_dockMode) {
      return _buildDockMode();
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Ambient Display',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          _brightnessControl(),
          const SizedBox(height: AppSpacing.lg),
          _enterDockButton(),
          const SizedBox(height: AppSpacing.lg),
          _quickActions(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(AppRadii.lg),
    ),
    child: Column(
      children: [
        Text(_timeString,
            style: gfont(AppType.headlineMd, color: Colors.white.withValues(alpha: _brightness), size: 48, weight: FontWeight.w200)),
        const SizedBox(height: 4),
        Text(_dateString,
            style: gfont(AppType.bodyMd, color: Colors.white.withValues(alpha: _brightness * 0.7), size: 14)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _miniButton(Icons.power_settings_new, () => _send(core.Key.power)),
            const SizedBox(width: 16),
            _miniButton(Icons.volume_off, () => _send(core.Key.mute)),
            const SizedBox(width: 16),
            _miniButton(Icons.volume_down, () => _send(core.Key.volumeDown)),
            const SizedBox(width: 16),
            _miniButton(Icons.volume_up, () => _send(core.Key.volumeUp)),
          ],
        ),
      ],
    ),
  );

  Widget _miniButton(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: Colors.white.withValues(alpha: _brightness)),
    ),
  );

  Widget _brightnessControl() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Brightness',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.brightness_low, size: 16, color: hex(AppColors.outline)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: hex(AppColors.primary),
                  inactiveTrackColor: hex(AppColors.surfaceContainerHigh),
                  thumbColor: hex(AppColors.primary),
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: _brightness,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (v) => setState(() => _brightness = v),
                ),
              ),
            ),
            Icon(Icons.brightness_high, size: 16, color: hex(AppColors.outline)),
          ],
        ),
      ],
    ),
  );

  Widget _enterDockButton() => GestureDetector(
    onTap: () => setState(() => _dockMode = true),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: hex(AppColors.primaryContainer).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dock, size: 16, color: hex(AppColors.primary)),
          const SizedBox(width: 8),
          Text('Enter Dock Mode',
              style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _quickActions() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions in Dock Mode',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _actionChip(Icons.power_settings_new, 'Power'),
            _actionChip(Icons.volume_off, 'Mute'),
            _actionChip(Icons.volume_down, 'Vol -'),
            _actionChip(Icons.volume_up, 'Vol +'),
            _actionChip(Icons.home, 'Home'),
            _actionChip(Icons.arrow_back, 'Back'),
          ],
        ),
      ],
    ),
  );

  Widget _actionChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerHigh),
      borderRadius: BorderRadius.circular(AppRadii.full),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: hex(AppColors.outline)),
        const SizedBox(width: 4),
        Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 10)),
      ],
    ),
  );

  Widget _buildDockMode() => GestureDetector(
    onDoubleTap: () => setState(() => _dockMode = false),
    child: Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_timeString,
                  style: gfont(AppType.headlineMd, color: Colors.white.withValues(alpha: _brightness), size: 64, weight: FontWeight.w100)),
              const SizedBox(height: 4),
              Text(_dateString,
                  style: gfont(AppType.bodyMd, color: Colors.white.withValues(alpha: _brightness * 0.6), size: 16)),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dockButton(Icons.power_settings_new, 'Power', () => _send(core.Key.power)),
                  const SizedBox(width: 24),
                  _dockButton(Icons.volume_off, 'Mute', () => _send(core.Key.mute)),
                  const SizedBox(width: 24),
                  _dockButton(Icons.volume_down, 'Vol -', () => _send(core.Key.volumeDown)),
                  const SizedBox(width: 24),
                  _dockButton(Icons.volume_up, 'Vol +', () => _send(core.Key.volumeUp)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dockButton(Icons.home, 'Home', () => _send(core.Key.home)),
                  const SizedBox(width: 24),
                  _dockButton(Icons.arrow_back, 'Back', () => _send(core.Key.back)),
                  const SizedBox(width: 24),
                  _dockButton(Icons.play_arrow, 'Play', () => _send(core.Key.play)),
                  const SizedBox(width: 24),
                  _dockButton(Icons.stop, 'Stop', () => _send(core.Key.stop)),
                ],
              ),
              const SizedBox(height: 48),
              Text('Double-tap to exit',
                  style: gfont(AppType.bodySm, color: Colors.white.withValues(alpha: 0.2), size: 11)),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _dockButton(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, size: 20, color: Colors.white.withValues(alpha: _brightness)),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: gfont(AppType.bodySm, color: Colors.white.withValues(alpha: _brightness * 0.5), size: 9)),
      ],
    ),
  );

  Widget _infoCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.tertiary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Dock Mode turns your phone into a bedside remote with a large clock and essential controls. Double-tap to exit dock mode.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
