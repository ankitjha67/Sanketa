import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../native/wearable_bridge.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class WearableScreen extends StatefulWidget {
  const WearableScreen({super.key});

  @override
  State<WearableScreen> createState() => _WearableScreenState();
}

class _WearableScreenState extends State<WearableScreen> {
  WearableStatus _status = WearableStatus.disconnected;
  bool _available = false;
  bool _loading = true;
  String? _deviceName;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await WearableBridge.isAvailable();
    final status = await WearableBridge.getStatus();
    String? name;
    if (status == WearableStatus.connected) {
      name = await WearableBridge.getWearableName();
    }
    if (!mounted) return;
    setState(() {
      _available = available;
      _status = status;
      _deviceName = name;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Wearable Remote',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(hex(AppColors.primaryContainer))))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _statusCard(),
                    const SizedBox(height: AppSpacing.md),
                    _controlsCard(),
                    const SizedBox(height: AppSpacing.md),
                    _setupCard(),
                    const SizedBox(height: AppSpacing.md),
                    _infoCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statusCard() {
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    switch (_status) {
      case WearableStatus.connected:
        statusColor = hex(AppColors.signalEmerald);
        statusText = _deviceName != null
            ? 'Connected to $_deviceName'
            : 'Connected';
        statusIcon = Icons.watch;
      case WearableStatus.connecting:
        statusColor = hex(AppColors.tertiary);
        statusText = 'Connecting...';
        statusIcon = Icons.sync;
      case WearableStatus.disconnected:
        statusColor = hex(AppColors.outlineVariant);
        statusText = _available ? 'Not connected' : 'No wearable found';
        statusIcon = Icons.watch_off;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration:
          panel(borderColor: AppColors.primaryContainer, borderOpacity: 0.3),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, size: 32, color: statusColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(statusText,
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 16,
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            _status == WearableStatus.connected
                ? 'Your watch can control the TV'
                : 'Pair a Wear OS watch to use as a remote',
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant)),
          ),
          if (_status == WearableStatus.disconnected && _available) ...[
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: _pair,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.primaryContainer),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Pair Watch',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.surface),
                        weight: FontWeight.w600)),
              ),
            ),
          ],
          if (_status == WearableStatus.connected) ...[
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: _disconnect,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Disconnect',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.error),
                        weight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _controlsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Watch Controls',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('What your watch can do',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
            const SizedBox(height: AppSpacing.md),
            _controlRow(Icons.power_settings_new, 'Power',
                'Toggle TV on/off from your wrist'),
            _controlRow(Icons.volume_up, 'Volume',
                'Volume up/down with crown or tap'),
            _controlRow(Icons.volume_off, 'Mute',
                'Quick mute toggle'),
            _controlRow(Icons.navigation, 'D-Pad',
                'Up/Down/Left/Right navigation'),
            _controlRow(Icons.home, 'Home',
                'Return to TV home screen'),
            _controlRow(Icons.check_circle_outline, 'Select',
                'OK / confirm on the TV'),
          ],
        ),
      );

  Widget _controlRow(IconData icon, String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    hex(AppColors.primaryContainer).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon,
                  size: 16, color: hex(AppColors.primaryContainer)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w500)),
                  Text(desc,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _setupCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Setup Guide',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            _stepRow(1, 'Install Sanketa on your Wear OS watch'),
            _stepRow(2, 'Open the app on your watch'),
            _stepRow(3, 'Tap "Pair Watch" above on your phone'),
            _stepRow(4, 'Accept the connection on your watch'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: hex(AppColors.tertiary).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: hex(AppColors.tertiary)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Both devices must be on the same Wi-Fi network '
                      'or paired via Bluetooth.',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.tertiary), size: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _stepRow(int num, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color:
                    hex(AppColors.primaryContainer).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$num',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primaryContainer),
                        size: 11,
                        weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(text,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface))),
              ),
            ),
          ],
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration:
            panel(fill: AppColors.surfaceContainerLowest, borderOpacity: 0.2),
        child: Row(
          children: [
            Icon(Icons.watch,
                size: 18, color: hex(AppColors.outlineVariant)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Requires a Wear OS 3+ watch. watchOS support is planned. '
                'The watch app is a minimal remote — not a full UI.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 11),
              ),
            ),
          ],
        ),
      );

  Future<void> _pair() async {
    setState(() => _status = WearableStatus.connecting);
    final ok = await WearableBridge.startPairing();
    if (!mounted) return;
    if (ok) {
      final name = await WearableBridge.getWearableName();
      setState(() {
        _status = WearableStatus.connected;
        _deviceName = name;
      });
    } else {
      setState(() => _status = WearableStatus.disconnected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Could not pair. Make sure Sanketa is installed on your watch.'),
        backgroundColor: hex(AppColors.surfaceContainerHigh),
      ));
    }
  }

  Future<void> _disconnect() async {
    await WearableBridge.disconnect();
    if (!mounted) return;
    setState(() {
      _status = WearableStatus.disconnected;
      _deviceName = null;
    });
  }
}
