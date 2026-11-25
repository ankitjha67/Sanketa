import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class MediaInfoScreen extends StatefulWidget {
  const MediaInfoScreen({super.key});

  @override
  State<MediaInfoScreen> createState() => _MediaInfoScreenState();
}

class _MediaInfoScreenState extends State<MediaInfoScreen> {
  String _inputLabel = 'HDMI 1';
  String _resolution = '3840 × 2160';
  String _hdr = 'HDR10';
  String _framerate = '60 Hz';
  String _audioFormat = 'Dolby Digital 5.1';
  String _audioOutput = 'TV Speakers';
  String _aspectRatio = '16:9';
  String _colourSpace = 'BT.2020';
  bool _loading = true;

  final _resolutions = ['720 × 480', '1280 × 720', '1920 × 1080', '3840 × 2160', '7680 × 4320'];
  final _hdrModes = ['SDR', 'HDR10', 'HDR10+', 'Dolby Vision', 'HLG'];
  final _framerates = ['24 Hz', '30 Hz', '50 Hz', '60 Hz', '120 Hz'];
  final _audioFormats = ['Stereo PCM', 'Dolby Digital 5.1', 'Dolby Atmos', 'DTS', 'DTS:X', 'AAC'];
  final _audioOutputs = ['TV Speakers', 'Soundbar (ARC)', 'Bluetooth', 'Optical', 'Headphones'];
  final _aspects = ['4:3', '16:9', '21:9', 'Auto'];
  final _colourSpaces = ['BT.709', 'BT.2020', 'DCI-P3'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/media_info.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _inputLabel = j['inputLabel'] as String? ?? _inputLabel;
        _resolution = j['resolution'] as String? ?? _resolution;
        _hdr = j['hdr'] as String? ?? _hdr;
        _framerate = j['framerate'] as String? ?? _framerate;
        _audioFormat = j['audioFormat'] as String? ?? _audioFormat;
        _audioOutput = j['audioOutput'] as String? ?? _audioOutput;
        _aspectRatio = j['aspectRatio'] as String? ?? _aspectRatio;
        _colourSpace = j['colourSpace'] as String? ?? _colourSpace;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'inputLabel': _inputLabel,
      'resolution': _resolution,
      'hdr': _hdr,
      'framerate': _framerate,
      'audioFormat': _audioFormat,
      'audioOutput': _audioOutput,
      'aspectRatio': _aspectRatio,
      'colourSpace': _colourSpace,
    }));
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
        title: Text('Media Info',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: () => RemoteScope.of(context).key(core.Key.info),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.info, size: 20, color: hex(AppColors.primary)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _videoSection(),
          const SizedBox(height: AppSpacing.lg),
          _audioSection(),
          const SizedBox(height: AppSpacing.lg),
          _refreshButton(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.tv, size: 28, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_inputLabel,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 15)),
              const SizedBox(height: 2),
              Text('$_resolution  $_hdr  $_framerate',
                  style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 11, weight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(_audioFormat,
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _videoSection() => _section('Video', [
    _row(Icons.aspect_ratio, 'Resolution', _resolution, _resolutions, (v) {
      setState(() => _resolution = v);
      _save();
    }),
    _row(Icons.hdr_on, 'HDR Mode', _hdr, _hdrModes, (v) {
      setState(() => _hdr = v);
      _save();
    }),
    _row(Icons.speed, 'Frame Rate', _framerate, _framerates, (v) {
      setState(() => _framerate = v);
      _save();
    }),
    _row(Icons.crop_16_9, 'Aspect Ratio', _aspectRatio, _aspects, (v) {
      setState(() => _aspectRatio = v);
      _save();
    }),
    _row(Icons.color_lens, 'Colour Space', _colourSpace, _colourSpaces, (v) {
      setState(() => _colourSpace = v);
      _save();
    }),
  ]);

  Widget _audioSection() => _section('Audio', [
    _row(Icons.speaker, 'Audio Format', _audioFormat, _audioFormats, (v) {
      setState(() => _audioFormat = v);
      _save();
    }),
    _row(Icons.output, 'Audio Output', _audioOutput, _audioOutputs, (v) {
      setState(() => _audioOutput = v);
      _save();
    }),
  ]);

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Divider(height: 16, thickness: 0.5, color: hex(AppColors.outlineVariant).withValues(alpha: 0.15));
          }
          return children[i ~/ 2];
        }),
      ],
    ),
  );

  Widget _row(IconData icon, String label, String value, List<String> options, ValueChanged<String> onChanged) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pickOption(label, value, options, onChanged),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(AppColors.outline)),
            const SizedBox(width: 10),
            Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 12)),
            const Spacer(),
            Text(value,
                style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 11, weight: FontWeight.w500)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14, color: hex(AppColors.outline)),
          ],
        ),
      );

  void _pickOption(String title, String current, List<String> options, ValueChanged<String> onChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...options.map((o) => GestureDetector(
              onTap: () {
                onChanged(o);
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: o == current
                      ? hex(AppColors.primaryContainer).withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(o,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: o == current ? FontWeight.w600 : FontWeight.w400)),
                    ),
                    if (o == current)
                      Icon(Icons.check, size: 16, color: hex(AppColors.primary)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _refreshButton() => GestureDetector(
    onTap: () => RemoteScope.of(context).key(core.Key.info),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh, size: 16, color: hex(AppColors.onSurface)),
          const SizedBox(width: 8),
          Text('Request Info from TV',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w500)),
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
            'View and manually track the current input signal details. Tap "Request Info" to send the Info key to your TV for on-screen display.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
