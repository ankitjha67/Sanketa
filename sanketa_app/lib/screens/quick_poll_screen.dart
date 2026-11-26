import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class QuickPollScreen extends StatefulWidget {
  const QuickPollScreen({super.key});

  @override
  State<QuickPollScreen> createState() => _QuickPollScreenState();
}

class _QuickPollScreenState extends State<QuickPollScreen> {
  final _questionCtrl = TextEditingController();
  String _question = '';
  final _options = <(String, int)>[];
  bool _revealed = false;
  bool _loading = true;

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.alertAmber,
    AppColors.error,
    AppColors.signalEmerald,
    AppColors.tertiary,
  ];

  static const _quickPolls = <(String, List<String>)>[
    ('Pizza or tacos?', ['Pizza', 'Tacos']),
    ('Movie or TV show?', ['Movie', 'TV Show']),
    ('Coffee or tea?', ['Coffee', 'Tea']),
    ('Dog or cat?', ['Dog', 'Cat']),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/quick_poll.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final d = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        _question = d['question'] as String? ?? '';
        _revealed = d['revealed'] as bool? ?? false;
        final list = d['options'] as List?;
        if (list != null) {
          _options.clear();
          for (final j in list) {
            final m = j as Map<String, dynamic>;
            _options.add((m['text'] as String, m['votes'] as int));
          }
        }
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'question': _question,
      'revealed': _revealed,
      'options': _options.map((o) => {'text': o.$1, 'votes': o.$2}).toList(),
    }));
  }

  void _createPoll(String q, List<String> opts) {
    setState(() {
      _question = q;
      _options.clear();
      _options.addAll(opts.map((o) => (o, 0)));
      _revealed = false;
    });
    _questionCtrl.clear();
    _save();
  }

  void _vote(int i) {
    if (_revealed) return;
    setState(() {
      final o = _options[i];
      _options[i] = (o.$1, o.$2 + 1);
    });
    _save();
  }

  void _reveal() {
    setState(() => _revealed = true);
    _save();
  }

  void _reset() {
    setState(() {
      _question = '';
      _options.clear();
      _revealed = false;
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Quick Poll',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          if (_question.isNotEmpty)
            GestureDetector(
              onTap: _reset,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.refresh, size: 20, color: hex(AppColors.error)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_question.isEmpty) ...[
            _heroCard(),
            const SizedBox(height: AppSpacing.md),
            _quickPollButtons(),
            const SizedBox(height: AppSpacing.md),
            _customPoll(),
          ] else ...[
            _pollView(),
            const SizedBox(height: AppSpacing.md),
            _optionsList(),
            const SizedBox(height: AppSpacing.md),
            if (!_revealed)
              _revealButton()
            else
              _winnerCard(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.poll, size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Instant Polls',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.alertAmber), weight: FontWeight.w600, size: 16)),
            const SizedBox(height: 4),
            Text('Quick household polls — pass the phone around to vote!',
                textAlign: TextAlign.center,
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _quickPollButtons() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Start',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...List.generate(_quickPolls.length, (i) {
            final p = _quickPolls[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _createPoll(p.$1, p.$2),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: hex(AppColors.surfaceContainerLow),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.play_circle, size: 18, color: hex(AppColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(p.$1,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface), size: 12)),
                      ),
                      Text(p.$2.join(' vs '),
                          style: gfont(AppType.bodySm,
                              color: hex(AppColors.outline), size: 10)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      );

  Widget _customPoll() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Custom Poll',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _questionCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
              decoration: InputDecoration(
                hintText: 'Your question...',
                hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                final q = _questionCtrl.text.trim();
                if (q.isEmpty) return;
                _createPoll(q, ['Yes', 'No']);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.alertAmber).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('Create Yes/No Poll',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.alertAmber), weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _pollView() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.alertAmber).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.alertAmber).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.poll, size: 30, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text(_question,
                textAlign: TextAlign.center,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600, size: 16)),
            const SizedBox(height: 4),
            Text('${_options.fold<int>(0, (s, o) => s + o.$2)} votes',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _optionsList() {
    final total = _options.fold<int>(0, (s, o) => s + o.$2);
    return Column(
      children: List.generate(_options.length, (i) {
        final o = _options[i];
        final pct = total > 0 ? o.$2 / total : 0.0;
        final color = _colors[i % _colors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _vote(i),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: hex(color).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: hex(color).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(o.$1,
                            style: gfont(AppType.bodyMd,
                                color: hex(AppColors.onSurface), weight: FontWeight.w600)),
                      ),
                      Text('${o.$2}',
                          style: gfont(AppType.bodyMd,
                              color: hex(color), weight: FontWeight.w700)),
                    ],
                  ),
                  if (_revealed) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                        color: hex(color),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('${(pct * 100).toStringAsFixed(0)}%',
                        style: gfont(AppType.bodySm, color: hex(color), size: 10)),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _revealButton() => GestureDetector(
        onTap: _reveal,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.alertAmber).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: hex(AppColors.alertAmber).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.visibility, size: 18, color: hex(AppColors.alertAmber)),
              const SizedBox(width: 8),
              Text('Reveal Results',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.alertAmber), weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _winnerCard() {
    if (_options.isEmpty) return const SizedBox.shrink();
    final maxVotes = _options.map((o) => o.$2).reduce((a, b) => a > b ? a : b);
    final winner = _options.firstWhere((o) => o.$2 == maxVotes);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, size: 24, color: hex(AppColors.signalEmerald)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Winner',
                    style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
                Text('${winner.$1} with ${winner.$2} votes',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.signalEmerald), weight: FontWeight.w600)),
              ],
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
          border: Border.all(color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: hex(AppColors.tertiary)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Quick polls for the whole household. Pass the phone around to vote, then reveal results. All data stays local on your phone.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
