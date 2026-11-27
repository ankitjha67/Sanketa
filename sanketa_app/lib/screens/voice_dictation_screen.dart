import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class VoiceDictationScreen extends StatefulWidget {
  const VoiceDictationScreen({super.key});

  @override
  State<VoiceDictationScreen> createState() => _VoiceDictationScreenState();
}

class _VoiceDictationScreenState extends State<VoiceDictationScreen> {
  final _textCtrl = TextEditingController();
  bool _listening = false;
  int _langIndex = 0;

  static const _languages = [
    ('English', 'en-US'),
    ('Hindi', 'hi-IN'),
    ('Spanish', 'es-ES'),
    ('French', 'fr-FR'),
    ('German', 'de-DE'),
    ('Japanese', 'ja-JP'),
  ];

  static const _quickPhrases = [
    'OK Google',
    'Search YouTube',
    'Open Netflix',
    'Play music',
    'What time is it',
    'Turn off in 30 minutes',
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.type(text);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Sent: $text'),
        duration: const Duration(seconds: 1),
      ));
    _textCtrl.clear();
  }

  void _sendQuick(String phrase) {
    HapticFeedback.lightImpact();
    final rc = RemoteScope.of(context);
    rc.type(phrase);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Sent: $phrase'),
        duration: const Duration(seconds: 1),
      ));
  }

  void _toggleListening() {
    setState(() => _listening = !_listening);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Voice Dictation',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _micButton(),
          const SizedBox(height: AppSpacing.md),
          _textInput(),
          const SizedBox(height: AppSpacing.md),
          _languagePicker(),
          const SizedBox(height: AppSpacing.md),
          _quickPhraseSection(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _micButton() => GestureDetector(
        onTap: _toggleListening,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: hex(_listening ? AppColors.primary : AppColors.surfaceContainerLow)
                .withValues(alpha: _listening ? 0.12 : 1),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: hex(_listening ? AppColors.primary : AppColors.outlineVariant)
                  .withValues(alpha: _listening ? 0.4 : 0.15),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: hex(_listening ? AppColors.primary : AppColors.secondary)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _listening ? Icons.mic : Icons.mic_none,
                  size: 36,
                  color: hex(_listening ? AppColors.primary : AppColors.secondary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _listening ? 'Listening...' : 'Tap to Speak',
                style: gfont(AppType.bodyMd,
                    color: hex(_listening ? AppColors.primary : AppColors.onSurface),
                    weight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _listening
                    ? 'Tap again to stop'
                    : 'Dictate text to send to your TV',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 11),
              ),
            ],
          ),
        ),
      );

  Widget _textInput() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manual Input',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'Type or paste text...',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendText,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(Icons.send,
                        size: 18, color: hex(AppColors.primary)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _languagePicker() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Language',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _languages.asMap().entries.map((e) {
                final active = e.key == _langIndex;
                return GestureDetector(
                  onTap: () => setState(() => _langIndex = e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                          .withValues(alpha: active ? 0.15 : 1),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                            .withValues(alpha: active ? 0.5 : 0.2),
                      ),
                    ),
                    child: Text(e.value.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(active ? AppColors.primary : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 10)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _quickPhraseSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Phrases',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._quickPhrases.map((phrase) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: GestureDetector(
                    onTap: () => _sendQuick(phrase),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: hex(AppColors.secondary).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                        border: Border.all(
                            color: hex(AppColors.secondary)
                                .withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.record_voice_over,
                              size: 14, color: hex(AppColors.secondary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(phrase,
                                style: gfont(AppType.bodySm,
                                    color: hex(AppColors.onSurface),
                                    weight: FontWeight.w500,
                                    size: 11)),
                          ),
                          Icon(Icons.send,
                              size: 12, color: hex(AppColors.outline)),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
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
                'Dictate or type text to send directly to your TV. Use quick phrases for common commands. All text stays between your phone and TV.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
