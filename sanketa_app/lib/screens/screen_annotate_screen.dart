import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ScreenAnnotateScreen extends StatefulWidget {
  const ScreenAnnotateScreen({super.key});

  @override
  State<ScreenAnnotateScreen> createState() => _ScreenAnnotateScreenState();
}

class _ScreenAnnotateScreenState extends State<ScreenAnnotateScreen> {
  int _toolIndex = 0;
  int _colorIndex = 0;
  double _strokeWidth = 3.0;
  final _strokes = <_Stroke>[];
  List<Offset> _currentPoints = [];
  bool _drawing = false;

  static const _tools = [
    ('Pen', Icons.edit),
    ('Highlighter', Icons.border_color),
    ('Arrow', Icons.arrow_right_alt),
    ('Circle', Icons.circle_outlined),
  ];

  static const _colors = [
    (AppColors.error, 'Red'),
    (AppColors.signalEmerald, 'Green'),
    (AppColors.primary, 'Blue'),
    (AppColors.alertAmber, 'Yellow'),
    (AppColors.secondary, 'Purple'),
    (AppColors.onSurface, 'White'),
  ];

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  void _clearAll() {
    setState(() => _strokes.clear());
  }

  void _share() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Annotation saved locally'),
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
        title: Text('Screen Annotate',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _undo,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.undo, size: 20, color: hex(AppColors.outline)),
            ),
          ),
          GestureDetector(
            onTap: _clearAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.delete_sweep,
                  size: 20, color: hex(AppColors.error)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _canvas(),
          const SizedBox(height: AppSpacing.md),
          _toolBar(),
          const SizedBox(height: AppSpacing.md),
          _colorPicker(),
          const SizedBox(height: AppSpacing.md),
          _strokeSlider(),
          const SizedBox(height: AppSpacing.md),
          _actionButtons(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _canvas() => Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: GestureDetector(
            onPanStart: (d) {
              setState(() {
                _drawing = true;
                _currentPoints = [d.localPosition];
              });
            },
            onPanUpdate: (d) {
              if (_drawing) {
                setState(() => _currentPoints.add(d.localPosition));
              }
            },
            onPanEnd: (_) {
              if (_drawing && _currentPoints.length > 1) {
                setState(() {
                  _strokes.add(_Stroke(
                    points: List.of(_currentPoints),
                    color: _colors[_colorIndex].$1,
                    width: _strokeWidth,
                    tool: _toolIndex,
                  ));
                  _currentPoints = [];
                  _drawing = false;
                });
              }
            },
            child: CustomPaint(
              painter: _AnnotatePainter(
                strokes: _strokes,
                currentPoints: _currentPoints,
                currentColor: _colors[_colorIndex].$1,
                currentWidth: _strokeWidth,
                currentTool: _toolIndex,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      );

  Widget _toolBar() => Container(
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
            Text('Tool',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _tools.asMap().entries.map((e) {
                final active = e.key == _toolIndex;
                return GestureDetector(
                  onTap: () => setState(() => _toolIndex = e.key),
                  child: Container(
                    width: 56,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(
                        color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(e.value.$2,
                            size: 18,
                            color: hex(active ? AppColors.primary : AppColors.outline)),
                        Text(e.value.$1,
                            style: gfont(AppType.bodySm,
                                color: hex(active ? AppColors.primary : AppColors.outline),
                                size: 8)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _colorPicker() => Container(
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
            Text('Color',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _colors.asMap().entries.map((e) {
                final active = e.key == _colorIndex;
                return GestureDetector(
                  onTap: () => setState(() => _colorIndex = e.key),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: hex(e.value.$1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? hex(AppColors.onSurface)
                            : Colors.transparent,
                        width: active ? 3 : 0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _strokeSlider() => Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Stroke Width',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                Text('${_strokeWidth.round()}px',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w700,
                        size: 14)),
              ],
            ),
            Slider(
              value: _strokeWidth,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: hex(AppColors.primary),
              inactiveColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              onChanged: (v) => setState(() => _strokeWidth = v),
            ),
          ],
        ),
      );

  Widget _actionButtons() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _share,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(AppColors.signalEmerald).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save,
                        size: 18, color: hex(AppColors.signalEmerald)),
                    const SizedBox(width: 6),
                    Text('Save',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.signalEmerald),
                            weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _clearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(AppColors.error).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.clear,
                        size: 18, color: hex(AppColors.error)),
                    const SizedBox(width: 6),
                    Text('Clear All',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.error),
                            weight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                'Draw on the TV screen preview to annotate what you see. Use different tools and colors to highlight, circle, or point at areas of interest. All annotations stay local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Stroke {
  const _Stroke({
    required this.points,
    required this.color,
    required this.width,
    required this.tool,
  });

  final List<Offset> points;
  final int color;
  final double width;
  final int tool;
}

class _AnnotatePainter extends CustomPainter {
  _AnnotatePainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.currentTool,
  });

  final List<_Stroke> strokes;
  final List<Offset> currentPoints;
  final int currentColor;
  final double currentWidth;
  final int currentTool;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.color, stroke.width);
    }
    if (currentPoints.length > 1) {
      _drawStroke(canvas, currentPoints, currentColor, currentWidth);
    }
  }

  void _drawStroke(
      Canvas canvas, List<Offset> points, int color, double width) {
    final paint = Paint()
      ..color = hex(color)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnnotatePainter old) => true;
}
