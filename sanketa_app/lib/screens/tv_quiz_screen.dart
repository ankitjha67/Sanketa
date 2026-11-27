import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvQuizScreen extends StatefulWidget {
  const TvQuizScreen({super.key});

  @override
  State<TvQuizScreen> createState() => _TvQuizScreenState();
}

class _TvQuizScreenState extends State<TvQuizScreen> {
  int _catIdx = 0;
  int _qIdx = 0;
  int _score = 0;
  int _total = 0;
  int? _selected;
  bool _answered = false;

  static const _categories = <(String, IconData, int)>[
    ('Movies', Icons.movie, AppColors.primary),
    ('Sports', Icons.sports_soccer, AppColors.signalEmerald),
    ('Science', Icons.science, AppColors.alertAmber),
    ('History', Icons.history_edu, AppColors.secondary),
  ];

  static const _questions = <List<_Q>>[
    [
      _Q('Who directed Jurassic Park?', ['Spielberg', 'Scorsese', 'Nolan', 'Cameron'], 0),
      _Q('Which film won Best Picture in 1994?', ['Forrest Gump', 'Pulp Fiction', 'Braveheart', 'Apollo 13'], 0),
      _Q('What year was The Matrix released?', ['1997', '1998', '1999', '2000'], 2),
      _Q('Who played Iron Man in the MCU?', ['Chris Evans', 'Robert Downey Jr', 'Chris Hemsworth', 'Mark Ruffalo'], 1),
      _Q('Which movie features the quote "Here\'s looking at you, kid"?', ['Casablanca', 'Gone with the Wind', 'Citizen Kane', 'The Godfather'], 0),
    ],
    [
      _Q('How many players on a soccer team?', ['9', '10', '11', '12'], 2),
      _Q('Which country hosted the 2016 Olympics?', ['China', 'UK', 'Brazil', 'Japan'], 2),
      _Q('What sport uses a shuttlecock?', ['Tennis', 'Badminton', 'Squash', 'Cricket'], 1),
      _Q('How long is an NBA quarter?', ['10 min', '12 min', '15 min', '20 min'], 1),
      _Q('Which Grand Slam is played on clay?', ['Wimbledon', 'US Open', 'French Open', 'Australian Open'], 2),
    ],
    [
      _Q('What is the chemical symbol for gold?', ['Go', 'Gd', 'Au', 'Ag'], 2),
      _Q('How many planets in our solar system?', ['7', '8', '9', '10'], 1),
      _Q('What gas do plants absorb?', ['Oxygen', 'Nitrogen', 'Carbon dioxide', 'Hydrogen'], 2),
      _Q('What is the speed of light (km/s)?', ['150,000', '200,000', '300,000', '400,000'], 2),
      _Q('Which element has atomic number 1?', ['Helium', 'Hydrogen', 'Lithium', 'Carbon'], 1),
    ],
    [
      _Q('Who was the first US President?', ['Adams', 'Jefferson', 'Washington', 'Lincoln'], 2),
      _Q('In which year did World War II end?', ['1943', '1944', '1945', '1946'], 2),
      _Q('Which empire built the Colosseum?', ['Greek', 'Roman', 'Ottoman', 'Persian'], 1),
      _Q('Who discovered America in 1492?', ['Magellan', 'Columbus', 'Vespucci', 'Drake'], 1),
      _Q('The Berlin Wall fell in what year?', ['1987', '1988', '1989', '1990'], 2),
    ],
  ];

  List<_Q> get _currentQuestions => _questions[_catIdx];
  _Q get _currentQ => _currentQuestions[_qIdx];

  void _selectAnswer(int idx) {
    if (_answered) return;
    setState(() {
      _selected = idx;
      _answered = true;
      _total++;
      if (idx == _currentQ.correct) _score++;
    });
    HapticFeedback.mediumImpact();
  }

  void _nextQuestion() {
    setState(() {
      _qIdx = (_qIdx + 1) % _currentQuestions.length;
      _selected = null;
      _answered = false;
    });
    HapticFeedback.selectionClick();
  }

  void _castQuestion() {
    final rc = RemoteScope.of(context);
    rc.type(_currentQ.question);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Question sent to TV'),
        duration: Duration(seconds: 2),
      ));
  }

  void _resetScore() {
    setState(() {
      _score = 0;
      _total = 0;
      _qIdx = 0;
      _selected = null;
      _answered = false;
    });
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
        title: Text('TV Quiz',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: hex(AppColors.outline)),
            onPressed: _resetScore,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _heroCard(),
          const SizedBox(height: AppSpacing.md),
          _categoryChips(),
          const SizedBox(height: AppSpacing.md),
          _scoreRow(),
          const SizedBox(height: AppSpacing.lg),
          _questionCard(),
          const SizedBox(height: AppSpacing.md),
          ..._currentQ.options.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _optionCard(e.key, e.value),
              )),
          const SizedBox(height: AppSpacing.md),
          if (_answered) _nextButton(),
          const SizedBox(height: AppSpacing.md),
          _castButton(),
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
          color: hex(AppColors.primary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.primary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.quiz, size: 48, color: hex(AppColors.primary)),
            const SizedBox(height: 8),
            Text('TV Trivia Quiz',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Test your knowledge and cast questions to TV',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _categoryChips() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.asMap().entries.map((e) {
            final active = e.key == _catIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _catIdx = e.key;
                    _qIdx = 0;
                    _selected = null;
                    _answered = false;
                  });
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: hex(e.value.$3)
                        .withValues(alpha: active ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    border: Border.all(
                      color: hex(e.value.$3)
                          .withValues(alpha: active ? 0.4 : 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.$2, size: 14, color: hex(e.value.$3)),
                      const SizedBox(width: 4),
                      Text(e.value.$1,
                          style: gfont(AppType.bodySm,
                              color: hex(e.value.$3),
                              weight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                              size: 11)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _scoreRow() => Row(
        children: [
          Expanded(child: _statBadge('Score', '$_score', AppColors.signalEmerald)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _statBadge('Total', '$_total', AppColors.primary)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: _statBadge(
                  'Accuracy',
                  _total == 0 ? '--' : '${(_score * 100 ~/ _total)}%',
                  AppColors.alertAmber)),
        ],
      );

  Widget _statBadge(String label, String value, int c) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: hex(c).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Column(
          children: [
            Text(value,
                style: gfont(AppType.headlineMd,
                    color: hex(c), size: 18, weight: FontWeight.w700)),
            Text(label,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.outline), size: 9)),
          ],
        ),
      );

  Widget _questionCard() {
    final cat = _categories[_catIdx];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(cat.$3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border:
            Border.all(color: hex(cat.$3).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: hex(cat.$3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
                child: Text('Q${_qIdx + 1}/${_currentQuestions.length}',
                    style: gfont(AppType.bodySm,
                        color: hex(cat.$3),
                        weight: FontWeight.w600,
                        size: 10)),
              ),
              const Spacer(),
              Text(cat.$1,
                  style: gfont(AppType.bodySm,
                      color: hex(cat.$3), size: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Text(_currentQ.question,
              textAlign: TextAlign.center,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 15)),
        ],
      ),
    );
  }

  Widget _optionCard(int idx, String text) {
    final isCorrect = idx == _currentQ.correct;
    final isSelected = idx == _selected;
    int bgColor;
    double bgAlpha;
    int borderColor;
    double borderAlpha;

    if (!_answered) {
      bgColor = AppColors.surfaceContainerLow;
      bgAlpha = 1;
      borderColor = AppColors.outlineVariant;
      borderAlpha = 0.2;
    } else if (isCorrect) {
      bgColor = AppColors.signalEmerald;
      bgAlpha = 0.12;
      borderColor = AppColors.signalEmerald;
      borderAlpha = 0.4;
    } else if (isSelected) {
      bgColor = AppColors.error;
      bgAlpha = 0.12;
      borderColor = AppColors.error;
      borderAlpha = 0.4;
    } else {
      bgColor = AppColors.surfaceContainerLow;
      bgAlpha = 1;
      borderColor = AppColors.outlineVariant;
      borderAlpha = 0.15;
    }

    return GestureDetector(
      onTap: () => _selectAnswer(idx),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(bgColor).withValues(alpha: bgAlpha),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
              color: hex(borderColor).withValues(alpha: borderAlpha)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hex(_answered && isCorrect
                        ? AppColors.signalEmerald
                        : _answered && isSelected
                            ? AppColors.error
                            : AppColors.outlineVariant)
                    .withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(String.fromCharCode(65 + idx),
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.onSurface),
                      weight: FontWeight.w500,
                      size: 13)),
            ),
            if (_answered && isCorrect)
              Icon(Icons.check_circle,
                  size: 20, color: hex(AppColors.signalEmerald)),
            if (_answered && isSelected && !isCorrect)
              Icon(Icons.cancel, size: 20, color: hex(AppColors.error)),
          ],
        ),
      ),
    );
  }

  Widget _nextButton() => GestureDetector(
        onTap: _nextQuestion,
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
              Icon(Icons.arrow_forward,
                  size: 20, color: hex(AppColors.primary)),
              const SizedBox(width: 8),
              Text('Next Question',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600)),
            ],
          ),
        ),
      );

  Widget _castButton() => GestureDetector(
        onTap: _castQuestion,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: hex(AppColors.secondary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.secondary).withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cast, size: 18, color: hex(AppColors.secondary)),
              const SizedBox(width: 8),
              Text('Cast to TV',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.secondary),
                      weight: FontWeight.w600,
                      size: 12)),
            ],
          ),
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
                'Quiz game with 4 categories and 5 questions each. '
                'Cast questions to TV for group play. All data local.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}

class _Q {
  final String question;
  final List<String> options;
  final int correct;
  const _Q(this.question, this.options, this.correct);
}
