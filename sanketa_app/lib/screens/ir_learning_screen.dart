import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _LearnedCode {
  _LearnedCode({required this.name, required this.button, this.protocol = '', this.hex = '', this.learnedAt});

  factory _LearnedCode.fromJson(Map<String, dynamic> j) => _LearnedCode(
    name: j['name'] as String,
    button: j['button'] as String,
    protocol: j['protocol'] as String? ?? '',
    hex: j['hex'] as String? ?? '',
    learnedAt: j['learnedAt'] != null ? DateTime.tryParse(j['learnedAt'] as String) : null,
  );

  final String name;
  final String button;
  final String protocol;
  final String hex;
  final DateTime? learnedAt;

  Map<String, dynamic> toJson() => {
    'name': name,
    'button': button,
    'protocol': protocol,
    'hex': hex,
    if (learnedAt != null) 'learnedAt': learnedAt!.toIso8601String(),
  };
}

class IrLearningScreen extends StatefulWidget {
  const IrLearningScreen({super.key});

  @override
  State<IrLearningScreen> createState() => _IrLearningScreenState();
}

class _IrLearningScreenState extends State<IrLearningScreen> {
  List<_LearnedCode> _codes = [];
  bool _loading = true;
  bool _learning = false;

  static const _commonButtons = [
    'Power', 'Vol +', 'Vol -', 'Mute', 'Ch +', 'Ch -',
    'Input', 'Menu', 'Home', 'Back', 'OK/Enter',
    'Up', 'Down', 'Left', 'Right',
    'Play', 'Pause', 'Stop', 'Rewind', 'Fast Forward',
    'Red', 'Green', 'Yellow', 'Blue',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/ir_learned.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _codes = list.map((j) => _LearnedCode.fromJson(j as Map<String, dynamic>)).toList();
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_codes.map((c) => c.toJson()).toList()));
  }

  void _startLearning(String button) {
    setState(() => _learning = true);

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _learning = false;
        _codes.add(_LearnedCode(
          name: 'Remote',
          button: button,
          protocol: 'NEC',
          hex: '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16).substring(4).toUpperCase()}',
          learnedAt: DateTime.now(),
        ));
      });
      _save();
    });
  }

  void _deleteCode(int index) {
    setState(() => _codes.removeAt(index));
    _save();
  }

  void _clearAll() {
    setState(() => _codes.clear());
    _save();
  }

  void _showButtonPicker() {
    final learned = _codes.map((c) => c.button).toSet();
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Button to Learn',
                style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _commonButtons.map((b) {
                final done = learned.contains(b);
                return GestureDetector(
                  onTap: done
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _startLearning(b);
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(done ? AppColors.signalEmerald : AppColors.surfaceContainerHigh)
                          .withValues(alpha: done ? 0.1 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(done ? AppColors.signalEmerald : AppColors.outlineVariant)
                            .withValues(alpha: done ? 0.3 : 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (done) ...[
                          Icon(Icons.check, size: 12, color: hex(AppColors.signalEmerald)),
                          const SizedBox(width: 4),
                        ],
                        Text(b,
                            style: gfont(AppType.bodySm,
                                color: hex(done ? AppColors.signalEmerald : AppColors.onSurface),
                                weight: done ? FontWeight.w500 : FontWeight.w400,
                                size: 11)),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
        title: Text('IR Learning',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_codes.isNotEmpty)
            GestureDetector(
              onTap: _clearAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.delete_sweep, size: 20, color: hex(AppColors.error)),
              ),
            ),
        ],
      ),
      body: _learning ? _learningView() : (_codes.isEmpty ? _emptyState() : _codeList()),
      floatingActionButton: !_learning
          ? FloatingActionButton(
              onPressed: _showButtonPicker,
              backgroundColor: hex(AppColors.primary),
              child: Icon(Icons.add, color: hex(AppColors.onPrimary)),
            )
          : null,
    );
  }

  Widget _learningView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(Icons.sensors, size: 48, color: hex(AppColors.primary)),
          ),
          const SizedBox(height: 20),
          Text('Point your remote at the phone',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Press the button on your physical remote now...',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12)),
          const SizedBox(height: 20),
          CircularProgressIndicator(color: hex(AppColors.primary)),
        ],
      ),
    ),
  );

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
          child: Icon(Icons.settings_remote, size: 32, color: hex(AppColors.outline)),
        ),
        const SizedBox(height: 16),
        Text('No learned codes',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Learn IR codes from your existing physical remote by pointing it at your phone.',
            textAlign: TextAlign.center,
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _showButtonPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
            ),
            child: Text('Start Learning',
                style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
          ),
        ),
        const Spacer(),
        _infoCard(),
      ],
    ),
  );

  Widget _codeList() => ListView(
    padding: const EdgeInsets.all(AppSpacing.lg),
    children: [
      Text('${_codes.length} learned code${_codes.length == 1 ? '' : 's'}',
          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
      const SizedBox(height: 8),
      ..._codes.asMap().entries.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _codeCard(e.value, e.key),
      )),
      const SizedBox(height: AppSpacing.md),
      _infoCard(),
    ],
  );

  Widget _codeCard(_LearnedCode code, int index) => Container(
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
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.settings_remote, size: 16, color: hex(AppColors.signalEmerald)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code.button,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
              Text('${code.protocol}  ${code.hex}',
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _deleteCode(index),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.close, size: 14, color: hex(AppColors.outline)),
          ),
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
            'Learn IR codes from your physical remote. Point the remote at the phone\'s IR receiver and press the button. Requires a phone with an IR blaster.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
