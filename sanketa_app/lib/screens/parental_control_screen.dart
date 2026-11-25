import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/parental_control_service.dart';
import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final pc = c.parentalControls;

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Parental Controls',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: ListenableBuilder(
        listenable: pc,
        builder: (_, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: pc.isEnabled ? _activeView(pc) : _setupView(pc),
          ),
        ),
      ),
    );
  }

  Widget _setupView(ParentalControlService pc) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined,
                  size: 56,
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.lg),
              Text('Set up parental controls',
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface),
                      size: 18,
                      weight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                  'Create a 4-digit PIN to restrict TV access,\nblock certain keys, and set daily time limits.',
                  textAlign: TextAlign.center,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant))),
              const SizedBox(height: AppSpacing.xl),
              _actionButton('Set PIN', AppColors.primaryContainer, () {
                _showPinDialog('Create PIN', (pin) {
                  pc.setPin(pin);
                });
              }),
            ],
          ),
        ),
      );

  Widget _activeView(ParentalControlService pc) => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _lockCard(pc),
          const SizedBox(height: AppSpacing.md),
          _blockedKeysCard(pc),
          const SizedBox(height: AppSpacing.md),
          _timeLimitCard(pc),
          const SizedBox(height: AppSpacing.md),
          _usageMeter(pc),
          const SizedBox(height: AppSpacing.xl),
          _actionButton('Reset Daily Usage', AppColors.tertiary, () {
            pc.resetDailyUsage();
          }),
          const SizedBox(height: AppSpacing.sm),
          _actionButton('Remove PIN', AppColors.error, () {
            _showPinDialog('Enter PIN to remove', (pin) {
              pc.clearPin(pin);
            });
          }),
        ],
      );

  Widget _lockCard(ParentalControlService pc) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(
          borderColor:
              pc.isLocked ? AppColors.error : AppColors.signalEmerald,
          borderOpacity: 0.5,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hex(pc.isLocked ? AppColors.error : AppColors.signalEmerald)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(
                pc.isLocked ? Icons.lock : Icons.lock_open,
                color: hex(pc.isLocked ? AppColors.error : AppColors.signalEmerald),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pc.isLocked ? 'Controls Locked' : 'Controls Unlocked',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600)),
                  Text(
                      pc.isLocked
                          ? 'Blocked keys are restricted'
                          : 'All keys available',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant))),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (pc.isLocked) {
                  _showPinDialog('Enter PIN to unlock', (pin) {
                    pc.unlock(pin);
                  });
                } else {
                  pc.lock();
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(pc.isLocked
                          ? AppColors.signalEmerald
                          : AppColors.error)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.base),
                ),
                child: Text(
                  pc.isLocked ? 'Unlock' : 'Lock',
                  style: gfont(AppType.bodySm,
                      color: hex(pc.isLocked
                          ? AppColors.signalEmerald
                          : AppColors.error),
                      weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _blockedKeysCard(ParentalControlService pc) {
    const keyGroups = <(String, List<core.Key>)>[
      ('Power', [core.Key.power, core.Key.powerOn, core.Key.powerOff]),
      ('Volume', [core.Key.volumeUp, core.Key.volumeDown, core.Key.mute]),
      ('Channel', [core.Key.channelUp, core.Key.channelDown]),
      ('Navigation', [core.Key.home, core.Key.back, core.Key.menu]),
      ('Input', [core.Key.input, core.Key.source]),
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
          const SizedBox(height: AppSpacing.sm),
          Text('Select keys to restrict when locked',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant))),
          const SizedBox(height: AppSpacing.md),
          for (final (group, keys) in keyGroups) ...[
            _keyGroupRow(pc, group, keys),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _keyGroupRow(
      ParentalControlService pc, String label, List<core.Key> keys) {
    final allBlocked = keys.every(pc.blockedKeys.contains);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final updated = Set<core.Key>.from(pc.blockedKeys);
        if (allBlocked) {
          updated.removeAll(keys);
        } else {
          updated.addAll(keys);
        }
        pc.setBlockedKeys(updated);
      },
      child: Row(
        children: [
          Icon(
            allBlocked ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: hex(allBlocked
                ? AppColors.primaryContainer
                : AppColors.outlineVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
          const Spacer(),
          Text('${keys.length} keys',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant), size: 11)),
        ],
      ),
    );
  }

  static const _timePresets = <(int, String)>[
    (30, '30m'),
    (60, '1h'),
    (120, '2h'),
    (180, '3h'),
    (0, 'None'),
  ];

  Widget _timeLimitCard(ParentalControlService pc) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Time Limit',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timePresets.map((p) {
                final active = pc.maxDailyMinutes == p.$1;
                return GestureDetector(
                  onTap: () => pc.setMaxDailyMinutes(p.$1),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? hex(AppColors.primaryContainer)
                              .withValues(alpha: 0.15)
                          : hex(AppColors.surfaceContainerLow),
                      borderRadius: BorderRadius.circular(AppRadii.base),
                      border: Border.all(
                        color: active
                            ? hex(AppColors.primaryContainer)
                                .withValues(alpha: 0.5)
                            : hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(p.$2,
                        style: gfont(AppType.bodySm,
                            color: hex(active
                                ? AppColors.primary
                                : AppColors.onSurface),
                            weight:
                                active ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _usageMeter(ParentalControlService pc) {
    final max = pc.maxDailyMinutes;
    final used = pc.usedMinutes;
    final progress = max > 0 ? (used / max).clamp(0.0, 1.0) : 0.0;
    final exceeded = pc.timeLimitExceeded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(
        borderColor: exceeded ? AppColors.error : AppColors.outlineVariant,
        borderOpacity: exceeded ? 0.5 : 0.3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Today\'s Usage',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
              const Spacer(),
              Text(
                max > 0
                    ? '${used}m / ${max}m'
                    : '${used}m',
                style: gfont(AppType.labelMonoSm,
                    color: hex(exceeded
                        ? AppColors.error
                        : AppColors.onSurfaceVariant)),
              ),
            ],
          ),
          if (max > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    hex(AppColors.surfaceContainerHigh),
                valueColor: AlwaysStoppedAnimation(
                  hex(exceeded ? AppColors.error : AppColors.primaryContainer),
                ),
                minHeight: 8,
              ),
            ),
          ],
          if (exceeded) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Time limit reached — controls are locked',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.error),
                    weight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  Widget _actionButton(String label, int color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(color).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(color).withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(label,
                style: gfont(AppType.bodyMd,
                    color: hex(color), weight: FontWeight.w600)),
          ),
        ),
      );

  void _showPinDialog(String title, void Function(String) onConfirm) {
    final ctrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLow),
        title: Text(title,
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          style: gfont(AppType.headlineMd,
              color: hex(AppColors.onSurface), size: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '• • • •',
            hintStyle: gfont(AppType.headlineMd,
                color: hex(AppColors.outlineVariant), size: 24),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              final pin = ctrl.text.trim();
              if (pin.length == 4) {
                Navigator.of(ctx).pop();
                onConfirm(pin);
              }
            },
            child: Text('Confirm',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.primaryContainer),
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
