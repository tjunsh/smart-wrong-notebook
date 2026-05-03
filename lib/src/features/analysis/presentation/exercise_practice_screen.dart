import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';

class ExercisePracticeScreen extends ConsumerStatefulWidget {
  const ExercisePracticeScreen({super.key});

  @override
  ConsumerState<ExercisePracticeScreen> createState() =>
      _ExercisePracticeState();
}

class _ExercisePracticeState extends ConsumerState<ExercisePracticeScreen> {
  int _index = 0;
  List<GeneratedExercise>? _exercises;
  String? _questionId;
  bool _isJudging = false;

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentQuestionProvider);
    final practiceContext = ref.watch(currentPracticeContextProvider);
    final returnRoute = practiceContext?.returnRoute;
    final fallbackRoute = returnRoute ?? '/notebook';
    if (current == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('练习'),
            leading: IconButton(
                icon: const Icon(CupertinoIcons.chevron_left),
                onPressed: () => context.go(fallbackRoute))),
        body: const Center(child: Text('未找到错题记录')),
      );
    }

    if (current.id != _questionId || _exercises == null) {
      _index = 0;
      _questionId = current.id;
      _exercises = List.from(_practiceExercises(current, practiceContext));
    }

    final exercises = _exercises!;
    if (exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('举一反三'),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_left),
            onPressed: () =>
                context.go(returnRoute ?? '/notebook/question/${current.id}'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(CupertinoIcons.question,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              const Text('暂无练习题', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context
                    .go(returnRoute ?? '/notebook/question/${current.id}'),
                child: Text(returnRoute == null ? '返回错题详情' : '返回解析'),
              ),
            ],
          ),
        ),
      );
    }

    final exercise = exercises[_index];
    final answered = exercise.isCorrect != null;
    final isCorrect = exercise.isCorrect == true;
    final isLast = _index >= exercises.length - 1;
    final answeredCount = exercises.where((e) => e.isCorrect != null).length;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('举一反三 ${_index + 1}/${exercises.length}'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark),
          onPressed: () => context.go(fallbackRoute),
        ),
      ),
      body: Column(
        children: <Widget>[
          LinearProgressIndicator(
            value: answeredCount / exercises.length,
            backgroundColor: colorScheme.outlineVariant,
            minHeight: 3,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _difficultyColor(context, exercise.difficulty)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                _difficultyColor(context, exercise.difficulty)
                                    .withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        exercise.difficulty,
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                _difficultyColor(context, exercise.difficulty),
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Spacer(),
                    Text('$answeredCount/${exercises.length} 已答',
                        style: TextStyle(
                            fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.12 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('第 ${_index + 1} 题',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      MathContentView(exercise.question,
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (exercise.options != null && exercise.options!.isNotEmpty)
                  ...exercise.options!.asMap().entries.map((entry) {
                    final parsedOption = _parseOption(entry.value);
                    final optionLetter = parsedOption.label;
                    final optionText = parsedOption.content;
                    final isSelected = exercise.userAnswer == optionLetter;
                    final isCorrectAnswer = exercise.answer == optionLetter;

                    Color? borderColor;
                    Color? bgColor;
                    Color? textColor;

                    if (answered) {
                      if (isCorrectAnswer) {
                        borderColor = const Color(0xFF16A34A);
                        bgColor = isDark
                            ? const Color(0xFF16A34A).withValues(alpha: 0.16)
                            : const Color(0xFFF0FDF4);
                        textColor = isDark
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF166534);
                      } else if (isSelected && !isCorrect) {
                        borderColor = const Color(0xFFEA580C);
                        bgColor = isDark
                            ? const Color(0xFFEA580C).withValues(alpha: 0.16)
                            : const Color(0xFFFFF7ED);
                        textColor = isDark
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF9A3412);
                      }
                    } else if (isSelected) {
                      borderColor = const Color(0xFF6366F1);
                      bgColor = isDark
                          ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                          : const Color(0xFFEEF2FF);
                      textColor = isDark
                          ? const Color(0xFF818CF8)
                          : const Color(0xFF4338CA);
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap:
                            answered ? null : () => _selectOption(optionLetter),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bgColor ?? colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    borderColor ?? colorScheme.outlineVariant),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected ||
                                          (answered && isCorrectAnswer)
                                      ? (borderColor ?? const Color(0xFF6366F1))
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    optionLetter,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ||
                                              (answered && isCorrectAnswer)
                                          ? Colors.white
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MathContentView(
                                  optionText,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          textColor ?? colorScheme.onSurface),
                                ),
                              ),
                              if (answered && isCorrectAnswer)
                                const Icon(CupertinoIcons.checkmark_circle,
                                    color: Color(0xFF16A34A), size: 20)
                              else if (answered && isSelected && !isCorrect)
                                const Icon(CupertinoIcons.xmark_circle,
                                    color: Color(0xFFEA580C), size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                else
                  const SizedBox.shrink(),
                if (answered) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? (isDark
                              ? const Color(0xFF16A34A).withValues(alpha: 0.16)
                              : const Color(0xFFF0FDF4))
                          : (isDark
                              ? const Color(0xFFEA580C).withValues(alpha: 0.16)
                              : const Color(0xFFFFF7ED)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isCorrect
                              ? (isDark
                                  ? const Color(0xFF16A34A)
                                      .withValues(alpha: 0.35)
                                  : const Color(0xFFBBF7D0))
                              : (isDark
                                  ? const Color(0xFFEA580C)
                                      .withValues(alpha: 0.35)
                                  : const Color(0xFFFED7AA))),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(
                              isCorrect
                                  ? CupertinoIcons.checkmark_circle
                                  : CupertinoIcons.xmark_circle,
                              color: isCorrect
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFEA580C),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isCorrect ? '回答正确' : '回答错误',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? (isDark
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF166534))
                                    : (isDark
                                        ? const Color(0xFFEA580C)
                                        : const Color(0xFF9A3412)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        MathContentView(
                          '正确答案：${exercise.answer}',
                          style: TextStyle(
                              fontSize: 14, color: colorScheme.onSurface),
                        ),
                        if (exercise.explanation.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          MathContentView(
                            exercise.explanation,
                            style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: answered
                  ? FilledButton.icon(
                      onPressed: () {
                        if (isLast) {
                          _finish(current, exercises);
                        } else {
                          setState(() => _index++);
                        }
                      },
                      icon: Icon(isLast
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.arrow_right),
                      label: Text(isLast ? '完成练习' : '下一题'),
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48)),
                    )
                  : _isJudging
                      ? const Center(child: CircularProgressIndicator())
                      : FilledButton.icon(
                          onPressed: exercise.userAnswer != null
                              ? () => _submitAnswer(exercises, _index)
                              : null,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48)),
                          icon: const Icon(CupertinoIcons.checkmark),
                          label: const Text('提交答案'),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  List<GeneratedExercise> _practiceExercises(
    QuestionRecord current,
    PracticeContext? practiceContext,
  ) {
    final candidateId = practiceContext?.candidateId;
    if (candidateId == null) return current.savedExercises;

    for (final candidate in current.candidateAnalyses) {
      if (candidate.candidateId == candidateId) {
        return candidate.savedExercises;
      }
    }
    return current.savedExercises;
  }

  Color _difficultyColor(BuildContext context, String difficulty) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (difficulty) {
      case '简单':
        return const Color(0xFF16A34A);
      case '中等':
        return const Color(0xFFD97706);
      case '困难':
        return const Color(0xFFDC2626);
      case '提高':
        return const Color(0xFF7C3AED);
      case '同级':
        return const Color(0xFF2563EB);
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  _ParsedOption _parseOption(String option) {
    final match = RegExp(r'^\s*([A-Za-z])\s*[\.、:：\)]\s*(.*)$', dotAll: true)
        .firstMatch(option);
    if (match == null) {
      final fallbackLabel = option.trim().isNotEmpty
          ? option.trim().substring(0, 1).toUpperCase()
          : '?';
      return _ParsedOption(label: fallbackLabel, content: option.trim());
    }

    return _ParsedOption(
      label: match.group(1)!.toUpperCase(),
      content: (match.group(2) ?? '').trim(),
    );
  }

  void _selectOption(String optionLetter) {
    setState(() {
      _exercises![_index] =
          _exercises![_index].copyWith(userAnswer: optionLetter);
    });
  }

  void _submitAnswer(List<GeneratedExercise> exercises, int index) async {
    final exercise = exercises[index];
    if (exercise.userAnswer == null) return;

    setState(() => _isJudging = true);

    final isCorrect = await _judgeAnswer(exercise);

    setState(() {
      exercises[index] = exercises[index].copyWith(isCorrect: isCorrect);
      _isJudging = false;
    });
  }

  Future<bool> _judgeAnswer(GeneratedExercise exercise) async {
    final current = ref.read(currentQuestionProvider);
    if (current?.analysisResult == null) {
      return exercise.userAnswer == exercise.answer;
    }

    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final config = await settingsRepo.getAiProviderConfig();

      if (config == null ||
          config.baseUrl.isEmpty ||
          config.apiKey.isEmpty ||
          config.model.isEmpty) {
        return exercise.userAnswer == exercise.answer;
      }

      final service = ref.read(aiAnalysisServiceProvider);
      final isCorrect = await service.judgeAnswer(
        question: exercise.question,
        userAnswer: exercise.userAnswer!,
        correctAnswer: exercise.answer,
        options: exercise.options,
      );
      return isCorrect;
    } catch (e) {
      debugPrint(
          '[ExercisePractice] AI judgment failed: $e, fallback to direct compare');
      return exercise.userAnswer == exercise.answer;
    }
  }

  Future<void> _finish(
      QuestionRecord question, List<GeneratedExercise> exercises) async {
    final practiceContext = ref.read(currentPracticeContextProvider);
    final updated = practiceContext?.source == PracticeContextSource.analysis
        ? _updateAnalysisPracticeState(question, exercises, practiceContext)
        : question.copyWith(savedExercises: exercises);

    if (practiceContext?.source == PracticeContextSource.analysis) {
      ref.read(currentQuestionProvider.notifier).state = updated;
    } else {
      await ref.read(questionRepositoryProvider).update(updated);
      invalidateQuestionList(ref);
      ref.read(currentQuestionProvider.notifier).state = updated;
      ref.read(currentPracticeContextProvider.notifier).state = null;
    }

    if (!mounted) return;
    final correctCount = exercises.where((e) => e.isCorrect == true).length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('练习完成：${exercises.length} 题中答对 $correctCount 题')),
    );
    context.go(practiceContext?.returnRoute ?? '/notebook');
  }

  QuestionRecord _updateAnalysisPracticeState(
    QuestionRecord question,
    List<GeneratedExercise> exercises,
    PracticeContext? practiceContext,
  ) {
    final candidateId = practiceContext?.candidateId;
    if (candidateId == null || question.candidateAnalyses.isEmpty) {
      return question.copyWith(savedExercises: exercises);
    }

    return question.copyWith(
      candidateAnalyses: question.candidateAnalyses.map((candidate) {
        if (candidate.candidateId != candidateId) return candidate;
        return candidate.copyWith(savedExercises: exercises);
      }).toList(),
    );
  }
}

class _ParsedOption {
  const _ParsedOption({required this.label, required this.content});

  final String label;
  final String content;
}
