import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class RemoteLockScreen extends StatefulWidget {
  const RemoteLockScreen({super.key});

  @override
  State<RemoteLockScreen> createState() => _RemoteLockScreenState();
}

class _RemoteLockScreenState extends State<RemoteLockScreen> {
  bool _locked = false;
  bool _usePinLock = false;
  String _pin = '';
  bool _lockOnTimeout = false;
  int _timeoutSeconds = 30;
  bool _allowVolume = true;
  bool _allowPower = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/remote_lock.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _usePinLock = j['usePinLock'] as bool? ?? false;
        _pin = j['pin'] as String? ?? '';
        _lockOnTimeout = j['lockOnTimeout'] as bool? ?? false;
        _timeoutSeconds = j['timeoutSeconds'] as int? ?? 30;
        _allowVolume = j['allowVolume'] as bool? ?? true;
        _allowPower = j['allowPower'] as bool? ?? false;
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'usePinLock': _usePinLock,
      'pin': _pin,
      'lockOnTimeout': _lockOnTimeout,
      'timeoutSeconds': _timeoutSeconds,
      'allowVolume': _allowVolume,
      'allowPower': _allowPower,
    }));
  }

  void _toggleLock() {
    if (_locked && _usePinLock && _pin.isNotEmpty) {
      _showPinDialog();
    } else {
      setState(() => _locked = !_locked);
    }
  }

  void _showPinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surface),
        title: Text('Enter PIN to Unlock',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          autofocus: true,
          style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 24, weight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '- - - -',
            hintStyle: gfont(AppType.headlineMd, color: hex(AppColors.outline), size: 24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
          onSubmitted: (val) {
            if (val == _pin) {
              Navigator.pop(ctx);
              setState(() => _locked = false);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == _pin) {
                Navigator.pop(ctx);
                setState(() => _locked = false);
              }
            },
            child: Text('Unlock', style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _setPin() {
    final controller = TextEditingController(text: _pin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surface),
        title: Text('Set Lock PIN',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          autofocus: true,
          style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 24, weight: FontWeight.w700),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '4 digits',
            hintStyle: gfont(AppType.bodyMd, color: hex(AppColors.outline)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.length == 4) {
                setState(() => _pin = controller.text);
                _save();
                Navigator.pop(ctx);
              }
            },
            child: Text('Save', style: gfont(AppType.bodySm, color: hex(AppColors.primary), weight: FontWeight.w600)),
          ),
        ],
      ),
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
        title: Text('Remote Lock',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _lockButton(),
          const SizedBox(height: AppSpacing.lg),
          _pinSection(),
          const SizedBox(height: AppSpacing.lg),
          _autoLockSection(),
          const SizedBox(height: AppSpacing.lg),
          _exceptionsSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _lockButton() => GestureDetector(
    onTap: _toggleLock,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: panel(
        fill: _locked ? AppColors.error : AppColors.surfaceContainerLowest,
        radius: AppRadii.lg,
        borderOpacity: _locked ? 0.4 : 0.15,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: hex(_locked ? AppColors.error : AppColors.signalEmerald).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _locked ? Icons.lock : Icons.lock_open,
              size: 36,
              color: hex(_locked ? AppColors.error : AppColors.signalEmerald),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _locked ? 'Remote Locked' : 'Remote Unlocked',
            style: gfont(AppType.headlineMd,
                color: hex(_locked ? AppColors.error : AppColors.onSurface),
                size: 18,
                weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _locked ? 'Tap to unlock' : 'Tap to lock',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline)),
          ),
        ],
      ),
    ),
  );

  Widget _pinSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PIN Protection',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _toggleRow(Icons.pin, 'Require PIN to unlock', _usePinLock, (v) {
          setState(() => _usePinLock = v);
          _save();
        }),
        if (_usePinLock) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _setPin,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, size: 14, color: hex(AppColors.outline)),
                  const SizedBox(width: 8),
                  Text(_pin.isEmpty ? 'Set PIN' : 'Change PIN (${_pin.replaceAll(RegExp(r'.'), '*')})',
                      style: gfont(AppType.bodySm, color: hex(AppColors.onSurface))),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _autoLockSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Auto-Lock',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _toggleRow(Icons.timer, 'Lock after inactivity', _lockOnTimeout, (v) {
          setState(() => _lockOnTimeout = v);
          _save();
        }),
        if (_lockOnTimeout) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [15, 30, 60, 120].map((s) {
              final active = _timeoutSeconds == s;
              return GestureDetector(
                onTap: () {
                  setState(() => _timeoutSeconds = s);
                  _save();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                        .withValues(alpha: active ? 0.25 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text('${s}s',
                      style: gfont(AppType.bodySm,
                          color: hex(active ? AppColors.primary : AppColors.onSurface),
                          weight: active ? FontWeight.w600 : FontWeight.w400,
                          size: 12)),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    ),
  );

  Widget _exceptionsSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: panel(radius: AppRadii.md, borderOpacity: 0.15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allow While Locked',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        _toggleRow(Icons.volume_up, 'Volume controls', _allowVolume, (v) {
          setState(() => _allowVolume = v);
          _save();
        }),
        const SizedBox(height: 6),
        _toggleRow(Icons.power_settings_new, 'Power button', _allowPower, (v) {
          setState(() => _allowPower = v);
          _save();
        }),
      ],
    ),
  );

  Widget _toggleRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 16, color: hex(value ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: gfont(AppType.bodySm, color: hex(AppColors.onSurface)))),
            Container(
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: hex(value ? AppColors.primary : AppColors.surfaceContainerHigh),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: hex(value ? AppColors.onPrimary : AppColors.outline),
                    shape: BoxShape.circle,
                  ),
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
            'Lock the remote to prevent accidental button presses in your pocket or by children. Volume and power exceptions keep essential controls available.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
