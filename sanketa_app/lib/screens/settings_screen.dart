import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _deviceInfoCard(c),
                        const SizedBox(height: AppSpacing.lg),
                        _protocolDiscovery(context, c),
                        const SizedBox(height: AppSpacing.lg),
                        _capabilitiesCard(c),
                        const SizedBox(height: AppSpacing.lg),
                        _settingsGroup('REMOTE', [
                          _toggleTile(
                            Icons.vibration,
                            'Haptic Feedback',
                            subtitle: 'Vibrate on button press',
                            value: c.hapticEnabled,
                            onChanged: (_) => c.toggleHaptic(),
                          ),
                          _toggleTile(
                            Icons.sync,
                            'Auto Reconnect',
                            subtitle: 'Reconnect when TV drops connection',
                            value: c.autoReconnect,
                            onChanged: (_) => c.toggleAutoReconnect(),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _settingsGroup('IR BLASTER', [
                          _settingTile(
                              Icons.settings_input_antenna, 'IR Hardware',
                              subtitle: c.hasIrHardware
                                  ? 'Available'
                                  : 'Not detected',
                              trailing: Icon(Icons.chevron_right,
                                  size: 20,
                                  color: hex(AppColors.onSurfaceVariant))),
                          _settingTile(Icons.tune, 'Codeset Wizard',
                              subtitle: 'Match your TV brand',
                              trailing: Icon(Icons.chevron_right,
                                  size: 20,
                                  color: hex(AppColors.onSurfaceVariant))),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _settingsGroup('PRIVACY', [
                          _settingTile(Icons.shield, 'Privacy',
                              subtitle:
                                  'Zero analytics, zero ads, zero accounts'),
                          _settingTile(Icons.wifi_off, 'Offline Mode',
                              subtitle: 'Control works without internet'),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _settingsGroup('ABOUT', [
                          _settingTile(Icons.info_outline, 'Sanketa v0.1.0',
                              subtitle: 'Universal TV Remote'),
                        ]),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surface),
          border: Border(
              bottom: BorderSide(
                  color:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.6))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.arrow_back,
                      size: 24, color: hex(AppColors.onSurface)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Settings',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.onSurface),
                          size: 16,
                          weight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Device Info Card
  // ---------------------------------------------------------------------------

  Widget _deviceInfoCard(RemoteController c) {
    final dev = c.selectedDevice;
    if (dev == null) {
      return _infoCard(
        icon: Icons.tv_off,
        iconColor: hex(AppColors.outline),
        title: 'No Device Connected',
        borderColor: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
        children: [
          Text('Go to the Devices tab to scan and connect.',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant))),
        ],
      );
    }

    final device = dev.device;
    final brand = _brandLabel(device.brand);
    final adapter = c.adapter;

    return _infoCard(
      icon: Icons.tv,
      iconColor: c.isConnected
          ? hex(AppColors.signalEmerald)
          : hex(AppColors.alertAmber),
      title: c.deviceName.isNotEmpty ? c.deviceName : 'Connected Device',
      borderColor: c.isConnected
          ? hex(AppColors.signalEmerald).withValues(alpha: 0.3)
          : hex(AppColors.alertAmber).withValues(alpha: 0.3),
      children: [
        _infoRow('Brand', brand),
        if (device.model != null) _infoRow('Model', device.model!),
        if (device.host != null) _infoRow('IP Address', device.host!),
        _infoRow('Adapter', _adapterLabel(adapter.id)),
        _infoRow('Transport', _transportLabel(adapter.transport)),
        _infoRow(
            'Status',
            c.isConnected
                ? 'Connected'
                : c.isConnecting
                    ? 'Connecting...'
                    : 'Disconnected'),
        if (c.connectionError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline,
                  size: 14, color: hex(AppColors.alertAmber)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(c.connectionError!,
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.alertAmber))),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Protocol Discovery — shows probed protocols, tap to switch
  // ---------------------------------------------------------------------------

  Widget _protocolDiscovery(BuildContext context, RemoteController c) {
    final dev = c.selectedDevice;
    if (dev == null) return const SizedBox.shrink();

    final meta = dev.metadata;
    final sources = dev.sources;
    final adapter = c.adapter;
    final probe = c.protocolProbe;

    final hasDialUrl = meta['application-url'] != null;
    final manufacturer = meta['manufacturer'];
    final model = meta['model'];

    final isAtvrs =
        adapter.id == 'android_tv' || adapter.id == 'fire_tv';
    final isSimpleIp = adapter.id == 'bravia_simple_ip';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('PROTOCOLS',
                  style: gfont(AppType.labelMonoSm,
                      color: hex(AppColors.outline))),
            ),
            if (c.isProbing)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: hex(AppColors.primaryContainer),
                ),
              )
            else if (dev.device.host != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => c.probeProtocols(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh,
                        size: 14, color: hex(AppColors.primaryContainer)),
                    const SizedBox(width: 4),
                    Text('Re-scan',
                        style: gfont(AppType.labelMonoSm,
                            color: hex(AppColors.primaryContainer))),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (probe != null) ...[
          Text('Tap an available protocol to switch to it.',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          decoration: panel(
              fill: AppColors.surfaceContainerLow,
              radius: AppRadii.md,
              borderOpacity: 0.2),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _protocolSwitchRow(
                context, c,
                'ATVRS (Android TV Remote)',
                'android_tv',
                discovered: sources.contains(core.DiscoverySource.mdns) || (probe?.atvrs ?? false),
                active: isAtvrs && c.isConnected,
                probed: probe?.atvrs,
                subtitle: 'Port 6466 — D-pad, keyboard, volume, apps',
              ),
              _protocolSwitchRow(
                context, c,
                'Simple IP (Sony BRAVIA)',
                'bravia',
                discovered: probe?.simpleIp ?? false,
                active: isSimpleIp && c.isConnected,
                probed: probe?.simpleIp,
                subtitle: 'Port 20060 — Sony-specific control',
              ),
              _protocolSwitchRow(
                context, c,
                'DLNA / UPnP',
                'dlna',
                discovered: sources.contains(core.DiscoverySource.ssdp) || (probe?.dlna ?? false),
                active: adapter.id == 'dlna' && c.isConnected,
                probed: probe?.dlna,
                subtitle: 'Volume, transport, media casting',
              ),
              _protocolSwitchRow(
                context, c,
                'Google Cast',
                'cast',
                discovered: probe?.googleCast ?? false,
                active: adapter.id == 'cast',
                probed: probe?.googleCast,
                subtitle: 'Port 8009 — Chromecast protocol',
              ),
              _protocolSwitchRow(
                context, c,
                'LG webOS',
                'webos',
                discovered: probe?.webos ?? false,
                active: adapter.id == 'webos' && c.isConnected,
                probed: probe?.webos,
                subtitle: 'Port 3000 — LG WebSocket API',
              ),
              _protocolSwitchRow(
                context, c,
                'Samsung Tizen',
                'tizen',
                discovered: probe?.tizen ?? false,
                active: adapter.id == 'tizen' && c.isConnected,
                probed: probe?.tizen,
                subtitle: 'Port 8001/8002 — Samsung WebSocket',
              ),
              _protocolSwitchRow(
                context, c,
                'Roku ECP',
                'roku',
                discovered: probe?.roku ?? false,
                active: adapter.id == 'roku' && c.isConnected,
                probed: probe?.roku,
                subtitle: 'Port 8060 — Roku External Control',
              ),
              _protocolRow(
                'DIAL (App Launch)',
                hasDialUrl,
                subtitle: hasDialUrl
                    ? 'Netflix, YouTube, Prime Video...'
                    : 'Not advertised',
              ),
              if (manufacturer != null || model != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Divider(
                    height: 1,
                    color: hex(AppColors.outlineVariant)
                        .withValues(alpha: 0.3)),
                const SizedBox(height: AppSpacing.xs),
                if (manufacturer != null)
                  _infoRow('Manufacturer', manufacturer),
                if (model != null) _infoRow('Model Info', model),
              ],
            ],
          ),
        ),
        if (c.forcedAdapterId != null) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              c.forcedAdapterId = null;
              final dev = c.selectedDevice;
              if (dev != null) c.selectDevice(dev);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                    color: hex(AppColors.primaryContainer)
                        .withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_fix_high,
                      size: 16, color: hex(AppColors.primaryContainer)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Protocol override active. Tap to reset to auto-detect.',
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.primaryContainer)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _protocolSwitchRow(
    BuildContext context,
    RemoteController c,
    String name,
    String adapterId, {
    required bool discovered,
    required bool active,
    bool? probed,
    String? subtitle,
  }) {
    final isReachable = probed ?? discovered;
    final isCurrent = active || c.adapter.id == adapterId;
    final canSwitch = isReachable && !isCurrent && c.selectedDevice != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canSwitch
          ? () {
              c.switchAdapter(adapterId);
              Navigator.of(context).pop();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isCurrent
                  ? Icons.radio_button_checked
                  : isReachable
                      ? Icons.radio_button_unchecked
                      : Icons.cancel_outlined,
              size: 16,
              color: isCurrent
                  ? hex(AppColors.primaryContainer)
                  : isReachable
                      ? hex(AppColors.signalEmerald)
                      : hex(AppColors.outline).withValues(alpha: 0.5),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: gfont(AppType.bodySm,
                          color: isCurrent
                              ? hex(AppColors.primaryContainer)
                              : isReachable
                                  ? hex(AppColors.onSurface)
                                  : hex(AppColors.onSurfaceVariant)
                                      .withValues(alpha: 0.6),
                          weight: isCurrent || isReachable
                              ? FontWeight.w500
                              : FontWeight.w400)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: gfont(AppType.labelMonoSm,
                            color: hex(AppColors.outline))),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      hex(AppColors.primaryContainer).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text('ACTIVE',
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.primaryContainer), size: 9)),
              )
            else if (canSwitch)
              Text('Switch',
                  style: gfont(AppType.labelMonoSm,
                      color: hex(AppColors.signalEmerald), size: 10)),
          ],
        ),
      ),
    );
  }

  Widget _protocolRow(String name, bool active, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: active
                ? hex(AppColors.signalEmerald)
                : hex(AppColors.outline),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: gfont(AppType.bodySm,
                        color: active
                            ? hex(AppColors.onSurface)
                            : hex(AppColors.onSurfaceVariant),
                        weight:
                            active ? FontWeight.w500 : FontWeight.w400)),
                if (subtitle != null)
                  Text(subtitle,
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.outline))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Capabilities Card
  // ---------------------------------------------------------------------------

  Widget _capabilitiesCard(RemoteController c) {
    final dev = c.selectedDevice;
    if (dev == null) return const SizedBox.shrink();

    final caps = c.caps;
    final badges = dev.badges;
    final detected = c.detectedFeatures;
    final hasDetection = detected.isNotEmpty &&
        !detected.containsKey('Status');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('CAPABILITIES',
                  style: gfont(AppType.labelMonoSm,
                      color: hex(AppColors.outline))),
            ),
            if (hasDetection)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text('AUTO-DETECTED',
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.signalEmerald), size: 9)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: panel(
              fill: AppColors.surfaceContainerLow,
              radius: AppRadii.md,
              borderOpacity: 0.2),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _capRow(Icons.gamepad, 'D-pad Navigation',
                  caps.keys.isNotEmpty,
                  source: detected['D-pad / Keys']),
              _capRow(Icons.keyboard, 'Keyboard / Text Input', caps.canType,
                  source: detected['Keyboard (IME)'] ?? detected['Keyboard']),
              _capRow(Icons.volume_up, 'Volume Control',
                  caps.supports(core.Key.volumeUp),
                  source: detected['Volume']),
              _capRow(Icons.power_settings_new, 'Power On/Off',
                  caps.supports(core.Key.power),
                  source: detected['Power']),
              _capRow(Icons.apps, 'App Launch', caps.appLaunch,
                  source: detected['App Launch']),
              _capRow(Icons.cast, 'Media Casting',
                  badges.contains(core.CapabilityBadge.cast)),
              _capRow(Icons.speed, 'State Readback', caps.stateReadback,
                  source: detected['State Readback']),
              _capRow(Icons.power, 'Wake from Standby', caps.wake,
                  source: detected['Wake']),
              if (detected.containsKey('Raw Bitmask')) ...[
                const SizedBox(height: AppSpacing.xs),
                Divider(
                    height: 1,
                    color: hex(AppColors.outlineVariant)
                        .withValues(alpha: 0.3)),
                const SizedBox(height: AppSpacing.xs),
                _infoRow('Negotiated', detected['Raw Bitmask']!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _capRow(IconData icon, String label, bool supported,
      {String? source}) {
    final isNotReported = source != null && source.contains('Not reported');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon,
                size: 16,
                color: supported
                    ? hex(AppColors.signalEmerald)
                    : hex(AppColors.outline)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: gfont(AppType.bodySm,
                        color: supported
                            ? hex(AppColors.onSurface)
                            : hex(AppColors.onSurfaceVariant))),
                if (source != null && !isNotReported)
                  Text(source,
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.outline), size: 9)),
              ],
            ),
          ),
          Text(
            supported ? 'Yes' : 'No',
            style: gfont(AppType.labelMonoSm,
                color: supported
                    ? hex(AppColors.signalEmerald)
                    : hex(AppColors.outline)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Widget _infoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(title,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: gfont(AppType.labelMonoSm,
                    color: hex(AppColors.outline))),
          ),
          Expanded(
            child: Text(value,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface))),
          ),
        ],
      ),
    );
  }

  Widget _settingsGroup(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: panel(
              fill: AppColors.surfaceContainerLow,
              radius: AppRadii.md,
              borderOpacity: 0.2),
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: hex(AppColors.outlineVariant)
                          .withValues(alpha: 0.3)),
                tiles[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingTile(IconData icon, String label,
      {String? subtitle, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: hex(AppColors.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle,
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.outline))),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _toggleTile(IconData icon, String label,
      {String? subtitle,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: hex(AppColors.onSurfaceVariant)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: gfont(AppType.labelMonoSm,
                            color: hex(AppColors.outline))),
                ],
              ),
            ),
            _toggle(value),
          ],
        ),
      ),
    );
  }

  Widget _toggle(bool value) {
    return Container(
      width: 42,
      height: 24,
      decoration: BoxDecoration(
        color: value
            ? hex(AppColors.primaryContainer).withValues(alpha: 0.3)
            : hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: value
                ? hex(AppColors.primaryContainer).withValues(alpha: 0.6)
                : hex(AppColors.outlineVariant).withValues(alpha: 0.4)),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: value
                ? hex(AppColors.primaryContainer)
                : hex(AppColors.outline),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  String _brandLabel(core.BrandFamily brand) {
    switch (brand) {
      case core.BrandFamily.androidTv:
        return 'Android TV / Google TV';
      case core.BrandFamily.tizen:
        return 'Samsung (Tizen)';
      case core.BrandFamily.webOs:
        return 'LG (webOS)';
      case core.BrandFamily.roku:
        return 'Roku';
      case core.BrandFamily.bravia:
        return 'Sony BRAVIA';
      case core.BrandFamily.fireTv:
        return 'Amazon Fire TV';
      case core.BrandFamily.vizio:
        return 'Vizio (SmartCast)';
      case core.BrandFamily.panasonic:
        return 'Panasonic';
      case core.BrandFamily.philips:
        return 'Philips';
      case core.BrandFamily.hisense:
        return 'Hisense (VIDAA)';
      case core.BrandFamily.tcl:
        return 'TCL';
      case core.BrandFamily.appleTv:
        return 'Apple TV';
      case core.BrandFamily.dlna:
        return 'DLNA / UPnP';
      case core.BrandFamily.genericIr:
        return 'IR (Infrared)';
      case core.BrandFamily.other:
        return 'Generic';
    }
  }

  String _adapterLabel(String id) {
    switch (id) {
      case 'android_tv':
        return 'Android TV Remote (ATVRS)';
      case 'bravia_simple_ip':
        return 'Sony Simple IP + ATVRS';
      case 'roku':
        return 'Roku ECP';
      case 'webos':
        return 'LG webOS WebSocket';
      case 'tizen':
        return 'Samsung Tizen WebSocket';
      case 'fire_tv':
        return 'Fire TV (ATVRS)';
      case 'vizio':
        return 'Vizio SmartCast API';
      case 'dlna':
        return 'DLNA / UPnP AV';
      case 'cast':
        return 'Google Cast';
      case 'dial':
        return 'DIAL (App Launch Only)';
      default:
        return id;
    }
  }

  String _transportLabel(core.Transport t) {
    switch (t) {
      case core.Transport.network:
        return 'WiFi / LAN';
      case core.Transport.infrared:
        return 'IR Blaster';
      case core.Transport.bridge:
        return 'WiFi-IR Bridge';
    }
  }
}
