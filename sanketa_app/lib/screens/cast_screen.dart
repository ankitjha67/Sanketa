import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';


class CastScreen extends StatelessWidget {
  const CastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Column(
      children: [
        _header(c),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    _castDeviceSection(context, c),
                    const SizedBox(height: AppSpacing.xl),
                    if (c.castSession.isActive || c.castSession.phase == core.CastPhase.error)
                      _nowPlaying(context, c)
                    else
                      _castReady(c),
                    const SizedBox(height: AppSpacing.xl),
                    _streamingApps(context, c),
                    const SizedBox(height: AppSpacing.xl),
                    _mediaSources(context),
                    const SizedBox(height: AppSpacing.xl),
                    _castInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(RemoteController c) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surface),
          border: Border(
              bottom: BorderSide(
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.6))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Row(
              children: [
                Icon(Icons.cast, size: 24, color: hex(AppColors.primaryContainer)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(c.canCast ? 'Cast to ${_shortName(c.castDeviceName)}' : 'Cast',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.onSurface),
                          size: 16,
                          weight: FontWeight.w600)),
                ),
                if (c.canCast && c.castProtocol.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(c.castProtocol.toUpperCase(),
                        style: gfont(AppType.labelMonoSm,
                            color: hex(AppColors.signalEmerald),
                            size: 10)),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _castDeviceSection(BuildContext context, RemoteController c) {
    if (c.canCast) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(
            fill: AppColors.surfaceContainerLow,
            radius: AppRadii.md,
            borderOpacity: 0.3),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(Icons.cast_connected,
                  size: 18, color: hex(AppColors.signalEmerald)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_shortName(c.castDeviceName),
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600)),
                  Text('${c.castProtocol.isNotEmpty ? c.castProtocol : 'Cast'} connected',
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.signalEmerald))),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => c.disconnectCastDevice(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Disconnect',
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.outline))),
              ),
            ),
          ],
        ),
      );
    }

    final castDevices = c.discoveredDevices
        .where((d) => d.badges.contains(core.CapabilityBadge.cast))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CAST DEVICES',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
        const SizedBox(height: AppSpacing.sm),
        if (c.isCastConnecting)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: panel(
                fill: AppColors.surfaceContainerLow,
                radius: AppRadii.md,
                borderOpacity: 0.3),
            child: Row(
              children: [
                SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: hex(AppColors.streamViolet))),
                const SizedBox(width: AppSpacing.sm),
                Text('Connecting to ${_shortName(c.castDeviceName)}...',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface))),
              ],
            ),
          )
        else if (castDevices.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: panel(
                fill: AppColors.surfaceContainerLowest,
                radius: AppRadii.md,
                borderOpacity: 0.15),
            child: Row(
              children: [
                Icon(Icons.cast, size: 18, color: hex(AppColors.outline)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                      c.scanState == ScanState.scanning
                          ? 'Scanning for cast devices...'
                          : 'No cast devices found. Go to Devices and scan.',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline))),
                ),
              ],
            ),
          )
        else
          ...castDevices.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _dlnaDeviceCard(c, d),
              )),
        if (c.castConnectionError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(c.castConnectionError!,
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.alertAmber))),
        ],
      ],
    );
  }

  Widget _dlnaDeviceCard(RemoteController c, core.DiscoveredDevice d) {
    final dev = d.device;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => c.connectCastDevice(d),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(
            fill: AppColors.surfaceContainerLow,
            radius: AppRadii.md,
            borderOpacity: 0.3),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child:
                  Icon(Icons.cast, size: 18, color: hex(AppColors.onSurfaceVariant)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_shortName(dev.displayName),
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600)),
                  Text(dev.host ?? '',
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.outline))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: hex(AppColors.outline)),
          ],
        ),
      ),
    );
  }

  Widget _castReady(RemoteController c) {
    final String subtitle;
    if (c.canCast) {
      subtitle =
          'Send photos, videos, and music to ${_shortName(c.castDeviceName)}';
    } else if (c.isCastConnecting) {
      subtitle = 'Connecting to ${_shortName(c.castDeviceName)}...';
    } else if (c.castConnectionError != null) {
      subtitle = c.castConnectionError!;
    } else {
      subtitle = 'Pick a device below to start casting';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border:
            Border.all(color: hex(AppColors.streamViolet).withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: hex(AppColors.streamViolet).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: hex(AppColors.streamViolet).withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.cast_connected,
                size: 28, color: hex(AppColors.streamViolet)),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(c.canCast ? 'Ready to Cast' : 'Cast',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 18,
                  weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.lg),
          if (c.canCast)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulseDot(color: hex(AppColors.signalEmerald), size: 8),
                const SizedBox(width: 6),
                Text('${c.castProtocol.isNotEmpty ? c.castProtocol : 'Cast'} ready',
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.signalEmerald))),
              ],
            )
          else if (c.isCastConnecting)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: hex(AppColors.outline))),
                const SizedBox(width: 8),
                Text('Probing for cast support...',
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.outline))),
              ],
            )
          else if (c.castConnectionError != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cast, size: 14, color: hex(AppColors.alertAmber)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text('Connection failed',
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.alertAmber))),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 14, color: hex(AppColors.outline)),
                const SizedBox(width: 6),
                Text('No cast device',
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.outline))),
              ],
            ),
        ],
      ),
    );
  }

  Widget _nowPlaying(BuildContext context, RemoteController c) {
    final session = c.castSession;
    final isError = session.phase == core.CastPhase.error;
    final isLoading = session.phase == core.CastPhase.loading;
    final isPaused = session.phase == core.CastPhase.paused;
    final borderColor =
        isError ? AppColors.alertAmber : AppColors.streamViolet;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(borderColor).withValues(alpha: 0.4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: hex(isError ? AppColors.alertAmber : AppColors.streamViolet)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                  color: hex(isError ? AppColors.alertAmber : AppColors.streamViolet)
                      .withValues(alpha: 0.3)),
            ),
            child: Icon(
                isError
                    ? Icons.error_outline
                    : isLoading
                        ? Icons.hourglass_top
                        : Icons.cast_connected,
                size: 28,
                color: hex(isError ? AppColors.alertAmber : AppColors.streamViolet)),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
              isError
                  ? 'Cast Failed'
                  : isLoading
                      ? 'Sending to TV...'
                      : 'Now Playing',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 18,
                  weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),

          // File name or error
          Text(
              isError
                  ? (session.error ?? 'Something went wrong.')
                  : session.fileName ?? 'Media',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.lg),

          // Transport controls
          if (!isError)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: hex(AppColors.streamViolet)))
                else ...[
                  _transportButton(
                    icon: isPaused ? Icons.play_arrow : Icons.pause,
                    onTap: () => isPaused ? c.resumeCast() : c.pauseCast(),
                    color: AppColors.streamViolet,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  _transportButton(
                    icon: Icons.stop,
                    onTap: () => c.stopCast(),
                    color: AppColors.outline,
                  ),
                ],
              ],
            ),

          if (isError) ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () => c.stopCast(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Dismiss',
                    style: gfont(AppType.labelMonoSm,
                        color: hex(AppColors.onSurface))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _transportButton({
    required IconData icon,
    required VoidCallback onTap,
    required int color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hex(color).withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: hex(color).withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 24, color: hex(color)),
      ),
    );
  }

  Widget _streamingApps(BuildContext context, RemoteController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STREAMING APPS',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: _appCard(context, c, 'Netflix', Icons.play_arrow,
                    AppColors.netflix)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _appCard(context, c, 'YouTube', Icons.play_arrow,
                    AppColors.youTube)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: _appCard(context, c, 'Prime Video', Icons.play_arrow,
                    AppColors.prime)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _appCard(context, c, 'Disney+', Icons.play_arrow,
                    AppColors.disney)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: _appCard(
                    context, c, 'Hulu', Icons.play_arrow, AppColors.outline)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _appCard(context, c, 'Spotify', Icons.music_note,
                    AppColors.outline)),
          ],
        ),
        if (!c.isConnected) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Connect to a TV to open apps on it',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.outlineVariant))),
        ],
        if (c.launchResult != null) ...[
          const SizedBox(height: AppSpacing.sm),
          _launchFeedback(c),
        ],
        if (c.isConnected) ...[
          const SizedBox(height: AppSpacing.sm),
          _castTip(),
        ],
      ],
    );
  }

  Widget _castTip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child:
                Icon(Icons.info_outline, size: 14, color: hex(AppColors.outline)),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Opens the app on your TV. Use the Remote tab to browse '
              'and search. To cast from your phone, use the app\'s own '
              'Cast button.',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.outline), size: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _launchFeedback(RemoteController c) {
    final raw = c.launchResult!;
    final isError = raw.startsWith('error:');
    final msg = raw.startsWith('ok:')
        ? raw.substring(3)
        : raw.startsWith('error:')
            ? raw.substring(6)
            : raw;
    final color = isError ? AppColors.alertAmber : AppColors.signalEmerald;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: hex(color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: hex(color).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 16,
              color: hex(color)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(msg,
                style: gfont(AppType.labelMonoSm, color: hex(color))),
          ),
        ],
      ),
    );
  }

  Widget _appCard(BuildContext context, RemoteController c, String name,
      IconData icon, int color) {
    final connected = c.isConnected;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!connected) {
          _showSnack(context, 'Connect to a TV first from the Devices tab.');
          return;
        }
        HapticFeedback.lightImpact();
        c.launch(name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(color).withValues(alpha: connected ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(color)
                  .withValues(alpha: connected ? 0.3 : 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: hex(color)
                    .withValues(alpha: connected ? 1.0 : 0.4)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: gfont(AppType.bodySm,
                      color: hex(color)
                          .withValues(alpha: connected ? 1.0 : 0.4),
                      weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mediaSources(BuildContext context) {
    final c = RemoteScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _miracastButton(context, c),
        const SizedBox(height: AppSpacing.xs),
        _mirrorButton(context, c),
        if (c.mirrorError != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(c.mirrorError!,
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.alertAmber))),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('MEDIA SOURCES',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline))),
        const SizedBox(height: AppSpacing.sm),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: _sourceCard(context, Icons.photo_library, 'Photos',
                    FileType.image)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _sourceCard(context, Icons.video_library, 'Videos',
                    FileType.video)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: _sourceCard(context, Icons.library_music, 'Music',
                    FileType.audio)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: _sourceCard(context, Icons.folder, 'Files',
                    FileType.any)),
          ],
        ),
      ],
    );
  }

  Widget _miracastButton(BuildContext context, RemoteController c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final ok = await c.openMiracast();
        if (!ok && context.mounted) {
          _showSnack(context, 'Could not open cast settings.');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.streamViolet).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.streamViolet).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.screen_share, size: 22,
                color: hex(AppColors.streamViolet)),
            const SizedBox(width: AppSpacing.sm),
            Text('Mirror Screen',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.streamViolet),
                    weight: FontWeight.w600)),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text('Miracast',
                  style: gfont(AppType.labelMonoSm,
                      color: hex(AppColors.signalEmerald), size: 9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mirrorButton(BuildContext context, RemoteController c) {
    final active = c.isMirroring;
    final color = active ? AppColors.alertAmber : AppColors.onSurfaceVariant;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (active) {
          c.stopMirror();
        } else if (!c.isConnected) {
          _showSnack(context, 'Connect to a TV first from the Devices tab.');
        } else if (c.castSession.isActive && !c.isMirroring) {
          _showSnack(context, 'Stop the current cast before mirroring.');
        } else {
          c.startWsMirror();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(color).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(color).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? Icons.stop_screen_share : Icons.cast,
                size: 18, color: hex(color)),
            const SizedBox(width: AppSpacing.sm),
            Text(active ? 'Stop Mirror' : 'Mirror Screen',
                style: gfont(AppType.bodySm,
                    color: hex(color), weight: FontWeight.w500)),
            if (!active) ...[
              const SizedBox(width: AppSpacing.sm),
              Text('Low Latency',
                  style: gfont(AppType.labelMonoSm,
                      color: hex(color).withValues(alpha: 0.6), size: 9)),
            ],
            if (active && c.mirrorMode.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Text('(${c.mirrorMode})',
                  style: gfont(AppType.bodySm,
                      color: hex(color).withValues(alpha: 0.7))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sourceCard(
      BuildContext context, IconData icon, String label, FileType fileType) {
    final c = RemoteScope.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _pickAndCast(context, c, label, fileType),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(
            fill: AppColors.surfaceContainerLow,
            radius: AppRadii.md,
            borderOpacity: 0.3),
        child: Column(
          children: [
            Icon(icon,
                size: 28,
                color: c.canCast
                    ? hex(AppColors.onSurfaceVariant)
                    : hex(AppColors.outline).withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: c.canCast
                        ? hex(AppColors.onSurface)
                        : hex(AppColors.outline).withValues(alpha: 0.5),
                    weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndCast(
    BuildContext context,
    RemoteController c,
    String label,
    FileType fileType,
  ) async {
    if (!c.canCast) {
      _showSnack(context,
          'Connect a cast device above to cast $label');
      return;
    }
    if (c.castSession.isActive) {
      _showSnack(context, 'Stop the current cast before starting a new one.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) {
      _showSnack(context, 'Could not access the selected file.');
      return;
    }

    await c.castFile(path, file.name);
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(message,
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
        duration: const Duration(seconds: 3),
        backgroundColor: hex(AppColors.surfaceContainerHigh),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ));
  }

  static String _shortName(String name) {
    final re = RegExp(r'-[0-9a-f]{20,}$');
    return name.replaceAll(re, '');
  }

  Widget _castInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(
          fill: AppColors.surfaceContainerLowest,
          radius: AppRadii.md,
          borderOpacity: 0.15),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: hex(AppColors.outline)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Media stays on your local network. Nothing leaves your home.',
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline)),
            ),
          ),
        ],
      ),
    );
  }
}
