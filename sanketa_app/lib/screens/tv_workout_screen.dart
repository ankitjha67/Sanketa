import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class TvWorkoutScreen extends StatefulWidget {
  const TvWorkoutScreen({super.key});

  @override
  State<TvWorkoutScreen> createState() => _TvWorkoutScreenState();
}

class _TvWorkoutScreenState extends State<TvWorkoutScreen> {
  int _routineIndex = 0;
  int _exerciseIndex = 0;
  int _repsLeft = 0;
  int _setsLeft = 0;
  int _timerSeconds = 0;
  bool _active = false;
  bool _resting = false;
  Timer? _timer;

  static const _routines = [
    (
      'Quick Stretch',
      Icons.self_improvement,
      AppColors.signalEmerald,
      [
        ('Neck Rolls', 10, 2, 0),
        ('Arm Circles', 15, 2, 0),
        ('Shoulder Shrugs', 12, 2, 0),
        ('Standing Side Stretch', 8, 2, 0),
      ],
    ),
    (
      'Commercial Break',
      Icons.tv,
      AppColors.primary,
      [
        ('Jumping Jacks', 20, 3, 0),
        ('Squats', 15, 3, 0),
        ('Push-ups', 10, 3, 0),
        ('Lunges', 12, 3, 0),
      ],
    ),
    (
      'Couch Workout',
      Icons.weekend,
      AppColors.alertAmber,
      [
        ('Seated Leg Raises', 15, 3, 0),
        ('Couch Dips', 10, 3, 0),
        ('Seated Twists', 12, 3, 0),
        ('Ankle Circles', 20, 2, 0),
      ],
    ),
    (
      'Morning Energy',
      Icons.wb_sunny,
      AppColors.secondary,
      [
        ('High Knees', 20, 3, 0),
        ('Burpees', 8, 3, 0),
        ('Mountain Climbers', 15, 3, 0),
        ('Plank', 0, 3, 30),
      ],
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRoutine() {
    final routine = _routines[_routineIndex];
    final exercise = routine.$4[0];
    setState(() {
      _active = true;
      _exerciseIndex = 0;
      _repsLeft = exercise.$2;
      _setsLeft = exercise.$3;
      _timerSeconds = exercise.$4;
      _resting = false;
    });
    HapticFeedback.mediumImpact();
    if (_timerSeconds > 0) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timerSeconds <= 1) {
        _timer?.cancel();
        _completeExercise();
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  void _completeRep() {
    if (_repsLeft <= 1) {
      _completeExercise();
    } else {
      setState(() => _repsLeft--);
      HapticFeedback.selectionClick();
    }
  }

  void _completeExercise() {
    _timer?.cancel();
    if (_setsLeft > 1) {
      final exercise = _routines[_routineIndex].$4[_exerciseIndex];
      setState(() {
        _setsLeft--;
        _repsLeft = exercise.$2;
        _timerSeconds = exercise.$4;
        _resting = true;
      });
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() => _resting = false);
          if (_timerSeconds > 0) _startTimer();
        }
      });
    } else {
      _nextExercise();
    }
  }

  void _nextExercise() {
    final routine = _routines[_routineIndex];
    if (_exerciseIndex + 1 < routine.$4.length) {
      final next = routine.$4[_exerciseIndex + 1];
      setState(() {
        _exerciseIndex++;
        _repsLeft = next.$2;
        _setsLeft = next.$3;
        _timerSeconds = next.$4;
        _resting = false;
      });
      HapticFeedback.heavyImpact();
      if (_timerSeconds > 0) _startTimer();
    } else {
      setState(() => _active = false);
      _timer?.cancel();
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Workout complete!'),
          duration: Duration(seconds: 3),
        ));
    }
  }

  void _stopWorkout() {
    _timer?.cancel();
    setState(() => _active = false);
  }

  void _pauseTV() {
    final rc = RemoteScope.of(context);
    rc.key(core.Key.ok);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('TV Workout',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_active)
            GestureDetector(
              onTap: _pauseTV,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.pause_circle, size: 20, color: hex(AppColors.primary)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_active)
            _activeView()
          else ...[
            _heroCard(),
            const SizedBox(height: AppSpacing.md),
            Text('Pick a Routine',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._routines.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _routineCard(e.key),
                )),
            const SizedBox(height: AppSpacing.md),
            _startButton(),
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
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.fitness_center, size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Stay Active While Watching',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Follow guided exercise routines during commercials or while binge-watching',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _routineCard(int idx) {
    final r = _routines[idx];
    final active = idx == _routineIndex;
    return GestureDetector(
      onTap: () => setState(() => _routineIndex = idx),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hex(active ? r.$3 : AppColors.surfaceContainerLow)
              .withValues(alpha: active ? 0.1 : 1),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: hex(active ? r.$3 : AppColors.outlineVariant)
                .withValues(alpha: active ? 0.4 : 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(r.$2, size: 24, color: hex(r.$3)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.$1,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.onSurface),
                          weight: FontWeight.w600,
                          size: 13)),
                  Text('${r.$4.length} exercises',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 10)),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle, size: 20, color: hex(r.$3)),
          ],
        ),
      ),
    );
  }

  Widget _activeView() {
    final routine = _routines[_routineIndex];
    final exercise = routine.$4[_exerciseIndex];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: hex(routine.$3).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: hex(routine.$3).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(routine.$1,
                  style: gfont(AppType.bodySm,
                      color: hex(routine.$3),
                      weight: FontWeight.w600,
                      size: 11)),
              const SizedBox(height: 8),
              Text(exercise.$1,
                  style: gfont(AppType.headlineMd,
                      color: hex(AppColors.onSurface),
                      size: 22,
                      weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Exercise ${_exerciseIndex + 1} of ${routine.$4.length}',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 11)),
              const SizedBox(height: 16),
              if (_resting)
                Text('Rest... next set in a moment',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.alertAmber),
                        weight: FontWeight.w600))
              else if (_timerSeconds > 0)
                Text('${_timerSeconds}s',
                    style: gfont(AppType.headlineMd,
                        color: hex(routine.$3),
                        size: 48,
                        weight: FontWeight.w700))
              else
                GestureDetector(
                  onTap: _completeRep,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: hex(routine.$3).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                    child: Text('$_repsLeft reps left — tap to count',
                        style: gfont(AppType.bodyMd,
                            color: hex(routine.$3),
                            weight: FontWeight.w600)),
                  ),
                ),
              const SizedBox(height: 8),
              Text('Set $_setsLeft remaining',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline), size: 10)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: _stopWorkout,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: hex(AppColors.error).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                  color: hex(AppColors.error).withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text('Stop Workout',
                  style: gfont(AppType.bodyMd,
                      color: hex(AppColors.error),
                      weight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _startButton() => GestureDetector(
        onTap: _startRoutine,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: hex(AppColors.signalEmerald).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow,
                  size: 20, color: hex(AppColors.signalEmerald)),
              const SizedBox(width: 8),
              Text('Start Workout',
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
                'Follow guided exercises while watching TV. Pause your show with the button in the app bar, do your reps, then resume. Great for commercial breaks!',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
