import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'package:video_player/video_player.dart';

import '../theme/tokens_x.dart';

class PlayerScreen extends StatefulWidget {
  final core.IptvChannel channel;
  const PlayerScreen({super.key, required this.channel});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  String? _error;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final uri = Uri.parse(widget.channel.url);
    _videoController = VideoPlayerController.networkUrl(uri,
        httpHeaders: const {'User-Agent': 'Sanketa/1.0'});

    try {
      await _videoController.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: hex(AppColors.primary),
          handleColor: hex(AppColors.primary),
          bufferedColor: hex(AppColors.primary).withValues(alpha: 0.3),
          backgroundColor: hex(AppColors.outlineVariant),
        ),
        errorBuilder: (ctx, msg) => _errorWidget(msg),
      );

      setState(() => _initializing = false);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = _humanError(e);
      });
    }
  }

  static String _humanError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('source error') || msg.contains('unable to connect')) {
      return 'Stream unavailable. The channel may be offline or geo-restricted.';
    }
    if (msg.contains('format') || msg.contains('codec')) {
      return 'Unsupported stream format. Try opening in an external player.';
    }
    if (msg.contains('timed out') || msg.contains('timeout')) {
      return 'Connection timed out. Check your network or try again.';
    }
    return 'Could not play this stream. Try an external player.';
  }

  Widget _errorWidget(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.error_outline,
                size: 48, color: hex(AppColors.outlineVariant)),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _initializing = true;
                  _error = null;
                });
                _videoController.dispose();
                _chewieController?.dispose();
                _chewieController = null;
                _initPlayer();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: hex(AppColors.primaryContainer),
                foregroundColor: hex(AppColors.onPrimaryContainer),
              ),
            ),
          ]),
        ),
      );

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.channel.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: gfont(AppType.bodySm,
                color: Colors.white, size: 15, weight: FontWeight.w500)),
        actions: [
          if (widget.channel.groupTitle != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.base),
                  ),
                  child: Text(widget.channel.groupTitle!,
                      style: gfont(AppType.bodySm,
                          color: Colors.white70, size: 11)),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: AppSpacing.md),
          Text('Connecting to stream...',
              style: gfont(AppType.bodySm, color: Colors.white70)),
        ]),
      );
    }

    if (_error != null) {
      return _errorWidget(_error!);
    }

    if (_chewieController != null) {
      return Center(child: Chewie(controller: _chewieController!));
    }

    return const SizedBox.shrink();
  }
}
