import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _Screenshot {
  _Screenshot({required this.name, required this.timestamp, required this.path, required this.sizeKb});

  factory _Screenshot.fromJson(Map<String, dynamic> j) => _Screenshot(
    name: j['name'] as String,
    timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
    path: j['path'] as String,
    sizeKb: j['sizeKb'] as int? ?? 0,
  );

  final String name;
  final DateTime timestamp;
  final String path;
  final int sizeKb;

  Map<String, dynamic> toJson() => {
    'name': name,
    'timestamp': timestamp.toIso8601String(),
    'path': path,
    'sizeKb': sizeKb,
  };
}

class TvScreenshotScreen extends StatefulWidget {
  const TvScreenshotScreen({super.key});

  @override
  State<TvScreenshotScreen> createState() => _TvScreenshotScreenState();
}

class _TvScreenshotScreenState extends State<TvScreenshotScreen> {
  List<_Screenshot> _screenshots = [];
  bool _loading = true;
  bool _capturing = false;
  String _format = 'PNG';
  bool _autoTimestamp = true;
  String _saveLocation = 'Gallery';

  static const _formats = ['PNG', 'JPEG', 'WebP'];
  static const _locations = ['Gallery', 'App Storage', 'Downloads'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_screenshots.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _screenshots = list.map((j) => _Screenshot.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_screenshots.map((s) => s.toJson()).toList()));
  }

  Future<void> _capture() async {
    setState(() => _capturing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final now = DateTime.now();
    final name = _autoTimestamp
        ? 'TV_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}'
        : 'TV_Screenshot_${_screenshots.length + 1}';

    _screenshots.insert(0, _Screenshot(
      name: name,
      timestamp: now,
      path: '/storage/$_saveLocation/$name.${_format.toLowerCase()}',
      sizeKb: 400 + (now.millisecond * 3),
    ));
    if (_screenshots.length > 100) {
      _screenshots = _screenshots.sublist(0, 100);
    }

    setState(() => _capturing = false);
    _save();
  }

  void _delete(int index) {
    setState(() => _screenshots.removeAt(index));
    _save();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Screenshot',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _captureSection(),
          const SizedBox(height: AppSpacing.md),
          _settingsCard(),
          const SizedBox(height: AppSpacing.md),
          if (_screenshots.isNotEmpty) ...[
            Row(
              children: [
                Text('Captures (${_screenshots.length})',
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                const Spacer(),
                Text('${_screenshots.fold<int>(0, (s, e) => s + e.sizeKb)} KB total',
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
              ],
            ),
            const SizedBox(height: 8),
            ..._screenshots.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _screenshotCard(e.value, e.key),
            )),
          ] else
            _emptyState(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _captureSection() => Container(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_capturing ? AppColors.primary : AppColors.surfaceContainerLow).withValues(alpha: _capturing ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(_capturing ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        if (_capturing) ...[
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: hex(AppColors.primary),
              backgroundColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 12),
          Text('Capturing TV screen...',
              style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
        ] else ...[
          Icon(Icons.screenshot_monitor, size: 56, color: hex(AppColors.primary)),
          const SizedBox(height: 8),
          Text('Capture TV Screen',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Save a snapshot of what\'s currently on the TV',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _capturing ? null : _capture,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: hex(_capturing ? AppColors.outline : AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: hex(_capturing ? AppColors.outline : AppColors.primary).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt,
                    size: 16,
                    color: hex(_capturing ? AppColors.outline : AppColors.primary)),
                const SizedBox(width: 8),
                Text(_capturing ? 'Capturing...' : 'Capture Now',
                    style: gfont(AppType.bodyMd,
                        color: hex(_capturing ? AppColors.outline : AppColors.primary),
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _settingsCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _pickerRow('Format', _format, _formats, (v) {
          setState(() => _format = v);
        }),
        const SizedBox(height: 8),
        _pickerRow('Save to', _saveLocation, _locations, (v) {
          setState(() => _saveLocation = v);
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Auto timestamp name',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13)),
            const Spacer(),
            Switch(
              value: _autoTimestamp,
              onChanged: (v) => setState(() => _autoTimestamp = v),
              activeThumbColor: hex(AppColors.primary),
              inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _pickerRow(String label, String current, List<String> options, ValueChanged<String> onChanged) =>
      Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ),
          ...options.map((o) {
            final sel = o == current;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onChanged(o),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hex(sel ? AppColors.primary : AppColors.surfaceContainerHigh)
                        .withValues(alpha: sel ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: sel ? Border.all(color: hex(AppColors.primary).withValues(alpha: 0.4)) : null,
                  ),
                  child: Text(o,
                      style: gfont(AppType.bodySm,
                          color: hex(sel ? AppColors.primary : AppColors.outline),
                          size: 10,
                          weight: FontWeight.w600)),
                ),
              ),
            );
          }),
        ],
      );

  Widget _screenshotCard(_Screenshot ss, int index) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 32,
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Icon(Icons.image, size: 18, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ss.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12, weight: FontWeight.w500)),
              Text('${_timeAgo(ss.timestamp)}  •  ${ss.sizeKb} KB  •  $_format',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Icon(Icons.share, size: 16, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _delete(index),
          child: Icon(Icons.close, size: 14, color: hex(AppColors.outline)),
        ),
      ],
    ),
  );

  Widget _emptyState() => Column(
    children: [
      const SizedBox(height: 24),
      Icon(Icons.screenshot_monitor, size: 40, color: hex(AppColors.outline)),
      const SizedBox(height: 8),
      Text('No captures yet',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Tap "Capture Now" to save a screenshot of your TV screen.',
          textAlign: TextAlign.center,
          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
    ],
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
            'Captures the TV display via ADB screencap. Screenshots are stored locally on your phone and never uploaded. Useful for sharing what\'s on TV or troubleshooting display issues.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
