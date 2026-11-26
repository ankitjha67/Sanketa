import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class QrConnectScreen extends StatefulWidget {
  const QrConnectScreen({super.key});

  @override
  State<QrConnectScreen> createState() => _QrConnectScreenState();
}

class _QrConnectScreenState extends State<QrConnectScreen>
    with SingleTickerProviderStateMixin {
  bool _scanning = false;
  bool _generating = false;
  String? _generatedCode;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startScan() => setState(() => _scanning = true);
  void _stopScan() => setState(() => _scanning = false);

  void _generateCode() {
    final code = List.generate(6, (_) => Random().nextInt(10)).join();
    setState(() {
      _generating = true;
      _generatedCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('QR Connect',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('Connection Methods',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          _methodCard(
            icon: Icons.qr_code_scanner,
            title: 'Scan TV QR Code',
            subtitle: 'Point your camera at the QR code shown on your TV',
            color: AppColors.primary,
            onTap: _startScan,
          ),
          const SizedBox(height: 8),
          _methodCard(
            icon: Icons.qr_code_2,
            title: 'Show QR Code',
            subtitle: 'Display a QR code for another device to scan',
            color: AppColors.tertiary,
            onTap: _generateCode,
          ),
          const SizedBox(height: 8),
          _methodCard(
            icon: Icons.pin,
            title: 'Enter PIN Code',
            subtitle: 'Type the 6-digit code shown on your TV',
            color: AppColors.alertAmber,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _methodCard(
            icon: Icons.nfc,
            title: 'NFC Tap',
            subtitle: 'Tap your phone against a compatible TV',
            color: AppColors.signalEmerald,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_scanning) _scannerView(),
          if (_generating && _generatedCode != null) _qrDisplay(),
          _recentDevices(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => AnimatedBuilder(
    animation: _pulseCtrl,
    builder: (context, child) {
      final scale = 1.0 + (_pulseCtrl.value * 0.03);
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hex(AppColors.primary).withValues(alpha: 0.08),
              hex(AppColors.tertiary).withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Icon(Icons.qr_code, size: 32, color: hex(AppColors.primary)),
              ),
            ),
            const SizedBox(height: 12),
            Text('Quick Connect',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 16)),
            const SizedBox(height: 4),
            Text(
              'Connect to your TV instantly with QR code, PIN, or NFC',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );
    },
  );

  Widget _methodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hex(color).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 20, color: hex(color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
                Text(subtitle,
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: hex(AppColors.outline)),
        ],
      ),
    ),
  );

  Widget _scannerView() => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    height: 200,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
    ),
    child: Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 40, color: hex(AppColors.primary).withValues(alpha: 0.5)),
              const SizedBox(height: 8),
              Text('Camera preview will appear here',
                  style: gfont(AppType.bodySm, color: hex(AppColors.primary).withValues(alpha: 0.6), size: 11)),
              Text('Point at QR code on TV',
                  style: gfont(AppType.bodySm, color: Colors.white54, size: 10)),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _stopScan,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _qrDisplay() => Container(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Icon(Icons.qr_code_2, size: 100, color: hex(AppColors.onSurface)),
          ),
        ),
        const SizedBox(height: 12),
        Text('Scan this code from another device',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: hex(AppColors.tertiary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.full),
          ),
          child: Text('PIN: $_generatedCode',
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.tertiary), size: 16, weight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Text('Expires in 5 minutes',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
      ],
    ),
  );

  Widget _recentDevices() => Container(
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
            Icon(Icons.devices, size: 16, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            Text('Previously Connected',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 12)),
          ],
        ),
        const SizedBox(height: 10),
        _deviceRow('Living Room TV', 'Samsung', '2 hours ago', true),
        const SizedBox(height: 6),
        _deviceRow('Bedroom TV', 'TCL Roku', 'Yesterday', false),
        const SizedBox(height: 6),
        _deviceRow('Office Shield', 'NVIDIA Shield', '3 days ago', false),
      ],
    ),
  );

  Widget _deviceRow(String name, String brand, String time, bool online) => Row(
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: hex(online ? AppColors.signalEmerald : AppColors.outline).withValues(alpha: online ? 1 : 0.3),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 11)),
            Text(brand, style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
          ],
        ),
      ),
      Text(time, style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: hex(online ? AppColors.signalEmerald : AppColors.outline).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Text(
          online ? 'Connect' : 'Reconnect',
          style: gfont(AppType.bodySm,
              color: hex(online ? AppColors.signalEmerald : AppColors.outline), size: 9, weight: FontWeight.w600),
        ),
      ),
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
            'QR Connect pairs your phone with a TV instantly. No manual IP entry needed. All pairing happens over your local network.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
