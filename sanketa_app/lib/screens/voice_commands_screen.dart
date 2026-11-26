import 'package:flutter/material.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class VoiceCommandsScreen extends StatefulWidget {
  const VoiceCommandsScreen({super.key});

  @override
  State<VoiceCommandsScreen> createState() => _VoiceCommandsScreenState();
}

class _VoiceCommandsScreenState extends State<VoiceCommandsScreen> {
  bool _listening = false;
  int _categoryIndex = 0;

  static const _categories = [
    'All',
    'Navigation',
    'Media',
    'Apps',
    'System',
    'Custom',
  ];

  static const _commands = [
    ('Go home', 'Navigate to the home screen', 'Navigation', Icons.home),
    ('Go back', 'Return to previous screen', 'Navigation', Icons.arrow_back),
    ('Open settings', 'Open TV settings menu', 'Navigation', Icons.settings),
    ('Scroll down', 'Scroll the current page down', 'Navigation', Icons.arrow_downward),
    ('Play', 'Resume playback', 'Media', Icons.play_arrow),
    ('Pause', 'Pause playback', 'Media', Icons.pause),
    ('Next episode', 'Skip to next episode', 'Media', Icons.skip_next),
    ('Volume up', 'Increase volume by 10%', 'Media', Icons.volume_up),
    ('Volume down', 'Decrease volume by 10%', 'Media', Icons.volume_down),
    ('Mute', 'Toggle mute on/off', 'Media', Icons.volume_off),
    ('Open YouTube', 'Launch YouTube app', 'Apps', Icons.play_circle),
    ('Open Netflix', 'Launch Netflix app', 'Apps', Icons.movie),
    ('Open Spotify', 'Launch Spotify app', 'Apps', Icons.music_note),
    ('Power off', 'Turn off the TV', 'System', Icons.power_settings_new),
    ('Sleep timer 30 minutes', 'Set sleep timer', 'System', Icons.bedtime),
    ('Take screenshot', 'Capture TV screen', 'System', Icons.screenshot),
    ('Switch to HDMI 1', 'Change input source', 'System', Icons.input),
  ];

  List<(String, String, String, IconData)> get _filtered {
    if (_categoryIndex == 0) return _commands;
    final cat = _categories[_categoryIndex];
    return _commands.where((c) => c.$3 == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Voice Commands',
            style: gfont(AppType.headlineMd, color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _micButton(),
                const SizedBox(height: AppSpacing.md),
                _categoryBar(),
                const SizedBox(height: AppSpacing.md),
                Text('${_filtered.length} Commands',
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                const SizedBox(height: 8),
                ..._filtered.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _commandCard(c),
                )),
                const SizedBox(height: AppSpacing.md),
                _infoCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _micButton() => GestureDetector(
    onTap: () => setState(() => _listening = !_listening),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: hex(_listening ? AppColors.error : AppColors.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: hex(_listening ? AppColors.error : AppColors.primary).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: hex(_listening ? AppColors.error : AppColors.primary).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _listening ? Icons.mic : Icons.mic_none,
              size: 36,
              color: hex(_listening ? AppColors.error : AppColors.primary),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _listening ? 'Listening...' : 'Tap to speak',
            style: gfont(AppType.bodyMd,
                color: hex(_listening ? AppColors.error : AppColors.primary), weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _listening ? 'Say a command or tap to stop' : 'Or tap a command below to execute it',
            style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
          ),
        ],
      ),
    ),
  );

  Widget _categoryBar() => SizedBox(
    height: 32,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 6),
      itemBuilder: (_, i) {
        final active = i == _categoryIndex;
        return GestureDetector(
          onTap: () => setState(() => _categoryIndex = i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                  .withValues(alpha: active ? 0.15 : 1),
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(
                color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                    .withValues(alpha: active ? 0.5 : 0.2),
              ),
            ),
            child: Center(
              child: Text(_categories[i],
                  style: gfont(AppType.bodySm,
                      color: hex(active ? AppColors.primary : AppColors.onSurface),
                      weight: active ? FontWeight.w600 : FontWeight.w400, size: 11)),
            ),
          ),
        );
      },
    ),
  );

  void _executeCommand(String command) {
    final rc = RemoteScope.of(context);
    switch (command) {
      case 'Go home':
        rc.key(core.Key.home);
      case 'Go back':
        rc.key(core.Key.back);
      case 'Open settings':
        rc.key(core.Key.menu);
      case 'Scroll down':
        rc.key(core.Key.down);
        rc.key(core.Key.down);
        rc.key(core.Key.down);
      case 'Play':
        rc.key(core.Key.play);
      case 'Pause':
        rc.key(core.Key.pause);
      case 'Next episode':
        rc.key(core.Key.next);
      case 'Volume up':
        rc.key(core.Key.volumeUp);
        rc.key(core.Key.volumeUp);
      case 'Volume down':
        rc.key(core.Key.volumeDown);
        rc.key(core.Key.volumeDown);
      case 'Mute':
        rc.key(core.Key.mute);
      case 'Open YouTube':
        rc.launch('YouTube');
      case 'Open Netflix':
        rc.launch('Netflix');
      case 'Open Spotify':
        rc.launch('Spotify');
      case 'Power off':
        rc.key(core.Key.power);
      case 'Sleep timer 30 minutes':
        rc.key(core.Key.power);
      case 'Take screenshot':
        rc.key(core.Key.info);
      case 'Switch to HDMI 1':
        rc.key(core.Key.input);
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Sent: "$command"'),
        duration: const Duration(seconds: 1),
      ));
  }

  Widget _commandCard((String, String, String, IconData) cmd) => GestureDetector(
    onTap: () => _executeCommand(cmd.$1),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(cmd.$4, size: 16, color: hex(AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('"${cmd.$1}"',
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 12)),
                Text(cmd.$2,
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: hex(AppColors.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: Text(cmd.$3,
                style: gfont(AppType.labelMonoSm, color: hex(AppColors.primary), size: 8, weight: FontWeight.w600)),
          ),
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
            'Control your TV with voice commands. Tap the mic to speak, or tap any command to execute it instantly. Voice data is processed on-device.',
            style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
          ),
        ),
      ],
    ),
  );
}
