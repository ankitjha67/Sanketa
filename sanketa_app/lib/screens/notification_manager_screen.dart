import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class _NotifRule {
  _NotifRule({required this.name, required this.icon, this.enabled = true, this.sound = true});

  factory _NotifRule.fromJson(Map<String, dynamic> j) => _NotifRule(
    name: j['name'] as String,
    icon: j['icon'] as int,
    enabled: j['enabled'] as bool? ?? true,
    sound: j['sound'] as bool? ?? true,
  );

  final String name;
  final int icon;
  bool enabled;
  bool sound;

  Map<String, dynamic> toJson() => {
    'name': name,
    'icon': icon,
    'enabled': enabled,
    'sound': sound,
  };
}

class NotificationManagerScreen extends StatefulWidget {
  const NotificationManagerScreen({super.key});

  @override
  State<NotificationManagerScreen> createState() => _NotificationManagerScreenState();
}

class _NotificationManagerScreenState extends State<NotificationManagerScreen> {
  bool _masterEnabled = true;
  bool _doNotDisturb = false;
  late List<_NotifRule> _rules;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _rules = _defaults();
    _load();
  }

  List<_NotifRule> _defaults() => [
    _NotifRule(name: 'Timer Expired', icon: Icons.timer.codePoint),
    _NotifRule(name: 'TV Disconnected', icon: Icons.wifi_off.codePoint),
    _NotifRule(name: 'Firmware Update', icon: Icons.system_update.codePoint),
    _NotifRule(name: 'Scheduled Action', icon: Icons.schedule.codePoint),
    _NotifRule(name: 'Low Signal', icon: Icons.signal_wifi_bad.codePoint),
    _NotifRule(name: 'Kid Mode Exit', icon: Icons.child_care.codePoint),
    _NotifRule(name: 'Volume Limit', icon: Icons.volume_up.codePoint),
    _NotifRule(name: 'CEC Device Change', icon: Icons.devices_other.codePoint),
  ];

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/notification_rules.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _masterEnabled = j['masterEnabled'] as bool? ?? true;
        _doNotDisturb = j['doNotDisturb'] as bool? ?? false;
        final list = j['rules'] as List?;
        if (list != null) {
          _rules = list.map((r) => _NotifRule.fromJson(r as Map<String, dynamic>)).toList();
        }
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'masterEnabled': _masterEnabled,
      'doNotDisturb': _doNotDisturb,
      'rules': _rules.map((r) => r.toJson()).toList(),
    }));
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
        title: Text('Notifications',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _masterCard(),
          const SizedBox(height: AppSpacing.md),
          _dndCard(),
          const SizedBox(height: AppSpacing.lg),
          Text('Notification Rules',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._rules.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ruleCard(e.value, e.key),
          )),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _masterCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(_masterEnabled ? AppColors.signalEmerald : AppColors.surfaceContainerLow).withValues(alpha: _masterEnabled ? 0.08 : 1),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(_masterEnabled ? AppColors.signalEmerald : AppColors.outlineVariant).withValues(alpha: 0.2)),
    ),
    child: Row(
      children: [
        Icon(Icons.notifications, size: 24, color: hex(_masterEnabled ? AppColors.signalEmerald : AppColors.outline)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifications', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
              Text(_masterEnabled ? 'All notifications enabled' : 'Notifications disabled',
                  style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
            ],
          ),
        ),
        _toggle(_masterEnabled, (v) {
          setState(() => _masterEnabled = v);
          _save();
        }),
      ],
    ),
  );

  Widget _dndCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        Icon(Icons.do_not_disturb_on, size: 20, color: hex(_doNotDisturb ? AppColors.alertAmber : AppColors.outline)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Do Not Disturb', style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 13)),
              Text('Silence all sounds', style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
        _toggle(_doNotDisturb, (v) {
          setState(() => _doNotDisturb = v);
          _save();
        }),
      ],
    ),
  );

  Widget _ruleCard(_NotifRule rule, int index) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Row(
      children: [
        // ignore: non_const_argument_for_const_parameter
        Icon(IconData(rule.icon, fontFamily: 'MaterialIcons'), size: 18,
            color: hex(rule.enabled ? AppColors.primary : AppColors.outline)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rule.name,
                  style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12, weight: FontWeight.w500)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => rule.sound = !rule.sound);
                      _save();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(rule.sound ? Icons.volume_up : Icons.volume_off, size: 12,
                            color: hex(AppColors.outline)),
                        const SizedBox(width: 3),
                        Text(rule.sound ? 'Sound' : 'Silent',
                            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _toggle(rule.enabled, (v) {
          setState(() => rule.enabled = v);
          _save();
        }),
      ],
    ),
  );

  Widget _toggle(bool value, ValueChanged<bool> onChanged) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: hex(value ? AppColors.primary : AppColors.outlineVariant).withValues(alpha: value ? 1 : 0.3),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hex(value ? AppColors.onPrimary : AppColors.outline),
          ),
        ),
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
            'Manage which events trigger notifications. Use Do Not Disturb to silence sounds without disabling alerts. Notifications are local only.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
