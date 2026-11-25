import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';

class FirmwareInfoScreen extends StatefulWidget {
  const FirmwareInfoScreen({super.key});

  @override
  State<FirmwareInfoScreen> createState() => _FirmwareInfoScreenState();
}

class _FirmwareInfoScreenState extends State<FirmwareInfoScreen> {
  String _tvModel = 'Sony BRAVIA XR-55A95L';
  String _firmware = '10.4.2.3';
  String _androidTv = 'Android TV 14';
  String _serialNo = 'SN-2024-X9A5LK3';
  String _chipset = 'MediaTek MT5895';
  String _ram = '4 GB';
  String _storage = '32 GB (18.4 GB free)';
  String _resolution = '3840 × 2160 (4K UHD)';
  String _hdrFormats = 'HDR10, HDR10+, Dolby Vision, HLG';
  String _lastUpdate = '2026-09-15';
  bool _loading = true;
  bool _checking = false;
  String? _updateStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/firmware_info.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _tvModel = j['tvModel'] as String? ?? _tvModel;
        _firmware = j['firmware'] as String? ?? _firmware;
        _androidTv = j['androidTv'] as String? ?? _androidTv;
        _serialNo = j['serialNo'] as String? ?? _serialNo;
        _chipset = j['chipset'] as String? ?? _chipset;
        _ram = j['ram'] as String? ?? _ram;
        _storage = j['storage'] as String? ?? _storage;
        _resolution = j['resolution'] as String? ?? _resolution;
        _hdrFormats = j['hdrFormats'] as String? ?? _hdrFormats;
        _lastUpdate = j['lastUpdate'] as String? ?? _lastUpdate;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _checkForUpdate() async {
    setState(() { _checking = true; _updateStatus = null; });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _checking = false;
        _updateStatus = 'Your TV firmware is up to date.';
      });
    }
  }

  void _copyInfo() {
    final buf = StringBuffer()
      ..writeln('TV Model: $_tvModel')
      ..writeln('Firmware: $_firmware')
      ..writeln('OS: $_androidTv')
      ..writeln('Serial: $_serialNo')
      ..writeln('Chipset: $_chipset')
      ..writeln('RAM: $_ram')
      ..writeln('Storage: $_storage')
      ..writeln('Resolution: $_resolution')
      ..writeln('HDR: $_hdrFormats')
      ..writeln('Last Update: $_lastUpdate');
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Info copied to clipboard')),
    );
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
        title: Text('Firmware Info',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _copyInfo,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.copy, size: 20, color: hex(AppColors.outline)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _deviceCard(),
          const SizedBox(height: AppSpacing.md),
          _displayCard(),
          const SizedBox(height: AppSpacing.md),
          _updateSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.primary).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Icon(Icons.tv, size: 40, color: hex(AppColors.primary)),
        const SizedBox(height: 8),
        Text(_tvModel,
            textAlign: TextAlign.center,
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Firmware $_firmware',
            style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12)),
        const SizedBox(height: 2),
        Text(_androidTv,
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
      ],
    ),
  );

  Widget _deviceCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hardware',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _row('Serial', _serialNo),
        _row('Chipset', _chipset),
        _row('RAM', _ram),
        _row('Storage', _storage),
      ],
    ),
  );

  Widget _displayCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        _row('Resolution', _resolution),
        _row('HDR', _hdrFormats),
        _row('Last Update', _lastUpdate),
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ),
        Expanded(
          child: Text(value,
              style: gfont(AppType.labelMonoSm, color: hex(AppColors.onSurface), size: 11, weight: FontWeight.w500)),
        ),
      ],
    ),
  );

  Widget _updateSection() => Container(
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
            Text('Software Update',
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const Spacer(),
            if (_updateStatus != null)
              Icon(Icons.check_circle, size: 16, color: hex(AppColors.signalEmerald)),
          ],
        ),
        if (_updateStatus != null) ...[
          const SizedBox(height: 6),
          Text(_updateStatus!,
              style: gfont(AppType.bodySm, color: hex(AppColors.signalEmerald), size: 11)),
        ],
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _checking ? null : _checkForUpdate,
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
                if (_checking)
                  SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: hex(AppColors.primary)))
                else
                  Icon(Icons.system_update, size: 16, color: hex(AppColors.primary)),
                const SizedBox(width: 8),
                Text(_checking ? 'Checking...' : 'Check for Updates',
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
            'Displays your TV hardware and firmware details. Tap Copy to share system info for troubleshooting. Update checks are done locally via the TV protocol.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
