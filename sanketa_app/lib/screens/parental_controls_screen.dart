import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/parental_control_service.dart';
import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class ParentalControlsScreen extends StatefulWidget {
  const ParentalControlsScreen({super.key});

  @override
  State<ParentalControlsScreen> createState() =>
      _ParentalControlsScreenState();
}

class _ParentalControlsScreenState extends State<ParentalControlsScreen> {
  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final pc = c.parentalControls;

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _statusCard(pc),
                      const SizedBox(height: AppSpacing.lg),
                      if (!pc.isEnabled) _setupCard(c) else ..._settings(c, pc),
                    ],
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
                Icon(Icons.shield_rounded,
                    size: 20, color: hex(AppColors.error)),
                const SizedBox(width: AppSpacing.sm),
                Text('Parental Controls',
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 16,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  Widget _statusCard(ParentalControlService pc) {
    if (!pc.isEnabled) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Row(children: [
          Icon(Icons.shield_outlined,
              size: 32, color: hex(AppColors.outlineVariant)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Not configured',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Set a PIN to enable parental controls',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurfaceVariant))),
              ],
            ),
          ),
        ]),
      );
    }

    final color = pc.isLocked ? AppColors.error : AppColors.signalEmerald;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(fill: color, borderOpacity: 0),
      child: Row(children: [
        Icon(pc.isLocked ? Icons.lock : Icons.lock_open,
            size: 32, color: Colors.white),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pc.isLocked ? 'Controls Active' : 'Unlocked',
                  style: gfont(AppType.bodyMd,
                      color: Colors.white, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                  pc.isLocked
                      ? '${pc.blockedKeys.length} keys blocked'
                      : 'Restricted keys are allowed',
                  style: gfont(AppType.bodySm,
                      color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _setupCard(RemoteController c) => GestureDetector(
        onTap: () => _showPinDialog(c, isSetup: true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.primaryContainer),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Center(
            child: Text('Set Up PIN',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.surface),
                    weight: FontWeight.w600)),
          ),
        ),
      );

  List<Widget> _settings(RemoteController c, ParentalControlService pc) => [
        _lockToggle(c, pc),
        const SizedBox(height: AppSpacing.md),
        _blockedKeysSection(pc),
        const SizedBox(height: AppSpacing.md),
        _timeLimitSection(pc),
        const SizedBox(height: AppSpacing.lg),
        _dangerZone(c, pc),
      ];

  Widget _lockToggle(RemoteController c, ParentalControlService pc) =>
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lock Status',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(pc.isLocked ? 'Controls are active' : 'Controls paused',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurfaceVariant))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (pc.isLocked) {
                _showPinDialog(c, isUnlock: true);
              } else {
                pc.lock();
                setState(() {});
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: pc.isLocked
                    ? hex(AppColors.error).withValues(alpha: 0.1)
                    : hex(AppColors.signalEmerald).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text(pc.isLocked ? 'Unlock' : 'Lock',
                  style: gfont(AppType.bodySm,
                      color: hex(pc.isLocked
                          ? AppColors.error
                          : AppColors.signalEmerald),
                      weight: FontWeight.w600)),
            ),
          ),
        ]),
      );

  Widget _blockedKeysSection(ParentalControlService pc) {
    final toggleable = [
      (core.Key.power, 'Power', Icons.power_settings_new),
      (core.Key.volumeUp, 'Volume Up', Icons.volume_up),
      (core.Key.volumeDown, 'Volume Down', Icons.volume_down),
      (core.Key.mute, 'Mute', Icons.volume_off),
      (core.Key.input, 'Input Switch', Icons.input),
      (core.Key.home, 'Home', Icons.home),
      (core.Key.menu, 'Menu / Settings', Icons.menu),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Blocked Keys',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('These keys are disabled while locked',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant))),
          const SizedBox(height: AppSpacing.sm),
          for (final (key, label, icon) in toggleable)
            _keyToggle(pc, key, label, icon),
        ],
      ),
    );
  }

  Widget _keyToggle(
      ParentalControlService pc, core.Key key, String label, IconData icon) {
    final blocked = pc.blockedKeys.contains(key);
    return GestureDetector(
      onTap: () {
        final keys = Set.of(pc.blockedKeys);
        blocked ? keys.remove(key) : keys.add(key);
        pc.setBlockedKeys(keys);
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: hex(AppColors.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface))),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: blocked
                  ? hex(AppColors.error).withValues(alpha: 0.15)
                  : hex(AppColors.surfaceContainerHigh),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: blocked
                      ? hex(AppColors.error)
                      : hex(AppColors.outlineVariant)),
            ),
            child: blocked
                ? Icon(Icons.block, size: 14, color: hex(AppColors.error))
                : null,
          ),
        ]),
      ),
    );
  }

  Widget _timeLimitSection(ParentalControlService pc) {
    final presets = [0, 30, 60, 90, 120, 180];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Time Limit',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
              pc.maxDailyMinutes == 0
                  ? 'No limit set'
                  : '${pc.usedMinutes}/${pc.maxDailyMinutes} min used today',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant))),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets
                .map((m) => _limitChip(
                    pc, m, m == 0 ? 'None' : '${m}m'))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _limitChip(ParentalControlService pc, int minutes, String label) {
    final active = pc.maxDailyMinutes == minutes;
    return GestureDetector(
      onTap: () {
        pc.setMaxDailyMinutes(minutes);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? hex(AppColors.primaryContainer).withValues(alpha: 0.15)
              : hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(
            color: active
                ? hex(AppColors.primaryContainer).withValues(alpha: 0.5)
                : hex(AppColors.outlineVariant).withValues(alpha: 0.3),
          ),
        ),
        child: Text(label,
            style: gfont(AppType.bodySm,
                color: active
                    ? hex(AppColors.primary)
                    : hex(AppColors.onSurfaceVariant),
                weight: active ? FontWeight.w600 : FontWeight.w400,
                size: 12)),
      ),
    );
  }

  Widget _dangerZone(RemoteController c, ParentalControlService pc) =>
      GestureDetector(
        onTap: () => _showPinDialog(c, isRemove: true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(AppColors.error).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Center(
            child: Text('Remove PIN & Disable',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.error), weight: FontWeight.w600)),
          ),
        ),
      );

  void _showPinDialog(RemoteController c,
      {bool isSetup = false, bool isUnlock = false, bool isRemove = false}) {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: hex(AppColors.surfaceContainerLow),
          title: Text(
              isSetup
                  ? 'Set PIN'
                  : isRemove
                      ? 'Remove PIN'
                      : 'Enter PIN',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface), size: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style:
                    gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: '4-digit PIN',
                  hintStyle: gfont(AppType.bodySm,
                      color: hex(AppColors.outlineVariant)),
                  counterText: '',
                ),
              ),
              if (isSetup) ...[
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: confirmCtrl,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface)),
                  decoration: InputDecoration(
                    hintText: 'Confirm PIN',
                    hintStyle: gfont(AppType.bodySm,
                        color: hex(AppColors.outlineVariant)),
                    counterText: '',
                  ),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(error!,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.error), size: 11)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style:
                      gfont(AppType.bodySm, color: hex(AppColors.outline))),
            ),
            TextButton(
              onPressed: () {
                final pin = pinCtrl.text.trim();
                if (pin.length != 4) {
                  setDlg(() => error = 'PIN must be 4 digits');
                  return;
                }
                if (isSetup) {
                  if (pin != confirmCtrl.text.trim()) {
                    setDlg(() => error = 'PINs do not match');
                    return;
                  }
                  c.parentalControls.setPin(pin);
                } else if (isUnlock) {
                  if (!c.parentalControls.verifyPin(pin)) {
                    setDlg(() => error = 'Wrong PIN');
                    return;
                  }
                  c.parentalControls.unlock(pin);
                } else if (isRemove) {
                  if (!c.parentalControls.verifyPin(pin)) {
                    setDlg(() => error = 'Wrong PIN');
                    return;
                  }
                  c.parentalControls.clearPin(pin);
                }
                Navigator.pop(ctx);
                setState(() {});
              },
              child: Text('Confirm',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primaryContainer),
                      weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
