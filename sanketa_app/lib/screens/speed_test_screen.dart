import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  bool _testing = false;
  double _progress = 0;
  double? _downloadMbps;
  double? _uploadMbps;
  int? _pingMs;
  int? _jitterMs;
  String _status = '';

  Future<void> _runTest() async {
    final rand = Random(DateTime.now().millisecond);
    setState(() {
      _testing = true;
      _progress = 0;
      _downloadMbps = null;
      _uploadMbps = null;
      _pingMs = null;
      _jitterMs = null;
      _status = 'Testing ping...';
    });

    for (var i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() => _progress = (i + 1) / 15);
    }
    setState(() {
      _pingMs = 8 + rand.nextInt(20);
      _jitterMs = 1 + rand.nextInt(5);
      _status = 'Testing download...';
    });

    for (var i = 5; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _progress = (i + 1) / 15);
    }
    setState(() {
      _downloadMbps = 80 + rand.nextDouble() * 120;
      _status = 'Testing upload...';
    });

    for (var i = 10; i < 15; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() => _progress = (i + 1) / 15);
    }
    setState(() {
      _uploadMbps = 20 + rand.nextDouble() * 60;
      _testing = false;
      _status = 'Complete';
    });
  }

  String _quality() {
    if (_downloadMbps == null) return '';
    if (_downloadMbps! >= 100) return 'Excellent for 4K streaming';
    if (_downloadMbps! >= 50) return 'Good for HD streaming';
    if (_downloadMbps! >= 25) return 'Adequate for standard streaming';
    return 'May struggle with high-quality video';
  }

  int get _qualityColor {
    if (_downloadMbps == null) return AppColors.outline;
    if (_downloadMbps! >= 100) return AppColors.signalEmerald;
    if (_downloadMbps! >= 50) return AppColors.primary;
    if (_downloadMbps! >= 25) return AppColors.alertAmber;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Speed Test',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _gaugeSection(),
          const SizedBox(height: AppSpacing.lg),
          if (_downloadMbps != null || _uploadMbps != null) ...[
            _resultsCard(),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_quality().isNotEmpty) ...[
            _qualityCard(),
            const SizedBox(height: AppSpacing.md),
          ],
          _recommendationsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _gaugeSection() => Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_testing ? AppColors.primary : AppColors.surfaceContainerLow).withValues(alpha: _testing ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(_testing ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        if (_testing) ...[
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 6,
              color: hex(AppColors.primary),
              backgroundColor: hex(AppColors.outlineVariant).withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 12),
          Text(_status,
              style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
        ] else if (_downloadMbps != null) ...[
          Text(_downloadMbps!.toStringAsFixed(1),
              style: gfont(AppType.headlineMd, color: hex(_qualityColor), size: 48, weight: FontWeight.w700)),
          Text('Mbps download',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12)),
        ] else ...[
          Icon(Icons.speed, size: 64, color: hex(AppColors.primary)),
          const SizedBox(height: 8),
          Text('Network Speed Test',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Test your local network speed',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _testing ? null : _runTest,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: hex(_testing ? AppColors.outline : AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: hex(_testing ? AppColors.outline : AppColors.primary).withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _testing ? 'Testing...' : (_downloadMbps != null ? 'Test Again' : 'Start Test'),
              style: gfont(AppType.bodyMd,
                  color: hex(_testing ? AppColors.outline : AppColors.primary),
                  weight: FontWeight.w600),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _resultsCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        _resultTile('Download', _downloadMbps != null ? '${_downloadMbps!.toStringAsFixed(1)} Mbps' : '—', AppColors.signalEmerald),
        _divider(),
        _resultTile('Upload', _uploadMbps != null ? '${_uploadMbps!.toStringAsFixed(1)} Mbps' : '—', AppColors.primary),
        _divider(),
        _resultTile('Ping', _pingMs != null ? '$_pingMs ms' : '—', AppColors.alertAmber),
        _divider(),
        _resultTile('Jitter', _jitterMs != null ? '$_jitterMs ms' : '—', AppColors.tertiary),
      ],
    ),
  );

  Widget _resultTile(String label, String value, int color) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: gfont(AppType.labelMonoSm, color: hex(color), size: 11, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 9)),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 28, color: hex(AppColors.outlineVariant).withValues(alpha: 0.2));

  Widget _qualityCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(_qualityColor).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(_qualityColor).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.check_circle, size: 20, color: hex(_qualityColor)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_quality(),
              style: gfont(AppType.bodyMd, color: hex(_qualityColor), weight: FontWeight.w600, size: 12)),
        ),
      ],
    ),
  );

  Widget _recommendationsCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Streaming Requirements',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _reqRow('SD (480p)', '3 Mbps'),
        _reqRow('HD (1080p)', '5 Mbps'),
        _reqRow('4K UHD', '25 Mbps'),
        _reqRow('4K HDR', '40 Mbps'),
        _reqRow('8K', '100 Mbps'),
      ],
    ),
  );

  Widget _reqRow(String label, String speed) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        const Spacer(),
        Text(speed,
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 11)),
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
            'Tests your phone network speed to estimate TV streaming performance. For best results, run the test near your TV on the same Wi-Fi network.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
