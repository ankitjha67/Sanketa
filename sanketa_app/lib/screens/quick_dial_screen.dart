import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class QuickDialScreen extends StatefulWidget {
  const QuickDialScreen({super.key});

  @override
  State<QuickDialScreen> createState() => _QuickDialScreenState();
}

class _QuickDialScreenState extends State<QuickDialScreen> {
  String _digits = '';

  static const _digitKeys = <String, core.Key>{
    '0': core.Key.digit0,
    '1': core.Key.digit1,
    '2': core.Key.digit2,
    '3': core.Key.digit3,
    '4': core.Key.digit4,
    '5': core.Key.digit5,
    '6': core.Key.digit6,
    '7': core.Key.digit7,
    '8': core.Key.digit8,
    '9': core.Key.digit9,
  };

  void _tap(String digit) {
    if (_digits.length >= 5) return;
    setState(() => _digits += digit);
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _clear() => setState(() => _digits = '');

  void _tune() {
    if (_digits.isEmpty) return;
    final c = RemoteScope.of(context);
    for (final ch in _digits.split('')) {
      final k = _digitKeys[ch];
      if (k != null) c.key(k);
    }
    c.key(core.Key.ok);
    setState(() => _digits = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Dial Pad',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _display(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _keypad()),
            const SizedBox(height: AppSpacing.md),
            _tuneButton(),
            const SizedBox(height: AppSpacing.lg),
            _infoCard(),
          ],
        ),
      ),
    );
  }

  Widget _display() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      children: [
        Text(
          _digits.isEmpty ? '---' : _digits,
          style: gfont(AppType.headlineMd,
              color: hex(_digits.isEmpty ? AppColors.outline : AppColors.onSurface),
              size: 48,
              weight: FontWeight.w200),
        ),
        if (_digits.isNotEmpty)
          Text('Channel $_digits',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
      ],
    ),
  );

  Widget _keypad() => LayoutBuilder(
    builder: (context, constraints) {
      final spacing = 8.0;
      final cols = 3;
      final rows = 4;
      final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
      final h = (constraints.maxHeight - spacing * (rows - 1)) / rows;
      final size = w < h ? w : h;

      return Center(
        child: SizedBox(
          width: size * cols + spacing * (cols - 1),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              ..._digitBtn('1', size), ..._digitBtn('2', size), ..._digitBtn('3', size),
              ..._digitBtn('4', size), ..._digitBtn('5', size), ..._digitBtn('6', size),
              ..._digitBtn('7', size), ..._digitBtn('8', size), ..._digitBtn('9', size),
              _actionBtn(Icons.backspace_outlined, 'Del', size, _backspace, AppColors.error),
              ..._digitBtn('0', size),
              _actionBtn(Icons.clear, 'Clr', size, _clear, AppColors.outline),
            ],
          ),
        ),
      );
    },
  );

  List<Widget> _digitBtn(String d, double size) => [
    GestureDetector(
      onTap: () => _tap(d),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Center(
          child: Text(d,
              style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 28, weight: FontWeight.w300)),
        ),
      ),
    ),
  ];

  Widget _actionBtn(IconData icon, String label, double size, VoidCallback onTap, int color) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: hex(color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(color).withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: hex(color)),
              Text(label, style: gfont(AppType.bodySm, color: hex(color), size: 9)),
            ],
          ),
        ),
      );

  Widget _tuneButton() => GestureDetector(
    onTap: _tune,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: hex(_digits.isEmpty ? AppColors.surfaceContainerHigh : AppColors.primary)
            .withValues(alpha: _digits.isEmpty ? 1 : 0.15),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: _digits.isNotEmpty
            ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send, size: 16,
              color: hex(_digits.isEmpty ? AppColors.outline : AppColors.primary)),
          const SizedBox(width: 8),
          Text('Tune',
              style: gfont(AppType.bodyMd,
                  color: hex(_digits.isEmpty ? AppColors.outline : AppColors.primary),
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
      border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Enter a channel number and tap Tune. Each digit is sent as a key press followed by OK to confirm.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
