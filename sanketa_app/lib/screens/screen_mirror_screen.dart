import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../native/screen_mirror_bridge.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class ScreenMirrorScreen extends StatefulWidget {
  const ScreenMirrorScreen({super.key});

  @override
  State<ScreenMirrorScreen> createState() => _ScreenMirrorScreenState();
}

class _ScreenMirrorScreenState extends State<ScreenMirrorScreen> {
  final _bridge = ScreenMirrorBridge();
  bool _starting = false;
  String? _error;
  MirrorMode _mode = MirrorMode.ws;

  @override
  void dispose() {
    if (_bridge.isActive) _bridge.stopMirror();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Screen Mirroring',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _statusCard(),
              const SizedBox(height: AppSpacing.md),
              _modeSelector(),
              const SizedBox(height: AppSpacing.md),
              _actionButton(),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                _errorCard(),
              ],
              const SizedBox(height: AppSpacing.md),
              _infoSection(),
              const SizedBox(height: AppSpacing.md),
              _privacyNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard() {
    final active = _bridge.isActive;
    final color = active ? AppColors.signalEmerald : AppColors.outlineVariant;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: panel(borderColor: color, borderOpacity: active ? 0.5 : 0.3),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: hex(color).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              active ? Icons.cast_connected : Icons.cast,
              size: 36,
              color: hex(color),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            active ? 'Mirroring Active' : 'Ready to Mirror',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            active
                ? 'Your screen is being cast to the TV'
                : 'Cast your phone screen to your TV',
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _modeSelector() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cast Mode',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _modeChip('WebSocket', MirrorMode.ws)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _modeChip('HLS', MirrorMode.hls)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _mode == MirrorMode.ws
                ? 'Lower latency, requires direct connection'
                : 'More compatible, slight delay',
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant), size: 11),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, MirrorMode mode) {
    final active = _mode == mode;
    return GestureDetector(
      onTap: _bridge.isActive ? null : () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? hex(AppColors.primaryContainer).withValues(alpha: 0.15)
              : hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: active
                ? hex(AppColors.primaryContainer).withValues(alpha: 0.5)
                : hex(AppColors.outlineVariant).withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(label,
              style: gfont(AppType.bodySm,
                  color:
                      hex(active ? AppColors.primary : AppColors.onSurface),
                  weight: active ? FontWeight.w600 : FontWeight.w400)),
        ),
      ),
    );
  }

  Widget _actionButton() {
    final active = _bridge.isActive;
    final color = active ? AppColors.error : AppColors.primaryContainer;

    return GestureDetector(
      onTap: _starting ? null : (active ? _stop : _start),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: hex(color).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(color).withValues(alpha: 0.3)),
        ),
        child: Center(
          child: _starting
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(hex(color))))
              : Text(
                  active ? 'Stop Mirroring' : 'Start Mirroring',
                  style: gfont(AppType.bodyMd,
                      color: hex(color), weight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _errorCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(borderColor: AppColors.error, borderOpacity: 0.4),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 18, color: hex(AppColors.error)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(_error!,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.error), size: 12)),
            ),
          ],
        ),
      );

  Widget _infoSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How it works',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            _infoRow(Icons.screen_share, 'Phone captures the screen'),
            _infoRow(Icons.wifi, 'Streams over your local network'),
            _infoRow(Icons.tv, 'TV displays the feed in real-time'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'DRM-protected apps (Netflix, Prime, etc.) will show a '
              'black screen — this is by design, not a bug.',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant), size: 11),
            ),
          ],
        ),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(AppColors.primaryContainer)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(text,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface))),
            ),
          ],
        ),
      );

  Widget _privacyNote() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration:
            panel(fill: AppColors.surfaceContainerLowest, borderOpacity: 0.2),
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 18, color: hex(AppColors.signalEmerald)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Screen data stays on your local network. '
                'Nothing is sent to any external server.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 11),
              ),
            ),
          ],
        ),
      );

  Future<void> _start() async {
    final c = RemoteScope.of(context);
    if (c.tvHost == null) {
      setState(() => _error = 'No TV connected — connect to a TV first');
      return;
    }

    setState(() {
      _starting = true;
      _error = null;
    });

    final result = await _bridge.startMirror(mode: _mode);
    if (!mounted) return;

    if (result == null) {
      setState(() {
        _starting = false;
        _error = 'Could not start screen capture. '
            'Make sure you granted the screen recording permission.';
      });
      return;
    }

    setState(() => _starting = false);
  }

  Future<void> _stop() async {
    await _bridge.stopMirror();
    if (mounted) setState(() {});
  }
}
