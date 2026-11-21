import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';
import '../widgets/connection_bar.dart';
import '../widgets/remote_pad.dart';
import '../widgets/tv_keyboard_sheet.dart';
import 'settings_screen.dart';

/// The primary remote-control surface. Lives inside [AppShell]'s IndexedStack
/// at index 0. No longer owns a Scaffold or bottom nav — those belong to the
/// shell.
class RemoteScreen extends StatelessWidget {
  const RemoteScreen({super.key});

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
                  const SizedBox(height: AppSpacing.md),
                  const TvKeyboardSheet(),
                  const SizedBox(height: AppSpacing.md),
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
              Flexible(flex: 0, child: _pill(Icons.keyboard, 'TV Keyboard')),
              const SizedBox(width: 4),
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

  Widget _pill(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(color: hex(AppColors.primaryContainer).withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: hex(AppColors.primaryContainer)),
          const SizedBox(width: 6),
          Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w500)),
        ]),
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
