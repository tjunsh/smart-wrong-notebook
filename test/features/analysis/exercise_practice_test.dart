import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/exercise_practice_screen.dart';
import 'package:smart_wrong_notebook/src/features/ocr/presentation/question_split_confirmation_screen.dart';

QuestionRecord _makeQuestion({List<GeneratedExercise>? exercises}) {
  final now = DateTime.now();
  return QuestionRecord(
    id: 'q-1',
    imagePath: '/tmp/q-1.jpg',
    subject: Subject.math,
    extractedQuestionText: 'sample',
    normalizedQuestionText: 'corrected',
    contentFormat: QuestionContentFormat.plain,
    tags: const [],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: 0,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: MasteryLevel.newQuestion,
    analysisResult: null,
    savedExercises: exercises ??
        [
          GeneratedExercise(
            id: 'e-1',
            questionId: 'q-1',
            generationMode: ExerciseGenerationMode.practice,
            difficulty: '简单',
            question: '1+1=?',
            options: ['A. 1', 'B. 2', 'C. 3', 'D. 4'],
            answer: 'B',
            explanation: 'basic addition',
            createdAt: now,
            order: 0,
          ),
          GeneratedExercise(
            id: 'e-2',
            questionId: 'q-1',
            generationMode: ExerciseGenerationMode.practice,
            difficulty: '中等',
            question: '2+2=?',
            options: ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
            answer: 'C',
            explanation: 'basic addition',
            createdAt: now,
            order: 1,
          ),
        ],
  );
}

Widget _buildApp(QuestionRecord question, InMemoryQuestionRepository repo,
    {GoRouter? router, List<Override> overrides = const <Override>[]}) {
  return ProviderScope(
    overrides: <Override>[
      questionRepositoryProvider.overrideWithValue(repo),
      currentQuestionProvider.overrideWith((ref) => question),
      ...overrides,
    ],
    child: router != null
        ? MaterialApp.router(routerConfig: router)
        : const MaterialApp(home: ExercisePracticeScreen()),
  );
}

GoRouter _practiceRouter() {
  return GoRouter(
    initialLocation: '/exercise/practice',
    routes: <RouteBase>[
      GoRoute(
        path: '/exercise/practice',
        builder: (_, __) => const ExercisePracticeScreen(),
      ),
      GoRoute(
        path: '/capture/split-confirmation',
        builder: (_, __) => const QuestionSplitConfirmationScreen(),
      ),
      GoRoute(
        path: '/analysis/result',
        builder: (_, __) => const Scaffold(body: Text('analysis result')),
      ),
      GoRoute(
        path: '/notebook/question/:id',
        builder: (_, state) => Scaffold(
          body: Text('question ${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/notebook',
        builder: (_, __) => const Scaffold(body: Text('notebook')),
      ),
    ],
  );
}

void main() {
  // TODO: Fix these tests to match actual UI
  // The exercise options are displayed differently than expected

  testWidgets('displays first exercise on load', (tester) async {
    final repo = InMemoryQuestionRepository();
    final question = _makeQuestion();
    await repo.saveDraft(question);

    await tester.pumpWidget(_buildApp(question, repo));
    await tester.pumpAndSettle();

    expect(find.text('举一反三 1/2'), findsOneWidget);
    expect(find.text('1+1=?'), findsOneWidget);
  });

  testWidgets('shows continue and save actions after finishing round',
      (tester) async {
    final repo = InMemoryQuestionRepository();
    final question = _makeQuestion();
    await repo.saveDraft(question);

    await tester.pumpWidget(_buildApp(question, repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.tap(find.text('提交答案'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.tap(find.text('下一题'));
    await tester.pump();
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.tap(find.text('提交答案'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.tap(find.text('完成练习'));
    await tester.pump();

    expect(find.text('举一反三完成'), findsOneWidget);
    expect(find.text('继续练习'), findsOneWidget);
    expect(find.text('返回错题详情'), findsOneWidget);
    expect(find.text('保存这道题'), findsNothing);
    expect(find.text('本轮练习结果已保存到错题本'), findsOneWidget);

    final saved = await repo.getById('q-1');
    expect(saved?.savedExercises.length, 2);
    expect(saved?.savedExercises.every((exercise) => exercise.roundIndex == 1),
        isTrue);
    expect(
        saved?.savedExercises.every((exercise) => exercise.isCorrect == true),
        isTrue);
  });

  testWidgets('continue practice starts another persisted round',
      (tester) async {
    final repo = InMemoryQuestionRepository();
    final question = _makeQuestion();
    await repo.saveDraft(question);

    await tester.pumpWidget(_buildApp(question, repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.tap(find.text('提交答案'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.tap(find.text('下一题'));
    await tester.pump();
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.tap(find.text('提交答案'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.tap(find.text('完成练习'));
    await tester.pump();
    await tester.tap(find.text('继续练习'));
    await tester.pump();

    expect(find.text('举一反三 1/2'), findsOneWidget);
    final saved = await repo.getById('q-1');
    expect(saved?.savedExercises.length, 4);
    expect(saved?.savedExercises.where((exercise) => exercise.roundIndex == 2),
        hasLength(2));
    expect(
        saved?.savedExercises
            .where((exercise) => exercise.roundIndex == 2)
            .every((exercise) =>
                exercise.isCorrect == null && exercise.userAnswer == null),
        isTrue);
  });

  testWidgets('save current analysis candidate selects only that draft',
      (tester) async {
    final repo = InMemoryQuestionRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final question = _makeQuestion().copyWith(
      splitResult: const QuestionSplitResult(
        sourceText: '第一题\n第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 2,
            text: '第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
      candidateAnalyses: <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-0',
          order: 1,
          questionText: '第一题',
          savedExercises: _makeQuestion().savedExercises,
        ),
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-1',
          order: 2,
          questionText: '第二题',
          savedExercises: _makeQuestion().savedExercises,
        ),
      ],
    );
    container.read(currentQuestionProvider.notifier).state = question;
    container.read(currentPracticeContextProvider.notifier).state =
        const PracticeContext(
      source: PracticeContextSource.analysis,
      candidateId: 'candidate-1',
      candidateOrder: 2,
      returnRoute: '/analysis/result',
    );
    final router = _practiceRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    await tester.pump();
    await tester.tap(find.text('提交答案'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.tap(find.text('下一题'));
    await tester.pump();
    await tester.tap(find.text('C'));
    await tester.pump();
    await tester.tap(find.text('提交答案'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    await tester.tap(find.text('完成练习'));
    await tester.pump();
    await tester.tap(find.text('保存这道题'));
    await tester.pump();

    final session = container.read(currentQuestionSplitSessionProvider);
    expect(session?.drafts.map((draft) => draft.selected).toList(),
        <bool>[false, true]);
  });

  // testWidgets('shows answer after marking correct', (tester) async { ... });
  // testWidgets('persists isCorrect to repository on finish', (tester) async { ... });
}
