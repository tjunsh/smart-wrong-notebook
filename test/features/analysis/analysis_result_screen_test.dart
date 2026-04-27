import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/services/question_split_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_result_screen.dart';

void main() {
  testWidgets('analysis result screen builds with latex content', (tester) async {
    final container = ProviderContainer(
      overrides: <Override>[
        questionSplitServiceProvider.overrideWithValue(const QuestionSplitService()),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state = QuestionRecord.draft(
      id: 'q-latex',
      imagePath: '',
      subject: Subject.math,
      recognizedText: r'已知 $x^2+1=5$，求 x 的值',
    ).copyWith(
      analysisResult: const AnalysisResult(
        finalAnswer: r'$x=\pm2$',
        steps: <String>[r'$x^2=4$', r'$x=\pm2$'],
        aiTags: <String>['方程'],
        knowledgePoints: <String>['平方根'],
        mistakeReason: r'忽略了 $\pm$',
        studyAdvice: r'注意 $a^2=b$ 需要讨论正负两种情况',
      ),
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'e-1',
          questionId: 'q-latex',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'若 $y^2=9$，则 y 的值为？',
          answer: r'$y=\pm3$',
          explanation: r'因为 $y^2=9$，所以 $y=\pm3$',
          createdAt: DateTime(2026),
        ),
      ],
      splitResult: const QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '1. 第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 2,
            text: '2. 第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AnalysisResultScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('AI 解析结果'), findsOneWidget);
    expect(find.byType(AnalysisResultScreen), findsOneWidget);
  });

  testWidgets('analysis result screen switches active split candidate', (tester) async {
    final container = ProviderContainer(
      overrides: <Override>[
        questionSplitServiceProvider.overrideWithValue(const QuestionSplitService()),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state = QuestionRecord.draft(
      id: 'q-switch',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '整题文本',
    ).copyWith(
      analysisResult: const AnalysisResult(
        finalAnswer: '答案',
        steps: <String>['步骤1'],
        aiTags: <String>['方程'],
        knowledgePoints: <String>['代数'],
        mistakeReason: '审题不清',
        studyAdvice: '多练习',
      ),
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'e-1',
          questionId: 'q-switch',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: '练习一',
          answer: 'A',
          explanation: '解释一',
          createdAt: DateTime(2026),
        ),
        GeneratedExercise(
          id: 'e-2',
          questionId: 'q-switch',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question: '练习二',
          answer: 'B',
          explanation: '解释二',
          createdAt: DateTime(2026),
        ),
      ],
      splitResult: const QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '1. 第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 2,
            text: '2. 第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AnalysisResultScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('当前第 1 题'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('练习一'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 2 题'));
    await tester.pumpAndSettle();

    expect(find.textContaining('当前预览'), findsOneWidget);
    expect(find.text('2. 第二题'), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('练习二'), findsOneWidget);
  });

  testWidgets('analysis result screen prefers independent candidate analysis content', (tester) async {
    final container = ProviderContainer(
      overrides: <Override>[
        questionSplitServiceProvider.overrideWithValue(const QuestionSplitService()),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state = QuestionRecord.draft(
      id: 'q-candidate',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '整题文本',
    ).copyWith(
      analysisResult: const AnalysisResult(
        finalAnswer: '整题答案',
        steps: <String>['整题步骤'],
        aiTags: <String>['整题标签'],
        knowledgePoints: <String>['整题知识点'],
        mistakeReason: '整题错因',
        studyAdvice: '整题建议',
      ),
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'e-overall',
          questionId: 'q-candidate',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: '整题练习',
          answer: 'A',
          explanation: '整题解释',
          createdAt: DateTime(2026),
        ),
      ],
      splitResult: const QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '1. 第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 2,
            text: '2. 第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
      candidateAnalyses: <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-0',
          order: 1,
          questionText: '1. 第一题',
          analysisResult: const AnalysisResult(
            finalAnswer: '第一题答案',
            steps: <String>['第一题步骤'],
            aiTags: <String>['一次函数'],
            knowledgePoints: <String>['第一题知识点'],
            mistakeReason: '第一题错因',
            studyAdvice: '第一题建议',
            subject: Subject.math,
          ),
          savedExercises: <GeneratedExercise>[
            GeneratedExercise(
              id: 'e-1',
              questionId: 'q-candidate-1',
              generationMode: ExerciseGenerationMode.practice,
              difficulty: '同级',
              question: '第一题练习',
              answer: 'A',
              explanation: '第一题解释',
              createdAt: DateTime(2026),
            ),
          ],
          aiTags: <String>['一次函数'],
          aiKnowledgePoints: <String>['第一题知识点'],
        ),
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-1',
          order: 2,
          questionText: '2. 第二题',
          analysisResult: const AnalysisResult(
            finalAnswer: '第二题答案',
            steps: <String>['第二题步骤'],
            aiTags: <String>['受力分析'],
            knowledgePoints: <String>['第二题知识点'],
            mistakeReason: '第二题错因',
            studyAdvice: '第二题建议',
            subject: Subject.physics,
          ),
          savedExercises: <GeneratedExercise>[
            GeneratedExercise(
              id: 'e-2',
              questionId: 'q-candidate-2',
              generationMode: ExerciseGenerationMode.practice,
              difficulty: '提高',
              question: '第二题练习',
              answer: 'B',
              explanation: '第二题解释',
              createdAt: DateTime(2026),
            ),
          ],
          aiTags: <String>['受力分析'],
          aiKnowledgePoints: <String>['第二题知识点'],
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: AnalysisResultScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('当前第 1 题'), findsOneWidget);
    expect(find.text('第一题练习'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -2400));
    await tester.pumpAndSettle();
    expect(find.text('第一题练习'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('第 2 题'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -2400));
    await tester.pumpAndSettle();

    expect(find.text('第二题练习'), findsOneWidget);
  });

  testWidgets('analysis result screen navigates to split confirmation when saving', (tester) async {
    final container = ProviderContainer(
      overrides: <Override>[
        questionSplitServiceProvider.overrideWithValue(const QuestionSplitService()),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state = QuestionRecord.draft(
      id: 'q-save',
      imagePath: '',
      subject: Subject.math,
      recognizedText: r'已知 $x^2+1=5$，求 x 的值',
    ).copyWith(
      analysisResult: const AnalysisResult(
        finalAnswer: r'$x=\pm2$',
        steps: <String>[r'$x^2=4$'],
        aiTags: <String>['方程'],
        knowledgePoints: <String>['平方根'],
        mistakeReason: r'忽略了 $\pm$',
        studyAdvice: r'注意分类讨论',
      ),
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'e-save',
          questionId: 'q-save',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'若 $y^2=9$，则 y 的值为？',
          answer: r'$y=\pm3$',
          explanation: r'因为 $y^2=9$，所以 $y=\pm3$',
          createdAt: DateTime(2026),
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: '/analysis/result',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const AnalysisResultScreen(),
        ),
        GoRoute(
          path: '/capture/split-confirmation',
          builder: (_, __) => const Scaffold(body: Text('SPLIT_CONFIRMATION')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(find.text('保存到错题本'), findsOneWidget);
    await tester.tap(find.text('保存到错题本'));
    await tester.pumpAndSettle();

    expect(find.text('SPLIT_CONFIRMATION'), findsOneWidget);
    expect(container.read(currentQuestionSplitSessionProvider), isNotNull);
  });
}
