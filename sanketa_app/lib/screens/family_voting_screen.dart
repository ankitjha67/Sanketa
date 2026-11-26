import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class FamilyVotingScreen extends StatefulWidget {
  const FamilyVotingScreen({super.key});

  @override
  State<FamilyVotingScreen> createState() => _FamilyVotingScreenState();
}

class _FamilyVotingScreenState extends State<FamilyVotingScreen> {
  final _optionCtrl = TextEditingController();
  List<(String, int)> _options = [];
  bool _loading = true;
  bool _revealed = false;
  String _sessionTitle = 'What to watch?';
  final _titleCtrl = TextEditingController(text: 'What to watch?');

  static const _sampleOptions = [
    'Movie Night',
    'Documentary',
    'TV Series',
    'Sports',
    'Kids Show',
  ];

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.alertAmber,
    AppColors.signalEmerald,
    AppColors.tertiary,
    AppColors.error,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _optionCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/family_voting.json');
  }

  Future<void> _load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        final opts = data['options'] as List?;
        if (opts != null && opts.isNotEmpty) {
          _options = opts
              .map((o) {
                final m = o as Map<String, dynamic>;
                return (m['name'] as String, m['votes'] as int);
              })
              .toList();
        }
        _sessionTitle = data['title'] as String? ?? 'What to watch?';
        _titleCtrl.text = _sessionTitle;
      }
    } on Object {/* defaults */}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final f = await _file;
    await f.writeAsString(jsonEncode({
      'title': _sessionTitle,
      'options': _options.map((o) => {'name': o.$1, 'votes': o.$2}).toList(),
    }));
  }

  void _addOption() {
    final text = _optionCtrl.text.trim();
    if (text.isEmpty || _options.length >= 8) return;
    setState(() => _options.add((text, 0)));
    _optionCtrl.clear();
    _save();
  }

  void _vote(int i) {
    if (_revealed) return;
    setState(() {
      _options[i] = (_options[i].$1, _options[i].$2 + 1);
    });
    _save();
  }

  void _reveal() {
    setState(() => _revealed = true);
  }

  void _newSession() {
    _sessionTitle = _titleCtrl.text.trim().isEmpty ? 'What to watch?' : _titleCtrl.text.trim();
    setState(() {
      _options.clear();
      _revealed = false;
    });
    _save();
  }

  void _quickFill() {
    setState(() {
      _options = _sampleOptions.map((s) => (s, 0)).toList();
      _revealed = false;
    });
    _save();
  }

  void _launchWinner() {
    if (_options.isEmpty) return;
    final winner = _options.reduce((a, b) => a.$2 >= b.$2 ? a : b);
    final rc = RemoteScope.of(context);
    rc.launch(winner.$1);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('Launching: ${winner.$1}'),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: hex(AppColors.surface),
        body: Center(child: CircularProgressIndicator(color: hex(AppColors.primary))),
      );
    }

    final totalVotes = _options.fold<int>(0, (s, o) => s + o.$2);

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Family Vote',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface), size: 18, weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _newSession,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.refresh, size: 20, color: hex(AppColors.primary)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          if (!_revealed) _inputSection(),
          const SizedBox(height: AppSpacing.md),
          if (_options.isNotEmpty) ...[
            Text('${_revealed ? 'Results' : 'Options'} (${_options.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('$totalVotes total votes',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 10)),
            const SizedBox(height: 8),
            ..._options.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _optionRow(e.key, e.value, totalVotes),
                )),
            const SizedBox(height: 10),
            _actionButtons(),
          ] else ...[
            _emptyState(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.how_to_vote, size: 40, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text(_sessionTitle,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald), weight: FontWeight.w600, size: 16)),
            const SizedBox(height: 4),
            Text('Everyone votes, the winner plays on TV',
                style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
          ],
        ),
      );

  Widget _inputSection() => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
              decoration: InputDecoration(
                hintText: 'Session title',
                hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) => _sessionTitle = v.trim().isEmpty ? 'What to watch?' : v.trim(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _optionCtrl,
                    style: gfont(AppType.bodyMd, color: hex(AppColors.onSurface), size: 12),
                    decoration: InputDecoration(
                      hintText: 'Add an option',
                      hintStyle: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.sm)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onSubmitted: (_) => _addOption(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addOption,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hex(AppColors.primary).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Icon(Icons.add, size: 20, color: hex(AppColors.primary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _quickFill,
              child: Text('Quick fill with sample options',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primary), size: 10, weight: FontWeight.w600)),
            ),
          ],
        ),
      );

  Widget _optionRow(int i, (String, int) opt, int total) {
    final color = _colors[i % _colors.length];
    final pct = total > 0 ? opt.$2 / total : 0.0;
    final isWinner = _revealed && total > 0 && opt.$2 == _options.map((o) => o.$2).reduce(max);

    return GestureDetector(
      onTap: () => _vote(i),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(isWinner ? AppColors.signalEmerald : AppColors.surfaceContainerLow)
              .withValues(alpha: isWinner ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(isWinner ? AppColors.signalEmerald : AppColors.outlineVariant)
                .withValues(alpha: isWinner ? 0.4 : 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: hex(color), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(opt.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600, size: 12)),
                ),
                Text('${opt.$2} votes',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 10)),
                if (isWinner) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.emoji_events, size: 14, color: hex(AppColors.alertAmber)),
                ],
              ],
            ),
            if (_revealed && total > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: hex(AppColors.outlineVariant).withValues(alpha: 0.15),
                  color: hex(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 2),
              Text('${(pct * 100).round()}%',
                  style: gfont(AppType.bodySm,
                      color: hex(color), size: 9, weight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionButtons() => Row(
        children: [
          if (!_revealed)
            Expanded(
              child: GestureDetector(
                onTap: _reveal,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                        color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text('Reveal Results',
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.signalEmerald), weight: FontWeight.w600)),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GestureDetector(
                onTap: _launchWinner,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: hex(AppColors.primary).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                        color: hex(AppColors.primary).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 18, color: hex(AppColors.primary)),
                      const SizedBox(width: 6),
                      Text('Launch Winner',
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.primary), weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _emptyState() => Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.how_to_vote, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No options yet',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Add options for the family to vote on.',
              style: gfont(AppType.bodySm, color: hex(AppColors.outline), size: 11)),
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
                'Let the family vote on what to watch next. Add up to 8 options, tap to vote, then reveal results. The winner can be launched directly on TV. All data stays on your phone.',
                style: gfont(AppType.bodySm, color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
