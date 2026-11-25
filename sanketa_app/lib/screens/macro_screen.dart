import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/macro_service.dart';
import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class MacroScreen extends StatefulWidget {
  const MacroScreen({super.key});

  @override
  State<MacroScreen> createState() => _MacroScreenState();
}

class _MacroScreenState extends State<MacroScreen> {
  @override
  Widget build(BuildContext context) {
    final c = RemoteScope.of(context);
    final ms = c.macroService;

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Macros',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: ms.macros.isEmpty ? _empty() : _list(c, ms),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: hex(AppColors.primaryContainer),
        onPressed: () => _showCreateDialog(c),
        child: Icon(Icons.add, color: hex(AppColors.onPrimaryContainer)),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high,
                size: 48,
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('No macros yet',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurfaceVariant))),
            const SizedBox(height: AppSpacing.sm),
            Text('Create sequences of TV commands to run with one tap',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline))),
          ],
        ),
      );

  Widget _list(RemoteController c, MacroService ms) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: ms.macros.length,
      itemBuilder: (_, i) {
        final m = ms.macros[i];
        final running = ms.playingMacroId == m.id;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: panel(
            borderColor: running ? AppColors.primaryContainer : AppColors.outlineVariant,
            borderOpacity: running ? 0.6 : 0.3,
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(AppColors.secondary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: running
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(hex(AppColors.secondary)),
                      ),
                    )
                  : Icon(Icons.auto_fix_high,
                      size: 20, color: hex(AppColors.secondary)),
            ),
            title: Text(m.name,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500)),
            subtitle: Text('${m.steps.length} steps',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (running)
                  IconButton(
                    icon:
                        Icon(Icons.stop, size: 20, color: hex(AppColors.error)),
                    onPressed: ms.stopPlayback,
                  )
                else
                  IconButton(
                    icon: Icon(Icons.play_arrow,
                        size: 20, color: hex(AppColors.primaryContainer)),
                    onPressed: () => _runMacro(c, ms, m),
                  ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: hex(AppColors.outlineVariant)),
                  onPressed: () {
                    ms.deleteMacro(m.id);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runMacro(
      RemoteController c, MacroService ms, Macro macro) async {
    await ms.play(macro, (step) async {
      switch (step.action) {
        case 'key':
          final k = core.Key.values.firstWhere(
            (k) => k.name == step.argument,
            orElse: () => core.Key.ok,
          );
          c.key(k);
        case 'power_on':
          c.power(true);
        case 'power_off':
          c.power(false);
        case 'source':
          if (step.argument != null) c.setSource(step.argument!);
        case 'launch':
          if (step.argument != null) c.launch(step.argument!);
        case 'type':
          if (step.argument != null) c.type(step.argument!);
      }
      setState(() {});
    });
    setState(() {});
  }

  void _showCreateDialog(RemoteController c) {
    final nameCtrl = TextEditingController();
    final steps = <MacroStep>[];

    void addStep(String action, [String? arg]) {
      steps.add(MacroStep(action: action, argument: arg));
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: hex(AppColors.surfaceContainerLow),
          title: Text('New Macro',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface), size: 16)),
          content: SizedBox(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface)),
                    decoration: InputDecoration(
                      hintText: 'Macro name',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outlineVariant)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Steps:',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant))),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i + 1}. ${steps[i].action}${steps[i].argument != null ? ' (${steps[i].argument})' : ''}',
                              style: gfont(AppType.labelMonoSm,
                                  color: hex(AppColors.onSurface)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setDlg(() => steps.removeAt(i)),
                            child: Icon(Icons.close,
                                size: 14,
                                color: hex(AppColors.outlineVariant)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      _stepBtn('Home', () => setDlg(() => addStep('key', 'home'))),
                      _stepBtn('Back', () => setDlg(() => addStep('key', 'back'))),
                      _stepBtn('OK', () => setDlg(() => addStep('key', 'ok'))),
                      _stepBtn('Up', () => setDlg(() => addStep('key', 'up'))),
                      _stepBtn('Down', () => setDlg(() => addStep('key', 'down'))),
                      _stepBtn('Left', () => setDlg(() => addStep('key', 'left'))),
                      _stepBtn('Right', () => setDlg(() => addStep('key', 'right'))),
                      _stepBtn('Vol+', () => setDlg(() => addStep('key', 'volumeUp'))),
                      _stepBtn('Vol-', () => setDlg(() => addStep('key', 'volumeDown'))),
                      _stepBtn('Mute', () => setDlg(() => addStep('key', 'mute'))),
                      _stepBtn('Power On', () => setDlg(() => addStep('power_on'))),
                      _stepBtn('Power Off', () => setDlg(() => addStep('power_off'))),
                      _stepBtn('Netflix', () => setDlg(() => addStep('launch', 'NETFLIX'))),
                      _stepBtn('YouTube', () => setDlg(() => addStep('launch', 'YouTube'))),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel',
                  style:
                      gfont(AppType.bodySm, color: hex(AppColors.outline))),
            ),
            TextButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty && steps.isNotEmpty) {
                  c.macroService.addMacro(Macro(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    steps: steps,
                  ));
                  setState(() {});
                }
                Navigator.of(ctx).pop();
              },
              child: Text('Create',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primaryContainer),
                      weight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainer),
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
          ),
          child: Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurface), size: 11)),
        ),
      );
}
