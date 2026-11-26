import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ChannelLockScreen extends StatefulWidget {
  const ChannelLockScreen({super.key});

  @override
  State<ChannelLockScreen> createState() => _ChannelLockScreenState();
}

class _ChannelLockScreenState extends State<ChannelLockScreen> {
  String _pin = '';
  bool _unlocked = false;
  bool _loading = true;
  final _pinCtrl = TextEditingController();
  final _channelCtrl = TextEditingController();

  List<(int, String, bool)> _locked = [];

  static const _sampleChannels = <(int, String)>[
    (18, 'HBO'),
    (25, 'Adult Swim'),
    (42, 'Showtime'),
    (67, 'Cinemax'),
    (99, 'Pay-Per-View'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _channelCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/channel_lock.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final d = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _pin = d['pin'] as String? ?? '';
        final list = d['channels'] as List?;
        if (list != null) {
          _locked = list.map((j) {
            final m = j as Map<String, dynamic>;
            return (m['ch'] as int, m['name'] as String, m['locked'] as bool);
          }).toList();
        }
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'pin': _pin,
      'channels': _locked.map((c) => {'ch': c.$1, 'name': c.$2, 'locked': c.$3}).toList(),
    }));
  }

  void _setPin() {
    if (_pinCtrl.text.trim().length != 4) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
      return;
    }
    setState(() {
      _pin = _pinCtrl.text.trim();
      _unlocked = true;
    });
    _pinCtrl.clear();
    _save();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('PIN set successfully')));
  }

  void _verifyPin() {
    if (_pinCtrl.text.trim() == _pin) {
      setState(() => _unlocked = true);
      _pinCtrl.clear();
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Incorrect PIN')));
      _pinCtrl.clear();
    }
  }

  void _addChannel() {
    final ch = int.tryParse(_channelCtrl.text.trim());
    if (ch == null || ch < 1) return;
    if (_locked.length >= 50) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Maximum 50 locked channels')));
      return;
    }
    setState(() => _locked.add((ch, 'Channel $ch', true)));
    _channelCtrl.clear();
    _save();
  }

  void _toggleLock(int i) {
    setState(() {
      final c = _locked[i];
      _locked[i] = (c.$1, c.$2, !c.$3);
    });
    _save();
  }

  void _removeChannel(int i) {
    setState(() => _locked.removeAt(i));
    _save();
  }

  void _quickFill() {
    setState(() {
      _locked = _sampleChannels.map((c) => (c.$1, c.$2, true)).toList();
    });
    _save();
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
        title: Text('Channel Lock',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          if (_pin.isEmpty)
            _setPinSection()
          else if (!_unlocked)
            _enterPinSection()
          else ...[
            _addSection(),
            const SizedBox(height: AppSpacing.md),
            if (_locked.isEmpty) _emptyState() else _channelList(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock, size: 36, color: hex(AppColors.error)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Parental Channel Lock',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.error), weight: FontWeight.w600)),
                  Text('PIN-protect channels from unauthorized viewing',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _setPinSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(Icons.pin, size: 40, color: hex(AppColors.error)),
            const SizedBox(height: 12),
            Text('Set a 4-digit PIN',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '****',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            GestureDetector(
              onTap: _setPin,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('Set PIN',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.error), weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _enterPinSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 40, color: hex(AppColors.error)),
            const SizedBox(height: 12),
            Text('Enter PIN to manage locked channels',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '****',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            GestureDetector(
              onTap: _verifyPin,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('Unlock',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary), weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _addSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lock a Channel',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _channelCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 4,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'Channel #',
                      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                      isDense: true,
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addChannel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(AppColors.error).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text('Lock',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.error), weight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _quickFill,
                  child: Text('Samples',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.primary), size: 10, weight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _channelList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Locked Channels (${_locked.length})',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_locked.length, (i) {
            final c = _locked[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(c.$3 ? AppColors.error : AppColors.surfaceContainerLow)
                      .withValues(alpha: c.$3 ? 0.06 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: hex(c.$3 ? AppColors.error : AppColors.outlineVariant)
                        .withValues(alpha: c.$3 ? 0.3 : 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(c.$3 ? Icons.lock : Icons.lock_open, size: 18,
                        color: hex(c.$3 ? AppColors.error : AppColors.signalEmerald)),
                    const SizedBox(width: 10),
                    Text('Ch ${c.$1}',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface), weight: FontWeight.w700, size: 13)),
                    const SizedBox(width: 8),
                    Text(c.$2,
                        style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _toggleLock(i),
                      child: Icon(c.$3 ? Icons.lock : Icons.lock_open, size: 20,
                          color: hex(c.$3 ? AppColors.error : AppColors.signalEmerald)),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeChannel(i),
                      child: Icon(Icons.delete_outline, size: 18, color: hex(AppColors.outline)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      );

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.lock_open, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No channels locked',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add channel numbers to lock them with your PIN.',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
        ],
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
                'Lock channels behind a 4-digit PIN to prevent unauthorized viewing. PIN and locked channels are stored locally on your phone only.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
