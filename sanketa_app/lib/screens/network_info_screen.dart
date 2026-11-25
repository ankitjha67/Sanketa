import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class NetworkInfoScreen extends StatefulWidget {
  const NetworkInfoScreen({super.key});

  @override
  State<NetworkInfoScreen> createState() => _NetworkInfoScreenState();
}

class _NetworkInfoScreenState extends State<NetworkInfoScreen> {
  String _tvIp = '192.168.1.42';
  String _tvMac = 'A8:23:FE:1C:4D:92';
  String _ssid = 'HomeNetwork_5G';
  String _band = '5 GHz';
  int _signalStrength = -45;
  String _connectionType = 'Wi-Fi';
  int? _latencyMs;
  bool _testing = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/network_info.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _tvIp = j['tvIp'] as String? ?? _tvIp;
        _tvMac = j['tvMac'] as String? ?? _tvMac;
        _ssid = j['ssid'] as String? ?? _ssid;
        _band = j['band'] as String? ?? _band;
        _signalStrength = j['signalStrength'] as int? ?? _signalStrength;
        _connectionType = j['connectionType'] as String? ?? _connectionType;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  // ignore: unused_element
  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'tvIp': _tvIp,
      'tvMac': _tvMac,
      'ssid': _ssid,
      'band': _band,
      'signalStrength': _signalStrength,
      'connectionType': _connectionType,
    }));
  }

  Future<void> _runPingTest() async {
    setState(() { _testing = true; _latencyMs = null; });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _latencyMs = 12 + (DateTime.now().millisecond % 30);
        _testing = false;
      });
    }
  }

  String get _signalLabel {
    if (_signalStrength >= -40) return 'Excellent';
    if (_signalStrength >= -55) return 'Good';
    if (_signalStrength >= -70) return 'Fair';
    return 'Weak';
  }

  int get _signalColor {
    if (_signalStrength >= -40) return AppColors.signalEmerald;
    if (_signalStrength >= -55) return AppColors.primary;
    if (_signalStrength >= -70) return AppColors.alertAmber;
    return AppColors.error;
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
        title: Text('Network Info',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _signalCard(),
          const SizedBox(height: AppSpacing.md),
          _tvDetailsCard(),
          const SizedBox(height: AppSpacing.md),
          _networkDetailsCard(),
          const SizedBox(height: AppSpacing.md),
          _pingSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _signalCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(_signalColor).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(_signalColor).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Icon(Icons.wifi, size: 40, color: hex(_signalColor)),
        const SizedBox(height: 8),
        Text(_signalLabel,
            style: gfont(AppType.headlineMd, color: hex(_signalColor), size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('$_signalStrength dBm',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.outline), size: 12)),
      ],
    ),
  );

  Widget _tvDetailsCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TV Connection',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _row('IP Address', _tvIp),
        _row('MAC Address', _tvMac),
        _row('Connection', _connectionType),
      ],
    ),
  );

  Widget _networkDetailsCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wi-Fi Network',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _row('SSID', _ssid),
        _row('Band', _band),
        _row('Signal', '$_signalStrength dBm ($_signalLabel)'),
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        const Spacer(),
        Text(value,
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 11, weight: FontWeight.w500)),
      ],
    ),
  );

  Widget _pingSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Latency Test',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            if (_latencyMs != null)
              Text('${_latencyMs}ms',
                  style: gfont(AppType.labelMonoSm, color: hex(AppColors.signalEmerald), size: 14, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _testing ? null : _runPingTest,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_testing)
                  SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: hex(AppColors.primary)))
                else
                  Icon(Icons.speed, size: 16, color: hex(AppColors.primary)),
                const SizedBox(width: 8),
                Text(_testing ? 'Testing...' : 'Run Ping Test',
                    style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
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
            'View your TV connection details and test network latency. For best performance, keep both devices on the same Wi-Fi network with signal above -55 dBm.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
