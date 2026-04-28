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
  Future<AiProviderConfig?> getAiProviderConfig() async =>
      const AiProviderConfig(
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
  testWidgets('loading screen extracts before analysis when text is empty',
      (tester) async {
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

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
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
    expect(updated.extractedQuestionText,
        service.extractionResult.extractedQuestionText);
  });

  testWidgets(
      'loading screen skips extraction when normalized text already exists',
      (tester) async {
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

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
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

  testWidgets(
      'loading screen stores independent candidate analyses when split result has multiple candidates',
      (tester) async {
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
          aiTags: <String>['第一题标签'],
          knowledgePoints: <String>['第一题知识点'],
          mistakeReason: '第一题错因',
          studyAdvice: '第一题建议',
        ),
        AnalysisResult(
          subject: Subject.math,
          finalAnswer: '第二题答案',
          steps: <String>['第二题步骤'],
          aiTags: <String>['第二题标签'],
          knowledgePoints: <String>['第二题知识点'],
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

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
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
    expect(service.analysisImageCallCount, 0);
    expect(updated!.candidateAnalyses, hasLength(2));
    expect(
        updated.candidateAnalyses.first.analysisResult!.finalAnswer, '第一题答案');
    expect(updated.candidateAnalyses.last.analysisResult!.finalAnswer, '第二题答案');
    expect(updated.savedExercises, isNotEmpty);
    expect(updated.analysisResult?.finalAnswer, '第一题答案');
  });

  testWidgets('loading screen analyzes extracted text without resending image',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '解方程 x^2 - 5x + 6 = 0，求 x 的值。',
        normalizedQuestionText: '解方程 x^2 - 5x + 6 = 0，求 x 的值。',
        subject: Subject.math,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: 'x = 2 或 x = 3',
        steps: <String>['因式分解'],
        aiTags: <String>['一元二次方程'],
        knowledgePoints: <String>['因式分解'],
        mistakeReason: '计算错误',
        studyAdvice: '复习因式分解',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-text-only',
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

    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);
    expect(service.analysisImageCallCount, 0);
  });

  testWidgets('loading screen uses image fallback for visual questions',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '如图，在三角形 ABC 中，求角 A 的度数。',
        normalizedQuestionText: '如图，在三角形 ABC 中，求角 A 的度数。',
        subject: Subject.math,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '角 A = 40°',
        steps: <String>['根据图形条件计算'],
        aiTags: <String>['三角形'],
        knowledgePoints: <String>['内角和'],
        mistakeReason: '漏看图形条件',
        studyAdvice: '标注图中条件',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-image-fallback',
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

    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);
    expect(service.analysisImageCallCount, 1);
  });

  testWidgets('loading screen keeps complete geometry text analysis text-only',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '在 △ABC 中，若 AB=AC，且 ∠A=40°，求 ∠B。',
        normalizedQuestionText: '在 △ABC 中，若 AB=AC，且 ∠A=40°，求 ∠B。',
        subject: Subject.math,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.math,
        finalAnswer: '∠B = 70°',
        steps: <String>['等腰三角形底角相等'],
        aiTags: <String>['等腰三角形'],
        knowledgePoints: <String>['三角形内角和'],
        mistakeReason: '角度关系不清',
        studyAdvice: '画图辅助理解',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-geometry-text-only',
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

    expect(service.extractionCallCount, 1);
    expect(service.analysisCallCount, 1);
    expect(service.analysisImageCallCount, 0);
  });

  testWidgets('loading screen analyzes language worksheet images directly',
      (tester) async {
    final settingsRepo = _TestSettingsRepository();
    final service = TestAiAnalysisService(
      settingsRepository: settingsRepo,
      extractionResult: const AiQuestionExtractionResult(
        extractedQuestionText: '不会被用到',
        normalizedQuestionText: '不会被用到',
        subject: Subject.english,
      ),
      analysisResultValue: const AnalysisResult(
        subject: Subject.english,
        finalAnswer: '按空号逐项解析',
        steps: <String>['分析全文语境'],
        aiTags: <String>['完形填空'],
        knowledgePoints: <String>['语境理解'],
        mistakeReason: '忽略上下文',
        studyAdvice: '通读全文',
      ),
    );

    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    container.read(currentQuestionProvider.notifier).state =
        QuestionRecord.draft(
      id: 'q-language-image',
      imagePath: '/tmp/fake.jpg',
      subject: Subject.english,
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
    expect(service.extractionCallCount, 0);
    expect(service.analysisCallCount, 1);
    expect(service.analysisImageCallCount, 1);
  });

  test('parseExtractionResultForTest attaches fallback split result', () {
    final service = AiAnalysisService.fake();

    final result = service.parseExtractionResultForTest(
        '{"subject":"math","extractedQuestionText":"1. 第一题\\n2. 第二题","normalizedQuestionText":"1. 第一题\\n2. 第二题"}');

    expect(result.splitResult, isNotNull);
    expect(result.splitResult?.strategy, QuestionSplitStrategy.numbered);
    expect(
        result.splitResult?.candidates
            .map((candidate) => candidate.text)
            .toList(),
        <String>['1. 第一题', '2. 第二题']);
  });

  test('parseExtractionResultForTest normalizes malformed latex commands', () {
    final service = AiAnalysisService.fake();

    final result = service.parseExtractionResultForTest(
        '{"subject":"math","extractedQuestionText":"4. 解方程组：begin{cases}x + y = 5 x - y = 1end{cases}\\n6. 在 tri\\angle ABC 中，若 AB=AC，且 angle A=40circ，求 angle B。","normalizedQuestionText":"4. 解方程组：begin{cases}x + y = 5 x - y = 1end{cases}\\n6. 在 tri\\angle ABC 中，若 AB=AC，且 angle A=40circ，求 angle B。"}');

    expect(result.normalizedQuestionText, contains(r'\begin{cases}'));
    expect(result.normalizedQuestionText, contains(r'\end{cases}'));
    expect(result.normalizedQuestionText, contains(r'\triangle'));
    expect(result.normalizedQuestionText, contains(r'\angle A'));
    expect(result.normalizedQuestionText, contains(r'40\circ'));
    expect(result.normalizedQuestionText, isNot(contains('begincases')));
    expect(result.normalizedQuestionText, isNot(contains('tri\\angle')));
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
