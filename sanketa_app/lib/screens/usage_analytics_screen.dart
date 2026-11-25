import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/usage_service.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class UsageAnalyticsScreen extends StatefulWidget {
  const UsageAnalyticsScreen({super.key});

  @override
  State<UsageAnalyticsScreen> createState() => _UsageAnalyticsScreenState();
}

class _UsageAnalyticsScreenState extends State<UsageAnalyticsScreen> {
  final _usage = UsageService();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _usage.load().then((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _usage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Usage Analytics',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: !_loaded
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(hex(AppColors.primaryContainer))))
          : ListenableBuilder(
              listenable: _usage,
              builder: (_, _) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _todayCard(),
                      const SizedBox(height: AppSpacing.md),
                      _weeklyChart(),
                      const SizedBox(height: AppSpacing.md),
                      _peakHours(),
                      const SizedBox(height: AppSpacing.md),
                      _sessionList(),
                      const SizedBox(height: AppSpacing.md),
                      _privacyNote(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _todayCard() {
    final mins = _usage.todayMinutes;
    final hours = mins ~/ 60;
    final remainder = mins % 60;
    final label =
        hours > 0 ? '${hours}h ${remainder}m' : '${remainder}m';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: panel(
          borderColor: AppColors.primaryContainer, borderOpacity: 0.3),
      child: Column(
        children: [
          Text("Today's Usage",
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant))),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 32,
                  weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${_usage.sessions.length} sessions total',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant), size: 11)),
        ],
      ),
    );
  }

  static const _dayLabels = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _weeklyChart() {
    final weekly = _usage.weeklyMinutes;
    final maxVal = weekly.values.fold(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This Week',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var d = 1; d <= 7; d++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (weekly[d]! > 0)
                          Text('${weekly[d]}',
                              style: gfont(AppType.labelMonoSm,
                                  color: hex(AppColors.onSurfaceVariant),
                                  size: 9)),
                        const SizedBox(height: 4),
                        Container(
                          height: (weekly[d]! / maxVal * 80).clamp(4.0, 80.0),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: hex(AppColors.primaryContainer)
                                .withValues(
                                    alpha: weekly[d]! > 0 ? 0.6 : 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_dayLabels[d],
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.onSurfaceVariant),
                                size: 10)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _peakHours() {
    final hourly = _usage.hourlyDistribution;
    final entries = hourly.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Peak Hours',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('No data yet',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant))),
            )
          else
            for (final e in top)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                          '${e.key.toString().padLeft(2, '0')}:00',
                          style: gfont(AppType.labelMonoSm,
                              color: hex(AppColors.onSurface))),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: entries.first.value > 0
                              ? e.value / entries.first.value
                              : 0,
                          backgroundColor:
                              hex(AppColors.surfaceContainerHigh),
                          valueColor: AlwaysStoppedAnimation(
                              hex(AppColors.primaryContainer)
                                  .withValues(alpha: 0.6)),
                          minHeight: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 40,
                      child: Text('${e.value}m',
                          textAlign: TextAlign.end,
                          style: gfont(AppType.labelMonoSm,
                              color: hex(AppColors.onSurfaceVariant),
                              size: 11)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _sessionList() {
    final recent = _usage.sessions.reversed.take(10).toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Recent Sessions',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
              const Spacer(),
              if (_usage.sessions.isNotEmpty)
                GestureDetector(
                  onTap: () => _usage.clearHistory(),
                  child: Text('Clear',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.error),
                          weight: FontWeight.w500, size: 11)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('No sessions recorded yet',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant))),
            )
          else
            for (final s in recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 14, color: hex(AppColors.outlineVariant)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          _formatDate(s.start),
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface), size: 12)),
                    ),
                    Text('${s.durationMinutes}m',
                        style: gfont(AppType.labelMonoSm,
                            color: hex(AppColors.onSurfaceVariant),
                            size: 11)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _privacyNote() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration:
            panel(fill: AppColors.surfaceContainerLowest, borderOpacity: 0.2),
        child: Row(
          children: [
            Icon(Icons.shield_outlined,
                size: 18, color: hex(AppColors.signalEmerald)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'All usage data stays on your device. '
                'Nothing is sent to any server.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant), size: 11),
              ),
            ),
          ],
        ),
      );

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    final diff = today.difference(date).inDays;
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Today $time';
    if (diff == 1) return 'Yesterday $time';
    return '${d.day}/${d.month} $time';
  }
}
