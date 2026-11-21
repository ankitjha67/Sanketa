import 'package:flutter/material.dart';
import 'package:sanketa_adapters/sanketa_adapters.dart' as adapters;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../services/tv_stats_service.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({super.key});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  final _service = TvStatsService();

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final c = RemoteScope.of(context);
      final host = c.tvHost;
      if (host != null && host.isNotEmpty) {
        _service.connectAndPoll(host);
      }
    }
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Performance',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_service.isConnected)
            IconButton(
              icon: Icon(Icons.refresh, color: hex(AppColors.onSurfaceVariant)),
              onPressed: _service.refresh,
            ),
        ],
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_service.isConnecting) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: hex(AppColors.primary)),
        const SizedBox(height: AppSpacing.md),
        Text('Connecting via ADB...',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
      ]));
    }

    if (!_service.isConnected) {
      return _notConnected();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
      child: Column(children: [
        _connectionBadge(),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(child: _memoryCard()),
          const SizedBox(width: 10),
          Expanded(child: _cpuCard()),
        ]),
        const SizedBox(height: 10),
        _storageCard(),
        const SizedBox(height: AppSpacing.md),
        _processesCard(),
      ]),
    );
  }

  Widget _notConnected() {
    final c = RemoteScope.of(context);
    return Center(
        child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.speed, size: 48, color: hex(AppColors.outlineVariant)),
        const SizedBox(height: AppSpacing.md),
        Text('ADB Connection Required',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _service.error ??
              'Connect to an Android TV to view performance stats.',
          textAlign: TextAlign.center,
          style: gfont(AppType.bodySm,
              color: hex(AppColors.onSurfaceVariant), size: 13),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: () {
            final host = c.tvHost;
            if (host != null && host.isNotEmpty) {
              _service.connectAndPoll(host);
            }
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
          style: FilledButton.styleFrom(
            backgroundColor: hex(AppColors.primaryContainer),
            foregroundColor: hex(AppColors.onPrimaryContainer),
          ),
        ),
      ]),
    ));
  }

  Widget _connectionBadge() => Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: panel(
            fill: AppColors.surfaceContainerLowest,
            radius: AppRadii.md,
            borderOpacity: 0.2),
        child: Row(children: [
          const PulseDot(color: Colors.green, size: 8),
          const SizedBox(width: AppSpacing.sm),
          Text('Live stats • refreshing every 5s',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.onSurfaceVariant), size: 10)),
        ]),
      );

  Widget _memoryCard() {
    final mem = _service.memory;
    final pct = mem?.usedPercent ?? 0;
    return _statCard(
      title: 'MEMORY',
      icon: Icons.memory,
      value: mem != null ? '${(mem.usedKb / 1024).round()} MB' : '--',
      subtitle: mem != null
          ? 'of ${(mem.totalKb / 1024).round()} MB'
          : 'Waiting...',
      percent: pct / 100,
      color: pct > 85
          ? hex(AppColors.error)
          : pct > 65
              ? hex(AppColors.tertiary)
              : hex(AppColors.primary),
    );
  }

  Widget _cpuCard() {
    final cpu = _service.cpu;
    final pct = cpu?.totalUsed ?? 0;
    return _statCard(
      title: 'CPU',
      icon: Icons.developer_board,
      value: cpu != null ? '${pct.toStringAsFixed(1)}%' : '--',
      subtitle: cpu != null
          ? 'user ${cpu.userPercent.toStringAsFixed(0)}% • sys ${cpu.systemPercent.toStringAsFixed(0)}%'
          : 'Waiting...',
      percent: pct / 100,
      color: pct > 85
          ? hex(AppColors.error)
          : pct > 60
              ? hex(AppColors.tertiary)
              : hex(AppColors.primary),
    );
  }

  Widget _statCard({
    required String title,
    required IconData icon,
    required String value,
    required String subtitle,
    required double percent,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: panel(
          fill: AppColors.surfaceContainerLowest,
          radius: AppRadii.md,
          borderOpacity: 0.15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: hex(AppColors.onSurfaceVariant)),
          const SizedBox(width: 4),
          Text(title,
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.onSurfaceVariant),
                  size: 10,
                  weight: FontWeight.w600)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(value,
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 22,
                weight: FontWeight.w700)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percent.clamp(0, 1),
            backgroundColor: hex(AppColors.surfaceContainerHigh),
            color: color,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle,
            style: gfont(AppType.bodySm,
                color: hex(AppColors.onSurfaceVariant), size: 10)),
      ]),
    );
  }

  Widget _storageCard() {
    final stor = _service.storage;
    final pct = stor?.usedPercent ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: panel(
          fill: AppColors.surfaceContainerLowest,
          radius: AppRadii.md,
          borderOpacity: 0.15),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.storage,
                      size: 14, color: hex(AppColors.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  Text('STORAGE',
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.onSurfaceVariant),
                          size: 10,
                          weight: FontWeight.w600)),
                ]),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  stor != null
                      ? '${(stor.usedKb / 1024).round()} MB used'
                      : '--',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurface),
                      size: 14,
                      weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  stor != null
                      ? '${(stor.availableKb / 1024).round()} MB free of ${(stor.totalKb / 1024).round()} MB'
                      : 'Waiting...',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.onSurfaceVariant), size: 11),
                ),
              ]),
        ),
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: (pct / 100).clamp(0, 1),
              strokeWidth: 5,
              backgroundColor: hex(AppColors.surfaceContainerHigh),
              color: pct > 85
                  ? hex(AppColors.error)
                  : hex(AppColors.primary),
            ),
            Text('${pct.round()}%',
                style: gfont(AppType.labelMonoSm,
                    color: hex(AppColors.onSurface),
                    size: 11,
                    weight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  Widget _processesCard() {
    final procs = _service.processes;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: panel(
          fill: AppColors.surfaceContainerLowest,
          radius: AppRadii.md,
          borderOpacity: 0.15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.list_alt,
              size: 14, color: hex(AppColors.onSurfaceVariant)),
          const SizedBox(width: 4),
          Text('TOP PROCESSES',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.onSurfaceVariant),
                  size: 10,
                  weight: FontWeight.w600)),
          const Spacer(),
          Text('${procs.length} running',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.outline), size: 10)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        if (procs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
                child: Text('Waiting for data...',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurfaceVariant)))),
          )
        else
          for (var i = 0; i < procs.length.clamp(0, 10); i++)
            _processTile(procs[i], i),
      ]),
    );
  }

  Widget _processTile(adapters.TvProcess proc, int index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(
            width: 18,
            child: Text('${index + 1}',
                style: gfont(AppType.labelMonoSm,
                    color: hex(AppColors.outline), size: 10)),
          ),
          Expanded(
            child: Text(proc.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: gfont(AppType.labelMonoSm,
                    color: hex(AppColors.onSurface), size: 11)),
          ),
          Text('${proc.cpuPercent.toStringAsFixed(1)}%',
              style: gfont(AppType.labelMonoSm,
                  color: proc.cpuPercent > 20
                      ? hex(AppColors.error)
                      : hex(AppColors.onSurfaceVariant),
                  size: 10)),
          const SizedBox(width: 8),
          Text('PID ${proc.pid}',
              style: gfont(AppType.labelMonoSm,
                  color: hex(AppColors.outline), size: 9)),
        ]),
      );
}
