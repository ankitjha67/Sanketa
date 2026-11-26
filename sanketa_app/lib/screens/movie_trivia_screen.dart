import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../theme/tokens_x.dart';

class _Question {
  const _Question({
    required this.question,
    required this.options,
    required this.answer,
  });

  final String question;
  final List<String> options;
  final int answer;
}

class MovieTriviaScreen extends StatefulWidget {
  const MovieTriviaScreen({super.key});

  @override
  State<MovieTriviaScreen> createState() => _MovieTriviaScreenState();
}

class _MovieTriviaScreenState extends State<MovieTriviaScreen> {
  int _questionIndex = 0;
  int _score = 0;
  int _total = 0;
  int? _selected;
  bool _revealed = false;
  bool _finished = false;
  final _rng = Random();

  static const _questions = <_Question>[
    _Question(
      question: 'What was the first feature-length film with sound?',
      options: ['The Jazz Singer', 'Metropolis', 'Nosferatu', 'Sunrise'],
      answer: 0,
    ),
    _Question(
      question: 'Which TV series had the most Emmy nominations ever?',
      options: ['Friends', 'Game of Thrones', 'Saturday Night Live', 'The Simpsons'],
      answer: 2,
    ),
    _Question(
      question: 'What year was the first colour TV broadcast?',
      options: ['1941', '1951', '1961', '1971'],
      answer: 1,
    ),
    _Question(
      question: 'Which streaming service launched first?',
      options: ['Hulu', 'Netflix Streaming', 'Amazon Prime Video', 'Disney+'],
      answer: 1,
    ),
    _Question(
      question: 'What does HDMI stand for?',
      options: [
        'High Definition Media Interface',
        'High-Definition Multimedia Interface',
        'Home Digital Media Input',
        'High Display Monitor Interface',
      ],
      answer: 1,
    ),
    _Question(
      question: 'Which country produces the most TV shows per year?',
      options: ['USA', 'India', 'South Korea', 'UK'],
      answer: 1,
    ),
    _Question(
      question: 'What was the first TV remote control called?',
      options: ['Lazy Bones', 'Space Command', 'Flash-Matic', 'Zenith'],
      answer: 0,
    ),
    _Question(
      question: 'How many pixels are in a 4K UHD display?',
      options: ['4,000', '4 million', '8.3 million', '16 million'],
      answer: 2,
    ),
    _Question(
      question: 'Which format won the HD disc war against HD DVD?',
      options: ['LaserDisc', 'Blu-ray', 'UMD', 'EVD'],
      answer: 1,
    ),
    _Question(
      question: 'What refresh rate is standard for most modern TVs?',
      options: ['30 Hz', '60 Hz', '120 Hz', '240 Hz'],
      answer: 1,
    ),
  ];

  late List<int> _order;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    _order = List.generate(_questions.length, (i) => i)..shuffle(_rng);
    _questionIndex = 0;
    _score = 0;
    _total = 0;
    _selected = null;
    _revealed = false;
    _finished = false;
  }

  _Question get _current => _questions[_order[_questionIndex]];

  void _select(int idx) {
    if (_revealed) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selected = idx;
      _revealed = true;
      _total++;
      if (idx == _current.answer) _score++;
    });
  }

  void _next() {
    if (_questionIndex + 1 >= _order.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _questionIndex++;
      _selected = null;
      _revealed = false;
    });
  }

  void _restart() => setState(_shuffle);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Movie Trivia',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text('$_score / $_total',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w700,
                      size: 14)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_finished) ...[
            _resultCard(),
            const SizedBox(height: AppSpacing.lg),
            _restartButton(),
          ] else ...[
            _progressBar(),
            const SizedBox(height: AppSpacing.md),
            _questionCard(),
            const SizedBox(height: AppSpacing.md),
            ..._current.options.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _optionCard(e.key, e.value),
                )),
            if (_revealed) ...[
              const SizedBox(height: AppSpacing.md),
              _nextButton(),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _progressBar() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question ${_questionIndex + 1} of ${_order.length}',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11)),
              Text('Score: $_score',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.primary),
                      weight: FontWeight.w600,
                      size: 11)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.full),
            child: LinearProgressIndicator(
              value: (_questionIndex + 1) / _order.length,
              minHeight: 4,
              backgroundColor:
                  hex(AppColors.outlineVariant).withValues(alpha: 0.2),
              valueColor:
                  AlwaysStoppedAnimation<Color>(hex(AppColors.primary)),
            ),
          ),
        ],
      );

  Widget _questionCard() => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.tertiary).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.tertiary).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.quiz, size: 32, color: hex(AppColors.tertiary)),
            const SizedBox(height: 10),
            Text(
              _current.question,
              textAlign: TextAlign.center,
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600,
                  size: 14),
            ),
          ],
        ),
      );

  Widget _optionCard(int idx, String text) {
    final isSelected = _selected == idx;
    final isCorrect = idx == _current.answer;
    int cardColor;
    if (!_revealed) {
      cardColor = AppColors.surfaceContainerLow;
    } else if (isCorrect) {
      cardColor = AppColors.signalEmerald;
    } else if (isSelected && !isCorrect) {
      cardColor = AppColors.error;
    } else {
      cardColor = AppColors.surfaceContainerLow;
    }

    return GestureDetector(
      onTap: () => _select(idx),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(cardColor)
              .withValues(alpha: _revealed && (isCorrect || isSelected) ? 0.12 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(_revealed && (isCorrect || isSelected)
                    ? cardColor
                    : AppColors.outlineVariant)
                .withValues(
                    alpha: _revealed && (isCorrect || isSelected) ? 0.5 : 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hex(cardColor).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _revealed
                    ? Icon(
                        isCorrect ? Icons.check : (isSelected ? Icons.close : null),
                        size: 16,
                        color: hex(isCorrect
                            ? AppColors.signalEmerald
                            : AppColors.error),
                      )
                    : Text(String.fromCharCode(65 + idx),
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
                      weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      size: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextButton() => GestureDetector(
        onTap: _next,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.12),
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
              Text(
                _questionIndex + 1 >= _order.length
                    ? 'See Results'
                    : 'Next Question',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.primary), weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

  Widget _resultCard() {
    final pct = _total > 0 ? (_score / _total * 100).round() : 0;
    final emoji = pct >= 80
        ? '🏆'
        : pct >= 60
            ? '👏'
            : pct >= 40
                ? '👍'
                : '📚';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: hex(AppColors.primary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
            color: hex(AppColors.primary).withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('$_score / $_total correct',
              style: gfont(AppType.headlineMd,
                  color: hex(AppColors.onSurface),
                  size: 24,
                  weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('$pct% accuracy',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.primary),
                  weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            pct >= 80
                ? 'TV expert! You really know your stuff.'
                : pct >= 60
                    ? 'Well done! Solid knowledge.'
                    : pct >= 40
                        ? 'Not bad! Keep watching and learning.'
                        : 'Time to binge some TV history!',
            textAlign: TextAlign.center,
            style: gfont(AppType.bodySm,
                color: hex(AppColors.outline), size: 11),
          ),
        ],
      ),
    );
  }

  Widget _restartButton() => GestureDetector(
        onTap: _restart,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.signalEmerald).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.replay, size: 20, color: hex(AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text('Play Again',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.signalEmerald),
                      weight: FontWeight.w600)),
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
                'Test your TV and movie knowledge during commercial breaks! 10 questions about TV history, technology, and entertainment. All questions stored locally.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
