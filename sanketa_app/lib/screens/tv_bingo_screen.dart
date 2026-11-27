import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class TvBingoScreen extends StatefulWidget {
  const TvBingoScreen({super.key});

  @override
  State<TvBingoScreen> createState() => _TvBingoScreenState();
}

class _TvBingoScreenState extends State<TvBingoScreen> {
  int _themeIndex = 0;
  late List<_BingoCell> _cells;
  int _markedCount = 0;
  bool _bingo = false;

  static const _themes = <(String, int)>[
    ('Movie Night', AppColors.primary),
    ('Sports', AppColors.signalEmerald),
    ('Reality TV', AppColors.secondary),
    ('News', AppColors.tertiary),
  ];

  static const _moviePrompts = [
    'Jump scare',
    'Plot twist',
    'Car chase',
    'Love interest',
    'Dramatic zoom',
    'Explosion',
    'Villain monologue',
    'Flashback scene',
    'Character cries',
    'Awkward silence',
    'Phone rings',
    'Door slam',
    'Free space',
    'Chase scene',
    'Someone trips',
    'Dramatic music',
    'Sunset shot',
    'Cliffhanger',
    'Happy ending',
    'Slow motion',
    'Montage',
    'Comic relief',
    'Foreshadowing',
    'Dream sequence',
    'Post-credits',
  ];

  static const _sportsPrompts = [
    'Goal scored',
    'Ref blows whistle',
    'Replay shown',
    'Coach angry',
    'Crowd roars',
    'Player substitution',
    'Penalty kick',
    'Commercial break',
    'Stats graphic',
    'Close-up fan',
    'Injury timeout',
    'Commentator joke',
    'Free space',
    'Yellow card',
    'Offside call',
    'Header attempt',
    'Corner kick',
    'Free kick',
    'Save by keeper',
    'Throw-in',
    'Halftime show',
    'Sponsor logo',
    'Slow-mo replay',
    'Player celebrates',
    'Final whistle',
  ];

  static const _realityPrompts = [
    'Someone cries',
    'Dramatic pause',
    'Confession cam',
    'Rose ceremony',
    '"I\'m not here to make friends"',
    'Backstabbing',
    'Awkward date',
    'Group fight',
    'Cliffhanger',
    'Shocking reveal',
    'Someone leaves',
    'Alliance formed',
    'Free space',
    'Judge critique',
    'Immunity won',
    'Twist announced',
    'Gossip session',
    '"Can I steal you?"',
    'Product placement',
    'Tearful goodbye',
    'Victory dance',
    'Villain edit',
    'Love triangle',
    'Recap montage',
    'Host smirks',
  ];

  static const _newsPrompts = [
    'Breaking news',
    'Weather segment',
    'Live report',
    'Expert panel',
    'Stock ticker',
    'Traffic update',
    'Human interest',
    'Press conference',
    'Social media mention',
    'Commercial break',
    'Anchor chuckle',
    'Graph shown',
    'Free space',
    'Interview clip',
    'Developing story',
    'Opinion segment',
    'Viral video',
    'Correspondent',
    'Fact check',
    'Poll results',
    'Debate clip',
    'Celebrity news',
    'Tech story',
    'Sports brief',
    'Sign off',
  ];

  @override
  void initState() {
    super.initState();
    _generateBoard();
  }

  List<String> get _currentPrompts {
    switch (_themeIndex) {
      case 1:
        return _sportsPrompts;
      case 2:
        return _realityPrompts;
      case 3:
        return _newsPrompts;
      default:
        return _moviePrompts;
    }
  }

  void _generateBoard() {
    final prompts = List<String>.from(_currentPrompts)..shuffle(Random());
    _cells = List.generate(25, (i) {
      final isFree = i == 12;
      return _BingoCell(
        text: isFree ? 'FREE' : prompts[i],
        marked: isFree,
      );
    });
    _markedCount = 1;
    _bingo = false;
  }

  void _toggleCell(int idx) {
    if (idx == 12) return;
    setState(() {
      _cells[idx].marked = !_cells[idx].marked;
      _markedCount = _cells.where((c) => c.marked).length;
      _bingo = _checkBingo();
    });
    HapticFeedback.selectionClick();
    if (_bingo) HapticFeedback.heavyImpact();
  }

  bool _checkBingo() {
    for (var r = 0; r < 5; r++) {
      if (List.generate(5, (c) => _cells[r * 5 + c].marked).every((m) => m)) {
        return true;
      }
    }
    for (var c = 0; c < 5; c++) {
      if (List.generate(5, (r) => _cells[r * 5 + c].marked).every((m) => m)) {
        return true;
      }
    }
    if (List.generate(5, (i) => _cells[i * 6].marked).every((m) => m)) {
      return true;
    }
    if (List.generate(5, (i) => _cells[(i + 1) * 4].marked).every((m) => m)) {
      return true;
    }
    return false;
  }

  void _newGame() {
    setState(_generateBoard);
    HapticFeedback.mediumImpact();
  }

  void _selectTheme(int idx) {
    setState(() {
      _themeIndex = idx;
      _generateBoard();
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _themes[_themeIndex];
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Bingo',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: hex(theme.$2)),
            onPressed: _newGame,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(theme),
          const SizedBox(height: AppSpacing.md),
          _themeSelector(),
          const SizedBox(height: AppSpacing.md),
          _statsRow(theme),
          const SizedBox(height: AppSpacing.md),
          _bingoGrid(theme),
          if (_bingo) ...[
            const SizedBox(height: AppSpacing.md),
            _bingoAlert(theme),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _heroCard((String, int) theme) => Container(
        padding: const EdgeInsets.symmetric(
            vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(theme.$2).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: hex(theme.$2).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.grid_on, size: 48, color: hex(theme.$2)),
            const SizedBox(height: 8),
            Text('${theme.$1} Bingo',
                style: gfont(AppType.bodyMd,
                    color: hex(theme.$2), weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Mark squares as you spot them on TV!',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _themeSelector() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _themes.asMap().entries.map((e) {
            final active = e.key == _themeIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => _selectTheme(e.key),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: hex(e.value.$2)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(e.value.$2)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Text(e.value.$1,
                      style: gfont(AppType.bodySm,
                          color: hex(e.value.$2),
                          weight:
                              active ? FontWeight.w600 : FontWeight.w400,
                          size: 11)),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _statsRow((String, int) theme) => Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(theme.$2).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                children: [
                  Text('$_markedCount/25',
                      style: gfont(AppType.headlineMd,
                          color: hex(theme.$2),
                          size: 18,
                          weight: FontWeight.w700)),
                  Text('Marked',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: hex(_bingo ? AppColors.signalEmerald : AppColors.outline)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Column(
                children: [
                  Text(_bingo ? 'BINGO!' : 'No bingo',
                      style: gfont(AppType.headlineMd,
                          color: hex(_bingo
                              ? AppColors.signalEmerald
                              : AppColors.outline),
                          size: 18,
                          weight: FontWeight.w700)),
                  Text('Status',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 9)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _bingoGrid((String, int) theme) => GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.85,
        children: _cells.asMap().entries.map((e) {
          final cell = e.value;
          final isFree = e.key == 12;
          return GestureDetector(
            onTap: () => _toggleCell(e.key),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: cell.marked
                    ? hex(theme.$2).withValues(alpha: 0.2)
                    : hex(AppColors.surfaceContainerLow),
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(
                  color: cell.marked
                      ? hex(theme.$2).withValues(alpha: 0.5)
                      : hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                  width: cell.marked ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  cell.text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: gfont(AppType.bodySm,
                      color: hex(cell.marked
                          ? theme.$2
                          : AppColors.onSurface),
                      weight: isFree || cell.marked
                          ? FontWeight.w700
                          : FontWeight.w400,
                      size: 8),
                ),
              ),
            ),
          );
        }).toList(),
      );

  Widget _bingoAlert((String, int) theme) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 24, color: hex(AppColors.signalEmerald)),
            const SizedBox(width: 8),
            Text('BINGO! You got a line!',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w700)),
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
                'Play bingo while watching TV! Tap squares as you spot them. '
                'Get 5 in a row for BINGO. Hit refresh for a new board.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _BingoCell {
  String text;
  bool marked;
  _BingoCell({required this.text, required this.marked});
}
