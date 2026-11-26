import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _Template {
  _Template({required this.label, required this.text, this.icon = Icons.text_snippet});

  factory _Template.fromJson(Map<String, dynamic> j) => _Template(
    label: j['label'] as String,
    text: j['text'] as String,
    icon: _Template._iconFromCode(j['icon'] as int?),
  );

  final String label;
  final String text;
  final IconData icon;

  Map<String, dynamic> toJson() => {'label': label, 'text': text, 'icon': icon.codePoint};

  static IconData _iconFromCode(int? code) =>
      // ignore: non_const_argument_for_const_parameter
      code != null ? IconData(code, fontFamily: 'MaterialIcons') : Icons.text_snippet;
}

class TextTemplatesScreen extends StatefulWidget {
  const TextTemplatesScreen({super.key});

  @override
  State<TextTemplatesScreen> createState() => _TextTemplatesScreenState();
}

class _TextTemplatesScreenState extends State<TextTemplatesScreen> {
  List<_Template> _templates = [];
  bool _loading = true;

  static final _builtIn = [
    _Template(label: 'WiFi Password', text: '', icon: Icons.wifi_password),
    _Template(label: 'Email Address', text: '', icon: Icons.email),
    _Template(label: 'Home Address', text: '', icon: Icons.home),
    _Template(label: 'Search Query', text: '', icon: Icons.search),
    _Template(label: 'YouTube URL', text: 'https://youtube.com/', icon: Icons.play_circle),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/text_templates.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _templates = list.map((j) => _Template.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object { /* defaults */ }
    if (_templates.isEmpty) _templates = List.of(_builtIn);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_templates.map((t) => t.toJson()).toList()));
  }

  void _sendToTv(String text) {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Template text is empty — tap to edit first')));
      return;
    }
    RemoteScope.of(context).type(text);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Sent "${text.length > 30 ? '${text.substring(0, 30)}...' : text}" to TV'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _addTemplate() {
    final labelCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Template',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13),
              decoration: InputDecoration(
                labelText: 'Label',
                labelStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textCtrl,
              maxLines: 3,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13),
              decoration: InputDecoration(
                labelText: 'Text to send',
                labelStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hex(AppColors.primary),
                  foregroundColor: hex(AppColors.onPrimary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
                onPressed: () {
                  if (labelCtrl.text.trim().isEmpty) return;
                  setState(() {
                    _templates.add(_Template(label: labelCtrl.text.trim(), text: textCtrl.text.trim()));
                  });
                  _save();
                  Navigator.pop(ctx);
                },
                child: const Text('Save Template'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editTemplate(int index) {
    final t = _templates[index];
    final labelCtrl = TextEditingController(text: t.label);
    final textCtrl = TextEditingController(text: t.text);
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Template',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13),
              decoration: InputDecoration(
                labelText: 'Label',
                labelStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: textCtrl,
              maxLines: 3,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13),
              decoration: InputDecoration(
                labelText: 'Text to send',
                labelStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hex(AppColors.error),
                      side: BorderSide(color: hex(AppColors.error).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                    onPressed: () {
                      setState(() => _templates.removeAt(index));
                      _save();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hex(AppColors.primary),
                      foregroundColor: hex(AppColors.onPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                    ),
                    onPressed: () {
                      setState(() {
                        _templates[index] = _Template(
                          label: labelCtrl.text.trim().isEmpty ? t.label : labelCtrl.text.trim(),
                          text: textCtrl.text.trim(),
                          icon: t.icon,
                        );
                      });
                      _save();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        title: Text('Text Templates',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primary)),
            onPressed: _addTemplate,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _headerCard(),
          const SizedBox(height: AppSpacing.md),
          Text('My Templates (${_templates.length})',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._templates.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _templateCard(e.value, e.key),
          )),
          const SizedBox(height: AppSpacing.md),
          _addButton(),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _headerCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.primary).withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Icon(Icons.text_snippet, size: 24, color: hex(AppColors.primary)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Text',
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text('Save frequently typed text and send to TV with one tap',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _templateCard(_Template t, int index) => GestureDetector(
    onTap: () => _sendToTv(t.text),
    onLongPress: () => _editTemplate(index),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(t.icon, size: 18, color: hex(AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.label,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 12)),
                Text(
                  t.text.isEmpty ? 'Tap to edit, long press to configure' : t.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _editTemplate(index),
            child: Icon(Icons.edit, size: 14, color: hex(AppColors.outline)),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendToTv(t.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text('Send',
                  style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 10, weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _addButton() => GestureDetector(
    onTap: _addTemplate,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: hex(AppColors.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(AppColors.primary).withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 18, color: hex(AppColors.primary)),
          const SizedBox(width: 8),
          Text('Add New Template',
              style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600, size: 13)),
        ],
      ),
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
            'Save WiFi passwords, emails, URLs, or any text you type often. Tap to send, long-press to edit. Text is stored locally and never leaves your device.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
