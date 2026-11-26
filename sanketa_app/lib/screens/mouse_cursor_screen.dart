import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class MouseCursorScreen extends StatefulWidget {
  const MouseCursorScreen({super.key});

  @override
  State<MouseCursorScreen> createState() => _MouseCursorScreenState();
}

class _MouseCursorScreenState extends State<MouseCursorScreen> {
  double _sensitivity = 1.0;
  bool _scrollMode = false;
  bool _leftClick = true;
  Offset _cursorPos = const Offset(0.5, 0.5);
  Timer? _repeatTimer;
  String _cursorStyle = 'pointer';
  bool _trailEnabled = false;

  static const _styles = ['pointer', 'crosshair', 'hand', 'dot'];

  void _onPanUpdate(DragUpdateDetails d, BoxConstraints box) {
    final dx = (d.delta.dx / box.maxWidth) * _sensitivity;
    final dy = (d.delta.dy / box.maxHeight) * _sensitivity;
    setState(() {
      _cursorPos = Offset(
        (_cursorPos.dx + dx).clamp(0.0, 1.0),
        (_cursorPos.dy + dy).clamp(0.0, 1.0),
      );
    });
    if (_scrollMode) {
      if (d.delta.dy.abs() > 2) {
        _sendScroll(d.delta.dy > 0 ? 'down' : 'up');
      }
    }
  }

  void _sendScroll(String direction) {
    // Scroll via ATVRS key injection
  }

  void _onTap() {
    if (_leftClick) {
      // Send OK/Enter via ATVRS
    }
  }

  void _onLongPress() {
    // Send long-press / context menu
  }

  void _onDoubleTap() {
    // Send double-click via rapid OK
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Mouse Cursor',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: () => setState(() => _scrollMode = !_scrollMode),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _scrollMode ? Icons.swap_vert : Icons.mouse,
                size: 20,
                color: hex(_scrollMode
                    ? AppColors.signalEmerald
                    : AppColors.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _touchArea(),
          const SizedBox(height: AppSpacing.md),
          _clickButtons(),
          const SizedBox(height: AppSpacing.md),
          _sensitivitySlider(),
          const SizedBox(height: AppSpacing.md),
          _cursorStylePicker(),
          const SizedBox(height: AppSpacing.md),
          _optionsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _touchArea() => LayoutBuilder(builder: (ctx, box) {
        return GestureDetector(
          onPanUpdate: (d) => _onPanUpdate(d, box),
          onTap: _onTap,
          onLongPress: _onLongPress,
          onDoubleTap: _onDoubleTap,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerLow),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                  color:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _scrollMode
                            ? Icons.swap_vert
                            : Icons.touch_app_rounded,
                        size: 32,
                        color: hex(AppColors.outline).withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scrollMode
                            ? 'Swipe to scroll'
                            : 'Move to control cursor',
                        style: gfont(AppType.bodySm,
                            color:
                                hex(AppColors.outline).withValues(alpha: 0.5),
                            size: 11),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: _cursorPos.dx * (box.maxWidth - 24),
                  top: _cursorPos.dy * 236,
                  child: _cursorIcon(),
                ),
                if (_trailEnabled)
                  Positioned(
                    left: _cursorPos.dx * (box.maxWidth - 24) + 2,
                    top: _cursorPos.dy * 236 + 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            hex(AppColors.primary).withValues(alpha: 0.2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      });

  Widget _cursorIcon() {
    switch (_cursorStyle) {
      case 'crosshair':
        return Icon(Icons.add, size: 20, color: hex(AppColors.primary));
      case 'hand':
        return Icon(Icons.pan_tool, size: 18, color: hex(AppColors.primary));
      case 'dot':
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hex(AppColors.primary),
            boxShadow: [
              BoxShadow(
                color: hex(AppColors.primary).withValues(alpha: 0.4),
                blurRadius: 6,
              ),
            ],
          ),
        );
      default:
        return Icon(Icons.navigation, size: 20, color: hex(AppColors.primary));
    }
  }

  Widget _clickButtons() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: (_) => setState(() => _leftClick = true),
                onTap: _onTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: hex(_leftClick
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh)
                        .withValues(alpha: _leftClick ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Center(
                    child: Text('Left Click',
                        style: gfont(AppType.bodyMd,
                            color: hex(_leftClick
                                ? AppColors.primary
                                : AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _onLongPress,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Center(
                    child: Text('Right Click',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _scrollMode = !_scrollMode),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hex(_scrollMode
                          ? AppColors.signalEmerald
                          : AppColors.surfaceContainerHigh)
                      .withValues(alpha: _scrollMode ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(Icons.swap_vert,
                    size: 18,
                    color: hex(_scrollMode
                        ? AppColors.signalEmerald
                        : AppColors.onSurface)),
              ),
            ),
          ],
        ),
      );

  Widget _sensitivitySlider() => Container(
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
                Text('Sensitivity',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
                const Spacer(),
                Text('${_sensitivity.toStringAsFixed(1)}x',
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.primary),
                        size: 11,
                        weight: FontWeight.w700)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: hex(AppColors.primary),
                inactiveTrackColor:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                thumbColor: hex(AppColors.primary),
                overlayColor: hex(AppColors.primary).withValues(alpha: 0.1),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _sensitivity,
                min: 0.3,
                max: 3.0,
                onChanged: (v) => setState(() => _sensitivity = v),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Slow',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 9)),
                Text('Fast',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 9)),
              ],
            ),
          ],
        ),
      );

  Widget _cursorStylePicker() => Container(
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
            Text('Cursor Style',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: _styles.map((s) {
                final sel = s == _cursorStyle;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _cursorStyle = s),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: hex(sel
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh)
                            .withValues(alpha: sel ? 0.15 : 1),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: sel
                            ? Border.all(
                                color: hex(AppColors.primary)
                                    .withValues(alpha: 0.4))
                            : null,
                      ),
                      child: Column(
                        children: [
                          _styleIcon(s, sel),
                          const SizedBox(height: 4),
                          Text(s[0].toUpperCase() + s.substring(1),
                              style: gfont(AppType.bodySm,
                                  color: hex(sel
                                      ? AppColors.primary
                                      : AppColors.outline),
                                  size: 9,
                                  weight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _styleIcon(String style, bool sel) {
    final c = hex(sel ? AppColors.primary : AppColors.onSurface);
    switch (style) {
      case 'crosshair':
        return Icon(Icons.add, size: 18, color: c);
      case 'hand':
        return Icon(Icons.pan_tool, size: 16, color: c);
      case 'dot':
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        );
      default:
        return Icon(Icons.navigation, size: 18, color: c);
    }
  }

  Widget _optionsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            _toggleRow('Cursor Trail', _trailEnabled,
                (v) => setState(() => _trailEnabled = v)),
          ],
        ),
      );

  Widget _toggleRow(String label, bool val, ValueChanged<bool> onChanged) =>
      Row(
        children: [
          Text(label,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), size: 13)),
          const Spacer(),
          Switch(
            value: val,
            onChanged: onChanged,
            activeThumbColor: hex(AppColors.primary),
            inactiveTrackColor:
                hex(AppColors.outlineVariant).withValues(alpha: 0.3),
          ),
        ],
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border:
              Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mouse cursor mode translates touch movements into directional inputs at variable speed — ideal for navigating TV browsers and web content. Tap for click, long-press for context menu.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
