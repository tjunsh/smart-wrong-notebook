import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/capture_entry_sheet.dart';
import 'package:smart_wrong_notebook/src/features/home/presentation/home_screen.dart';
import 'package:smart_wrong_notebook/src/features/notebook/presentation/notebook_screen.dart';
import 'package:smart_wrong_notebook/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:smart_wrong_notebook/src/features/ocr/presentation/question_save_confirmation_screen.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_screen.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/settings_screen.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

final _inMemRepo = InMemoryQuestionRepository();

final _repoOverride = questionRepositoryProvider.overrideWithValue(_inMemRepo);
final _settingsOverride =
    settingsRepositoryProvider.overrideWithValue(_InMemSettingsRepo());

class _InMemSettingsRepo implements SettingsRepository {
  @override
  Future<AiProviderConfig?> getAiProviderConfig() async => null;

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {}

  @override
  Future<String?> getString(String key) async {
    if (key == 'onboarding_done') return 'true';
    return null;
  }

  @override
  Future<void> setString(String key, String value) async {}
}

void main() {
  group('MVP smoke tests', () {
    testWidgets('app boots to home screen with default content',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride, _settingsOverride],
        child: const MaterialApp(home: HomeScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('开始拍错题'), findsOneWidget);
      expect(find.text('最近新增'), findsOneWidget);
    });

    testWidgets('user can tap camera button and see capture sheet',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride, _settingsOverride],
        child: const MaterialApp(home: HomeScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('拍照录题'));
      await tester.pumpAndSettle();

      expect(find.text('拍照'), findsOneWidget);
      expect(find.text('相册'), findsOneWidget);
    });

    testWidgets('settings screen shows all required entries', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride, _settingsOverride],
        child: const MaterialApp(home: SettingsScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('外观'), findsOneWidget);
      expect(find.text('系统'), findsOneWidget);
      expect(find.text('浅色'), findsOneWidget);
      expect(find.text('深色'), findsOneWidget);
      expect(find.text('复习提醒'), findsOneWidget);
      expect(find.text('AI 服务'), findsOneWidget);
      expect(find.text('内容'), findsOneWidget);
    });

    testWidgets('notebook screen shows search and add icons', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride, _settingsOverride],
        child: const MaterialApp(home: Scaffold(body: NotebookScreen())),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.search), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.camera), findsOneWidget);
    });

    testWidgets('review screen shows today review section', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride, _settingsOverride],
        child: const MaterialApp(home: ReviewScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('待复习 0'), findsOneWidget);
    });

    testWidgets('capture entry sheet has camera and gallery options',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride, _settingsOverride],
        child: const MaterialApp(
          home: Scaffold(body: CaptureEntrySheet()),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('拍照'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.camera), findsOneWidget);
      expect(find.text('相册'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.photo), findsOneWidget);
    });

    testWidgets('save confirmation screen shows editable extracted text',
        (tester) async {
      final container =
          ProviderContainer(overrides: [_repoOverride, _settingsOverride]);
      addTearDown(container.dispose);
      container.read(currentQuestionProvider.notifier).state =
          QuestionRecord.draft(
        id: 'q-1',
        imagePath: '',
        subject: Subject.math,
        recognizedText: '已知 2x+1=5，求 x 的值',
      );

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: QuestionSaveConfirmationScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('确认题目内容'), findsOneWidget);
      expect(find.text('确认并保存到错题本'), findsOneWidget);
      expect(find.text('已知 2x+1=5，求 x 的值'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('save confirmation screen blocks empty text before saving',
        (tester) async {
      final container =
          ProviderContainer(overrides: [_repoOverride, _settingsOverride]);
      addTearDown(container.dispose);
      container.read(currentQuestionProvider.notifier).state =
          QuestionRecord.draft(
        id: 'q-empty',
        imagePath: '',
        subject: Subject.math,
        recognizedText: '',
      );

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: QuestionSaveConfirmationScreen()),
      ));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('确认并保存到错题本'));
      await tester.tap(find.text('确认并保存到错题本'));
      await tester.pumpAndSettle();

      expect(find.text('请先补充题目内容，再保存到错题本'), findsWidgets);
      expect(find.byType(QuestionSaveConfirmationScreen), findsOneWidget);
    });

    testWidgets('onboarding screen shows three pages with skip and next',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [_repoOverride, _settingsOverride],
        child: const MaterialApp(home: OnboardingScreen()),
      ));
      await tester.pumpAndSettle();

      expect(find.text('AI错题本'), findsOneWidget);
      expect(find.text('拍照录题'), findsOneWidget);
      expect(find.text('跳过'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);

      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('AI 解析'), findsOneWidget);

      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('举一反三'), findsOneWidget);
      expect(find.text('开始使用'), findsOneWidget);
    });
  });
}
