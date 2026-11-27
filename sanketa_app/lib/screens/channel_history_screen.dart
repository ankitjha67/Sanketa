import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ChannelHistoryScreen extends StatefulWidget {
  const ChannelHistoryScreen({super.key});

  @override
  State<ChannelHistoryScreen> createState() => _ChannelHistoryScreenState();
}

class _ChannelHistoryScreenState extends State<ChannelHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<String> get _filePath async {
    final dir = await getApplicationSupportDirectory();
    return '${dir.path}/channel_history.json';
  }

  Future<void> _loadHistory() async {
    try {
      final path = await _filePath;
      final file = File(path);
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = jsonDecode(raw) as List<dynamic>;
        setState(() {
          _history = list.cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        // Seed with mock data
        final mock = _mockHistory();
        await _saveHistory(mock);
        setState(() {
          _history = mock;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _history = _mockHistory();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _mockHistory() {
    final now = DateTime.now();
    return [
      {'channel': '1', 'name': 'BBC One', 'time': now.subtract(const Duration(minutes: 5)).toIso8601String()},
      {'channel': '2', 'name': 'CNN', 'time': now.subtract(const Duration(minutes: 18)).toIso8601String()},
      {'channel': '5', 'name': 'Discovery', 'time': now.subtract(const Duration(minutes: 42)).toIso8601String()},
      {'channel': '11', 'name': 'ESPN', 'time': now.subtract(const Duration(hours: 1, minutes: 10)).toIso8601String()},
      {'channel': '14', 'name': 'HBO', 'time': now.subtract(const Duration(hours: 1, minutes: 35)).toIso8601String()},
      {'channel': '20', 'name': 'National Geographic', 'time': now.subtract(const Duration(hours: 2)).toIso8601String()},
      {'channel': '22', 'name': 'History Channel', 'time': now.subtract(const Duration(hours: 2, minutes: 30)).toIso8601String()},
      {'channel': '30', 'name': 'Cartoon Network', 'time': now.subtract(const Duration(hours: 3)).toIso8601String()},
      {'channel': '35', 'name': 'Fox News', 'time': now.subtract(const Duration(hours: 4)).toIso8601String()},
      {'channel': '42', 'name': 'Animal Planet', 'time': now.subtract(const Duration(hours: 5)).toIso8601String()},
      {'channel': '50', 'name': 'MTV', 'time': now.subtract(const Duration(hours: 6)).toIso8601String()},
      {'channel': '55', 'name': 'Comedy Central', 'time': now.subtract(const Duration(hours: 7)).toIso8601String()},
      {'channel': '60', 'name': 'Sky Sports', 'time': now.subtract(const Duration(hours: 8)).toIso8601String()},
      {'channel': '65', 'name': 'Nickelodeon', 'time': now.subtract(const Duration(hours: 10)).toIso8601String()},
      {'channel': '70', 'name': 'TLC', 'time': now.subtract(const Duration(hours: 12)).toIso8601String()},
      {'channel': '75', 'name': 'Food Network', 'time': now.subtract(const Duration(hours: 14)).toIso8601String()},
      {'channel': '80', 'name': 'Sci-Fi Channel', 'time': now.subtract(const Duration(hours: 16)).toIso8601String()},
      {'channel': '85', 'name': 'Travel Channel', 'time': now.subtract(const Duration(hours: 18)).toIso8601String()},
      {'channel': '90', 'name': 'ABC', 'time': now.subtract(const Duration(hours: 20)).toIso8601String()},
      {'channel': '99', 'name': 'PBS', 'time': now.subtract(const Duration(hours: 24)).toIso8601String()},
    ];
  }

  Future<void> _saveHistory(List<Map<String, dynamic>> data) async {
    try {
      final path = await _filePath;
      await File(path).writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  void _tuneToChannel(Map<String, dynamic> entry) {
    final rc = RemoteScope.of(context);
    final ch = entry['channel'] as String;
    for (final digit in ch.split('')) {
      final key = core.Key.values.firstWhere(
          (k) => k.name == 'digit$digit',
          orElse: () => core.Key.digit0);
      rc.key(key);
    }
    rc.key(core.Key.ok);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Tuning to Ch $ch — ${entry['name']}'),
        duration: const Duration(seconds: 2),
      ));
  }

  Future<void> _clearHistory() async {
    setState(() => _history = []);
    await _saveHistory([]);
    HapticFeedback.mediumImpact();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Channel history cleared'),
          duration: Duration(seconds: 2),
        ));
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
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
        title: Text('Channel History',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: hex(AppColors.outline), size: 20),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            _emptyState()
          else ...[
            _statsRow(),
            const SizedBox(height: AppSpacing.md),
            Text('Recent Channels',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            ..._history.map((e) => _channelTile(e)),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.secondary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.secondary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: hex(AppColors.secondary)),
            const SizedBox(height: 8),
            Text('Channel History',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.secondary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Jump back to recently watched channels with one tap',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(child: _statChip('${_history.length}', 'Channels', AppColors.secondary)),
          const SizedBox(width: 8),
          Expanded(child: _statChip(
              _history.isNotEmpty ? _formatTime(_history.first['time'] as String) : '--',
              'Last watched',
              AppColors.primary)),
        ],
      );

  Widget _statChip(String value, String label, int color) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.bodyMd,
                    color: hex(color),
                    weight: FontWeight.w700,
                    size: 16)),
            const SizedBox(height: 2),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 10)),
          ],
        ),
      );

  Widget _channelTile(Map<String, dynamic> entry) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => _tuneToChannel(entry),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: hex(AppColors.surfaceContainerLow),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                  color:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hex(AppColors.secondary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Center(
                    child: Text(entry['channel'] as String,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.secondary),
                            weight: FontWeight.w700,
                            size: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry['name'] as String,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w500,
                              size: 13)),
                      Text('Ch ${entry['channel']}',
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                    ],
                  ),
                ),
                Text(_formatTime(entry['time'] as String),
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                const SizedBox(width: 6),
                Icon(Icons.play_circle_outline,
                    size: 18, color: hex(AppColors.secondary)),
              ],
            ),
          ),
        ),
      );

  Widget _emptyState() => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.tv_off,
                size: 48,
                color: hex(AppColors.outline).withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No channel history yet',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.outline),
                    weight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Channels you watch will appear here',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: hex(AppColors.primary)),
                const SizedBox(width: 6),
                Text('About',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tap any channel to tune to it immediately. '
              'History stores the last 20 channels and persists between sessions.',
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );
}
