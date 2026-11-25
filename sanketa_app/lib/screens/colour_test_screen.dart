import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _TestPattern {
  const _TestPattern(this.id, this.name, this.icon);
  final String id;
  final String name;
  final IconData icon;
}

class ColourTestScreen extends StatefulWidget {
  const ColourTestScreen({super.key});

  @override
  State<ColourTestScreen> createState() => _ColourTestScreenState();
}

class _ColourTestScreenState extends State<ColourTestScreen> {
  static const _patterns = <_TestPattern>[
    _TestPattern('bars', 'Colour Bars', Icons.view_column),
    _TestPattern('gradient', 'Gradient', Icons.gradient),
    _TestPattern('white', 'Full White', Icons.crop_square),
    _TestPattern('black', 'Full Black', Icons.square),
    _TestPattern('red', 'Red', Icons.circle),
    _TestPattern('green', 'Green', Icons.circle),
    _TestPattern('blue', 'Blue', Icons.circle),
    _TestPattern('grid', 'Pixel Grid', Icons.grid_on),
    _TestPattern('greyscale', 'Greyscale', Icons.tonality),
    _TestPattern('crosshatch', 'Focus Chart', Icons.center_focus_strong),
  ];

  static const _barColours = [
    Color(0xFFFFFFFF),
    Color(0xFFFFFF00),
    Color(0xFF00FFFF),
    Color(0xFF00FF00),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
    Color(0xFF0000FF),
    Color(0xFF000000),
  ];

  void _showPattern(String id) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _PatternView(id: id, onBack: () => Navigator.pop(context)),
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
        title: Text('Test Patterns',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _previewCard(),
          const SizedBox(height: AppSpacing.lg),
          _patternGrid(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _previewCard() => Container(
    height: 140,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Row(
      children: _barColours.map((c) => Expanded(
        child: Container(color: c),
      )).toList(),
    ),
  );

  Widget _patternGrid() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Patterns',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: _patterns.map((p) => GestureDetector(
            onTap: () => _showPattern(p.id),
            child: Container(
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(p.icon, size: 18, color: _patternIconColor(p.id)),
                  const SizedBox(height: 2),
                  Text(p.name,
                      textAlign: TextAlign.center,
                      style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 8)),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    ),
  );

  Color _patternIconColor(String id) {
    switch (id) {
      case 'red': return const Color(0xFFFF0000);
      case 'green': return const Color(0xFF00FF00);
      case 'blue': return const Color(0xFF0000FF);
      default: return hex(AppColors.primary);
    }
  }

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
            'Display test patterns on your phone screen. Hold the phone next to your TV or use screen mirroring to calibrate colours, check for dead pixels, and verify uniformity.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}

class _PatternView extends StatelessWidget {
  const _PatternView({required this.id, required this.onBack});
  final String id;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBack,
      child: Scaffold(
        body: SizedBox.expand(child: _patternWidget()),
      ),
    );
  }

  Widget _patternWidget() {
    switch (id) {
      case 'bars': return _bars();
      case 'gradient': return _gradient();
      case 'white': return Container(color: const Color(0xFFFFFFFF));
      case 'black': return Container(color: const Color(0xFF000000));
      case 'red': return Container(color: const Color(0xFFFF0000));
      case 'green': return Container(color: const Color(0xFF00FF00));
      case 'blue': return Container(color: const Color(0xFF0000FF));
      case 'grid': return _grid();
      case 'greyscale': return _greyscale();
      case 'crosshatch': return _crosshatch();
      default: return Container(color: const Color(0xFF000000));
    }
  }

  Widget _bars() => Row(
    children: [
      const Color(0xFFFFFFFF),
      const Color(0xFFFFFF00),
      const Color(0xFF00FFFF),
      const Color(0xFF00FF00),
      const Color(0xFFFF00FF),
      const Color(0xFFFF0000),
      const Color(0xFF0000FF),
      const Color(0xFF000000),
    ].map((c) => Expanded(child: Container(color: c))).toList(),
  );

  Widget _gradient() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF000000), Color(0xFFFFFFFF)],
      ),
    ),
  );

  Widget _grid() => CustomPaint(painter: _GridPainter(), child: const SizedBox.expand());

  Widget _greyscale() => Row(
    children: List.generate(16, (i) {
      final v = (i * 17).clamp(0, 255);
      return Expanded(child: Container(color: Color.fromARGB(255, v, v, v)));
    }),
  );

  Widget _crosshatch() => Container(
    color: const Color(0xFF000000),
    child: Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
        ),
        child: const Center(
          child: Icon(Icons.add, size: 60, color: Color(0xFFFFFFFF)),
        ),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 0.5;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF000000));
    const step = 20.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
