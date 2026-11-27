import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class QuickTranslateScreen extends StatefulWidget {
  const QuickTranslateScreen({super.key});

  @override
  State<QuickTranslateScreen> createState() => _QuickTranslateScreenState();
}

class _QuickTranslateScreenState extends State<QuickTranslateScreen> {
  final _inputCtrl = TextEditingController();
  String _result = '';
  int _fromIdx = 0;
  int _toIdx = 1;

  static const _languages = <(String, String, int)>[
    ('English', 'en', AppColors.primary),
    ('Hindi', 'hi', AppColors.secondary),
    ('Spanish', 'es', AppColors.tertiary),
    ('French', 'fr', AppColors.error),
    ('German', 'de', AppColors.signalEmerald),
    ('Japanese', 'ja', AppColors.alertAmber),
    ('Korean', 'ko', AppColors.outline),
    ('Chinese', 'zh', AppColors.outlineVariant),
  ];

  static const _quickPhrases = <(String, String)>[
    ('Play', 'Common TV action'),
    ('Pause', 'Pause playback'),
    ('Next episode', 'Continue watching'),
    ('Volume up', 'Increase volume'),
    ('Search', 'Find content'),
    ('Settings', 'Open settings'),
    ('Subtitles on', 'Enable subs'),
    ('Go back', 'Navigate back'),
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _translate() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final toLang = _languages[_toIdx].$1;
    setState(() {
      _result = '[$toLang] $text';
    });
    HapticFeedback.mediumImpact();
  }

  void _sendToTv() {
    if (_result.isEmpty) return;
    final rc = RemoteScope.of(context);
    final cleanText = _result.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
    rc.type(cleanText);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Sent to TV: $cleanText'),
        duration: const Duration(seconds: 2),
      ));
  }

  void _swapLanguages() {
    setState(() {
      final tmp = _fromIdx;
      _fromIdx = _toIdx;
      _toIdx = tmp;
      _result = '';
    });
    HapticFeedback.selectionClick();
  }

  void _useQuickPhrase(String phrase) {
    _inputCtrl.text = phrase;
    _translate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Quick Translate',
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
          _languageSelector(),
          const SizedBox(height: AppSpacing.md),
          _inputField(),
          const SizedBox(height: AppSpacing.md),
          _translateButton(),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _resultCard(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _quickPhrasesSection(),
          const SizedBox(height: AppSpacing.lg),
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
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.translate,
                size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Translate & Send',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Translate text and send it directly to your TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _languageSelector() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(child: _langChip(_fromIdx, true)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _swapLanguages,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.swap_horiz,
                    size: 20, color: hex(AppColors.primary)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _langChip(_toIdx, false)),
          ],
        ),
      );

  Widget _langChip(int idx, bool isFrom) => GestureDetector(
        onTap: () => _showLangPicker(isFrom),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: hex(_languages[idx].$3).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(_languages[idx].$3).withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(isFrom ? 'From' : 'To',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 9)),
              const SizedBox(height: 2),
              Text(_languages[idx].$1,
                  style: gfont(AppType.bodyMd,
                      color: hex(_languages[idx].$3),
                      weight: FontWeight.w600,
                      size: 13)),
            ],
          ),
        ),
      );

  void _showLangPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: hex(AppColors.surfaceContainerLow),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isFrom ? 'Translate From' : 'Translate To',
                style: gfont(AppType.headlineMd,
                    color: hex(AppColors.onSurface),
                    size: 16,
                    weight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.asMap().entries.map((e) {
                final current = isFrom ? _fromIdx : _toIdx;
                final active = e.key == current;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isFrom) {
                        _fromIdx = e.key;
                      } else {
                        _toIdx = e.key;
                      }
                      _result = '';
                    });
                    Navigator.pop(ctx);
                    HapticFeedback.selectionClick();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: hex(e.value.$3)
                          .withValues(alpha: active ? 0.15 : 0.05),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      border: Border.all(
                        color: hex(e.value.$3)
                            .withValues(alpha: active ? 0.4 : 0.15),
                      ),
                    ),
                    child: Text(e.value.$1,
                        style: gfont(AppType.bodySm,
                            color: hex(e.value.$3),
                            weight:
                                active ? FontWeight.w600 : FontWeight.w400,
                            size: 12)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _inputField() => TextField(
        controller: _inputCtrl,
        maxLines: 3,
        style: gfont(AppType.bodyMd,
            color: hex(AppColors.onSurface), size: 14),
        decoration: InputDecoration(
          hintText: 'Type text to translate...',
          hintStyle: gfont(AppType.bodySm,
              color: hex(AppColors.outline), size: 13),
          filled: true,
          fillColor: hex(AppColors.surfaceContainerLow),
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
        onSubmitted: (_) => _translate(),
      );

  Widget _translateButton() => GestureDetector(
        onTap: _translate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.translate, size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Translate',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _resultCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle,
                    size: 16, color: hex(AppColors.signalEmerald)),
                const SizedBox(width: 6),
                Text('Translation',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 10)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_result,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500,
                    size: 15)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _sendToTv,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, size: 16, color: hex(AppColors.signalEmerald)),
                    const SizedBox(width: 6),
                    Text('Send to TV',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.signalEmerald),
                            weight: FontWeight.w600,
                            size: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _quickPhrasesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Phrases',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 13)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickPhrases.map((p) {
              return GestureDetector(
                onTap: () => _useQuickPhrase(p.$1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                        color: hex(AppColors.outlineVariant)
                            .withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(p.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.onSurface),
                              weight: FontWeight.w500,
                              size: 11)),
                      Text(p.$2,
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 8)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
                'Translate text between languages and send directly to your TV. '
                'Use quick phrases for common TV commands. All processing is local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
