import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/exercise_practice_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/notebook_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/question_detail_screen.dart';

QuestionRecord _buildSavedSplitQuestion({
  String id = 'q-batch-1',
  String text = '第一题：已知 x+1=3，求 x',
  int splitOrder = 1,
}) {
  final now = DateTime(2026);
  return QuestionRecord(
    id: id,
    imagePath: '/tmp/q-batch.jpg',
    subject: Subject.math,
    extractedQuestionText: text,
    normalizedQuestionText: text,
    contentFormat: QuestionContentFormat.plain,
    tags: const [],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: 0,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: MasteryLevel.newQuestion,
    analysisResult: const AnalysisResult(
      finalAnswer: 'x=2',
      steps: <String>['移项'],
      aiTags: <String>['一次方程'],
      knowledgePoints: <String>['移项法则'],
      mistakeReason: '符号错误',
      studyAdvice: '注意变号',
      subject: Subject.math,
    ),
    savedExercises: <GeneratedExercise>[
      GeneratedExercise(
        id: 'e-1',
        questionId: id,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: '练习题1',
        answer: 'A',
        explanation: '解析1',
        createdAt: now,
        order: 0,
      ),
    ],
    aiTags: const <String>['一次方程'],
    aiKnowledgePoints: const <String>['移项法则'],
    customTags: const <String>['课堂'],
    parentQuestionId: 'q-batch-root',
    rootQuestionId: 'q-batch-root',
    splitOrder: splitOrder,
  );
}

void main() {
  testWidgets('notebook screen shows saved split question tags and text',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion();
    await repository.saveDraft(question);

    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: Scaffold(body: NotebookScreen())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('第一题：已知 x+1=3，求 x'), findsOneWidget);
    expect(find.text('来自同一拍照批次 · 第 1 题'), findsOneWidget);
    expect(find.text('一次方程'), findsOneWidget);
    expect(find.text('课堂'), findsOneWidget);
  });

  testWidgets(
      'saved split question navigates from notebook to detail to practice',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion();
    await repository.saveDraft(question);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const NotebookScreen(),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, state) {
            final current = container.read(currentQuestionProvider);
            if (current?.id != state.pathParameters['id']) {
              container.read(currentQuestionProvider.notifier).state = question;
            }
            return const QuestionDetailScreen();
          },
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const ExercisePracticeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('第一题：已知 x+1=3，求 x'), findsOneWidget);
    await tester.tap(find.text('第一题：已知 x+1=3，求 x'));
    await tester.pumpAndSettle();

    expect(find.text('错题详情'), findsOneWidget);
    expect(find.text('拍照批次 · 第 1 题'), findsOneWidget);
    expect(find.text('一次方程'), findsOneWidget);
    expect(container.read(currentQuestionProvider)?.id, 'q-batch-1');

    await tester.tap(find.text('继续练习'));
    await tester.pumpAndSettle();

    expect(find.text('举一反三 1/1'), findsOneWidget);
    expect(find.text('练习题1'), findsOneWidget);
  });

  testWidgets(
      'practice completion updates detail answered count for saved split question',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion().copyWith(
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'e-1',
          questionId: 'q-batch-1',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: '练习题1',
          options: const <String>['A. 2', 'B. 3'],
          answer: 'A',
          explanation: '解析1',
          createdAt: DateTime(2026),
          order: 0,
        ),
      ],
    );
    await repository.saveDraft(question);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        settingsRepositoryProvider
            .overrideWithValue(InMemorySettingsRepository()),
        aiAnalysisServiceProvider.overrideWithValue(AiAnalysisService.fake()),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const NotebookScreen(),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, state) {
            final current = container.read(currentQuestionProvider);
            if (current?.id != state.pathParameters['id']) {
              container.read(currentQuestionProvider.notifier).state = question;
            }
            return const QuestionDetailScreen();
          },
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const ExercisePracticeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('第一题：已知 x+1=3，求 x'));
    await tester.pumpAndSettle();
    expect(find.text('0/1 已答'), findsOneWidget);

    await tester.tap(find.text('继续练习'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.text('提交答案'), findsOneWidget);
    await tester.tap(find.text('提交答案'));
    await tester.pumpAndSettle();
    expect(find.text('回答正确'), findsOneWidget);
    expect(find.text('完成练习'), findsOneWidget);
    await tester.tap(find.text('完成练习'));
    await tester.pumpAndSettle();

    final updated = (await repository.getById('q-batch-1'))!;
    container.read(currentQuestionProvider.notifier).state = updated;
    container.read(currentPracticeContextProvider.notifier).state = null;

    router.go('/notebook/question/q-batch-1');
    await tester.pumpAndSettle();

    expect(find.text('1/1 已答'), findsOneWidget);
    expect(
        container.read(currentQuestionProvider)?.savedExercises.first.isCorrect,
        isTrue);

    final saved = await repository.getById('q-batch-1');
    expect(saved?.savedExercises.first.isCorrect, isTrue);
  });
  testWidgets(
      'question detail screen shows candidate-level analysis and exercise entry',
      (tester) async {
    final question = _buildSavedSplitQuestion();
    final container = ProviderContainer(
      overrides: <Override>[
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${question.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const Scaffold(body: Text('NOTEBOOK')),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const Scaffold(body: Text('PRACTICE')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('x=2'), findsOneWidget);
    expect(find.text('移项法则'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('继续练习'), findsOneWidget);

    await tester.tap(find.text('继续练习'));
    await tester.pumpAndSettle();

    expect(find.text('PRACTICE'), findsOneWidget);
    expect(
        container
            .read(currentQuestionProvider)
            ?.savedExercises
            .map((exercise) => exercise.question)
            .toList(),
        <String>['练习题1']);
  });

  testWidgets('question detail screen switches between same batch siblings',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final first = _buildSavedSplitQuestion();
    final second = _buildSavedSplitQuestion(
      id: 'q-batch-2',
      text: '第二题：已知 y-2=0，求 y',
      splitOrder: 2,
    );
    await repository.saveDrafts(<QuestionRecord>[first, second]);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        currentQuestionProvider.overrideWith((ref) => first),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/notebook/question/${first.id}',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const NotebookScreen(),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const QuestionDetailScreen(),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const Scaffold(body: Text('PRACTICE')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('同批题目'), findsOneWidget);
    expect(find.text('第 1 题'), findsOneWidget);
    expect(find.text('第 2 题'), findsOneWidget);
    expect(find.text('第一题：已知 x+1=3，求 x'), findsOneWidget);

    await tester.tap(find.text('第 2 题'));
    await tester.pumpAndSettle();

    expect(container.read(currentQuestionProvider)?.id, 'q-batch-2');
    expect(find.text('第二题：已知 y-2=0，求 y'), findsOneWidget);
  });

  testWidgets('exercise practice screen uses saved split question exercises',
      (tester) async {
    final repository = InMemoryQuestionRepository();
    final question = _buildSavedSplitQuestion();
    await repository.saveDraft(question);

    final container = ProviderContainer(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        currentQuestionProvider.overrideWith((ref) => question),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/exercise/practice',
      routes: <GoRoute>[
        GoRoute(
          path: '/notebook',
          builder: (_, __) => const Scaffold(body: Text('NOTEBOOK')),
        ),
        GoRoute(
          path: '/notebook/question/:id',
          builder: (_, __) => const Scaffold(body: Text('DETAIL')),
        ),
        GoRoute(
          path: '/exercise/practice',
          builder: (_, __) => const ExercisePracticeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    expect(find.text('举一反三 1/1'), findsOneWidget);
    expect(find.text('练习题1'), findsOneWidget);
  });
}
