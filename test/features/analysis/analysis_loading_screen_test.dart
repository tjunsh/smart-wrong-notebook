import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_loading_screen.dart';

class _TestSettingsRepository implements SettingsRepository {
  @override
  Future<AiProviderConfig?> getAiProviderConfig() async => const AiProviderConfig(
        id: 'test',
        displayName: 'Test',
        baseUrl: 'https://api.test.com',
        model: 'test-model',
        apiKey: 'test-key',
      );

  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {}

  @override
  Future<void> setString(String key, String value) async {}
}

void main() {
  testWidgets('loading screen extracts before analysis when text is empty', (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '原始题目文本',
        normalizedQuestionText: '整理后的题目文本',
        subject: Subject.physics,
        splitResult: QuestionSplitResult(
          sourceText: '整理后的题目文本',
          strategy: QuestionSplitStrategy.fallback,
          candidates: <QuestionSplitCandidate>[
            QuestionSplitCandidate(
              id: 'candidate-0',
              order: 1,
              text: '整理后的题目文本',
              strategy: QuestionSplitStrategy.fallback,
            ),
          ],
        ),
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.physics,
        finalAnswer: '答案',
        steps: <String>['步骤1'],
        aiTags: <String>['电学'],
        knowledgePoints: <String>['欧姆定律'],
        mistakeReason: '审题不清',
        studyAdvice: '复习公式',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state = QuestionRecord.draft(
      id: 'q-1',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RESULT_SCREEN'), findsOneWidget);
    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);

    final updated = container.read(currentQuestionProvider);
    expect(updated, isNotNull);
    expect(updated!.subject, Subject.physics);
    expect(updated.extractedQuestionText, '原始题目文本');
    expect(updated.normalizedQuestionText, '整理后的题目文本');
    expect(updated.splitResult, isNotNull);
    expect(updated.splitResult?.strategy, QuestionSplitStrategy.fallback);
    expect(updated.contentStatus, ContentStatus.ready);
    expect(updated.analysisResult?.finalAnswer, '答案');
    expect(updated.extractedQuestionText, service.extractionResult.extractedQuestionText);
  });

  testWidgets('loading screen skips extraction when normalized text already exists', (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '不会被用到',
        normalizedQuestionText: '不会被用到',
        subject: Subject.physics,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: 'x = 3',
        steps: <String>['移项'],
        aiTags: <String>['方程'],
        knowledgePoints: <String>['一元一次方程'],
        mistakeReason: '粗心',
        studyAdvice: '多练习',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state = QuestionRecord.draft(
      id: 'q-2',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '已确认文本',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('RESULT_SCREEN'), findsOneWidget);
    expect(service.extractionCallCount, 0);
    expect(service.analysisCallCount, 1);

    final updated = container.read(currentQuestionProvider);
    expect(updated, isNotNull);
    expect(updated!.normalizedQuestionText, '已确认文本');
    expect(updated.contentStatus, ContentStatus.ready);
    expect(updated.analysisResult?.finalAnswer, 'x = 3');
  });

  testWidgets('loading screen stores independent candidate analyses when split result has multiple candidates', (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '1. 第一题\n2. 第二题',
        normalizedQuestionText: '1. 第一题\n2. 第二题',
        subject: Subject.math,
        splitResult: QuestionSplitResult(
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
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '默认答案',
        steps: <String>['默认步骤'],
        aiTags: <String>['默认标签'],
        knowledgePoints: <String>['默认知识点'],
        mistakeReason: '默认错因',
        studyAdvice: '默认建议',
      ),
      candidateAnalysisResults: const <AnalysisResult>[
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第一题答案',
          steps: <String>['第一题步骤'],
          aiTags: <String>['一次函数'],
          knowledgePoints: <String>['代数一'],
          mistakeReason: '第一题错因',
          studyAdvice: '第一题建议',
        ),
        AnalysisResult(
          subject: Subject.physics,
          finalAnswer: '第二题答案',
          steps: <String>['第二题步骤'],
          aiTags: <String>['受力分析'],
          knowledgePoints: <String>['力学二'],
          mistakeReason: '第二题错因',
          studyAdvice: '第二题建议',
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state = QuestionRecord.draft(
      id: 'q-multi',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.math,
      recognizedText: '',
    );

    final router = GoRouter(
      initialLocation: '/analysis/loading',
      routes: <GoRoute>[
        GoRoute(
          path: '/analysis/loading',
          builder: (_, __) => const AnalysisLoadingScreen(),
        ),
        GoRoute(
          path: '/analysis/result',
          builder: (_, __) => const Scaffold(body: Text('RESULT_SCREEN')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    final updated = container.read(currentQuestionProvider);
    expect(updated, isNotNull);
    expect(service.analysisCallCount, 2);
    expect(updated!.candidateAnalyses.length, 2);
    expect(updated.candidateAnalyses.first.analysisResult?.finalAnswer, '第一题答案');
    expect(updated.candidateAnalyses.last.analysisResult?.finalAnswer, '第二题答案');
    expect(updated.savedExercises, isNotEmpty);
    expect(updated.analysisResult?.finalAnswer, '第一题答案');
  });

  test('parseExtractionResultForTest attaches fallback split result', () {
    final service = AiAnalysisService.fake();

    final result = service.parseExtractionResultForTest('{"subject":"math","extractedQuestionText":"1. 第一题\\n2. 第二题","normalizedQuestionText":"1. 第一题\\n2. 第二题"}');

    expect(result.splitResult, isNotNull);
    expect(result.splitResult?.strategy, QuestionSplitStrategy.numbered);
    expect(result.splitResult?.candidates.map((candidate) => candidate.text).toList(), <String>['1. 第一题', '2. 第二题']);
  });

  test('fake extraction attaches split result', () async {
    final service = AiAnalysisService.fake();

    final result = await service.extractQuestionStructure(
      subjectName: 'math',
      imagePath: '/tmp/fake.jpg',
      textHint: '1. 第一题\n2. 第二题',
    );

    expect(result.splitResult, isNotNull);
    expect(result.splitResult?.strategy, QuestionSplitStrategy.numbered);
  });
}
