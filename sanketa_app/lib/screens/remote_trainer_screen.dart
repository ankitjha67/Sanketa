import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanketa_core/sanketa_core.dart' as core;
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';

class _Lesson {
  const _Lesson({
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<_LessonStep> steps;
}

class _LessonStep {
  const _LessonStep({
    required this.instruction,
    required this.buttonLabel,
    this.keyToSend,
    this.launchAction,
  });

  final String instruction;
  final String buttonLabel;
  final core.Key? keyToSend;
  final String? launchAction;
}

class RemoteTrainerScreen extends StatefulWidget {
  const RemoteTrainerScreen({super.key});

  @override
  State<RemoteTrainerScreen> createState() => _RemoteTrainerScreenState();
}

class _RemoteTrainerScreenState extends State<RemoteTrainerScreen> {
  int _lessonIndex = -1;
  int _stepIndex = 0;
  int _completedCount = 0;

  static const _lessons = <_Lesson>[
    _Lesson(
      title: 'Power & Volume',
      description: 'Learn the basic controls',
      icon: Icons.power_settings_new,
      steps: [
        _LessonStep(
          instruction:
              'The Power button turns the TV on or off. Try pressing it now.',
          buttonLabel: 'Power',
          keyToSend: core.Key.power,
        ),
        _LessonStep(
          instruction:
              'Volume Up increases the sound level. Give it a try.',
          buttonLabel: 'Volume Up',
          keyToSend: core.Key.volumeUp,
        ),
        _LessonStep(
          instruction:
              'Volume Down lowers the sound. Press it.',
          buttonLabel: 'Volume Down',
          keyToSend: core.Key.volumeDown,
        ),
        _LessonStep(
          instruction:
              'Mute silences the TV instantly. Very useful during ads!',
          buttonLabel: 'Mute',
          keyToSend: core.Key.mute,
        ),
      ],
    ),
    _Lesson(
      title: 'Navigation',
      description: 'Move around menus',
      icon: Icons.gamepad,
      steps: [
        _LessonStep(
          instruction:
              'Press Up to move the cursor up in menus and lists.',
          buttonLabel: 'Up',
          keyToSend: core.Key.up,
        ),
        _LessonStep(
          instruction:
              'Press Down to move the cursor down.',
          buttonLabel: 'Down',
          keyToSend: core.Key.down,
        ),
        _LessonStep(
          instruction:
              'Press Left and Right to navigate sideways.',
          buttonLabel: 'Left',
          keyToSend: core.Key.left,
        ),
        _LessonStep(
          instruction:
              'OK/Select confirms your choice. Try pressing OK.',
          buttonLabel: 'OK',
          keyToSend: core.Key.ok,
        ),
        _LessonStep(
          instruction:
              'Back returns to the previous screen.',
          buttonLabel: 'Back',
          keyToSend: core.Key.back,
        ),
      ],
    ),
    _Lesson(
      title: 'Home & Menu',
      description: 'Access system menus',
      icon: Icons.home,
      steps: [
        _LessonStep(
          instruction:
              'Home takes you to the TV home screen from anywhere.',
          buttonLabel: 'Home',
          keyToSend: core.Key.home,
        ),
        _LessonStep(
          instruction:
              'Menu opens context options for the current screen.',
          buttonLabel: 'Menu',
          keyToSend: core.Key.menu,
        ),
      ],
    ),
    _Lesson(
      title: 'App Launching',
      description: 'Open apps on the TV',
      icon: Icons.apps,
      steps: [
        _LessonStep(
          instruction:
              'You can launch apps directly from the remote. Try opening Netflix.',
          buttonLabel: 'Launch Netflix',
          launchAction: 'Netflix',
        ),
        _LessonStep(
          instruction:
              'Now try launching YouTube.',
          buttonLabel: 'Launch YouTube',
          launchAction: 'YouTube',
        ),
      ],
    ),
  ];

  void _startLesson(int idx) {
    HapticFeedback.selectionClick();
    setState(() {
      _lessonIndex = idx;
      _stepIndex = 0;
    });
  }

  void _executeStep() {
    final step = _lessons[_lessonIndex].steps[_stepIndex];
    final rc = RemoteScope.of(context);

    if (step.keyToSend != null) {
      rc.key(step.keyToSend!);
    } else if (step.launchAction != null) {
      rc.launch(step.launchAction!);
    }

    HapticFeedback.lightImpact();

    if (_stepIndex + 1 < _lessons[_lessonIndex].steps.length) {
      setState(() => _stepIndex++);
    } else {
      setState(() {
        _completedCount++;
        _lessonIndex = -1;
        _stepIndex = 0;
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(
          content: Text('Lesson complete!'),
          duration: Duration(seconds: 2),
        ));
    }
  }

  void _exitLesson() {
    setState(() {
      _lessonIndex = -1;
      _stepIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: hex(AppColors.surface),
      appBar: AppBar(
        backgroundColor: hex(AppColors.surface),
        foregroundColor: hex(AppColors.onSurface),
        elevation: 0,
        title: Text('Remote Trainer',
            style: gfont(AppType.headlineMd,
                color: hex(AppColors.onSurface),
                size: 18,
                weight: FontWeight.w600)),
        actions: [
          if (_completedCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text('$_completedCount done',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.signalEmerald),
                        weight: FontWeight.w600,
                        size: 11)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_lessonIndex < 0) ...[
            _heroCard(),
            const SizedBox(height: AppSpacing.md),
            _progressCard(),
            const SizedBox(height: AppSpacing.md),
            Text('Lessons (${_lessons.length})',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._lessons.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _lessonCard(e.value, e.key),
                )),
          ] else ...[
            _activeLessonCard(),
          ],
          const SizedBox(height: AppSpacing.lg),
          _infoCard(),
        ],
      ),
    );
  }

  Widget _heroCard() => Container(
        padding:
            const EdgeInsets.symmetric(vertical: 24, horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: hex(AppColors.signalEmerald).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
              color: hex(AppColors.signalEmerald).withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(Icons.school, size: 48, color: hex(AppColors.signalEmerald)),
            const SizedBox(height: 8),
            Text('Learn Your Remote',
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.signalEmerald),
                    weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Interactive lessons to master every remote control feature',
              textAlign: TextAlign.center,
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11),
            ),
          ],
        ),
      );

  Widget _progressCard() => Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress',
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface),
                        weight: FontWeight.w600,
                        size: 12)),
                Text('$_completedCount / ${_lessons.length}',
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
                value: _lessons.isEmpty
                    ? 0
                    : _completedCount / _lessons.length,
                minHeight: 6,
                backgroundColor:
                    hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                valueColor:
                    AlwaysStoppedAnimation<Color>(hex(AppColors.primary)),
              ),
            ),
          ],
        ),
      );

  Widget _lessonCard(_Lesson lesson, int idx) => GestureDetector(
        onTap: () => _startLesson(idx),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hex(AppColors.surfaceContainerLow),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
                color: hex(AppColors.outlineVariant).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: hex(AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(lesson.icon,
                    size: 20, color: hex(AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title,
                        style: gfont(AppType.bodyMd,
                            color: hex(AppColors.onSurface),
                            weight: FontWeight.w600,
                            size: 13)),
                    Text('${lesson.description} · ${lesson.steps.length} steps',
                        style: gfont(AppType.bodySm,
                            color: hex(AppColors.outline), size: 10)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 20, color: hex(AppColors.outline)),
            ],
          ),
        ),
      );

  Widget _activeLessonCard() {
    final lesson = _lessons[_lessonIndex];
    final step = lesson.steps[_stepIndex];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: hex(AppColors.primary).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
                color: hex(AppColors.primary).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(lesson.icon,
                      size: 20, color: hex(AppColors.primary)),
                  const SizedBox(width: 8),
                  Text(lesson.title,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    'Step ${_stepIndex + 1}/${lesson.steps.length}',
                    style: gfont(AppType.bodySm,
                        color: hex(AppColors.outline), size: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.full),
                child: LinearProgressIndicator(
                  value: (_stepIndex + 1) / lesson.steps.length,
                  minHeight: 4,
                  backgroundColor:
                      hex(AppColors.outlineVariant).withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                      hex(AppColors.primary)),
                ),
              ),
              const SizedBox(height: 16),
              Icon(Icons.touch_app, size: 40, color: hex(AppColors.primary)),
              const SizedBox(height: 12),
              Text(
                step.instruction,
                textAlign: TextAlign.center,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w500,
                    size: 14),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _executeStep,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color:
                        hex(AppColors.primary).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                        color: hex(AppColors.primary)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(step.buttonLabel,
                      style: gfont(AppType.bodyMd,
                          color: hex(AppColors.primary),
                          weight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: _exitLesson,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: hex(AppColors.outline).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Center(
              child: Text('Exit Lesson',
                  style: gfont(AppType.bodySm,
                      color: hex(AppColors.outline),
                      weight: FontWeight.w600,
                      size: 11)),
            ),
          ),
        ),
      ],
    );
  }

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
                'Interactive lessons teach you how to use every remote control feature step by step. Each lesson sends real commands to the TV so you can practice.',
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurface), size: 11),
              ),
            ),
          ],
        ),
      );
}
