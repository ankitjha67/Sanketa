import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';
import 'dart:io';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvInputManagerScreen extends StatefulWidget {
  const TvInputManagerScreen({super.key});

  @override
  State<TvInputManagerScreen> createState() => _TvInputManagerScreenState();
}

class _TvInputManagerScreenState extends State<TvInputManagerScreen> {
  final List<_Input> _inputs = [
    _Input('HDMI 1', 'hdmi1', Icons.settings_input_hdmi, 'PlayStation 5', true),
    _Input('HDMI 2', 'hdmi2', Icons.settings_input_hdmi, 'Apple TV', true),
    _Input('HDMI 3', 'hdmi3', Icons.settings_input_hdmi, 'Sound Bar', true),
    _Input('HDMI 4', 'hdmi4', Icons.settings_input_hdmi, '', false),
    _Input('USB', 'usb', Icons.usb, 'Flash Drive', true),
    _Input('AV', 'av', Icons.settings_input_composite, '', false),
    _Input('Antenna', 'antenna', Icons.settings_input_antenna, 'Cable TV', true),
  ];

  int _activeInput = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/tv_inputs.json');
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final list = data['inputs'] as List<dynamic>? ?? [];
        setState(() {
          _activeInput = data['active'] as int? ?? 0;
          _inputs.clear();
          for (final i in list) {
            final m = i as Map<String, dynamic>;
            _inputs.add(_Input(
              m['name'] as String? ?? '',
              m['id'] as String? ?? '',
              _iconForId(m['id'] as String? ?? ''),
              m['label'] as String? ?? '',
              m['enabled'] as bool? ?? true,
            ));
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/tv_inputs.json');
      await f.writeAsString(jsonEncode({
        'active': _activeInput,
        'inputs': _inputs
            .map((i) => {
                  'name': i.name,
                  'id': i.inputId,
                  'label': i.label,
                  'enabled': i.enabled,
                })
            .toList(),
      }));
    } catch (_) {}
  }

  static IconData _iconForId(String id) {
    if (id.startsWith('hdmi')) return Icons.settings_input_hdmi;
    if (id == 'usb') return Icons.usb;
    if (id == 'av') return Icons.settings_input_composite;
    if (id == 'antenna') return Icons.settings_input_antenna;
    return Icons.input;
  }

  void _switchInput(int idx) {
    final rc = RemoteScope.of(context);
    rc.launch('input:${_inputs[idx].inputId}');
    setState(() => _activeInput = idx);
    _save();
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Switched to ${_inputs[idx].name}'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _toggleEnabled(int idx) {
    setState(() => _inputs[idx].enabled = !_inputs[idx].enabled);
    _save();
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final enabledInputs = _inputs.where((i) => i.enabled).toList();
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Input Manager',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _currentInput(),
          const SizedBox(height: AppSpacing.lg),
          Text('Quick Switch',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          _quickSwitchGrid(enabledInputs),
          const SizedBox(height: AppSpacing.lg),
          Text('All Inputs',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: 8),
          ..._inputs.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _inputTile(e.key, e.value),
              )),
          const SizedBox(height: AppSpacing.md),
          _infoCard(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.input, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('HDMI & Input Manager',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Switch inputs, label devices, hide unused ports',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _currentInput() {
    final cur =
        _activeInput >= 0 && _activeInput < _inputs.length
            ? _inputs[_activeInput]
            : null;
    if (cur == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(cur.icon, size: 28, color: hex(AppColors.signalEmerald)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active: ${cur.name}',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 14)),
                if (cur.label.isNotEmpty)
                  Text(cur.label,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface), size: 11)),
              ],
            ),
          ),
          Icon(Icons.check_circle,
              size: 22, color: hex(AppColors.signalEmerald)),
        ],
      ),
    );
  }

  Widget _quickSwitchGrid(List<_Input> inputs) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: inputs.map((inp) {
          final idx = _inputs.indexOf(inp);
          final active = idx == _activeInput;
          return GestureDetector(
            onTap: () => _switchInput(idx),
            child: Container(
              width: 90,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: hex(active
                        ? AppColors.signalEmerald
                        : AppColors.surfaceContainerLow)
                    .withValues(alpha: active ? 0.12 : 1),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                    color: hex(active
                            ? AppColors.signalEmerald
                            : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.4 : 0.2)),
              ),
              child: Column(
                children: [
                  Icon(inp.icon,
                      size: 22,
                      color: hex(active
                          ? AppColors.signalEmerald
                          : AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text(inp.name,
                      textAlign: TextAlign.center,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurface),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 10)),
                  if (inp.label.isNotEmpty)
                    Text(inp.label,
                        textAlign: TextAlign.center,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 8)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _inputTile(int idx, _Input inp) {
    final active = idx == _activeInput;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(active
                ? AppColors.signalEmerald
                : AppColors.surfaceContainerLow)
            .withValues(alpha: active ? 0.06 : 1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
            color: hex(active
                    ? AppColors.signalEmerald
                    : AppColors.outlineVariant)
                .withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(inp.icon, size: 22, color: hex(AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inp.name,
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 13)),
                if (inp.label.isNotEmpty)
                  Text(inp.label,
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ),
          if (active)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:
                    hex(AppColors.signalEmerald).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text('Active',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.signalEmerald),
                      weight: FontWeight.w600,
                      size: 9)),
            ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _toggleEnabled(idx),
            child: Icon(
              inp.enabled ? Icons.visibility : Icons.visibility_off,
              size: 20,
              color: hex(
                  inp.enabled ? AppColors.onSurface : AppColors.outlineVariant),
            ),
          ),
        ],
      ),
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
                'Manage HDMI and other inputs. Label devices, hide unused ports, '
                'and quick-switch between inputs. All data stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Input {
  String name;
  String inputId;
  IconData icon;
  String label;
  bool enabled;
  _Input(this.name, this.inputId, this.icon, this.label, this.enabled);
}
