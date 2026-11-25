import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class MultiRoomScreen extends StatefulWidget {
  const MultiRoomScreen({super.key});

  @override
  State<MultiRoomScreen> createState() => _MultiRoomScreenState();
}

class _MultiRoomScreenState extends State<MultiRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final devices = c.discoveredDevices;

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      body: SafeArea(
        child: Column(
          children: [
            _header(context, c),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: devices.isEmpty
                      ? _empty(c)
                      : _deviceGrid(c, devices),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, RemoteController c) => Container(
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back,
                      size: 20, color: hex(AppColors.onSurface)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.devices_rounded,
                    size: 20, color: hex(AppColors.secondary)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Multi-Room',
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.onSurface),
                          size: 16,
                          weight: FontWeight.w600)),
                ),
                GestureDetector(
                  onTap: () {
                    c.startScan();
                    setState(() {});
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(AppColors.surfaceContainerHigh),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.refresh, size: 14, color: hex(AppColors.onSurfaceVariant)),
                      const SizedBox(width: 4),
                      Text('Scan',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurfaceVariant),
                              size: 11)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _empty(RemoteController c) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.devices_other_rounded,
                size: 48,
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('No TVs found on this network',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurfaceVariant))),
            const SizedBox(height: AppSpacing.sm),
            Text('Make sure your TVs are powered on and connected to Wi-Fi',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () {
                c.startScan();
                setState(() {});
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primaryContainer),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Text('Scan Network',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.surface),
                        weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );

  Widget _deviceGrid(RemoteController c, List<core.DiscoveredDevice> devices) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: devices.length,
      itemBuilder: (_, i) => _deviceCard(c, devices[i]),
    );
  }

  Widget _deviceCard(RemoteController c, core.DiscoveredDevice entry) {
    final isActive = c.selectedDevice?.device.host == entry.device.host;
    final brand = entry.device.brand.name;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: panel(
        borderColor:
            isActive ? AppColors.primaryContainer : AppColors.outlineVariant,
        borderOpacity: isActive ? 0.6 : 0.3,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hex(isActive
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainerHigh)
                        .withValues(alpha: isActive ? 0.15 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(Icons.tv,
                      size: 24,
                      color: hex(isActive
                          ? AppColors.primaryContainer
                          : AppColors.onSurfaceVariant)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.device.friendlyName ?? entry.device.host ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hex(AppColors.surfaceContainerHighest),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(brand,
                              style: gfont(AppType.labelMonoSm,
                                  color: hex(AppColors.onSurfaceVariant),
                                  size: 10)),
                        ),
                        const SizedBox(width: 6),
                        Text(entry.device.host ?? '',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.outline), size: 11)),
                      ]),
                    ],
                  ),
                ),
                if (isActive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text('Active',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.signalEmerald),
                            size: 10,
                            weight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color:
                          hex(AppColors.outlineVariant).withValues(alpha: 0.2))),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickBtn(Icons.power_settings_new, 'Power', () {
                  if (isActive) c.power(false);
                }),
                _quickBtn(Icons.volume_up, 'Vol+', () {
                  if (isActive) c.key(core.Key.volumeUp);
                }),
                _quickBtn(Icons.volume_down, 'Vol-', () {
                  if (isActive) c.key(core.Key.volumeDown);
                }),
                _quickBtn(Icons.volume_off, 'Mute', () {
                  if (isActive) c.key(core.Key.mute);
                }),
                _quickBtn(Icons.home, 'Home', () {
                  if (isActive) c.key(core.Key.home);
                }),
                _quickBtn(
                  isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  isActive ? 'Selected' : 'Select',
                  () {
                    if (!isActive) {
                      c.selectDevice(entry);
                      setState(() {});
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: hex(AppColors.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
      );
}
