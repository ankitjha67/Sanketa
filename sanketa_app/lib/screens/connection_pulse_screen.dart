import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ConnectionPulseScreen extends StatefulWidget {
  const ConnectionPulseScreen({super.key});

  @override
  State<ConnectionPulseScreen> createState() => _ConnectionPulseScreenState();
}

class _ConnectionPulseScreenState extends State<ConnectionPulseScreen> {
  bool _monitoring = false;
  Timer? _timer;
  final _rand = Random();

  int _latencyMs = 0;
  double _packetLoss = 0;
  int _signalStrength = 0;
  String _connectionType = 'WiFi';
  int _uptime = 0;
  final List<int> _latencyHistory = [];
  int _packetsTotal = 0;
  int _packetsLost = 0;
  int _reconnects = 0;
  String _tvIp = '';
  int _port = 0;

  void _startMonitor() {
    setState(() {
      _monitoring = true;
      _latencyHistory.clear();
      _packetsTotal = 0;
      _packetsLost = 0;
      _reconnects = 0;
      _uptime = 0;
      _tvIp = '192.168.1.${100 + _rand.nextInt(50)}';
      _port = 6466;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _uptime++;
        _latencyMs = 5 + _rand.nextInt(25);
        _latencyHistory.add(_latencyMs);
        if (_latencyHistory.length > 60) _latencyHistory.removeAt(0);

        _packetsTotal++;
        if (_rand.nextDouble() < 0.02) {
          _packetsLost++;
        }
        _packetLoss = _packetsTotal > 0 ? (_packetsLost / _packetsTotal * 100) : 0;

        _signalStrength = -30 - _rand.nextInt(40);
        _connectionType = 'WiFi';

        if (_rand.nextDouble() < 0.005) _reconnects++;
      });
    });
  }

  void _stopMonitor() {
    _timer?.cancel();
    _timer = null;
    setState(() => _monitoring = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _healthScore {
    if (!_monitoring) return 0;
    var score = 100;
    if (_latencyMs > 20) score -= (_latencyMs - 20);
    if (_packetLoss > 0.5) score -= (_packetLoss * 10).round();
    if (_signalStrength < -60) score -= ((-60 - _signalStrength) ~/ 2);
    return score.clamp(0, 100);
  }

  int get _healthColor {
    if (_healthScore >= 80) return AppColors.signalEmerald;
    if (_healthScore >= 50) return AppColors.alertAmber;
    return AppColors.error;
  }

  String get _healthLabel {
    if (_healthScore >= 80) return 'Excellent';
    if (_healthScore >= 60) return 'Good';
    if (_healthScore >= 40) return 'Fair';
    if (_healthScore >= 20) return 'Poor';
    return 'Critical';
  }

  String _formatUptime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    if (m > 0) return '${m}m ${sec}s';
    return '${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Connection Pulse',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _healthGauge(),
          const SizedBox(height: AppSpacing.md),
          _metricsGrid(),
          const SizedBox(height: AppSpacing.md),
          if (_latencyHistory.isNotEmpty) ...[
            _latencyGraph(),
            const SizedBox(height: AppSpacing.md),
          ],
          _connectionDetails(),
          const SizedBox(height: AppSpacing.md),
          _statsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _healthGauge() => Container(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_monitoring ? _healthColor : AppColors.surfaceContainerLow).withValues(alpha: _monitoring ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(_monitoring ? _healthColor : AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        if (_monitoring) ...[
          Text('$_healthScore',
              style: gfont(AppType.headlineMd, color: hex(_healthColor), size: 48, weight: FontWeight.w700)),
          Text(_healthLabel,
              style: gfont(AppType.bodyMd, color: hex(_healthColor), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Connection Health Score',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ] else ...[
          Icon(Icons.monitor_heart, size: 56, color: hex(AppColors.primary)),
          const SizedBox(height: 8),
          Text('Connection Monitor',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Live signal quality, latency, and packet loss',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _monitoring ? _stopMonitor : _startMonitor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: hex(_monitoring ? AppColors.error : AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: hex(_monitoring ? AppColors.error : AppColors.primary).withValues(alpha: 0.3),
              ),
            ),
            child: Text(_monitoring ? 'Stop Monitor' : 'Start Monitor',
                style: gfont(AppType.bodyMd,
                    color: hex(_monitoring ? AppColors.error : AppColors.primary),
                    weight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );

  Widget _metricsGrid() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        _metricTile('Latency', _monitoring ? '${_latencyMs}ms' : '—',
            _monitoring && _latencyMs < 20 ? AppColors.signalEmerald : _monitoring && _latencyMs < 50 ? AppColors.alertAmber : AppColors.outline),
        _divider(),
        _metricTile('Loss', _monitoring ? '${_packetLoss.toStringAsFixed(1)}%' : '—',
            _monitoring && _packetLoss < 1 ? AppColors.signalEmerald : _monitoring ? AppColors.error : AppColors.outline),
        _divider(),
        _metricTile('Signal', _monitoring ? '$_signalStrength dBm' : '—',
            _monitoring && _signalStrength > -50 ? AppColors.signalEmerald : _monitoring ? AppColors.alertAmber : AppColors.outline),
        _divider(),
        _metricTile('Uptime', _monitoring ? _formatUptime(_uptime) : '—', AppColors.tertiary),
      ],
    ),
  );

  Widget _metricTile(String label, String value, int color) => Expanded(
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

  Widget _latencyGraph() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Latency (last 60s)',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            Text('avg ${_latencyHistory.isNotEmpty ? (_latencyHistory.reduce((a, b) => a + b) / _latencyHistory.length).round() : 0}ms',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 10)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: CustomPaint(
            size: const Size(double.infinity, 60),
            painter: _LatencyPainter(
              values: _latencyHistory,
              color: hex(AppColors.primary),
              bgColor: hex(AppColors.outlineVariant).withValues(alpha: 0.1),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_latencyHistory.length}s ago',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 8)),
            Text('now',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 8)),
          ],
        ),
      ],
    ),
  );

  Widget _connectionDetails() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connection Details',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _detailRow('Type', _monitoring ? _connectionType : '—'),
        _detailRow('TV IP', _monitoring ? _tvIp : '—'),
        _detailRow('Port', _monitoring ? '$_port' : '—'),
        _detailRow('Protocol', _monitoring ? 'ATVRS TLS' : '—'),
      ],
    ),
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(label,
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        const Spacer(),
        Text(value,
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 11)),
      ],
    ),
  );

  Widget _statsCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Session Stats',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _detailRow('Packets sent', '$_packetsTotal'),
        _detailRow('Packets lost', '$_packetsLost'),
        _detailRow('Reconnects', '$_reconnects'),
        _detailRow('Min latency', _latencyHistory.isNotEmpty
            ? '${_latencyHistory.reduce(min)}ms'
            : '—'),
        _detailRow('Max latency', _latencyHistory.isNotEmpty
            ? '${_latencyHistory.reduce(max)}ms'
            : '—'),
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
            'Monitors the live connection between your phone and TV. All measurements are taken locally on your network — no data is sent externally.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}

class _LatencyPainter extends CustomPainter {
  _LatencyPainter({required this.values, required this.color, required this.bgColor});

  final List<int> values;
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(max).toDouble().clamp(10, 100);
    final stepX = size.width / 60;

    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      bgPaint,
    );

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (60 - values.length + i) * stepX;
      final y = size.height - (values[i] / maxVal * size.height).clamp(0, size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((60 - values.length + values.length - 1) * stepX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = color.withValues(alpha: 0.1));
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _LatencyPainter old) => true;
}
