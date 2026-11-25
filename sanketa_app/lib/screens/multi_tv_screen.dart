import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _TvEntry {
  _TvEntry({required this.name, required this.ip, this.model = '', this.isActive = false, this.lastSeen});

  factory _TvEntry.fromJson(Map<String, dynamic> j) => _TvEntry(
    name: j['name'] as String,
    ip: j['ip'] as String,
    model: j['model'] as String? ?? '',
    isActive: j['isActive'] as bool? ?? false,
    lastSeen: j['lastSeen'] != null ? DateTime.tryParse(j['lastSeen'] as String) : null,
  );

  final String name;
  final String ip;
  final String model;
  bool isActive;
  final DateTime? lastSeen;

  Map<String, dynamic> toJson() => {
    'name': name,
    'ip': ip,
    'model': model,
    'isActive': isActive,
    if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
  };
}

class MultiTvScreen extends StatefulWidget {
  const MultiTvScreen({super.key});

  @override
  State<MultiTvScreen> createState() => _MultiTvScreenState();
}

class _MultiTvScreenState extends State<MultiTvScreen> {
  List<_TvEntry> _tvs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/multi_tv.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _tvs = list.map((j) => _TvEntry.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_tvs.map((t) => t.toJson()).toList()));
  }

  void _setActive(int index) {
    setState(() {
      for (var i = 0; i < _tvs.length; i++) {
        _tvs[i].isActive = i == index;
      }
    });
    _save();
  }

  void _delete(int index) {
    setState(() => _tvs.removeAt(index));
    _save();
  }

  void _showAddSheet() {
    final nameCtrl = TextEditingController();
    final ipCtrl = TextEditingController();
    final modelCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add TV',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            _field(nameCtrl, 'Name', 'Living Room TV'),
            const SizedBox(height: 8),
            _field(ipCtrl, 'IP Address', '192.168.1.100'),
            const SizedBox(height: 8),
            _field(modelCtrl, 'Model (optional)', 'Samsung QN85B'),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                if (nameCtrl.text.trim().isEmpty || ipCtrl.text.trim().isEmpty) return;
                setState(() {
                  _tvs.add(_TvEntry(
                    name: nameCtrl.text.trim(),
                    ip: ipCtrl.text.trim(),
                    model: modelCtrl.text.trim(),
                    isActive: _tvs.isEmpty,
                    lastSeen: DateTime.now(),
                  ));
                });
                _save();
                Navigator.pop(ctx);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text('Add',
                      style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String hint) => TextField(
    controller: c,
    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline).withValues(alpha: 0.5), size: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

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
        title: Text('My TVs',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: _tvs.isEmpty ? _emptyState() : _tvList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: hex(AppColors.primary),
        child: Icon(Icons.add, color: hex(AppColors.onPrimary)),
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Column(
      children: [
        const SizedBox(height: 48),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerHigh),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.tv, size: 32, color: hex(AppColors.outline)),
        ),
        const SizedBox(height: 16),
        Text('No TVs added',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Add your TVs to quickly switch between them.',
            textAlign: TextAlign.center,
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12)),
        const Spacer(),
        _infoCard(),
      ],
    ),
  );

  Widget _tvList() => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      Text('${_tvs.length} TV${_tvs.length == 1 ? '' : 's'}',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
      const SizedBox(height: 8),
      ..._tvs.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _tvCard(e.value, e.key),
      )),
      const SizedBox(height: AppSpacing.md),
      _infoCard(),
    ],
  );

  Widget _tvCard(_TvEntry tv, int index) => GestureDetector(
    onTap: () => _setActive(index),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(tv.isActive ? AppColors.primaryContainer : AppColors.surfaceContainerLow)
            .withValues(alpha: tv.isActive ? 0.15 : 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: hex(tv.isActive ? AppColors.primary : AppColors.outlineVariant)
              .withValues(alpha: tv.isActive ? 0.4 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hex(tv.isActive ? AppColors.primary : AppColors.surfaceContainerHigh)
                  .withValues(alpha: tv.isActive ? 0.15 : 1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.tv, size: 18,
                color: hex(tv.isActive ? AppColors.primary : AppColors.outline)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tv.name,
                        style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
                    if (tv.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text('ACTIVE',
                            style: gfont(AppType.bodySm, color: hex(AppColors.signalEmerald), size: 8, weight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                Text('${tv.ip}${tv.model.isNotEmpty ? '  •  ${tv.model}' : ''}',
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _delete(index),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: hex(AppColors.outline)),
            ),
          ),
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
            'Manage multiple TVs. Tap a TV to make it the active control target. All remote commands will be sent to the active TV.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
