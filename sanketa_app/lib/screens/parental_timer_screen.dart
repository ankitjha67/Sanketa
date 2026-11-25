import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class ParentalTimerScreen extends StatefulWidget {
  const ParentalTimerScreen({super.key});

  @override
  State<ParentalTimerScreen> createState() => _ParentalTimerScreenState();
}

class _ParentalTimerScreenState extends State<ParentalTimerScreen> {
  int _dailyLimitMinutes = 120;
  int _remainingSeconds = 0;
  bool _active = false;
  bool _pinProtected = false;
  String _pin = '';
  Timer? _countdown;
  bool _loading = true;

  static const _presets = <(int, String)>[
    (30, '30 min'),
    (60, '1 hour'),
    (90, '1.5 hrs'),
    (120, '2 hours'),
    (180, '3 hours'),
    (240, '4 hours'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/parental_timer.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _dailyLimitMinutes = j['dailyLimitMinutes'] as int? ?? 120;
        _pinProtected = j['pinProtected'] as bool? ?? false;
        _pin = j['pin'] as String? ?? '';
      }
    } on Object {
      // defaults
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'dailyLimitMinutes': _dailyLimitMinutes,
      'pinProtected': _pinProtected,
      'pin': _pin,
    }));
  }

  void _start() {
    setState(() {
      _active = true;
      _remainingSeconds = _dailyLimitMinutes * 60;
    });
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        _onTimeUp();
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _stop() {
    _countdown?.cancel();
    setState(() {
      _active = false;
      _remainingSeconds = 0;
    });
  }

  void _onTimeUp() {
    _countdown?.cancel();
    RemoteScope.of(context).key(core.Key.power);
    setState(() {
      _active = false;
      _remainingSeconds = 0;
    });
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: hex(AppColors.surface),
          title: Text('Time is up!',
              style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
          content: Text('The daily viewing limit has been reached. The TV has been powered off.',
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
  }

  void _addTime(int minutes) {
    if (!_active) return;
    setState(() => _remainingSeconds += minutes * 60);
  }

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  double get _progress {
    if (!_active || _dailyLimitMinutes == 0) return 0;
    return _remainingSeconds / (_dailyLimitMinutes * 60);
  }

  void _setPin() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: hex(AppColors.surface),
        title: Text(_pin.isEmpty ? 'Set PIN' : 'Change PIN',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 16, weight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface)),
          decoration: InputDecoration(
            hintText: '4-digit PIN',
            hintStyle: gfont(AppType.bodyMd, color: hex(AppColors.outline)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: gfont(AppType.bodyMd, color: hex(AppColors.outline))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.length == 4) {
                setState(() {
                  _pin = controller.text;
                  _pinProtected = true;
                });
                _save();
                Navigator.pop(ctx);
              }
            },
            child: Text('Save', style: gfont(AppType.bodyMd, color: hex(AppColors.primary), weight: FontWeight.w600)),
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
        title: Text('Parental Timer',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _timerDisplay(),
          const SizedBox(height: AppSpacing.lg),
          _limitSelector(),
          const SizedBox(height: AppSpacing.lg),
          _controlButtons(),
          if (_active) ...[
            const SizedBox(height: AppSpacing.md),
            _extendRow(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _pinSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _timerDisplay() => Container(
    padding: const EdgeInsets.all(AppSpacing.xl),
    decoration: BoxDecoration(
      color: hex(_active ? AppColors.primaryContainer : AppColors.surfaceContainerLow)
          .withValues(alpha: _active ? 0.15 : 1),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(
        color: hex(_active ? AppColors.primary : AppColors.outlineVariant)
            .withValues(alpha: _active ? 0.3 : 0.15),
      ),
    ),
    child: Column(
      children: [
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: _active ? _progress : 0,
                  strokeWidth: 6,
                  backgroundColor: hex(AppColors.surfaceContainerHigh),
                  color: _remainingSeconds < 300 && _active
                      ? hex(AppColors.error)
                      : hex(AppColors.primary),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _active ? Icons.timer : Icons.timer_off,
                    size: 24,
                    color: hex(_active ? AppColors.primary : AppColors.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _active ? _formatTime(_remainingSeconds) : 'Inactive',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: _active ? 14 : 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_active && _remainingSeconds < 300) ...[
          const SizedBox(height: 10),
          Text('Less than 5 minutes remaining',
              style: gfont(AppType.bodySm, color: hex(AppColors.error), size: 11, weight: FontWeight.w500)),
        ],
      ],
    ),
  );

  Widget _limitSelector() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Limit',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((p) {
            final active = _dailyLimitMinutes == p.$1;
            return GestureDetector(
              onTap: _active
                  ? null
                  : () {
                      setState(() => _dailyLimitMinutes = p.$1);
                      _save();
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primaryContainer : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.25 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.6 : 0.2),
                  ),
                ),
                child: Text(p.$2,
                    style: gfont(AppType.bodySm,
                        color: hex(active ? AppColors.primary : AppColors.onSurface),
                        weight: active ? FontWeight.w600 : FontWeight.w400,
                        size: 12)),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );

  Widget _controlButtons() => Row(
    children: [
      Expanded(
        child: GestureDetector(
          onTap: _active ? _stop : _start,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: hex(_active ? AppColors.error : AppColors.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: hex(_active ? AppColors.error : AppColors.primary).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_active ? Icons.stop : Icons.play_arrow,
                    size: 18, color: hex(_active ? AppColors.error : AppColors.primary)),
                const SizedBox(width: 8),
                Text(_active ? 'Stop Timer' : 'Start Timer',
                    style: gfont(AppType.bodyMd,
                        color: hex(_active ? AppColors.error : AppColors.primary),
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _extendRow() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Extend: ', style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
      _extendChip('+15m', 15),
      const SizedBox(width: 6),
      _extendChip('+30m', 30),
      const SizedBox(width: 6),
      _extendChip('+1h', 60),
    ],
  );

  Widget _extendChip(String label, int minutes) => GestureDetector(
    onTap: () => _addTime(minutes),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(label,
          style: gfont(AppType.bodySm, color: hex(AppColors.primary), size: 10, weight: FontWeight.w600)),
    ),
  );

  Widget _pinSection() => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: hex(AppColors.surfaceContainerLow),
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PIN Protection',
            style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_pinProtected && _pin.isNotEmpty) {
              setState(() {
                _pinProtected = false;
                _pin = '';
              });
              _save();
            } else {
              _setPin();
            }
          },
          child: Row(
            children: [
              Icon(Icons.lock,
                  size: 16, color: hex(_pinProtected ? AppColors.primary : AppColors.outline)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _pinProtected ? 'PIN enabled — tap to remove' : 'Set a PIN to prevent children from stopping the timer',
                  style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
                ),
              ),
              Container(
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: hex(_pinProtected ? AppColors.primary : AppColors.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 150),
                  alignment: _pinProtected ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: hex(_pinProtected ? AppColors.onPrimary : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
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
            'Set a daily viewing limit. When time runs out, the TV powers off automatically. Use the PIN to prevent children from disabling the timer.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
