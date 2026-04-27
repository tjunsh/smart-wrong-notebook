import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/review_log.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/review_log_repository.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_history_screen.dart';

QuestionRecord _question(String id, String text) {
  final now = DateTime(2026);
  return QuestionRecord(
    id: id,
    imagePath: '',
    subject: Subject.math,
    extractedQuestionText: text,
    normalizedQuestionText: text,
    contentFormat: QuestionContentFormat.plain,
    tags: const <String>[],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: 0,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: MasteryLevel.newQuestion,
    analysisResult: null,
  );
}

ReviewLog _log({
  required String id,
  required String questionId,
  required DateTime reviewedAt,
  required String result,
  required MasteryLevel masteryAfter,
}) {
  return ReviewLog(
    id: id,
    questionRecordId: questionId,
    reviewedAt: reviewedAt,
    result: result,
    masteryAfter: masteryAfter,
  );
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  required InMemoryQuestionRepository questionRepository,
  required InMemoryReviewLogRepository reviewLogRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(questionRepository),
        reviewLogRepositoryProvider.overrideWithValue(reviewLogRepository),
      ],
      child: const MaterialApp(home: ReviewHistoryScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows empty state when there are no review logs',
      (tester) async {
    await _pumpHistory(
      tester,
      questionRepository: InMemoryQuestionRepository(),
      reviewLogRepository: InMemoryReviewLogRepository(),
    );

    expect(find.text('复习记录'), findsOneWidget);
    expect(find.text('暂无复习记录'), findsOneWidget);
    expect(find.text('开始复习后在首页查看历史'), findsOneWidget);
  });

  testWidgets('shows review logs with question text in newest order',
      (tester) async {
    final questionRepository = InMemoryQuestionRepository();
    final reviewLogRepository = InMemoryReviewLogRepository();
    await questionRepository.saveDraft(_question('q-1', '较早题目'));
    await questionRepository.saveDraft(_question('q-2', '较新题目'));
    await reviewLogRepository.insert(_log(
      id: 'log-old',
      questionId: 'q-1',
      reviewedAt: DateTime(2026, 1, 1, 9),
      result: 'reviewing',
      masteryAfter: MasteryLevel.reviewing,
    ));
    await reviewLogRepository.insert(_log(
      id: 'log-new',
      questionId: 'q-2',
      reviewedAt: DateTime(2026, 1, 2, 9),
      result: 'mastered',
      masteryAfter: MasteryLevel.mastered,
    ));

    await _pumpHistory(
      tester,
      questionRepository: questionRepository,
      reviewLogRepository: reviewLogRepository,
    );

    expect(find.text('较新题目'), findsOneWidget);
    expect(find.text('较早题目'), findsOneWidget);
    expect(find.textContaining('已掌握'), findsWidgets);
    expect(find.textContaining('复习中'), findsWidgets);

    final newerTop = tester.getTopLeft(find.text('较新题目')).dy;
    final olderTop = tester.getTopLeft(find.text('较早题目')).dy;
    expect(newerTop, lessThan(olderTop));
  });

  testWidgets('shows deleted fallback for logs without matching question',
      (tester) async {
    final reviewLogRepository = InMemoryReviewLogRepository();
    await reviewLogRepository.insert(_log(
      id: 'log-deleted',
      questionId: 'missing-question',
      reviewedAt: DateTime(2026),
      result: 'mastered',
      masteryAfter: MasteryLevel.mastered,
    ));

    await _pumpHistory(
      tester,
      questionRepository: InMemoryQuestionRepository(),
      reviewLogRepository: reviewLogRepository,
    );

    expect(find.text('已删除'), findsOneWidget);
    expect(find.textContaining('已掌握'), findsWidgets);
  });
}
