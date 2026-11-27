import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvNetworkShareScreen extends StatefulWidget {
  const TvNetworkShareScreen({super.key});

  @override
  State<TvNetworkShareScreen> createState() => _TvNetworkShareScreenState();
}

class _TvNetworkShareScreenState extends State<TvNetworkShareScreen> {
  bool _sharing = false;
  int _protocol = 0;

  static const _protocols = <(String, IconData, String, int)>[
    ('DLNA', Icons.cast_connected, 'Universal media sharing', AppColors.primary),
    ('SMB', Icons.folder_shared, 'Windows file sharing', AppColors.signalEmerald),
    ('NFS', Icons.storage, 'Network file system', AppColors.secondary),
    ('AirPlay', Icons.airplay, 'Apple ecosystem', AppColors.alertAmber),
  ];

  static const _devices = <(String, String, IconData, bool)>[
    ('Living Room TV', 'Samsung 55"', Icons.tv, true),
    ('Bedroom TV', 'LG 43"', Icons.tv, true),
    ('Office PC', 'Desktop', Icons.computer, false),
    ('NAS', 'Synology DS220+', Icons.storage, true),
    ('Laptop', 'MacBook Pro', Icons.laptop, false),
  ];

  void _toggleSharing() {
    final rc = RemoteScope.of(context);
    rc.launch('share:${_sharing ? 'stop' : 'start'}');
    setState(() => _sharing = !_sharing);
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Network Share',
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
          _sharingToggle(),
          const SizedBox(height: AppSpacing.lg),
          _protocolSelector(),
          const SizedBox(height: AppSpacing.lg),
          Text('Discovered Devices',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          ..._devices.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _deviceTile(d),
              )),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.share,
                size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Network Sharing',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Share media between TV and network devices via DLNA, SMB, NFS',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _sharingToggle() => GestureDetector(
        onTap: _toggleSharing,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 14),
          decoration: BoxDecoration(
            color: hex(_sharing
                    ? AppColors.signalEmerald
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _sharing ? 0.12 : 1),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: hex(_sharing
                        ? AppColors.signalEmerald
                        : AppColors.outlineVariant)
                    .withValues(alpha: _sharing ? 0.4 : 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _sharing ? Icons.stop_circle : Icons.share,
                size: 24,
                color: hex(
                    _sharing ? AppColors.signalEmerald : AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                _sharing ? 'Sharing Active' : 'Start Sharing',
                style: gfont(AppType.bodyMd,
                    color: hex(_sharing
                        ? AppColors.signalEmerald
                        : AppColors.primary),
                    weight: FontWeight.w600,
                    size: 14),
              ),
            ],
          ),
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
            final active = e.key == _protocol;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() => _protocol = e.key);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: hex(active ? e.value.$4 : AppColors.surfaceContainerLow)
                        .withValues(alpha: active ? 0.1 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                        color: hex(active
                                ? e.value.$4
                                : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.4 : 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(e.value.$2, size: 22, color: hex(e.value.$4)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.$1,
                                style: gfont(AppType.bodyMd,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600,
                                    size: 13)),
                            Text(e.value.$3,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline), size: 10)),
                          ],
                        ),
                      ),
                      if (active)
                        Icon(Icons.check_circle,
                            size: 20, color: hex(e.value.$4)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _deviceTile((String, String, IconData, bool) d) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(d.$4
                  ? AppColors.signalEmerald
                  : AppColors.surfaceContainerLow)
              .withValues(alpha: d.$4 ? 0.06 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(d.$4
                      ? AppColors.signalEmerald
                      : AppColors.outlineVariant)
                  .withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(d.$3, size: 22, color: hex(AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text(d.$2,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hex(d.$4
                        ? AppColors.signalEmerald
                        : AppColors.outlineVariant)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(d.$4 ? 'Online' : 'Offline',
                  style: gfont(AppType.bodySm,
                      color: hex(d.$4
                          ? AppColors.signalEmerald
                          : AppColors.outlineVariant),
                      weight: FontWeight.w600,
                      size: 9)),
            ),
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
                'Share media between TV and LAN devices via DLNA, SMB, NFS, '
                'or AirPlay. Discover devices on your network. All local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
