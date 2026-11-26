import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class MirrorQrScreen extends StatefulWidget {
  const MirrorQrScreen({super.key});

  @override
  State<MirrorQrScreen> createState() => _MirrorQrScreenState();
}

class _MirrorQrScreenState extends State<MirrorQrScreen> {
  bool _generated = false;
  int _protocolIndex = 0;

  static const _protocols = [
    ('Miracast', Icons.cast, 'Wi-Fi Direct screen mirroring'),
    ('AirPlay', Icons.airplay, 'Apple device mirroring'),
    ('Chromecast', Icons.cast_connected, 'Google Cast protocol'),
  ];

  static const _steps = [
    'Ensure phone and TV are on the same Wi-Fi',
    'Open mirroring on your TV (Settings → Display)',
    'Scan the QR code with your phone camera',
    'Accept the connection prompt on TV',
  ];

  final _mockIp = '192.168.1.42';
  final _mockPort = '7236';

  String get _connectionUrl =>
      '${_protocols[_protocolIndex].$1.toLowerCase()}://$_mockIp:$_mockPort';

  void _generate() {
    HapticFeedback.mediumImpact();
    setState(() => _generated = true);
  }

  void _reset() {
    setState(() => _generated = false);
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: _connectionUrl));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Connection URL copied'),
        duration: Duration(seconds: 1),
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
        title: Text('Mirror QR',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _protocolSelector(),
          const SizedBox(height: AppSpacing.lg),
          if (_generated) ...[
            _qrDisplay(),
            const SizedBox(height: AppSpacing.md),
            _connectionInfo(),
            const SizedBox(height: AppSpacing.md),
            _resetButton(),
          ] else
            _generateButton(),
          const SizedBox(height: AppSpacing.lg),
          _stepsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.qr_code_2, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Quick Mirror Setup',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Generate a QR code for instant screen mirroring connection',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _protocolSelector() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Protocol',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          ..._protocols.asMap().entries.map((e) {
            final active = e.key == _protocolIndex;
            final p = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => setState(() {
                  _protocolIndex = e.key;
                  _generated = false;
                }),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: hex(active
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(active
                              ? AppColors.primary
                              : AppColors.outlineVariant)
                          .withValues(alpha: active ? 0.4 : 0.15),
                      width: active ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(p.$2,
                          size: 20,
                          color: hex(active
                              ? AppColors.primary
                              : AppColors.outline)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.$1,
                                style: gfont(AppType.bodyMd,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600,
                                    size: 13)),
                            Text(p.$3,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline),
                                    size: 10)),
                          ],
                        ),
                      ),
                      Icon(
                        active
                            ? Icons.check_circle
                            : Icons.radio_button_off,
                        size: 20,
                        color: hex(active
                            ? AppColors.primary
                            : AppColors.outline),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _qrDisplay() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: CustomPaint(
                painter: _QrPlaceholderPainter(),
                size: const Size(180, 180),
              ),
            ),
            const SizedBox(height: 12),
            Text('Scan with phone camera',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _connectionInfo() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.link, size: 16, color: hex(AppColors.signalEmerald)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connection URL',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 10)),
                  Text(_connectionUrl,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _copyUrl,
              child:
                  Icon(Icons.copy, size: 16, color: hex(AppColors.outline)),
            ),
          ],
        ),
      );

  Widget _generateButton() => GestureDetector(
        onTap: _generate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Generate QR Code',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _resetButton() => GestureDetector(
        onTap: _reset,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(AppColors.outline).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Center(
            child: Text('Generate New Code',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline),
                    weight: FontWeight.w600,
                    size: 11)),
          ),
        ),
      );

  Widget _stepsCard() => Container(
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
            Text('How to Mirror',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: hex(AppColors.primary).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: gfont(AppType.bodySm,
                                  color: hex(AppColors.primary),
                                  weight: FontWeight.w700,
                                  size: 9)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(e.value,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurface), size: 11)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
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
                'Generate a QR code for quick screen mirroring setup. Supports Miracast, AirPlay, and Chromecast protocols. All connection data stays on your local network.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _QrPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 25;

    void drawSquare(int x, int y, int s) {
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, s * cellSize, s * cellSize),
        paint,
      );
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(
            (x + 1) * cellSize, (y + 1) * cellSize, (s - 2) * cellSize, (s - 2) * cellSize),
        whitePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
            (x + 2) * cellSize, (y + 2) * cellSize, (s - 4) * cellSize, (s - 4) * cellSize),
        paint,
      );
    }

    drawSquare(1, 1, 7);
    drawSquare(17, 1, 7);
    drawSquare(1, 17, 7);

    final rng = [
      (10, 1), (12, 2), (11, 3), (13, 4), (10, 5), (14, 6),
      (9, 10), (11, 11), (13, 12), (10, 13), (12, 14),
      (1, 10), (3, 11), (5, 12), (2, 13), (4, 14),
      (17, 10), (19, 11), (21, 12), (18, 13), (20, 14),
      (10, 17), (12, 18), (14, 19), (11, 20), (13, 21),
    ];
    for (final (x, y) in rng) {
      canvas.drawRect(
        Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
