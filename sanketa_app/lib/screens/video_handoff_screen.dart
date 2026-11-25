import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class VideoHandoffScreen extends StatefulWidget {
  const VideoHandoffScreen({super.key});

  @override
  State<VideoHandoffScreen> createState() => _VideoHandoffScreenState();
}

class _VideoHandoffScreenState extends State<VideoHandoffScreen> {
  final _urlCtrl = TextEditingController();
  bool _sending = false;
  String? _lastResult;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final connected = c.tvHost != null;

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Video Hand-off',
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
              _heroCard(connected),
              const SizedBox(height: AppSpacing.md),
              _urlInputCard(c, connected),
              const SizedBox(height: AppSpacing.md),
              _supportedAppsCard(),
              const SizedBox(height: AppSpacing.md),
              _howItWorksCard(),
              const SizedBox(height: AppSpacing.md),
              _privacyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroCard(bool connected) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: panel(
            borderColor: AppColors.primaryContainer, borderOpacity: 0.3),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color:
                    hex(AppColors.primaryContainer).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cast,
                  size: 28, color: hex(AppColors.primaryContainer)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Send Video to TV',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 16,
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              connected
                  ? 'Paste a URL or share from your browser'
                  : 'Connect to a TV first',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant)),
            ),
            if (!connected) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(AppColors.tertiary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber,
                        size: 14, color: hex(AppColors.tertiary)),
                    const SizedBox(width: 4),
                    Text('No TV connected',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.tertiary),
                            size: 11,
                            weight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _urlInputCard(RemoteController c, bool connected) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Video URL',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlCtrl,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface)),
                      decoration: InputDecoration(
                        hintText: 'https://youtube.com/watch?v=...',
                        hintStyle: gfont(AppType.bodySm,
                            color: hex(AppColors.outlineVariant)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pasteFromClipboard,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.content_paste,
                          size: 20,
                          color: hex(AppColors.primaryContainer)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: connected && _urlCtrl.text.trim().isNotEmpty && !_sending
                        ? () => _sendUrl(c)
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: connected && _urlCtrl.text.trim().isNotEmpty
                            ? hex(AppColors.primaryContainer)
                            : hex(AppColors.surfaceContainerHigh),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Center(
                        child: _sending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        hex(AppColors.surface))))
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.send,
                                      size: 16,
                                      color: connected &&
                                              _urlCtrl.text.trim().isNotEmpty
                                          ? hex(AppColors.surface)
                                          : hex(AppColors.outlineVariant)),
                                  const SizedBox(width: 6),
                                  Text('Send to TV',
                                      style: gfont(AppType.bodyMd,
                                          color: connected &&
                                                  _urlCtrl
                                                      .text
                                                      .trim()
                                                      .isNotEmpty
                                              ? hex(AppColors.surface)
                                              : hex(AppColors.outlineVariant),
                                          weight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_lastResult != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_lastResult!,
                  style: gfont(AppType.bodySm,
                      color: _lastResult!.startsWith('Sent')
                          ? hex(AppColors.signalEmerald)
                          : hex(AppColors.error),
                      size: 11)),
            ],
          ],
        ),
      );

  Widget _supportedAppsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Supported Sources',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('URLs from these platforms can be opened on your TV',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _appChip('YouTube'),
                _appChip('Twitch'),
                _appChip('Vimeo'),
                _appChip('Dailymotion'),
                _appChip('Plex'),
                _appChip('Direct MP4/HLS'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'DRM-protected content (Netflix, Prime, Disney+) cannot be '
              'redirected. Those services have their own cast features.',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outlineVariant), size: 11),
            ),
          ],
        ),
      );

  Widget _appChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hex(AppColors.primaryContainer).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Text(label,
            style: gfont(AppType.bodySm,
                color: hex(AppColors.primaryContainer),
                size: 11,
                weight: FontWeight.w500)),
      );

  Widget _howItWorksCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How It Works',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            _stepRow(1, 'Share', 'Tap Share in your browser or paste a URL here'),
            _stepRow(2, 'Resolve', 'Sanketa extracts the direct video stream URL'),
            _stepRow(
                3, 'Play', 'The TV\'s built-in player opens the video stream'),
          ],
        ),
      );

  Widget _stepRow(int num, String title, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    hex(AppColors.primaryContainer).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$num',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.primaryContainer),
                        size: 11,
                        weight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w500)),
                  Text(desc,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _privacyCard() => Container(
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
                'URLs are sent directly to your TV over the local network. '
                'Nothing passes through Sanketa servers.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 11),
              ),
            ),
          ],
        ),
      );

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlCtrl.text = data.text!;
      setState(() {});
    }
  }

  Future<void> _sendUrl(RemoteController c) async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _sending = true;
      _lastResult = null;
    });

    try {
      final result = await c.launchUrl(url);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lastResult = result.ok ? 'Sent to TV' : (result.error ?? 'Failed to send');
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lastResult = 'Error: $e';
      });
    }
  }
}
