import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class MacroRunnerScreen extends StatefulWidget {
  const MacroRunnerScreen({super.key});

  @override
  State<MacroRunnerScreen> createState() => _MacroRunnerScreenState();
}

class _MacroRunnerScreenState extends State<MacroRunnerScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final _favourites = <int>{};
  int _runningIdx = -1;

  static const _macros = <({String name, String desc, IconData icon, int color, List<(String, core.Key)> steps})>[
    (
      name: 'Quick Mute Cycle',
      desc: 'Mute, wait, unmute — test audio path',
      icon: Icons.volume_off,
      color: AppColors.error,
      steps: [
        ('Mute TV', core.Key.mute),
        ('Wait', core.Key.ok),
        ('Unmute TV', core.Key.mute),
      ],
    ),
    (
      name: 'Volume Ramp',
      desc: 'Gradually increase volume in 5 steps',
      icon: Icons.volume_up,
      color: AppColors.primary,
      steps: [
        ('Volume +1', core.Key.volumeUp),
        ('Volume +2', core.Key.volumeUp),
        ('Volume +3', core.Key.volumeUp),
        ('Volume +4', core.Key.volumeUp),
        ('Volume +5', core.Key.volumeUp),
      ],
    ),
    (
      name: 'Input Sweep',
      desc: 'Cycle through TV inputs via menu',
      icon: Icons.input,
      color: AppColors.secondary,
      steps: [
        ('Open menu', core.Key.menu),
        ('Navigate down', core.Key.down),
        ('Navigate down', core.Key.down),
        ('Select', core.Key.ok),
      ],
    ),
    (
      name: 'Navigation Dance',
      desc: 'Test all D-pad directions',
      icon: Icons.gamepad,
      color: AppColors.tertiary,
      steps: [
        ('Up', core.Key.up),
        ('Right', core.Key.right),
        ('Down', core.Key.down),
        ('Left', core.Key.left),
        ('Centre OK', core.Key.ok),
      ],
    ),
    (
      name: 'Sleep Prep',
      desc: 'Lower volume and open power menu',
      icon: Icons.bedtime,
      color: AppColors.alertAmber,
      steps: [
        ('Vol down', core.Key.volumeDown),
        ('Vol down', core.Key.volumeDown),
        ('Vol down', core.Key.volumeDown),
        ('Open menu', core.Key.menu),
      ],
    ),
    (
      name: 'Home Reset',
      desc: 'Go home and clear navigation stack',
      icon: Icons.home,
      color: AppColors.signalEmerald,
      steps: [
        ('Back', core.Key.back),
        ('Back', core.Key.back),
        ('Home', core.Key.home),
      ],
    ),
    (
      name: 'Channel Surf',
      desc: 'Quick flip through 3 channels',
      icon: Icons.tv,
      color: AppColors.primary,
      steps: [
        ('Channel up', core.Key.up),
        ('Wait', core.Key.ok),
        ('Channel up', core.Key.up),
        ('Wait', core.Key.ok),
        ('Channel up', core.Key.up),
      ],
    ),
    (
      name: 'Power Cycle',
      desc: 'Power off, wait, power on',
      icon: Icons.power_settings_new,
      color: AppColors.error,
      steps: [
        ('Power off', core.Key.power),
        ('Wait', core.Key.ok),
        ('Power on', core.Key.power),
      ],
    ),
  ];

  void _toggleFav(int idx) {
    setState(() {
      if (_favourites.contains(idx)) {
        _favourites.remove(idx);
      } else {
        _favourites.add(idx);
      }
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _runMacro(int idx) async {
    if (_runningIdx >= 0) return;
    setState(() => _runningIdx = idx);
    HapticFeedback.mediumImpact();
    final rc = RemoteScope.of(context);
    final steps = _macros[idx].steps;
    for (var i = 0; i < steps.length; i++) {
      if (!mounted) break;
      rc.key(steps[i].$2);
      if (i < steps.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    if (mounted) {
      setState(() => _runningIdx = -1);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('${_macros[idx].name} completed'),
          duration: const Duration(seconds: 2),
        ));
    }
  }

  List<int> get _filteredIndices {
    final q = _query.toLowerCase();
    return List.generate(_macros.length, (i) => i).where((i) {
      if (q.isEmpty) return true;
      return _macros[i].name.toLowerCase().contains(q) ||
          _macros[i].desc.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Macro Runner',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.lg),
          _statsRow(),
          const SizedBox(height: AppSpacing.md),
          _searchBar(),
          const SizedBox(height: AppSpacing.lg),
          Text('Preset Macros',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._filteredIndices.map(_macroCard),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.play_circle_outline,
                size: 48, color: hex(AppColors.tertiary)),
            const SizedBox(height: 8),
            Text('Gesture Macros',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.tertiary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Browse and run pre-made multi-step remote macros with one tap',
              textAlign: TextAlign.center,
              style:
                  gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _statsRow() => Row(
        children: [
          _statBadge('${_macros.length}', 'Macros', AppColors.primary),
          const SizedBox(width: 8),
          _statBadge('${_favourites.length}', 'Favourites', AppColors.alertAmber),
          const SizedBox(width: 8),
          _statBadge(
              _runningIdx >= 0 ? 'Running' : 'Idle', 'Status',
              _runningIdx >= 0 ? AppColors.signalEmerald : AppColors.outline),
        ],
      );

  Widget _statBadge(String value, String label, int color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: hex(color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(color).withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: gfont(AppType.bodySm,
                      color: hex(color), weight: FontWeight.w700, size: 11)),
              const SizedBox(height: 2),
              Text(label,
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
      );

  Widget _searchBar() => TextField(
        controller: _searchCtrl,
        style: gfont(AppType.bodySm,
            color: hex(AppColors.onSurface), size: 13),
        decoration: InputDecoration(
          hintText: 'Search macros...',
          hintStyle:
              gfont(AppType.bodySm, color: hex(AppColors.outline), size: 13),
          prefixIcon:
              Icon(Icons.search, color: hex(AppColors.outline), size: 20),
          filled: true,
          fillColor: hex(AppColors.surfaceContainerLow),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: BorderSide.none,
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (v) => setState(() => _query = v),
      );

  Widget _macroCard(int idx) {
    final m = _macros[idx];
    final isFav = _favourites.contains(idx);
    final isRunning = _runningIdx == idx;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(isRunning ? AppColors.signalEmerald : AppColors.outlineVariant)
                  .withValues(alpha: isRunning ? 0.4 : 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hex(m.color).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(m.icon, color: hex(m.color), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w600,
                              size: 13)),
                      Text(m.desc,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 11)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleFav(idx),
                  child: Icon(
                    isFav ? Icons.star : Icons.star_border,
                    color:
                        hex(isFav ? AppColors.alertAmber : AppColors.outline),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: m.steps.asMap().entries.map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        hex(AppColors.outlineVariant).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text('${e.key + 1}. ${e.value.$1}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _runningIdx < 0 ? () => _runMacro(idx) : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(isRunning
                          ? AppColors.signalEmerald
                          : AppColors.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isRunning)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: hex(AppColors.signalEmerald)),
                        ),
                      ),
                    Text(
                      isRunning
                          ? 'Running...'
                          : 'Run (${m.steps.length} steps)',
                      style: gfont(AppType.bodySm,
                          color: hex(isRunning
                              ? AppColors.signalEmerald
                              : AppColors.primary),
                          weight: FontWeight.w600,
                          size: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: hex(AppColors.outline), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Each macro sends its steps to your TV with a short delay between them. All commands run locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11),
              ),
            ),
          ],
        ),
      );
}
