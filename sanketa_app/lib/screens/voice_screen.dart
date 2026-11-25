import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../control/voice_service.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final _voice = VoiceService();

  @override
  void initState() {
    super.initState();
    _voice.checkAvailability();
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hex(AppColors.onSurface)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Voice to TV',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 16,
                weight: FontWeight.w600)),
      ),
      body: ListenableBuilder(
        listenable: _voice,
        builder: (_, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: _voice.isAvailable ? _activeView() : _unavailableView(),
          ),
        ),
      ),
    );
  }

  Widget _unavailableView() => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic_off,
                  size: 40, color: hex(AppColors.outlineVariant)),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Speech Recognition Not Available',
                textAlign: TextAlign.center,
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 18,
                    weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Voice-to-TV requires the speech recognition plugin.\n'
              'This feature will be available in a future update.',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.onSurfaceVariant)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: panel(
                  fill: AppColors.surfaceContainerLowest,
                  borderOpacity: 0.2),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 18, color: hex(AppColors.signalEmerald)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Audio stays on your phone — only the recognized '
                      'text is sent to your TV.',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.onSurfaceVariant), size: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _activeView() {
    final c = RemoteScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (_voice.isListening) {
                _voice.stopListening();
              } else {
                _voice.startListening();
              }
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: hex(_voice.isListening
                        ? AppColors.error
                        : AppColors.primaryContainer)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hex(_voice.isListening
                          ? AppColors.error
                          : AppColors.primaryContainer)
                      .withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                _voice.isListening ? Icons.stop : Icons.mic,
                size: 48,
                color: hex(_voice.isListening
                    ? AppColors.error
                    : AppColors.primaryContainer),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _voice.isListening ? 'Listening...' : 'Tap to speak',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_voice.transcript.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: panel(fill: AppColors.surfaceContainerLowest),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recognized text',
                      style: gfont(AppType.labelMonoSm,
                          color: hex(AppColors.outline), size: 10)),
                  const SizedBox(height: 4),
                  Text(_voice.transcript,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface))),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _btn('Send to TV', AppColors.primaryContainer, () {
                    c.type(_voice.transcript);
                    c.submit();
                    _voice.clear();
                  }),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _btn('Clear', AppColors.outlineVariant, () {
                    _voice.clear();
                  }),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration:
                panel(fill: AppColors.surfaceContainerLowest, borderOpacity: 0.2),
            child: Row(
              children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: hex(AppColors.signalEmerald)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Audio stays on your phone — only the recognized '
                    'text is sent to your TV.',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurfaceVariant), size: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(String label, int color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(color).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(color).withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(label,
                style: gfont(AppType.bodyMd,
                    color: hex(color), weight: FontWeight.w600)),
          ),
        ),
      );
}
