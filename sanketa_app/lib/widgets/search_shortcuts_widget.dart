import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import 'common.dart';

class SearchShortcut {
  SearchShortcut({required this.name, required this.query});
  final String name;
  final String query;

  Map<String, String> toJson() => {'name': name, 'query': query};

  factory SearchShortcut.fromJson(Map<String, dynamic> j) =>
      SearchShortcut(name: j['name'] as String, query: j['query'] as String);
}

class SearchShortcutsWidget extends StatefulWidget {
  const SearchShortcutsWidget({super.key});

  @override
  State<SearchShortcutsWidget> createState() => SearchShortcutsWidgetState();
}

class SearchShortcutsWidgetState extends State<SearchShortcutsWidget> {
  List<SearchShortcut> _shortcuts = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/search_shortcuts.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final raw = await f.readAsString();
        final list = (jsonDecode(raw) as List)
            .cast<Map<String, dynamic>>()
            .map(SearchShortcut.fromJson)
            .toList();
        if (mounted) setState(() => _shortcuts = list);
      }
    } on Object {
      // Best-effort load.
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_shortcuts.map((s) => s.toJson()).toList()));
  }

  void _add(SearchShortcut s) {
    if (_shortcuts.length >= 20) return;
    setState(() => _shortcuts.add(s));
    _save();
  }

  void _remove(int i) {
    setState(() => _shortcuts.removeAt(i));
    _save();
  }

  void _reorder(int old, int next) {
    setState(() {
      final item = _shortcuts.removeAt(old);
      _shortcuts.insert(next, item);
    });
    _save();
  }

  void showAddDialog() {
    final nameC = TextEditingController();
    final queryC = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surfaceContainerLow),
        title: Text('Add Shortcut',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Name (e.g. "My Show")',
                hintStyle:
                    gfont(AppType.bodySm, color: hex(AppColors.outlineVariant)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: queryC,
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)),
              decoration: InputDecoration(
                hintText: 'Search text to type on TV',
                hintStyle:
                    gfont(AppType.bodySm, color: hex(AppColors.outlineVariant)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              final n = nameC.text.trim();
              final q = queryC.text.trim();
              if (n.isNotEmpty && q.isNotEmpty) {
                _add(SearchShortcut(name: n, query: q));
              }
              Navigator.of(ctx).pop();
            },
            child: Text('Add',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.primaryContainer),
                    weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_shortcuts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border,
                size: 48,
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('No shortcuts yet',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurfaceVariant))),
            const SizedBox(height: AppSpacing.sm),
            Text('Add search queries to type on your TV with one tap',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _shortcuts.length,
      onReorderItem: _reorder,
      itemBuilder: (_, i) {
        final s = _shortcuts[i];
        return Container(
          key: ValueKey('$i-${s.name}'),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: panel(),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(Icons.search,
                  size: 18, color: hex(AppColors.primaryContainer)),
            ),
            title: Text(s.name,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500)),
            subtitle: Text(s.query,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
            trailing: IconButton(
              icon: Icon(Icons.close,
                  size: 18, color: hex(AppColors.outlineVariant)),
              onPressed: () => _remove(i),
            ),
            onTap: () {
              c.clearText();
              c.type(s.query);
              c.submit();
            },
          ),
        );
      },
    );
  }
}
