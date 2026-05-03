import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/review_log_repository.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_screen.dart';

QuestionRecord _reviewQuestion(
  String id, {
  String text = 'sample',
  String? rootQuestionId,
  int? splitOrder,
  MasteryLevel masteryLevel = MasteryLevel.newQuestion,
  int reviewCount = 0,
}) {
  final now = DateTime(2026);
  return QuestionRecord(
    id: id,
    imagePath: '/tmp/$id.jpg',
    subject: Subject.math,
    extractedQuestionText: text,
    normalizedQuestionText: text,
    contentFormat: QuestionContentFormat.plain,
    tags: const <String>[],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: reviewCount,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: masteryLevel,
    analysisResult: null,
    rootQuestionId: rootQuestionId,
    splitOrder: splitOrder,
  );
}

Future<void> _pumpReviewScreen(
  WidgetTester tester,
  InMemoryQuestionRepository repository, {
  InMemoryReviewLogRepository? reviewLogRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(repository),
        if (reviewLogRepository != null)
          reviewLogRepositoryProvider.overrideWithValue(reviewLogRepository),
      ],
      child: const MaterialApp(home: ReviewScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ReviewScreen', () {
    testWidgets('shows empty state when no questions due', (tester) async {
      await _pumpReviewScreen(tester, InMemoryQuestionRepository());

      expect(find.text('待复习 0'), findsOneWidget);
      expect(find.text('暂无待复习错题'), findsOneWidget);
    });

    testWidgets('shows summary card with correct counts', (tester) async {
      await _pumpReviewScreen(tester, InMemoryQuestionRepository());

      expect(find.text('整体进度'), findsOneWidget);
      expect(find.text('共 0 题'), findsOneWidget);
    });

    testWidgets('shows history link', (tester) async {
      await _pumpReviewScreen(tester, InMemoryQuestionRepository());

      await tester.scrollUntilVisible(
        find.text('复习记录'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('复习记录'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_right), findsWidgets);
    });

    testWidgets('does not show batch label for standalone due question',
        (tester) async {
      final repository = InMemoryQuestionRepository();
      await repository.saveDraft(_reviewQuestion('q-1', text: '单题'));

      await _pumpReviewScreen(tester, repository);

      expect(find.text('单题'), findsOneWidget);
      expect(find.textContaining('来自同一拍照批次'), findsNothing);
    });

    testWidgets('shows batch labels for due sibling questions', (tester) async {
      final repository = InMemoryQuestionRepository();
      await repository.saveDrafts(<QuestionRecord>[
        _reviewQuestion('q-1',
            text: '第一题', rootQuestionId: 'root-1', splitOrder: 1),
        _reviewQuestion('q-2',
            text: '第二题', rootQuestionId: 'root-1', splitOrder: 2),
      ]);

      await _pumpReviewScreen(tester, repository);

      expect(find.text('第一题'), findsOneWidget);
      expect(find.text('第二题'), findsOneWidget);
      expect(find.text('来自同一拍照批次 · 第 1 题'), findsOneWidget);
      expect(find.text('来自同一拍照批次 · 第 2 题'), findsOneWidget);
    });

    testWidgets('shows mastery status without quick action buttons',
        (tester) async {
      final repository = InMemoryQuestionRepository();
      await repository.saveDrafts(<QuestionRecord>[
        _reviewQuestion('q-new', text: '新增题'),
        _reviewQuestion('q-reviewing',
            text: '复习题', masteryLevel: MasteryLevel.reviewing),
      ]);

      await _pumpReviewScreen(tester, repository);

      expect(find.text('新增题'), findsOneWidget);
      expect(find.text('复习题'), findsOneWidget);
      expect(find.text('待复习'), findsWidgets);
      expect(find.text('仍需复习'), findsNothing);
      expect(find.text('继续巩固'), findsNothing);
      expect(find.widgetWithText(FilledButton, '已掌握'), findsNothing);
    });
  });
}
