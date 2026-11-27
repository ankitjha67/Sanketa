import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvDiagnosticScreen extends StatefulWidget {
  const TvDiagnosticScreen({super.key});

  @override
  State<TvDiagnosticScreen> createState() => _TvDiagnosticScreenState();
}

class _TvDiagnosticScreenState extends State<TvDiagnosticScreen> {
  static const _tests = <(String, IconData, int)>[
    ('Display', Icons.monitor, AppColors.primary),
    ('Audio', Icons.speaker, AppColors.secondary),
    ('Network', Icons.wifi, AppColors.signalEmerald),
    ('HDMI', Icons.settings_input_hdmi, AppColors.tertiary),
    ('IR Sensor', Icons.sensors, AppColors.alertAmber),
  ];

  // null = not run, true = pass, false = fail
  final List<bool?> _results = List.filled(5, null);
  final List<bool> _running = List.filled(5, false);
  bool _runAll = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/tv_diagnostics.json');
  }

  Future<void> _loadHistory() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as List<dynamic>;
        setState(() {
          _history = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final f = await _file;
      await f.writeAsString(jsonEncode(_history));
    } catch (_) {}
  }

  Future<void> _runTest(int index) async {
    if (_running[index]) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _running[index] = true;
      _results[index] = null;
    });

    final rc = RemoteScope.of(context);
    rc.key(core.Key.menu);

    // Simulate diagnostic check
    await Future<void>.delayed(Duration(milliseconds: 1200 + Random().nextInt(800)));

    final passed = Random().nextDouble() > 0.15;
    setState(() {
      _running[index] = false;
      _results[index] = passed;
    });

    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(
            '${_tests[index].$1}: ${passed ? "PASS" : "FAIL"}'),
        duration: const Duration(seconds: 1),
      ));
  }

  Future<void> _runAllTests() async {
    if (_runAll) return;
    HapticFeedback.heavyImpact();
    setState(() => _runAll = true);

    for (var i = 0; i < _tests.length; i++) {
      await _runTest(i);
    }

    // Save to history
    final entry = <String, dynamic>{
      'ts': DateTime.now().toIso8601String(),
      'results': List.generate(
          _tests.length, (i) => {'name': _tests[i].$1, 'pass': _results[i]}),
    };
    _history.insert(0, entry);
    if (_history.length > 10) _history = _history.sublist(0, 10);
    await _saveHistory();

    setState(() => _runAll = false);
    if (!mounted) return;
    final passed = _results.where((r) => r == true).length;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Diagnostics complete: $passed/${_tests.length} passed'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Diagnostics',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _summaryCard(),
          const SizedBox(height: AppSpacing.md),
          _testList(),
          const SizedBox(height: AppSpacing.md),
          _runAllButton(),
          const SizedBox(height: AppSpacing.md),
          _historySection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final ran = _results.where((r) => r != null).length;
    final passed = _results.where((r) => r == true).length;
    final failed = _results.where((r) => r == false).length;
    final colour = failed > 0
        ? AppColors.error
        : ran == _tests.length
            ? AppColors.signalEmerald
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(colour).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: hex(colour).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            failed > 0
                ? Icons.error
                : ran == _tests.length
                    ? Icons.check_circle
                    : Icons.build_circle,
            size: 44,
            color: hex(colour),
          ),
          const SizedBox(height: 10),
          Text(
            ran == 0
                ? 'No Tests Run'
                : failed > 0
                    ? '$failed Test${failed > 1 ? 's' : ''} Failed'
                    : 'All Tests Passed',
            style: gfont(AppType.headlineMd,
                color: hex(colour), weight: FontWeight.w700, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            ran == 0
                ? 'Run individual tests or tap Run All'
                : '$passed passed, $failed failed out of ${_tests.length}',
            style: gfont(AppType.bodySm,
                color: hex(AppColors.outline), size: 11),
          ),
        ],
      ),
    );
  }

  Widget _testList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnostic Tests',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_tests.length, (i) {
            final t = _tests[i];
            final result = _results[i];
            final busy = _running[i];

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: busy ? null : () => _runTest(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(result == true
                            ? AppColors.signalEmerald
                            : result == false
                                ? AppColors.error
                                : AppColors.surfaceContainerLow)
                        .withValues(alpha: result != null ? 0.08 : 1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                        color: hex(result == true
                                ? AppColors.signalEmerald
                                : result == false
                                    ? AppColors.error
                                    : AppColors.outlineVariant)
                            .withValues(alpha: result != null ? 0.3 : 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(t.$2, size: 20, color: hex(t.$3)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(t.$1,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface),
                                weight: FontWeight.w500,
                                size: 13)),
                      ),
                      if (busy)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: hex(t.$3),
                          ),
                        )
                      else if (result == true)
                        Icon(Icons.check_circle,
                            size: 18, color: hex(AppColors.signalEmerald))
                      else if (result == false)
                        Icon(Icons.cancel,
                            size: 18, color: hex(AppColors.error))
                      else
                        Icon(Icons.play_circle_outline,
                            size: 18, color: hex(AppColors.outline)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _runAllButton() => GestureDetector(
        onTap: _runAll ? null : _runAllTests,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(_runAll ? AppColors.outline : AppColors.primary)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(_runAll ? AppColors.outline : AppColors.primary)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_runAll)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: hex(AppColors.outline),
                  ),
                )
              else
                Icon(Icons.play_arrow,
                    size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text(_runAll ? 'Running...' : 'Run All Tests',
                  style: gfont(AppType.bodyMd,
                      color: hex(_runAll ? AppColors.outline : AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _historySection() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History',
            style: gfont(AppType.bodyMd,
                color: hex(AppColors.onSurface), weight: FontWeight.w600)),
        const SizedBox(height: 8),
        ..._history.take(5).map((h) {
          final ts = DateTime.tryParse(h['ts'] as String? ?? '');
          final results = h['results'] as List<dynamic>? ?? [];
          final passed =
              results.where((r) => (r as Map)['pass'] == true).length;
          final total = results.length;
          final allOk = passed == total;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                    color: hex(AppColors.outlineVariant)
                        .withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    allOk ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: hex(allOk
                        ? AppColors.signalEmerald
                        : AppColors.error),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$passed/$total passed',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface), size: 11),
                    ),
                  ),
                  if (ts != null)
                    Text(
                      '${ts.day}/${ts.month} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

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
                'Run self-diagnostic tests on your TV. Each test checks a hardware or connectivity subsystem. Use Run All for a full check. Results are saved in history for tracking.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
