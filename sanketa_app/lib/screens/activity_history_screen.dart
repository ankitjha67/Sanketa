import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ActivityEntry {
  ActivityEntry({required this.action, required this.detail, required this.timestamp});

  final String action;
  final String detail;
  final DateTime timestamp;

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData get icon {
    if (action.contains('volume')) return Icons.volume_up;
    if (action.contains('power')) return Icons.power_settings_new;
    if (action.contains('mute')) return Icons.volume_off;
    if (action.contains('channel')) return Icons.tv;
    if (action.contains('home')) return Icons.home;
    if (action.contains('back')) return Icons.arrow_back;
    if (action.contains('play') || action.contains('pause')) return Icons.play_arrow;
    if (action.contains('type') || action.contains('text')) return Icons.keyboard;
    if (action.contains('hdmi') || action.contains('input')) return Icons.settings_input_hdmi;
    if (action.contains('navigate')) return Icons.explore;
    if (action.contains('app')) return Icons.apps;
    return Icons.touch_app;
  }
}

class ActivityHistoryService extends ChangeNotifier {
  final _entries = Queue<ActivityEntry>();
  static const _maxEntries = 200;

  List<ActivityEntry> get entries => _entries.toList();
  int get count => _entries.length;

  void record(String action, [String detail = '']) {
    _entries.addFirst(ActivityEntry(
      action: action,
      detail: detail,
      timestamp: DateTime.now(),
    ));
    if (_entries.length > _maxEntries) {
      _entries.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    notifyListeners();
  }
}

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  late final ActivityHistoryService _service;
  String _filter = 'all';

  static const _filters = <String, String>{
    'all': 'All',
    'key': 'Keys',
    'text': 'Text',
    'volume': 'Volume',
    'navigation': 'Navigation',
  };

  @override
  void initState() {
    super.initState();
    _service = ActivityHistoryService();
    _populateSampleHistory();
  }

  void _populateSampleHistory() {
    if (_service.entries.isEmpty) {
      final now = DateTime.now();
      final samples = [
        ('key:power', 'Power toggle', now.subtract(const Duration(minutes: 2))),
        ('key:volumeUp', 'Volume up', now.subtract(const Duration(minutes: 3))),
        ('key:volumeUp', 'Volume up', now.subtract(const Duration(minutes: 3))),
        ('key:volumeUp', 'Volume up', now.subtract(const Duration(minutes: 3))),
        ('key:home', 'Home pressed', now.subtract(const Duration(minutes: 5))),
        ('text:type', 'Typed "netflix"', now.subtract(const Duration(minutes: 8))),
        ('key:ok', 'OK pressed', now.subtract(const Duration(minutes: 8))),
        ('key:channelUp', 'Channel up', now.subtract(const Duration(minutes: 15))),
        ('key:mute', 'Mute toggle', now.subtract(const Duration(minutes: 20))),
        ('key:back', 'Back pressed', now.subtract(const Duration(minutes: 25))),
        ('navigate:app', 'Launched YouTube', now.subtract(const Duration(hours: 1))),
        ('key:power', 'Power toggle', now.subtract(const Duration(hours: 2))),
      ];
      for (final (action, detail, time) in samples) {
        _service._entries.addLast(ActivityEntry(
          action: action,
          detail: detail,
          timestamp: time,
        ));
      }
    }
  }

  List<ActivityEntry> get _filtered {
    final all = _service.entries;
    if (_filter == 'all') return all;
    if (_filter == 'key') return all.where((e) => e.action.startsWith('key:')).toList();
    if (_filter == 'text') return all.where((e) => e.action.contains('text') || e.action.contains('type')).toList();
    if (_filter == 'volume') return all.where((e) => e.action.contains('volume') || e.action.contains('mute')).toList();
    if (_filter == 'navigation') {
      return all.where((e) =>
          e.action.contains('navigate') ||
          e.action.contains('home') ||
          e.action.contains('back') ||
          e.action.contains('app')).toList();
    }
    return all;
  }

  void _replayAction(ActivityEntry entry) {
    final c = RemoteScope.of(context);
    final parts = entry.action.split(':');
    if (parts.length == 2 && parts[0] == 'key') {
      final keyName = parts[1];
      final key = core.Key.values.where((k) => k.name == keyName).firstOrNull;
      if (key != null) {
        c.key(key);
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('Replayed: ${entry.detail}'),
          duration: const Duration(seconds: 1),
          backgroundColor: hex(AppColors.surfaceContainerHigh),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Activity History',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_service.count > 0)
            IconButton(
              icon: Icon(Icons.delete_outline, color: hex(AppColors.outlineVariant)),
              onPressed: () {
                setState(() => _service.clear());
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: _filtered.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) => _entryTile(_filtered[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.entries.map((e) {
          final active = _filter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _filter = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.25 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primaryContainer : AppColors.outlineVariant)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(e.value,
                    style: gfont(AppType.bodySm,
                        color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                        size: 12)),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48, color: hex(AppColors.outlineVariant)),
          const SizedBox(height: AppSpacing.md),
          Text('No activity yet',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Text('Commands you send to your TV will appear here.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
        ],
      ),
    ),
  );

  Widget _entryTile(ActivityEntry entry, int index) {
    final showTimeSeparator = index == 0 ||
        _filtered[index - 1].timestamp.difference(entry.timestamp).inMinutes > 10;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTimeSeparator)
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(entry.timeLabel,
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 10)),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: GestureDetector(
            onTap: () => _replayAction(entry),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLowest),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(entry.icon, size: 16, color: hex(AppColors.primary)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(entry.detail,
                        style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
                  ),
                  Text(entry.timeLabel,
                      style: gfont(AppType.labelMonoSm, color: hex(AppColors.outlineVariant), size: 9)),
                  const SizedBox(width: 6),
                  Icon(Icons.replay, size: 12, color: hex(AppColors.outlineVariant)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
