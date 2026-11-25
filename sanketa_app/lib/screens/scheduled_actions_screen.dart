import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class ScheduledAction {
  ScheduledAction({
    required this.id,
    required this.name,
    required this.actionKey,
    required this.hour,
    required this.minute,
    this.days = const [1, 2, 3, 4, 5, 6, 7],
    this.enabled = true,
  });

  final String id;
  final String name;
  final String actionKey;
  final int hour;
  final int minute;
  final List<int> days;
  bool enabled;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get daysLabel {
    if (days.length == 7) {
      return 'Every day';
    }
    if (days.length == 5 &&
        days.contains(1) && days.contains(2) && days.contains(3) &&
        days.contains(4) && days.contains(5)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends';
    }
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => names[d]).join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'actionKey': actionKey,
    'hour': hour,
    'minute': minute,
    'days': days,
    'enabled': enabled,
  };

  factory ScheduledAction.fromJson(Map<String, dynamic> j) => ScheduledAction(
    id: j['id'] as String,
    name: j['name'] as String,
    actionKey: j['actionKey'] as String,
    hour: j['hour'] as int,
    minute: j['minute'] as int,
    days: (j['days'] as List).cast<int>(),
    enabled: j['enabled'] as bool? ?? true,
  );
}

class ScheduledActionsScreen extends StatefulWidget {
  const ScheduledActionsScreen({super.key});

  @override
  State<ScheduledActionsScreen> createState() => _ScheduledActionsScreenState();
}

class _ScheduledActionsScreenState extends State<ScheduledActionsScreen> {
  List<ScheduledAction> _actions = [];
  bool _loading = true;

  static const _actionOptions = <String, (String, IconData)>{
    'powerOn': ('Power On', Icons.power),
    'powerOff': ('Power Off', Icons.power_settings_new),
    'mute': ('Toggle Mute', Icons.volume_off),
    'volumeUp': ('Volume Up', Icons.volume_up),
    'volumeDown': ('Volume Down', Icons.volume_down),
    'home': ('Go Home', Icons.home),
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
    return File('${dir.path}/scheduled_actions.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final list = jsonDecode(await f.readAsString()) as List;
        _actions = list.map((e) => ScheduledAction.fromJson(e as Map<String, dynamic>)).toList();
      }
    } on Object {
      // First launch.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode(_actions.map((a) => a.toJson()).toList()));
  }

  void _addAction() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: hex(AppColors.primaryContainer),
            surface: hex(AppColors.surfaceContainerLowest),
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    String? selectedAction;
    if (!mounted) return;
    selectedAction = await showModalBottomSheet<String>(
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
              ..._actionOptions.entries.map((e) => GestureDetector(
                onTap: () => Navigator.pop(ctx, e.key),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(e.value.$2, size: 20, color: hex(AppColors.onSurface)),
                      const SizedBox(width: 12),
                      Text(e.value.$1, style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface))),
                    ],
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
    if (selectedAction == null || !mounted) return;

    final actionName = _actionOptions[selectedAction]!.$1;
    setState(() => _actions.add(ScheduledAction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '$actionName at ${time.format(context)}',
      actionKey: selectedAction!,
      hour: time.hour,
      minute: time.minute,
    )));
    _save();
  }

  void _toggleAction(int index) {
    setState(() => _actions[index].enabled = !_actions[index].enabled);
    _save();
  }

  void _removeAction(int index) {
    setState(() => _actions.removeAt(index));
    _save();
  }

  void _editDays(int index) {
    final action = _actions[index];
    final selected = Set<int>.from(action.days);
    showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _DayPickerDialog(selected: selected),
    ).then((result) {
      if (result != null && result.isNotEmpty && mounted) {
        setState(() => _actions[index] = ScheduledAction(
          id: action.id,
          name: action.name,
          actionKey: action.actionKey,
          hour: action.hour,
          minute: action.minute,
          days: result.toList()..sort(),
          enabled: action.enabled,
        ));
        _save();
      }
    });
  }

  void _executeNow(String actionKey) {
    final c = RemoteScope.of(context);
    final keyMap = <String, core.Key>{
      'powerOn': core.Key.power,
      'powerOff': core.Key.power,
      'mute': core.Key.mute,
      'volumeUp': core.Key.volumeUp,
      'volumeDown': core.Key.volumeDown,
      'home': core.Key.home,
      'channelUp': core.Key.channelUp,
      'channelDown': core.Key.channelDown,
    };
    final key = keyMap[actionKey];
    if (key != null) c.key(key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Scheduled Actions',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: hex(AppColors.primaryContainer)),
            onPressed: _addAction,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: hex(AppColors.primary)))
          : _actions.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _actions.length + 1,
                  itemBuilder: (ctx, i) {
                    if (i == _actions.length) return _infoCard();
                    return _actionTile(_actions[i], i);
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
          Icon(Icons.schedule, size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('No scheduled actions',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text('Schedule your TV to power on/off or change volume at set times.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _addAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.primaryContainer),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Text('Add Schedule',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onPrimaryContainer), weight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _actionTile(ScheduledAction action, int index) {
    final info = _actionOptions[action.actionKey] ?? ('Unknown', Icons.help);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(
          fill: action.enabled
              ? AppColors.surfaceContainerLowest
              : AppColors.surfaceContainerLow,
          radius: AppRadii.md,
          borderOpacity: action.enabled ? 0.3 : 0.15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  action.timeLabel,
                  style: gfont(AppType.headlineMd,
                      color: hex(action.enabled ? AppColors.onSurface : AppColors.outline),
                      size: 28, weight: FontWeight.w700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(info.$2, size: 14, color: hex(AppColors.primary)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(info.$1,
                                overflow: TextOverflow.ellipsis,
                                style: gfont(AppType.bodyMd,
                                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _editDays(index),
                        child: Text(action.daysLabel,
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.tertiary), size: 11)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _removeAction(index),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: hex(AppColors.outlineVariant)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleAction(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hex(action.enabled ? AppColors.tertiaryContainer : AppColors.surfaceContainerHigh)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text(
                      action.enabled ? 'ACTIVE' : 'PAUSED',
                      style: gfont(AppType.labelMonoSm,
                          color: hex(action.enabled ? AppColors.tertiary : AppColors.outline), size: 10),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _executeNow(action.actionKey),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hex(AppColors.primaryContainer),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text('Run Now',
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
              'Scheduled actions require the app to be running and the TV connected at the scheduled time.',
              style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DayPickerDialog extends StatefulWidget {
  const _DayPickerDialog({required this.selected});
  final Set<int> selected;

  @override
  State<_DayPickerDialog> createState() => _DayPickerDialogState();
}

class _DayPickerDialogState extends State<_DayPickerDialog> {
  late final Set<int> _selected;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: hex(AppColors.surfaceContainerLowest),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.lg)),
    title: Text('Repeat on',
        style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w700)),
    content: Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (i) {
        final day = i + 1;
        final active = _selected.contains(day);
        return GestureDetector(
          onTap: () => setState(() {
            if (active) {
              _selected.remove(day);
            } else {
              _selected.add(day);
            }
          }),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                  .withValues(alpha: active ? 0.3 : 1),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: hex(active ? AppColors.primaryContainer : AppColors.outlineVariant)
                    .withValues(alpha: 0.5),
              ),
            ),
            child: Text(_dayNames[i],
                style: gfont(AppType.bodySm,
                    color: hex(active ? AppColors.primary : AppColors.onSurface),
                    weight: active ? FontWeight.w700 : FontWeight.w400,
                    size: 11)),
          ),
        );
      }),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel', style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _selected),
        child: Text('Done',
            style: gfont(AppType.bodySm, color: hex(AppColors.primaryContainer), weight: FontWeight.w700)),
      ),
    ],
  );
}
