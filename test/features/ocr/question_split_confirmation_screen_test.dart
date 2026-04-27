import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_session.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/ocr/presentation/question_split_confirmation_screen.dart';

void main() {
  testWidgets('split confirmation screen saves selected questions', (tester) async {
    final repository = InMemoryQuestionRepository();
    final container = ProviderContainer(
      overrides: [questionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final source = QuestionRecord.draft(
      id: 'q-batch',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '原始整题',
    ).copyWith(
      analysisResult: const AnalysisResult(
        finalAnswer: '答案',
        steps: <String>['步骤1'],
        aiTags: <String>['方程'],
        knowledgePoints: <String>['代数'],
        mistakeReason: '审题不清',
        studyAdvice: '多复习',
      ),
      candidateAnalyses: <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-0',
          order: 1,
          questionText: '第一题：已知 x+1=3，求 x',
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
              questionId: 'q-batch-1',
              generationMode: ExerciseGenerationMode.practice,
              difficulty: '同级',
              question: '练习题1',
              answer: 'A',
              explanation: '解析1',
              createdAt: DateTime(2026),
            ),
          ],
          aiTags: <String>['一次方程'],
          aiKnowledgePoints: <String>['移项法则'],
        ),
      ],
    );

    container.read(currentQuestionSplitSessionProvider.notifier).state = QuestionSplitSession(
      source: source,
      strategy: QuestionSplitStrategy.fallback,
      drafts: const <QuestionSplitDraft>[
        QuestionSplitDraft(id: 'd-1', text: '第一题：已知 x+1=3，求 x', selected: true),
        QuestionSplitDraft(id: 'd-2', text: '第二题：求 y=2x 的值', selected: false),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: QuestionSplitConfirmationScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('逐题确认后保存'), findsOneWidget);
    expect(find.text('题目列表'), findsOneWidget);
    expect(find.text('当前题目内容'), findsOneWidget);

    container.read(questionRepositoryProvider).saveDrafts([
      buildSplitQuestionRecord(
        source: source,
        draft: const QuestionSplitDraft(id: 'd-1', text: '第一题：已知 x+1=3，求 x', selected: true),
        sortOrder: 1,
      ),
    ]);
    container.read(currentQuestionSplitSessionProvider.notifier).state = null;

    final saved = await repository.listAll();
    expect(saved.length, 1);
    expect(saved.first.correctedText, '第一题：已知 x+1=3，求 x');
    expect(saved.first.analysisResult?.finalAnswer, 'x=2');
    expect(saved.first.aiTags, <String>['一次方程']);
    expect(saved.first.aiKnowledgePoints, <String>['移项法则']);
    expect(saved.first.savedExercises.map((exercise) => exercise.question).toList(), <String>['练习题1']);
    expect(container.read(currentQuestionSplitSessionProvider), isNull);
  });

  testWidgets('split confirmation screen shows editor for unselected draft', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(currentQuestionSplitSessionProvider.notifier).state = QuestionSplitSession(
      source: QuestionRecord.draft(
        id: 'q-empty',
        imagePath: '',
        subject: Subject.math,
        recognizedText: '原始整题',
      ),
      strategy: QuestionSplitStrategy.fallback,
      drafts: const <QuestionSplitDraft>[
        QuestionSplitDraft(id: 'd-1', text: '第一题', selected: false),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: QuestionSplitConfirmationScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('题目列表'), findsOneWidget);
    expect(find.text('当前题目内容'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
