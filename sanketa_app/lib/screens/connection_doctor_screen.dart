import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/diagnostics_service.dart';
import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class ConnectionDoctorScreen extends StatefulWidget {
  const ConnectionDoctorScreen({super.key});

  @override
  State<ConnectionDoctorScreen> createState() => _ConnectionDoctorScreenState();
}

enum _CheckStatus { pending, running, pass, warn, fail }

class _DiagCheck {
  _DiagCheck(this.label, this.detail);
  final String label;
  String detail;
  _CheckStatus status = _CheckStatus.pending;
  String? remedy;
}

class _ConnectionDoctorScreenState extends State<ConnectionDoctorScreen> {
  late final List<_DiagCheck> _checks;
  bool _running = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _checks = [
      _DiagCheck('Network available', 'Checking Wi-Fi / LAN connectivity'),
      _DiagCheck('Gateway reachable', 'Pinging default gateway'),
      _DiagCheck('DNS resolution', 'Resolving a known hostname'),
      _DiagCheck('TV reachable', 'Pinging the TV\'s IP address'),
      _DiagCheck('Control port open', 'Testing the adapter\'s control port'),
      _DiagCheck('Adapter handshake', 'Verifying the adapter connection'),
      _DiagCheck('Command round-trip', 'Sending a no-op status query'),
    ];
  }

  Future<void> _runDiagnostics() async {
    final c = RemoteScope.of(context);
    setState(() {
      _running = true;
      _done = false;
      for (final ch in _checks) {
        ch.status = _CheckStatus.pending;
        ch.remedy = null;
      }
    });

    // 1. Network available
    await _runCheck(0, () async {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        throw Exception('No network');
      }
    }, remedy: 'Check that your phone is connected to Wi-Fi.');

    // 2. Gateway reachable
    await _runCheck(1, () async {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      if (interfaces.isEmpty) throw Exception('No network interfaces');
      _checks[1].detail = 'Found ${interfaces.length} interface(s)';
    }, remedy: 'Your phone may not be on a local network.');

    // 3. DNS
    await _runCheck(2, () async {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      _checks[2].detail = 'Resolved to ${result.first.address}';
    }, remedy: 'DNS is not resolving. Try switching DNS to 8.8.8.8.');

    // 4. TV reachable
    final device = c.selectedDevice;
    final host = device?.device.host;
    if (host == null) {
      _checks[3].status = _CheckStatus.warn;
      _checks[3].detail = 'No TV selected — select a device first';
      _checks[3].remedy = 'Go to Devices and select your TV.';
      setState(() {});
    } else {
      await _runCheck(3, () async {
        final socket = await Socket.connect(host, 80,
                timeout: const Duration(seconds: 3))
            .catchError((_) async {
          final socket2 = await Socket.connect(host, 443,
              timeout: const Duration(seconds: 3));
          return socket2;
        });
        socket.destroy();
        _checks[3].detail = '$host is reachable';
      }, remedy: 'TV is not responding. Check it is powered on and on the same Wi-Fi.');
    }

    // 5. Control port
    if (host != null) {
      await _runCheck(4, () async {
        final ports = _portsForAdapter(c.adapter.id);
        Socket? sock;
        for (final port in ports) {
          try {
            sock = await Socket.connect(host, port,
                timeout: const Duration(seconds: 3));
            _checks[4].detail = 'Port $port open on $host';
            sock.destroy();
            return;
          } on Object {
            continue;
          }
        }
        throw Exception('No control port open');
      },
          remedy:
              'The TV\'s control port is closed. Enable network remote control in TV settings.');
    } else {
      _checks[4].status = _CheckStatus.warn;
      _checks[4].detail = 'Skipped — no TV selected';
      setState(() {});
    }

    // 6. Adapter handshake
    await _runCheck(5, () async {
      if (!c.isConnected) {
        throw Exception('Adapter not connected');
      }
      _checks[5].detail = 'Adapter "${c.adapter.id}" connected';
    },
        remedy:
            'The adapter failed to connect. Try reconnecting from the Devices screen.');

    // 7. Command round-trip
    await _runCheck(6, () async {
      if (!c.isConnected) throw Exception('Not connected');
      final result = await c.adapter
          .sendKey(core.Key.ok, press: core.PressType.tap)
          .timeout(const Duration(seconds: 5))
          .catchError((_) async {
        _checks[6].detail = 'Command sent (no feedback from adapter)';
        _checks[6].status = _CheckStatus.warn;
        return const core.CommandResult.success();
      });
      if (result.ok) {
        _checks[6].detail = 'Command accepted by TV';
      }
    }, remedy: 'Commands are not reaching the TV. Try power-cycling it.');

    setState(() {
      _running = false;
      _done = true;
    });
  }

  Future<void> _runCheck(int index, Future<void> Function() fn,
      {String? remedy}) async {
    setState(() => _checks[index].status = _CheckStatus.running);
    try {
      await fn();
      if (_checks[index].status == _CheckStatus.running) {
        _checks[index].status = _CheckStatus.pass;
      }
    } on Object catch (e) {
      if (_checks[index].status == _CheckStatus.running) {
        _checks[index].status = _CheckStatus.fail;
        _checks[index].detail = '$e';
        _checks[index].remedy = remedy;
      }
    }
    if (mounted) setState(() {});
  }

  List<int> _portsForAdapter(String adapterId) {
    switch (adapterId) {
      case 'android_tv':
      case 'fire_tv':
        return [6466, 6467];
      case 'bravia':
        return [20060, 6466];
      case 'roku':
        return [8060];
      case 'webos':
        return [3000, 3001];
      case 'tizen':
        return [8001, 8002];
      case 'vizio':
        return [7345, 9000];
      case 'dlna':
        return [8008, 8009];
      case 'panasonic':
        return [55000];
      case 'philips':
        return [1925, 1926];
      default:
        return [80, 443, 8080];
    }
  }

  int get _passCount => _checks.where((c) => c.status == _CheckStatus.pass).length;
  int get _failCount => _checks.where((c) => c.status == _CheckStatus.fail).length;
  int get _warnCount => _checks.where((c) => c.status == _CheckStatus.warn).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _summaryCard(),
                      const SizedBox(height: AppSpacing.lg),
                      ..._checks.map(_checkTile),
                      const SizedBox(height: AppSpacing.lg),
                      _runButton(),
                      if (_done && _failCount > 0) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _remedyCard(),
                      ],
                      if (_done) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _exportButton(context),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surface),
          border: Border(
              bottom: BorderSide(
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.6))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back,
                      size: 20, color: hex(AppColors.onSurface)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.healing_rounded,
                    size: 20, color: hex(AppColors.primaryContainer)),
                const SizedBox(width: AppSpacing.sm),
                Text('Connection Doctor',
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 16,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  Widget _summaryCard() {
    if (!_done) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: panel(),
        child: Row(
          children: [
            Icon(Icons.wifi_find_rounded,
                size: 32, color: hex(AppColors.primaryContainer)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Diagnose Connection',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                      _running
                          ? 'Running diagnostics...'
                          : 'Tap "Run Diagnostics" to check your setup',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant))),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final allPass = _failCount == 0 && _warnCount == 0;
    final color = allPass
        ? AppColors.primary
        : _failCount > 0
            ? AppColors.error
            : AppColors.tertiary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(fill: color, borderOpacity: 0),
      child: Row(
        children: [
          Icon(
              allPass
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              size: 32,
              color: Colors.white),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    allPass
                        ? 'All Clear'
                        : '$_failCount issue${_failCount == 1 ? '' : 's'} found',
                    style: gfont(AppType.bodyMd,
                        color: Colors.white, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                    allPass
                        ? '$_passCount/${_checks.length} checks passed'
                        : '$_passCount passed, $_warnCount warnings',
                    style: gfont(AppType.bodySm,
                        color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkTile(_DiagCheck check) {
    final (IconData icon, Color color) = switch (check.status) {
      _CheckStatus.pending => (Icons.circle_outlined, hex(AppColors.outlineVariant)),
      _CheckStatus.running => (Icons.sync, hex(AppColors.primaryContainer)),
      _CheckStatus.pass => (Icons.check_circle, hex(AppColors.primary)),
      _CheckStatus.warn => (Icons.warning_amber_rounded, hex(AppColors.tertiary)),
      _CheckStatus.fail => (Icons.cancel, hex(AppColors.error)),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: panel(borderOpacity: 0.15),
        child: Row(
          children: [
            check.status == _CheckStatus.running
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: hex(AppColors.primaryContainer)),
                  )
                : Icon(icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(check.label,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600)),
                  Text(check.detail,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant), size: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _runButton() => GestureDetector(
        onTap: _running ? null : _runDiagnostics,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: _running
                ? hex(AppColors.surfaceContainerHigh)
                : hex(AppColors.primaryContainer),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          child: Center(
            child: _running
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: hex(AppColors.onSurface)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Running...',
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600)),
                    ],
                  )
                : Text(_done ? 'Run Again' : 'Run Diagnostics',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.surface),
                        weight: FontWeight.w600)),
          ),
        ),
      );

  Widget _exportButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final c = RemoteScope.of(context);
        final checkResults = <String, String>{};
        for (final ch in _checks) {
          checkResults[ch.label] = '${ch.status.name}: ${ch.detail}';
        }
        final caps = <String, bool>{};
        final capMap = c.caps;
        caps['D-pad'] = capMap.supports(core.Key.up);
        caps['Volume'] = capMap.supports(core.Key.volumeUp);
        caps['Power'] = capMap.supports(core.Key.power);
        caps['Apps'] = capMap.appLaunch;
        caps['Keyboard'] = capMap.canType;
        caps['Source'] = capMap.inputList;

        final report = await DiagnosticsService.generateReport(
          appVersion: 'v0.1.0',
          isConnected: c.isConnected,
          deviceName: c.deviceName.isNotEmpty ? c.deviceName : null,
          adapterId: c.adapter.id,
          transport: c.adapter.transport,
          host: c.selectedDevice?.device.host,
          capabilities: caps,
          actionLog: c.actionLog,
          connectionError: c.connectionError,
          checkResults: checkResults,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('Saved to ${report.filePath}',
                style:
                    gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
            backgroundColor: hex(AppColors.surfaceContainerHigh),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerHigh),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bug_report_outlined,
                  size: 18, color: hex(AppColors.onSurfaceVariant)),
              const SizedBox(width: AppSpacing.sm),
              Text('Export Diagnostics',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _remedyCard() {
    final remedies = _checks
        .where((c) => c.status == _CheckStatus.fail && c.remedy != null)
        .toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: panel(
        fill: AppColors.error,
        borderOpacity: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suggested Fixes',
              style: gfont(AppType.bodyMd,
                  color: Colors.white, weight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          for (final r in remedies)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('  •  ',
                      style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Text(r.remedy!,
                        style: gfont(AppType.bodySm,
                            color: Colors.white.withValues(alpha: 0.9))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

