import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class TextTemplate {
  TextTemplate({required this.label, required this.text, this.pinned = false});

  final String label;
  final String text;
  bool pinned;

  Map<String, dynamic> toJson() => {
    'label': label,
    'text': text,
    'pinned': pinned,
  };

  factory TextTemplate.fromJson(Map<String, dynamic> j) => TextTemplate(
    label: j['label'] as String,
    text: j['text'] as String,
    pinned: j['pinned'] as bool? ?? false,
  );
}

class QuickTextScreen extends StatefulWidget {
  const QuickTextScreen({super.key});

  @override
  State<QuickTextScreen> createState() => _QuickTextScreenState();
}

class _QuickTextScreenState extends State<QuickTextScreen> {
  List<TextTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/quick_text_templates.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _templates = list.map((e) => TextTemplate.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on Object {
      // First launch.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_templates.map((t) => t.toJson()).toList()));
  }

  void _addTemplate() {
    final labelCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLowest),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: Text('New Text Template',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              autofocus: true,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Label (e.g. WiFi Password)',
                hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline)),
                isDense: true,
                filled: true,
                fillColor: hex(AppColors.surfaceContainerHigh),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 3,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Text to type on TV',
                hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline)),
                isDense: true,
                filled: true,
                fillColor: hex(AppColors.surfaceContainerHigh),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              final label = labelCtrl.text.trim();
              final text = textCtrl.text.trim();
              if (label.isNotEmpty && text.isNotEmpty) {
                setState(() => _templates.insert(0, TextTemplate(label: label, text: text)));
                _save();
                Navigator.pop(ctx);
              }
            },
            child: Text('Save',
                style: gfont(AppType.bodySm, color: hex(AppColors.primaryContainer), weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _sendToTv(TextTemplate t) {
    final c = RemoteScope.of(context);
    c.type(t.text);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Typed "${t.label}" on TV'),
          duration: const Duration(seconds: 2),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  void _togglePin(int index) {
    setState(() => _templates[index].pinned = !_templates[index].pinned);
    _save();
  }

  void _removeTemplate(int index) {
    setState(() => _templates.removeAt(index));
    _save();
  }

  List<TextTemplate> get _sorted {
    final pinned = _templates.where((t) => t.pinned).toList();
    final unpinned = _templates.where((t) => !t.pinned).toList();
    return [...pinned, ...unpinned];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Quick Text',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primaryContainer)),
            onPressed: _addTemplate,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: hex(AppColors.primary)))
          : _templates.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _sorted.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == _sorted.length) return _infoCard();
                    final t = _sorted[i];
                    final realIndex = _templates.indexOf(t);
                    return _templateTile(t, realIndex);
                  },
                ),
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.text_snippet_outlined, size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('No text templates',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text('Save frequently typed text — WiFi passwords, search queries, streaming logins — for one-tap typing on your TV.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _addTemplate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text('Add Template',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _templateTile(TextTemplate t, int index) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GestureDetector(
      onTap: () => _sendToTv(t),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(radius: AppRadii.md, borderOpacity: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (t.pinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.push_pin, size: 12, color: hex(AppColors.tertiary)),
                  ),
                Expanded(
                  child: Text(t.label,
                      style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _togglePin(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      t.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 14,
                      color: hex(t.pinned ? AppColors.tertiary : AppColors.outlineVariant),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _removeTemplate(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: hex(AppColors.outlineVariant)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Text(
                t.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${t.text.length} characters',
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hex(AppColors.primaryContainer),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send, size: 11, color: hex(AppColors.onPrimaryContainer)),
                      const SizedBox(width: 4),
                      Text('Type on TV',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600, size: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _infoCard() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Container(
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
              'Tap a template to type its text on your TV instantly. Text is stored locally and never leaves your phone.',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
            ),
          ),
        ],
      ),
    ),
  );
}
