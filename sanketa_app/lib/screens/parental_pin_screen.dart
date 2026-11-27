import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class ParentalPinScreen extends StatefulWidget {
  const ParentalPinScreen({super.key});

  @override
  State<ParentalPinScreen> createState() => _ParentalPinScreenState();
}

class _ParentalPinScreenState extends State<ParentalPinScreen> {
  bool _loading = true;
  bool _pinEnabled = false;
  String _currentPin = '0000';
  bool _locked = false;
  final _pinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  String _enteredPin = '';

  static const _protectedActions = <(String, IconData, int)>[
    ('App Store Access', Icons.store, AppColors.primary),
    ('Settings Changes', Icons.settings, AppColors.secondary),
    ('Channel Purchases', Icons.shopping_cart, AppColors.tertiary),
    ('Content Ratings', Icons.family_restroom, AppColors.signalEmerald),
    ('Network Settings', Icons.wifi, AppColors.alertAmber),
    ('System Reset', Icons.restart_alt, AppColors.error),
  ];

  final _actionStates = <String, bool>{};

  @override
  void initState() {
    super.initState();
    for (final a in _protectedActions) {
      _actionStates[a.$1] = false;
    }
    _load();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _newPinCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/parental_pin.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _pinEnabled = j['pinEnabled'] as bool? ?? false;
        _currentPin = j['pin'] as String? ?? '0000';
        final actions = j['actions'] as Map<String, dynamic>? ?? {};
        for (final key in actions.keys) {
          _actionStates[key] = actions[key] as bool? ?? false;
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'pinEnabled': _pinEnabled,
      'pin': _currentPin,
      'actions': _actionStates,
    }));
  }

  void _toggleAction(String name) {
    setState(() => _actionStates[name] = !(_actionStates[name] ?? false));
    HapticFeedback.selectionClick();
    _save();
  }

  void _enterDigit(String d) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += d);
      HapticFeedback.selectionClick();
      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _deleteLast() {
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
      HapticFeedback.selectionClick();
    }
  }

  void _verifyPin() {
    if (_enteredPin == _currentPin) {
      setState(() {
        _locked = false;
        _enteredPin = '';
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('PIN verified — unlocked'),
          duration: Duration(seconds: 2),
        ));
    } else {
      setState(() => _enteredPin = '');
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Incorrect PIN'),
          duration: Duration(seconds: 2),
        ));
    }
  }

  void _changePin() {
    _newPinCtrl.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surfaceContainerLow),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Set New PIN',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 16,
                    weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _newPinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 24,
                  weight: FontWeight.w700),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '4 digits',
                hintStyle: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(
                      color: hex(AppColors.outlineVariant)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  borderSide: BorderSide(color: hex(AppColors.primary)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () {
                final pin = _newPinCtrl.text;
                if (pin.length == 4 &&
                    RegExp(r'^\d{4}$').hasMatch(pin)) {
                  setState(() => _currentPin = pin);
                  _save();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                    ..clearSnackBars()
                    ..showSnackBar(const SnackBar(
                      content: Text('PIN updated'),
                      duration: Duration(seconds: 2),
                    ));
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('Save PIN',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _lockNow() {
    setState(() => _locked = true);
    HapticFeedback.mediumImpact();
  }

  int get _protectedCount =>
      _actionStates.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Parental PIN',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _locked
              ? _lockScreen()
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _heroCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _pinToggle(),
                    if (_pinEnabled) ...[
                      const SizedBox(height: AppSpacing.md),
                      _pinActions(),
                      const SizedBox(height: AppSpacing.md),
                      _statsRow(),
                      const SizedBox(height: AppSpacing.md),
                      ..._protectedActions.map((a) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _actionCard(a),
                          )),
                      const SizedBox(height: AppSpacing.md),
                      _lockButton(),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _infoCard(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
    );
  }

  Widget _lockScreen() => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: hex(AppColors.error)),
            const SizedBox(height: AppSpacing.lg),
            Text('Enter PIN to unlock',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 18,
                    weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _enteredPin.length;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: filled
                        ? hex(AppColors.primary)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hex(filled
                          ? AppColors.primary
                          : AppColors.outlineVariant),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            _numpad(),
          ],
        ),
      );

  Widget _numpad() => SizedBox(
        width: 240,
        child: Column(
          children: [
            for (var row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '<'],
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row.map((d) {
                    if (d.isEmpty) return const SizedBox(width: 60);
                    return GestureDetector(
                      onTap: () => d == '<' ? _deleteLast() : _enterDigit(d),
                      child: Container(
                        width: 60,
                        height: 50,
                        decoration: BoxDecoration(
                          color: hex(AppColors.surfaceContainerLow),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          border: Border.all(
                              color: hex(AppColors.outlineVariant)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Center(
                          child: d == '<'
                              ? Icon(Icons.backspace_outlined,
                                  size: 20, color: hex(AppColors.error))
                              : Text(d,
                                  style: gfont(AppType.headlineMd,
                                      color: hex(AppColors.onSurface),
                                      size: 20,
                                      weight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.error).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.error).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.pin, size: 48, color: hex(AppColors.error)),
            const SizedBox(height: 8),
            Text('PIN Protection',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.error), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Lock settings and purchases behind a PIN',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _pinToggle() => GestureDetector(
        onTap: () {
          setState(() => _pinEnabled = !_pinEnabled);
          HapticFeedback.mediumImpact();
          _save();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(_pinEnabled
                    ? AppColors.error
                    : AppColors.surfaceContainerLow)
                .withValues(alpha: _pinEnabled ? 0.1 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_pinEnabled
                      ? AppColors.error
                      : AppColors.outlineVariant)
                  .withValues(alpha: _pinEnabled ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.lock,
                  size: 22,
                  color: hex(
                      _pinEnabled ? AppColors.error : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PIN Lock',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600)),
                    Text(_pinEnabled ? 'Active — PIN: ****' : 'Disabled',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hex(_pinEnabled
                          ? AppColors.error
                          : AppColors.outline)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(_pinEnabled ? 'ON' : 'OFF',
                    style: gfont(AppType.bodySm,
                        color: hex(
                            _pinEnabled ? AppColors.error : AppColors.outline),
                        weight: FontWeight.w700,
                        size: 11)),
              ),
            ],
          ),
        ),
      );

  Widget _pinActions() => Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _changePin,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.primary).withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text('Change PIN',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600,
                          size: 12)),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: _lockNow,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: hex(AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                      color: hex(AppColors.error).withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text('Lock Now',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.error),
                          weight: FontWeight.w600,
                          size: 12)),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _statsRow() => Row(
        children: [
          Expanded(
              child: _statBadge(
                  'Protected', '$_protectedCount', AppColors.error)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Unprotected',
                  '${_protectedActions.length - _protectedCount}',
                  AppColors.outline)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 20, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _actionCard((String, IconData, int) action) => GestureDetector(
        onTap: () => _toggleAction(action.$1),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex((_actionStates[action.$1] ?? false)
                    ? action.$3
                    : AppColors.surfaceContainerLow)
                .withValues(
                    alpha: (_actionStates[action.$1] ?? false) ? 0.08 : 1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex((_actionStates[action.$1] ?? false)
                      ? action.$3
                      : AppColors.outlineVariant)
                  .withValues(
                      alpha: (_actionStates[action.$1] ?? false) ? 0.3 : 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(action.$2,
                  size: 20,
                  color: hex((_actionStates[action.$1] ?? false)
                      ? action.$3
                      : AppColors.outline)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(action.$1,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w500,
                        size: 13)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hex((_actionStates[action.$1] ?? false)
                          ? action.$3
                          : AppColors.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(
                    (_actionStates[action.$1] ?? false) ? 'LOCKED' : 'OPEN',
                    style: gfont(AppType.bodySm,
                        color: hex((_actionStates[action.$1] ?? false)
                            ? action.$3
                            : AppColors.outline),
                        weight: FontWeight.w600,
                        size: 9)),
              ),
            ],
          ),
        ),
      );

  Widget _lockButton() => GestureDetector(
        onTap: _lockNow,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.error).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.error).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 20, color: hex(AppColors.error)),
              const SizedBox(width: 8),
              Text('Lock Controls Now',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.error),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Set a 4-digit PIN to protect settings and purchases. '
                'Choose which actions require PIN entry. PIN stored locally only.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
