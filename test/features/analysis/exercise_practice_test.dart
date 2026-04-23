import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/exercise_practice_screen.dart';

QuestionRecord _makeQuestion({List<GeneratedExercise>? exercises}) {
  final now = DateTime.now();
  return QuestionRecord(
    id: 'q-1',
    imagePath: '/tmp/q-1.jpg',
    subject: Subject.math,
    recognizedText: 'sample',
    correctedText: 'corrected',
    tags: const [],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: 0,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: MasteryLevel.newQuestion,
    analysisResult: AnalysisResult(
      finalAnswer: '42',
      steps: const ['step1'],
      aiTags: const [],
      knowledgePoints: const ['math'],
      mistakeReason: 'careless',
      studyAdvice: 'practice',
      generatedExercises: exercises ?? const [
        GeneratedExercise(id: 'e-1', difficulty: '简单', question: '1+1=?', answer: '2', explanation: 'basic addition'),
        GeneratedExercise(id: 'e-2', difficulty: '中等', question: '2+2=?', answer: '4', explanation: 'basic addition'),
      ],
    ),
  );
}

Widget _buildApp(QuestionRecord question, InMemoryQuestionRepository repo, {GoRouter? router}) {
  return ProviderScope(
    overrides: <Override>[
      questionRepositoryProvider.overrideWithValue(repo),
      currentQuestionProvider.overrideWith((ref) => question),
    ],
    child: router != null
        ? MaterialApp.router(routerConfig: router)
        : const MaterialApp(home: ExercisePracticeScreen()),
  );
}

void main() {
  testWidgets('displays first exercise on load', (tester) async {
    final repo = InMemoryQuestionRepository();
    final question = _makeQuestion();
    await repo.saveDraft(question);

    await tester.pumpWidget(_buildApp(question, repo));
    await tester.pumpAndSettle();

    expect(find.text('举一反三 1/2'), findsOneWidget);
    expect(find.text('1+1=?'), findsOneWidget);
    expect(find.text('做错了'), findsOneWidget);
    expect(find.text('做对了'), findsOneWidget);
  });

  testWidgets('shows answer after marking correct', (tester) async {
    final repo = InMemoryQuestionRepository();
    final question = _makeQuestion();
    await repo.saveDraft(question);

    await tester.pumpWidget(_buildApp(question, repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('做对了'));
    await tester.pumpAndSettle();

    expect(find.text('答案：2'), findsOneWidget);
    expect(find.text('下一题'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('persists isCorrect to repository on finish', (tester) async {
    final repo = InMemoryQuestionRepository();
    final question = _makeQuestion();
    await repo.saveDraft(question);

    final router = GoRouter(
      initialLocation: '/exercise/practice',
      routes: <RouteBase>[
        GoRoute(path: '/exercise/practice', builder: (_, __) => const ExercisePracticeScreen()),
        GoRoute(path: '/notebook', builder: (_, __) => const Scaffold(body: Center(child: Text('notebook')))),
      ],
    );

    await tester.pumpWidget(_buildApp(question, repo, router: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('做对了'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('下一题'));
    await tester.pumpAndSettle();

    expect(find.text('举一反三 2/2'), findsOneWidget);
    expect(find.text('2+2=?'), findsOneWidget);

    await tester.tap(find.text('做错了'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('完成练习'));
    await tester.pumpAndSettle();

    final saved = await repo.getById('q-1');
    expect(saved!.analysisResult!.generatedExercises[0].isCorrect, true);
    expect(saved.analysisResult!.generatedExercises[1].isCorrect, false);
  });
}
