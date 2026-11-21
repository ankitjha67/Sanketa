import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';
import '../widgets/ir_setup_wizard.dart';
import 'app_launcher_screen.dart';
import 'debloat_screen.dart';
import 'performance_screen.dart';
import 'settings_screen.dart';

String _shortName(String name) => name.replaceAll(RegExp(r'-[0-9a-f]{20,}$'), '');

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _pairing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = RemoteScope.of(context);
    if (c.scanState == ScanState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && c.scanState == ScanState.idle) {
          c.startScan();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Column(
      children: [
        _header(context, c),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.isConnecting) ...[
                      _connectingDevice(c),
                      const SizedBox(height: AppSpacing.xl),
                    ] else if (c.connectionError != null) ...[
                      _connectionFailed(c),
                      const SizedBox(height: AppSpacing.xl),
                    ] else if (c.isConnected) ...[
                      _connectedDevice(c),
                      const SizedBox(height: AppSpacing.xl),
                      if (_isAndroidTv(c)) ...[
                        _tvToolsSection(context, c),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ] else ...[
                      _notConnected(),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    _discoverySection(c),
                    const SizedBox(height: AppSpacing.xl),
                    _irRemoteSection(context, c),
                    const SizedBox(height: AppSpacing.md),
                    _addDeviceButton(context, c),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, RemoteController c) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: hex(AppColors.surface),
      border: Border(
        bottom: BorderSide(
          color: hex(AppColors.outlineVariant).withValues(alpha: 0.6),
        ),
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 448),
        child: Row(
          children: [
            Icon(
              Icons.devices,
              size: 24,
              color: hex(AppColors.primaryContainer),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Devices',
                style: gfont(
                  AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      RemoteScope(controller: c, child: const SettingsScreen()),
                ),
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    Icons.settings,
                    size: 20,
                    color: hex(AppColors.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _connectingDevice(RemoteController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: hex(AppColors.primaryContainer),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.deviceName,
                  style: gfont(
                    AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Connecting...',
                  style: gfont(
                    AppType.labelMonoSm,
                    color: hex(AppColors.primaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectionFailed(RemoteController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(AppColors.error).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 24,
                  color: hex(AppColors.error),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.deviceName,
                      style: gfont(
                        AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connection failed',
                      style: gfont(
                        AppType.labelMonoSm,
                        color: hex(AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => c.retryConnection(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    'Retry',
                    style: gfont(
                      AppType.bodySm,
                      color: hex(AppColors.primaryContainer),
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerLowest),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              c.connectionError!,
              style: gfont(
                AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant),
              ),
            ),
          ),
          if (c.needsAtvrsPairing) ...[
            const SizedBox(height: AppSpacing.sm),
            _atvrsPairingBanner(c),
          ],
        ],
      ),
    );
  }

  Widget _notConnected() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: hex(AppColors.outlineVariant).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              Icons.tv_off,
              size: 24,
              color: hex(AppColors.outlineVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No device connected',
                  style: gfont(
                    AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap a device below to connect',
                  style: gfont(
                    AppType.labelMonoSm,
                    color: hex(AppColors.outline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectedDevice(RemoteController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONNECTED',
          style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.tv,
                  size: 24,
                  color: hex(AppColors.primaryContainer),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.deviceName,
                      style: gfont(
                        AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        PulseDot(color: hex(AppColors.signalEmerald), size: 6),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Connected · ${c.transportBadge}',
                            overflow: TextOverflow.ellipsis,
                            style: gfont(
                              AppType.labelMonoSm,
                              color: hex(AppColors.signalEmerald),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  'Remote',
                  style: gfont(
                    AppType.bodySm,
                    color: hex(AppColors.primaryContainer),
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (c.needsAtvrsPairing) ...[
          const SizedBox(height: AppSpacing.sm),
          _atvrsPairingBanner(c),
        ],
      ],
    );
  }

  Widget _atvrsPairingBanner(RemoteController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.primaryContainer).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                c.pairingIsForFullControl ? Icons.link : Icons.keyboard,
                size: 20,
                color: hex(AppColors.primaryContainer),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  c.pairingIsForFullControl
                      ? 'Pair to control this TV'
                      : 'Pair for keyboard typing',
                  style: gfont(
                    AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            c.pairingIsForFullControl
                ? 'This TV requires pairing before it can be controlled. '
                    'A code will appear on the TV screen.'
                : 'Pair with your TV to type directly from your phone keyboard. '
                    'A code will appear on the TV screen.',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
          ),
          if (c.pairingError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: hex(AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                c.pairingError!,
                style: gfont(AppType.bodySm, color: hex(AppColors.error), size: 12),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pairing ? null : () => _startDevicePairing(c),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Center(
                child: _pairing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: hex(AppColors.onPrimaryContainer),
                        ),
                      )
                    : Text(
                        'Pair Now',
                        style: gfont(
                          AppType.bodyMd,
                          color: hex(AppColors.onPrimaryContainer),
                          weight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDevicePairing(RemoteController c) async {
    setState(() => _pairing = true);
    final ok = await c.pairAtvrs(() async {
      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PairingPinDialog(),
      );
      return pin ?? '';
    });
    if (mounted) {
      setState(() => _pairing = false);
      if (ok) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(
              'Paired! Keyboard typing is now enabled.',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
            ),
            backgroundColor: hex(AppColors.surfaceContainerHigh),
          ));
      }
    }
  }

  bool _isAndroidTv(RemoteController c) {
    final brand = c.selectedDevice?.device.brand;
    return brand == core.BrandFamily.androidTv ||
        brand == core.BrandFamily.bravia ||
        brand == core.BrandFamily.fireTv;
  }

  Widget _tvToolsSection(BuildContext context, RemoteController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TV TOOLS',
            style: gfont(AppType.labelMonoSm,
                color: hex(AppColors.outline))),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(
              child: _tvToolCard(
            context,
            c,
            icon: Icons.cleaning_services,
            label: 'Debloat',
            subtitle: 'Remove bloatware',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => RemoteScope(
                    controller: c, child: const DebloatScreen()))),
          )),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _tvToolCard(
            context,
            c,
            icon: Icons.speed,
            label: 'Performance',
            subtitle: 'CPU, RAM, storage',
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => RemoteScope(
                    controller: c, child: const PerformanceScreen()))),
          )),
        ]),
        const SizedBox(height: AppSpacing.sm),
        _tvToolCard(
          context,
          c,
          icon: Icons.apps,
          label: 'App Launcher',
          subtitle: 'Browse & launch TV apps',
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => RemoteScope(
                  controller: c, child: const AppLauncherScreen()))),
        ),
      ],
    );
  }

  Widget _tvToolCard(
    BuildContext context,
    RemoteController c, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: panel(
            fill: AppColors.surfaceContainerLowest,
            radius: AppRadii.md,
            borderOpacity: 0.2),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 18, color: hex(AppColors.primaryContainer)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        size: 13,
                        weight: FontWeight.w500)),
                Text(subtitle,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurfaceVariant), size: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: 18, color: hex(AppColors.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _discoverySection(RemoteController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'NEARBY DEVICES',
                style: gfont(
                  AppType.labelMonoSm,
                  color: hex(AppColors.outline),
                ),
              ),
            ),
            if (c.scanState == ScanState.scanning) _scanIndicator(),
            if (c.scanState == ScanState.done)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => c.startScan(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: hex(AppColors.primaryContainer),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rescan',
                      style: gfont(
                        AppType.labelMonoSm,
                        color: hex(AppColors.primaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (c.discoveredDevices.isEmpty) _emptyDiscovery(c),
        for (final d in c.discoveredDevices) ...[
          _deviceCard(c, d),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _emptyDiscovery(RemoteController c) {
    final isScanning = c.scanState == ScanState.scanning;
    final apIsolation = c.lastScanResult?.apIsolationSuspected ?? false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: panel(
        fill: AppColors.surfaceContainerLowest,
        radius: AppRadii.md,
        borderOpacity: 0.2,
      ),
      child: Column(
        children: [
          Icon(
            isScanning ? Icons.radar : Icons.wifi_find,
            size: 36,
            color: hex(AppColors.outlineVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isScanning
                ? 'Scanning your network...'
                : apIsolation
                ? 'Network may block device discovery'
                : 'No smart TVs found on this network',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isScanning
                ? 'Looking for smart TVs and streaming devices'
                : apIsolation
                ? 'Your router may have AP isolation enabled. Try adding a device by IP address.'
                : 'Make sure your TV is on and connected to the same WiFi network',
            textAlign: TextAlign.center,
            style: gfont(
              AppType.labelMonoSm,
              color: hex(AppColors.outlineVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard(RemoteController c, core.DiscoveredDevice d) {
    final dev = d.device;
    final isSelected = c.deviceName == _shortName(dev.displayName);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => c.selectDevice(d),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: isSelected
                ? hex(AppColors.primaryContainer).withValues(alpha: 0.5)
                : hex(AppColors.outlineVariant).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                _iconForType(dev.type),
                size: 22,
                color: hex(AppColors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shortName(dev.displayName),
                    style: gfont(
                      AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dev.brand.name.toUpperCase()} · ${dev.host ?? 'unknown'}',
                    style: gfont(
                      AppType.labelMonoSm,
                      color: hex(AppColors.outline),
                    ),
                  ),
                ],
              ),
            ),
            if (d.badges.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final badge in d.badges)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        _iconForBadge(badge),
                        size: 14,
                        color: hex(AppColors.primaryContainer),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(core.DeviceType type) {
    switch (type) {
      case core.DeviceType.tv:
        return Icons.tv;
      case core.DeviceType.streamingStick:
        return Icons.usb;
      case core.DeviceType.soundbar:
        return Icons.speaker;
      case core.DeviceType.projector:
        return Icons.videocam;
      case core.DeviceType.mediaRenderer:
        return Icons.cast;
      default:
        return Icons.devices_other;
    }
  }

  IconData _iconForBadge(core.CapabilityBadge badge) {
    switch (badge) {
      case core.CapabilityBadge.control:
        return Icons.settings_remote;
      case core.CapabilityBadge.keyboard:
        return Icons.keyboard;
      case core.CapabilityBadge.cast:
        return Icons.cast;
    }
  }

  Widget _scanIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: hex(AppColors.primaryContainer),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Scanning',
          style: gfont(
            AppType.labelMonoSm,
            color: hex(AppColors.primaryContainer),
          ),
        ),
      ],
    );
  }

  Widget _irRemoteSection(BuildContext context, RemoteController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IR REMOTE',
          style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline)),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (c.isIrDevice && c.activeIrEntry != null) ...[
          _activeIrCard(c),
          const SizedBox(height: AppSpacing.sm),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showIrSetupWizard(context, c),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings_remote,
                  size: 20,
                  color: hex(AppColors.primaryContainer),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  c.isIrDevice ? 'Change IR Remote' : 'Add IR Remote',
                  style: gfont(
                    AppType.bodyMd,
                    color: hex(AppColors.primaryContainer),
                    weight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _activeIrCard(RemoteController c) {
    final entry = c.activeIrEntry!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(
              Icons.settings_remote,
              size: 22,
              color: hex(AppColors.primaryContainer),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: gfont(
                    AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    PulseDot(color: hex(AppColors.signalEmerald), size: 6),
                    const SizedBox(width: 4),
                    Text(
                      'IR · ${entry.keyCount} keys',
                      style: gfont(
                        AppType.labelMonoSm,
                        color: hex(AppColors.signalEmerald),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addDeviceButton(BuildContext context, RemoteController c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showAddDeviceDialog(context, c),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 20,
              color: hex(AppColors.primaryContainer),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Add Device Manually',
              style: gfont(
                AppType.bodyMd,
                color: hex(AppColors.primaryContainer),
                weight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context, RemoteController c) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerHigh),
        title: Text(
          'Add Device by IP',
          style: gfont(
            AppType.headlineMd,
            color: hex(AppColors.onSurface),
            weight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
          decoration: InputDecoration(
            hintText: '192.168.1.100',
            hintStyle: gfont(AppType.bodyMd, color: hex(AppColors.outline)),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: hex(AppColors.primaryContainer)),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
            ),
          ),
          TextButton(
            onPressed: () {
              final ip = controller.text.trim();
              if (ip.isNotEmpty) {
                c.addManualDevice(ip);
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Add',
              style: gfont(
                AppType.bodySm,
                color: hex(AppColors.primaryContainer),
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PairingPinDialog extends StatefulWidget {
  @override
  State<_PairingPinDialog> createState() => _PairingPinDialogState();
}

class _PairingPinDialogState extends State<_PairingPinDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: hex(AppColors.surfaceContainerLowest),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
    ),
    title: Text(
      'Enter pairing code',
      style: gfont(
        AppType.bodyMd,
        color: hex(AppColors.onSurface),
        weight: FontWeight.w700,
      ),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter the code shown on your TV',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _ctrl,
          autofocus: true,
          textAlign: TextAlign.center,
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
          decoration: InputDecoration(
            hintText: 'e.g. A1B2C3',
            hintStyle: gfont(
              AppType.bodyMd,
              color: hex(AppColors.outline).withValues(alpha: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: hex(AppColors.outlineVariant)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(
                color: hex(AppColors.primaryContainer),
                width: 2,
              ),
            ),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(null),
        child: Text(
          'Cancel',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
        ),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
        child: Text(
          'Pair',
          style: gfont(
            AppType.bodySm,
            color: hex(AppColors.primaryContainer),
            weight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
