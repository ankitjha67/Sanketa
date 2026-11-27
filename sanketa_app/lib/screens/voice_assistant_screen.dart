import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  bool _enabled = true;
  int _assistantIdx = 0;
  bool _wakeWord = true;
  bool _soundFeedback = true;

  static const _assistants = <(String, IconData, int)>[
    ('Google', Icons.assistant, AppColors.primary),
    ('Alexa', Icons.smart_display, AppColors.secondary),
    ('Bixby', Icons.memory, AppColors.tertiary),
    ('Siri', Icons.mic, AppColors.signalEmerald),
  ];

  static const _commands = <(String, IconData, String)>[
    ('Volume up', Icons.volume_up, 'Increase volume by 10'),
    ('Volume down', Icons.volume_down, 'Decrease volume by 10'),
    ('Mute', Icons.volume_off, 'Toggle mute'),
    ('Channel up', Icons.keyboard_arrow_up, 'Next channel'),
    ('Power off', Icons.power_settings_new, 'Turn off TV'),
    ('Open Netflix', Icons.play_circle, 'Launch Netflix'),
    ('Search', Icons.search, 'Open search'),
    ('Go home', Icons.home, 'Return to home screen'),
  ];

  void _sendTest(int idx) {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    final keys = [
      core.Key.volumeUp,
      core.Key.volumeDown,
      core.Key.mute,
      core.Key.up,
      core.Key.power,
      core.Key.ok,
      core.Key.menu,
      core.Key.home,
    ];
    rc.key(keys[idx]);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Sent: ${_commands[idx].$1}'),
        duration: const Duration(seconds: 1),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final a = _assistants[_assistantIdx];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Voice Assistant',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(a),
          const SizedBox(height: AppSpacing.md),
          _assistantPicker(),
          const SizedBox(height: AppSpacing.md),
          _settingsSection(),
          const SizedBox(height: AppSpacing.md),
          _commandsList(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard((String, IconData, int) a) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(a.$3).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(a.$3).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(a.$2, size: 44, color: hex(a.$3)),
            const SizedBox(height: 8),
            Text(a.$1,
                style: gfont(AppType.bodyMd,
                    color: hex(a.$3), weight: FontWeight.w700, size: 16)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hex(_enabled ? AppColors.signalEmerald : AppColors.outline)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
              child: Text(_enabled ? 'ENABLED' : 'DISABLED',
                  style: gfont(AppType.bodySm,
                      color: hex(_enabled ? AppColors.signalEmerald : AppColors.outline),
                      weight: FontWeight.w700,
                      size: 9)),
            ),
          ],
        ),
      );

  Widget _assistantPicker() => Row(
        children: _assistants.asMap().entries.map((e) {
          final a = e.value;
          final active = e.key == _assistantIdx;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _assistantIdx = e.key),
              child: Container(
                margin: EdgeInsets.only(right: e.key < 3 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(active ? a.$3 : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.12 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: hex(active ? a.$3 : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(a.$2,
                        size: 20,
                        color: hex(active ? a.$3 : AppColors.outline)),
                    const SizedBox(height: 2),
                    Text(a.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(active ? a.$3 : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 9)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _settingsSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            _toggleRow('Voice Assistant', Icons.mic, _enabled, (v) {
              setState(() => _enabled = v);
            }),
            _toggleRow('Wake Word Detection', Icons.hearing, _wakeWord, (v) {
              setState(() => _wakeWord = v);
            }),
            _toggleRow('Sound Feedback', Icons.volume_up, _soundFeedback, (v) {
              setState(() => _soundFeedback = v);
            }),
          ],
        ),
      );

  Widget _toggleRow(
          String label, IconData icon, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(
          onTap: () => onChanged(!value),
          child: Row(
            children: [
              Icon(icon, size: 16, color: hex(AppColors.outline)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface), size: 11)),
              ),
              Container(
                width: 36,
                height: 20,
                decoration: BoxDecoration(
                  color: hex(value ? AppColors.signalEmerald : AppColors.outlineVariant)
                      .withValues(alpha: value ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: hex(value ? AppColors.signalEmerald : AppColors.outline),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _commandsList() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Voice Commands',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._commands.asMap().entries.map((e) {
            final c = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => _sendTest(e.key),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                    border: Border.all(
                        color: hex(AppColors.outlineVariant)
                            .withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(c.$2,
                          size: 18, color: hex(AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('"${c.$1}"',
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w600,
                                    size: 11)),
                            Text(c.$3,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.outline), size: 9)),
                          ],
                        ),
                      ),
                      Icon(Icons.play_circle_outline,
                          size: 18, color: hex(AppColors.primary)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
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
                'Configure voice assistant for TV control. Choose your assistant, enable wake word, and test voice commands. Tap any command to send it. All commands sent locally via IR/IP.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
