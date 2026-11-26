import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvDictionaryScreen extends StatefulWidget {
  const TvDictionaryScreen({super.key});

  @override
  State<TvDictionaryScreen> createState() => _TvDictionaryScreenState();
}

class _TvDictionaryScreenState extends State<TvDictionaryScreen> {
  final _ctrl = TextEditingController();
  String _result = '';
  String _word = '';

  static const _sampleDefs = <String, (String, String, String)>{
    'remote': ('noun', '/rɪˈmoʊt/', 'A device for controlling a TV or other appliance from a distance.'),
    'stream': ('verb', '/striːm/', 'To transmit or receive data, especially video and audio, in a continuous flow.'),
    'channel': ('noun', '/ˈtʃæn.əl/', 'A band of frequencies used for broadcasting television signals.'),
    'resolution': ('noun', '/ˌrez.əˈluː.ʃən/', 'The number of pixels displayed on a screen, determining image clarity.'),
    'codec': ('noun', '/ˈkoʊ.dɛk/', 'A device or program that compresses and decompresses digital media.'),
    'buffer': ('verb', '/ˈbʌf.ər/', 'To temporarily store data while it is being transferred or processed.'),
    'subtitle': ('noun', '/ˈsʌb.taɪ.tl/', 'Text displayed at the bottom of a screen translating or transcribing dialogue.'),
    'hdmi': ('noun', '/eɪtʃ.diː.ɛm.aɪ/', 'High-Definition Multimedia Interface; a standard for transmitting audio and video.'),
    'casting': ('noun', '/ˈkæs.tɪŋ/', 'The process of sending media content wirelessly to a display device.'),
    'firmware': ('noun', '/ˈfɜːrm.wɛr/', 'Permanent software programmed into a device\'s read-only memory.'),
  };

  void _lookup() {
    final w = _ctrl.text.trim().toLowerCase();
    if (w.isEmpty) return;
    final def = _sampleDefs[w];
    setState(() {
      _word = w;
      if (def != null) {
        _result = '${def.$1}  ${def.$2}\n\n${def.$3}';
      } else {
        _result = 'No definition found for "$w". Try: ${_sampleDefs.keys.take(5).join(', ')}';
      }
    });
  }

  void _sendToTv() {
    if (_word.isEmpty) return;
    final rc = RemoteScope.of(context);
    rc.type(_word);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Sent "$_word" to TV search'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
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
        title: Text('TV Dictionary',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _searchBar(),
          const SizedBox(height: AppSpacing.md),
          if (_result.isNotEmpty) ...[
            _resultCard(),
            const SizedBox(height: AppSpacing.md),
          ],
          _sampleWords(),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.menu_book, size: 36, color: hex(AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Lookup',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary), weight: FontWeight.w600)),
                  Text('Look up words while watching TV',
                      style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _searchBar() => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 14),
              decoration: InputDecoration(
                hintText: 'Type a word...',
                hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 12),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => _lookup(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _lookup,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hex(AppColors.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(Icons.search, size: 22, color: hex(AppColors.primary)),
            ),
          ),
        ],
      );

  Widget _resultCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_word,
                      style: gfont(AppType.headlineMd,
                          color: hex(AppColors.primary), size: 20, weight: FontWeight.w700)),
                ),
                GestureDetector(
                  onTap: _sendToTv,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tv, size: 14, color: hex(AppColors.signalEmerald)),
                        const SizedBox(width: 4),
                        Text('TV',
                            style: gfont(AppType.bodySm,
                                color: hex(AppColors.signalEmerald), size: 10, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_result,
                style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 13)),
          ],
        ),
      );

  Widget _sampleWords() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Try These',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sampleDefs.keys.map((w) => GestureDetector(
                  onTap: () {
                    _ctrl.text = w;
                    _lookup();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: hex(AppColors.surfaceContainerHigh),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.2)),
                    ),
                    child: Text(w,
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.onSurface), size: 11, weight: FontWeight.w500)),
                  ),
                )).toList(),
          ),
        ],
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
                'Quick dictionary lookup while watching TV. Tap "TV" to send a word to your TV search. All lookups are offline — no data leaves your phone.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
