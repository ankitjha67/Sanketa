import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _LinkEntry {
  _LinkEntry({required this.url, required this.sentAt});

  factory _LinkEntry.fromJson(Map<String, dynamic> j) => _LinkEntry(
    url: j['url'] as String,
    sentAt: DateTime.tryParse(j['sentAt'] as String? ?? '') ?? DateTime.now(),
  );

  final String url;
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {'url': url, 'sentAt': sentAt.toIso8601String()};
}

class DeepLinkScreen extends StatefulWidget {
  const DeepLinkScreen({super.key});

  @override
  State<DeepLinkScreen> createState() => _DeepLinkScreenState();
}

class _DeepLinkScreenState extends State<DeepLinkScreen> {
  final _urlCtrl = TextEditingController();
  List<_LinkEntry> _history = [];
  bool _loading = true;

  static const _quickApps = [
    ('YouTube', 'https://www.youtube.com', Icons.play_circle_fill, 0xFFFF0000),
    ('Netflix', 'https://www.netflix.com', Icons.movie, 0xFFE50914),
    ('Prime', 'https://www.primevideo.com', Icons.local_movies, 0xFF00A8E1),
    ('Disney+', 'https://www.disneyplus.com', Icons.castle, 0xFF113CCF),
    ('Spotify', 'https://open.spotify.com', Icons.music_note, 0xFF1DB954),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/deep_link_history.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _history = list.map((j) => _LinkEntry.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_history.map((e) => e.toJson()).toList()));
  }

  bool _isValidUrl(String text) {
    final uri = Uri.tryParse(text);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  void _sendUrl(String url) {
    if (!_isValidUrl(url)) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Enter a valid URL (https://...)')));
      return;
    }
    RemoteScope.of(context).type(url);
    setState(() {
      _history.insert(0, _LinkEntry(url: url, sentAt: DateTime.now()));
      if (_history.length > 20) _history = _history.sublist(0, 20);
    });
    _save();
    _urlCtrl.clear();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Sent to TV: $url')));
  }

  Future<void> _pasteUrl() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _urlCtrl.text = text;
    }
  }

  void _deleteEntry(int index) {
    setState(() => _history.removeAt(index));
    _save();
  }

  String _domain(String url) {
    final uri = Uri.tryParse(url);
    return uri?.host ?? url;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

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
        title: Text('Deep Link',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _urlInput(),
          const SizedBox(height: AppSpacing.md),
          _quickAppsRow(),
          const SizedBox(height: AppSpacing.lg),
          if (_history.isNotEmpty) ...[
            Text('Recent (${_history.length})',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._history.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _historyCard(e.value, e.key),
            )),
            const SizedBox(height: AppSpacing.md),
          ],
          _infoCard(),
        ],
      ),
    );
  }

  Widget _urlInput() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Send URL to TV',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlCtrl,
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://youtube.com/watch?v=...',
                  hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline).withValues(alpha: 0.5), size: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (v) => _sendUrl(v.trim()),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _pasteUrl,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hex(AppColors.tertiary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(Icons.content_paste, size: 18, color: hex(AppColors.tertiary)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _sendUrl(_urlCtrl.text.trim()),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(Icons.send, size: 18, color: hex(AppColors.primary)),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _quickAppsRow() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Quick Launch',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline), weight: FontWeight.w600, size: 11)),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _quickApps.map((app) => GestureDetector(
          onTap: () => _sendUrl(app.$2),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(app.$4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(app.$3, size: 22, color: Color(app.$4)),
              ),
              const SizedBox(height: 4),
              Text(app.$1, style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
            ],
          ),
        )).toList(),
      ),
    ],
  );

  Widget _historyCard(_LinkEntry entry, int index) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.link, size: 16, color: hex(AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_domain(entry.url),
                  style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 11)),
              Text(entry.url, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 9)),
            ],
          ),
        ),
        Text(_timeAgo(entry.sentAt),
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 8)),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _sendUrl(entry.url),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text('Send',
                style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 9, weight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _deleteEntry(index),
          child: Icon(Icons.close, size: 14, color: hex(AppColors.outline)),
        ),
      ],
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
            'Opens the URL directly on your TV. The URL is sent over your local network and never leaves your home.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
