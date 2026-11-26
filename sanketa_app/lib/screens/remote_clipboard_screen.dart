import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _ClipEntry {
  _ClipEntry({required this.text, required this.createdAt});

  factory _ClipEntry.fromJson(Map<String, dynamic> j) => _ClipEntry(
    text: j['text'] as String,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}

class RemoteClipboardScreen extends StatefulWidget {
  const RemoteClipboardScreen({super.key});

  @override
  State<RemoteClipboardScreen> createState() => _RemoteClipboardScreenState();
}

class _RemoteClipboardScreenState extends State<RemoteClipboardScreen> {
  List<_ClipEntry> _clips = [];
  bool _loading = true;
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/remote_clipboard.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _clips = list.map((j) => _ClipEntry.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_clips.map((c) => c.toJson()).toList()));
  }

  void _addFromInput() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _clips.insert(0, _ClipEntry(text: text, createdAt: DateTime.now()));
      if (_clips.length > 50) {
        _clips = _clips.sublist(0, 50);
      }
    });
    _textCtrl.clear();
    _save();
  }

  Future<void> _pasteFromPhone() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _clips.insert(0, _ClipEntry(text: data.text!.trim(), createdAt: DateTime.now()));
        if (_clips.length > 50) {
          _clips = _clips.sublist(0, 50);
        }
      });
      _save();
    }
  }

  void _sendToTv(String text) {
    RemoteScope.of(context).paste(text);
  }

  void _copyToPhone(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to phone clipboard')),
    );
  }

  void _delete(int index) {
    setState(() => _clips.removeAt(index));
    _save();
  }

  void _clearAll() {
    setState(() => _clips.clear());
    _save();
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
        title: Text('Clipboard',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_clips.isNotEmpty)
            GestureDetector(
              onTap: _clearAll,
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
          _inputSection(),
          const SizedBox(height: AppSpacing.md),
          _pasteButton(),
          const SizedBox(height: AppSpacing.lg),
          if (_clips.isNotEmpty) ...[
            Text('History (${_clips.length})',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._clips.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _clipCard(e.value, e.key),
            )),
          ] else
            _emptyState(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _inputSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Send Text to TV',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
                decoration: InputDecoration(
                  hintText: 'Type or paste text...',
                  hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline).withValues(alpha: 0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: (_) => _addFromInput(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _addFromInput,
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

  Widget _pasteButton() => GestureDetector(
    onTap: _pasteFromPhone,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.content_paste, size: 16, color: hex(AppColors.onSurface)),
          const SizedBox(width: 8),
          Text('Paste from Phone Clipboard',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w500, size: 12)),
        ],
      ),
    ),
  );

  Widget _clipCard(_ClipEntry clip, int index) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(clip.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(_timeAgo(clip.createdAt),
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 9)),
            Text('  •  ${clip.text.length} chars',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 9)),
            const Spacer(),
            GestureDetector(
              onTap: () => _sendToTv(clip.text),
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
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _copyToPhone(clip.text),
              child: Icon(Icons.copy, size: 14, color: hex(AppColors.outline)),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => _delete(index),
              child: Icon(Icons.close, size: 14, color: hex(AppColors.outline)),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _emptyState() => Column(
    children: [
      const SizedBox(height: 24),
      Icon(Icons.content_paste_off, size: 40, color: hex(AppColors.outline)),
      const SizedBox(height: 8),
      Text('No clipboard entries',
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('Type text above or paste from your phone clipboard.',
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
            'Share text between your phone and TV. Tap Send to type text on the TV screen. Text is stored locally and never sent to any server.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
