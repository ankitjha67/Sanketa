import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class WhistleFinderScreen extends StatefulWidget {
  const WhistleFinderScreen({super.key});

  @override
  State<WhistleFinderScreen> createState() => _WhistleFinderScreenState();
}

class _WhistleFinderScreenState extends State<WhistleFinderScreen> with SingleTickerProviderStateMixin {
  bool _ringing = false;
  int _ringCount = 0;
  Timer? _timer;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startRinging() {
    final rc = RemoteScope.of(context);
    setState(() { _ringing = true; _ringCount = 0; });
    _pulseCtrl.repeat(reverse: true);

    rc.key(core.Key.volumeUp);

    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_ringCount >= 5) {
        _stopRinging();
        return;
      }
      rc.key(core.Key.mute);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_ringing) {
          rc.key(core.Key.mute);
        }
      });
      setState(() => _ringCount++);
    });
  }

  void _stopRinging() {
    _timer?.cancel();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() { _ringing = false; _ringCount = 0; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Find My TV',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroSection(),
          const SizedBox(height: AppSpacing.lg),
          _quickActions(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroSection() => Container(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_ringing ? AppColors.alertAmber : AppColors.primary).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(
        color: hex(_ringing ? AppColors.alertAmber : AppColors.primary).withValues(alpha: 0.2),
      ),
    ),
    child: Column(
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) => Transform.scale(
            scale: _ringing ? 1.0 + _pulseCtrl.value * 0.15 : 1.0,
            child: child,
          ),
          child: Icon(
            _ringing ? Icons.volume_up : Icons.tv,
            size: 64,
            color: hex(_ringing ? AppColors.alertAmber : AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _ringing ? 'Ringing TV...' : 'Find your TV',
          style: gfont(AppType.headlineMd,
              color: hex(_ringing ? AppColors.alertAmber : AppColors.onSurface),
              size: 20,
              weight: FontWeight.w700),
        ),
        if (_ringing) ...[
          const SizedBox(height: 4),
          Text('$_ringCount of 5 pulses',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _ringing ? _stopRinging : _startRinging,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: hex(_ringing ? AppColors.error : AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: hex(_ringing ? AppColors.error : AppColors.primary).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _ringing ? Icons.stop : Icons.notifications_active,
                  size: 20,
                  color: hex(_ringing ? AppColors.error : AppColors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  _ringing ? 'Stop' : 'Ring TV',
                  style: gfont(AppType.bodyMd,
                      color: hex(_ringing ? AppColors.error : AppColors.primary),
                      weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _quickActions() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            _actionButton('Power On', Icons.power_settings_new, AppColors.signalEmerald, core.Key.power),
            const SizedBox(width: 8),
            _actionButton('Max Volume', Icons.volume_up, AppColors.alertAmber, core.Key.volumeUp),
            const SizedBox(width: 8),
            _actionButton('Unmute', Icons.volume_off, AppColors.primary, core.Key.mute),
          ],
        ),
      ],
    ),
  );

  Widget _actionButton(String label, IconData icon, int color, core.Key key) => Expanded(
    child: GestureDetector(
      onTap: () => RemoteScope.of(context).key(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(color).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(color).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: hex(color)),
            const SizedBox(height: 4),
            Text(label,
                style: gfont(AppType.bodySm, color: hex(color), size: 9, weight: FontWeight.w600)),
          ],
        ),
      ),
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
            'Make your TV beep by toggling mute on and off rapidly. Useful for finding which room the TV is in or if it is powered on. Works over your local network.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
