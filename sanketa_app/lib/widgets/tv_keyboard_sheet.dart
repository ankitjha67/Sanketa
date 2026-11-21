import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'common.dart';

/// The hero feature (FR-4): a phone keyboard whose keystrokes stream to the TV's
/// focused field, with a live "sent to TV" mirror. Every tap routes through the
/// [ControlAdapter] via [RemoteController].
class TvKeyboardSheet extends StatefulWidget {
  const TvKeyboardSheet({super.key});

  @override
  State<TvKeyboardSheet> createState() => _TvKeyboardSheetState();
}

class _TvKeyboardSheetState extends State<TvKeyboardSheet> {
  bool _pairing = false;
  bool _expanded = true;

  static const _rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
  static const _numRows = ['1234567890', '-+*/#@&!?', '.,;:()'];

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(c),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.sm),
            _preview(c),
            const SizedBox(height: AppSpacing.sm),
            _cursorBar(c),
            const SizedBox(height: AppSpacing.sm),
            ..._keyboard(c),
          ],
        ],
      ),
    );
  }

  Widget _header(RemoteController c) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.base),
          border: Border.all(
            color: hex(AppColors.primaryContainer).withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          Icons.keyboard,
          size: 16,
          color: hex(AppColors.primaryContainer),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    'TV Search & Text Sync',
                    overflow: TextOverflow.ellipsis,
                    style: gfont(
                      AppType.bodySm,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (c.needsAtvrsPairing)
                  _pairButton(c)
                else if (c.isConnected)
                  _livePill(),
              ],
            ),
            Text(
              'Type here, see it on ${c.deviceName}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline)),
            ),
          ],
        ),
      ),
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            _expanded ? Icons.keyboard_hide : Icons.keyboard,
            size: 18,
            color: hex(AppColors.onSurfaceVariant),
          ),
        ),
      ),
    ],
  );

  Widget _pairButton(RemoteController c) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _pairing ? null : () => _startPairing(c),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        _pairing ? 'Pairing…' : 'Pair with TV',
        style: gfont(
          AppType.labelMonoSm,
          color: hex(AppColors.primaryContainer),
          size: 10,
        ),
      ),
    ),
  );

  Future<void> _startPairing(RemoteController c) async {
    setState(() => _pairing = true);
    final ok = await c.pairAtvrs(() async {
      final pin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PinDialog(),
      );
      return pin ?? '';
    });
    if (mounted) {
      setState(() => _pairing = false);
      if (!ok && c.pairingError != null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(c.pairingError!),
            duration: const Duration(seconds: 4),
          ));
      }
    }
  }

  Widget _livePill() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: hex(AppColors.tertiaryContainer).withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(AppRadii.full),
      border: Border.all(
        color: hex(AppColors.tertiaryContainer).withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PulseDot(color: hex(AppColors.tertiary), size: 6),
        const SizedBox(width: 4),
        Text(
          'Live Mirrored',
          style: gfont(
            AppType.labelMonoSm,
            color: hex(AppColors.tertiary),
            size: 10,
          ),
        ),
      ],
    ),
  );

  Widget _preview(RemoteController c) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: panel(
      fill: AppColors.surfaceContainerLow,
      radius: AppRadii.md,
      borderOpacity: 0.4,
    ),
    child: Row(
      children: [
        Icon(Icons.search, size: 16, color: hex(AppColors.outline)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            c.tvText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
          ),
        ),
        Container(width: 2, height: 16, color: hex(AppColors.primaryContainer)),
        const SizedBox(width: 8),
        _textButton('CLEAR', onTap: c.clearText),
      ],
    ),
  );

  Widget _cursorBar(RemoteController c) => Row(
    children: [
      Text(
        'TV CURSOR:',
        style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline)),
      ),
      const SizedBox(width: 6),
      _miniKey(Icons.chevron_left, () => c.key(core.Key.left)),
      const SizedBox(width: 4),
      _miniKey(Icons.chevron_right, () => c.key(core.Key.right)),
      const Spacer(),
      Flexible(child: _enterToTv(c)),
    ],
  );

  Widget _enterToTv(RemoteController c) => _tap(
    onTap: c.submit,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: hex(AppColors.primaryContainer),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard_return,
            size: 14,
            color: hex(AppColors.onPrimaryContainer),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Enter to TV',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: gfont(
                AppType.bodySm,
                color: hex(AppColors.onPrimaryContainer),
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _keyboard(RemoteController c) {
    final rows = c.numberMode ? _numRows : _rows;
    return [
      _charRow(rows[0], c),
      const SizedBox(height: 6),
      _charRow(rows[1], c),
      const SizedBox(height: 6),
      Row(
        children: [
          if (!c.numberMode) ...[
            _utilKey(
              child: Icon(
                Icons.arrow_upward,
                size: 14,
                color: c.capsLock
                    ? hex(AppColors.primaryContainer)
                    : hex(AppColors.onSurfaceVariant),
              ),
              onTap: c.toggleCaps,
              active: c.capsLock,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(child: _charRow(rows[2], c)),
          const SizedBox(width: 4),
          _utilKey(
            child: Icon(
              Icons.backspace_outlined,
              size: 16,
              color: hex(AppColors.onSurfaceVariant),
            ),
            onTap: c.backspace,
          ),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          _utilKey(
            label: c.numberMode ? 'ABC' : '123',
            onTap: c.toggleNumbers,
            active: c.numberMode,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _tap(
              onTap: () => c.type(' '),
              child: Container(
                height: 38,
                alignment: Alignment.center,
                decoration: panel(
                  fill: AppColors.surfaceContainerHigh,
                  radius: AppRadii.sm,
                  borderOpacity: 0.2,
                ),
                child: Text(
                  'space',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _tap(
            onTap: c.submit,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search,
                    size: 13,
                    color: hex(AppColors.onPrimaryContainer),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Search',
                    style: gfont(
                      AppType.bodySm,
                      color: hex(AppColors.onPrimaryContainer),
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _charRow(String chars, RemoteController c) => Row(
    children: [
      for (var i = 0; i < chars.length; i++) ...[
        if (i > 0) const SizedBox(width: 4),
        Expanded(
          child: _tap(
            onTap: () => c.type(
              c.numberMode || c.capsLock ? chars[i] : chars[i].toLowerCase(),
            ),
            child: Container(
              height: 38,
              alignment: Alignment.center,
              decoration: panel(
                fill: AppColors.surfaceContainerHigh,
                radius: AppRadii.sm,
                borderOpacity: 0.2,
              ),
              child: Text(
                c.numberMode || c.capsLock ? chars[i] : chars[i].toLowerCase(),
                style: gfont(
                  AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _utilKey({
    String? label,
    Widget? child,
    required VoidCallback onTap,
    bool active = false,
  }) => _tap(
    onTap: onTap,
    child: Container(
      height: 38,
      width: 44,
      alignment: Alignment.center,
      decoration: panel(
        fill: active
            ? AppColors.surfaceContainerHighest
            : AppColors.surfaceContainer,
        radius: AppRadii.sm,
        borderOpacity: active ? 0.5 : 0.25,
        borderColor: active
            ? AppColors.primaryContainer
            : AppColors.outlineVariant,
      ),
      child:
          child ??
          Text(
            label!,
            style: gfont(
              AppType.bodySm,
              color: hex(AppColors.onSurface),
              weight: FontWeight.w600,
            ),
          ),
    ),
  );

  Widget _miniKey(IconData icon, VoidCallback onTap) => _tap(
    onTap: onTap,
    child: Container(
      width: 28,
      height: 24,
      alignment: Alignment.center,
      decoration: panel(
        fill: AppColors.surfaceContainer,
        radius: AppRadii.sm,
        borderOpacity: 0.3,
      ),
      child: Icon(icon, size: 14, color: hex(AppColors.onSurface)),
    ),
  );

  Widget _textButton(String text, {required VoidCallback onTap}) => _tap(
    onTap: onTap,
    child: Text(
      text,
      style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline)),
    ),
  );

  Widget _tap({required Widget child, required VoidCallback onTap}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
}

class _PinDialog extends StatefulWidget {
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: hex(AppColors.surfaceContainerLowest),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.lg),
    ),
    title: Text(
      'Enter pairing code',
      style: gfont(
        AppType.bodyMd,
        color: hex(AppColors.onSurface),
        weight: FontWeight.w700,
      ),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter the code shown on your TV',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _ctrl,
          autofocus: true,
          textAlign: TextAlign.center,
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
          decoration: InputDecoration(
            hintText: 'e.g. A1B2C3',
            hintStyle: gfont(
              AppType.bodyMd,
              color: hex(AppColors.outline).withValues(alpha: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: hex(AppColors.outlineVariant)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(
                color: hex(AppColors.primaryContainer),
                width: 2,
              ),
            ),
          ),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(null),
        child: Text(
          'Cancel',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
        ),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
        child: Text(
          'Pair',
          style: gfont(
            AppType.bodySm,
            color: hex(AppColors.primaryContainer),
            weight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
