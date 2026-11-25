import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class SimpleRemoteScreen extends StatelessWidget {
  const SimpleRemoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _statusRow(c),
              const SizedBox(height: AppSpacing.xl),
              Expanded(child: _buttonGrid(c)),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow(RemoteController c) {
    final connected = c.isConnected;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: connected
                ? hex(AppColors.signalEmerald)
                : hex(AppColors.outline),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          connected ? c.deviceName : 'Not connected',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _buttonGrid(RemoteController c) {
    return Column(
      children: [
        Expanded(
          child: _bigButton(
            Icons.power_settings_new,
            'Power',
            AppColors.error,
            () => c.power(!c.isPoweredOn),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _bigButton(
                        Icons.volume_up,
                        'Vol +',
                        AppColors.primaryContainer,
                        () => c.key(core.Key.volumeUp),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: _bigButton(
                        Icons.volume_down,
                        'Vol -',
                        AppColors.primaryContainer,
                        () => c.key(core.Key.volumeDown),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: _bigButton(
                        Icons.keyboard_arrow_up,
                        'Ch +',
                        AppColors.tertiary,
                        () => c.key(core.Key.channelUp),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: _bigButton(
                        Icons.keyboard_arrow_down,
                        'Ch -',
                        AppColors.tertiary,
                        () => c.key(core.Key.channelDown),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: _bigButton(
            Icons.volume_off,
            'Mute',
            AppColors.alertAmber,
            () => c.key(core.Key.mute),
          ),
        ),
      ],
    );
  }

  Widget _bigButton(
      IconData icon, String label, int colorToken, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: hex(colorToken).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border:
              Border.all(color: hex(colorToken).withValues(alpha: 0.25)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: hex(colorToken)),
              const SizedBox(height: 4),
              Text(label,
                  style: gfont(AppType.bodyMd,
                      color: hex(colorToken), weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
