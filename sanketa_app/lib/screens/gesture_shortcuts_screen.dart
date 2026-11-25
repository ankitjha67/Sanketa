import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

enum GestureType {
  shake,
  flipFaceDown,
  doubleTapBack,
  twoFingerSwipeDown,
}

class GestureShortcut {
  GestureShortcut({required this.gesture, required this.actionKey, this.enabled = true});

  final GestureType gesture;
  final String actionKey;
  bool enabled;

  Map<String, dynamic> toJson() => {
    'gesture': gesture.name,
    'actionKey': actionKey,
    'enabled': enabled,
  };

  factory GestureShortcut.fromJson(Map<String, dynamic> j) => GestureShortcut(
    gesture: GestureType.values.firstWhere((g) => g.name == j['gesture']),
    actionKey: j['actionKey'] as String,
    enabled: j['enabled'] as bool? ?? true,
  );
}

class GestureShortcutsScreen extends StatefulWidget {
  const GestureShortcutsScreen({super.key});

  @override
  State<GestureShortcutsScreen> createState() => _GestureShortcutsScreenState();
}

class _GestureShortcutsScreenState extends State<GestureShortcutsScreen> {
  List<GestureShortcut> _shortcuts = [];
  bool _loading = true;

  static const _gestureInfo = <GestureType, (String, String, IconData)>{
    GestureType.shake: ('Shake Phone', 'Shake the phone to trigger an action', Icons.vibration),
    GestureType.flipFaceDown: ('Flip Face Down', 'Place phone face-down on a surface', Icons.screen_lock_rotation),
    GestureType.doubleTapBack: ('Double-Tap Back', 'Double-tap the back of the phone', Icons.touch_app),
    GestureType.twoFingerSwipeDown: ('Two-Finger Swipe', 'Swipe down with two fingers', Icons.swipe_down),
  };

  static const _actions = <String, (String, IconData)>{
    'mute': ('Toggle Mute', Icons.volume_off),
    'power': ('Power Off', Icons.power_settings_new),
    'volumeUp': ('Volume Up', Icons.volume_up),
    'volumeDown': ('Volume Down', Icons.volume_down),
    'home': ('Home', Icons.home),
    'back': ('Back', Icons.arrow_back),
    'playPause': ('Play / Pause', Icons.play_arrow),
    'channelUp': ('Channel Up', Icons.keyboard_arrow_up),
    'channelDown': ('Channel Down', Icons.keyboard_arrow_down),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/gesture_shortcuts.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _shortcuts = list.map((e) => GestureShortcut.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _shortcuts = [
          GestureShortcut(gesture: GestureType.shake, actionKey: 'mute'),
          GestureShortcut(gesture: GestureType.flipFaceDown, actionKey: 'power', enabled: false),
        ];
      }
    } on Object {
      _shortcuts = [
        GestureShortcut(gesture: GestureType.shake, actionKey: 'mute'),
        GestureShortcut(gesture: GestureType.flipFaceDown, actionKey: 'power', enabled: false),
      ];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_shortcuts.map((s) => s.toJson()).toList()));
  }

  void _executeAction(String actionKey) {
    final c = RemoteScope.of(context);
    final keyMap = <String, core.Key>{
      'mute': core.Key.mute,
      'power': core.Key.power,
      'volumeUp': core.Key.volumeUp,
      'volumeDown': core.Key.volumeDown,
      'home': core.Key.home,
      'back': core.Key.back,
      'playPause': core.Key.play,
      'channelUp': core.Key.channelUp,
      'channelDown': core.Key.channelDown,
    };
    final key = keyMap[actionKey];
    if (key != null) c.key(key);
  }

  void _toggleShortcut(int index) {
    setState(() => _shortcuts[index].enabled = !_shortcuts[index].enabled);
    _save();
  }

  void _changeAction(int index) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: hex(AppColors.surface),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose Action',
                  style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.md),
              ..._actions.entries.map((e) => _actionOption(ctx, e.key, e.value.$1, e.value.$2)),
            ],
          ),
        ),
      ),
    ).then((actionKey) {
      if (actionKey != null && mounted) {
        setState(() => _shortcuts[index] = GestureShortcut(
          gesture: _shortcuts[index].gesture,
          actionKey: actionKey,
          enabled: _shortcuts[index].enabled,
        ));
        _save();
      }
    });
  }

  Widget _actionOption(BuildContext ctx, String key, String label, IconData icon) =>
      GestureDetector(
        onTap: () => Navigator.pop(ctx, key),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: hex(AppColors.onSurface)),
              const SizedBox(width: 12),
              Text(label, style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface))),
            ],
          ),
        ),
      );

  void _addGesture() {
    final usedGestures = _shortcuts.map((s) => s.gesture).toSet();
    final available = GestureType.values.where((g) => !usedGestures.contains(g)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('All gestures are already assigned.'),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
      return;
    }
    setState(() {
      _shortcuts.add(GestureShortcut(gesture: available.first, actionKey: 'mute'));
    });
    _save();
  }

  void _removeGesture(int index) {
    setState(() => _shortcuts.removeAt(index));
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
        title: Text('Gesture Shortcuts',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primaryContainer)),
            onPressed: _addGesture,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: hex(AppColors.primary)))
          : _shortcuts.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _shortcuts.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == _shortcuts.length) return _infoCard();
                    return _gestureTile(_shortcuts[i], i);
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
          Icon(Icons.gesture, size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('No gesture shortcuts',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text('Map phone gestures to TV actions.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _addGesture,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text('Add Gesture',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _gestureTile(GestureShortcut shortcut, int index) {
    final info = _gestureInfo[shortcut.gesture]!;
    final actionInfo = _actions[shortcut.actionKey] ?? ('Unknown', Icons.help);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(
          fill: shortcut.enabled
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          radius: AppRadii.md,
          borderOpacity: shortcut.enabled ? 0.3 : 0.15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hex(shortcut.enabled ? AppColors.primaryContainer : AppColors.outlineVariant)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(info.$3, size: 18,
                      color: hex(shortcut.enabled ? AppColors.primary : AppColors.outline)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.$1,
                          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                      Text(info.$2,
                          style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _removeGesture(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: hex(AppColors.outlineVariant)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.arrow_forward, size: 12, color: hex(AppColors.outline)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _changeAction(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hex(AppColors.surfaceContainerHigh),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(actionInfo.$2, size: 14, color: hex(AppColors.onSurface)),
                        const SizedBox(width: 6),
                        Text(actionInfo.$1,
                            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), weight: FontWeight.w500)),
                        const SizedBox(width: 4),
                        Icon(Icons.edit, size: 10, color: hex(AppColors.outline)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _toggleShortcut(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hex(shortcut.enabled ? AppColors.tertiaryContainer : AppColors.surfaceContainerHigh)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      shortcut.enabled ? 'ON' : 'OFF',
                      style: gfont(AppType.labelMonoSm,
                          color: hex(shortcut.enabled ? AppColors.tertiary : AppColors.outline),
                          size: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _executeAction(shortcut.actionKey),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hex(AppColors.primaryContainer),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text('Test',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600, size: 11)),
                  ),
                ),
              ],
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
              'Gesture detection uses device sensors. Some gestures need accelerometer access.',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
            ),
          ),
        ],
      ),
    ),
  );
}
