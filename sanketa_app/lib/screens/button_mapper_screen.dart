import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class ButtonMapping {
  ButtonMapping({required this.buttonId, required this.label, required this.actionKey});

  final String buttonId;
  final String label;
  String actionKey;

  Map<String, dynamic> toJson() => {
    'buttonId': buttonId,
    'label': label,
    'actionKey': actionKey,
  };

  factory ButtonMapping.fromJson(Map<String, dynamic> j) => ButtonMapping(
    buttonId: j['buttonId'] as String,
    label: j['label'] as String,
    actionKey: j['actionKey'] as String,
  );
}

class ButtonMapperScreen extends StatefulWidget {
  const ButtonMapperScreen({super.key});

  @override
  State<ButtonMapperScreen> createState() => _ButtonMapperScreenState();
}

class _ButtonMapperScreenState extends State<ButtonMapperScreen> {
  List<ButtonMapping> _mappings = [];
  bool _loading = true;

  static const _defaultMappings = <(String, String, String, IconData)>[
    ('hw_volume_up', 'Volume Up Button', 'volumeUp', Icons.volume_up),
    ('hw_volume_down', 'Volume Down Button', 'volumeDown', Icons.volume_down),
    ('red', 'Red Button', 'red', Icons.circle),
    ('green', 'Green Button', 'green', Icons.circle),
    ('yellow', 'Yellow Button', 'yellow', Icons.circle),
    ('blue', 'Blue Button', 'blue', Icons.circle),
  ];

  static const _actionOptions = <String, (String, IconData)>{
    'volumeUp': ('Volume Up', Icons.volume_up),
    'volumeDown': ('Volume Down', Icons.volume_down),
    'mute': ('Toggle Mute', Icons.volume_off),
    'channelUp': ('Channel Up', Icons.keyboard_arrow_up),
    'channelDown': ('Channel Down', Icons.keyboard_arrow_down),
    'power': ('Power', Icons.power_settings_new),
    'home': ('Home', Icons.home),
    'back': ('Back', Icons.arrow_back),
    'ok': ('OK / Select', Icons.check_circle),
    'play': ('Play / Pause', Icons.play_arrow),
    'stop': ('Stop', Icons.stop),
    'rewind': ('Rewind', Icons.fast_rewind),
    'fastForward': ('Fast Forward', Icons.fast_forward),
    'input': ('Input / Source', Icons.settings_input_hdmi),
    'menu': ('Menu', Icons.menu),
    'info': ('Info', Icons.info),
    'guide': ('TV Guide', Icons.list_alt),
    'red': ('Red Button', Icons.circle),
    'green': ('Green Button', Icons.circle),
    'yellow': ('Yellow Button', Icons.circle),
    'blue': ('Blue Button', Icons.circle),
    'up': ('D-pad Up', Icons.arrow_upward),
    'down': ('D-pad Down', Icons.arrow_downward),
    'left': ('D-pad Left', Icons.arrow_back),
    'right': ('D-pad Right', Icons.arrow_forward),
  };

  static const _buttonIcons = <String, IconData>{
    'hw_volume_up': Icons.volume_up,
    'hw_volume_down': Icons.volume_down,
    'red': Icons.circle,
    'green': Icons.circle,
    'yellow': Icons.circle,
    'blue': Icons.circle,
  };

  static const _buttonColors = <String, int>{
    'red': 0xFFE53935,
    'green': 0xFF43A047,
    'yellow': 0xFFFDD835,
    'blue': 0xFF1E88E5,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/button_mappings.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _mappings = list.map((e) => ButtonMapping.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _mappings = _defaultMappings
            .map((d) => ButtonMapping(buttonId: d.$1, label: d.$2, actionKey: d.$3))
            .toList();
      }
    } on Object {
      _mappings = _defaultMappings
          .map((d) => ButtonMapping(buttonId: d.$1, label: d.$2, actionKey: d.$3))
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_mappings.map((m) => m.toJson()).toList()));
  }

  void _changeAction(int index) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: hex(AppColors.surface),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assign Action to "${_mappings[index].label}"',
                    style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: _actionOptions.entries.map((e) => GestureDetector(
                      onTap: () => Navigator.pop(ctx, e.key),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        decoration: BoxDecoration(
                          color: _mappings[index].actionKey == e.key
                              ? hex(AppColors.primaryContainer).withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: Row(
                          children: [
                            Icon(e.value.$2, size: 18, color: hex(AppColors.onSurface)),
                            const SizedBox(width: 12),
                            Text(e.value.$1, style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface))),
                            if (_mappings[index].actionKey == e.key) ...[
                              const Spacer(),
                              Icon(Icons.check, size: 16, color: hex(AppColors.primary)),
                            ],
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((actionKey) {
      if (actionKey != null && mounted) {
        setState(() => _mappings[index].actionKey = actionKey);
        _save();
      }
    });
  }

  void _testMapping(ButtonMapping mapping) {
    final c = RemoteScope.of(context);
    final key = core.Key.values.where((k) => k.name == mapping.actionKey).firstOrNull;
    if (key != null) {
      c.key(key);
    }
    if (mounted) {
      final actionName = _actionOptions[mapping.actionKey]?.$1 ?? mapping.actionKey;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Sent: $actionName'),
          duration: const Duration(seconds: 1),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  void _resetDefaults() {
    setState(() {
      _mappings = _defaultMappings
          .map((d) => ButtonMapping(buttonId: d.$1, label: d.$2, actionKey: d.$3))
          .toList();
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Button Mapper',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.restore, color: hex(AppColors.outlineVariant)),
            onPressed: _resetDefaults,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: hex(AppColors.primary)))
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _mappings.length + 1,
              itemBuilder: (ctx, i) {
                if (i == _mappings.length) return _infoCard();
                return _mappingTile(_mappings[i], i);
              },
            ),
    );
  }

  Widget _mappingTile(ButtonMapping mapping, int index) {
    final actionInfo = _actionOptions[mapping.actionKey] ?? ('Unknown', Icons.help);
    final buttonIcon = _buttonIcons[mapping.buttonId] ?? Icons.radio_button_unchecked;
    final buttonColor = _buttonColors[mapping.buttonId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(radius: AppRadii.md, borderOpacity: 0.2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (buttonColor != null ? Color(buttonColor) : hex(AppColors.outlineVariant))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(buttonIcon, size: 18,
                  color: buttonColor != null ? Color(buttonColor) : hex(AppColors.outline)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mapping.label,
                      style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 10, color: hex(AppColors.outline)),
                      const SizedBox(width: 4),
                      Icon(actionInfo.$2, size: 12, color: hex(AppColors.primary)),
                      const SizedBox(width: 4),
                      Text(actionInfo.$1,
                          style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 11)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _testMapping(mapping),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: hex(AppColors.primaryContainer),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text('Test',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600, size: 10)),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _changeAction(index),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.edit, size: 16, color: hex(AppColors.outlineVariant)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              'Remap hardware volume buttons and colour keys to any TV action. Tap Test to verify a mapping.',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
            ),
          ),
        ],
      ),
    ),
  );
}
