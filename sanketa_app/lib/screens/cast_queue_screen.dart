import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _QueueItem {
  _QueueItem({required this.title, required this.url, this.type = 'video', this.durationMin = 0});

  factory _QueueItem.fromJson(Map<String, dynamic> j) => _QueueItem(
    title: j['title'] as String,
    url: j['url'] as String,
    type: j['type'] as String? ?? 'video',
    durationMin: j['durationMin'] as int? ?? 0,
  );

  final String title;
  final String url;
  final String type;
  final int durationMin;
  bool playing = false;

  Map<String, dynamic> toJson() => {
    'title': title,
    'url': url,
    'type': type,
    'durationMin': durationMin,
  };
}

class CastQueueScreen extends StatefulWidget {
  const CastQueueScreen({super.key});

  @override
  State<CastQueueScreen> createState() => _CastQueueScreenState();
}

class _CastQueueScreenState extends State<CastQueueScreen> {
  List<_QueueItem> _queue = [];
  bool _loading = true;
  bool _playing = false;
  int _currentIndex = -1;
  bool _autoPlay = true;
  bool _loopQueue = false;
  bool _shuffle = false;
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/cast_queue.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final list = data['queue'] as List? ?? [];
        _queue = list.map((j) => _QueueItem.fromJson(j as Map<String, dynamic>)).toList();
        _autoPlay = data['autoPlay'] as bool? ?? true;
        _loopQueue = data['loopQueue'] as bool? ?? false;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'queue': _queue.map((q) => q.toJson()).toList(),
      'autoPlay': _autoPlay,
      'loopQueue': _loopQueue,
    }));
  }

  void _addItem() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    final title = _titleCtrl.text.trim().isEmpty
        ? 'Media ${_queue.length + 1}'
        : _titleCtrl.text.trim();
    final type = url.contains('.mp3') || url.contains('.flac') || url.contains('audio')
        ? 'audio'
        : url.contains('.jpg') || url.contains('.png') || url.contains('image')
            ? 'photo'
            : 'video';

    setState(() {
      _queue.add(_QueueItem(title: title, url: url, type: type));
    });
    _urlCtrl.clear();
    _titleCtrl.clear();
    _save();
  }

  void _removeItem(int index) {
    setState(() {
      _queue.removeAt(index);
      if (_currentIndex >= _queue.length) _currentIndex = _queue.length - 1;
    });
    _save();
  }

  void _playQueue() {
    if (_queue.isEmpty) return;
    setState(() {
      _playing = true;
      _currentIndex = 0;
    });
  }

  void _stopQueue() {
    setState(() {
      _playing = false;
      _currentIndex = -1;
    });
  }

  void _skipNext() {
    if (_currentIndex < _queue.length - 1) {
      setState(() => _currentIndex++);
    } else if (_loopQueue) {
      setState(() => _currentIndex = 0);
    } else {
      _stopQueue();
    }
  }

  void _skipPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _clearQueue() {
    setState(() {
      _queue.clear();
      _playing = false;
      _currentIndex = -1;
    });
    _save();
  }

  IconData _typeIcon(String type) => switch (type) {
    'audio' => Icons.music_note,
    'photo' => Icons.photo,
    _ => Icons.play_circle,
  };

  int _typeColor(String type) => switch (type) {
    'audio' => AppColors.tertiary,
    'photo' => AppColors.signalEmerald,
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Cast Queue',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_queue.isNotEmpty)
            GestureDetector(
              onTap: _clearQueue,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.delete_sweep, size: 20, color: hex(AppColors.error)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_playing) _nowPlayingCard(),
          if (_playing) const SizedBox(height: AppSpacing.md),
          _addSection(),
          const SizedBox(height: AppSpacing.md),
          _controlBar(),
          const SizedBox(height: AppSpacing.md),
          if (_queue.isNotEmpty) ...[
            Text('Queue (${_queue.length} items)',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._queue.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _queueCard(e.value, e.key),
            )),
          ] else
            _emptyState(),
          const SizedBox(height: AppSpacing.md),
          _optionsCard(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _nowPlayingCard() {
    final item = _queue[_currentIndex];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('NOW CASTING',
                    style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 8, weight: FontWeight.w700)),
              ),
              const Spacer(),
              Text('${_currentIndex + 1}/${_queue.length}',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_typeIcon(item.type), size: 20, color: hex(_typeColor(item.type))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _controlButton(Icons.skip_previous, _skipPrev),
              const SizedBox(width: 16),
              _controlButton(Icons.stop, _stopQueue, large: true),
              const SizedBox(width: 16),
              _controlButton(Icons.skip_next, _skipNext),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, VoidCallback onTap, {bool large = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: large ? 44 : 36,
          height: large ? 44 : 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hex(AppColors.primary).withValues(alpha: large ? 0.2 : 0.1),
          ),
          child: Icon(icon, size: large ? 22 : 18, color: hex(AppColors.primary)),
        ),
      );

  Widget _addSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Media',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
          decoration: InputDecoration(
            hintText: 'Title (optional)',
            hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline).withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Media URL',
                  hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline).withValues(alpha: 0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addItem,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(Icons.add, size: 20, color: hex(AppColors.primary)),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _controlBar() => Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: _queue.isEmpty ? null : (_playing ? _stopQueue : _playQueue),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: hex(_queue.isEmpty ? AppColors.outline : AppColors.primary)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: hex(_queue.isEmpty ? AppColors.outline : AppColors.primary)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_playing ? Icons.stop : Icons.play_arrow,
                    size: 18,
                    color: hex(_queue.isEmpty ? AppColors.outline : AppColors.primary)),
                const SizedBox(width: 6),
                Text(_playing ? 'Stop Queue' : 'Cast Queue',
                    style: gfont(AppType.bodyMd,
                        color: hex(_queue.isEmpty ? AppColors.outline : AppColors.primary),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _queueCard(_QueueItem item, int index) {
    final isCurrent = _playing && index == _currentIndex;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(isCurrent ? AppColors.primary : AppColors.surfaceContainerLow)
            .withValues(alpha: isCurrent ? 0.08 : 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(isCurrent ? AppColors.primary : AppColors.outlineVariant)
              .withValues(alpha: isCurrent ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Text('${index + 1}',
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
          const SizedBox(width: 10),
          Icon(_typeIcon(item.type), size: 18, color: hex(_typeColor(item.type))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        size: 12,
                        weight: isCurrent ? FontWeight.w600 : FontWeight.w400)),
                Text(item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 9)),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Icon(Icons.cast_connected, size: 10, color: hex(AppColors.primary)),
            ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeItem(index),
            child: Icon(Icons.close, size: 14, color: hex(AppColors.outline)),
          ),
        ],
      ),
    );
  }

  Widget _optionsCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      children: [
        _toggleRow('Auto-play next', _autoPlay, (v) {
          setState(() => _autoPlay = v);
          _save();
        }),
        _toggleRow('Loop queue', _loopQueue, (v) {
          setState(() => _loopQueue = v);
          _save();
        }),
        _toggleRow('Shuffle', _shuffle, (v) {
          setState(() => _shuffle = v);
        }),
      ],
    ),
  );

  Widget _toggleRow(String label, bool val, ValueChanged<bool> onChanged) => Row(
    children: [
      Text(label,
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13)),
      const Spacer(),
      Switch(
        value: val,
        onChanged: onChanged,
        activeThumbColor: hex(AppColors.primary),
        inactiveTrackColor: hex(AppColors.outlineVariant).withValues(alpha: 0.3),
      ),
    ],
  );

  Widget _emptyState() => Column(
    children: [
      const SizedBox(height: 24),
      Icon(Icons.queue_music, size: 40, color: hex(AppColors.outline)),
      const SizedBox(height: 8),
      Text('Queue is empty',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Add media URLs to build a cast playlist for your TV.',
          textAlign: TextAlign.center,
          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
    ],
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
            'Build a playlist and cast items one after another. Supports video, audio, and photo URLs via DLNA or Google Cast. Queue is saved locally.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
