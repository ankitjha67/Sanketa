import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class TvTriviaScreen extends StatefulWidget {
  const TvTriviaScreen({super.key});

  @override
  State<TvTriviaScreen> createState() => _TvTriviaScreenState();
}

class _TvTriviaScreenState extends State<TvTriviaScreen> {
  int _questionIndex = 0;
  int _score = 0;
  int _answered = 0;
  int? _selected;
  bool _revealed = false;
  int _categoryIndex = 0;

  static const _categories = ['All', 'Movies', 'TV Shows', 'Music', 'Sports'];
  static const _categoryIcons = [
    Icons.quiz,
    Icons.movie,
    Icons.tv,
    Icons.music_note,
    Icons.sports_soccer,
  ];

  static const _questions = <(String, List<String>, int, String)>[
    ('Which TV show features a chemistry teacher turned drug lord?',
        ['The Wire', 'Breaking Bad', 'Ozark', 'Narcos'], 1, 'TV Shows'),
    ('What year was the first Star Wars film released?',
        ['1975', '1977', '1980', '1983'], 1, 'Movies'),
    ('Which streaming service produced "Stranger Things"?',
        ['Amazon Prime', 'Hulu', 'Netflix', 'Disney+'], 2, 'TV Shows'),
    ('Who directed "The Shawshank Redemption"?',
        ['Steven Spielberg', 'Frank Darabont', 'Martin Scorsese', 'Ridley Scott'], 1, 'Movies'),
    ('Which band performed the theme for "Friends"?',
        ['The Rembrandts', 'R.E.M.', 'Oasis', 'Blur'], 0, 'Music'),
    ('How many seasons did "Game of Thrones" run?',
        ['6', '7', '8', '10'], 2, 'TV Shows'),
    ('Which actor played Iron Man in the MCU?',
        ['Chris Evans', 'Chris Hemsworth', 'Robert Downey Jr.', 'Mark Ruffalo'], 2, 'Movies'),
    ('What sport does Ted Lasso coach?',
        ['Basketball', 'American Football', 'Soccer', 'Cricket'], 2, 'Sports'),
    ('Which animated series features a family named Griffin?',
        ['The Simpsons', 'Family Guy', 'Bob\'s Burgers', 'South Park'], 1, 'TV Shows'),
    ('What was the highest-grossing film of all time (unadjusted)?',
        ['Titanic', 'Avengers: Endgame', 'Avatar', 'Star Wars'], 2, 'Movies'),
    ('Which TV show is set in Hawkins, Indiana?',
        ['Dark', 'Stranger Things', 'Westworld', 'Lost'], 1, 'TV Shows'),
    ('Who composed the "Jaws" theme?',
        ['Hans Zimmer', 'John Williams', 'Danny Elfman', 'James Horner'], 1, 'Music'),
    ('Which sport has the Super Bowl?',
        ['Baseball', 'Basketball', 'American Football', 'Hockey'], 2, 'Sports'),
    ('In "The Office", what is the name of the paper company?',
        ['Staples', 'Dunder Mifflin', 'Sabre', 'Wernham Hogg'], 1, 'TV Shows'),
    ('Which film won Best Picture at the 2020 Oscars?',
        ['1917', 'Joker', 'Parasite', 'Once Upon a Time'], 2, 'Movies'),
  ];

  late List<int> _shuffled;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    final indices = List.generate(_questions.length, (i) => i);
    indices.shuffle(Random());
    _shuffled = indices;
  }

  List<int> get _filteredIndices {
    if (_categoryIndex == 0) return _shuffled;
    final cat = _categories[_categoryIndex];
    return _shuffled.where((i) => _questions[i].$4 == cat).toList();
  }

  void _selectAnswer(int i) {
    if (_revealed) return;
    setState(() {
      _selected = i;
      _revealed = true;
      _answered++;
      if (i == _questions[_filteredIndices[_questionIndex]].$3) _score++;
    });
  }

  void _next() {
    setState(() {
      _questionIndex++;
      _selected = null;
      _revealed = false;
    });
  }

  void _restart() {
    _shuffle();
    setState(() {
      _questionIndex = 0;
      _score = 0;
      _answered = 0;
      _selected = null;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIndices;
    final done = _questionIndex >= filtered.length;

    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Trivia',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          GestureDetector(
            onTap: _restart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.replay, size: 20, color: hex(AppColors.primary)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _scoreCard(),
          const SizedBox(height: AppSpacing.md),
          _categoryBar(),
          const SizedBox(height: AppSpacing.md),
          if (done)
            _resultsCard()
          else if (filtered.isEmpty)
            _emptyCategory()
          else
            _questionCard(filtered[_questionIndex]),
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _scoreCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _stat('Score', '$_score'),
            Container(width: 1, height: 30, color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
            _stat('Answered', '$_answered'),
            Container(width: 1, height: 30, color: hex(AppColors.outlineVariant).withValues(alpha: 0.3)),
            _stat('Accuracy',
                _answered == 0 ? '—' : '${(_score * 100 / _answered).round()}%'),
          ],
        ),
      );

  Widget _stat(String label, String value) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.primary),
                  size: 20,
                  weight: FontWeight.w700)),
          Text(label,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 10)),
        ],
      );

  Widget _categoryBar() => SizedBox(
        height: 30,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final active = i == _categoryIndex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _categoryIndex = i;
                  _questionIndex = 0;
                  _selected = null;
                  _revealed = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: hex(active ? AppColors.primary : AppColors.surfaceContainerHigh)
                      .withValues(alpha: active ? 0.15 : 1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                  border: Border.all(
                    color: hex(active ? AppColors.primary : AppColors.outlineVariant)
                        .withValues(alpha: active ? 0.5 : 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_categoryIcons[i],
                        size: 12,
                        color: hex(active ? AppColors.primary : AppColors.outline)),
                    const SizedBox(width: 4),
                    Text(_categories[i],
                        style: gfont(AppType.bodySm,
                            color: hex(active ? AppColors.primary : AppColors.onSurface),
                            weight: active ? FontWeight.w600 : FontWeight.w400,
                            size: 10)),
                  ],
                ),
              ),
            );
          },
        ),
      );

  Widget _questionCard(int qIndex) {
    final q = _questions[qIndex];
    final correct = q.$3;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(AppColors.surfaceContainerLow),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hex(AppColors.tertiary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text(q.$4,
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.tertiary),
                        size: 9,
                        weight: FontWeight.w600)),
              ),
              const Spacer(),
              Text('${_questionIndex + 1}/${_filteredIndices.length}',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(q.$1,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 14)),
          const SizedBox(height: 14),
          ...q.$2.asMap().entries.map((e) {
            final isCorrect = e.key == correct;
            final isSelected = e.key == _selected;
            final borderColor = !_revealed
                ? AppColors.outlineVariant
                : isCorrect
                    ? AppColors.signalEmerald
                    : isSelected
                        ? AppColors.error
                        : AppColors.outlineVariant;
            final bgAlpha = !_revealed
                ? 1.0
                : isCorrect
                    ? 0.1
                    : isSelected
                        ? 0.08
                        : 1.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _selectAnswer(e.key),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: hex(_revealed && (isCorrect || isSelected)
                            ? borderColor
                            : AppColors.surfaceContainerHigh)
                        .withValues(alpha: bgAlpha),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: hex(borderColor)
                          .withValues(alpha: _revealed ? 0.6 : 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(e.value,
                          style: gfont(AppType.bodyMd,
                              color: hex(AppColors.onSurface),
                              size: 12)),
                      const Spacer(),
                      if (_revealed && isCorrect)
                        Icon(Icons.check_circle,
                            size: 16, color: hex(AppColors.signalEmerald))
                      else if (_revealed && isSelected && !isCorrect)
                        Icon(Icons.cancel,
                            size: 16, color: hex(AppColors.error)),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (_revealed) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _next,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Center(
                  child: Text('Next Question',
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultsCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.emoji_events,
                size: 48, color: hex(AppColors.alertAmber)),
            const SizedBox(height: 8),
            Text('Quiz Complete!',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w700,
                    size: 16)),
            const SizedBox(height: 4),
            Text('$_score out of $_answered correct',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface), size: 13)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _restart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Play Again',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.primary),
                        weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );

  Widget _emptyCategory() => Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.quiz, size: 40, color: hex(AppColors.outline)),
          const SizedBox(height: 8),
          Text('No questions in this category',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface), weight: FontWeight.w600)),
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
                'Test your entertainment knowledge while watching TV. Questions are shuffled each round. All questions are built-in — no network calls.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
