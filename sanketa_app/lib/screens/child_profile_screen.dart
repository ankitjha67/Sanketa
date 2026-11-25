import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  bool _locked = false;
  String _pin = '1234';
  bool _loading = true;

  static const _actions = <(String, IconData, core.Key, int)>[
    ('Power', Icons.power_settings_new, core.Key.power, AppColors.error),
    ('Vol +', Icons.volume_up, core.Key.volumeUp, AppColors.primary),
    ('Vol -', Icons.volume_down, core.Key.volumeDown, AppColors.primary),
    ('Ch +', Icons.arrow_upward, core.Key.channelUp, AppColors.signalEmerald),
    ('Ch -', Icons.arrow_downward, core.Key.channelDown, AppColors.signalEmerald),
    ('OK', Icons.check_circle, core.Key.ok, AppColors.tertiary),
    ('Home', Icons.home, core.Key.home, AppColors.alertAmber),
    ('Back', Icons.arrow_back, core.Key.back, AppColors.secondary),
    ('Mute', Icons.volume_off, core.Key.mute, AppColors.outline),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/child_profile.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _pin = j['pin'] as String? ?? '1234';
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({'pin': _pin}));
  }

  void _enterKidMode() {
    setState(() => _locked = true);
  }

  void _exitKidMode() {
    _showPinDialog();
  }

  void _showPinDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surface),
        title: Text('Enter PIN to Exit',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          autofocus: true,
          style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
              borderSide: BorderSide(color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
            ),
          ),
          onSubmitted: (v) {
            if (v == _pin) {
              Navigator.pop(ctx);
              setState(() => _locked = false);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (ctrl.text == _pin) {
                Navigator.pop(ctx);
                setState(() => _locked = false);
              }
            },
            child: Text('Unlock', style: gfont(AppType.bodyMd, color: hex(AppColors.primary))),
          ),
        ],
      ),
    );
  }

  void _showSetPinDialog() {
    final ctrl = TextEditingController(text: _pin);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surface),
        title: Text('Set PIN',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          autofocus: true,
          style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '1234',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: gfont(AppType.bodyMd, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.length == 4) {
                setState(() => _pin = ctrl.text);
                _save();
                Navigator.pop(ctx);
              }
            },
            child: Text('Save', style: gfont(AppType.bodyMd, color: hex(AppColors.primary))),
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

    if (_locked) {
      return _kidMode();
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Child Profile',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _showSetPinDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.lock, size: 20, color: hex(AppColors.outline)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: _enterKidMode,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.child_care, size: 20, color: hex(AppColors.signalEmerald)),
                  const SizedBox(width: 8),
                  Text('Enter Kid Mode',
                      style: gfont(AppType.bodyMd, color: hex(AppColors.signalEmerald), weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _settingsSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Icon(Icons.child_care, size: 48, color: hex(AppColors.signalEmerald)),
        const SizedBox(height: 8),
        Text('Kid-Friendly Remote',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Large buttons, limited actions, PIN to exit',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
      ],
    ),
  );

  Widget _settingsSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.pin, size: 16, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            Text('Exit PIN', style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 12)),
            const Spacer(),
            Text('*' * _pin.length,
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showSetPinDialog,
              child: Text('Change', style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 11, weight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.grid_view, size: 16, color: hex(AppColors.outline)),
            const SizedBox(width: 8),
            Text('Available buttons', style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 12)),
            const Spacer(),
            Text('${_actions.length}',
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 12)),
          ],
        ),
      ],
    ),
  );

  Widget _kidMode() => Scaffold(
    backgroundColor: hex(AppColors.surface),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.child_care, size: 20, color: hex(AppColors.signalEmerald)),
                const SizedBox(width: 6),
                Text('Kid Mode',
                    style: gfont(AppType.bodyMd, color: hex(AppColors.signalEmerald), weight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: _exitKidMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hex(AppColors.surfaceContainerHigh),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: hex(AppColors.outline)),
                        const SizedBox(width: 4),
                        Text('Exit', style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: _actions.map((a) => _kidButton(a.$1, a.$2, a.$3, a.$4)).toList(),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _kidButton(String label, IconData icon, core.Key key, int color) => GestureDetector(
    onTap: () => RemoteScope.of(context).key(key),
    child: Container(
      decoration: BoxDecoration(
        color: hex(color).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: hex(color).withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: hex(color)),
          const SizedBox(height: 6),
          Text(label,
              style: gfont(AppType.bodyMd, color: hex(color), weight: FontWeight.w600, size: 13)),
        ],
      ),
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
            'Kid Mode shows only large, simple buttons. A 4-digit PIN is required to exit, keeping little hands safe from changing settings.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
