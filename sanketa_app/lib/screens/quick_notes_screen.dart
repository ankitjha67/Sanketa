import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _Note {
  _Note({required this.text, required this.createdAt, this.tag = ''});

  factory _Note.fromJson(Map<String, dynamic> j) => _Note(
        text: j['text'] as String,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        tag: j['tag'] as String? ?? '',
      );

  final String text;
  final DateTime createdAt;
  final String tag;

  Map<String, dynamic> toJson() => {
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'tag': tag,
      };
}

class QuickNotesScreen extends StatefulWidget {
  const QuickNotesScreen({super.key});

  @override
  State<QuickNotesScreen> createState() => _QuickNotesScreenState();
}

class _QuickNotesScreenState extends State<QuickNotesScreen> {
  List<_Note> _notes = [];
  bool _loading = true;
  final _textCtrl = TextEditingController();
  int _tagIndex = 0;

  static const _tags = ['', 'Product', 'URL', 'Recipe', 'Quote', 'Idea'];
  static const _tagIcons = [
    Icons.note,
    Icons.shopping_bag,
    Icons.link,
    Icons.restaurant,
    Icons.format_quote,
    Icons.lightbulb,
  ];
  static const _tagColors = [
    AppColors.outline,
    AppColors.primary,
    AppColors.tertiary,
    AppColors.signalEmerald,
    AppColors.alertAmber,
    AppColors.secondary,
  ];

  int _filterIndex = 0;

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
    return File('${dir.path}/quick_notes.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _notes = list.map((j) => _Note.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object { /* defaults */ }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_notes.map((n) => n.toJson()).toList()));
  }

  void _addNote() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _notes.insert(0, _Note(
        text: text,
        createdAt: DateTime.now(),
        tag: _tags[_tagIndex],
      ));
      if (_notes.length > 100) _notes = _notes.sublist(0, 100);
    });
    _textCtrl.clear();
    _save();
  }

  void _delete(int index) {
    setState(() => _notes.removeAt(index));
    _save();
  }

  void _copyNote(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ));
  }

  void _clearAll() {
    setState(() => _notes.clear());
    _save();
  }

  List<_Note> get _filtered {
    if (_filterIndex == 0) return _notes;
    final tag = _tags[_filterIndex];
    return _notes.where((n) => n.tag == tag).toList();
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
        title: Text('Quick Notes',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_notes.isNotEmpty)
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
          const SizedBox(height: AppSpacing.sm),
          _tagSelector(),
          const SizedBox(height: AppSpacing.md),
          _filterBar(),
          const SizedBox(height: AppSpacing.md),
          if (_filtered.isEmpty)
            _emptyState()
          else ...[
            Text('${_filtered.length} Notes',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._filtered.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _noteCard(e.value, _notes.indexOf(e.value)),
                )),
          ],
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
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jot Something Down',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    maxLines: 2,
                    minLines: 1,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
                    decoration: InputDecoration(
                      hintText: 'Product name, URL, recipe...',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline).withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addNote(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addNote,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child:
                        Icon(Icons.add, size: 20, color: hex(AppColors.primary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _tagSelector() => SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _tags.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = i == _tagIndex;
            return GestureDetector(
              onTap: () => setState(() => _tagIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: hex(active ? _tagColors[i] : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? _tagColors[i] : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tagIcons[i],
                        size: 12,
                        color: hex(active ? _tagColors[i] : AppColors.outline)),
                    const SizedBox(width: 4),
                    Text(i == 0 ? 'General' : _tags[i],
                        style: gfont(AppType.bodySm,
                            color: hex(active ? _tagColors[i] : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 10)),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _filterBar() => SizedBox(
        height: 28,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _tags.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = i == _filterIndex;
            final count = i == 0
                ? _notes.length
                : _notes.where((n) => n.tag == _tags[i]).length;
            return GestureDetector(
              onTap: () => setState(() => _filterIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Center(
                  child: Text('${i == 0 ? "All" : _tags[i]} ($count)',
                      style: gfont(AppType.bodySm,
                          color: hex(active ? AppColors.primary : AppColors.outline),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                ),
              ),
            );
          },
        ),
      );

  Widget _noteCard(_Note note, int index) {
    final tagIdx = _tags.indexOf(note.tag);
    final tColor = tagIdx >= 0 ? _tagColors[tagIdx] : AppColors.outline;
    final tIcon = tagIdx >= 0 ? _tagIcons[tagIdx] : Icons.note;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), size: 12)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(tIcon, size: 10, color: hex(tColor)),
              const SizedBox(width: 4),
              Text(note.tag.isEmpty ? 'General' : note.tag,
                  style: gfont(AppType.bodySm,
                      color: hex(tColor), size: 9, weight: FontWeight.w600)),
              Text('  ·  ${_timeAgo(note.createdAt)}',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
              const Spacer(),
              GestureDetector(
                onTap: () => _copyNote(note.text),
                child: Icon(Icons.copy, size: 14, color: hex(AppColors.outline)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _delete(index),
                child:
                    Icon(Icons.close, size: 14, color: hex(AppColors.outline)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.note_add, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No notes yet',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              'Jot down product names, URLs, recipes, or anything you see on TV.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
        ],
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Quick notes while watching TV. Save product names, URLs, recipes, or anything that catches your eye. All notes are stored locally on your phone.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
