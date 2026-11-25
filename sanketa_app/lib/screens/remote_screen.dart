import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../control/sleep_timer_service.dart';
import '../control/voice_control_service.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';
import '../widgets/connection_bar.dart';
import '../widgets/honesty_banner.dart';
import '../widgets/quick_actions_sheet.dart';
import '../widgets/remote_pad.dart';
import '../widgets/touchpad_surface.dart';
import '../widgets/tv_keyboard_sheet.dart';
import 'settings_screen.dart';

/// The primary remote-control surface. Lives inside [AppShell]'s IndexedStack
/// at index 0. No longer owns a Scaffold or bottom nav — those belong to the
/// shell.
class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  bool _touchpadMode = false;

  void _showVoiceSheet(BuildContext context, RemoteController c) {
    final vc = c.voiceControl;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: hex(AppColors.surface),
      builder: (_) => _VoiceListenSheet(
        voiceControl: vc,
        onCommand: (cmd) {
          if (cmd.isText) {
            c.type(cmd.label);
          } else {
            for (final k in cmd.keys) {
              c.key(k);
            }
          }
        },
      ),
    );
  }

  void _showSleepTimerPicker() {
    final c = RemoteScope.of(context);
    showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: hex(AppColors.surface),
      builder: (_) => _SleepTimerPicker(active: c.sleepTimer.isActive),
    ).then((d) {
      if (d == null) {
        if (c.sleepTimer.isActive) c.sleepTimer.cancel();
        return;
      }
      c.startSleepTimer(d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    return Column(children: [
      _header(context, c),
      Expanded(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Column(
                children: [
                  const ConnectionBar(),
                  ListenableBuilder(
                    listenable: c.stateReadback,
                    builder: (_, _) => HonestyBanner(
                      label: c.stateReadback.honestyLabel,
                      reportsState: c.stateReadback.adapterReportsState,
                    ),
                  ),
                  if (c.connectionError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ErrorBanner(
                      message: c.connectionError!,
                      onRetry: c.retryConnection,
                    ),
                  ],
                  if (c.lastCommandError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _ErrorBanner(
                      message: c.lastCommandError!,
                      onDismiss: c.clearCommandError,
                    ),
                  ],
                  ListenableBuilder(
                    listenable: c.sleepTimer,
                    builder: (_, _) => c.sleepTimer.isActive
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: _SleepTimerBadge(
                              timer: c.sleepTimer,
                              onTap: _showSleepTimerPicker,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ModeToggle(
                    touchpadMode: _touchpadMode,
                    onChanged: (v) => setState(() => _touchpadMode = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const TvKeyboardSheet(),
                  const SizedBox(height: AppSpacing.md),
                  if (_touchpadMode)
                    const TouchpadSurface()
                  else
                    const RemotePad(),
                  const SizedBox(height: AppSpacing.md),
                  const _SentReadout(),
                ],
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _header(BuildContext context, RemoteController c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surface),
          border: Border(bottom: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.6))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hex(AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                ),
                child: Image.asset('assets/images/sanketa_logo.png', width: 20, height: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Sanketa',
                            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: hex(AppColors.surfaceContainerHighest),
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Text(c.transportBadge, style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurfaceVariant), size: 10)),
                        ),
                      ],
                    ),
                    Text(c.deviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
                  ],
                ),
              ),
              Semantics(
                label: 'Sleep timer',
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _showSleepTimerPicker,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(Icons.bedtime_outlined, size: 18),
                    ),
                  ),
                ),
              ),
              Semantics(
                label: 'Quick actions',
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showQuickActionsSheet(context),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(Icons.bolt, size: 18),
                    ),
                  ),
                ),
              ),
              Semantics(
                label: 'Voice input',
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showVoiceSheet(context, c),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(Icons.mic_none, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RemoteScope(
                      controller: c,
                      child: const SettingsScreen(),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Icon(Icons.tune, size: 20, color: hex(AppColors.onSurfaceVariant)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );

}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onRetry, this.onDismiss});

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: hex(AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.error).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: hex(AppColors.error)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 12)),
          ),
          if (onRetry != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRetry,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text('Retry',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primaryContainer),
                        weight: FontWeight.w600, size: 12)),
              ),
            ),
          if (onDismiss != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close,
                    size: 16, color: hex(AppColors.onSurfaceVariant)),
              ),
            ),
        ],
      ),
    );
  }
}

/// A live mono readout of the last commands the UI sent through the contract —
/// visible proof the whole screen is wired to a real [ControlAdapter].
class _SentReadout extends StatelessWidget {
  const _SentReadout();

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final last = c.actionLog.take(3).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: panel(fill: AppColors.surfaceContainerLowest, radius: AppRadii.md, borderOpacity: 0.25),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SENT TO TV (via ControlAdapter)',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
        const SizedBox(height: 4),
        if (last.isEmpty)
          Text('— press any control —', style: gfont(AppType.labelMonoSm, color: hex(AppColors.outlineVariant)))
        else
          for (final a in last)
            Text(a, style: gfont(AppType.labelMonoSm, color: hex(AppColors.tertiary))),
      ]),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.touchpadMode, required this.onChanged});
  final bool touchpadMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _chip('D-pad', !touchpadMode, () => onChanged(false)),
          const SizedBox(width: 8),
          _chip('Touchpad', touchpadMode, () => onChanged(true)),
        ],
      );

  Widget _chip(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
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
                  color: active ? hex(AppColors.primary) : hex(AppColors.onSurfaceVariant),
                  weight: active ? FontWeight.w600 : FontWeight.w400,
                  size: 12)),
        ),
      );
}

class _SleepTimerBadge extends StatelessWidget {
  const _SleepTimerBadge({required this.timer, required this.onTap});
  final SleepTimerService timer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: hex(AppColors.tertiary).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Icon(Icons.bedtime, size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 8),
            Text('Sleep timer: ${timer.label}',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.tertiary), weight: FontWeight.w500, size: 12)),
            const Spacer(),
            Text('Tap to change',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
          ]),
        ),
      );
}

class _SleepTimerPicker extends StatelessWidget {
  const _SleepTimerPicker({this.active = false});
  final bool active;

  static const _presets = [
    (Duration(minutes: 15), '15 min'),
    (Duration(minutes: 30), '30 min'),
    (Duration(minutes: 45), '45 min'),
    (Duration(hours: 1), '1 hour'),
    (Duration(hours: 1, minutes: 30), '1.5 hours'),
    (Duration(hours: 2), '2 hours'),
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sleep Timer',
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('TV will power off after the timer expires',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets
                    .map((p) => _timerChip(context, p.$1, p.$2))
                    .toList(),
              ),
              if (active) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: hex(AppColors.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Center(
                        child: Text('Cancel Timer',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.error), weight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _timerChip(BuildContext context, Duration d, String label) =>
      GestureDetector(
        onTap: () => Navigator.of(context).pop(d),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface), weight: FontWeight.w500)),
        ),
      );
}

class _VoiceListenSheet extends StatefulWidget {
  const _VoiceListenSheet({required this.voiceControl, required this.onCommand});
  final VoiceControlService voiceControl;
  final void Function(VoiceCommand) onCommand;

  @override
  State<_VoiceListenSheet> createState() => _VoiceListenSheetState();
}

class _VoiceListenSheetState extends State<_VoiceListenSheet> {
  @override
  void initState() {
    super.initState();
    widget.voiceControl.addListener(_onUpdate);
    widget.voiceControl.startListening();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    final cmd = widget.voiceControl.lastCommand;
    if (cmd != null && !widget.voiceControl.isListening) {
      widget.onCommand(cmd);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    widget.voiceControl.removeListener(_onUpdate);
    widget.voiceControl.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vc = widget.voiceControl;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              vc.isListening ? Icons.mic : Icons.mic_off,
              size: 48,
              color: hex(vc.isListening
                  ? AppColors.primaryContainer
                  : AppColors.outlineVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              vc.isListening
                  ? 'Listening...'
                  : vc.error ?? 'Say a command',
              style: gfont(AppType.bodyMd,
                  color: hex(vc.error != null
                      ? AppColors.error
                      : AppColors.onSurface),
                  weight: FontWeight.w600),
            ),
            if (vc.transcript.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('"${vc.transcript}"',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.tertiary))),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Try: "volume up", "mute", "home", "channel up"',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!vc.isListening && vc.error != null)
              GestureDetector(
                onTap: () => vc.startListening(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(AppColors.primaryContainer),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Text('Try Again',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.surface),
                          weight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
