import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class NetworkDiagnosticsScreen extends StatefulWidget {
  const NetworkDiagnosticsScreen({super.key});

  @override
  State<NetworkDiagnosticsScreen> createState() =>
      _NetworkDiagnosticsScreenState();
}

enum _CheckStatus { idle, running, pass, warn, fail }

class _DiagResult {
  _DiagResult(this.label, this.status);
  final String label;
  _CheckStatus status;
  String? detail;
}

class _NetworkDiagnosticsScreenState extends State<NetworkDiagnosticsScreen> {
  List<_DiagResult> _results = [];
  bool _running = false;

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
        title: Text('Network Diagnostics',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _networkInfo(),
              const SizedBox(height: AppSpacing.md),
              _runButton(),
              const SizedBox(height: AppSpacing.md),
              if (_results.isNotEmpty) _resultsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _networkInfo() {
    return FutureBuilder<List<NetworkInterface>>(
      future: NetworkInterface.list(),
      builder: (_, snap) {
        final interfaces = snap.data ?? [];
        final wlan = interfaces
            .where((i) =>
                i.name.toLowerCase().contains('wlan') ||
                i.name.toLowerCase().contains('wi-fi') ||
                i.name.toLowerCase().contains('en0'))
            .toList();
        final primary = wlan.isNotEmpty ? wlan.first : interfaces.firstOrNull;
        final ip =
            primary?.addresses.firstOrNull?.address ?? 'Unknown';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: panel(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Network Info',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              _infoRow('Local IP', ip),
              if (primary != null)
                _infoRow('Interface', primary.name),
              _infoRow('Interfaces', '${interfaces.length} found'),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
            const Spacer(),
            Text(value,
                style: gfont(AppType.labelMonoSm,
                    color: hex(AppColors.onSurface))),
          ],
        ),
      );

  Widget _runButton() => GestureDetector(
        onTap: _running ? null : _runDiagnostics,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primaryContainer).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color:
                    hex(AppColors.primaryContainer).withValues(alpha: 0.3)),
          ),
          child: Center(
            child: _running
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                            hex(AppColors.primaryContainer))))
                : Text('Run Diagnostics',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primaryContainer),
                        weight: FontWeight.w600)),
          ),
        ),
      );

  Widget _resultsList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Results',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          for (final r in _results) _resultCard(r),
        ],
      );

  Widget _resultCard(_DiagResult r) {
    final (icon, color) = switch (r.status) {
      _CheckStatus.pass => (Icons.check_circle, AppColors.signalEmerald),
      _CheckStatus.warn => (Icons.warning_amber_rounded, AppColors.tertiary),
      _CheckStatus.fail => (Icons.cancel, AppColors.error),
      _CheckStatus.running => (Icons.hourglass_top, AppColors.outline),
      _CheckStatus.idle => (Icons.circle_outlined, AppColors.outlineVariant),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(),
      child: Row(
        children: [
          Icon(icon, size: 20, color: hex(color)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.label,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500)),
                if (r.detail != null)
                  Text(r.detail!,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant), size: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runDiagnostics() async {
    final c = RemoteScope.of(context);
    setState(() {
      _running = true;
      _results = [
        _DiagResult('Local network', _CheckStatus.running),
        _DiagResult('TV reachable', _CheckStatus.idle),
        _DiagResult('Control port', _CheckStatus.idle),
        _DiagResult('DNS resolution', _CheckStatus.idle),
        _DiagResult('Internet access', _CheckStatus.idle),
      ];
    });

    // 1. Local network
    try {
      final ifaces = await NetworkInterface.list();
      _results[0].status = ifaces.isNotEmpty ? _CheckStatus.pass : _CheckStatus.fail;
      _results[0].detail = '${ifaces.length} interface(s)';
    } on Object {
      _results[0].status = _CheckStatus.fail;
      _results[0].detail = 'Cannot enumerate interfaces';
    }
    if (mounted) setState(() {});

    // 2. TV reachable
    _results[1].status = _CheckStatus.running;
    if (mounted) setState(() {});
    final host = c.tvHost;
    if (host != null && host.isNotEmpty) {
      try {
        final sw = Stopwatch()..start();
        final sock = await Socket.connect(host, 80,
            timeout: const Duration(seconds: 3));
        sw.stop();
        sock.destroy();
        _results[1].status = _CheckStatus.pass;
        _results[1].detail = '$host — ${sw.elapsedMilliseconds}ms';
      } on Object {
        try {
          final sw = Stopwatch()..start();
          final sock = await Socket.connect(host, 8060,
              timeout: const Duration(seconds: 3));
          sw.stop();
          sock.destroy();
          _results[1].status = _CheckStatus.pass;
          _results[1].detail = '$host — ${sw.elapsedMilliseconds}ms (port 8060)';
        } on Object {
          _results[1].status = _CheckStatus.fail;
          _results[1].detail = '$host — unreachable';
        }
      }
    } else {
      _results[1].status = _CheckStatus.warn;
      _results[1].detail = 'No TV connected';
    }
    if (mounted) setState(() {});

    // 3. Control port
    _results[2].status = _CheckStatus.running;
    if (mounted) setState(() {});
    if (host != null && host.isNotEmpty) {
      final ports = [8060, 8008, 8009, 55000, 1925, 7345, 3000, 8001];
      final open = <int>[];
      for (final port in ports) {
        try {
          final sock = await Socket.connect(host, port,
              timeout: const Duration(seconds: 2));
          sock.destroy();
          open.add(port);
        } on Object {
          // closed
        }
      }
      _results[2].status =
          open.isNotEmpty ? _CheckStatus.pass : _CheckStatus.warn;
      _results[2].detail = open.isNotEmpty
          ? 'Open: ${open.join(", ")}'
          : 'No known ports open';
    } else {
      _results[2].status = _CheckStatus.warn;
      _results[2].detail = 'No TV to scan';
    }
    if (mounted) setState(() {});

    // 4. DNS
    _results[3].status = _CheckStatus.running;
    if (mounted) setState(() {});
    try {
      final result = await InternetAddress.lookup('google.com');
      _results[3].status =
          result.isNotEmpty ? _CheckStatus.pass : _CheckStatus.fail;
      _results[3].detail = result.isNotEmpty ? result.first.address : 'No result';
    } on Object {
      _results[3].status = _CheckStatus.fail;
      _results[3].detail = 'DNS lookup failed';
    }
    if (mounted) setState(() {});

    // 5. Internet
    _results[4].status = _CheckStatus.running;
    if (mounted) setState(() {});
    try {
      final sock = await Socket.connect('1.1.1.1', 443,
          timeout: const Duration(seconds: 3));
      sock.destroy();
      _results[4].status = _CheckStatus.pass;
      _results[4].detail = 'Cloudflare reachable';
    } on Object {
      _results[4].status = _CheckStatus.warn;
      _results[4].detail = 'No internet — local control still works';
    }
    if (mounted) setState(() {});

    setState(() => _running = false);
  }
}
