import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class ExercisePracticeScreen extends ConsumerStatefulWidget {
  const ExercisePracticeScreen({super.key});

  @override
  ConsumerState<ExercisePracticeScreen> createState() => _ExercisePracticeState();
}

class _ExercisePracticeState extends ConsumerState<ExercisePracticeScreen> {
  int _index = 0;
  List<GeneratedExercise>? _exercises;
  String? _questionId;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentQuestionProvider);

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('练习')),
        body: const Center(child: Text('未找到错题记录')),
      );
    }

    // Reset on new question
    if (current.id != _questionId) {
      _index = 0;
      _questionId = current.id;
      _exercises = List.from(current.analysisResult?.generatedExercises ?? []);
    }

    final exercises = _exercises!;
    if (exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('练习')),
        body: const Center(child: Text('暂无练习题')),
      );
    }

    final exercise = exercises[_index];
    final answered = exercise.isCorrect != null;
    final isLast = _index >= exercises.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text('练习 ${_index + 1}/${exercises.length}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Chip(label: Text('难度：${exercise.difficulty}')),
            const SizedBox(height: 16),
            Text(exercise.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: answered
                  ? Column(
                      key: ValueKey(exercise.id),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('答案：${exercise.answer}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(exercise.explanation),
                        const SizedBox(height: 8),
                        Icon(
                          exercise.isCorrect! ? Icons.check_circle : Icons.cancel,
                          color: exercise.isCorrect! ? Colors.green : Colors.red,
                          size: 32,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const Spacer(),
            if (!answered)
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _markResult(exercises, _index, false),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('做错了'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _markResult(exercises, _index, true),
                      child: const Text('做对了'),
                    ),
                  ),
                ],
              )
            else
              FilledButton(
                onPressed: () {
                  if (isLast) {
                    _finish(current, exercises);
                  } else {
                    setState(() => _index++);
                  }
                },
                child: Text(isLast ? '完成' : '下一题'),
              ),
          ],
        ),
      ),
    );
  }

  void _markResult(List<GeneratedExercise> exercises, int index, bool correct) {
    setState(() {
      exercises[index] = exercises[index].copyWith(isCorrect: correct);
    });
  }

  Future<void> _finish(QuestionRecord question, List<GeneratedExercise> exercises) async {
    final updatedAnalysis = question.analysisResult!.copyWith(generatedExercises: exercises);
    final updated = question.copyWith(analysisResult: updatedAnalysis);
    await ref.read(questionRepositoryProvider).update(updated);
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = updated;

    if (!mounted) return;
    final correctCount = exercises.where((e) => e.isCorrect == true).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('练习完成：${exercises.length} 题中答对 $correctCount 题')),
    );
    context.go('/notebook');
  }
}
